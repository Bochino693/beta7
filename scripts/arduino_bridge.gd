extends Node

## O ARDUINO DA MÁQUINA NA TV BOX / TV ANDROID (cabo USB direto na TV).
##
## No Windows nada muda: cada tela continua usando a ponte PowerShell na
## COM5, como sempre. Fora do Windows (TV Box, TV Android) os mesmos
## comandos das telas ("SET:A=255,0,0;B=..." e "OFF") passam por aqui e vão
## para o Arduino pelo plugin Android StrikeSerial (addons/StrikeSerial).
##
## Com o firmware novo (arduino/olho_no_lance) o Arduino também LÊ a
## máquina e manda para o jogo, então a placa Zero Delay não é necessária
## na TV Box:
##   Arduino -> jogo:  OLA:OLHO_NO_LANCE:1 / PONG:OLHO_NO_LANCE:1
##                     S:A ... S:G        (bola no alvo A..G)
##                     B:START:1 / B:START:0   (botão START apertou/soltou)
##                     B:SELECT:1 / B:SELECT:0 (botão SELECT/COPA)
##                     FICHA              (moedeiro / noteiro: 1 crédito)
##   jogo -> Arduino:  PING, OFF, SET:A=r,g,b;B=r,g,b...
##                     (SET acende os alvos da lista e apaga os outros)
## O firmware antigo (só LEDs) também funciona: os LEDs acendem, e os
## sensores continuam vindo pela placa Zero Delay.
##
## PERMISSÃO USB: o Android pergunta UMA vez ("Permitir que o Olho no
## Lance acesse o USB?"). Marque "Usar por padrão / Sempre" e OK: nunca mais
## aparece, nem depois de desligar a TV.

signal mudou
signal sensor(letra: String)

const BAUD := 9600
const LETRAS := ["A", "B", "C", "D", "E", "F", "G"]
const REPETIR_MS := 700
const ESPACO_MS := 35            # entre dois comandos (o Arduino fica surdo enquanto acende a fita)
const PING_MS := 2000
const PROCURAR_MS := 1500
const REINICIO_UNO_MS := 2300    # o Uno reinicia ao abrir a porta
const SEM_RESPOSTA_MS := 7000
const PERMISSOES := "user://permissoes_usb.cfg"

var status := "Arduino: iniciando..."
var conectado := false
var firmware := ""               # "OLHO_NO_LANCE:1" (novo) ou "" (antigo, só LEDs)
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
var _ultimo_led := 0
var fita := ""                    # resposta do CFG? ("ORDEM=0;LEDS=64")
var _ultima_procura := -100000
var _pendente := ""              # comando de LED esperando a vez (o último vale)
var _falhou := {}
var _pedir_agora := false
var _pedidos: ConfigFile


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_carimbo()
	for l in LETRAS:
		contagem[l] = 0
	_carregar_entradas()
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
## a tela do Android e você escolhe OLHO NO LANCE como tela inicial
## ("Sempre"). É o caminho que o próprio Android usa para abrir um app ao
## ligar: nenhuma ROM bloqueia. Aceito, nunca mais pede. Não aceito, pede de
## novo nas próximas aberturas (no máximo MAX_PEDIDOS; depois, só pela
## Central da Máquina). No Android 10+ a segunda tentativa pede "Sobrepor a
## outros apps" (para a caixa que não deixa trocar a tela inicial).
const ESPERA_INICIO_MS := 9000
const MAX_PEDIDOS := 6
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
	return int(d.get("sdk", "0")) >= 29 and str(d.get("sobrepor", "")) == "sim"


## O QUE AINDA FALTA PEDIR (no máximo um pedido por abertura do jogo):
##  - Android 10+: 1o "Sobrepor a outros apps" (até 3 vezes). É o que faz o
##    jogo vir para a frente ao ligar DE QUALQUER JEITO, mesmo que o Android
##    mostre a escolha da tela inicial; depois, a tela inicial (até 2 vezes).
##  - Android 9 ou mais antigo: a tela inicial (até 4 vezes).
## Com as duas coisas feitas (ou as tentativas gastas) nunca mais pede nada,
## nem se o Android desfizer alguma coisa depois: aí é pela Central da Máquina.
func _o_que_falta(d: Dictionary, cfg: ConfigFile) -> String:
	var novo: bool = int(d.get("sdk", "0")) >= 29
	if novo and str(d.get("sobrepor", "")) == "nao" and int(cfg.get_value("inicio", "ped_sobrepor", 0)) < 3:
		return "sobrepor"
	if str(d.get("tela_inicial", "")) != "jogo" and int(cfg.get_value("inicio", "ped_tela", 0)) < (2 if novo else 4):
		return "tela"
	return ""


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
	if d.is_empty():
		return
	var cfg := ConfigFile.new()
	cfg.load(PERMISSOES)
	if _carimbo_label != null:
		_carimbo_inicio = "Android %s  •  tela inicial: %s  •  sobrepor: %s" % [d.get("android", "?"),
			"JOGO" if str(d.get("tela_inicial", "")) == "jogo" else "NÃO", str(d.get("sobrepor", "?")).to_upper()]
	if _inicio_pediu:
		# voltou da tela do Android: um pedido por abertura, sem insistir
		_inicio_resolvido = true
		if _o_que_falta(d, cfg) == "" and not bool(cfg.get_value("inicio", "avisou_pronto2", false)):
			cfg.set_value("inicio", "avisou_pronto2", true)
			cfg.save(PERMISSOES)
			_pedidos = null
			_mostrar_aviso("PRONTO!", "O jogo vai abrir sozinho sempre que a TV Box ligar.", "", 5000, false)
		return
	_inicio_modo = _o_que_falta(d, cfg)
	if _inicio_modo == "":
		_inicio_resolvido = true
		return
	var chave := "ped_sobrepor" if _inicio_modo == "sobrepor" else "ped_tela"
	cfg.set_value("inicio", chave, int(cfg.get_value("inicio", chave, 0)) + 1)
	cfg.save(PERMISSOES)
	_pedidos = null
	_mostrar_passos(_inicio_modo, 20000)


const COR_AVISO := Color(0.30, 1.0, 0.50)
const COR_DESTAQUE := Color(1.0, 0.84, 0.10)
const FONTE_TITULO := "res://fonts/BarlowCondensed-ExtraBoldItalic.ttf"


## Base de todo aviso: fundo escuro + cartão que entra com um pulo. Devolve o
## cartão (um Control do tamanho pedido, em pontos de uma tela 1280 x 720).
func _cartao_do_aviso(largura: float, altura: float, cor: Color) -> Control:
	_fechar_aviso()
	_aviso = CanvasLayer.new()
	_aviso.layer = 120
	_aviso.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_aviso)
	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.0, 0.02, 0.06, 0.62)
	_aviso.add_child(fundo)
	var tela := get_viewport().get_visible_rect().size
	var k: float = minf(tela.x / 1280.0, tela.y / 720.0)
	var cartao := Panel.new()
	cartao.size = Vector2(largura, altura)
	cartao.scale = Vector2(k, k)
	cartao.position = (tela - cartao.size * k) * 0.5
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.035, 0.065, 0.11, 0.98)
	st.border_color = Color(cor.r, cor.g, cor.b, 0.9)
	st.set_border_width_all(2)
	st.set_corner_radius_all(30)
	st.shadow_color = Color(cor.r, cor.g, cor.b, 0.28)
	st.shadow_size = 22
	st.anti_aliasing = true
	cartao.add_theme_stylebox_override("panel", st)
	_aviso.add_child(cartao)
	# entrada: o fundo surge e o cartão dá um pulo curto
	fundo.modulate.a = 0.0
	cartao.pivot_offset = cartao.size * 0.5
	cartao.modulate.a = 0.0
	var alvo := cartao.scale
	cartao.scale = alvo * 0.88
	var tw := _aviso.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(fundo, "modulate:a", 1.0, 0.22)
	tw.tween_property(cartao, "modulate:a", 1.0, 0.22)
	tw.tween_property(cartao, "scale", alvo, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return cartao


func _texto(pai: Control, txt: String, tam: int, cor: Color, pos: Vector2, tamanho: Vector2, titulo := false) -> Label:
	var l := Label.new()
	l.text = txt
	l.position = pos
	l.size = tamanho
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	if titulo and ResourceLoader.exists(FONTE_TITULO):
		l.add_theme_font_override("font", load(FONTE_TITULO))
	pai.add_child(l)
	return l


func _pilula(pai: Control, pos: Vector2, tamanho: Vector2, fundo: Color, borda: Color, raio := -1) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = tamanho
	var st := StyleBoxFlat.new()
	st.bg_color = fundo
	st.border_color = borda
	st.set_border_width_all(2 if borda.a > 0.0 else 0)
	st.set_corner_radius_all(int(tamanho.y * 0.5) if raio < 0 else raio)
	st.anti_aliasing = true
	p.add_theme_stylebox_override("panel", st)
	pai.add_child(p)
	return p


func _depois_do_aviso(pede: bool, ms: int) -> void:
	var diag := texto_inicio()
	if diag != "" and _aviso != null:
		var ld := Label.new()
		ld.text = diag
		ld.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		ld.position.y -= 26
		ld.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ld.add_theme_font_size_override("font_size", 12)
		ld.add_theme_color_override("font_color", Color(0.45, 0.55, 0.68, 0.7))
		_aviso.add_child(ld)
	aviso_aberto = true
	_aviso_pede = pede
	_aviso_ate = Time.get_ticks_msec() + ms
	if pede:
		# o menu espera: o START não começa uma partida por trás do aviso
		get_tree().paused = true


## Aviso simples (PRONTO!, APK incompleto): título, texto e some sozinho.
func _mostrar_aviso(titulo: String, texto: String, rodape: String, ms: int, pede: bool) -> void:
	var certo: bool = titulo.begins_with("PRONTO")
	var cor: Color = COR_AVISO if certo else COR_DESTAQUE
	var cartao := _cartao_do_aviso(820.0, 330.0, cor)
	if certo:
		# o "visto" verde
		var bola := _pilula(cartao, Vector2(370, 28), Vector2(80, 80), Color(cor.r, cor.g, cor.b, 0.18), cor)
		_texto(bola, "✓", 50, cor, Vector2.ZERO, bola.size)
	_texto(cartao, titulo, 54, cor, Vector2(30, 112 if certo else 30), Vector2(760, 66), true)
	_texto(cartao, texto, 25, Color.WHITE, Vector2(40, 184 if certo else 108), Vector2(740, 120 if certo else 190))
	if rodape != "":
		_texto(cartao, rodape, 22, COR_AVISO, Vector2(40, 282), Vector2(740, 34))
	_depois_do_aviso(pede, ms)


## O PEDIDO, PASSO A PASSO E COM DESENHO, para qualquer pessoa entender:
## 1 aperte OK, 2 o que fazer na tela do Android, 3 como voltar.
func _mostrar_passos(modo: String, ms: int) -> void:
	var cartao := _cartao_do_aviso(1060.0, 560.0, COR_AVISO)
	var etiqueta := _pilula(cartao, Vector2(330, 26), Vector2(400, 34), Color(COR_DESTAQUE.r, COR_DESTAQUE.g, COR_DESTAQUE.b, 0.14), Color(COR_DESTAQUE.r, COR_DESTAQUE.g, COR_DESTAQUE.b, 0.7))
	_texto(etiqueta, "AJUSTE INICIAL  •  SÓ DESTA VEZ", 17, COR_DESTAQUE, Vector2.ZERO, etiqueta.size)
	_texto(cartao, "FAÇA O JOGO ABRIR SOZINHO", 58, Color.WHITE, Vector2(30, 66), Vector2(1000, 70), true)
	_texto(cartao, "Depois disso, é só ligar a TV Box: o jogo abre direto.", 22, Color(0.72, 0.80, 0.90), Vector2(30, 134), Vector2(1000, 32))

	var legendas: Array
	if modo == "sobrepor":
		legendas = ["Aperte OK\nno controle", "Na tela que abrir,\nLIGUE a chave do\nOLHO NO LANCE", "Aperte VOLTAR\nno controle"]
	else:
		legendas = ["Aperte OK\nno controle", "Na tela que abrir,\nescolha\nOLHO NO LANCE", "Se aparecer,\nmarque SEMPRE"]
	var lw := 300.0
	for i in range(3):
		var x := 50.0 + i * (lw + 30.0)
		var col := _pilula(cartao, Vector2(x, 186), Vector2(lw, 262), Color(0.06, 0.10, 0.17, 1.0), Color(0.30, 0.45, 0.65, 0.35), 22)
		var num := _pilula(col, Vector2(16, 14), Vector2(46, 46), COR_AVISO, Color(0, 0, 0, 0))
		_texto(num, str(i + 1), 30, Color(0.02, 0.08, 0.04), Vector2.ZERO, num.size, true)
		var desenho := Control.new()
		desenho.position = Vector2(0, 34)
		desenho.size = Vector2(lw, 120)
		col.add_child(desenho)
		if i == 0:
			_desenhar_botao(desenho, "OK")
		elif i == 1:
			_desenhar_tela_android(desenho, modo)
		elif modo == "sobrepor":
			_desenhar_botao(desenho, "VOLTAR")
		else:
			_desenhar_sempre(desenho)
		_texto(col, str(legendas[i]), 23, Color.WHITE, Vector2(10, 160), Vector2(lw - 20, 94))
		# as colunas entram uma depois da outra
		col.modulate.a = 0.0
		var tw := _aviso.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_interval(0.18 + 0.12 * i)
		tw.tween_property(col, "modulate:a", 1.0, 0.25)

	# o botão de continuar pulsa; a barra mostra o tempo até continuar sozinho
	var botao := _pilula(cartao, Vector2(330, 470), Vector2(400, 58), COR_AVISO, Color(0, 0, 0, 0))
	_texto(botao, "APERTE  OK  PARA CONTINUAR", 26, Color(0.02, 0.10, 0.04), Vector2.ZERO, botao.size, true)
	botao.pivot_offset = botao.size * 0.5
	var pulso := _aviso.create_tween()
	pulso.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	pulso.set_loops()
	pulso.tween_property(botao, "scale", Vector2(1.05, 1.05), 0.55).set_trans(Tween.TRANS_SINE)
	pulso.tween_property(botao, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE)
	var trilho := _pilula(cartao, Vector2(330, 538), Vector2(400, 6), Color(1, 1, 1, 0.10), Color(0, 0, 0, 0))
	var tempo := _pilula(trilho, Vector2.ZERO, Vector2(400, 6), Color(COR_AVISO.r, COR_AVISO.g, COR_AVISO.b, 0.8), Color(0, 0, 0, 0))
	var tt := _aviso.create_tween()
	tt.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tt.tween_property(tempo, "size:x", 0.0, ms / 1000.0)
	_depois_do_aviso(true, ms)


## Um botão do controle remoto (redondo, com o nome dentro), "apertando".
func _desenhar_botao(pai: Control, nome: String) -> void:
	var lado := 96.0 if nome == "OK" else 92.0
	var larg := lado if nome == "OK" else 170.0
	var anel := _pilula(pai, Vector2((pai.size.x - larg - 16) * 0.5, (pai.size.y - lado - 16) * 0.5 + 6), Vector2(larg + 16, lado + 16), Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.20))
	var b := _pilula(anel, Vector2(8, 8), Vector2(larg, lado), Color(0.92, 0.95, 1.0), Color(0, 0, 0, 0))
	_texto(b, nome, 34 if nome == "OK" else 30, Color(0.05, 0.08, 0.14), Vector2.ZERO, b.size, true)
	b.pivot_offset = b.size * 0.5
	var tw := _aviso.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_loops()
	tw.tween_interval(0.5)
	tw.tween_property(b, "scale", Vector2(0.86, 0.86), 0.12)
	tw.tween_property(b, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.7)


## A tela do Android em miniatura: a linha do jogo com a chave ligando
## (sobrepor) ou a lista de telas iniciais com o jogo escolhido (tela).
func _desenhar_tela_android(pai: Control, modo: String) -> void:
	var w := pai.size.x - 40.0
	var tela := _pilula(pai, Vector2(20, 14), Vector2(w, 104), Color(0.10, 0.12, 0.16), Color(1, 1, 1, 0.18), 12)
	if modo == "sobrepor":
		var outra := _pilula(tela, Vector2(8, 8), Vector2(w - 16, 38), Color(1, 1, 1, 0.04), Color(0, 0, 0, 0), 8)
		_texto(outra, "Outro app", 16, Color(1, 1, 1, 0.35), Vector2(10, 0), Vector2(140, 38)).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_pilula(outra, Vector2(w - 16 - 54, 10), Vector2(42, 18), Color(1, 1, 1, 0.14), Color(0, 0, 0, 0))
		var linha := _pilula(tela, Vector2(8, 54), Vector2(w - 16, 42), Color(COR_AVISO.r, COR_AVISO.g, COR_AVISO.b, 0.12), Color(COR_AVISO.r, COR_AVISO.g, COR_AVISO.b, 0.8), 8)
		_texto(linha, "Olho no Lance", 18, Color.WHITE, Vector2(10, 0), Vector2(160, 42)).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var chave := _pilula(linha, Vector2(w - 16 - 62, 9), Vector2(50, 24), Color(1, 1, 1, 0.20), Color(0, 0, 0, 0))
		var pino := _pilula(chave, Vector2(3, 3), Vector2(18, 18), Color.WHITE, Color(0, 0, 0, 0))
		var st: StyleBoxFlat = chave.get_theme_stylebox("panel")
		var tw := _aviso.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.set_loops()
		tw.tween_interval(0.7)
		tw.tween_property(pino, "position:x", 29.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(st, "bg_color", COR_AVISO, 0.22)
		tw.tween_interval(1.1)
		tw.tween_property(pino, "position:x", 3.0, 0.01)
		tw.parallel().tween_property(st, "bg_color", Color(1, 1, 1, 0.20), 0.01)
	else:
		var outra := _pilula(tela, Vector2(8, 8), Vector2(w - 16, 38), Color(1, 1, 1, 0.04), Color(0, 0, 0, 0), 8)
		_texto(outra, "Tela da TV", 16, Color(1, 1, 1, 0.35), Vector2(10, 0), Vector2(160, 38)).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var linha := _pilula(tela, Vector2(8, 54), Vector2(w - 16, 42), Color(COR_AVISO.r, COR_AVISO.g, COR_AVISO.b, 0.12), Color(COR_AVISO.r, COR_AVISO.g, COR_AVISO.b, 0.9), 8)
		_texto(linha, "Olho no Lance", 18, Color.WHITE, Vector2(10, 0), Vector2(170, 42)).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_texto(linha, "✓", 24, COR_AVISO, Vector2(w - 16 - 44, 0), Vector2(36, 42))
		var tw := _aviso.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.set_loops()
		tw.tween_property(linha, "modulate:a", 0.55, 0.5)
		tw.tween_property(linha, "modulate:a", 1.0, 0.5)


## Os dois botões da janela do Android: "Só uma vez" apagado, "SEMPRE" aceso.
func _desenhar_sempre(pai: Control) -> void:
	var a := _pilula(pai, Vector2(24, 44), Vector2(118, 44), Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.18), 10)
	_texto(a, "Só uma vez", 16, Color(1, 1, 1, 0.38), Vector2.ZERO, a.size)
	var b := _pilula(pai, Vector2(156, 40), Vector2(122, 52), COR_AVISO, Color(0, 0, 0, 0), 10)
	_texto(b, "SEMPRE", 24, Color(0.02, 0.10, 0.04), Vector2.ZERO, b.size, true)
	b.pivot_offset = b.size * 0.5
	var tw := _aviso.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_loops()
	tw.tween_property(b, "scale", Vector2(1.10, 1.10), 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_property(b, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)


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


## A VERSÃO NA TELA (canto de baixo, discreta): para saber qual APK está na
## TV Box. Mude a cada APK entregue.
const VERSAO := "TV 15"
var _carimbo_label: Label
var _carimbo_inicio := ""
var _carimbo_em := 0


func _carimbo() -> void:
	if OS.get_name() != "Android":
		return
	var camada := CanvasLayer.new()
	camada.layer = 119
	add_child(camada)
	_carimbo_label = Label.new()
	_carimbo_label.text = VERSAO
	_carimbo_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_carimbo_label.position = Vector2(8, -24)
	_carimbo_label.add_theme_font_size_override("font_size", 13)
	_carimbo_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	_carimbo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(_carimbo_label)


## true = os comandos de LED passam por aqui (tudo que não é Windows).
func ativo() -> bool:
	return OS.get_name() != "Windows"


func tem_plugin() -> bool:
	return _plugin != null


## O firmware deste jogo: OLHO_NO_LANCE (o nome de hoje) ou GOL_FLASH (o
## mesmo código, com o nome antigo - um Arduino já gravado continua valendo).
func _firmware_do_jogo(fw: String) -> bool:
	return fw.begins_with("OLHO_NO_LANCE") or fw.begins_with("GOL_FLASH")


## Firmware novo (sensores, botões e ficha pelo Arduino)?
func completo() -> bool:
	return conectado and _firmware_do_jogo(firmware)


## As telas chamam ao abrir (no lugar de iniciar a ponte PowerShell).
func preparar() -> void:
	await get_tree().process_frame
	enviar("OFF")


## Mesmo texto que ia para a ponte PowerShell: "OFF" ou "SET:A=r,g,b;...".
func enviar(texto: String) -> void:
	var cmd := texto.strip_edges()
	if cmd == "" or cmd == "__EXIT__":
		return
	if cmd.begins_with("ORDEM:") or cmd == "CFG?":
		if _plugin != null and _fase == "conectado":
			_escrever(cmd, Time.get_ticks_msec())
		return
	ultimo_comando = cmd
	_pendente = cmd


func _process(_delta: float) -> void:
	var agora := Time.get_ticks_msec()
	# o carimbo do canto: versão, placa de vídeo, quadros por segundo e nível
	if _carimbo_label != null and agora - _carimbo_em >= 2000:
		_carimbo_em = agora
		_carimbo_label.text = "%s  •  %s%s" % [VERSAO, Visual.texto(), ("  •  " + _carimbo_inicio) if _carimbo_inicio != "" else ""]
	if _plugin == null:
		return
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
					_ultimo_led = agora
				elif ultimo_comando != "" and agora - _ultimo_led >= REPETIR_MS:
					# repete o último comando de LED: se o Arduino perdeu um
					# (estava ocupado acendendo a fita), ele se acerta sozinho
					_ultimo_led = agora
					_escrever(ultimo_comando, agora)
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
			if _firmware_do_jogo(fw):
				_set_status("Arduino conectado (%s): LEDs, sensores, botões e ficha OK" % chip)
			mudou.emit()
		return
	if linha.begins_with("CFG:"):
		fita = linha.substr(4)
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


## A ordem das cores da fita de LED (0..5), guardada no Arduino. Vale no PC
## também: a Central da Máquina manda "ORDEM:n" pelo mesmo caminho dos LEDs.
func ordem_da_fita() -> int:
	var k := fita.find("ORDEM=")
	return int(fita.substr(k + 6, 1)) if k >= 0 else -1


# ------------------------------------------------------- entradas ensinadas
## A PLACA ZERO DELAY NA TV BOX: o Android numera os botões dela de um jeito
## diferente do Windows, então os sensores e os botões "trocam de lugar". Na
## Central da Máquina, "ENSINAR SENSORES E BOTÕES" pede cada um na ordem
## (alvo A...G, START, SELECT) e guarda aqui qual botão é qual. Vale só para
## este aparelho (user://entradas.cfg) e não mexe no que já funciona no PC.
const ARQUIVO_ENTRADAS := "user://entradas.cfg"
const ENTRADAS: Array[String] = ["input_led_a", "input_led_b", "input_led_c", "input_led_d", "input_led_e", "input_led_f", "input_led_g", "input_start", "input_cup"]
var tem_mapa := false
var ensinando := false            # a Central da Máquina está pedindo os botões


func _carregar_entradas() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(ARQUIVO_ENTRADAS) != OK:
		return
	for acao in ENTRADAS:
		var v: String = str(cfg.get_value("entradas", acao, ""))
		var ev := _evento_de(v)
		if ev == null or not InputMap.has_action(acao):
			continue
		InputMap.action_erase_events(acao)
		InputMap.action_add_event(acao, ev)
		tem_mapa = true


## "b:7" botão de joystick, "e:5:1" eixo (número e lado), "t:65" tecla.
func _evento_de(v: String) -> InputEvent:
	var p := v.split(":")
	if p.size() >= 2 and p[0] == "b":
		var b := InputEventJoypadButton.new()
		b.device = -1
		b.button_index = int(p[1]) as JoyButton
		return b
	if p.size() >= 3 and p[0] == "e":
		var e := InputEventJoypadMotion.new()
		e.device = -1
		e.axis = int(p[1]) as JoyAxis
		e.axis_value = float(p[2])
		return e
	if p.size() >= 2 and p[0] == "t":
		var t := InputEventKey.new()
		t.keycode = int(p[1]) as Key
		return t
	return null


## O texto que guarda este aperto ("" = não serve para ensinar).
func texto_do_evento(ev: InputEvent) -> String:
	if ev is InputEventJoypadButton and ev.pressed:
		return "b:%d" % ev.button_index
	if ev is InputEventJoypadMotion and absf(ev.axis_value) > 0.6:
		return "e:%d:%d" % [ev.axis, 1 if ev.axis_value > 0.0 else -1]
	if ev is InputEventKey and ev.pressed and not ev.echo and not (ev.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_BACK, KEY_ESCAPE, KEY_MENU, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_F9]):
		return "t:%d" % ev.keycode
	return ""


func guardar_entradas(mapa: Dictionary) -> void:
	var cfg := ConfigFile.new()
	for acao in mapa:
		cfg.set_value("entradas", acao, mapa[acao])
	cfg.save(ARQUIVO_ENTRADAS)
	_carregar_entradas()


func esquecer_entradas() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ARQUIVO_ENTRADAS))
	tem_mapa = false
	InputMap.load_from_project_settings()


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
