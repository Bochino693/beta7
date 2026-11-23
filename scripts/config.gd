extends Node2D

const CENA_OPENING := "res://scenes/opening.tscn"
const LEDS: Array[String] = ["A", "B", "C", "D", "E", "F", "G"]
const CORES: Array[Color] = [Color.DODGER_BLUE, Color.LIME_GREEN, Color.RED, Color.YELLOW, Color.MAGENTA, Color.CYAN, Color.ORANGE]
var status_label: Label
var creditos_label: Label
var partidas_label: Label
var modo_option: OptionButton
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

func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_criar_interface()
	_atualizar_dados()
	await _abrir_serial()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("input_credit"):
		ArcadeData.adicionar_credito()
		_atualizar_dados()
		_mensagem("●  CRÉDITO ADICIONADO")
	for i in range(LEDS.size()):
		var acao := "input_led_" + LEDS[i].to_lower()
		if Input.is_action_just_pressed(acao):
			_testar_alvo(i, true)
	if apagar_timer > 0.0:
		apagar_timer -= delta
		if apagar_timer <= 0.0:
			_serial_write("OFF")
			if ultimo_sensor >= 0: botoes_led[ultimo_sensor].modulate = Color.WHITE

func _input(event: InputEvent) -> void:
	if ensinando >= 0:
		_ensinar_recebeu(event)
		return
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.keycode == KEY_F9):
		get_viewport().set_input_as_handled()
		_solicitar_voltar()

func _criar_interface() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.006, 0.011, 0.024)
	canvas.add_child(fundo)
	_adicionar_luzes_fundo(canvas)

	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	margem.add_theme_constant_override("margin_left", 30)
	margem.add_theme_constant_override("margin_right", 30)
	margem.add_theme_constant_override("margin_top", 20)
	margem.add_theme_constant_override("margin_bottom", 20)
	canvas.add_child(margem)
	var app := VBoxContainer.new()
	app.add_theme_constant_override("separation", 12)
	margem.add_child(app)

	var header := PanelContainer.new()
	header.custom_minimum_size.y = 72
	header.add_theme_stylebox_override("panel", _estilo_card(Color(0.08, 0.55, 0.95), Color(0.018, 0.032, 0.060, 0.98), 18, 1))
	app.add_child(header)
	var header_box := HBoxContainer.new()
	header_box.add_theme_constant_override("separation", 14)
	header.add_child(header_box)
	var marca := _label("OLHO NO LANCE  /  SISTEMA", 15, Color(0.18, 0.78, 1.0))
	marca.custom_minimum_size.x = 210
	marca.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_box.add_child(marca)
	var titulo := _label("CENTRAL DA MÁQUINA", 24, Color.WHITE)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_box.add_child(titulo)
	status_label = _label("●  CONECTANDO À COM5", 15, Color(0.35, 0.92, 1.0))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.custom_minimum_size.x = 390
	header_box.add_child(status_label)

	# Três cards compactos na mesma linha: sempre cabem em 1280 x 720.
	var resumo := HBoxContainer.new()
	resumo.custom_minimum_size.y = 172 if not ArduinoBridge.tem_plugin() else 260
	resumo.add_theme_constant_override("separation", 12)
	app.add_child(resumo)
	var box_modo := _painel("MODO DE OPERAÇÃO", "Como as partidas são liberadas", resumo, Color(0.12, 0.65, 1.0))
	box_modo.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modo_option = OptionButton.new()
	modo_option.add_item("LIVRE — SEM CRÉDITO")
	modo_option.add_item("CRÉDITO — 1 POR PARTIDA")
	modo_option.custom_minimum_size.y = 42
	modo_option.add_theme_font_size_override("font_size", 15)
	modo_option.item_selected.connect(_modo_alterado)
	box_modo.add_child(modo_option)
	creditos_label = _label("", 17, Color(1.0, 0.82, 0.12))
	box_modo.add_child(creditos_label)

	var box_stats := _painel("PARTIDAS JOGADAS", "Histórico salvo automaticamente", resumo, Color(0.65, 0.35, 1.0))
	box_stats.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	partidas_label = _label("", 16, Color.WHITE)
	box_stats.add_child(partidas_label)
	var zerar := _botao("ZERAR CONTADOR", Color(1.0, 0.48, 0.12))
	zerar.pressed.connect(_zerar_estatisticas)
	box_stats.add_child(zerar)

	var box_acoes := _painel("AÇÕES RÁPIDAS", "Créditos e dados da máquina", resumo, Color(0.08, 0.86, 0.78))
	box_acoes.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var credito_btn := _botao("+  ADICIONAR CRÉDITO", Color(0.12, 0.78, 1.0), true)
	credito_btn.pressed.connect(_adicionar_credito_manual)
	box_acoes.add_child(credito_btn)
	var mural := _botao("LIMPAR MURAL DE CAMPEÕES", Color(1.0, 0.18, 0.25))
	mural.pressed.connect(_resetar_mural)
	box_acoes.add_child(mural)
	if ArduinoBridge.tem_plugin():
		# TV Box / TV Android: o jogo abre sozinho depois que a TV liga
		var inicio := _botao("ABRIR SOZINHO AO LIGAR A TV", Color(0.18, 0.92, 0.46))
		inicio.pressed.connect(_escolher_tela_inicial)
		box_acoes.add_child(inicio)
		var sair := _botao("SAIR PARA A TELA DA TV", Color(0.7, 0.75, 0.82))
		sair.pressed.connect(_sair_para_tv)
		box_acoes.add_child(sair)

	var box_teste := _painel("DIAGNÓSTICO DOS 7 ALVOS", "Pressione o sensor físico ou selecione um alvo para testar LED + entrada", app, Color(0.08, 0.86, 0.78))
	box_teste.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	var grade := GridContainer.new()
	grade.columns = 7
	grade.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grade.add_theme_constant_override("h_separation", 10)
	box_teste.add_child(grade)
	for i in range(LEDS.size()):
		var b := _botao_alvo(i)
		b.pressed.connect(_testar_alvo.bind(i, false))
		grade.add_child(b)
		botoes_led.append(b)
	var linha_teste := HBoxContainer.new()
	linha_teste.add_theme_constant_override("separation", 10)
	box_teste.add_child(linha_teste)
	var todos := _botao("TESTAR TODOS OS LEDS", Color(0.08, 0.86, 0.78), true)
	todos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	todos.pressed.connect(_testar_todos)
	linha_teste.add_child(todos)
	# a cor errada nos LEDs (pede vermelho, acende verde...) se acerta aqui
	var ordem := _botao("ORDEM DAS CORES DOS LEDS", Color(1.0, 0.25, 0.25))
	ordem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ordem.pressed.connect(_trocar_ordem_das_cores)
	linha_teste.add_child(ordem)
	# sensores e botões na placa Zero Delay: ensina qual é qual nesta TV Box
	var ensinar := _botao("ENSINAR SENSORES E BOTÕES", Color(1.0, 0.82, 0.12))
	ensinar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ensinar.pressed.connect(_ensinar_entradas)
	linha_teste.add_child(ensinar)

	var rodape := HBoxContainer.new()
	rodape.custom_minimum_size.y = 52
	rodape.add_theme_constant_override("separation", 12)
	app.add_child(rodape)
	if ArduinoBridge.tem_plugin():
		# o estado do "abrir sozinho ao ligar" desta TV (para o suporte)
		inicio_label = _label(_texto_inicio(), 13, Color(0.62, 0.72, 0.84))
		app.add_child(inicio_label)
	var atalho := _label("F9, ESC ou VOLTAR do controle para fechar  •  setas + OK escolhem", 14, Color(0.50, 0.60, 0.70))
	atalho.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atalho.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rodape.add_child(atalho)
	var voltar := _botao("SALVAR E VOLTAR AO JOGO", Color(0.18, 0.92, 0.46), true)
	voltar.custom_minimum_size = Vector2(330, 52)
	voltar.pressed.connect(_solicitar_voltar)
	rodape.add_child(voltar)

func _painel(titulo_txt: String, subtitulo_txt: String, pai: Control, destaque: Color) -> VBoxContainer:
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override("panel", _estilo_card(destaque, Color(0.018, 0.029, 0.052, 0.98), 16, 1))
	pai.add_child(painel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	painel.add_child(box)
	var titulo := _label(titulo_txt, 18, Color.WHITE)
	box.add_child(titulo)
	box.add_child(_label(subtitulo_txt, 13, Color(0.48, 0.59, 0.70)))
	var linha := ColorRect.new()
	linha.color = Color(destaque.r, destaque.g, destaque.b, 0.75)
	linha.custom_minimum_size = Vector2(0, 2)
	box.add_child(linha)
	return box

func _label(texto: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	return l

func _botao(texto: String, cor: Color, preenchido: bool = false) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(190, 46)
	b.add_theme_font_size_override("font_size", 15)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for estado in ["normal", "hover", "pressed", "focus"]:
		var st := StyleBoxFlat.new()
		var intensidade := 0.24 if preenchido else 0.09
		if estado == "hover": intensidade += 0.16
		if estado == "pressed": intensidade += 0.28
		st.bg_color = Color(cor.r * intensidade, cor.g * intensidade, cor.b * intensidade, 0.98)
		st.border_color = Color(cor.r, cor.g, cor.b, 0.95 if estado != "normal" else 0.55)
		st.set_border_width_all(1 if estado == "normal" else 2)
		st.set_corner_radius_all(10)
		b.add_theme_stylebox_override(estado, st)
	return b

func _botao_alvo(index: int) -> Button:
	var b := _botao("ALVO  %s\n●  LED E SENSOR" % LEDS[index], CORES[index])
	b.custom_minimum_size = Vector2(120, 90)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 17)
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

func _adicionar_credito_manual() -> void:
	ArcadeData.adicionar_credito()
	_atualizar_dados()
	_mensagem("●  CRÉDITO ADICIONADO COM SUCESSO")

func _modo_alterado(index: int) -> void:
	ArcadeData.definir_modo("credito" if index == 1 else "free"); _atualizar_dados(); _mensagem("MODO DE OPERAÇÃO SALVO")

func _atualizar_dados() -> void:
	modo_option.select(1 if ArcadeData.modo_operacao == "credito" else 0)
	if ArcadeData.modo_operacao == "credito":
		if ArcadeData.creditos <= 0:
			creditos_label.text = "SEM CRÉDITOS\nInsira a ficha para liberar uma partida"
			creditos_label.add_theme_color_override("font_color", Color(1.0, 0.32, 0.25))
		else:
			creditos_label.text = "%d CRÉDITO(S) DISPONÍVEL(IS)" % ArcadeData.creditos
			creditos_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.12))
	else:
		creditos_label.text = "ACESSO LIVRE\nNenhum crédito será consumido"
		creditos_label.add_theme_color_override("font_color", Color(0.22, 1.0, 0.48))
	partidas_label.text = "TOTAL   %d\nARCADE   %d\nCOPA     %d" % [ArcadeData.partidas_total, ArcadeData.partidas_arcade, ArcadeData.partidas_copa]

func _zerar_estatisticas() -> void:
	ArcadeData.zerar_estatisticas(); _atualizar_dados(); _mensagem("CONTADOR DE PARTIDAS ZERADO")

func _resetar_mural() -> void:
	ChampionsDb.limpar_tudo(); _mensagem("MURAL DE CAMPEÕES RESETADO")

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

func _mensagem(texto: String) -> void: status_label.text = texto

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
	var erro := get_tree().change_scene_to_file(CENA_OPENING)
	if erro != OK:
		voltando = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
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

func _exit_tree() -> void: _serial_write("OFF")


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
	if inicio_label != null:
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
