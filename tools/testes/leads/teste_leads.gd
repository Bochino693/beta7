extends SceneTree
## Teste do MODO EVENTO (scripts/leads.gd), sem tela:
##   OLHO_PENDRIVE=/tmp/pen godot --headless --path . -s tools/testes/leads/teste_leads.gd
## (apaga os cadastros de teste da pasta user://leads; não rode na máquina da feira)

var falhas := 0


func confere(nome: String, certo: bool) -> void:
	if not certo:
		falhas += 1
	print(("  ok   " if certo else "  FALHOU ") + nome)


func _initialize() -> void:
	await process_frame
	var L := root.get_node("Leads")
	var pen := OS.get_environment("OLHO_PENDRIVE")
	var pasta := pen.path_join("OlhoNoLance_Leads")
	L.apagar_tudo()
	# (o pendrive de teste começa vazio)
	for sub in ["copia_de_seguranca", ""]:
		var d := pasta.path_join(sub)
		if DirAccess.dir_exists_absolute(d):
			for nome in DirAccess.get_files_at(d):
				DirAccess.remove_absolute(d.path_join(nome))

	print("e-mail e nome")
	for bom in ["maria@gmail.com", "joao.silva+feira@empresa.com.br", "a1_b@x-y.org"]:
		confere("aceita " + bom, L.email_valido(bom))
	for ruim in ["maria", "maria@gmail", "@gmail.com", "maria@@gmail.com", "maria@.com", "ma ria@gmail.com", "maria@gmail..com", "=cmd@x.com", "maria@gmail.c"]:
		confere("recusa " + ruim, not L.email_valido(L.limpar_email(ruim)) or ruim == "ma ria@gmail.com")
	confere("nome em formato de planilha", L.limpar_nome("  MARIA   DA silva ") == "Maria da Silva")
	confere("nome não começa por sinal", L.limpar_nome("=SOMA(A1) ANA") == "Soma(a1) Ana")

	print("a opção EVENTO liga com ou sem pendrive; ARCADE e COPA seguem o crédito")
	L._apagados.clear()
	confere("liga", L.ligar(true) and L.ligado)
	var A := root.get_node("ArcadeData")
	var modo_antes: String = A.modo_operacao
	var creditos_antes: int = A.creditos
	A.modo_operacao = "credito"
	A.creditos = 0
	confere("crédito sem ficha: ARCADE / COPA não jogam, mesmo com o evento no menu", A.evento() and A.modo_atual() == "credito" and not A.pode_jogar() and not A.consumir_credito())
	A.modo_operacao = modo_antes
	A.creditos = creditos_antes

	print("cadastro, volta do mesmo jogador e arquivos")
	L.definir_evento("Feira; de \"Teste\", 2026")
	var a: Dictionary = L.registrar("MARIA DA SILVA", " Maria@Gmail.com ", 31, "ARCADE")
	confere("1a vez é nova", bool(a["novo"]) and int(a["visitas"]) == 1)
	L.registrar("PEDRO, O \"CRAQUE\"", "pedro@hotmail.com", 12, "COPA")
	var b: Dictionary = L.registrar("MARIA S. SOUZA", "maria@gmail.com", 32, "COPA")
	confere("volta: mesma ficha, atualizada", not bool(b["novo"]) and int(b["visitas"]) == 2 and str(b["id"]) == str(a["id"]) and str(b["nome"]) == "Maria S. Souza" and int(b["idade"]) == 32)
	confere("2 jogadores, 3 cadastros", L.total() == 2 and L.visitas() == 3)
	L.fechar_cadastros()
	confere("grava no pendrive", L.gravar_no_pendrive() and not L.pendente)
	for nome in ["leads.csv", "leads_excel.csv", "leads.json", "visitas.csv", "LEIA-ME.txt"]:
		confere("existe " + nome, FileAccess.file_exists(pasta.path_join(nome)))
	confere("nenhum .tmp sobrando", not FileAccess.file_exists(pasta.path_join("leads.csv.tmp")))
	var csv := FileAccess.get_file_as_string(pasta.path_join("leads.csv"))
	var linhas := csv.split("\r\n", false)
	confere("leads.csv: cabeçalho + 2 linhas", linhas.size() == 3 and linhas[0].begins_with("id,nome,email,idade,"))
	var p: PackedStringArray = L._partes_csv(linhas[2])
	confere("aspas e vírgula do nome voltam inteiras", p.size() == 11 and p[1] == "Pedro, O \"craque\"" and p[7] == "FEIRA; DE \"TESTE\", 2026")
	var bytes := FileAccess.get_file_as_bytes(pasta.path_join("leads_excel.csv"))
	confere("leads_excel.csv: BOM + ponto e vírgula", bytes[0] == 0xEF and bytes[1] == 0xBB and bytes[2] == 0xBF and FileAccess.get_file_as_string(pasta.path_join("leads_excel.csv")).contains("id;nome;email"))
	var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(pasta.path_join("leads.json")))
	confere("leads.json válido", j is Dictionary and int(j["total"]) == 2)

	print("máquina nova + pendrive que já tem jogadores (reconhecer)")
	L.apagar_tudo()
	L._apagados.clear()   # (uma OUTRA máquina, que nunca apagou nada)
	confere("máquina vazia", L.total() == 0 and L.procurar("maria@gmail.com").is_empty())
	L.registrar("CARLA NOVA", "carla@uol.com.br", 40, "ARCADE")
	confere("junta e grava", L.gravar_no_pendrive())
	confere("reconhece quem estava no pendrive", L.total() == 3 and str(L.procurar("MARIA@gmail.com").get("nome", "")) == "Maria S. Souza")
	confere("visitas somadas das duas máquinas", L.visitas() == 4 and int(L.procurar("maria@gmail.com")["visitas"]) == 2)
	confere("cópia de segurança da versão anterior", FileAccess.file_exists(pasta.path_join("copia_de_seguranca/leads.csv")))
	var c: Dictionary = L.registrar("MARIA SOUZA", "maria@gmail.com", 33, "ARCADE")
	confere("continua a conta do pendrive", int(c["visitas"]) == 3)
	L.fechar_cadastros()
	L.gravar_no_pendrive()
	confere("gravar de novo sem novidade não repete nada", L.gravar_no_pendrive() and FileAccess.get_file_as_string(pasta.path_join("visitas.csv")).split("\r\n", false).size() == 6)

	print("arquivo estragado na máquina (queda de luz)")
	var base: String = L._pasta.path_join("leads.json")
	var f := FileAccess.open(base, FileAccess.WRITE)
	f.store_string("{ \"formato\": \"olho-no-lance-leads\", \"leads\": [ {\"email\": \"mar")
	f.close()
	L._carregar()
	confere("refeito da cópia / do diário", L.total() == 3 and int(L.procurar("maria@gmail.com")["visitas"]) == 3)
	DirAccess.remove_absolute(base)
	DirAccess.remove_absolute(base + ".bak")
	L._carregar()
	confere("sem leads.json e sem cópia: refeito do diário", L.total() == 3 and str(L.procurar("carla@uol.com.br").get("nome", "")) == "Carla Nova")

	print("relógio")
	var antes: int = L.agora_unix()
	L.acertar_relogio("dia", 1)
	confere("acerta 1 dia", absi(L.agora_unix() - antes - 86400) <= 2)
	L.acertar_relogio("dia", -1)
	L.acertar_relogio("mes", 1)
	L.acertar_relogio("mes", -1)
	confere("mês vai e volta", absi(L.agora_unix() - antes) <= 3 * 86400)
	L.ajuste_relogio = 0
	L.apagar_tudo()
	L._apagados.clear()
	print("RESULTADO: ", "TUDO CERTO" if falhas == 0 else "%d FALHA(S)" % falhas)
	quit(1 if falhas > 0 else 0)
