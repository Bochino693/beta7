extends CanvasLayer

## MODO EVENTO (antes "Modo Feira") — CADASTRO DE LEADS (liga na Central da Máquina).
##
## Com o modo ligado, antes de cada partida todo jogador preenche uma ficha:
## E-MAIL, NOME e IDADE (a DATA e a hora entram sozinhas). O e-mail é a
## "identidade" do jogador: quem já jogou antes digita o mesmo e-mail e os
## dados voltam prontos para conferir e atualizar - a ficha dele é
## atualizada (não duplica) e a visita é somada.
##
## ONDE FICA GUARDADO
##  1. Na máquina, sempre (mesmo sem pendrive): user://leads/
##       leads.json        todos os jogadores (com cópia leads.json.bak)
##       visitas.csv       diário: uma linha por cadastro, só cresce
##     Se o leads.json estragar (queda de luz no meio), ele é refeito da
##     cópia; sem a cópia, do diário. Nada se perde.
##  2. No PENDRIVE, quando houver um espetado: pasta OlhoNoLance_Leads/
##       leads.csv         planilha universal (vírgula, UTF-8): RD Station,
##                         Mailchimp, HubSpot, Google Contatos, Meta, etc.
##       leads_excel.csv   a mesma planilha, para abrir com 2 cliques no
##                         Excel em português (ponto e vírgula)
##       leads.json        os mesmos dados, completos (é o que o jogo lê
##                         para RECONHECER quem já estava no pendrive)
##       visitas.csv       o histórico: uma linha por cadastro / partida
##       resumo.txt        as estatísticas prontas para ler (por evento)
##       LEIA-ME.txt       o que é cada arquivo
##       copia_de_seguranca/   a versão anterior de cada arquivo
##     Cada arquivo é escrito inteiro num arquivo novo, conferido e só
##     então posto no lugar do antigo: tirar o pendrive ou faltar luz no
##     meio não deixa arquivo pela metade.
##
## JUNTAR: o que já está no pendrive (outra feira, outra máquina) entra na
## conta antes de gravar - a máquina passa a reconhecer aqueles jogadores e
## o pendrive fica com a soma de tudo, sem repetir ninguém.

signal mudou
signal _terminou(ok: bool)

const PASTA_PEN := "OlhoNoLance_Leads"
const COPIA := "copia_de_seguranca"
const FORMATO := "olho-no-lance-leads"
const ANO_MINIMO := 2026           # relógio da TV antes disto = relógio errado
const COLUNAS := ["id", "nome", "email", "idade", "primeira_visita", "ultima_visita", "visitas", "evento", "modo", "autorizou_contato", "maquina"]
const CAB_VISITAS := "data,hora,id,nome,email,idade,modo,evento,maquina"
const IDADE_MIN := 3
const IDADE_MAX := 110
const SEM_TOQUE_S := 150.0         # ficha parada este tempo: volta para o menu
const OLHAR_PEN_S := 5.0
const TELAS_DE_PARTIDA := ["play", "cup_play", "torment_play", "pendings_play"]
const FONTE_TITULO := "res://fonts/BarlowCondensed-ExtraBoldItalic.ttf"
const FONTE_FORTE := "res://fonts/Barlow-Bold.ttf"
const VERDE := Color(0.30, 1.0, 0.50)
const AMARELO := Color(1.0, 0.84, 0.10)
const VERMELHO := Color(1.0, 0.36, 0.30)

var ligado := false
var evento := ""
var maquina := ""
var pendente := false              # tem cadastro que ainda não foi para o pendrive
var ultima_gravacao := ""          # "23/11/2026 14:05" da última ida ao pendrive
var onde_gravou := ""              # a pasta, para mostrar ao operador
var ajuste_relogio := 0            # segundos somados ao relógio da TV (Central da Máquina)
var ajuste_com_relogio_errado := false
var ultimo_instante := 0
var painel_aberto := false         # a Central da Máquina está aberta

var _pasta := ""
var _leads := {}                   # e-mail -> ficha
var _visitas := 0
var _olhar := 0.0
var _tinha_pen := false
var _destinos := {}                # raiz -> destino já testado
var _letras_win := ""
var _removiveis_win: PackedStringArray = []
var _fio: Thread
var _erro_pen := ""


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pasta = OS.get_user_data_dir().path_join("leads")
	DirAccess.make_dir_recursive_absolute(_pasta)
	_carregar_cfg()
	_carregar()
	ControleTv.teclado_fechou.connect(_teclado_fechou)


func _exit_tree() -> void:
	if _fio != null and _fio.is_started():
		_fio.wait_to_finish()


# ------------------------------------------------------------------ ajustes
func _carregar_cfg() -> void:
	var cfg := ConfigFile.new()
	cfg.load(_pasta.path_join("config.cfg"))
	ligado = bool(cfg.get_value("feira", "ligado", false))
	evento = str(cfg.get_value("feira", "evento", ""))
	maquina = str(cfg.get_value("feira", "maquina", ""))
	pendente = bool(cfg.get_value("feira", "pendente", false))
	ultima_gravacao = str(cfg.get_value("feira", "ultima_gravacao", ""))
	onde_gravou = str(cfg.get_value("feira", "onde_gravou", ""))
	ajuste_relogio = int(cfg.get_value("relogio", "ajuste", 0))
	ajuste_com_relogio_errado = bool(cfg.get_value("relogio", "com_relogio_errado", false))
	ultimo_instante = int(cfg.get_value("relogio", "ultimo_instante", 0))
	if maquina == "":
		# o nome desta máquina nos arquivos (para saber de onde veio cada cadastro)
		maquina = "M-" + ("%08X" % (randi() ^ int(Time.get_unix_time_from_system()))).substr(0, 6)
		_guardar_cfg()


func _guardar_cfg() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("feira", "ligado", ligado)
	cfg.set_value("feira", "evento", evento)
	cfg.set_value("feira", "maquina", maquina)
	cfg.set_value("feira", "pendente", pendente)
	cfg.set_value("feira", "ultima_gravacao", ultima_gravacao)
	cfg.set_value("feira", "onde_gravou", onde_gravou)
	cfg.set_value("relogio", "ajuste", ajuste_relogio)
	cfg.set_value("relogio", "com_relogio_errado", ajuste_com_relogio_errado)
	cfg.set_value("relogio", "ultimo_instante", ultimo_instante)
	cfg.save(_pasta.path_join("config.cfg"))


## O MODO EVENTO LIGA SEMPRE, COM OU SEM PENDRIVE: os cadastros ficam
## guardados na máquina e vão para o pendrive assim que ele for espetado
## (o menu e a Central da Máquina avisam enquanto falta o pendrive).
func ligar(sim: bool) -> bool:
	if ligado == sim:
		return true
	ligado = sim
	_tinha_pen = false
	_olhar = OLHAR_PEN_S
	_guardar_cfg()
	mudou.emit()
	return true


func definir_evento(nome: String) -> void:
	evento = _uma_linha(nome).to_upper().substr(0, 40)
	_guardar_cfg()


# ------------------------------------------------------------------- relógio
## A "data atual" de cada cadastro é a do relógio da TV Box / do PC. Caixa
## sem internet costuma abrir com o relógio errado (ano 2015...): a Central
## da Máquina deixa acertar - o jogo guarda a diferença e passa a usar a
## data certa. Se o relógio da caixa voltar para trás (religou sem bateria),
## os cadastros continuam a partir do último instante conhecido.
func _relogio_da_tv() -> int:
	return int(Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system()))


func relogio_suspeito() -> bool:
	return int(Time.get_datetime_dict_from_system().get("year", 0)) < ANO_MINIMO and ajuste_relogio == 0


func agora_unix() -> int:
	var errado: bool = int(Time.get_datetime_dict_from_system().get("year", 0)) < ANO_MINIMO
	if ajuste_relogio != 0 and ajuste_com_relogio_errado and not errado:
		# a TV pegou a hora certa (internet): o acerto feito à mão não vale mais
		ajuste_relogio = 0
		ajuste_com_relogio_errado = false
		_guardar_cfg()
	var u := _relogio_da_tv() + ajuste_relogio
	if errado and u <= ultimo_instante:
		ajuste_relogio += ultimo_instante - u + 60
		u = ultimo_instante + 60
		_guardar_cfg()
	return u


## "2026-11-23 14:05:09" (o formato que toda planilha e plataforma entende).
func texto_data(u: int) -> String:
	return Time.get_datetime_string_from_unix_time(u, true)


## "23/11/2026 14:05" (para a tela).
func data_na_tela(u: int = -1) -> String:
	var d := Time.get_datetime_dict_from_unix_time(agora_unix() if u < 0 else u)
	return "%02d/%02d/%04d  %02d:%02d" % [d.day, d.month, d.year, d.hour, d.minute]


## A Central da Máquina acerta a data: campo = "dia" | "mes" | "ano" | "hora" | "minuto".
func acertar_relogio(campo: String, quanto: int) -> void:
	var antes := _relogio_da_tv() + ajuste_relogio
	var d := Time.get_datetime_dict_from_unix_time(antes)
	match campo:
		"dia": antes += 86400 * quanto
		"hora": antes += 3600 * quanto
		"minuto": antes += 60 * quanto
		"mes", "ano":
			if campo == "ano":
				d.year = clampi(int(d.year) + quanto, 2024, 2099)
			else:
				var m := int(d.month) - 1 + quanto
				d.year = int(d.year) + int(floor(m / 12.0))
				d.month = posmod(m, 12) + 1
			var dias := [31, 29 if (int(d.year) % 4 == 0 and (int(d.year) % 100 != 0 or int(d.year) % 400 == 0)) else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
			d.day = mini(int(d.day), int(dias[int(d.month) - 1]))
			antes = int(Time.get_unix_time_from_datetime_dict(d))
	ajuste_relogio = antes - _relogio_da_tv()
	ajuste_com_relogio_errado = int(Time.get_datetime_dict_from_system().get("year", 0)) < ANO_MINIMO
	ultimo_instante = 0
	_guardar_cfg()
	mudou.emit()


# ------------------------------------------------------------ texto limpo
static func _uma_linha(t: String) -> String:
	var s := t.replace("\r", " ").replace("\n", " ").replace("\t", " ").strip_edges()
	while s.contains("  "):
		s = s.replace("  ", " ")
	return s


static func limpar_email(t: String) -> String:
	return t.strip_edges().to_lower().replace(" ", "")


static func email_valido(e: String) -> bool:
	if e.length() < 6 or e.length() > 90 or e.contains(".."):
		return false
	var er := RegEx.new()
	er.compile("^[a-z0-9][a-z0-9._%+-]*@[a-z0-9][a-z0-9-]*(\\.[a-z0-9-]+)+$")
	if er.search(e) == null:
		return false
	var fim := e.get_slice(".", e.get_slice_count(".") - 1)
	return fim.length() >= 2 and not e.contains(".@") and not e.contains("@.") and not e.contains("-.")


## "MARIA DA SILVA" -> "Maria da Silva" (as planilhas e os e-mails ficam certos).
static func limpar_nome(t: String) -> String:
	var s := _uma_linha(t)
	# (um nome começa por letra: nada de fórmula de planilha nem sinal solto)
	while s != "" and not _e_letra(s[0]):
		s = s.substr(1)
	var saida: PackedStringArray = []
	var palavras := s.split(" ", false)
	for i in range(palavras.size()):
		var p: String = palavras[i].to_lower()
		if i > 0 and p in ["da", "de", "do", "das", "dos", "e"]:
			saida.append(p)
		else:
			saida.append(p.substr(0, 1).to_upper() + p.substr(1))
	return " ".join(saida).substr(0, 60)


static func _e_letra(c: String) -> bool:
	return c.to_upper() != c.to_lower()


static func nome_valido(n: String) -> bool:
	var letras := 0
	for i in range(n.length()):
		if _e_letra(n[i]):
			letras += 1
	return letras >= 2


static func id_de(email: String) -> String:
	return "L" + email.sha256_text().substr(0, 10).to_upper()


# -------------------------------------------------------------- consultas
func total() -> int:
	return _leads.size()


func visitas() -> int:
	return _visitas


func hoje() -> int:
	var dia := texto_data(agora_unix()).substr(0, 10)
	var n := 0
	for e in _leads:
		if str(_leads[e].get("ultima_visita", "")).begins_with(dia):
			n += 1
	return n


## A ficha de quem já jogou ({} = nunca veio).
func procurar(email: String) -> Dictionary:
	return _leads.get(limpar_email(email), {})


# ------------------------------------------------------------ cadastrar
## Guarda (ou atualiza) o jogador. Devolve a ficha; "novo" diz se é a 1a vez.
func registrar(nome: String, email: String, idade: int, modo: String) -> Dictionary:
	var e := limpar_email(email)
	var agora := agora_unix()
	var quando := texto_data(agora)
	var novo := not _leads.has(e)
	var r: Dictionary = _leads.get(e, {})
	if novo:
		r = {"id": id_de(e), "email": e, "primeira_visita": quando, "visitas": 0}
	r["nome"] = limpar_nome(nome)
	r["idade"] = clampi(idade, 0, 130)
	r["ultima_visita"] = quando
	r["visitas"] = int(r.get("visitas", 0)) + 1
	r["evento"] = evento
	r["modo"] = modo
	r["autorizou_contato"] = "sim"
	r["maquina"] = maquina
	_leads[e] = r
	_anotar_visita(r, quando, modo)
	ultimo_instante = agora
	pendente = true
	var copia := r.duplicate()
	copia["novo"] = novo
	return copia


## Depois de uma ou mais fichas: grava na máquina e tenta o pendrive.
func fechar_cadastros() -> void:
	_guardar()
	_guardar_cfg()
	mudou.emit()
	_olhar = OLHAR_PEN_S   # o pendrive é visto no próximo quadro livre


func _anotar_visita(r: Dictionary, quando: String, modo: String) -> void:
	var caminho := _pasta.path_join("visitas.csv")
	var linha := _linha_visita(r, quando, modo)
	var f: FileAccess
	if FileAccess.file_exists(caminho):
		f = FileAccess.open(caminho, FileAccess.READ_WRITE)
		if f != null:
			f.seek_end()
	else:
		f = FileAccess.open(caminho, FileAccess.WRITE)
		if f != null:
			f.store_string(CAB_VISITAS + "\r\n")
	if f == null:
		return
	f.store_string(linha + "\r\n")
	f.close()
	_visitas += 1


func _linha_visita(r: Dictionary, quando: String, modo: String) -> String:
	return ",".join([quando.substr(0, 10), quando.substr(11), str(r.get("id", "")), _csv_campo(str(r.get("nome", "")), ","),
		str(r.get("email", "")), str(int(r.get("idade", 0))), _csv_campo(modo, ","), _csv_campo(evento, ","), maquina])


# --------------------------------------------------- arquivos da máquina
## Arquivo inteiro num arquivo novo, conferido, e só então no lugar do
## antigo (que fica como .bak): nunca sobra arquivo pela metade.
func _gravar_seguro(caminho: String, texto: String, guardar_bak := true) -> bool:
	var novo := caminho + ".tmp"
	var f := FileAccess.open(novo, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(texto)
	f.flush()
	f.close()
	if not _mesmo_texto(FileAccess.get_file_as_string(novo), texto):
		DirAccess.remove_absolute(novo)
		return false
	if FileAccess.file_exists(caminho):
		if guardar_bak:
			DirAccess.remove_absolute(caminho + ".bak")
			DirAccess.rename_absolute(caminho, caminho + ".bak")
		else:
			DirAccess.remove_absolute(caminho)
	return DirAccess.rename_absolute(novo, caminho) == OK


static func _mesmo_texto(a: String, b: String) -> bool:
	return a.trim_prefix("\uFEFF") == b.trim_prefix("\uFEFF")


func _guardar() -> bool:
	return _gravar_seguro(_pasta.path_join("leads.json"), _json_texto())


func _carregar() -> void:
	_leads.clear()
	var base := _pasta.path_join("leads.json")
	var ok := false
	for caminho in [base, base + ".bak", base + ".tmp"]:
		if FileAccess.file_exists(caminho) and _juntar_json(FileAccess.get_file_as_string(caminho)) >= 0:
			ok = true
			if caminho != base:
				push_warning("LEADS: leads.json refeito de " + caminho.get_file())
			break
	var diario := _ler_visitas(FileAccess.get_file_as_string(_pasta.path_join("visitas.csv")) if FileAccess.file_exists(_pasta.path_join("visitas.csv")) else "")
	_visitas = diario.size()
	if not ok and not diario.is_empty():
		push_warning("LEADS: leads.json refeito do diário de visitas")
	# (o diário manda: quem está nele e não está no leads.json volta)
	if _refazer_do_diario(diario) or not ok:
		_guardar()


## Lê um leads.json (o da máquina ou o do pendrive) e JUNTA com o que já
## está na memória. Devolve quantas fichas mudaram (-1 = arquivo ruim).
func _juntar_json(texto: String) -> int:
	if texto.strip_edges() == "":
		return -1
	var leitor := JSON.new()
	if leitor.parse(texto.trim_prefix("\uFEFF")) != OK:
		return -1
	var dados: Variant = leitor.data
	if not (dados is Dictionary) or str(dados.get("formato", "")) != FORMATO or not (dados.get("leads") is Array):
		return -1
	var mudou_n := 0
	for item in dados["leads"]:
		if not (item is Dictionary):
			continue
		var e := limpar_email(str(item.get("email", "")))
		if not email_valido(e):
			continue
		var r := {"id": id_de(e), "email": e, "nome": limpar_nome(str(item.get("nome", ""))), "idade": int(item.get("idade", 0)),
			"primeira_visita": str(item.get("primeira_visita", "")), "ultima_visita": str(item.get("ultima_visita", "")),
			"visitas": maxi(int(item.get("visitas", 1)), 1), "evento": _uma_linha(str(item.get("evento", ""))),
			"modo": _uma_linha(str(item.get("modo", ""))), "autorizou_contato": str(item.get("autorizou_contato", "sim")),
			"maquina": _uma_linha(str(item.get("maquina", "")))}
		if _juntar_ficha(r):
			mudou_n += 1
	return mudou_n


## Uma ficha de fora entra na memória: a mais recente manda no nome e na
## idade; a 1a visita é a mais antiga; as visitas, a maior conta.
func _juntar_ficha(r: Dictionary) -> bool:
	var e: String = r["email"]
	if not _leads.has(e):
		_leads[e] = r
		return true
	var meu: Dictionary = _leads[e]
	var antes := meu.duplicate()
	if str(r["primeira_visita"]) != "" and (str(meu.get("primeira_visita", "")) == "" or str(r["primeira_visita"]) < str(meu["primeira_visita"])):
		meu["primeira_visita"] = r["primeira_visita"]
	if str(r["ultima_visita"]) > str(meu.get("ultima_visita", "")):
		for k in ["nome", "idade", "ultima_visita", "evento", "modo", "maquina", "autorizou_contato"]:
			meu[k] = r[k]
	meu["visitas"] = maxi(int(meu.get("visitas", 1)), int(r["visitas"]))
	return meu != antes


func _json_texto() -> String:
	var lista: Array = []
	for r in _ordenados():
		var item := {}
		for c in COLUNAS:
			item[c] = r.get(c, "")
		item["idade"] = int(r.get("idade", 0))
		item["visitas"] = int(r.get("visitas", 1))
		lista.append(item)
	# ("atualizado" = a visita mais recente: o arquivo só muda quando os dados mudam)
	var recente := ""
	for item in lista:
		if str(item["ultima_visita"]) > recente:
			recente = str(item["ultima_visita"])
	var dados := {"formato": FORMATO, "versao": 1, "jogo": "Olho no Lance", "atualizado": recente,
		"total": lista.size(), "leads": lista}
	return JSON.stringify(dados, "  ", false) + "\n"


func _ordenados() -> Array:
	var lista: Array = _leads.values()
	lista.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa := str(a.get("primeira_visita", ""))
		var pb := str(b.get("primeira_visita", ""))
		return pa < pb if pa != pb else str(a.get("email", "")) < str(b.get("email", "")))
	return lista


# -------------------------------------------------------------- planilhas
static func _csv_campo(v: String, sep: String) -> String:
	var s := v.replace("\r", " ").replace("\n", " ")
	if s.contains(sep) or s.contains("\"") or s.begins_with(" ") or s.ends_with(" "):
		return "\"" + s.replace("\"", "\"\"") + "\""
	return s


func _csv_texto(sep: String, bom: bool) -> String:
	var linhas: PackedStringArray = []
	linhas.append(sep.join(COLUNAS))
	for r in _ordenados():
		var campos: PackedStringArray = []
		for c in COLUNAS:
			var v: Variant = r.get(c, "")
			campos.append(_csv_campo(str(int(v)) if c in ["idade", "visitas"] else str(v), sep))
		linhas.append(sep.join(campos))
	return ("\uFEFF" if bom else "") + "\r\n".join(linhas) + "\r\n"


## Uma linha de planilha em pedaços (aspas e vírgulas dentro do nome valem).
static func _partes_csv(linha: String, sep := ",") -> PackedStringArray:
	var saida: PackedStringArray = []
	var atual := ""
	var aspas := false
	var i := 0
	while i < linha.length():
		var c := linha[i]
		if aspas:
			if c == "\"":
				if i + 1 < linha.length() and linha[i + 1] == "\"":
					atual += "\""
					i += 1
				else:
					aspas = false
			else:
				atual += c
		elif c == "\"":
			aspas = true
		elif c == sep:
			saida.append(atual)
			atual = ""
		else:
			atual += c
		i += 1
	saida.append(atual)
	return saida


## As linhas de um visitas.csv (sem o cabeçalho, sem repetidas, em ordem).
func _ler_visitas(texto: String) -> PackedStringArray:
	var vistas := {}
	for bruta in texto.trim_prefix("\uFEFF").split("\n", false):
		var l := bruta.strip_edges()
		if l == "" or l.begins_with("data,") or l.length() < 24 or l[4] != "-" or l[10] != ",":
			continue
		vistas[l] = true
	var saida := PackedStringArray(vistas.keys())
	saida.sort()
	return saida


func _texto_visitas(linhas: PackedStringArray) -> String:
	return CAB_VISITAS + "\r\n" + ("\r\n".join(linhas) + "\r\n" if not linhas.is_empty() else "")


## O diário manda nas contas: quem só está nele volta para as fichas e as
## visitas de cada um são as linhas dele. true = alguma ficha mudou.
func _refazer_do_diario(linhas: PackedStringArray) -> bool:
	var contas := {}
	var ultimas := {}
	for l in linhas:
		var p := _partes_csv(l)
		if p.size() < 6:
			continue
		var e := limpar_email(p[4])
		if not email_valido(e):
			continue
		contas[e] = int(contas.get(e, 0)) + 1
		ultimas[e] = p
	var mexeu := false
	for e in contas:
		var p: PackedStringArray = ultimas[e]
		var quando := p[0] + " " + p[1]
		if not _leads.has(e):
			_leads[e] = {"id": id_de(e), "email": e, "nome": limpar_nome(p[3]), "idade": int(p[5]), "primeira_visita": quando,
				"ultima_visita": quando, "visitas": int(contas[e]), "evento": p[7] if p.size() > 7 else "",
				"modo": p[6] if p.size() > 6 else "", "autorizou_contato": "sim", "maquina": p[8] if p.size() > 8 else ""}
			mexeu = true
		elif int(_leads[e].get("visitas", 0)) < int(contas[e]):
			_leads[e]["visitas"] = int(contas[e])
			mexeu = true
	return mexeu


## AS ESTATÍSTICAS PRONTAS PARA LER (resumo.txt no pendrive): por evento,
## quantos jogadores, quantos cadastros (partidas), novos x quem voltou,
## idades e movimento por dia. Feito das mesmas linhas do visitas.csv.
func _resumo_texto(linhas: PackedStringArray) -> String:
	var eventos := {}      # nome -> {"cad", "emails" {e-mail: idade}, "novos", "dias", "modos"}
	var ordem: Array = []
	var vistos := {}       # e-mails que já apareceram (as linhas vêm em ordem de data)
	var ultimo_dia := ""
	for l in linhas:
		var p := _partes_csv(l)
		if p.size() < 6:
			continue
		var e := limpar_email(p[4])
		var nome_ev: String = p[7] if p.size() > 7 and p[7] != "" else "(sem nome de evento)"
		if not eventos.has(nome_ev):
			eventos[nome_ev] = {"cad": 0, "emails": {}, "novos": 0, "dias": {}, "modos": {}}
			ordem.append(nome_ev)
		var ev: Dictionary = eventos[nome_ev]
		ev["cad"] = int(ev["cad"]) + 1
		ev["emails"][e] = int(p[5])
		ev["dias"][p[0]] = int(ev["dias"].get(p[0], 0)) + 1
		var modo: String = p[6] if p.size() > 6 and p[6] != "" else "-"
		ev["modos"][modo] = int(ev["modos"].get(modo, 0)) + 1
		if not vistos.has(e):
			vistos[e] = true
			ev["novos"] = int(ev["novos"]) + 1
		ultimo_dia = p[0] + " " + p[1]
	var t: PackedStringArray = []
	t.append("OLHO NO LANCE - RESUMO DOS CADASTROS (MODO EVENTO)")
	t.append("==================================================")
	# ("até" = o cadastro mais recente: o arquivo só muda quando os dados mudam)
	t.append("Máquina: %s        Cadastros até: %s" % [maquina, ultimo_dia if ultimo_dia != "" else "-"])
	t.append("")
	t.append("NO TOTAL")
	t.append("  jogadores diferentes ........ %d" % _leads.size())
	t.append("  cadastros (um por partida) .. %d" % linhas.size())
	t.append("  jogaram mais de uma vez ..... %d" % _quantos_voltaram())
	t.append("  idades ...................... %s" % _texto_idades(_idades_de(_leads)))
	for nome_ev in ordem:
		var ev: Dictionary = eventos[nome_ev]
		var emails: Dictionary = ev["emails"]
		t.append("")
		t.append("EVENTO: %s" % nome_ev)
		t.append("  jogadores diferentes ........ %d" % emails.size())
		t.append("  cadastros (um por partida) .. %d" % int(ev["cad"]))
		t.append("  novos neste evento .......... %d" % int(ev["novos"]))
		t.append("  já tinham cadastro .......... %d" % (emails.size() - int(ev["novos"])))
		t.append("  idades ...................... %s" % _texto_idades(emails.values()))
		var modos: PackedStringArray = []
		for m in ev["modos"]:
			modos.append("%s %d" % [m, int(ev["modos"][m])])
		t.append("  por modo de jogo ............ %s" % "  /  ".join(modos))
		t.append("  por dia:")
		var dias: Array = (ev["dias"] as Dictionary).keys()
		dias.sort()
		for d in dias:
			t.append("    %s/%s/%s ................ %d cadastro(s)" % [str(d).substr(8, 2), str(d).substr(5, 2), str(d).substr(0, 4), int(ev["dias"][d])])
	t.append("")
	t.append("A lista completa está no leads.csv (um jogador por linha) e no")
	t.append("visitas.csv (uma linha por cadastro).")
	t.append("")
	return "\r\n".join(t)


func _quantos_voltaram() -> int:
	var n := 0
	for e in _leads:
		if int(_leads[e].get("visitas", 1)) > 1:
			n += 1
	return n


func _idades_de(fichas: Dictionary) -> Array:
	var saida: Array = []
	for e in fichas:
		saida.append(int(fichas[e].get("idade", 0)))
	return saida


## "média 21 anos / até 12: 3 / 13 a 17: 2 / 18 a 29: 5 / 30 a 49: 4 / 50+: 1"
func _texto_idades(idades: Array) -> String:
	var faixas := [0, 0, 0, 0, 0]
	var soma := 0
	var n := 0
	for i in idades:
		var a := int(i)
		if a <= 0:
			continue
		soma += a
		n += 1
		faixas[0 if a <= 12 else (1 if a <= 17 else (2 if a <= 29 else (3 if a <= 49 else 4)))] += 1
	if n == 0:
		return "-"
	return "média %d anos  /  até 12: %d  /  13 a 17: %d  /  18 a 29: %d  /  30 a 49: %d  /  50+: %d" % [int(round(float(soma) / n)), faixas[0], faixas[1], faixas[2], faixas[3], faixas[4]]


func _leia_me() -> String:
	return "\r\n".join([
		"OLHO NO LANCE - CADASTROS DOS JOGADORES (MODO EVENTO)",
		"====================================================",
		"",
		"Esta pasta é escrita pelo jogo. Pode copiar os arquivos à vontade.",
		"",
		"leads.csv         Um jogador por linha. Separado por vírgula, UTF-8.",
		"                  É o arquivo para IMPORTAR em outras plataformas",
		"                  (RD Station, Mailchimp, HubSpot, Google Contatos,",
		"                  Meta / Google Ads, Planilhas Google...).",
		"leads_excel.csv   A mesma lista, para abrir com 2 cliques no Excel em",
		"                  português (separado por ponto e vírgula).",
		"leads.json        A mesma lista, completa. É o arquivo que o JOGO lê",
		"                  para reconhecer quem já se cadastrou. NÃO EDITE.",
		"visitas.csv       O histórico: uma linha para cada cadastro / partida",
		"                  (data, hora, jogador, modo de jogo, evento).",
		"resumo.txt        AS ESTATÍSTICAS PRONTAS: por evento, quantos jogadores,",
		"                  quantos cadastros, novos x quem já tinha cadastro,",
		"                  idades e movimento por dia. É só abrir e ler.",
		"copia_de_seguranca\\  A versão anterior de cada arquivo.",
		"",
		"COLUNAS DO leads.csv",
		"  id                 código do jogador (sempre o mesmo para o mesmo e-mail)",
		"  nome, email, idade o que o jogador informou na última visita",
		"  primeira_visita    data e hora do 1o cadastro (AAAA-MM-DD HH:MM:SS)",
		"  ultima_visita      data e hora do último cadastro",
		"  visitas            quantas vezes ele se cadastrou para jogar",
		"  evento             nome do evento / feira (Central da Máquina)",
		"  modo               modo de jogo da última visita (ARCADE, COPA...)",
		"  autorizou_contato  sim = aceitou o aviso de contato na ficha",
		"  maquina            código da máquina onde foi a última visita",
		"",
		"O MESMO JOGADOR NÃO SE REPETE: quem volta e digita o mesmo e-mail tem",
		"a ficha atualizada (nome, idade, última visita) e a visita somada.",
		"",
		"PENDRIVE EM OUTRA MÁQUINA OU EM OUTRA FEIRA: deixe estes arquivos nele.",
		"O jogo lê o que já está aqui, reconhece esses jogadores e grava tudo",
		"junto, sem perder nem repetir ninguém.",
		"",
		"ANTES DE TIRAR O PENDRIVE: espere a Central da Máquina (Modo Evento)",
		"mostrar \"GRAVADO - PODE TIRAR O PENDRIVE\".",
		"",
		"Dados pessoais (LGPD): use estes contatos só para o que foi avisado ao",
		"jogador na ficha, guarde o pendrive em lugar seguro e apague os dados",
		"de quem pedir.",
		""])


# ---------------------------------------------------------------- pendrive
func _plugin() -> Object:
	if OS.get_name() == "Android" and Engine.has_singleton("StrikeSerial"):
		var p := Engine.get_singleton("StrikeSerial")
		if p.has_method("pen_pasta"):
			return p
	return null


## Uma pasta do pendrive onde dá para escrever ({} = não dá).
func _destino_pasta(raiz: String, nome: String) -> Dictionary:
	if raiz == "":
		return {}
	if _destinos.has(raiz):
		if DirAccess.dir_exists_absolute(raiz):
			return _destinos[raiz]
		_destinos.erase(raiz)
	if not DirAccess.dir_exists_absolute(raiz):
		return {}
	var pasta := raiz.path_join(PASTA_PEN)
	DirAccess.make_dir_recursive_absolute(pasta.path_join(COPIA))
	var teste := pasta.path_join(".teste_de_escrita")
	var f := FileAccess.open(teste, FileAccess.WRITE)
	if f == null:
		return {}
	f.store_string("ok")
	f.close()
	var leu := FileAccess.get_file_as_string(teste)
	DirAccess.remove_absolute(teste)
	if leu != "ok":
		return {}
	var d := {"tipo": "pasta", "raiz": raiz, "pasta": pasta, "nome": nome}
	_destinos[raiz] = d
	return d


## O pendrive que está espetado agora ({} = nenhum onde dê para escrever).
func achar_pendrive() -> Dictionary:
	var teste := OS.get_environment("OLHO_PENDRIVE")
	if teste != "":
		return _destino_pasta(teste, teste)
	match OS.get_name():
		"Android": return _achar_android()
		"Windows": return _achar_windows()
	return _achar_unix()


func _pastas_de(base: String) -> PackedStringArray:
	var saida: PackedStringArray = []
	if DirAccess.dir_exists_absolute(base):
		for n in DirAccess.get_directories_at(base):
			saida.append(base.path_join(n))
	return saida


## Android: os arquivos passam pelo plugin (o leitor de arquivos do Godot não
## enxerga pendrives). 1o a pasta que o operador escolheu no seletor do
## Android; senão a pasta que o plugin achou e testou (raiz do pendrive ou
## a pasta do próprio jogo dentro dele).
func _achar_android() -> Dictionary:
	var p := _plugin()
	if p == null:
		return {}
	var nome := str(p.call("pen_nome"))
	if nome != "":
		return {"tipo": "android", "nome": nome, "pasta": nome + "/" + PASTA_PEN}
	var pasta := str(p.call("pen_pasta"))
	if pasta != "":
		return {"tipo": "java", "nome": "pendrive", "pasta": pasta}
	return {}


func _achar_unix() -> Dictionary:
	for base in ["/media", "/run/media"]:
		for usuario in _pastas_de(base):
			for r in _pastas_de(usuario):
				var d := _destino_pasta(r, r.get_file())
				if not d.is_empty():
					return d
	return {}


## Windows: só unidades REMOVÍVEIS (o Windows diz quais são; a pergunta vai
## em segundo plano e só quando a lista de letras muda).
func _achar_windows() -> Dictionary:
	var letras := ""
	for i in range(DirAccess.get_drive_count()):
		letras += DirAccess.get_drive_name(i) + " "
	if letras != _letras_win and (_fio == null or not _fio.is_started()):
		_letras_win = letras
		_fio = Thread.new()
		_fio.start(_perguntar_ao_windows)
	for letra in _removiveis_win:
		var d := _destino_pasta(letra + "/", letra)
		if not d.is_empty():
			return d
	# (sem resposta do Windows: vale a unidade que já tem a pasta dos leads)
	for i in range(DirAccess.get_drive_count()):
		var letra := DirAccess.get_drive_name(i)
		if letra.to_upper().begins_with("C") or letra.length() > 3:
			continue
		if DirAccess.dir_exists_absolute(letra + "/" + PASTA_PEN):
			var d := _destino_pasta(letra + "/", letra)
			if not d.is_empty():
				return d
	return {}


func _perguntar_ao_windows() -> void:
	var saida: Array = []
	var achou: PackedStringArray = []
	var cod := OS.execute("powershell.exe", ["-NoProfile", "-NonInteractive", "-Command",
		"Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=2' | ForEach-Object { $_.DeviceID }"], saida, false, false)
	if cod == 0:
		for bloco in saida:
			for l in str(bloco).split("\n", false):
				var s := l.strip_edges().to_upper()
				if s.length() == 2 and s[1] == ":":
					achou.append(s)
	_resposta_do_windows.call_deferred(achou)


func _resposta_do_windows(achou: PackedStringArray) -> void:
	_removiveis_win = achou
	if _fio != null:
		_fio.wait_to_finish()
		_fio = null


func _pen_ler(dest: Dictionary, rel: String) -> String:
	if str(dest.get("tipo", "")) == "android":
		var p := _plugin()
		return str(p.call("pen_ler", PASTA_PEN + "/" + rel)) if p != null else ""
	if str(dest.get("tipo", "")) == "java":
		var pj := _plugin()
		return str(pj.call("arq_ler", str(dest["pasta"]) + "/" + rel)) if pj != null else ""
	var caminho := str(dest["pasta"]).path_join(rel)
	return FileAccess.get_file_as_string(caminho) if FileAccess.file_exists(caminho) else ""


func _pen_gravar(dest: Dictionary, rel: String, texto: String) -> bool:
	if str(dest.get("tipo", "")) == "android":
		var p := _plugin()
		return p != null and bool(p.call("pen_gravar", PASTA_PEN + "/" + rel, texto))
	if str(dest.get("tipo", "")) == "java":
		var pj := _plugin()
		return pj != null and bool(pj.call("arq_gravar", str(dest["pasta"]) + "/" + rel, texto))
	var caminho := str(dest["pasta"]).path_join(rel)
	DirAccess.make_dir_recursive_absolute(caminho.get_base_dir())
	return _gravar_seguro(caminho, texto, false)


## Troca um arquivo do pendrive: a versão anterior vai para a cópia de
## segurança, a nova é gravada e LIDA DE VOLTA para conferir.
func _trocar_no_pen(dest: Dictionary, nome: String, texto: String) -> bool:
	var antigo := _pen_ler(dest, nome)
	if _mesmo_texto(antigo, texto):
		return true
	if antigo != "":
		_pen_gravar(dest, COPIA + "/" + nome, antigo)
	if not _pen_gravar(dest, nome, texto):
		return false
	return _mesmo_texto(_pen_ler(dest, nome), texto)


func _sincronizar() -> void:
	var p := _plugin()
	if p != null and p.has_method("pen_sincronizar"):
		p.call("pen_sincronizar")
	elif OS.get_name() == "Linux" and OS.get_environment("OLHO_PENDRIVE") == "":
		OS.execute("sync", [])


## JUNTA o que está no pendrive com o que está na máquina e grava os
## arquivos. true = gravado e conferido (pode tirar o pendrive).
func gravar_no_pendrive() -> bool:
	var dest := achar_pendrive()
	if dest.is_empty():
		_erro_pen = ""
		return false
	# 1. quem já estava no pendrive entra na conta
	var mudou_n := maxi(_juntar_json(_pen_ler(dest, "leads.json")), 0)
	var local := _pasta.path_join("visitas.csv")
	var meu_diario := FileAccess.get_file_as_string(local) if FileAccess.file_exists(local) else ""
	var minhas := _ler_visitas(meu_diario)
	var todas := _ler_visitas(meu_diario + "\n" + _pen_ler(dest, "visitas.csv"))
	if _refazer_do_diario(todas):
		mudou_n += 1
	if todas.size() != minhas.size():
		_gravar_seguro(local, _texto_visitas(todas), false)
		_visitas = todas.size()
	if mudou_n > 0:
		_guardar()
	# 2. os arquivos do pendrive
	var certo := true
	for par in [["leads.json", _json_texto()], ["leads.csv", _csv_texto(",", false)], ["leads_excel.csv", _csv_texto(";", true)],
			["visitas.csv", _texto_visitas(todas)], ["resumo.txt", _resumo_texto(todas)], ["LEIA-ME.txt", _leia_me()]]:
		if not _trocar_no_pen(dest, str(par[0]), str(par[1])):
			certo = false
			_erro_pen = "não consegui gravar " + str(par[0])
			break
	_sincronizar()
	onde_gravou = str(dest.get("pasta", dest.get("nome", "")))
	if certo:
		pendente = false
		_erro_pen = ""
		ultima_gravacao = data_na_tela()
	_guardar_cfg()
	mudou.emit()
	return certo


## O estado do pendrive em uma linha, para a Central da Máquina.
func texto_pendrive() -> String:
	var dest := achar_pendrive()
	if dest.is_empty():
		if pendente:
			return "SEM PENDRIVE  •  os cadastros estão guardados na máquina e vão para o pendrive quando ele for espetado"
		return "SEM PENDRIVE  •  espete um para receber os cadastros"
	if _erro_pen != "":
		return "PENDRIVE COM ERRO: %s  •  tente outro pendrive" % _erro_pen
	if pendente:
		return "PENDRIVE ENCONTRADO  •  gravando..."
	if ultima_gravacao == "":
		return "PENDRIVE ENCONTRADO  •  nenhum cadastro ainda"
	return "GRAVADO EM %s  •  PODE TIRAR O PENDRIVE  •  %s" % [ultima_gravacao, onde_gravou]


func tem_pendrive() -> bool:
	return not achar_pendrive().is_empty()


## Android: o operador escolhe a pasta do pendrive no seletor (uma vez).
func escolher_pendrive() -> bool:
	var p := _plugin()
	return p != null and bool(p.call("pen_escolher"))


## Apaga TODOS os cadastros desta máquina (os arquivos do pendrive ficam).
func apagar_tudo() -> void:
	_leads.clear()
	_visitas = 0
	for nome in ["leads.json", "leads.json.bak", "leads.json.tmp", "visitas.csv"]:
		DirAccess.remove_absolute(_pasta.path_join(nome))
	pendente = false
	ultima_gravacao = ""
	_guardar()
	_guardar_cfg()
	mudou.emit()


func _process(delta: float) -> void:
	if _ficha != null:
		_ficha_quadro(delta)
		return
	# o pendrive: só fora das partidas, e só se há o que gravar (ou a Central aberta)
	if not (pendente or painel_aberto or ligado):
		return
	_olhar += delta
	if _olhar < OLHAR_PEN_S:
		return
	_olhar = 0.0
	var cena := get_tree().current_scene
	if cena == null or cena.scene_file_path.get_file().get_basename() in TELAS_DE_PARTIDA:
		return
	var tem := tem_pendrive()
	if tem and _erro_pen == "" and (pendente or (ligado and not _tinha_pen)):
		# cadastro novo para gravar, ou o pendrive acabou de ser visto: junta
		# o que está nele (reconhece aqueles jogadores) e grava
		gravar_no_pendrive()
	elif tem != _tinha_pen:
		if not tem:
			_erro_pen = ""
		mudou.emit()
	_tinha_pen = tem


# =====================================================================
# A FICHA DO JOGADOR (na frente do jogo, pelo controle remoto da TV)
# =====================================================================
var _ficha: Control
var _palco: Control
var _cartao: Panel
var _fila: Array = []
var _indice := 0
var _modo := "ARCADE"
var _campo_email: LineEdit
var _campo_nome: LineEdit
var _campo_idade: LineEdit
var _titulo: Label
var _conta: Label
var _recado: Label
var _passos: Array[Panel] = []
var _bt_confirmar: Button
var _bt_voltar: Button
var _parado := 0.0
var _voltar_em := 0
var _reconhecido := ""
var _estilo_cartao: StyleBoxFlat


func ficha_aberta() -> bool:
	return _ficha != null


func tocou() -> void:
	_parado = 0.0


## ARCADE: uma ficha por jogador (cores = a cor de cada um). Devolve false
## se o cadastro foi abandonado (a partida não começa).
func cadastrar_jogadores(quantos: int, cores: Array, modo: String = "ARCADE") -> bool:
	var lista: Array = []
	for i in range(quantos):
		lista.append({"titulo": "JOGADOR %d" % (i + 1), "cor": cores[i] if i < cores.size() else VERDE, "nome": "", "nome_fixo": false})
	return await cadastrar(lista, modo)


## COPA / TORNEIO: os nomes já foram escritos; a ficha pede e-mail e idade.
func cadastrar_nomes(nomes: Array, modo: String = "COPA") -> bool:
	var lista: Array = []
	for n in nomes:
		lista.append({"titulo": str(n).to_upper(), "cor": AMARELO, "nome": str(n), "nome_fixo": true})
	return await cadastrar(lista, modo)


func cadastrar(lista: Array, modo: String) -> bool:
	if not ligado or lista.is_empty() or _ficha != null:
		return true
	_fila = lista
	_indice = 0
	_modo = modo
	_montar_ficha()
	_mostrar_jogador()
	var ok: bool = await _terminou
	_desmontar_ficha()
	if ok:
		fechar_cadastros()
	return ok


func _fonte(caminho: String) -> Font:
	return load(caminho) if ResourceLoader.exists(caminho) else null


func _rotulo(pai: Control, texto: String, tam: int, cor: Color, pos: Vector2, tamanho: Vector2, fonte := "", alinhar := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = texto
	l.position = pos
	l.size = tamanho
	l.horizontal_alignment = alinhar
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.clip_text = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	var f := _fonte(fonte) if fonte != "" else null
	if f != null:
		l.add_theme_font_override("font", f)
	pai.add_child(l)
	return l


func _caixa(cor_fundo: Color, cor_borda: Color, raio: int, borda := 2) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = cor_fundo
	st.border_color = cor_borda
	st.set_border_width_all(borda)
	st.set_corner_radius_all(raio)
	st.content_margin_left = 16
	st.content_margin_right = 16
	return st


func _campo(pai: Control, pos: Vector2, tamanho: Vector2, dica: String, teclado: String, titulo: String, maximo: int) -> LineEdit:
	var c := LineEdit.new()
	c.position = pos
	c.size = tamanho
	c.placeholder_text = dica
	c.max_length = maximo
	c.context_menu_enabled = false
	c.virtual_keyboard_enabled = false
	c.focus_mode = Control.FOCUS_NONE   # quem escreve é o teclado da tela (ControleTv)
	c.set_meta("teclado", teclado)
	c.set_meta("titulo", titulo)
	c.add_theme_font_size_override("font_size", 26)
	c.add_theme_color_override("font_color", Color.WHITE)
	c.add_theme_color_override("font_placeholder_color", Color(0.50, 0.58, 0.70))
	c.add_theme_stylebox_override("normal", _caixa(Color(0.02, 0.04, 0.08), Color(0.30, 0.48, 0.72), 12))
	c.add_theme_stylebox_override("read_only", _caixa(Color(0.05, 0.08, 0.13), Color(0.30, 0.36, 0.46), 12))
	c.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	c.text_changed.connect(_campo_mudou.unbind(1))
	pai.add_child(c)
	return c


func _botao(pai: Control, texto: String, pos: Vector2, tamanho: Vector2, cor: Color, cheio: bool) -> Button:
	var b := Button.new()
	b.text = texto
	b.position = pos
	b.size = tamanho
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 28 if cheio else 22)
	var f := _fonte(FONTE_TITULO)
	if f != null:
		b.add_theme_font_override("font", f)
	for estado in ["normal", "hover", "pressed"]:
		var forte: float = 1.0 if estado == "normal" else 1.18
		var st := _caixa(Color(cor.r * forte, cor.g * forte, cor.b * forte, 1.0) if cheio else Color(cor.r, cor.g, cor.b, 0.10 if estado == "normal" else 0.22),
			cor, int(tamanho.y * 0.5))
		b.add_theme_stylebox_override(estado, st)
	var tinta := Color(0.02, 0.10, 0.04) if cheio else cor
	for nome_cor in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(nome_cor, tinta)
	pai.add_child(b)
	return b


## A ficha é desenhada para 1280 x 720 e cresce inteira com a tela.
func _montar_ficha() -> void:
	var tela := get_viewport().get_visible_rect().size
	var k: float = minf(tela.x / 1280.0, tela.y / 720.0)
	_ficha = Control.new()
	_ficha.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ficha.mouse_filter = Control.MOUSE_FILTER_STOP   # nada atrás recebe toque / seta
	add_child(_ficha)
	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.01, 0.04, 0.10, 0.80)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ficha.add_child(fundo)
	_palco = Control.new()
	_palco.size = Vector2(1280, 720)
	_palco.scale = Vector2(k, k)
	_palco.position = (tela - Vector2(1280, 720) * k) * 0.5
	_palco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ficha.add_child(_palco)

	_cartao = Panel.new()
	_cartao.position = Vector2(70, 12)
	_cartao.size = Vector2(1140, 696)
	_cartao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_estilo_cartao = _caixa(Color(0.035, 0.065, 0.12, 0.985), VERDE, 28, 3)
	_cartao.add_theme_stylebox_override("panel", _estilo_cartao)
	_palco.add_child(_cartao)

	# cabeçalho
	var selo := Panel.new()
	selo.position = Vector2(30, 14)
	selo.size = Vector2(300, 28)
	selo.add_theme_stylebox_override("panel", _caixa(Color(AMARELO.r, AMARELO.g, AMARELO.b, 0.14), Color(AMARELO.r, AMARELO.g, AMARELO.b, 0.7), 14))
	_cartao.add_child(selo)
	_rotulo(selo, "MODO EVENTO  •  CADASTRO", 16, AMARELO, Vector2.ZERO, selo.size, FONTE_FORTE, HORIZONTAL_ALIGNMENT_CENTER)
	_titulo = _rotulo(_cartao, "", 46, Color.WHITE, Vector2(30, 40), Vector2(760, 52), FONTE_TITULO)
	_conta = _rotulo(_cartao, "", 22, Color(0.72, 0.80, 0.92), Vector2(800, 14), Vector2(310, 30), FONTE_FORTE, HORIZONTAL_ALIGNMENT_RIGHT)
	_rotulo(_cartao, "HOJE:  " + data_na_tela().substr(0, 10), 20, Color(0.60, 0.70, 0.82), Vector2(800, 48), Vector2(310, 30), "", HORIZONTAL_ALIGNMENT_RIGHT)

	# os 3 campos (em cima: o teclado da tela abre embaixo)
	_rotulo(_cartao, "E-MAIL", 20, Color(0.72, 0.84, 1.0), Vector2(30, 98), Vector2(100, 50), FONTE_FORTE)
	_campo_email = _campo(_cartao, Vector2(134, 98), Vector2(976, 50), "seu e-mail  (ex.: maria@gmail.com)", "email", "E-MAIL DO JOGADOR", 90)
	_rotulo(_cartao, "NOME", 20, Color(0.72, 0.84, 1.0), Vector2(30, 156), Vector2(100, 50), FONTE_FORTE)
	_campo_nome = _campo(_cartao, Vector2(134, 156), Vector2(660, 50), "nome e sobrenome", "", "NOME DO JOGADOR", 40)
	_rotulo(_cartao, "IDADE", 20, Color(0.72, 0.84, 1.0), Vector2(814, 156), Vector2(90, 50), FONTE_FORTE)
	_campo_idade = _campo(_cartao, Vector2(910, 156), Vector2(200, 50), "anos", "numero", "IDADE DO JOGADOR (ANOS)", 3)

	_recado = _rotulo(_cartao, "", 24, Color(0.80, 0.88, 0.98), Vector2(30, 216), Vector2(1080, 44), FONTE_FORTE, HORIZONTAL_ALIGNMENT_CENTER)

	# os 3 passos, grandes: o que falta fica à vista
	_passos.clear()
	var nomes_passo := ["1   E-MAIL", "2   NOME", "3   IDADE"]
	for i in range(3):
		var p := Panel.new()
		p.position = Vector2(30 + i * 366, 276)
		p.size = Vector2(348, 150)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_theme_stylebox_override("panel", _caixa(Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.16), 20))
		_cartao.add_child(p)
		_rotulo(p, nomes_passo[i], 30, Color.WHITE, Vector2(20, 14), Vector2(308, 40), FONTE_TITULO)
		_rotulo(p, "", 22, Color(0.70, 0.78, 0.90), Vector2(20, 60), Vector2(308, 76)).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_passos.append(p)

	var ajuda := _rotulo(_cartao, "Use o MOUSE ou as SETAS + OK do controle.   Já jogou antes?  Digite o mesmo e-mail: seus dados voltam sozinhos.", 20,
		Color(0.72, 0.80, 0.92), Vector2(30, 440), Vector2(1080, 34), "", HORIZONTAL_ALIGNMENT_CENTER)
	ajuda.clip_text = false
	var aviso := _rotulo(_cartao, "Ao confirmar, você autoriza a Lazer & Sport a guardar estes dados e a entrar em contato com você.\nMenor de idade: o cadastro é feito pelo responsável.",
		16, Color(0.52, 0.60, 0.72), Vector2(30, 486), Vector2(1080, 50), "", HORIZONTAL_ALIGNMENT_CENTER)
	aviso.clip_text = false

	_bt_voltar = _botao(_cartao, "✕  SAIR SEM JOGAR", Vector2(30, 600), Vector2(300, 66), Color(0.75, 0.80, 0.88), false)
	_bt_voltar.pressed.connect(voltar)
	_bt_confirmar = _botao(_cartao, "CONFIRMAR E JOGAR  ▶", Vector2(650, 596), Vector2(460, 74), VERDE, true)
	_bt_confirmar.pressed.connect(_confirmar)

	# entrada: surge e dá um pulo curto
	_cartao.pivot_offset = _cartao.size * 0.5
	_cartao.scale = Vector2(0.92, 0.92)
	_ficha.modulate.a = 0.0
	var tw := _ficha.create_tween()
	tw.set_parallel(true)
	tw.tween_property(_ficha, "modulate:a", 1.0, 0.20)
	tw.tween_property(_cartao, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_parado = 0.0
	_voltar_em = 0


func _desmontar_ficha() -> void:
	ControleTv.fechar_teclado()
	if _ficha != null and is_instance_valid(_ficha):
		_ficha.queue_free()
	_ficha = null
	_palco = null
	_cartao = null
	_passos.clear()
	_fila = []


func _mostrar_jogador() -> void:
	var j: Dictionary = _fila[_indice]
	var cor: Color = j.get("cor", VERDE)
	_titulo.text = str(j.get("titulo", "JOGADOR"))
	_titulo.add_theme_color_override("font_color", cor.lightened(0.25))
	_conta.text = ("JOGADOR  %d  DE  %d" % [_indice + 1, _fila.size()]) if _fila.size() > 1 else ""
	_estilo_cartao.border_color = cor
	var fixo: bool = bool(j.get("nome_fixo", false))
	_campo_email.text = ""
	_campo_nome.text = limpar_nome(str(j.get("nome", ""))) if fixo else ""
	_campo_nome.editable = not fixo
	_campo_idade.text = ""
	_reconhecido = ""
	_bt_confirmar.text = "CONFIRMAR E JOGAR  ▶" if _indice == _fila.size() - 1 else "CONFIRMAR  •  PRÓXIMO JOGADOR  ▶"
	_dizer("Digite o seu E-MAIL para começar", Color(0.80, 0.88, 0.98))
	_atualizar_passos()
	# já abre o teclado no e-mail (depois da entrada da ficha)
	var mesmo := _indice
	get_tree().create_timer(0.38, true, false, true).timeout.connect(func() -> void:
		if _ficha != null and _indice == mesmo and not ControleTv.teclado_aberto() and _campo_email.text == "":
			ControleTv.abrir_teclado(_campo_email))


func _dizer(texto: String, cor: Color) -> void:
	if _recado != null:
		_recado.text = texto
		_recado.add_theme_color_override("font_color", cor)


func _campo_mudou() -> void:
	_parado = 0.0
	_atualizar_passos()


func _atualizar_passos() -> void:
	if _passos.size() < 3:
		return
	var e := limpar_email(_campo_email.text)
	var idade := int(_campo_idade.text) if _campo_idade.text.is_valid_int() else 0
	var certos := [email_valido(e), nome_valido(_campo_nome.text), idade >= IDADE_MIN and idade <= IDADE_MAX]
	var textos := [e if e != "" else "ainda não digitado", _campo_nome.text if _campo_nome.text != "" else "ainda não digitado",
		("%d anos" % idade) if _campo_idade.text != "" else "ainda não digitada"]
	for i in range(3):
		var cor: Color = VERDE if certos[i] else Color(1, 1, 1, 0.16)
		_passos[i].add_theme_stylebox_override("panel", _caixa(Color(VERDE.r, VERDE.g, VERDE.b, 0.10) if certos[i] else Color(1, 1, 1, 0.04), cor, 20))
		var titulo := _passos[i].get_child(0) as Label
		titulo.text = ["E-MAIL", "NOME", "IDADE"][i] + ("   ✔" if certos[i] else "")
		titulo.add_theme_color_override("font_color", VERDE if certos[i] else Color.WHITE)
		(_passos[i].get_child(1) as Label).text = textos[i]


## O teclado da tela fechou: a ficha anda sozinha para o próximo passo.
func _teclado_fechou(campo: LineEdit, pronto: bool) -> void:
	if _ficha == null or not pronto:
		return
	_seguir.call_deferred(campo)


func _seguir(campo: LineEdit) -> void:
	if _ficha == null:
		return
	if campo == _campo_email:
		var e := limpar_email(_campo_email.text)
		_campo_email.text = e
		if not email_valido(e):
			_dizer("Confira o E-MAIL: falta o @ ou o final  (ex.: maria@gmail.com)", VERMELHO)
			ControleTv.marcar(_campo_email)
			return
		var antigo := procurar(e)
		if not antigo.is_empty() and _reconhecido != e:
			# JÁ JOGOU: os dados voltam prontos, é só conferir
			_reconhecido = e
			if _campo_nome.editable:
				_campo_nome.text = str(antigo.get("nome", ""))
			_campo_idade.text = str(int(antigo.get("idade", 0))) if int(antigo.get("idade", 0)) > 0 else ""
			_atualizar_passos()
			_dizer("BEM-VINDO DE VOLTA, %s!  Confira os dados e confirme." % str(antigo.get("nome", "")).get_slice(" ", 0).to_upper(), VERDE)
			if _tudo_certo():
				ControleTv.marcar(_bt_confirmar)
				return
	_proximo_passo()


func _tudo_certo() -> bool:
	var idade := int(_campo_idade.text) if _campo_idade.text.is_valid_int() else 0
	return email_valido(limpar_email(_campo_email.text)) and nome_valido(_campo_nome.text) and idade >= IDADE_MIN and idade <= IDADE_MAX


## Abre o teclado no primeiro campo que falta; com tudo certo, marca o CONFIRMAR.
func _proximo_passo() -> void:
	_atualizar_passos()
	var idade := int(_campo_idade.text) if _campo_idade.text.is_valid_int() else 0
	if not email_valido(limpar_email(_campo_email.text)):
		ControleTv.abrir_teclado(_campo_email)
	elif not nome_valido(_campo_nome.text) and _campo_nome.editable:
		if _campo_nome.text != "":
			_dizer("Confira o NOME  (pelo menos 2 letras)", VERMELHO)
		elif _reconhecido == "":
			_dizer("Agora o seu NOME", Color(0.80, 0.88, 0.98))
		ControleTv.abrir_teclado(_campo_nome)
	elif idade < IDADE_MIN or idade > IDADE_MAX:
		if _campo_idade.text != "":
			_dizer("Confira a IDADE  (de %d a %d anos)" % [IDADE_MIN, IDADE_MAX], VERMELHO)
		elif _reconhecido == "":
			_dizer("E a sua IDADE", Color(0.80, 0.88, 0.98))
		ControleTv.abrir_teclado(_campo_idade)
	else:
		if _reconhecido == "":
			_dizer("TUDO CERTO!  Aperte OK para confirmar", VERDE)
		ControleTv.marcar(_bt_confirmar)


func _confirmar() -> void:
	if _ficha == null:
		return
	_parado = 0.0
	if not _tudo_certo():
		var e := limpar_email(_campo_email.text)
		if not email_valido(e):
			_dizer("Falta o E-MAIL  (ex.: maria@gmail.com)", VERMELHO)
		elif not nome_valido(_campo_nome.text):
			_dizer("Falta o NOME", VERMELHO)
		else:
			_dizer("Falta a IDADE  (de %d a %d anos)" % [IDADE_MIN, IDADE_MAX], VERMELHO)
		_proximo_passo.call_deferred()
		return
	var r := registrar(_campo_nome.text, _campo_email.text, int(_campo_idade.text), _modo)
	_fila[_indice]["cadastro"] = r
	_indice += 1
	if _indice >= _fila.size():
		_terminou.emit(true)
		return
	# próximo jogador: a ficha "vira"
	var tw := _cartao.create_tween()
	tw.tween_property(_cartao, "modulate:a", 0.0, 0.12)
	tw.tween_callback(_mostrar_jogador)
	tw.tween_property(_cartao, "modulate:a", 1.0, 0.16)


## VOLTAR do controle / botão SAIR: pede de novo para ter certeza.
func voltar() -> void:
	if _ficha == null:
		return
	var agora := Time.get_ticks_msec()
	if _voltar_em > 0 and agora - _voltar_em < 4000:
		_terminou.emit(false)
		return
	_voltar_em = agora
	_dizer("SAIR SEM JOGAR?  Aperte VOLTAR de novo para sair", AMARELO)
	ControleTv.marcar(_bt_voltar)


func _ficha_quadro(delta: float) -> void:
	_parado += delta
	if _parado >= SEM_TOQUE_S:
		_terminou.emit(false)   # ninguém na máquina: o menu volta
	elif _parado >= SEM_TOQUE_S - 20.0:
		_dizer("ALGUÉM AÍ?  Voltando ao menu em %d s..." % int(ceil(SEM_TOQUE_S - _parado)), AMARELO)
