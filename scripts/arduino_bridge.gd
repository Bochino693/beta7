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
		return
	_plugin = Engine.get_singleton("StrikeSerial")
	_pedir_abrir_sozinho_uma_vez()


## ABRIR SOZINHO DEPOIS QUE A TV LIGA (a tela da ROM abre e o jogo entra por
## cima; o jogo NÃO vira a tela inicial da TV). Até o Android 9 não precisa
## de nada. No Android 10+ o sistema pede a permissão "aparecer sobre outros
## apps": na primeira vez que o jogo abre, a tela dessa permissão aparece
## UMA vez (ligue a chave do Gol Flash Arena e aperte VOLTAR). De novo, só
## pela Central da Máquina. Com o Arduino no USB e "Usar por padrão"
## marcado, o Android já abre o jogo sozinho mesmo sem ela.
func _pedir_abrir_sozinho_uma_vez() -> void:
	await get_tree().create_timer(12.0, true, false, true).timeout
	if pode_abrir_sozinho():
		return
	var cfg := ConfigFile.new()
	cfg.load(PERMISSOES)
	if bool(cfg.get_value("inicio", "ja_pediu_abrir", false)):
		return
	# uma janela do Android por vez: espera a do USB fechar
	while bool(_plugin.call("permissao_pendente")):
		await get_tree().create_timer(2.0, true, false, true).timeout
	cfg.set_value("inicio", "ja_pediu_abrir", true)
	cfg.save(PERMISSOES)
	_pedidos = null
	print("ABRIR SOZINHO: pedindo a permissão ao Android (", pedir_abrir_sozinho(), ")")


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
## O Android deixa o jogo abrir sozinho depois que a TV liga?
func pode_abrir_sozinho() -> bool:
	return _plugin != null and bool(_plugin.call("pode_abrir_sozinho"))


## Abre a tela da permissão do Android: "ja", "permissao", "app" ou "".
func pedir_abrir_sozinho() -> String:
	return str(_plugin.call("pedir_abrir_sozinho")) if _plugin != null else ""


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
