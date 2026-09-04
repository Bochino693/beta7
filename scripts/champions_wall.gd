extends Node2D

# ============================================================
# CHAMPIONS WALL  (versão "supimpa")
# Tela visual do Mural de Campeões.
# Lê o banco ChampionsDb e mostra as competições finalizadas.
#
# NOVO NESTA VERSÃO:
# - Cursor do mouse NEON gerado por código (visível e decorado).
# - Barra de FILTROS por tipo: TODOS / COPAS / TORNEIOS / CAMPEONATOS.
# - Lista rolável (já tinha) + DETALHE rolável (pódio + resumo).
# - Enquadramento por proporção, badges de tipo, medalhas no pódio.
# - Tudo lido do banco e exibido com os NOMES salvos.
#
# CTRL + TAB fecha o jogo.  VOLTAR retorna à tela inicial.
# ============================================================

const CENA_OPENING: String = "res://scenes/opening.tscn"
const FONTE_ORBITRON: String = "res://fonts/orbitron-bold.ttf"
const IMAGEM_FUNDO: String = "res://fundos/back.png"

const COR_OURO: Color = Color(1.00, 0.78, 0.16)
const COR_PRATA: Color = Color(0.78, 0.84, 0.92)
const COR_BRONZE: Color = Color(0.95, 0.52, 0.22)
const COR_NEON: Color = Color(0.10, 0.75, 1.00)
const COR_VERDE: Color = Color(0.20, 1.00, 0.35)
const COR_VERMELHO: Color = Color(1.00, 0.16, 0.16)
const COR_ROXO: Color = Color(0.62, 0.50, 1.00)

# Cores por tipo de competição.
const COR_COPA: Color = COR_OURO
const COR_TORNEIO: Color = COR_ROXO
const COR_CAMPEONATO: Color = COR_VERDE

# Filtros disponíveis (chave interna -> rótulo exibido).
const FILTROS: Array = [
	{"id": "TODOS",       "label": "TODOS"},
	{"id": "COPA",        "label": "COPAS"},
	{"id": "TORNEIO",     "label": "TORNEIOS"},
	{"id": "CAMPEONATO",  "label": "CAMPEONATOS"},
]

const CENA_RANKING: String = "res://scenes/champions_ranking.tscn"


var canvas: CanvasLayer
var root: Control

var fonte_orbitron: Font
var cursor_tex: ImageTexture = null

var reset_modal_layer: CanvasLayer = null

var lista_panel: Panel
var lista_box: VBoxContainer
var detalhe_panel: Panel
var total_label: Label
var filtros_box: HBoxContainer

var copas: Array = []
var copa_selecionada_id: String = ""
var filtro_tipo: String = "TODOS"

var fechando_jogo: bool = false

var reset_overlay: ColorRect = null
var reset_modal_aberto: bool = false


func _ready() -> void:
	get_tree().auto_accept_quit = false
	randomize()

	_travar_modo_arcade()

	# Aqui o mouse é VISÍVEL (tela de navegação), com cursor neon decorado.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_aplicar_cursor_neon()

	RenderingServer.set_default_clear_color(Color(0.004, 0.007, 0.014, 1.0))

	_carregar_fontes()
	_criar_tela()
	_conectar_banco()
	_carregar_copas()


func _exit_tree() -> void:
	# Limpa o cursor custom ao sair (a próxima cena define o seu).
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null, Input.CURSOR_POINTING_HAND)


func _travar_modo_arcade() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	get_tree().auto_accept_quit = false


func _carregar_fontes() -> void:
	if ResourceLoader.exists(FONTE_ORBITRON):
		fonte_orbitron = load(FONTE_ORBITRON)


# ============================================================
# CURSOR NEON (gerado por código — não depende de asset externo)
# ============================================================
func _aplicar_cursor_neon() -> void:
	var margem := 3
	cursor_tex = _gerar_cursor_textura(margem)

	if cursor_tex == null:
		return

	var hotspot := Vector2(margem, margem)

	# Mesmo cursor para seta e "mãozinha" -> visual consistente em tudo.
	Input.set_custom_mouse_cursor(cursor_tex, Input.CURSOR_ARROW, hotspot)
	Input.set_custom_mouse_cursor(cursor_tex, Input.CURSOR_POINTING_HAND, hotspot)


func _gerar_cursor_textura(margem: int) -> ImageTexture:
	# Forma clássica de seta de cursor.
	var base := PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(0.0, 17.0),
		Vector2(4.2, 13.2),
		Vector2(7.0, 20.4),
		Vector2(9.4, 19.4),
		Vector2(6.6, 12.4),
		Vector2(11.5, 12.4),
	])

	var escala := 1.7
	var maxx := 0.0
	var maxy := 0.0
	var poly := PackedVector2Array()

	for p in base:
		var q: Vector2 = p * escala + Vector2(float(margem), float(margem))
		poly.append(q)
		maxx = maxf(maxx, q.x)
		maxy = maxf(maxy, q.y)

	var w := int(ceil(maxx)) + margem
	var h := int(ceil(maxy)) + margem

	if w <= 2 or h <= 2:
		return null

	# Mapa de "está dentro da seta".
	var dentro: Array = []
	dentro.resize(w * h)

	for y in range(h):
		for x in range(w):
			dentro[y * w + x] = Geometry2D.is_point_in_polygon(
				Vector2(float(x) + 0.5, float(y) + 0.5),
				poly
			)

	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var branco := Color(1, 1, 1, 1)
	var neon := COR_NEON
	var glow := Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 0.42)

	# Preenche interior (branco) e marca borda (neon).
	for y in range(h):
		for x in range(w):
			if not dentro[y * w + x]:
				continue

			var eh_borda := false

			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var nx : int = x + dx
					var ny : int = y + dy

					if nx < 0 or ny < 0 or nx >= w or ny >= h:
						eh_borda = true
						continue

					if not dentro[ny * w + nx]:
						eh_borda = true

			img.set_pixel(x, y, neon if eh_borda else branco)

	# Halo neon suave de 1px ao redor.
	for y in range(h):
		for x in range(w):
			if dentro[y * w + x]:
				continue

			var perto := false

			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var nx : int = x + dx
					var ny : int = y + dy

					if nx < 0 or ny < 0 or nx >= w or ny >= h:
						continue

					if dentro[ny * w + nx]:
						perto = true

			if perto:
				img.set_pixel(x, y, glow)

	return ImageTexture.create_from_image(img)


# ============================================================
# BANCO
# ============================================================
func _conectar_banco() -> void:
	var db := get_node_or_null("/root/ChampionsDb")

	if db == null:
		push_warning("ChampionsWall: Autoload ChampionsDb não encontrado.")
		return

	var cb := Callable(self, "_carregar_copas")

	if db.has_signal("banco_atualizado"):
		if not db.is_connected("banco_atualizado", cb):
			db.connect("banco_atualizado", cb)


# ============================================================
# TELA
# ============================================================
func _criar_tela() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)

	_criar_fundo()
	_criar_header()
	_criar_barra_filtros()
	_criar_layout_principal()
	_criar_rodape()


func _criar_fundo() -> void:
	var fundo_base := ColorRect.new()
	fundo_base.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo_base.color = Color(0.006, 0.010, 0.020, 1.0)
	fundo_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fundo_base)

	if ResourceLoader.exists(IMAGEM_FUNDO):
		var img := TextureRect.new()
		img.set_anchors_preset(Control.PRESET_FULL_RECT)
		img.texture = load(IMAGEM_FUNDO)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.modulate = Color(1, 1, 1, 0.52)
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(img)

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.56)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)

	var glow_top := ColorRect.new()
	glow_top.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow_top.color = Color(COR_OURO.r, COR_OURO.g, COR_OURO.b, 0.07)
	glow_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(glow_top)


func _criar_header() -> void:
	var vp: Vector2 = get_viewport_rect().size

	var header := Panel.new()
	header.position = Vector2(24, 20)
	header.size = Vector2(vp.x - 48, 90)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_stylebox_override("panel", _style_panel(COR_OURO, 0.18, 26, 3))
	root.add_child(header)

	# Troféu decorativo.
	_label(
		header,
		"🏆",
		Vector2(26, 0),
		Vector2(56, header.size.y),
		40,
		COR_OURO,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER,
		COR_OURO
	)

	_label(
		header,
		"MURAL DE CAMPEÕES",
		Vector2(90, 12),
		Vector2(header.size.x - 460, 46),
		40,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER,
		COR_OURO
	)

	_label(
		header,
		"Histórico das competições finalizadas • TOP 3 com nomes, data, ID e estatísticas",
		Vector2(94, 56),
		Vector2(header.size.x - 480, 24),
		14,
		Color(0.80, 0.86, 0.92),
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER
	)

	total_label = _label(
		header,
		"0 REGISTROS",
		Vector2(header.size.x - 370, 14),
		Vector2(170, 44),
		20,
		COR_OURO,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER,
		COR_OURO
	)

	_criar_botao(
	header,
	"RANKING",
	Vector2(header.size.x - 360, 22),
	Vector2(160, 46),
	COR_ROXO,
	Callable(self, "_abrir_ranking")
)

	_criar_botao(
		header,
		"VOLTAR",
		Vector2(header.size.x - 188, 22),
		Vector2(160, 46),
		COR_NEON,
		Callable(self, "_voltar_opening")
	)


func _criar_barra_filtros() -> void:
	var vp: Vector2 = get_viewport_rect().size

	var barra := Panel.new()
	barra.position = Vector2(24, 120)
	barra.size = Vector2(vp.x - 48, 50)
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra.add_theme_stylebox_override("panel", _style_panel(COR_NEON, 0.10, 16, 2))
	root.add_child(barra)

	_label(
		barra,
		"FILTRAR:",
		Vector2(22, 0),
		Vector2(110, barra.size.y),
		15,
		Color(0.74, 0.82, 0.90),
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER
	)

	filtros_box = HBoxContainer.new()
	filtros_box.position = Vector2(128, 7)
	filtros_box.size = Vector2(barra.size.x - 150, barra.size.y - 14)
	filtros_box.add_theme_constant_override("separation", 12)
	barra.add_child(filtros_box)

	_montar_barra_filtros()


func _montar_barra_filtros() -> void:
	if filtros_box == null:
		return

	_limpar_filhos(filtros_box)

	var contagem := _contagem_por_tipo()

	for f in FILTROS:
		var id := str(f["id"])
		var label := str(f["label"])
		var qtd := int(contagem.get(id, 0))
		var cor := _cor_tipo(id) if id != "TODOS" else COR_NEON
		var ativo := (id == filtro_tipo)

		var b := Button.new()
		b.text = "%s (%d)" % [label, qtd]
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.custom_minimum_size = Vector2(150, 36)

		if fonte_orbitron:
			b.add_theme_font_override("font", fonte_orbitron)

		b.add_theme_font_size_override("font_size", 14)
		b.add_theme_color_override("font_color", Color.WHITE if ativo else Color(0.82, 0.88, 0.94))
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.add_theme_color_override("font_pressed_color", cor)

		var intens_normal := 0.70 if ativo else 0.20
		b.add_theme_stylebox_override("normal", _style_button(cor, intens_normal, 12))
		b.add_theme_stylebox_override("hover", _style_button(cor, 0.55, 12))
		b.add_theme_stylebox_override("pressed", _style_button(cor, 0.85, 12))
		b.add_theme_stylebox_override("focus", _style_button(cor, intens_normal, 12))

		b.pressed.connect(func(): _aplicar_filtro(id))

		filtros_box.add_child(b)


func _aplicar_filtro(tipo: String) -> void:
	filtro_tipo = tipo
	_montar_barra_filtros()
	_montar_lista_copas()
	_selecionar_inicial()


func _criar_layout_principal() -> void:
	var vp: Vector2 = get_viewport_rect().size

	var margem_x := 24.0
	var y := 182.0
	var h := vp.y - y - 64.0

	var lista_w := clampf(vp.x * 0.32, 430.0, 560.0)
	var detalhe_x := margem_x + lista_w + 24.0
	var detalhe_w := vp.x - detalhe_x - margem_x

	# ── Painel da lista ──
	lista_panel = Panel.new()
	lista_panel.position = Vector2(margem_x, y)
	lista_panel.size = Vector2(lista_w, h)
	lista_panel.add_theme_stylebox_override("panel", _style_panel(COR_NEON, 0.16, 24, 2))
	root.add_child(lista_panel)

	_label(
		lista_panel,
		"COMPETIÇÕES SALVAS",
		Vector2(24, 18),
		Vector2(lista_panel.size.x - 180, 38),
		22,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER,
		COR_NEON
	)

	_criar_botao(
		lista_panel,
		"ATUALIZAR",
		Vector2(lista_panel.size.x - 158, 18),
		Vector2(134, 38),
		COR_VERDE,
		Callable(self, "_carregar_copas")
	)

	var linha := ColorRect.new()
	linha.position = Vector2(24, 68)
	linha.size = Vector2(lista_panel.size.x - 48, 2)
	linha.color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 0.58)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lista_panel.add_child(linha)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 88)
	scroll.size = Vector2(lista_panel.size.x - 40, lista_panel.size.y - 112)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lista_panel.add_child(scroll)

	lista_box = VBoxContainer.new()
	lista_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista_box.add_theme_constant_override("separation", 12)
	scroll.add_child(lista_box)

	# ── Painel de detalhe ──
	detalhe_panel = Panel.new()
	detalhe_panel.position = Vector2(detalhe_x, y)
	detalhe_panel.size = Vector2(detalhe_w, h)
	detalhe_panel.clip_contents = true
	detalhe_panel.add_theme_stylebox_override("panel", _style_panel(COR_OURO, 0.14, 24, 2))
	root.add_child(detalhe_panel)


func _criar_rodape() -> void:
	var vp: Vector2 = get_viewport_rect().size

	var rodape := Panel.new()
	rodape.position = Vector2(24, vp.y - 50)
	rodape.size = Vector2(vp.x - 48, 30)
	rodape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rodape.add_theme_stylebox_override("panel", _style_panel(Color(1, 1, 1), 0.06, 10, 1))
	root.add_child(rodape)

	_label(
		rodape,
		"CLICK: selecionar   •   FILTROS: Copa / Torneio / Campeonato   •   F9: resetar mural   •   CTRL + TAB: fechar jogo   •   VOLTAR: tela inicial",
		Vector2(0, 0),
		rodape.size,
		13,
		Color(0.70, 0.78, 0.86),
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER
	)


# ============================================================
# DADOS / LISTA
# ============================================================
func _carregar_copas() -> void:
	var db := get_node_or_null("/root/ChampionsDb")

	copas.clear()

	if db != null and db.has_method("listar_copas"):
		var retorno: Variant = db.call("listar_copas")

		if retorno is Array:
			copas = retorno

	if total_label:
		total_label.text = "%d REGISTRO%s" % [
			copas.size(),
			"" if copas.size() == 1 else "S"
		]

	_montar_barra_filtros()
	_montar_lista_copas()
	_selecionar_inicial()


func _contagem_por_tipo() -> Dictionary:
	var cont := {"TODOS": copas.size(), "COPA": 0, "TORNEIO": 0, "CAMPEONATO": 0}

	for c in copas:
		if not (c is Dictionary):
			continue

		var t := str(c.get("tipo", "COPA")).to_upper()
		if cont.has(t):
			cont[t] = int(cont[t]) + 1

	return cont


func _copas_filtradas() -> Array:
	if filtro_tipo == "TODOS":
		return copas

	var res: Array = []

	for c in copas:
		if c is Dictionary and str(c.get("tipo", "COPA")).to_upper() == filtro_tipo:
			res.append(c)

	return res


func _selecionar_inicial() -> void:
	var filt := _copas_filtradas()

	if filt.is_empty():
		copa_selecionada_id = ""
		_mostrar_vazio()
		return

	var ainda_existe := false

	for c in filt:
		if c is Dictionary and str(c.get("id", "")) == copa_selecionada_id:
			ainda_existe = true
			break

	if not ainda_existe:
		var primeira: Dictionary = filt[0]
		copa_selecionada_id = str(primeira.get("id", ""))

	_mostrar_copa_por_id(copa_selecionada_id)


func _montar_lista_copas() -> void:
	if lista_box == null:
		return

	_limpar_filhos(lista_box)

	var filt := _copas_filtradas()

	if filt.is_empty():
		var msg := "Nenhuma competição salva ainda."
		if filtro_tipo != "TODOS":
			msg = "Nenhum registro deste tipo ainda."

		var vazio := _label(
			lista_box,
			msg + "\n\nFinalize uma competição para ela aparecer aqui automaticamente.",
			Vector2.ZERO,
			Vector2(lista_panel.size.x - 70, 170),
			16,
			Color(0.78, 0.84, 0.90),
			HORIZONTAL_ALIGNMENT_CENTER,
			VERTICAL_ALIGNMENT_CENTER
		)

		vazio.custom_minimum_size = Vector2(lista_panel.size.x - 70, 170)
		return

	var index := 1

	for copa_var in filt:
		if not (copa_var is Dictionary):
			continue

		_adicionar_item_lista(copa_var, index)
		index += 1


func _adicionar_item_lista(copa: Dictionary, index: int) -> void:
	var id := str(copa.get("id", ""))
	var titulo := str(copa.get("titulo", "Competição"))
	var data_txt := str(copa.get("finished_at_text", ""))
	var tipo := str(copa.get("tipo", "COPA")).to_upper()
	var tipo_nome := str(copa.get("tipo_nome", _tipo_nome_local(tipo)))
	var cor_tipo := _cor_tipo(tipo)

	var campeao := "Sem campeão"
	var top3_var: Variant = copa.get("top3", [])
	if top3_var is Array and top3_var.size() > 0 and top3_var[0] is Dictionary:
		campeao = str(top3_var[0].get("nome", "Campeão"))

	var selecionado := (id == copa_selecionada_id)
	var cor_card := COR_OURO if selecionado else cor_tipo

	# Container do item.
	var wrap := Panel.new()
	wrap.custom_minimum_size = Vector2(lista_panel.size.x - 70, 96)
	wrap.add_theme_stylebox_override("panel", _style_button(cor_card, 0.55 if selecionado else 0.20, 16))
	lista_box.add_child(wrap)

	# Barra de cor do tipo na lateral.
	var faixa := ColorRect.new()
	faixa.position = Vector2(0, 8)
	faixa.size = Vector2(6, wrap.custom_minimum_size.y - 16)
	faixa.color = cor_tipo
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(faixa)

	# Badge do tipo.
	_criar_badge_tipo(wrap, tipo_nome, cor_tipo, Vector2(18, 12))

	# Número do registro.
	_label(
		wrap,
		"#%02d" % index,
		Vector2(wrap.custom_minimum_size.x - 70, 10),
		Vector2(56, 22),
		14,
		Color(0.66, 0.74, 0.82),
		HORIZONTAL_ALIGNMENT_RIGHT,
		VERTICAL_ALIGNMENT_CENTER
	)

	# Título.
	_label(
		wrap,
		titulo,
		Vector2(18, 40),
		Vector2(wrap.custom_minimum_size.x - 36, 26),
		17,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER,
		cor_card
	)

	# Campeão + data.
	_label(
		wrap,
		"🏆 %s   •   %s" % [campeao, data_txt],
		Vector2(18, 66),
		Vector2(wrap.custom_minimum_size.x - 36, 22),
		13,
		Color(0.78, 0.85, 0.92),
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER
	)

	# Botão invisível por cima para capturar o clique no card inteiro.
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.position = Vector2.ZERO
	btn.size = wrap.custom_minimum_size
	btn.custom_minimum_size = wrap.custom_minimum_size
	var vazio_sb := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", vazio_sb)
	btn.add_theme_stylebox_override("hover", vazio_sb)
	btn.add_theme_stylebox_override("pressed", vazio_sb)
	btn.add_theme_stylebox_override("focus", vazio_sb)
	btn.pressed.connect(func():
		copa_selecionada_id = id
		_montar_lista_copas()
		_mostrar_copa(copa)
	)
	wrap.add_child(btn)


func _criar_badge_tipo(parent: Control, texto: String, cor: Color, pos: Vector2) -> void:
	var badge := Panel.new()
	badge.position = pos
	badge.size = Vector2(maxf(96.0, float(texto.length()) * 10.0 + 22.0), 22)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(cor.r * 0.18, cor.g * 0.18, cor.b * 0.18, 0.95)
	sb.border_color = Color(cor.r, cor.g, cor.b, 0.85)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(11)
	badge.add_theme_stylebox_override("panel", sb)
	parent.add_child(badge)

	_label(
		badge,
		texto.to_upper(),
		Vector2.ZERO,
		badge.size,
		11,
		cor,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER
	)


# ============================================================
# DETALHE (com rolagem)
# ============================================================
func _mostrar_vazio() -> void:
	if detalhe_panel == null:
		return

	_limpar_filhos(detalhe_panel)

	_label(
		detalhe_panel,
		"NENHUM REGISTRO SELECIONADO",
		Vector2(0, detalhe_panel.size.y * 0.36),
		Vector2(detalhe_panel.size.x, 54),
		32,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER,
		COR_OURO
	)

	_label(
		detalhe_panel,
		"Quando uma competição for finalizada, o TOP 3 será salvo aqui com nomes, ID, data, hora e estatísticas.",
		Vector2(80, detalhe_panel.size.y * 0.48),
		Vector2(detalhe_panel.size.x - 160, 80),
		17,
		Color(0.76, 0.84, 0.92),
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER
	)


func _mostrar_copa_por_id(id: String) -> void:
	for c in copas:
		if c is Dictionary and str(c.get("id", "")) == id:
			_mostrar_copa(c)
			return

	_mostrar_vazio()


func _mostrar_copa(copa: Dictionary) -> void:
	if detalhe_panel == null:
		return

	_limpar_filhos(detalhe_panel)

	var titulo := str(copa.get("titulo", "Competição"))
	var data_txt := str(copa.get("finished_at_text", ""))
	var id := str(copa.get("id", ""))
	var tipo := str(copa.get("tipo", "COPA")).to_upper()
	var tipo_nome := str(copa.get("tipo_nome", _tipo_nome_local(tipo)))
	var cor_tipo := _cor_tipo(tipo)

	# ── Cabeçalho FIXO ──
	_criar_badge_tipo(detalhe_panel, tipo_nome, cor_tipo, Vector2(34, 22))

	_label(
		detalhe_panel,
		titulo,
		Vector2(34, 50),
		Vector2(detalhe_panel.size.x - 68, 46),
		30,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER,
		COR_OURO
	)

	_label(
		detalhe_panel,
		"Finalizada em: %s        ID: %s" % [data_txt, id],
		Vector2(36, 100),
		Vector2(detalhe_panel.size.x - 72, 22),
		13,
		Color(0.70, 0.78, 0.86),
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER
	)

	var linha := ColorRect.new()
	linha.position = Vector2(34, 134)
	linha.size = Vector2(detalhe_panel.size.x - 68, 2)
	linha.color = Color(cor_tipo.r, cor_tipo.g, cor_tipo.b, 0.58)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detalhe_panel.add_child(linha)

	# ── Conteúdo ROLÁVEL ──
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 148)
	scroll.size = Vector2(detalhe_panel.size.x - 40, detalhe_panel.size.y - 148 - 18)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detalhe_panel.add_child(scroll)

	var cont := Control.new()
	var cont_w := scroll.size.x - 16
	var altura := _preencher_conteudo_detalhe(cont, cont_w, copa, cor_tipo)
	cont.custom_minimum_size = Vector2(cont_w, altura)
	scroll.add_child(cont)


func _preencher_conteudo_detalhe(cont: Control, w: float, copa: Dictionary, cor_tipo: Color) -> float:
	var top3: Array = []
	var top3_var: Variant = copa.get("top3", [])
	if top3_var is Array:
		top3 = top3_var

	# ── Pódio ──
	_label(
		cont,
		"PÓDIO OFICIAL",
		Vector2(8, 4),
		Vector2(w - 16, 32),
		22,
		COR_OURO,
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER,
		COR_OURO
	)

	var gap := 16.0
	var card_w := (w - gap * 2.0) / 3.0
	var card_h := 318.0
	var podio_y := 44.0

	for i in range(3):
		var item: Dictionary = {}
		if i < top3.size() and top3[i] is Dictionary:
			item = top3[i]

		var cor := COR_OURO
		match i:
			1: cor = COR_PRATA
			2: cor = COR_BRONZE

		_criar_card_top3(
			cont,
			item,
			i + 1,
			Vector2(float(i) * (card_w + gap), podio_y),
			Vector2(card_w, card_h),
			cor
		)

	# ── Resumo ──
	var resumo_y := podio_y + card_h + 30.0

	_label(
		cont,
		"RESUMO DA COMPETIÇÃO",
		Vector2(8, resumo_y),
		Vector2(w - 16, 32),
		20,
		COR_NEON,
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER,
		COR_NEON
	)

	var resumo: Dictionary = {}
	var resumo_var: Variant = copa.get("resumo", {})
	if resumo_var is Dictionary:
		resumo = resumo_var

	var painel_y := resumo_y + 44.0
	var painel_h := 178.0

	var painel := Panel.new()
	painel.position = Vector2(0, painel_y)
	painel.size = Vector2(w, painel_h)
	painel.add_theme_stylebox_override("panel", _style_panel(COR_NEON, 0.10, 18, 2))
	cont.add_child(painel)

	var partidas := int(resumo.get("partidas_total", 0))
	var grupos := int(resumo.get("grupos_total", 0))
	var jogadores_reais := int(resumo.get("jogadores_reais", 0))
	var gols_top3 := int(resumo.get("gols_top3", 0))
	var fase_final := str(resumo.get("fase_final", "Competição encerrada"))

	var col_w := painel.size.x / 4.0

	_criar_bloco_resumo(painel, "PARTIDAS", str(partidas), Vector2(0, 22), Vector2(col_w, 82), COR_OURO)
	_criar_bloco_resumo(painel, "GRUPOS", str(grupos), Vector2(col_w, 22), Vector2(col_w, 82), COR_NEON)
	_criar_bloco_resumo(painel, "JOGADORES", str(jogadores_reais), Vector2(col_w * 2.0, 22), Vector2(col_w, 82), COR_VERDE)
	_criar_bloco_resumo(painel, "GOLS TOP 3", str(gols_top3), Vector2(col_w * 3.0, 22), Vector2(col_w, 82), COR_BRONZE)

	_label(
		painel,
		"Status: %s" % fase_final,
		Vector2(22, 124),
		Vector2(painel.size.x - 44, 30),
		15,
		Color(0.78, 0.84, 0.92),
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER
	)

	# Altura total do conteúdo rolável.
	return painel_y + painel_h + 16.0


func _criar_card_top3(parent: Control, item: Dictionary, posicao: int, pos: Vector2, tamanho: Vector2, cor: Color) -> void:
	var card := Panel.new()
	card.position = pos
	card.size = tamanho
	card.clip_contents = true
	card.add_theme_stylebox_override("panel", _style_panel(cor, 0.18, 22, 3))
	parent.add_child(card)

	# Medalha circular.
	var medalha := Panel.new()
	medalha.size = Vector2(48, 48)
	medalha.position = Vector2((card.size.x - 48) * 0.5, 14)
	medalha.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var msb := StyleBoxFlat.new()
	msb.bg_color = Color(cor.r * 0.22, cor.g * 0.20, cor.b * 0.16, 1.0)
	msb.border_color = cor
	msb.set_border_width_all(3)
	msb.set_corner_radius_all(24)
	msb.shadow_color = Color(cor.r, cor.g, cor.b, 0.55)
	msb.shadow_size = 12
	medalha.add_theme_stylebox_override("panel", msb)
	card.add_child(medalha)

	_label(
		medalha,
		"%dº" % posicao,
		Vector2.ZERO,
		medalha.size,
		22,
		cor,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER,
		cor
	)

	var nome := _ler_txt(item, ["nome", "name", "jogador", "player_name", "player"], "---")
	var grupo := _ler_txt(item, ["grupo", "grupo_nome"], "-")
	var fase := _ler_txt(item, ["fase_nome", "fase"], "-")

	var gols_normais := _ler_num(item, [
		"gols_normais",
		"gols_normal",
		"gols_tempo_normal",
		"normal_gols"
	])

	var gols_prorrogacao := _ler_num(item, [
		"gols_prorrogacao",
		"gols_prorro",
		"gols_extra",
		"prorrogacao_gols"
	])

	var penaltis := _ler_num(item, [
		"penaltis_total",
		"penaltis",
		"penaltis_marcados",
		"gols_penalti",
		"gols_penaltis"
	])

	var gols := _ler_num(item, [
		"gols_total",
		"gols",
		"score",
		"pontuacao"
	])

	if gols == 0 and (gols_normais > 0 or gols_prorrogacao > 0 or penaltis > 0):
		gols = gols_normais + gols_prorrogacao + penaltis

	var vitorias := _ler_num(item, [
		"vitorias_total",
		"vitorias",
		"wins",
		"partidas_vencidas"
	])

	var jogos := _ler_num(item, [
		"jogos_total",
		"jogos",
		"partidas",
		"partidas_jogadas",
		"jogos_disputados",
		"matches"
	])

	var pontos := _ler_num(item, [
		"pontos_grupo",
		"pontos",
		"pontos_tabela",
		"pts"
	])

	# Nome.
	_label(
		card,
		nome,
		Vector2(12, 70),
		Vector2(card.size.x - 24, 40),
		23,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER,
		cor
	)

	_label(
		card,
		"Grupo %s  •  %s" % [grupo, fase],
		Vector2(10, 112),
		Vector2(card.size.x - 20, 22),
		12,
		Color(0.74, 0.82, 0.90),
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER
	)

	var sep := ColorRect.new()
	sep.position = Vector2(card.size.x * 0.12, 142)
	sep.size = Vector2(card.size.x * 0.76, 1)
	sep.color = Color(cor.r, cor.g, cor.b, 0.30)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sep)

	# Grade de estatísticas.
	var margem := 14.0
	var gap := 8.0
	var stat_w := (card.size.x - margem * 2.0 - gap) / 2.0

	_criar_linha_stat(card, "GOLS", str(gols), Vector2(margem, 154), cor, stat_w)
	_criar_linha_stat(card, "PARTIDAS", str(jogos), Vector2(margem + stat_w + gap, 154), cor, stat_w)

	_criar_linha_stat(card, "VITÓRIAS", str(vitorias), Vector2(margem, 214), cor, stat_w)
	_criar_linha_stat(card, "PONTOS", str(pontos), Vector2(margem + stat_w + gap, 214), cor, stat_w)

	var detalhe_gols := "Normal: %d   •   Prorr.: %d   •   Pên.: %d" % [
		gols_normais,
		gols_prorrogacao,
		penaltis
	]

	_label(
		card,
		detalhe_gols,
		Vector2(8, card.size.y - 34),
		Vector2(card.size.x - 16, 24),
		11,
		Color(0.80, 0.86, 0.92),
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER
	)


func _criar_linha_stat(parent: Control, titulo: String, valor: String, pos: Vector2, cor: Color, largura: float = 130.0) -> void:
	var box := Panel.new()
	box.position = pos
	box.size = Vector2(largura, 54)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.z_index = 20
	box.add_theme_stylebox_override("panel", _style_button(cor, 0.38, 12))
	parent.add_child(box)

	var titulo_lbl := Label.new()
	titulo_lbl.text = titulo
	titulo_lbl.position = Vector2(4, 4)
	titulo_lbl.size = Vector2(box.size.x - 8, 16)
	titulo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo_lbl.clip_text = false
	titulo_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if fonte_orbitron:
		titulo_lbl.add_theme_font_override("font", fonte_orbitron)

	titulo_lbl.add_theme_font_size_override("font_size", 10)
	titulo_lbl.add_theme_color_override("font_color", Color(0.72, 0.82, 0.92))
	box.add_child(titulo_lbl)

	var valor_final := valor.strip_edges()
	if valor_final == "":
		valor_final = "0"

	var valor_lbl := Label.new()
	valor_lbl.text = valor_final
	valor_lbl.position = Vector2(4, 17)
	valor_lbl.size = Vector2(box.size.x - 8, 32)
	valor_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	valor_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	valor_lbl.clip_text = false
	valor_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	valor_lbl.z_index = 30

	if fonte_orbitron:
		valor_lbl.add_theme_font_override("font", fonte_orbitron)

	valor_lbl.add_theme_font_size_override("font_size", 24)
	valor_lbl.add_theme_color_override("font_color", Color.WHITE)
	valor_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	valor_lbl.add_theme_constant_override("outline_size", 4)
	valor_lbl.add_theme_color_override("font_shadow_color", cor)
	valor_lbl.add_theme_constant_override("shadow_offset_x", 0)
	valor_lbl.add_theme_constant_override("shadow_offset_y", 0)

	box.add_child(valor_lbl)


func _criar_bloco_resumo(parent: Control, titulo: String, valor: String, pos: Vector2, tamanho: Vector2, cor: Color) -> void:
	_label(
		parent,
		titulo,
		pos,
		Vector2(tamanho.x, 24),
		13,
		Color(0.68, 0.76, 0.84),
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER
	)

	_label(
		parent,
		valor,
		pos + Vector2(0, 28),
		Vector2(tamanho.x, 44),
		32,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER,
		cor
	)


# ============================================================
# HELPERS DE TIPO / COR
# ============================================================
func _cor_tipo(tipo: String) -> Color:
	match tipo.to_upper():
		"TORNEIO":
			return COR_TORNEIO
		"CAMPEONATO":
			return COR_CAMPEONATO
		_:
			return COR_COPA


func _tipo_nome_local(tipo: String) -> String:
	match tipo.to_upper():
		"TORNEIO":
			return "Torneio"
		"CAMPEONATO":
			return "Campeonato"
		_:
			return "Copa"


# ============================================================
# UI BÁSICA
# ============================================================
func _criar_botao(parent: Control, txt: String, pos: Vector2, tamanho: Vector2, cor: Color, acao: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.position = pos
	b.size = tamanho
	b.custom_minimum_size = tamanho
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if fonte_orbitron:
		b.add_theme_font_override("font", fonte_orbitron)

	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", cor)

	b.add_theme_stylebox_override("normal", _style_button(cor, 0.22, 14))
	b.add_theme_stylebox_override("hover", _style_button(cor, 0.55, 14))
	b.add_theme_stylebox_override("pressed", _style_button(cor, 0.82, 14))
	b.add_theme_stylebox_override("focus", _style_button(cor, 0.36, 14))

	b.pressed.connect(acao)

	parent.add_child(b)
	return b


func _label(
	parent: Control,
	txt: String,
	pos: Vector2,
	tamanho: Vector2,
	font_size: int,
	cor: Color,
	h_align := HORIZONTAL_ALIGNMENT_LEFT,
	v_align := VERTICAL_ALIGNMENT_CENTER,
	sombra: Color = Color.TRANSPARENT
) -> Label:
	var l := Label.new()
	l.text = txt
	l.position = pos
	l.size = tamanho
	l.horizontal_alignment = h_align
	l.vertical_alignment = v_align
	l.clip_text = true
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if fonte_orbitron:
		l.add_theme_font_override("font", fonte_orbitron)

	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", cor)

	if sombra.a > 0.0:
		l.add_theme_color_override("font_shadow_color", sombra)
		l.add_theme_constant_override("shadow_offset_x", 0)
		l.add_theme_constant_override("shadow_offset_y", 0)

	parent.add_child(l)
	return l


func _style_panel(cor: Color, alpha_bg: float, radius: int, border: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.008 + cor.r * 0.05, 0.012 + cor.g * 0.04, 0.020 + cor.b * 0.04, 0.92 + alpha_bg * 0.25)
	s.border_color = Color(cor.r, cor.g, cor.b, 0.84)
	s.set_border_width_all(border)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(cor.r, cor.g, cor.b, 0.28 + alpha_bg)
	s.shadow_size = 24
	s.shadow_offset = Vector2.ZERO
	return s


func _style_button(cor: Color, intensidade: float, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(cor.r * 0.09, cor.g * 0.08, cor.b * 0.08, 0.94)
	s.border_color = Color(cor.r, cor.g, cor.b, 0.92)
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(cor.r, cor.g, cor.b, intensidade)
	s.shadow_size = 14
	s.shadow_offset = Vector2.ZERO
	return s


func _limpar_filhos(n: Node) -> void:
	if n == null:
		return

	for child in n.get_children():
		n.remove_child(child)
		child.queue_free()


func _voltar_opening() -> void:
	if ResourceLoader.exists(CENA_OPENING):
		get_tree().set_meta("pular_patrocinadores_opening_uma_vez", true)
		get_tree().change_scene_to_file(CENA_OPENING)
	else:
		push_error("Cena opening não encontrada: " + CENA_OPENING)


# ============================================================
# INPUT / FECHAMENTO
# ============================================================
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	if not event.pressed or event.echo:
		return

	var viewport := get_viewport()

	# F9 abre modal de reset do mural.
	if event.keycode == KEY_F9:
		if viewport:
			viewport.set_input_as_handled()

		_mostrar_modal_resetar_mural()
		return

	# CTRL + TAB fecha o jogo.
	if event.ctrl_pressed and event.keycode == KEY_TAB:
		if viewport:
			viewport.set_input_as_handled()

		_fechar_jogo_arcade()
		return

	# Bloqueia ESC.
	if event.keycode == KEY_ESCAPE:
		if viewport:
			viewport.set_input_as_handled()
		return

	# Bloqueia ALT + F4.
	if event.alt_pressed and event.keycode == KEY_F4:
		if viewport:
			viewport.set_input_as_handled()
		return

	# Bloqueia ALT + TAB.
	if event.alt_pressed and event.keycode == KEY_TAB:
		if viewport:
			viewport.set_input_as_handled()
		return

	# Bloqueia CTRL + ESC.
	if event.ctrl_pressed and event.keycode == KEY_ESCAPE:
		if viewport:
			viewport.set_input_as_handled()
		return


func _mostrar_modal_resetar_mural() -> void:
	if reset_modal_layer != null and is_instance_valid(reset_modal_layer):
		return

	var vp: Vector2 = get_viewport_rect().size

	reset_modal_layer = CanvasLayer.new()
	reset_modal_layer.layer = 300
	add_child(reset_modal_layer)

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.82)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reset_modal_layer.add_child(overlay)

	var painel := Panel.new()
	painel.size = Vector2(760, 360)
	painel.position = (vp - painel.size) * 0.5
	painel.add_theme_stylebox_override("panel", _style_panel(COR_VERMELHO, 0.22, 24, 3))
	reset_modal_layer.add_child(painel)

	_label(
		painel,
		"RESETAR MURAL DE CAMPEÕES?",
		Vector2(30, 36),
		Vector2(painel.size.x - 60, 48),
		28,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER,
		COR_VERMELHO
	)

	_label(
		painel,
		"Essa ação vai apagar todas as competições salvas em user://champions_wall.json.\n\nUse apenas se quiser limpar completamente o histórico do pódio de campeões.",
		Vector2(60, 108),
		Vector2(painel.size.x - 120, 110),
		16,
		Color(0.82, 0.88, 0.94),
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER
	)

	_criar_botao(
		painel,
		"CANCELAR",
		Vector2(90, 260),
		Vector2(250, 56),
		COR_NEON,
		Callable(self, "_fechar_modal_resetar_mural")
	)

	_criar_botao(
		painel,
		"RESETAR TUDO",
		Vector2(painel.size.x - 340, 260),
		Vector2(250, 56),
		COR_VERMELHO,
		Callable(self, "_confirmar_resetar_mural")
	)


func _fechar_modal_resetar_mural() -> void:
	if reset_modal_layer != null and is_instance_valid(reset_modal_layer):
		reset_modal_layer.queue_free()

	reset_modal_layer = null


func _confirmar_resetar_mural() -> void:
	var db := get_node_or_null("/root/ChampionsDb")

	if db == null:
		push_warning("Reset do mural falhou: ChampionsDb não encontrado no Autoload.")
		_fechar_modal_resetar_mural()
		return

	if not db.has_method("apagar_tudo"):
		push_warning("Reset do mural falhou: ChampionsDb não tem apagar_tudo().")
		_fechar_modal_resetar_mural()
		return

	db.apagar_tudo()

	copas.clear()
	copa_selecionada_id = ""
	filtro_tipo = "TODOS"

	_fechar_modal_resetar_mural()
	_carregar_copas()

	print("MURAL DE CAMPEÕES RESETADO COM F9.")

func _unhandled_input(event: InputEvent) -> void:
	_input(event)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		return

	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		return



# ============================================================
# MODAL RESET MURAL
# ============================================================
func _mostrar_modal_reset() -> void:
	if reset_modal_aberto:
		return

	reset_modal_aberto = true

	var vp: Vector2 = get_viewport_rect().size

	reset_overlay = ColorRect.new()
	reset_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	reset_overlay.color = Color(0, 0, 0, 0.78)
	reset_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(reset_overlay)

	var modal := Panel.new()
	modal.size = Vector2(720, 330)
	modal.position = (vp - modal.size) * 0.5
	modal.add_theme_stylebox_override("panel", _style_panel(COR_VERMELHO, 0.24, 26, 3))
	reset_overlay.add_child(modal)

	_label(
		modal,
		"RESETAR MURAL DE CAMPEÕES?",
		Vector2(34, 26),
		Vector2(modal.size.x - 68, 44),
		28,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER,
		COR_VERMELHO
	)

	_label(
		modal,
		"Essa ação vai apagar todos os registros salvos em user://champions_wall.json.",
		Vector2(54, 84),
		Vector2(modal.size.x - 108, 48),
		16,
		Color(0.88, 0.92, 0.96),
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER
	)

	_label(
		modal,
		"Competições salvas atualmente: %d" % copas.size(),
		Vector2(54, 140),
		Vector2(modal.size.x - 108, 34),
		18,
		COR_OURO,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER,
		COR_OURO
	)

	_label(
		modal,
		"ENTER confirma   •   ESC ou F9 cancela",
		Vector2(54, 186),
		Vector2(modal.size.x - 108, 28),
		13,
		Color(0.74, 0.82, 0.90),
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER
	)

	_criar_botao(
		modal,
		"CANCELAR",
		Vector2(90, 248),
		Vector2(220, 52),
		COR_NEON,
		Callable(self, "_fechar_modal_reset")
	)

	_criar_botao(
		modal,
		"RESETAR TUDO",
		Vector2(modal.size.x - 310, 248),
		Vector2(220, 52),
		COR_VERMELHO,
		Callable(self, "_confirmar_reset_podio")
	)


func _fechar_modal_reset() -> void:
	reset_modal_aberto = false

	if reset_overlay != null:
		reset_overlay.queue_free()
		reset_overlay = null


func _confirmar_reset_podio() -> void:
	var db := get_node_or_null("/root/ChampionsDb")

	if db != null and db.has_method("apagar_tudo"):
		db.call("apagar_tudo")
	else:
		push_warning("ChampionsWall: não encontrei o ChampionsDb para resetar.")

	copa_selecionada_id = ""

	_fechar_modal_reset()
	_carregar_copas()


func _fechar_jogo_arcade() -> void:
	if fechando_jogo:
		return

	fechando_jogo = true

	print("FECHANDO JOGO PELO MURAL COM CTRL + TAB...")

	await get_tree().create_timer(0.08).timeout
	get_tree().quit()



func _ler_num(item: Dictionary, chaves: Array, padrao: int = 0) -> int:
	for k in chaves:
		if item.has(k):
			var v: Variant = item[k]
			if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
				return int(v)
			if typeof(v) == TYPE_STRING and str(v).is_valid_int():
				return int(str(v))
	return padrao


func _ler_txt(item: Dictionary, chaves: Array, padrao: String = "-") -> String:
	for k in chaves:
		if item.has(k):
			var s := str(item[k]).strip_edges()
			if s != "":
				return s
	return padrao



func _abrir_ranking() -> void:
	if ResourceLoader.exists(CENA_RANKING):
		get_tree().change_scene_to_file(CENA_RANKING)
	else:
		push_error("Cena de ranking não encontrada: " + CENA_RANKING)
	
	
