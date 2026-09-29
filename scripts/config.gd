extends Node2D

## CENTRAL DA MÁQUINA (TV Box).
##
## Abre no menu segurando o botão de CRÉDITO por 5 s (ou F9 num teclado).
## Na máquina não há mouse: SELECT passa de um botão para o outro e START
## aperta o botão marcado. Bater num alvo acende o LED dele e mostra o
## sensor que chegou (teste da fiação). O topo mostra a conexão USB com o
## Arduino Nano.

const CENA_OPENING := "res://scenes/opening.tscn"
const LEDS: Array = ["A", "B", "C", "D", "E", "F", "G"]
const CORES: Array = [Color.dodgerblue, Color.limegreen, Color.red, Color.yellow, Color.magenta, Color.cyan, Color.orange]
var status_label: Label
var usb_label: Label
var creditos_label: Label
var partidas_label: Label
var modo_botao: Button
var botoes_led: Array = []
var focaveis: Array = []
var foco := 0
var apagar_timer := 0.0
var ultimo_sensor := -1
var voltando := false


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_criar_interface()
	_atualizar_dados()
	_focar(0)
	_serial_write("OFF")
	_mensagem("PRONTO • BATA NOS ALVOS A–G PARA TESTAR")


func _process(delta: float) -> void:
	usb_label.text = ("●  USB: " + Arduino.status).to_upper()
	usb_label.add_color_override("font_color", Color(0.22, 1.0, 0.48) if Arduino.conectado else Color(1.0, 0.72, 0.2))
	if Input.is_action_just_pressed("input_credit"):
		ArcadeData.adicionar_credito()
		_atualizar_dados()
		_mensagem("CRÉDITO ADICIONADO")
	if Input.is_action_just_pressed("input_cup"):
		_focar(foco + 1)
	if Input.is_action_just_pressed("input_start") and not voltando:
		var b = focaveis[foco]
		if is_instance_valid(b):
			b.emit_signal("pressed")
	for i in range(LEDS.size()):
		var acao = "input_led_" + LEDS[i].to_lower()
		if Input.is_action_just_pressed(acao):
			_testar_alvo(i, true)
	if apagar_timer > 0.0:
		apagar_timer -= delta
		if apagar_timer <= 0.0:
			_serial_write("OFF")
			if ultimo_sensor >= 0:
				botoes_led[ultimo_sensor].modulate = Color.white


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.scancode == KEY_ESCAPE or event.scancode == KEY_F9):
		get_tree().set_input_as_handled()
		_solicitar_voltar()


func _focar(i: int) -> void:
	foco = posmod(i, focaveis.size())
	var b = focaveis[foco]
	if is_instance_valid(b):
		b.grab_focus()


func _criar_interface() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var fundo := ColorRect.new()
	fundo.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	fundo.color = Color(0.006, 0.011, 0.024)
	canvas.add_child(fundo)
	_adicionar_luzes_fundo(canvas)

	var margem := MarginContainer.new()
	margem.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	margem.add_constant_override("margin_left", 30)
	margem.add_constant_override("margin_right", 30)
	margem.add_constant_override("margin_top", 20)
	margem.add_constant_override("margin_bottom", 20)
	canvas.add_child(margem)
	var app := VBoxContainer.new()
	app.add_constant_override("separation", 12)
	margem.add_child(app)

	var header := PanelContainer.new()
	header.rect_min_size.y = 72
	header.add_stylebox_override("panel", _estilo_card(Color(0.08, 0.55, 0.95), Color(0.018, 0.032, 0.060, 0.98), 18, 1))
	app.add_child(header)
	var header_box := HBoxContainer.new()
	header_box.add_constant_override("separation", 14)
	header.add_child(header_box)
	var marca := _label("GOL FLASH  /  SISTEMA", 15, Color(0.18, 0.78, 1.0))
	marca.rect_min_size.x = 210
	marca.valign = Label.VALIGN_CENTER
	header_box.add_child(marca)
	var titulo := _label("CENTRAL DA MÁQUINA", 24, Color.white)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.valign = Label.VALIGN_CENTER
	header_box.add_child(titulo)
	var colunas := VBoxContainer.new()
	colunas.rect_min_size.x = 430
	header_box.add_child(colunas)
	usb_label = _label("●  USB", 13, Color(1.0, 0.72, 0.2))
	usb_label.align = Label.ALIGN_RIGHT
	colunas.add_child(usb_label)
	status_label = _label("", 15, Color(0.35, 0.92, 1.0))
	status_label.align = Label.ALIGN_RIGHT
	colunas.add_child(status_label)

	# Três cards compactos na mesma linha: sempre cabem em 1280 x 720.
	var resumo := HBoxContainer.new()
	resumo.rect_min_size.y = 172
	resumo.add_constant_override("separation", 12)
	app.add_child(resumo)
	var box_modo := _painel("MODO DE OPERAÇÃO", "Como as partidas são liberadas", resumo, Color(0.12, 0.65, 1.0))
	box_modo.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modo_botao = _botao("", Color(0.12, 0.65, 1.0), true)
	modo_botao.connect("pressed", self, "_alternar_modo")
	box_modo.add_child(modo_botao)
	creditos_label = _label("", 17, Color(1.0, 0.82, 0.12))
	box_modo.add_child(creditos_label)

	var box_stats := _painel("PARTIDAS JOGADAS", "Histórico salvo automaticamente", resumo, Color(0.65, 0.35, 1.0))
	box_stats.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	partidas_label = _label("", 16, Color.white)
	box_stats.add_child(partidas_label)
	var zerar := _botao("ZERAR CONTADOR", Color(1.0, 0.48, 0.12))
	zerar.connect("pressed", self, "_zerar_estatisticas")
	box_stats.add_child(zerar)

	var box_acoes := _painel("AÇÕES RÁPIDAS", "Créditos e dados da máquina", resumo, Color(0.08, 0.86, 0.78))
	box_acoes.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var credito_btn := _botao("+  ADICIONAR CRÉDITO", Color(0.12, 0.78, 1.0), true)
	credito_btn.connect("pressed", self, "_adicionar_credito_manual")
	box_acoes.add_child(credito_btn)
	var mural := _botao("LIMPAR MURAL DE CAMPEÕES", Color(1.0, 0.18, 0.25))
	mural.connect("pressed", self, "_resetar_mural")
	box_acoes.add_child(mural)

	var box_teste := _painel("DIAGNÓSTICO DOS 7 ALVOS", "Bata no alvo (sensor) ou escolha um botão para testar LED + entrada", app, Color(0.08, 0.86, 0.78))
	box_teste.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	var grade := GridContainer.new()
	grade.columns = 7
	grade.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grade.add_constant_override("hseparation", 10)
	box_teste.add_child(grade)
	for i in range(LEDS.size()):
		var b := _botao_alvo(i)
		b.connect("pressed", self, "_testar_alvo", [i, false])
		grade.add_child(b)
		botoes_led.append(b)
	var todos := _botao("TESTAR TODOS OS LEDS", Color(0.08, 0.86, 0.78), true)
	todos.connect("pressed", self, "_testar_todos")
	box_teste.add_child(todos)

	var rodape := HBoxContainer.new()
	rodape.rect_min_size.y = 52
	rodape.add_constant_override("separation", 12)
	app.add_child(rodape)
	var atalho := _label("SELECT: próximo botão   •   START: apertar   •   crédito: +1", 14, Color(0.50, 0.60, 0.70))
	atalho.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atalho.valign = Label.VALIGN_CENTER
	rodape.add_child(atalho)
	var voltar := _botao("SALVAR E VOLTAR AO JOGO", Color(0.18, 0.92, 0.46), true)
	voltar.rect_min_size = Vector2(330, 52)
	voltar.connect("pressed", self, "_solicitar_voltar")
	rodape.add_child(voltar)

	# Ordem do SELECT: voltar primeiro (sair é o mais comum), depois o resto.
	focaveis = [voltar, modo_botao, zerar, credito_btn, mural] + botoes_led + [todos]


func _painel(titulo_txt: String, subtitulo_txt: String, pai: Control, destaque: Color) -> VBoxContainer:
	var painel := PanelContainer.new()
	painel.add_stylebox_override("panel", _estilo_card(destaque, Color(0.018, 0.029, 0.052, 0.98), 16, 1))
	pai.add_child(painel)
	var box := VBoxContainer.new()
	box.add_constant_override("separation", 10)
	painel.add_child(box)
	var titulo := _label(titulo_txt, 18, Color.white)
	box.add_child(titulo)
	box.add_child(_label(subtitulo_txt, 13, Color(0.48, 0.59, 0.70)))
	var linha := ColorRect.new()
	linha.color = Color(destaque.r, destaque.g, destaque.b, 0.75)
	linha.rect_min_size = Vector2(0, 2)
	box.add_child(linha)
	return box


func _label(texto: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	Compat.tamanho(l, tamanho)
	l.add_color_override("font_color", cor)
	return l


func _botao(texto: String, cor: Color, preenchido: bool = false) -> Button:
	var b := Button.new()
	b.text = texto
	b.rect_min_size = Vector2(190, 46)
	b.focus_mode = Control.FOCUS_ALL
	Compat.tamanho(b, 15)
	for estado in ["normal", "hover", "pressed", "focus"]:
		var st := StyleBoxFlat.new()
		var intensidade := 0.24 if preenchido else 0.09
		if estado == "hover":
			intensidade += 0.16
		if estado == "pressed":
			intensidade += 0.28
		if estado == "focus":
			intensidade += 0.22
		st.bg_color = Color(cor.r * intensidade, cor.g * intensidade, cor.b * intensidade, 0.98)
		st.border_color = Color(1, 1, 1, 0.95) if estado == "focus" else Color(cor.r, cor.g, cor.b, 0.95 if estado != "normal" else 0.55)
		st.set_border_width_all(3 if estado == "focus" else (1 if estado == "normal" else 2))
		st.set_corner_radius_all(10)
		b.add_stylebox_override(estado, st)
	return b


func _botao_alvo(index: int) -> Button:
	var b := _botao("ALVO  %s\n●  LED E SENSOR" % LEDS[index], CORES[index])
	b.rect_min_size = Vector2(120, 90)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Compat.tamanho(b, 17)
	return b


func _estilo_card(borda: Color, fundo: Color, raio: int, largura: int) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = fundo
	st.border_color = Color(borda.r, borda.g, borda.b, 0.42)
	st.set_border_width_all(largura)
	st.set_corner_radius_all(raio)
	st.content_margin_left = 22
	st.content_margin_right = 22
	st.content_margin_top = 17
	st.content_margin_bottom = 17
	st.shadow_color = Color(0, 0, 0, 0.32)
	st.shadow_size = 10
	st.shadow_offset = Vector2(0, 4)
	return st


func _adicionar_luzes_fundo(canvas: CanvasLayer) -> void:
	var luz_azul := ColorRect.new()
	luz_azul.rect_position = Vector2(-180, -160)
	luz_azul.rect_size = Vector2(620, 480)
	luz_azul.color = Color(0.02, 0.18, 0.34, 0.16)
	luz_azul.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(luz_azul)
	var luz_verde := ColorRect.new()
	var tela := get_viewport_rect().size
	luz_verde.rect_position = tela - Vector2(420, 300)
	luz_verde.rect_size = Vector2(520, 380)
	luz_verde.color = Color(0.0, 0.22, 0.16, 0.10)
	luz_verde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(luz_verde)


func _adicionar_credito_manual() -> void:
	ArcadeData.adicionar_credito()
	_atualizar_dados()
	_mensagem("●  CRÉDITO ADICIONADO COM SUCESSO")


func _alternar_modo() -> void:
	ArcadeData.definir_modo("free" if ArcadeData.modo_operacao == "credito" else "credito")
	_atualizar_dados()
	_mensagem("MODO DE OPERAÇÃO SALVO")


func _atualizar_dados() -> void:
	if ArcadeData.modo_operacao == "credito":
		modo_botao.text = "MODO: CRÉDITO — 1 POR PARTIDA"
		if ArcadeData.creditos <= 0:
			creditos_label.text = "SEM CRÉDITOS\nUse o botão de crédito para liberar"
			creditos_label.add_color_override("font_color", Color(1.0, 0.32, 0.25))
		else:
			creditos_label.text = "%d CRÉDITO(S) DISPONÍVEL(IS)" % ArcadeData.creditos
			creditos_label.add_color_override("font_color", Color(1.0, 0.82, 0.12))
	else:
		modo_botao.text = "MODO: LIVRE — SEM CRÉDITO"
		creditos_label.text = "ACESSO LIVRE\nNenhum crédito será consumido"
		creditos_label.add_color_override("font_color", Color(0.22, 1.0, 0.48))
	partidas_label.text = "TOTAL   %d\nARCADE   %d\nCOPA     %d" % [ArcadeData.partidas_total, ArcadeData.partidas_arcade, ArcadeData.partidas_copa]


func _zerar_estatisticas() -> void:
	ArcadeData.zerar_estatisticas()
	_atualizar_dados()
	_mensagem("CONTADOR DE PARTIDAS ZERADO")


func _resetar_mural() -> void:
	ChampionsDb.limpar_tudo()
	_mensagem("MURAL DE CAMPEÕES RESETADO")


func _testar_alvo(index: int, sensor_fisico: bool) -> void:
	_serial_write("SET:%s=255,255,255" % LEDS[index])
	if ultimo_sensor >= 0:
		botoes_led[ultimo_sensor].modulate = Color.white
	ultimo_sensor = index
	botoes_led[index].modulate = CORES[index].lightened(.35)
	apagar_timer = 1.0
	_mensagem(("SENSOR %s RECEBIDO • LED %s ACESO" if sensor_fisico else "TESTE DO ALVO %s • LED %s ACESO") % [LEDS[index], LEDS[index]])


func _testar_todos() -> void:
	var itens := []
	for letra in LEDS:
		itens.append("%s=255,255,255" % letra)
	_serial_write("SET:" + PoolStringArray(itens).join(";"))
	apagar_timer = 1.5
	_mensagem("TODOS OS LEDS ACESOS")


func _mensagem(texto: String) -> void:
	status_label.text = texto


func _solicitar_voltar() -> void:
	if voltando:
		return
	voltando = true
	status_label.text = "●  SALVANDO E VOLTANDO AO JOGO..."
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	call_deferred("_voltar_seguro")


func _voltar_seguro() -> void:
	_serial_write("OFF")
	yield(get_tree().create_timer(0.08), "timeout")
	var erro := get_tree().change_scene(CENA_OPENING)
	if erro != OK:
		voltando = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		status_label.text = "●  ERRO AO VOLTAR — TENTE NOVAMENTE"


func _serial_write(comando: String) -> void:
	Arduino.enviar(comando)


func _exit_tree() -> void:
	_serial_write("OFF")
