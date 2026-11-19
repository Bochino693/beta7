extends Node

## O ARDUINO DA MÁQUINA NA TV BOX / TV ANDROID (cabo USB direto na TV).
##
## No Windows nada muda: cada tela continua usando a ponte PowerShell na
## COM5, como sempre. Fora do Windows (TV Box, TV Android) os mesmos
## comandos das telas ("SET:A=255,0,0;B=..." e "OFF") passam por aqui e vão
## para o Arduino pelo plugin Android StrikeSerial (addons/StrikeSerial).
##
## Com o firmware novo (arduino/gol_flash_arena) o Arduino também LÊ a
## máquina e manda para o jogo, então a placa Zero Delay não é necessária
## na TV Box:
##   Arduino -> jogo:  OLA:GOL_FLASH:1 / PONG:GOL_FLASH:1
##                     S:A ... S:G        (bola no alvo A..G)
##                     B:START:1 / B:START:0   (botão START apertou/soltou)
##                     B:SELECT:1 / B:SELECT:0 (botão SELECT/COPA)
##                     FICHA              (moedeiro / noteiro: 1 crédito)
##   jogo -> Arduino:  PING, OFF, SET:A=r,g,b;B=r,g,b...
##                     (SET acende os alvos da lista e apaga os outros)
## O firmware antigo (só LEDs) também funciona: os LEDs acendem, e os
## sensores continuam vindo pela placa Zero Delay.
##
## PERMISSÃO USB: o Android pergunta UMA vez ("Permitir que o Gol Flash
## Arena acesse o USB?"). Marque "Usar por padrão / Sempre" e OK: nunca mais
## aparece, nem depois de desligar a TV.

signal mudou
signal sensor(letra: String)

const BAUD := 9600
const LETRAS := ["A", "B", "C", "D", "E", "F", "G"]
const ESPACO_MS := 30            # entre dois comandos (o Arduino fica surdo enquanto acende a fita)
const PING_MS := 2000
const PROCURAR_MS := 1500
const REINICIO_UNO_MS := 2300    # o Uno reinicia ao abrir a porta
const SEM_RESPOSTA_MS := 7000
const PERMISSOES := "user://permissoes_usb.cfg"

var status := "Arduino: iniciando..."
var conectado := false
var firmware := ""               # "GOL_FLASH:1" (novo) ou "" (antigo, só LEDs)
var chip := ""
var contagem := {}               # letra -> quantas vezes o sensor bateu (tela de teste)
var ultimo_comando := ""         # último comando de LED pedido pelo jogo

var _plugin: Object
var _fase := "procurando"        # procurando | abrindo | aquecendo | conectado
var _aparelho := ""
var _desde := 0
var _ultimo_rx := 0
var _ultimo_tx := 0
var _ultimo_ping := 0
var _ultima_procura := -100000
var _pendente := ""              # comando de LED esperando a vez (o último vale)
var _falhou := {}
var _pedir_agora := false
var _pedidos: ConfigFile


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_imagem_da_tv()
	for l in LETRAS:
		contagem[l] = 0
	if OS.get_name() == "Windows":
		status = "Arduino: ponte PowerShell (COM5)"
		set_process(false)
		return
	if OS.get_name() != "Android":
		status = "Arduino: só no Windows (COM5) ou na TV Box (USB)"
		set_process(false)
		return
	if not Engine.has_singleton("StrikeSerial"):
		status = "Arduino: este APK não tem o plugin USB — gere pelo GERAR_APK.bat"
		set_process(false)
		# sem o plugin nada da máquina funciona (Arduino, abrir ao ligar): avisa na tela
		get_tree().create_timer(10.0, true, false, true).timeout.connect(func() -> void:
			_mostrar_aviso("ESTE APK ESTÁ INCOMPLETO", "Ele foi gerado sem o plugin da máquina (o Gradle falhou):\no Arduino não funciona e o jogo não abre sozinho ao ligar.\n\nGere de novo pelo GERAR_APK.bat e envie o arquivo\nbuild\\android\\GERACAO-COMPLETA.log se falhar.", "", 20000, false)
			get_tree().create_timer(20.0, true, false, true).timeout.connect(_fechar_aviso))
		return
	_plugin = Engine.get_singleton("StrikeSerial")
	_abriu_em = Time.get_ticks_msec()


## ABRIR SOZINHO AO LIGAR A TV (a TV Box é só do jogo).
## Ao abrir, o plugin tenta se preparar em silêncio (root / adb da TV). Se a
## caixa não deixar, o jogo PEDE UMA VEZ, uns 10 s depois de o menu
## aparecer, em QUALQUER versão do Android: um aviso grande explica, OK abre
## a tela do Android e você escolhe GOL FLASH ARENA como tela inicial
## ("Sempre"). É o caminho que o próprio Android usa para abrir um app ao
## ligar: nenhuma ROM bloqueia. Aceito, nunca mais pede. Não aceito, pede de
## novo nas próximas aberturas (no máximo MAX_PEDIDOS; depois, só pela
## Central da Máquina). No Android 10+ a segunda tentativa pede "Sobrepor a
## outros apps" (para a caixa que não deixa trocar a tela inicial).
const ESPERA_INICIO_MS := 9000
const MAX_PEDIDOS := 4
var aviso_aberto := false          # o ControleTv manda o OK para cá
var _inicio_resolvido := false
var _inicio_olhou := 0
var _inicio_pediu := false
var _inicio_modo := "tela"         # "tela" (tela inicial) ou "sobrepor"
var _aviso: CanvasLayer
var _aviso_ate := 0
var _abriu_em := 0


func _inicio_pronto(d: Dictionary) -> bool:
	if str(d.get("tela_inicial", "")) == "jogo":
		return true
	# Android 10+: com "Sobrepor" permitido o aviso de "ligou" e o guarda abrem o jogo
	return int(d.get("sdk", "0")) >= 29 and str(d.get("sobrepor", "")) == "sim"


func _olhar_inicio(agora: int) -> void:
	if aviso_aberto:
		if _aviso_ate > 0 and agora >= _aviso_ate:
			confirmar_aviso()
		return
	if _inicio_resolvido or agora - _inicio_olhou < 2000 or agora - _abriu_em < ESPERA_INICIO_MS:
		return
	_inicio_olhou = agora
	var cena := get_tree().current_scene
	if cena == null or cena.scene_file_path.get_file() != "opening.tscn":
		return
	if bool(_plugin.call("permissao_pendente")):
		return   # uma janela do Android por vez: primeiro a do USB
	var d := inicio_estado()
	if _inicio_pronto(d):
		_inicio_resolvido = true
		if _inicio_pediu:
			_mostrar_aviso("PRONTO!", "O jogo vai abrir sozinho sempre que a TV Box ligar.", "", 5000, false)
		return
	if _inicio_pediu:
		# voltou da tela do Android sem escolher: pede de novo na próxima abertura
		_inicio_resolvido = true
		_mostrar_aviso("AINDA NÃO ESTÁ PRONTO", "O jogo ainda não é a tela inicial da TV Box.\nO pedido aparece de novo na próxima vez que o jogo abrir\n(ou agora: MENU > Central da Máquina > ABRIR SOZINHO AO LIGAR A TV).", "", 9000, false)
		return
	var cfg := ConfigFile.new()
	cfg.load(PERMISSOES)
	var pedidos := int(cfg.get_value("inicio", "pedidos", 0))
	if pedidos >= MAX_PEDIDOS:
		_inicio_resolvido = true
		return
	cfg.set_value("inicio", "pedidos", pedidos + 1)
	cfg.save(PERMISSOES)
	_pedidos = null
	# Android 10+: 1o "Sobrepor a outros apps" (essas caixas quase nunca deixam
	# trocar a tela inicial pelo menu); nas vezes pares, a tela inicial.
	# Android 9 ou mais antigo: sempre a tela inicial.
	var novo: bool = int(d.get("sdk", "0")) >= 29
	_inicio_modo = "sobrepor" if (novo and str(d.get("sobrepor", "")) == "nao" and pedidos % 2 == 0) else "tela"
	if _inicio_modo == "sobrepor":
		_mostrar_aviso("PARA O JOGO ABRIR SOZINHO AO LIGAR",
			"Na próxima tela, deixe  GOL FLASH ARENA  PERMITIDO (ligado)\ne aperte VOLTAR no controle.\n\nÉ só desta vez.",
			"APERTE OK PARA CONTINUAR", 25000, true)
	else:
		_mostrar_aviso("PARA O JOGO ABRIR SOZINHO AO LIGAR",
			"Na próxima tela, escolha  GOL FLASH ARENA  como tela inicial\n(app de início) e, se aparecer, marque  SEMPRE.\n\nÉ só desta vez.",
			"APERTE OK PARA CONTINUAR", 25000, true)


func _mostrar_aviso(titulo: String, texto: String, rodape: String, ms: int, pede: bool) -> void:
	_fechar_aviso()
	_aviso = CanvasLayer.new()
	_aviso.layer = 120
	_aviso.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_aviso)
	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0, 0, 0, 0.93)
	_aviso.add_child(fundo)
	var tela := get_viewport().get_visible_rect().size
	var k := clampf(tela.x / 1280.0, 0.8, 3.0)
	var caixa := VBoxContainer.new()
	caixa.set_anchors_preset(Control.PRESET_FULL_RECT)
	caixa.alignment = BoxContainer.ALIGNMENT_CENTER
	caixa.add_theme_constant_override("separation", int(26 * k))
	_aviso.add_child(caixa)
	for item in [[titulo, 44, Color(1.0, 0.86, 0.10)], [texto, 28, Color.WHITE], [rodape, 26, Color(0.30, 1.0, 0.50)]]:
		if str(item[0]) == "":
			continue
		var l := Label.new()
		l.text = str(item[0])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", int(int(item[1]) * k))
		l.add_theme_color_override("font_color", item[2])
		caixa.add_child(l)
	var diag := texto_inicio()
	if diag != "":
		var ld := Label.new()
		ld.text = diag
		ld.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ld.add_theme_font_size_override("font_size", int(15 * k))
		ld.add_theme_color_override("font_color", Color(0.55, 0.65, 0.78))
		caixa.add_child(ld)
	aviso_aberto = true
	_aviso_pede = pede
	_aviso_ate = Time.get_ticks_msec() + ms
	if pede:
		# o menu espera: o START não começa uma partida por trás do aviso
		get_tree().paused = true


var _aviso_pede := false


func _fechar_aviso() -> void:
	if _aviso != null and is_instance_valid(_aviso):
		_aviso.queue_free()
	_aviso = null
	aviso_aberto = false
	_aviso_ate = 0
	get_tree().paused = false


## OK no controle (ControleTv) ou o tempo do aviso: abre a tela do Android.
func confirmar_aviso() -> void:
	if not aviso_aberto:
		return
	var pede := _aviso_pede
	_fechar_aviso()
	if not pede or _plugin == null:
		return
	_inicio_pediu = true
	_inicio_olhou = Time.get_ticks_msec() + 4000   # dá tempo de a tela do Android abrir
	var abriu := ""
	if _inicio_modo == "sobrepor":
		abriu = "sobrepor" if bool(_plugin.call("pedir_sobrepor")) else ""
		if abriu == "":
			_inicio_modo = "tela"
			abriu = str(_plugin.call("pedir_tela_inicial"))
			if abriu == "":
				abriu = str(_plugin.call("escolher_tela_inicial"))
	else:
		abriu = str(_plugin.call("pedir_tela_inicial"))
		if abriu == "" and int(inicio_estado().get("sdk", "0")) >= 29 and bool(_plugin.call("pedir_sobrepor")):
			_inicio_modo = "sobrepor"
			abriu = "sobrepor"
		if abriu == "":
			abriu = str(_plugin.call("escolher_tela_inicial"))
	print("ABRIR AO LIGAR: tela do Android aberta = ", abriu if abriu != "" else "nenhuma")


## IMAGEM LISA NA TV BOX: o jogo é desenhado em 720 linhas e a própria TV
## Box estica para a tela (1080p ou 4K). Sem isso uma caixa ligada em 4K
## desenharia 9 vezes mais pontos por quadro e o jogo arrastaria. As telas
## do jogo já se montam pelo tamanho da imagem (a partir de 1280 x 720).
## ALTURA_NA_TV = 0 desenha no tamanho da tela (mais nítido, mais pesado).
const ALTURA_NA_TV := 720


func _imagem_da_tv() -> void:
	if OS.get_name() != "Android" or ALTURA_NA_TV <= 0:
		return
	var janela := get_tree().root
	janela.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	janela.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	janela.content_scale_size = Vector2i(int(round(ALTURA_NA_TV * 16.0 / 9.0)), ALTURA_NA_TV)


## true = os comandos de LED passam por aqui (tudo que não é Windows).
func ativo() -> bool:
	return OS.get_name() != "Windows"


func tem_plugin() -> bool:
	return _plugin != null


## Firmware novo (sensores, botões e ficha pelo Arduino)?
func completo() -> bool:
	return conectado and firmware.begins_with("GOL_FLASH")


## As telas chamam ao abrir (no lugar de iniciar a ponte PowerShell).
func preparar() -> void:
	await get_tree().process_frame
	enviar("OFF")


## Mesmo texto que ia para a ponte PowerShell: "OFF" ou "SET:A=r,g,b;...".
func enviar(texto: String) -> void:
	var cmd := texto.strip_edges()
	if cmd == "" or cmd == "__EXIT__":
		return
	ultimo_comando = cmd
	_pendente = cmd


func _process(_delta: float) -> void:
	if _plugin == null:
		return
	var agora := Time.get_ticks_msec()
	_olhar_inicio(agora)
	match _fase:
		"procurando":
			if agora - _ultima_procura >= PROCURAR_MS:
				_ultima_procura = agora
				_procurar(agora)
		"abrindo":
			var e := str(_plugin.call("estado"))
			if e == "aberta":
				_fase = "aquecendo"
				_desde = agora
				_set_status("Arduino: aguardando a placa iniciar (%s)..." % chip)
			elif e == "erro" or e == "fechada" or agora - _desde > 8000:
				_falha(str(_plugin.call("erro")) if e == "erro" else "a porta USB não abriu")
		"aquecendo", "conectado":
			if str(_plugin.call("estado")) != "aberta":
				_perdeu(str(_plugin.call("erro")))
				return
			var texto := str(_plugin.call("ler"))
			if texto != "":
				for linha in texto.split("\n", false):
					_receber(linha.strip_edges().to_upper(), agora)
			if _fase == "aquecendo":
				if agora - _desde >= REINICIO_UNO_MS:
					_conectou()
				return
			# um comando por vez, com folga; o de LED mais novo substitui o velho
			if agora - _ultimo_tx >= ESPACO_MS:
				if _pendente != "":
					_escrever(_pendente, agora)
					_pendente = ""
				elif agora - _ultimo_ping >= PING_MS:
					_ultimo_ping = agora
					_escrever("PING", agora)
			if firmware != "" and agora - _ultimo_rx > SEM_RESPOSTA_MS:
				_perdeu("o Arduino parou de responder")


func _escrever(linha: String, agora: int) -> void:
	_ultimo_tx = agora
	_plugin.call("escrever", linha)


func _procurar(agora: int) -> void:
	var lista := str(_plugin.call("listar"))
	var sem_permissao := ""
	for linha in lista.split("\n", false):
		var p := linha.split("|")
		if p.size() < 4:
			continue
		if agora - int(_falhou.get(p[0], -100000)) < 10000:
			continue
		if p[3] == "1":
			_aparelho = p[0]
			chip = _nome_chip(p[2])
			_fase = "abrindo"
			_desde = agora
			_set_status("Arduino: abrindo o USB (%s)..." % chip)
			_plugin.call("abrir", _aparelho, BAUD)
			return
		if sem_permissao == "":
			sem_permissao = linha
	if sem_permissao != "":
		var p := sem_permissao.split("|")
		_set_status("Arduino no USB: aceite a janela do Android (marque \"Usar por padrão\" e OK)")
		if bool(_plugin.call("permissao_pendente")):
			return
		# sozinho, só uma vez por Arduino; depois, só pela Central da Máquina
		if _pedir_agora or not _ja_pediu(p[1]):
			_pedir_agora = false
			_marcar_pedido(p[1])
			_plugin.call("pedir_permissao", p[0])
		return
	if lista.strip_edges() == "":
		_set_status("Arduino não encontrado: confira o cabo USB")


func _nome_chip(t: String) -> String:
	return str({"ch34x": "CH340", "cdc": "USB original", "ftdi": "FTDI", "cp210x": "CP2102"}.get(t, t))


## A Central da Máquina pede a janela de permissão de novo.
func pedir_permissao_agora() -> void:
	if _plugin == null or conectado:
		return
	_pedir_agora = true
	_ultima_procura = -100000


func _ja_pediu(chave: String) -> bool:
	if _pedidos == null:
		_pedidos = ConfigFile.new()
		_pedidos.load(PERMISSOES)
	return bool(_pedidos.get_value("usb", chave, false))


func _marcar_pedido(chave: String) -> void:
	_ja_pediu(chave)
	_pedidos.set_value("usb", chave, true)
	_pedidos.save(PERMISSOES)


func _conectou() -> void:
	_fase = "conectado"
	conectado = true
	_falhou.clear()
	_ultimo_rx = Time.get_ticks_msec()
	_ultimo_ping = 0
	if firmware == "":
		_set_status("Arduino conectado (%s): LEDs OK" % chip)
	# reacende o que o jogo tinha pedido por último
	_pendente = ultimo_comando if ultimo_comando != "" else "OFF"
	mudou.emit()


func _falha(motivo: String) -> void:
	_falhou[_aparelho] = Time.get_ticks_msec()
	_plugin.call("fechar")
	_set_status("Arduino: %s" % motivo)
	_desconectar()


func _perdeu(motivo: String) -> void:
	_plugin.call("fechar")
	_set_status("Arduino desconectado (%s): procurando de novo" % (motivo if motivo != "" else "cabo USB"))
	_desconectar()


func _desconectar() -> void:
	var estava := conectado
	conectado = false
	firmware = ""
	_fase = "procurando"
	_ultima_procura = Time.get_ticks_msec()
	# botões que ficaram "apertados" soltam
	for acao in ["input_start", "input_cup"]:
		if InputMap.has_action(acao) and Input.is_action_pressed(acao):
			_acao(acao, false)
	if estava:
		mudou.emit()


func _receber(linha: String, agora: int) -> void:
	if linha == "":
		return
	_ultimo_rx = agora
	if linha.begins_with("OLA:") or linha.begins_with("PONG:"):
		var fw := linha.substr(linha.find(":") + 1)
		if fw != firmware:
			firmware = fw
			if fw.begins_with("GOL_FLASH"):
				_set_status("Arduino conectado (%s): LEDs, sensores, botões e ficha OK" % chip)
			mudou.emit()
		return
	if linha.begins_with("S:") or linha.begins_with("HIT:"):
		var letra := linha.substr(linha.find(":") + 1, 1)
		if LETRAS.has(letra):
			contagem[letra] = int(contagem[letra]) + 1
			_pulsar("input_led_" + letra.to_lower())
			sensor.emit(letra)
		return
	match linha:
		"B:START:1":
			_acao("input_start", true)
		"B:START:0":
			_acao("input_start", false)
		"B:SELECT:1":
			_acao("input_cup", true)
		"B:SELECT:0":
			_acao("input_cup", false)
		"FICHA":
			_pulsar("input_credit")


## O sensor/botão do Arduino vira a MESMA ação da placa Zero Delay.
func _acao(acao: String, apertou: bool) -> void:
	if not InputMap.has_action(acao):
		return
	var ev := InputEventAction.new()
	ev.action = acao
	ev.pressed = apertou
	Input.parse_input_event(ev)


func _pulsar(acao: String) -> void:
	_acao(acao, true)
	get_tree().create_timer(0.07, true, false, true).timeout.connect(_acao.bind(acao, false))


# ------------------------------------------------------------ abrir ao ligar
## O estado do "abrir ao ligar": {android, sdk, tela_inicial, sobrepor,
## ligou, ligou_vezes, root, adb, aparelho} ({} fora da TV).
func inicio_estado() -> Dictionary:
	var d := {}
	if _plugin == null:
		return d
	for linha in str(_plugin.call("inicio_relatorio")).split("\n", false):
		var k := linha.find("=")
		if k > 0:
			d[linha.substr(0, k)] = linha.substr(k + 1)
	return d


## O estado numa linha (Central da Máquina e avisos): é o que o suporte pede.
func texto_inicio() -> String:
	var d := inicio_estado()
	if d.is_empty():
		return ""
	var tela := str(d.get("tela_inicial", "?"))
	return "ANDROID %s (API %s)  •  TELA INICIAL: %s  •  SOBREPOR: %s  •  LIGOU: %sx  •  ROOT: %s  •  ADB: %s  •  %s" % [
		d.get("android", "?"), d.get("sdk", "?"), "O JOGO" if tela == "jogo" else tela.to_upper(),
		str(d.get("sobrepor", "?")).to_upper(), d.get("ligou_vezes", "0"),
		str(d.get("root", "")) if str(d.get("root", "")) != "" else "-",
		str(d.get("adb", "")) if str(d.get("adb", "")) != "" else "-", d.get("aparelho", "")]


## A TV já abre o jogo sozinha ao ligar?
func abre_sozinho() -> bool:
	var d := inicio_estado()
	if d.is_empty():
		return false
	return str(d.get("tela_inicial", "")) == "jogo" or (str(d.get("sobrepor", "")) != "nao" and int(d.get("ligou_vezes", "0")) > 0)


## Tenta de novo pelo root / adb da TV (sem nada na tela).
func preparar_sozinho() -> void:
	if _plugin != null:
		_plugin.call("preparar_sozinho")


## Abre a escolha da tela inicial do Android.
func escolher_tela_inicial() -> String:
	return str(_plugin.call("escolher_tela_inicial")) if _plugin != null else ""


## Abre "Sobrepor a outros apps" (Android 10+).
func pedir_sobrepor() -> bool:
	return _plugin != null and bool(_plugin.call("pedir_sobrepor"))


## Sai do jogo para a tela inicial da TV (saída do operador).
func sair_para_tv() -> String:
	return str(_plugin.call("sair_para_tv")) if _plugin != null else ""


func relatorio() -> String:
	var t := "%s\nfirmware: %s   chip: %s\n" % [status, firmware if firmware != "" else "-", chip if chip != "" else "-"]
	if _plugin != null:
		t += str(_plugin.call("relatorio"))
	return t


func _set_status(m: String) -> void:
	if m != status:
		status = m
		print("ARDUINO USB: ", m)
		mudou.emit()


func _exit_tree() -> void:
	if _plugin != null:
		_plugin.call("escrever", "OFF")
		_plugin.call("fechar")
