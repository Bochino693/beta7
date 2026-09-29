extends Node

## ARDUINO NANO DA MÁQUINA, pela USB da TV Box (Android 7.1).
##
## O Nano faz tudo: acende os 7 alvos (NeoPixel), lê os 7 sensores e os
## botões START e SELECT (arduino/gol_flash_arena_nano). A Zero Delay não é
## mais usada.
##
## ENTRADAS: cada mensagem do Nano vira a MESMA ação do Input Map que a
## Zero Delay gerava — o resto do jogo não muda nada:
##   HIT:A..G        -> input_led_a..g (um toque: aperta e solta)
##   BTN:START:1/0   -> input_start apertado / solto
##   BTN:SELECT:1/0  -> input_cup   (o SELECT do jogo)
##   BTN:CREDIT:1/0  -> input_credit (moedeiro opcional no A5)
##
## LEDS: as telas continuam mandando "SET:A=r,g,b;B=..." e "OFF" por
## Arduino.enviar(). Aqui isso vira UM quadro com os 7 alvos,
## "C:" + 3 dígitos hexa por alvo (23 caracteres: cabe no limite de 32 do
## plugin USB). Vai um quadro por vez, esperando o OK do Nano (enquanto
## desenha os LEDs ele não lê a serial); se chegarem vários no meio tempo,
## só o mais novo é mandado.
##
## CONEXÃO: procura o Arduino a cada 1,5 s, abre a 115200, espera o
## READY/PONG e mantém um PING a cada 2,5 s. Cabo solto ou Nano mudo por
## 7,5 s: reconecta sozinho. No PC (sem o plugin) nada disso roda: o
## teclado faz o papel do Nano (ver project.godot).

signal conectado_mudou(conectado, texto)

const BAUD := 115200
const PING_MS := 2500
const MUDO_MS := 7500
const PROCURAR_MS := 1500
const APERTO_DE_MAO_MS := 5000
const ESPERA_OK_MS := 150
const LETRAS := ["A", "B", "C", "D", "E", "F", "G"]
const ACAO_BOTAO := {
	"START": "input_start",
	"SELECT": "input_cup",
	"CREDIT": "input_credit",
}

var conectado := false
var status := "Procurando o Arduino..."
var aparelho := ""

var _plugin: Object = null
var _candidatos := PoolStringArray()
var _indice := 0
var _ultima_procura := -100000
var _ultimo_rx := 0
var _ultimo_ping := 0
var _aberto_em := 0

## LEDs: o que o jogo pediu (7 cores) e o que já foi para o Nano.
var _cores := []
var _quadro_enviado := ""
var _quadro_pendente := ""
var _esperando_ok_desde := -1

## Toques dos sensores para soltar no quadro seguinte.
var _soltar := []


func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS
	for _i in range(LETRAS.size()):
		_cores.append([0, 0, 0])
	if OS.get_name() != "Android":
		status = "PC: teclado no lugar do Arduino"
		return
	if not Engine.has_singleton("DragonUsbSerial"):
		status = "Plugin USB ausente no APK"
		push_warning(status)
		return
	_plugin = Engine.get_singleton("DragonUsbSerial")


func _process(_delta: float) -> void:
	# Solta os sensores tocados no quadro anterior.
	if not _soltar.empty():
		for acao in _soltar:
			_injetar(acao, false)
		_soltar.clear()
	if _plugin == null:
		return
	var agora := OS.get_ticks_msec()
	if not bool(_plugin.call("isOpen")):
		if conectado:
			_desconectar("Arduino desligado; procurando de novo")
		if agora - _ultima_procura > PROCURAR_MS:
			_procurar()
		return
	var linhas: String = str(_plugin.call("pollLines"))
	for linha in linhas.split("\n", false):
		_receber(linha.strip_edges().to_upper(), agora)
	if not conectado:
		if agora - _aberto_em > APERTO_DE_MAO_MS:
			_plugin.call("closePort")
			_tentar_proximo()
		elif agora - _ultimo_ping > 600:
			_plugin.call("writeLine", "PING")
			_ultimo_ping = agora
		return
	if agora - _ultimo_rx > MUDO_MS:
		_desconectar("Arduino sem resposta; reconectando")
		return
	_despachar_leds(agora)
	if _esperando_ok_desde < 0 and agora - _ultimo_ping > PING_MS:
		_plugin.call("writeLine", "PING")
		_ultimo_ping = agora


# ---------------------------------------------------------------- LEDs
## Recebe os comandos das telas: "SET:A=255,0,0;C=0,0,255" (os listados
## acendem, o resto apaga) ou "OFF". Sem Arduino, só guarda o estado.
func enviar(comando: String) -> void:
	var cmd := comando.strip_edges().to_upper()
	if cmd == "" or cmd == "__EXIT__":
		return
	var novas := []
	for _i in range(LETRAS.size()):
		novas.append([0, 0, 0])
	if cmd.begins_with("SET:"):
		for item in cmd.substr(4).split(";", false):
			var partes = item.strip_edges().split("=", false)
			if partes.size() != 2:
				continue
			var i := LETRAS.find(partes[0].strip_edges())
			var rgb = partes[1].split(",", false)
			if i < 0 or rgb.size() != 3:
				continue
			novas[i] = [int(clamp(int(rgb[0]), 0, 255)), int(clamp(int(rgb[1]), 0, 255)), int(clamp(int(rgb[2]), 0, 255))]
	elif cmd != "OFF":
		push_warning("Comando de LED desconhecido: " + cmd)
		return
	_cores = novas
	_quadro_pendente = quadro_compacto(_cores)


## "C:" + R G B de cada alvo em hexa de 0 a F (0..255 -> 0..15).
static func quadro_compacto(cores: Array) -> String:
	var t := "C:"
	for c in cores:
		for canal in c:
			t += "%X" % int(round(clamp(float(canal), 0.0, 255.0) / 17.0))
	return t


func cores_atuais() -> Array:
	return _cores.duplicate(true)


func _despachar_leds(agora: int) -> void:
	if _quadro_pendente == "" or _quadro_pendente == _quadro_enviado:
		_quadro_pendente = ""
		return
	if _esperando_ok_desde >= 0 and agora - _esperando_ok_desde < ESPERA_OK_MS:
		return
	_plugin.call("writeLine", _quadro_pendente)
	_quadro_enviado = _quadro_pendente
	_quadro_pendente = ""
	_esperando_ok_desde = agora


# ------------------------------------------------------------ entradas
func _receber(linha: String, agora: int) -> void:
	if linha == "":
		return
	_ultimo_rx = agora
	if linha.begins_with("READY:GOL_FLASH") or linha.begins_with("PONG:GOL_FLASH"):
		if not conectado:
			conectado = true
			status = "Arduino conectado"
			_quadro_enviado = ""
			_quadro_pendente = quadro_compacto(_cores)
			_esperando_ok_desde = -1
			emit_signal("conectado_mudou", true, status)
		return
	if not conectado:
		return
	if linha.begins_with("OK:"):
		_esperando_ok_desde = -1
		return
	if linha.begins_with("ERR:"):
		# Quadro perdido: manda o estado atual de novo.
		_esperando_ok_desde = -1
		_quadro_enviado = ""
		_quadro_pendente = quadro_compacto(_cores)
		return
	if linha.begins_with("HIT:") and linha.length() >= 5:
		var letra := linha.substr(4, 1)
		if LETRAS.has(letra):
			var acao := "input_led_" + letra.to_lower()
			_injetar(acao, true)
			_soltar.append(acao)
		return
	if linha.begins_with("BTN:"):
		var partes := linha.split(":")
		if partes.size() == 3 and ACAO_BOTAO.has(partes[1]):
			_injetar(ACAO_BOTAO[partes[1]], partes[2] == "1")


func _injetar(acao: String, apertado: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = acao
	ev.pressed = apertado
	Input.parse_input_event(ev)


# ------------------------------------------------------------- conexão
func _procurar() -> void:
	_ultima_procura = OS.get_ticks_msec()
	_candidatos = PoolStringArray(str(_plugin.call("listPorts")).split("\n", false))
	_indice = 0
	if _candidatos.empty():
		status = "Arduino não encontrado: confira o cabo USB"
		return
	_tentar_proximo()


func _tentar_proximo() -> void:
	while _indice < _candidatos.size():
		var porta: String = _candidatos[_indice]
		_indice += 1
		status = "Conectando no Arduino..."
		if bool(_plugin.call("openPort", porta, BAUD)):
			aparelho = porta
			_aberto_em = OS.get_ticks_msec()
			_ultimo_ping = 0
			return
		status = str(_plugin.call("getLastError"))
	_ultima_procura = OS.get_ticks_msec()


func _desconectar(motivo: String) -> void:
	var estava := conectado
	conectado = false
	aparelho = ""
	_esperando_ok_desde = -1
	_quadro_enviado = ""
	if _plugin != null:
		_plugin.call("closePort")
	status = motivo
	# Botões que estavam apertados não podem ficar presos.
	for acao in ACAO_BOTAO.values():
		if Input.is_action_pressed(acao):
			_injetar(acao, false)
	if estava:
		emit_signal("conectado_mudou", false, status)
	_ultima_procura = 0


func _exit_tree() -> void:
	if _plugin != null and bool(_plugin.call("isOpen")):
		_plugin.call("writeLine", "OFF")
		_plugin.call("closePort")
