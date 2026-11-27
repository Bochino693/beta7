extends Node2D

## CENTRAL DA MÁQUINA (F9 / tecla MENU / botão ⚙ com o mouse).
##
## Uma tela só, com o que o operador usa de verdade:
##   1. ARCADE E COPA      - LIVRE ou CRÉDITO (um toque troca)
##   2. DADOS DA MÁQUINA   - partidas de arcade, copa e evento, jogadores
##                           cadastrados; EVENTOS E DADOS abre a janela que
##                           cria / usa / apaga eventos e descarrega no pendrive
##   3. TESTE DOS ALVOS    - acende o LED e mostra o sensor
##   embaixo               - partidas jogadas, AJUSTES AVANÇADOS e VOLTAR
## O que se usa uma vez na vida (ordem das cores, ensinar os sensores, abrir
## ao ligar, apagar dados) fica em AJUSTES AVANÇADOS.
##
## O MODO EVENTO não é ligado aqui: é uma opção do menu do jogo, ao lado de
## ARCADE e COPA - um arcade de até 8 jogadores, sem ficha, com o cadastro
## (e-mail, nome, idade) de cada um antes da partida (scripts/leads.gd).
##
## JANELAS: cada janela aberta cobre a tela inteira e é a ÚNICA que recebe
## mouse, controle e teclas (ESC / VOLTAR fecha só a de cima). Nenhum botão
## guarda "foco", então ENTER, START ou um sensor nunca apertam o que ficou
## atrás.

const CENA_OPENING := "res://scenes/opening.tscn"
const LEDS: Array[String] = ["A", "B", "C", "D", "E", "F", "G"]
const CORES: Array[Color] = [Color.DODGER_BLUE, Color.LIME_GREEN, Color.RED, Color.YELLOW, Color.MAGENTA, Color.CYAN, Color.ORANGE]
const AZUL := Color(0.12, 0.70, 1.0)
const VERDE := Color(0.22, 0.95, 0.48)
const AMARELO := Color(1.0, 0.82, 0.12)
const VERMELHO := Color(1.0, 0.30, 0.30)
const CINZA := Color(0.62, 0.70, 0.80)
const MODOS := ["livre", "credito"]
const COR_MODO := {"livre": VERDE, "credito": AMARELO}

var status_label: Label
var partidas_label: Label
var botoes_led: Array[Button] = []
var caminho_fila := ""
var caminho_script := ""
var apagar_timer := 0.0
var ultimo_sensor := -1
var voltando := false
var ordem_cores := -1
var ensinando := -1               # qual entrada está sendo pedida (-1 = não está ensinando)
var ensinado := {}
var ensinar_desde := 0
var inicio_label: Label
var palco: Control
var botoes_modo := {}             # "livre" | "credito" -> Button
var numeros_dados := {}           # "arcade" | "copa" | "evento" | "cadastros" -> Label
var _dados_aberto := false
var faixas_modo := {}             # o que cada modo tem para ajustar
var creditos_label: Label
var evento_pen: Label
var data_label: Label
var _modais: Array[Control] = []
var _recados: Array[Label] = []


func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	# (o cursor é o do jogo: ControleTv desenha quando o mouse mexe)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_criar_interface()
	_atualizar_dados()
	Leads.painel_aberto = true
	Leads.mudou.connect(_atualizar_dados)
	ArcadeData.dados_atualizados.connect(_atualizar_dados)
	var relogio := Timer.new()
	relogio.wait_time = 2.0
	relogio.autostart = true
	relogio.timeout.connect(_atualizar_dados)
	add_child(relogio)
	await _abrir_serial()


func _process(delta: float) -> void:
	if apagar_timer > 0.0:
		apagar_timer -= delta
		if apagar_timer <= 0.0:
			_serial_write("OFF")
			if ultimo_sensor >= 0: botoes_led[ultimo_sensor].modulate = Color.WHITE
	# com uma janela aberta, ficha e sensores não mexem na tela de trás
	if not _modais.is_empty() or ensinando >= 0 or voltando:
		return
	if Input.is_action_just_pressed("input_credit"):
		ArcadeData.adicionar_credito()
		_mensagem("●  FICHA RECEBIDA: +1 CRÉDITO")
	for i in range(LEDS.size()):
		var acao := "input_led_" + LEDS[i].to_lower()
		if Input.is_action_just_pressed(acao):
			_testar_alvo(i, true)


func _input(event: InputEvent) -> void:
	if ensinando >= 0:
		_ensinar_recebeu(event)
		return
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.keycode == KEY_F9):
		get_viewport().set_input_as_handled()
		if not _modais.is_empty():
			_fechar_modal()
			return
		_solicitar_voltar()


# ------------------------------------------------------------------ a tela
func _criar_interface() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	# A Central foi desenhada para 1280 x 720: na tela de 1080 linhas ela
	# cresce inteira (letras e botões no tamanho de ler do sofá).
	var tela := get_viewport_rect().size
	var k := maxf(minf(tela.x / 1280.0, tela.y / 720.0), 0.5)
	canvas.scale = Vector2(k, k)
	palco = Control.new()
	palco.size = tela / k
	palco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(palco)
	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.006, 0.011, 0.024)
	palco.add_child(fundo)
	_adicionar_luzes_fundo(palco)

	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margem.add_theme_constant_override("margin_left", 30)
	margem.add_theme_constant_override("margin_right", 30)
	margem.add_theme_constant_override("margin_top", 14)
	margem.add_theme_constant_override("margin_bottom", 14)
	palco.add_child(margem)
	var app := VBoxContainer.new()
	app.add_theme_constant_override("separation", 10)
	margem.add_child(app)

	# cabeçalho: o nome da tela e o recado do que acabou de acontecer
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 46
	header.add_theme_constant_override("separation", 14)
	app.add_child(header)
	var titulo := _label("CENTRAL DA MÁQUINA", 30, Color.WHITE)
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(titulo)
	status_label = _label("●  CONECTANDO O ARDUINO...", 16, Color(0.35, 0.92, 1.0))
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.clip_text = true
	header.add_child(status_label)

	# ---- 1. ARCADE e COPA: livre ou crédito (dois botões grandes, um ligado)
	var box_modo := _painel("1   ARCADE E COPA", "Como as partidas são liberadas. Vale na hora e fica guardado.", app, VERDE)
	var linha_modos := HBoxContainer.new()
	linha_modos.add_theme_constant_override("separation", 12)
	box_modo.add_child(linha_modos)
	for modo in MODOS:
		var b := _botao("", COR_MODO[modo])
		b.clip_text = false
		b.custom_minimum_size = Vector2(300, 68)
		b.add_theme_font_size_override("font_size", 17)
		b.add_theme_constant_override("line_spacing", 2)
		b.pressed.connect(_escolher_modo.bind(modo))
		linha_modos.add_child(b)
		botoes_modo[modo] = b
	# ao lado: o que o modo ligado tem para ajustar
	var f_livre := _label("Nada para ajustar: é só apertar START e jogar.", 17, Color(0.80, 0.88, 0.96))
	f_livre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f_livre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	f_livre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	linha_modos.add_child(f_livre)
	faixas_modo["livre"] = f_livre

	var f_credito := HBoxContainer.new()
	f_credito.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f_credito.add_theme_constant_override("separation", 10)
	linha_modos.add_child(f_credito)
	faixas_modo["credito"] = f_credito
	creditos_label = _label("", 20, AMARELO)
	creditos_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	creditos_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	creditos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	creditos_label.clip_text = true
	f_credito.add_child(creditos_label)
	var mais := _botao("+ 1 CRÉDITO", AMARELO, true)
	mais.custom_minimum_size = Vector2(170, 56)
	mais.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mais.pressed.connect(_adicionar_credito_manual)
	f_credito.add_child(mais)
	var zerar_c := _botao("ZERAR", CINZA)
	zerar_c.custom_minimum_size = Vector2(110, 56)
	zerar_c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	zerar_c.pressed.connect(_zerar_creditos)
	f_credito.add_child(zerar_c)

	# ---- 2. PARTIDAS JOGADAS (os eventos, os leads e o pendrive ficam no jogo:
	# menu > EVENTO - scripts/evento_lobby.gd)
	var box_dados := _painel("2   PARTIDAS JOGADAS", "Quantas vezes cada modo foi jogado nesta máquina.", app, AZUL)
	var linha_dados := HBoxContainer.new()
	linha_dados.add_theme_constant_override("separation", 10)
	box_dados.add_child(linha_dados)
	for item in [["arcade", "ARCADE", VERDE], ["copa", "COPA", AMARELO], ["evento", "EVENTO", AZUL], ["cadastros", "JOGADORES\nCADASTRADOS", Color(0.80, 0.55, 1.0)]]:
		var tile := PanelContainer.new()
		tile.custom_minimum_size = Vector2(150, 92)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cor_t: Color = item[2]
		var st_t := _estilo_card(cor_t, Color(cor_t.r * 0.07, cor_t.g * 0.07, cor_t.b * 0.07), 14, 1)
		st_t.shadow_size = 0
		st_t.content_margin_top = 6
		st_t.content_margin_bottom = 6
		tile.add_theme_stylebox_override("panel", st_t)
		linha_dados.add_child(tile)
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 0)
		tile.add_child(col)
		var numero := _label("0", 38, Color.WHITE)
		numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(numero)
		var nome_t := _label(str(item[1]) + ("" if str(item[0]) == "cadastros" else "\npartidas"), 13, cor_t.lightened(0.35))
		nome_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nome_t.add_theme_constant_override("line_spacing", -2)
		col.add_child(nome_t)
		numeros_dados[str(item[0])] = numero
	var col_botoes := VBoxContainer.new()
	col_botoes.add_theme_constant_override("separation", 8)
	linha_dados.add_child(col_botoes)
	col_botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	var gerenciar := _botao("ZERAR CONTADORES  ▸", AZUL, true)
	gerenciar.custom_minimum_size = Vector2(300, 52)
	gerenciar.pressed.connect(_abrir_dados)
	col_botoes.add_child(gerenciar)
	evento_pen = _label("", 14, Color.WHITE)
	evento_pen.clip_text = true
	box_dados.add_child(evento_pen)

	# ---- 3. os alvos
	var box_teste := _painel("3   TESTE DOS ALVOS", "Bata no alvo ou escolha a letra: o LED acende e o botão da tela pisca.", app, Color(0.08, 0.86, 0.78))
	box_teste.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	var grade := HBoxContainer.new()
	grade.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grade.add_theme_constant_override("separation", 10)
	box_teste.add_child(grade)
	for i in range(LEDS.size()):
		var b := _botao(LEDS[i], CORES[i])
		b.custom_minimum_size = Vector2(90, 64)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 34)
		b.pressed.connect(_testar_alvo.bind(i, false))
		grade.add_child(b)
		botoes_led.append(b)
	var todos := _botao("ACENDER\nTODOS", Color(0.08, 0.86, 0.78), true)
	todos.clip_text = false
	todos.custom_minimum_size = Vector2(170, 64)
	todos.size_flags_vertical = Control.SIZE_EXPAND_FILL
	todos.pressed.connect(_testar_todos)
	grade.add_child(todos)

	# ---- embaixo
	var rodape := HBoxContainer.new()
	rodape.custom_minimum_size.y = 56
	rodape.add_theme_constant_override("separation", 12)
	app.add_child(rodape)
	partidas_label = _label("", 15, Color(0.56, 0.66, 0.78))
	partidas_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	partidas_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rodape.add_child(partidas_label)
	var avancado := _botao("AJUSTES AVANÇADOS  ▸", CINZA)
	avancado.custom_minimum_size = Vector2(270, 56)
	avancado.pressed.connect(_abrir_avancado)
	rodape.add_child(avancado)
	var voltar := _botao("VOLTAR AO JOGO  ✔", VERDE, true)
	voltar.custom_minimum_size = Vector2(300, 56)
	voltar.add_theme_font_size_override("font_size", 20)
	voltar.pressed.connect(_solicitar_voltar)
	rodape.add_child(voltar)
	app.add_child(_label("MOUSE: clique   •   CONTROLE: setas + OK   •   ESC / VOLTAR / F9: fecha", 13, Color(0.45, 0.54, 0.66)))


func _painel(titulo_txt: String, subtitulo_txt: String, pai: Control, destaque: Color) -> VBoxContainer:
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override("panel", _estilo_card(destaque, Color(0.018, 0.029, 0.052), 16, 1))
	pai.add_child(painel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	painel.add_child(box)
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 16)
	box.add_child(cab)
	var titulo := _label(titulo_txt, 21, Color(destaque.r, destaque.g, destaque.b).lightened(0.35))
	cab.add_child(titulo)
	var sub := _label(subtitulo_txt, 15, Color(0.56, 0.66, 0.78))
	sub.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	sub.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cab.add_child(sub)
	return box


func _label(texto: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	return l


func _botao(texto: String, cor: Color, preenchido: bool = false) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(150, 48)
	b.add_theme_font_size_override("font_size", 17)
	b.clip_text = true
	# sem "foco" do Godot: ENTER, START ou um sensor nunca apertam um botão
	# que ficou atrás de uma janela (quem anda pelos botões é o ControleTv)
	b.focus_mode = Control.FOCUS_NONE
	_pintar(b, cor, preenchido)
	return b


func _pintar(b: Button, cor: Color, preenchido: bool) -> void:
	for estado in ["normal", "hover", "pressed"]:
		var st := StyleBoxFlat.new()
		var intensidade := 0.30 if preenchido else 0.09
		if estado == "hover": intensidade += 0.14
		if estado == "pressed": intensidade += 0.26
		st.bg_color = Color(cor.r * intensidade, cor.g * intensidade, cor.b * intensidade, 1.0)
		st.border_color = Color(cor.r, cor.g, cor.b, 1.0 if (preenchido or estado != "normal") else 0.50)
		st.set_border_width_all(3 if preenchido else (1 if estado == "normal" else 2))
		st.set_corner_radius_all(12)
		st.content_margin_left = 10
		st.content_margin_right = 10
		b.add_theme_stylebox_override(estado, st)
	for nome in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(nome, Color.WHITE if preenchido else cor.lightened(0.45))


func _estilo_card(borda: Color, fundo: Color, raio: int, largura: int) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = fundo
	st.border_color = Color(borda.r, borda.g, borda.b, 0.42)
	st.set_border_width_all(largura)
	st.set_corner_radius_all(raio)
	st.content_margin_left = 20
	st.content_margin_right = 20
	st.content_margin_top = 12
	st.content_margin_bottom = 12
	st.shadow_color = Color(0, 0, 0, 0.32)
	st.shadow_size = 10
	st.shadow_offset = Vector2(0, 4)
	return st

func _adicionar_luzes_fundo(canvas: Control) -> void:
	var luz_azul := ColorRect.new()
	luz_azul.position = Vector2(-180, -160)
	luz_azul.size = Vector2(620, 480)
	luz_azul.color = Color(0.02, 0.18, 0.34, 0.16)
	luz_azul.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(luz_azul)
	var luz_verde := ColorRect.new()
	luz_verde.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	luz_verde.position = Vector2(-420, -300)
	luz_verde.size = Vector2(520, 380)
	luz_verde.color = Color(0.0, 0.22, 0.16, 0.10)
	luz_verde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(luz_verde)

# ------------------------------------------------------------------ janelas
## Abre uma janela por cima de tudo e devolve a caixa onde vão os botões.
## A janela cobre a tela inteira (nada atrás recebe clique nem seta) e tem a
## sua linha de recado; ESC / VOLTAR fecha a de cima.
func _abrir_modal(titulo_txt: String, sub_txt: String, largura: float, cor: Color) -> VBoxContainer:
	ControleTv.fechar_teclado()
	var tampa := ColorRect.new()
	tampa.set_anchors_preset(Control.PRESET_FULL_RECT)
	tampa.color = Color(0.0, 0.01, 0.03, 0.90)
	tampa.mouse_filter = Control.MOUSE_FILTER_STOP
	palco.add_child(tampa)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tampa.add_child(centro)
	var cartao := PanelContainer.new()
	cartao.custom_minimum_size.x = largura
	var st := _estilo_card(cor, Color(0.030, 0.050, 0.090), 22, 2)
	st.border_color = cor
	st.content_margin_left = 30
	st.content_margin_right = 30
	st.content_margin_top = 22
	st.content_margin_bottom = 22
	cartao.add_theme_stylebox_override("panel", st)
	centro.add_child(cartao)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	cartao.add_child(box)
	box.add_child(_label(titulo_txt, 28, Color.WHITE))
	if sub_txt != "":
		var sub := _label(sub_txt, 16, Color(0.66, 0.75, 0.86))
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub.custom_minimum_size.x = largura - 60
		box.add_child(sub)
	var recado := _label("", 16, AMARELO)
	recado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recado.custom_minimum_size = Vector2(largura - 60, 24)
	tampa.set_meta("recado", recado)
	_modais.append(tampa)
	_recados.append(recado)
	return box


## A linha de recado e o botão de fechar entram por último na janela.
func _fim_do_modal(box: VBoxContainer, fechar_txt: String = "FECHAR  ✔") -> void:
	box.add_child(_recados[-1])
	var fechar := _botao(fechar_txt, VERDE, true)
	fechar.custom_minimum_size = Vector2(260, 52)
	fechar.size_flags_horizontal = Control.SIZE_SHRINK_END
	fechar.pressed.connect(_fechar_modal)
	box.add_child(fechar)
	ControleTv.marcar.call_deferred(fechar)


func _fechar_modal() -> void:
	if _modais.is_empty():
		return
	ControleTv.fechar_teclado()
	var tampa: Control = _modais.pop_back()
	_recados.pop_back()
	if _modais.is_empty():
		_dados_aberto = false
	tampa.queue_free()
	_atualizar_dados()


## Uma linha de ajuste: o botão à esquerda e, ao lado, para que ele serve.
func _linha_ajuste(box: VBoxContainer, texto: String, explica: String, cor: Color, acao: Callable) -> Button:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 16)
	box.add_child(linha)
	var b := _botao(texto, cor)
	b.custom_minimum_size = Vector2(330, 50)
	b.pressed.connect(acao)
	linha.add_child(b)
	var l := _label(explica, 15, Color(0.70, 0.78, 0.88))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	linha.add_child(l)
	return b


## "Tem certeza?" - só o SIM faz; CANCELAR, ESC e VOLTAR não fazem nada.
func _confirmar(pergunta: String, explica: String, sim_txt: String, acao: Callable) -> void:
	var box := _abrir_modal(pergunta, explica, 700, VERMELHO)
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_END
	linha.add_theme_constant_override("separation", 14)
	box.add_child(linha)
	var nao := _botao("CANCELAR", CINZA)
	nao.custom_minimum_size = Vector2(220, 54)
	nao.pressed.connect(_fechar_modal)
	linha.add_child(nao)
	var sim := _botao(sim_txt, VERMELHO, true)
	sim.custom_minimum_size = Vector2(300, 54)
	sim.pressed.connect(func() -> void:
		_fechar_modal()
		acao.call())
	linha.add_child(sim)
	ControleTv.marcar.call_deferred(nao)


# ------------------------------------------------------------- modo da máquina
func _escolher_modo(modo: String) -> void:
	if modo == ArcadeData.modo_atual():
		return
	if modo == "credito":
		ArcadeData.definir_modo("credito")
		_mensagem("●  ARCADE E COPA: 1 FICHA POR PARTIDA")
	else:
		ArcadeData.definir_modo("free")
		_mensagem("●  ARCADE E COPA: JOGAM SEM FICHA")
	_atualizar_dados()


func _adicionar_credito_manual() -> void:
	ArcadeData.adicionar_credito()
	_mensagem("●  +1 CRÉDITO")


func _zerar_creditos() -> void:
	ArcadeData.zerar_creditos()
	_mensagem("●  CRÉDITOS ZERADOS")


func _atualizar_dados() -> void:
	if not is_inside_tree() or botoes_modo.is_empty():
		return
	var atual := ArcadeData.modo_atual()
	var textos := {
		"livre": "LIVRE\nsem ficha",
		"credito": "CRÉDITO\n1 ficha por partida"}
	for modo in MODOS:
		var b: Button = botoes_modo[modo]
		b.text = ("✔  " if modo == atual else "") + str(textos[modo])
		_pintar(b, COR_MODO[modo], modo == atual)
		(faixas_modo[modo] as Control).visible = modo == atual
	(numeros_dados["arcade"] as Label).text = str(ArcadeData.partidas_arcade)
	(numeros_dados["copa"] as Label).text = str(ArcadeData.partidas_copa)
	(numeros_dados["evento"] as Label).text = str(ArcadeData.partidas_evento)
	(numeros_dados["cadastros"] as Label).text = str(Leads.total())
	if ArcadeData.creditos <= 0:
		creditos_label.text = "SEM CRÉDITOS"
		creditos_label.add_theme_color_override("font_color", VERMELHO)
	else:
		creditos_label.text = "%d CRÉDITO%s" % [ArcadeData.creditos, "" if ArcadeData.creditos == 1 else "S"]
		creditos_label.add_theme_color_override("font_color", AMARELO)
	if Leads.relogio_suspeito():
		evento_pen.text = "⚠ O RELÓGIO DESTA TV ESTÁ ERRADO: acerte em AJUSTES AVANÇADOS > DATA E HORA  (é a data que entra nos cadastros)"
		evento_pen.add_theme_color_override("font_color", AMARELO)
	else:
		evento_pen.text = "EVENTOS, LEADS E PENDRIVE:  no jogo, escolha EVENTO no menu (ao lado de ARCADE e COPA)  -  está tudo lá."
		evento_pen.add_theme_color_override("font_color", Color(0.62, 0.72, 0.84))
	partidas_label.text = "TOTAL DE PARTIDAS: %d" % ArcadeData.partidas_total
	if data_label != null and is_instance_valid(data_label):
		data_label.text = Leads.data_na_tela() + ("   ⚠" if Leads.relogio_suspeito() else "")
	_atualizar_inicio()


# ------------------------------------------------------------------- evento
func _abrir_opcoes_evento() -> void:
	var box := _abrir_modal("DATA E HORA", "É a data que entra em cada cadastro do MODO EVENTO. Caixa sem internet costuma ligar com a data errada.", 900, AZUL)
	# a data que entra em cada cadastro
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 8)
	box.add_child(linha)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(col)
	col.add_child(_label("DATA E HORA DOS CADASTROS", 15, AZUL))
	data_label = _label(Leads.data_na_tela(), 24, Color.WHITE)
	col.add_child(data_label)
	for par in [["DIA", "dia"], ["MÊS", "mes"], ["ANO", "ano"], ["HORA", "hora"], ["MIN", "minuto"]]:
		var c := VBoxContainer.new()
		c.add_theme_constant_override("separation", 2)
		linha.add_child(c)
		var nome := _label(str(par[0]), 13, CINZA)
		nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_child(nome)
		var pm := HBoxContainer.new()
		pm.add_theme_constant_override("separation", 4)
		c.add_child(pm)
		for quanto in [-1, 1]:
			var b := _botao("−" if quanto < 0 else "+", CINZA)
			b.custom_minimum_size = Vector2(48, 46)
			b.add_theme_font_size_override("font_size", 24)
			b.pressed.connect(_acertar_data.bind(str(par[1]), quanto))
			pm.add_child(b)
	_fim_do_modal(box)


func _acertar_data(campo: String, quanto: int) -> void:
	Leads.acertar_relogio(campo, quanto)
	_mensagem("●  DATA DOS CADASTROS ACERTADA")


# ------------------------------------------------------------ contadores
## ZERAR CONTADORES: as partidas de cada modo, uma por uma (pede confirmação).
## (os eventos, os leads e o pendrive ficam no jogo: menu > EVENTO)
func _abrir_dados() -> void:
	_dados_aberto = true
	var box := _abrir_modal("CONTADORES DE PARTIDAS", "Zerar um contador não mexe nos eventos nem nos cadastros.", 1100, AZUL)

	# --- as partidas, por tipo
	var linha_p := HBoxContainer.new()
	linha_p.add_theme_constant_override("separation", 10)
	box.add_child(linha_p)
	for item in [["arcade", "ARCADE", VERDE, ArcadeData.partidas_arcade], ["copa", "COPA", AMARELO, ArcadeData.partidas_copa], ["evento", "EVENTO", AZUL, ArcadeData.partidas_evento]]:
		var cor_t: Color = item[2]
		var chip := PanelContainer.new()
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var st_c := _estilo_card(cor_t, Color(cor_t.r * 0.07, cor_t.g * 0.07, cor_t.b * 0.07), 14, 1)
		st_c.shadow_size = 0
		st_c.content_margin_top = 8
		st_c.content_margin_bottom = 8
		st_c.content_margin_left = 16
		st_c.content_margin_right = 10
		chip.add_theme_stylebox_override("panel", st_c)
		linha_p.add_child(chip)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		chip.add_child(h)
		var num := _label(str(int(item[3])), 32, Color.WHITE)
		num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(num)
		var nome := _label("partidas\n" + str(item[1]), 14, cor_t.lightened(0.35))
		nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nome.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(nome)
		var zerar := _botao("ZERAR", CINZA)
		zerar.custom_minimum_size = Vector2(96, 42)
		zerar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		zerar.disabled = int(item[3]) == 0
		zerar.modulate.a = 0.35 if zerar.disabled else 1.0
		var tipo := str(item[0])
		var rotulo := str(item[1])
		zerar.pressed.connect(func() -> void:
			_confirmar("ZERAR AS PARTIDAS DE %s?" % rotulo, "O contador de partidas de %s volta para zero. Os cadastros não são mexidos." % rotulo, "SIM, ZERAR", func() -> void:
				ArcadeData.zerar_partidas(tipo)
				_mensagem("●  PARTIDAS DE %s ZERADAS" % rotulo)
				_refazer_dados()))
		h.add_child(zerar)

	_fim_do_modal(box)


func _data_curta(t: String) -> String:
	if t.length() < 16:
		return t if t != "" else "-"
	return "%s/%s/%s %s" % [t.substr(8, 2), t.substr(5, 2), t.substr(0, 4), t.substr(11, 5)]


## A janela dos dados é montada de novo com os números de agora.
func _refazer_dados() -> void:
	if not _dados_aberto:
		return
	var recado := status_label.text
	while not _modais.is_empty():
		_fechar_modal()
	_dados_aberto = true
	_abrir_dados()
	_mensagem(recado)


# ----------------------------------------------------------------- avançado
func _abrir_avancado() -> void:
	var box := _abrir_modal("AJUSTES AVANÇADOS", "Coisas que se faz uma vez, na instalação da máquina.", 980, CINZA)
	_linha_ajuste(box, "ORDEM DAS CORES DOS LEDS", "Pediu vermelho e acendeu outra cor? Aperte até os alvos ficarem VERMELHOS.", VERMELHO, _trocar_ordem_das_cores)
	_linha_ajuste(box, "ENSINAR SENSORES E BOTÕES", "Para a placa Zero Delay: a tela pede cada alvo e botão, um por vez.", AMARELO, _ensinar_entradas)
	_linha_ajuste(box, "DATA E HORA", "A data que entra nos cadastros do MODO EVENTO. Agora: %s" % Leads.data_na_tela(), AZUL, _abrir_opcoes_evento)
	if ArduinoBridge.tem_plugin() or OS.get_environment("OLHO_TESTE_TV") != "":
		# TV Box / TV Android: o jogo abre sozinho depois que a TV liga.
		# (desligado - ArduinoBridge.ABRIR_SOZINHO: quem abre é o app auto start)
		if ArduinoBridge.ABRIR_SOZINHO:
			_linha_ajuste(box, "ABRIR O JOGO AO LIGAR A TV", "A TV Box liga e já entra no jogo, sem passar pela tela do Android.", VERDE, _escolher_tela_inicial)
			inicio_label = _label(_texto_inicio(), 13, Color(0.55, 0.64, 0.76))
			inicio_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(inicio_label)
		_linha_ajuste(box, "SAIR PARA A TV", "Fecha o jogo e volta para a tela do Android.", CINZA, _sair_para_tv)
	var bt_menu := _linha_ajuste(box, "", "A opção EVENTO fica no menu do jogo, ao lado de ARCADE e COPA: abre a tela dos EVENTOS (criar, jogar, leads, pendrive). Esconda se esta máquina não vai a eventos.", AZUL, func() -> void: pass)
	var texto_menu := func() -> void:
		bt_menu.text = "EVENTO NO MENU:  SIM  ✔" if Leads.ligado else "EVENTO NO MENU:  NÃO"
		_pintar(bt_menu, AZUL if Leads.ligado else CINZA, Leads.ligado)
	texto_menu.call()
	bt_menu.pressed.connect(func() -> void:
		Leads.ligar(not Leads.ligado)
		texto_menu.call()
		_mensagem("●  A OPÇÃO EVENTO ESTÁ NO MENU DO JOGO" if Leads.ligado else "●  A OPÇÃO EVENTO SAIU DO MENU DO JOGO"))
	_linha_ajuste(box, "LIMPAR MURAL DE CAMPEÕES", "Apaga todos os campeões e o ranking guardados.", VERMELHO, func() -> void:
		_confirmar("LIMPAR O MURAL DE CAMPEÕES?", "Todos os campeões e o ranking são apagados. Não dá para desfazer.", "SIM, LIMPAR", func() -> void:
			ChampionsDb.limpar_tudo()
			_mensagem("●  MURAL DE CAMPEÕES LIMPO")))
	_fim_do_modal(box)


func _testar_alvo(index: int, sensor_fisico: bool) -> void:
	_serial_write("SET:%s=255,255,255" % LEDS[index])
	if ultimo_sensor >= 0: botoes_led[ultimo_sensor].modulate = Color.WHITE
	ultimo_sensor = index; botoes_led[index].modulate = CORES[index].lightened(.35); apagar_timer = 1.0
	_mensagem(("SENSOR %s RECEBIDO • LED %s ACESO" if sensor_fisico else "TESTE DO ALVO %s • LED %s ACESO") % [LEDS[index], LEDS[index]])

func _testar_todos() -> void:
	var itens: Array[String] = []
	for letra in LEDS:
		itens.append("%s=255,255,255" % letra)
	_serial_write("SET:" + ";".join(itens))
	apagar_timer = 1.5
	_mensagem("TODOS OS LEDS ACESOS")

## O recado vai para o cabeçalho e, com uma janela aberta, para ela também.
func _mensagem(texto: String) -> void:
	if status_label != null:
		status_label.text = texto
	if not _recados.is_empty() and is_instance_valid(_recados[-1]):
		_recados[-1].text = texto


func _solicitar_voltar() -> void:
	if voltando:
		return
	voltando = true
	status_label.text = "●  SALVANDO E VOLTANDO AO JOGO..."
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	call_deferred("_voltar_seguro")

func _voltar_seguro() -> void:
	_serial_write("OFF")
	await get_tree().create_timer(0.08).timeout
	_serial_write("__EXIT__")
	await get_tree().create_timer(0.18).timeout
	# (o menu volta direto, sem a tela de carregamento)
	get_tree().set_meta("pular_patrocinadores_opening_uma_vez", true)
	var erro := get_tree().change_scene_to_file(CENA_OPENING)
	if erro != OK:
		voltando = false
		status_label.text = "●  ERRO AO VOLTAR — TENTE NOVAMENTE"

func _abrir_serial() -> void:
	# TV Box / TV Android: o Arduino vai pelo USB (ArduinoBridge), sem PowerShell.
	if ArduinoBridge.ativo():
		ArduinoBridge.pedir_permissao_agora()
		await ArduinoBridge.preparar()
		_mensagem("●  " + ArduinoBridge.status.to_upper())
		if not ArduinoBridge.mudou.is_connected(_arduino_mudou):
			ArduinoBridge.mudou.connect(_arduino_mudou)
		return
	caminho_fila = ProjectSettings.globalize_path("user://arduino_queue_config"); caminho_script = ProjectSettings.globalize_path("user://arduino_bridge_config.ps1"); var log := ProjectSettings.globalize_path("user://arduino_log_config.txt"); DirAccess.make_dir_recursive_absolute(caminho_fila)
	var script := """$ErrorActionPreference='Stop'
$p=New-Object System.IO.Ports.SerialPort 'COM5',9600,'None',8,'One'
$p.DtrEnable=$false;$p.RtsEnable=$false;$p.NewLine="`n"
try{$p.Open();Start-Sleep -Milliseconds 180;$p.WriteLine('OFF');Add-Content '%s' 'CONFIG_READY';while($true){Get-ChildItem '%s' -Filter '*.cmd'|Sort-Object Name|ForEach-Object{$c=(Get-Content $_.FullName -Raw).Trim();Remove-Item $_.FullName -Force;if($c -eq '__EXIT__'){$p.WriteLine('OFF');$p.Close();exit};if($c.Length -gt 0){$p.WriteLine($c)}};Start-Sleep -Milliseconds 8}}catch{Add-Content '%s' $_.Exception.Message}
""" % [log.replace("\\", "\\\\"), caminho_fila.replace("\\", "\\\\"), log.replace("\\", "\\\\")]
	var f := FileAccess.open(caminho_script, FileAccess.WRITE)
	if f == null:
		_mensagem("ERRO AO CRIAR CONTROLE SERIAL")
		return
	f.store_string(script)
	f.close()
	# Dá tempo para a ponte da tela anterior liberar a COM5.
	await get_tree().create_timer(.55).timeout
	OS.create_process("powershell.exe", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden", "-File", caminho_script], false)
	await get_tree().create_timer(.45).timeout
	_mensagem("PRONTO • TESTE OS LEDS E SENSORES A–G")

func _serial_write(comando: String) -> void:
	# TV Box / TV Android: o Arduino vai pelo USB (ArduinoBridge), sem PowerShell.
	if ArduinoBridge.ativo():
		ArduinoBridge.enviar(comando)
		return

	if caminho_fila == "":
		return
	var nome := "%020d_%06d.cmd" % [Time.get_ticks_msec(), randi() % 1000000]
	var f := FileAccess.open(caminho_fila.path_join(nome), FileAccess.WRITE)
	if f:
		f.store_string(comando)
		f.close()

func _exit_tree() -> void:
	Leads.painel_aberto = false
	_serial_write("OFF")


func _arduino_mudou() -> void:
	if not voltando:
		_mensagem("●  " + ArduinoBridge.status.to_upper())


func _texto_inicio() -> String:
	return ArduinoBridge.texto_inicio()


func _escolher_tela_inicial() -> void:
	if ArduinoBridge.abre_sozinho() and str(ArduinoBridge.inicio_estado().get("tela_inicial", "")) == "jogo":
		_mensagem("●  OK: A TV JÁ ABRE O JOGO SOZINHA")
		_atualizar_inicio()
		return
	# 1o em silêncio (root / adb da TV); se a caixa não deixar, a tela do Android
	_mensagem("●  PREPARANDO A TV...")
	ArduinoBridge.preparar_sozinho()
	await get_tree().create_timer(6.0).timeout
	if not is_inside_tree() or voltando:
		return
	var d := ArduinoBridge.inicio_estado()
	_atualizar_inicio()
	if str(d.get("tela_inicial", "")) == "jogo":
		_mensagem("●  PRONTO: A TV ABRE O JOGO SOZINHA AO LIGAR")
	elif int(d.get("sdk", "0")) >= 29 and str(d.get("sobrepor", "")) == "nao" and ArduinoBridge.pedir_sobrepor():
		_mensagem("●  DEIXE OLHO NO LANCE PERMITIDO E APERTE VOLTAR")
	else:
		_mensagem("●  ESCOLHA OLHO NO LANCE E \"SEMPRE\"")
		ArduinoBridge.escolher_tela_inicial()


func _atualizar_inicio() -> void:
	if inicio_label != null and is_instance_valid(inicio_label):
		inicio_label.text = _texto_inicio()


func _sair_para_tv() -> void:
	_serial_write("OFF")
	ArduinoBridge.sair_para_tv()


# ------------------------------------------------------------ ordem das cores
## Cada aperto passa para a próxima ordem (são 6) e acende TODOS os alvos em
## VERMELHO: quando os anéis ficarem vermelhos de verdade, é essa. O Arduino
## guarda; não precisa regravar nada.
const NOMES_ORDEM := ["GRB", "RGB", "BRG", "RBG", "GBR", "BGR"]


func _trocar_ordem_das_cores() -> void:
	if ordem_cores < 0:
		ordem_cores = maxi(ArduinoBridge.ordem_da_fita(), 0)
	else:
		ordem_cores = (ordem_cores + 1) % 6
		_serial_write("ORDEM:%d" % ordem_cores)
		await get_tree().create_timer(0.25).timeout
	var itens: Array[String] = []
	for letra in LEDS:
		itens.append("%s=255,0,0" % letra)
	_serial_write("SET:" + ";".join(itens))
	apagar_timer = 6.0
	_mensagem("●  ORDEM %d (%s): OS ALVOS ESTÃO VERMELHOS?  SE NÃO, APERTE DE NOVO" % [ordem_cores + 1, NOMES_ORDEM[ordem_cores]])


# ------------------------------------------------------- ensinar as entradas
## Para a placa Zero Delay ligada na TV Box: pede cada sensor e botão na
## ordem e guarda qual botão do Android é qual (ArduinoBridge).
const NOMES_ENTRADA := ["BATA NO ALVO A", "BATA NO ALVO B", "BATA NO ALVO C", "BATA NO ALVO D", "BATA NO ALVO E", "BATA NO ALVO F", "BATA NO ALVO G", "APERTE O BOTÃO START", "APERTE O BOTÃO SELECT"]


func _ensinar_entradas() -> void:
	if ensinando >= 0:
		return
	ensinado.clear()
	ensinando = 0
	ensinar_desde = Time.get_ticks_msec()
	ArduinoBridge.ensinando = true
	_pedir_entrada()


func _pedir_entrada() -> void:
	_mensagem("●  ENSINANDO %d/9:  %s   (VOLTAR cancela)" % [ensinando + 1, NOMES_ENTRADA[ensinando]])
	if ensinando < LEDS.size():
		_serial_write("SET:%s=255,255,255" % LEDS[ensinando])
		apagar_timer = 0.0


func _ensinar_recebeu(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and event.keycode in [KEY_BACK, KEY_ESCAPE]:
		_ensinar_fim(false)
		return
	# (o aperto que abriu o ensino ainda está chegando)
	if Time.get_ticks_msec() - ensinar_desde < 500:
		return
	var txt := ArduinoBridge.texto_do_evento(event)
	if txt == "" or ensinado.values().has(txt):
		return
	ensinado[ArduinoBridge.ENTRADAS[ensinando]] = txt
	ensinando += 1
	ensinar_desde = Time.get_ticks_msec()
	if ensinando >= ArduinoBridge.ENTRADAS.size():
		_ensinar_fim(true)
	else:
		_pedir_entrada()


func _ensinar_fim(guardar: bool) -> void:
	ensinando = -1
	ArduinoBridge.ensinando = false
	_serial_write("OFF")
	if guardar:
		ArduinoBridge.guardar_entradas(ensinado)
		_mensagem("●  PRONTO: SENSORES E BOTÕES GUARDADOS — TESTE BATENDO NOS ALVOS")
	else:
		_mensagem("●  ENSINO CANCELADO (NADA FOI MUDADO)")
