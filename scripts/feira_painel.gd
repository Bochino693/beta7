extends Control

## O PAINEL DO MODO FEIRA na Central da Máquina (scripts/leads.gd faz o
## trabalho): liga / desliga o cadastro dos jogadores, o nome do evento, o
## estado do pendrive, a data dos cadastros e apagar tudo.
## Desenhado para 1280 x 720 (a Central inteira cresce junto com a tela).

signal fechou

const VERDE := Color(0.30, 1.0, 0.50)
const AMARELO := Color(1.0, 0.84, 0.10)
const AZUL := Color(0.18, 0.78, 1.0)
const VERMELHO := Color(1.0, 0.30, 0.30)

var _bt_liga: Button
var _contas: Label
var _evento: LineEdit
var _pen: Label
var _data: Label
var _bt_apagar: Button
var _apagar_em := 0
var _recado: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.0, 0.02, 0.06, 0.86)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)

	var cartao := Panel.new()
	cartao.size = Vector2(1120, 640)
	cartao.position = (size - cartao.size) * 0.5 if size.x > 0.0 else Vector2(80, 40)
	cartao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cartao.add_theme_stylebox_override("panel", _caixa(Color(0.03, 0.055, 0.10, 0.99), VERDE, 24, 2))
	add_child(cartao)

	_rotulo(cartao, "MODO FEIRA", 34, Color.WHITE, Vector2(34, 18), Vector2(500, 44))
	_rotulo(cartao, "Antes de cada partida, cada jogador informa E-MAIL, NOME e IDADE (a data entra sozinha). Os cadastros vão para o pendrive.",
		15, Color(0.62, 0.72, 0.84), Vector2(34, 60), Vector2(1052, 26))

	# 1. liga / desliga + as contas
	_bt_liga = _botao(cartao, "", Vector2(34, 100), Vector2(430, 64), VERDE, 24)
	_bt_liga.pressed.connect(_trocar)
	_contas = _rotulo(cartao, "", 20, Color.WHITE, Vector2(490, 100), Vector2(596, 64))

	# 2. o evento
	_rotulo(cartao, "NOME DO EVENTO", 15, AZUL, Vector2(34, 184), Vector2(190, 46))
	_evento = LineEdit.new()
	_evento.position = Vector2(224, 184)
	_evento.size = Vector2(540, 46)
	_evento.max_length = 40
	_evento.placeholder_text = "ex.: FEIRA DE BRINQUEDOS 2026  (vai para as planilhas)"
	_evento.text = Leads.evento
	_evento.context_menu_enabled = false
	_evento.virtual_keyboard_enabled = false
	_evento.set_meta("titulo", "NOME DO EVENTO / FEIRA")
	_evento.add_theme_font_size_override("font_size", 18)
	_evento.add_theme_stylebox_override("normal", _caixa(Color(0.02, 0.04, 0.08), Color(0.30, 0.48, 0.72), 10, 1))
	_evento.text_changed.connect(func(t: String) -> void: Leads.definir_evento(t))
	cartao.add_child(_evento)

	# 3. o pendrive
	var linha1 := _linha(cartao, 250)
	_rotulo(linha1, "PENDRIVE", 15, AZUL, Vector2(16, 8), Vector2(160, 24))
	_pen = _rotulo(linha1, "", 16, Color.WHITE, Vector2(16, 32), Vector2(1020, 46))
	_pen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pen.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var gravar := _botao(cartao, "GRAVAR NO PENDRIVE AGORA", Vector2(34, 348), Vector2(380, 50), AZUL, 17)
	gravar.pressed.connect(_gravar)
	if OS.get_name() == "Android":
		var escolher := _botao(cartao, "ESCOLHER A PASTA DO PENDRIVE", Vector2(430, 348), Vector2(380, 50), Color(0.72, 0.80, 0.92), 17)
		escolher.pressed.connect(_escolher)

	# 4. a data dos cadastros
	var linha2 := _linha(cartao, 416)
	_rotulo(linha2, "DATA E HORA DOS CADASTROS", 15, AZUL, Vector2(16, 8), Vector2(300, 24))
	_data = _rotulo(linha2, "", 22, Color.WHITE, Vector2(16, 32), Vector2(420, 46))
	var x := 452.0
	for par in [["DIA", "dia"], ["MÊS", "mes"], ["ANO", "ano"], ["HORA", "hora"], ["MIN", "minuto"]]:
		_rotulo(linha2, str(par[0]), 13, Color(0.62, 0.72, 0.84), Vector2(x, 6), Vector2(112, 20)).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var menos := _botao(linha2, "−", Vector2(x, 28), Vector2(52, 46), Color(0.72, 0.80, 0.92), 24)
		menos.pressed.connect(_acertar.bind(str(par[1]), -1))
		var mais := _botao(linha2, "+", Vector2(x + 60, 28), Vector2(52, 46), Color(0.72, 0.80, 0.92), 24)
		mais.pressed.connect(_acertar.bind(str(par[1]), 1))
		x += 120.0

	# 5. recado, apagar e fechar
	_recado = _rotulo(cartao, "", 17, AMARELO, Vector2(34, 514), Vector2(1052, 34))
	_recado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bt_apagar = _botao(cartao, "APAGAR TODOS OS CADASTROS DA MÁQUINA", Vector2(34, 562), Vector2(460, 54), VERMELHO, 16)
	_bt_apagar.pressed.connect(_apagar)
	var fechar := _botao(cartao, "FECHAR  ✔", Vector2(786, 562), Vector2(300, 54), VERDE, 20, true)
	fechar.pressed.connect(func() -> void: fechou.emit())

	Leads.painel_aberto = true
	Leads.mudou.connect(_atualizar)
	var relogio := Timer.new()
	relogio.wait_time = 2.0
	relogio.autostart = true
	relogio.timeout.connect(_atualizar)
	add_child(relogio)
	_atualizar()


func _exit_tree() -> void:
	Leads.painel_aberto = false
	if Leads.mudou.is_connected(_atualizar):
		Leads.mudou.disconnect(_atualizar)


func _caixa(fundo: Color, borda: Color, raio: int, largura: int) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = fundo
	st.border_color = borda
	st.set_border_width_all(largura)
	st.set_corner_radius_all(raio)
	st.content_margin_left = 12
	st.content_margin_right = 12
	return st


func _rotulo(pai: Control, texto: String, tam: int, cor: Color, pos: Vector2, tamanho: Vector2) -> Label:
	var l := Label.new()
	l.text = texto
	l.position = pos
	l.size = tamanho
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.clip_text = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	pai.add_child(l)
	return l


func _linha(pai: Control, y: float) -> Panel:
	var p := Panel.new()
	p.position = Vector2(34, y)
	p.size = Vector2(1052, 84)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _caixa(Color(1, 1, 1, 0.035), Color(1, 1, 1, 0.12), 14, 1))
	pai.add_child(p)
	return p


func _botao(pai: Control, texto: String, pos: Vector2, tamanho: Vector2, cor: Color, letra: int, cheio := false) -> Button:
	var b := Button.new()
	b.text = texto
	b.position = pos
	b.size = tamanho
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", letra)
	_pintar(b, cor, cheio)
	pai.add_child(b)
	return b


func _pintar(b: Button, cor: Color, cheio: bool) -> void:
	for estado in ["normal", "hover", "pressed"]:
		var forca: float = (0.30 if cheio else 0.10) + (0.0 if estado == "normal" else 0.16)
		b.add_theme_stylebox_override(estado, _caixa(Color(cor.r * forca, cor.g * forca, cor.b * forca, 0.98), cor, 12, 2 if cheio else 1))
	for nome in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(nome, Color.WHITE if cheio else cor.lightened(0.2))


func _atualizar() -> void:
	if not is_inside_tree():
		return
	var tem: bool = Leads.tem_pendrive()
	if Leads.ligado:
		_bt_liga.text = "MODO FEIRA:  LIGADO  ✔"
	else:
		_bt_liga.text = "LIGAR O MODO FEIRA" if tem else "🔒  ESPETE O PENDRIVE PARA LIBERAR"
	_pintar(_bt_liga, VERDE if Leads.ligado else (AZUL if tem else Color(0.60, 0.65, 0.72)), Leads.ligado)
	_contas.text = "JOGADORES: %d   •   CADASTROS: %d   •   HOJE: %d" % [Leads.total(), Leads.visitas(), Leads.hoje()]
	_pen.text = Leads.texto_pendrive()
	_pen.add_theme_color_override("font_color", VERDE if _pen.text.begins_with("GRAVADO") else (AMARELO if _pen.text.begins_with("SEM") else Color.WHITE))
	_data.text = Leads.data_na_tela()
	if Leads.relogio_suspeito():
		_data.text += "   ⚠"
		if _recado.text == "":
			_recado.text = "O RELÓGIO DESTA TV ESTÁ ERRADO: acerte a data com os botões  −  +  (ou ligue a TV na internet)"


func _dizer(texto: String) -> void:
	_recado.text = texto


func _trocar() -> void:
	if not Leads.ligar(not Leads.ligado):
		# só libera com o pendrive reconhecido
		_dizer("ESPETE O PENDRIVE PRIMEIRO: o Modo Feira só liga com o pendrive reconhecido" + ("  (ou aperte ESCOLHER A PASTA DO PENDRIVE)" if OS.get_name() == "Android" else ""))
		_atualizar()
		return
	_dizer("MODO FEIRA LIGADO: toda partida pede o cadastro dos jogadores" if Leads.ligado else "MODO FEIRA DESLIGADO: as partidas começam direto")
	_atualizar()


func _gravar() -> void:
	if not Leads.tem_pendrive():
		_dizer("NÃO ACHEI PENDRIVE: espete um na USB e aperte de novo")
	elif Leads.gravar_no_pendrive():
		_dizer("GRAVADO E CONFERIDO  •  PODE TIRAR O PENDRIVE")
	else:
		_dizer("O PENDRIVE NÃO ACEITOU A GRAVAÇÃO: tente outro (formatado em FAT32 ou exFAT)")
	_atualizar()


func _escolher() -> void:
	if Leads.escolher_pendrive():
		_dizer("Na tela do Android: entre no PENDRIVE e aperte \"USAR ESTA PASTA\" / \"PERMITIR\"")
	else:
		_dizer("Esta TV não tem o seletor de pastas: os arquivos vão para a pasta Android/data/.../files do pendrive")


func _acertar(campo: String, quanto: int) -> void:
	Leads.acertar_relogio(campo, quanto)
	_dizer("DATA DOS CADASTROS ACERTADA")
	_atualizar()


func _apagar() -> void:
	var agora := Time.get_ticks_msec()
	if _apagar_em > 0 and agora - _apagar_em < 5000:
		_apagar_em = 0
		Leads.apagar_tudo()
		_bt_apagar.text = "APAGAR TODOS OS CADASTROS DA MÁQUINA"
		_dizer("CADASTROS DA MÁQUINA APAGADOS  (os arquivos do pendrive não foram mexidos)")
		_atualizar()
		return
	_apagar_em = agora
	_bt_apagar.text = "TEM CERTEZA?  APERTE DE NOVO PARA APAGAR"
	_dizer("Isto apaga os %d jogadores guardados nesta máquina. Grave no pendrive antes." % Leads.total())
