extends Node2D

# ============================================================
# LOBBY DO MODO COPA — v2.0
#
# SEMPRE 4 GRUPOS de 4 jogadores = 16 slots totais.
# Jogadores não preenchidos → BOOT automático (Boot 1, 2, …).
# • Nomes não podem ficar em branco  → preenche com Boot
# • Nomes não podem se repetir       → aviso inline + bloqueia
# • Mesma quantidade de Boots por grupo (distribuição balanceada)
# Redireciona para cup_lobby.tscn após confirmar grupos.
# ============================================================

# ----- CONFIG -----
const CENA_SEGUINTE: String   = "res://scenes/cup_lobby.tscn"
const FONTE_ORBITRON: String  = "res://fonts/orbitron-bold.ttf"
const SFX_SELECT: String      = "res://songs/player_select.mp3"
const SFX_CONFIRM: String     = "res://songs/game_start.mp3"
const SFX_ERRO: String        = "res://songs/player_select.mp3"   # fallback
const MUSICA_FUNDO: String    = "res://songs/song_fut.mp3"

const MIN_LETRAS_NOME: int = 3
const MIN_JOGADORES_REAIS: int = 1

const COR_COPA: Color   = Color(1.0,  0.78, 0.12)
const COR_OK: Color     = Color(0.20, 0.95, 0.40)
const COR_ERRO: Color   = Color(1.0,  0.22, 0.22)
const COR_BOOT: Color   = Color(0.45, 0.50, 0.60)

# Sempre 4 grupos de 4 jogadores
const NUM_GRUPOS: int          = 4
const JOGADORES_POR_GRUPO: int = 4
const TOTAL_SLOTS: int         = NUM_GRUPOS * JOGADORES_POR_GRUPO   # 16

const LETRAS_GRUPO: Array[String] = ["A", "B", "C", "D"]

const PALETA: Array = [
	{"nome": "VERMELHO", "cor": Color(1.00, 0.20, 0.20)},
	{"nome": "VERDE",    "cor": Color(0.20, 0.92, 0.32)},
	{"nome": "AZUL",     "cor": Color(0.12, 0.58, 1.00)},
	{"nome": "AMARELO",  "cor": Color(1.00, 0.84, 0.10)},
]

# ----- ESTADO -----
var nomes: Array[String]  = []
var grupos: Array         = []
var etapa: int            = 1
var erro_indices: Array   = []    # índices de slots com nome duplicado

var btn_sortear: Button = null

# ----- NÓS -----
var fonte_orbitron: Font
var ui_layer: CanvasLayer
var ui_root: Control
var ponteiro_layer: CanvasLayer
var ponteiro: Control

var audio_fundo: AudioStreamPlayer
var sfx_select: AudioStreamPlayer
var sfx_confirm: AudioStreamPlayer

var name_edits: Array[LineEdit]   = []
var error_labels: Array[Label]    = []
var label_erro_global: Label


# =========================================================
# READY
# =========================================================
func _ready() -> void:
	get_tree().auto_accept_quit = false
	_travar_arcade()
	randomize()

	nomes.resize(TOTAL_SLOTS)
	for i in range(TOTAL_SLOTS):
		nomes[i] = ""

	_carregar_fontes()
	_criar_fundo()
	_criar_ui_root()
	_criar_ponteiro()
	_criar_audio()

	_abrir_etapa_cadastro()


func _process(_delta: float) -> void:
	if ponteiro:
		ponteiro.position = get_viewport().get_mouse_position()


func _travar_arcade() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _carregar_fontes() -> void:
	if ResourceLoader.exists(FONTE_ORBITRON):
		fonte_orbitron = load(FONTE_ORBITRON)


# =========================================================
# FUNDO + UI ROOT + PONTEIRO
# =========================================================
func _criar_fundo() -> void:
	var cl := CanvasLayer.new()
	cl.layer = -10
	add_child(cl)

	# Fundo escuro principal
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.03, 0.045, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(bg)

	# Grade neon sutil (decorativa)
	var grid_rect := ColorRect.new()
	grid_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid_rect.color = Color(0.12, 0.58, 1.00, 0.03)
	grid_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(grid_rect)


func _criar_ui_root() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 2
	add_child(ui_layer)

	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(ui_root)


func _criar_ponteiro() -> void:
	ponteiro_layer = CanvasLayer.new()
	ponteiro_layer.layer = 128
	add_child(ponteiro_layer)

	ponteiro = Control.new()
	ponteiro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ponteiro_layer.add_child(ponteiro)

	var anel := Panel.new()
	anel.size = Vector2(34, 34)
	anel.position = Vector2(-17, -17)
	anel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.border_color = Color(0.20, 1.0, 0.85, 0.95)
	s.set_border_width_all(3)
	s.set_corner_radius_all(17)
	s.shadow_color = Color(0.20, 1.0, 0.85, 0.55)
	s.shadow_size = 10
	anel.add_theme_stylebox_override("panel", s)
	ponteiro.add_child(anel)

	var dot := Panel.new()
	dot.size = Vector2(8, 8)
	dot.position = Vector2(-4, -4)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sd := StyleBoxFlat.new()
	sd.bg_color = Color(1, 1, 1, 0.95)
	sd.set_corner_radius_all(4)
	sd.shadow_color = Color(0.20, 1.0, 0.85, 0.8)
	sd.shadow_size = 6
	dot.add_theme_stylebox_override("panel", sd)
	ponteiro.add_child(dot)


func _limpar_ui() -> void:
	if ui_root:
		for c in ui_root.get_children():
			c.queue_free()
	name_edits.clear()
	error_labels.clear()
	label_erro_global = null


# =========================================================
# ETAPA 1 — CADASTRO DOS JOGADORES (16 slots, 4 grupos)
# =========================================================
func _abrir_etapa_cadastro() -> void:
	etapa = 1
	_limpar_ui()

	var vp: Vector2 = get_viewport_rect().size

	# =========================
	# HEADER
	# =========================
	var header_bg := Panel.new()
	header_bg.size = Vector2(vp.x, 92)
	header_bg.position = Vector2.ZERO
	header_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var hbs := StyleBoxFlat.new()
	hbs.bg_color = Color(0.018, 0.022, 0.032, 0.98)
	hbs.border_color = Color(1, 1, 1, 0.14)
	hbs.set_border_width_all(0)
	hbs.border_width_bottom = 2
	hbs.shadow_color = Color(0.25, 0.70, 1.0, 0.22)
	hbs.shadow_size = 18
	header_bg.add_theme_stylebox_override("panel", hbs)
	ui_root.add_child(header_bg)

	var titulo := _label("⚽  MODO COPA", 38, Color.WHITE, Color(0.25, 0.70, 1.0, 0.55))
	titulo.position = Vector2(44, 0)
	titulo.size = Vector2(vp.x * 0.5, 92)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ui_root.add_child(titulo)

	var badge := _label("CADASTRO POR CORES  •  16 JOGADORES", 17, Color(0.78, 0.84, 0.94))
	badge.position = Vector2(vp.x - 520, 0)
	badge.size = Vector2(470, 92)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui_root.add_child(badge)

	var sub := _label(
		"Preencha 4 jogadores por cor. Depois o sorteio monta cada grupo com 1 vermelho, 1 verde, 1 azul e 1 amarelo.",
		16,
		Color(0.68, 0.74, 0.84)
	)
	sub.position = Vector2(0, 104)
	sub.size = Vector2(vp.x, 30)
	ui_root.add_child(sub)

	label_erro_global = _label("", 16, COR_ERRO)
	label_erro_global.position = Vector2(0, 136)
	label_erro_global.size = Vector2(vp.x, 28)
	ui_root.add_child(label_erro_global)

	# =========================
	# FORMULÁRIO 4 COLUNAS
	# =========================
	var form_w: float = minf(vp.x - 96.0, 1380.0)
	var form_h: float = vp.y - 292.0
	var form_x: float = (vp.x - form_w) / 2.0
	var form_y: float = 178.0

	var form := Control.new()
	form.position = Vector2(form_x, form_y)
	form.size = Vector2(form_w, form_h)
	ui_root.add_child(form)

	var gap: float = 22.0
	var col_w: float = (form_w - gap * 3.0) / 4.0

	for cor_i in range(PALETA.size()):
		var painel := _criar_painel_cadastro_cor(cor_i, Vector2(col_w, form_h))
		painel.position = Vector2(cor_i * (col_w + gap), 0)
		form.add_child(painel)

	# =========================
	# FOOTER
	# =========================
	var footer_y := vp.y - 88.0

	var dica := _label(
		"💡 Campos vazios viram Boot automático. Nomes repetidos são bloqueados.",
		15,
		Color(0.55, 0.62, 0.72)
	)
	dica.position = Vector2(48, footer_y + 6)
	dica.size = Vector2(vp.x * 0.55, 36)
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ui_root.add_child(dica)

	var btn_ok := _botao_neon(
		"SORTEAR GRUPOS  ▶",
		Vector2(vp.x - 390, footer_y - 2),
		Vector2(340, 62),
		Color(0.24, 0.95, 0.65)
	)
	btn_ok.pressed.connect(_tentar_confirmar_cadastro)
	ui_root.add_child(btn_ok)
	btn_sortear = btn_ok
	_atualizar_estado_botao_iniciar()



func _criar_painel_cadastro_grupo(g: int, tam: Vector2) -> Panel:
	var panel := Panel.new()
	panel.size = tam
	_aplicar_neon(panel, COR_COPA)

	# Header do grupo
	var header_g := Panel.new()
	header_g.position = Vector2(0, 0)
	header_g.size = Vector2(tam.x, 46)
	header_g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hgs := StyleBoxFlat.new()
	hgs.bg_color = Color(COR_COPA.r * 0.15, COR_COPA.g * 0.15, COR_COPA.b * 0.05, 0.9)
	hgs.border_color = COR_COPA
	hgs.set_border_width_all(0)
	hgs.border_width_bottom = 2
	hgs.set_corner_radius_all(0)
	hgs.corner_radius_top_left = 30
	hgs.corner_radius_top_right = 30
	header_g.add_theme_stylebox_override("panel", hgs)
	panel.add_child(header_g)

	var lbl_grupo := _label("GRUPO  %s" % LETRAS_GRUPO[g], 22, COR_COPA)
	lbl_grupo.position = Vector2(0, 0)
	lbl_grupo.size = Vector2(tam.x, 46)
	panel.add_child(lbl_grupo)

	# 4 campos de jogador
	var slot_h := (tam.y - 60.0) / float(JOGADORES_POR_GRUPO)
	for slot in range(JOGADORES_POR_GRUPO):
		var idx := g * JOGADORES_POR_GRUPO + slot
		var y_slot := 52.0 + slot * slot_h

		# Chip de cor
		var cor_slot: Color = PALETA[slot]["cor"]
		var chip := Panel.new()
		chip.position = Vector2(18, y_slot + (slot_h - 30) / 2.0)
		chip.size = Vector2(30, 30)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_theme_stylebox_override("panel", _style_chip(cor_slot))
		panel.add_child(chip)

		# LineEdit
		var edit := LineEdit.new()
		edit.placeholder_text = "Jogador %d" % (idx + 1)
		edit.text = nomes[idx]
		edit.position = Vector2(60, y_slot + (slot_h - 44) / 2.0)
		edit.size = Vector2(tam.x - 80, 44)
		edit.max_length = 14
		if fonte_orbitron:
			edit.add_theme_font_override("font", fonte_orbitron)
		edit.add_theme_font_size_override("font_size", 20)
		_estilizar_lineedit(edit, cor_slot)
		edit.text_changed.connect(func(t): _ao_alterar_nome(idx, t))
		panel.add_child(edit)
		name_edits.append(edit)

		# Label de erro inline (por slot)
		var lbl_e := _label("", 12, COR_ERRO)
		lbl_e.position = Vector2(60, y_slot + (slot_h - 44) / 2.0 + 46)
		lbl_e.size = Vector2(tam.x - 80, 18)
		lbl_e.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		panel.add_child(lbl_e)
		error_labels.append(lbl_e)

	return panel


func _ao_alterar_nome(idx: int, texto: String) -> void:
	var maiusc := texto.to_upper()
	nomes[idx] = maiusc

	# Mostra tudo em MAIÚSCULO sem perder a posição do cursor.
	if idx < name_edits.size() and is_instance_valid(name_edits[idx]):
		var edit := name_edits[idx]
		if edit.text != maiusc:
			var caret := edit.caret_column
			edit.text = maiusc
			edit.caret_column = mini(caret, maiusc.length())

	_validar_duplicatas_live()



# =========================================================
# VALIDAÇÃO
# =========================================================
func _validar_duplicatas_live() -> void:
	for i in range(error_labels.size()):
		if is_instance_valid(error_labels[i]):
			error_labels[i].text = ""

	for i in range(name_edits.size()):
		if is_instance_valid(name_edits[i]):
			var cor_index := int(i / JOGADORES_POR_GRUPO)
			var cor: Color = PALETA[cor_index]["cor"]
			_estilizar_lineedit(name_edits[i], cor)

	if is_instance_valid(label_erro_global):
		label_erro_global.text = ""

	var tem_erro := false

	# Mínimo de letras (só para campos preenchidos).
	for i in range(TOTAL_SLOTS):
		var n := nomes[i].strip_edges()
		if n != "" and n.length() < MIN_LETRAS_NOME:
			tem_erro = true
			if i < error_labels.size() and is_instance_valid(error_labels[i]):
				error_labels[i].text = "⚠ Mínimo %d letras" % MIN_LETRAS_NOME
			if i < name_edits.size() and is_instance_valid(name_edits[i]):
				_estilizar_lineedit_erro(name_edits[i])

	# Nomes duplicados.
	var mapa: Dictionary = {}
	for i in range(TOTAL_SLOTS):
		var nm := nomes[i].strip_edges().to_upper()
		if nm == "":
			continue
		if not mapa.has(nm):
			mapa[nm] = []
		mapa[nm].append(i)

	for nm in mapa:
		if mapa[nm].size() > 1:
			tem_erro = true
			for idx in mapa[nm]:
				if idx < error_labels.size() and is_instance_valid(error_labels[idx]):
					error_labels[idx].text = "⚠ Nome duplicado"
				if idx < name_edits.size() and is_instance_valid(name_edits[idx]):
					_estilizar_lineedit_erro(name_edits[idx])

	if tem_erro and is_instance_valid(label_erro_global):
		label_erro_global.text = "⚠ Corrija os nomes destacados (mínimo %d letras, sem repetir)." % MIN_LETRAS_NOME

	_atualizar_estado_botao_iniciar()


func _contar_nomes_validos() -> int:
	var c := 0
	for i in range(TOTAL_SLOTS):
		if nomes[i].strip_edges().length() >= MIN_LETRAS_NOME:
			c += 1
	return c


func _cadastro_ok_para_iniciar() -> bool:
	var mapa: Dictionary = {}
	var validos := 0

	for i in range(TOTAL_SLOTS):
		var n := nomes[i].strip_edges()
		if n == "":
			continue

		if n.length() < MIN_LETRAS_NOME:
			return false

		var chave := n.to_upper()
		if mapa.has(chave):
			return false
		mapa[chave] = true
		validos += 1

	return validos >= MIN_JOGADORES_REAIS


func _atualizar_estado_botao_iniciar() -> void:
	if not is_instance_valid(btn_sortear):
		return

	var liberar := _cadastro_ok_para_iniciar()
	btn_sortear.disabled = not liberar
	btn_sortear.modulate = Color(1, 1, 1, 1.0) if liberar else Color(1, 1, 1, 0.32)


func _estilizar_lineedit_erro(edit: LineEdit) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.15, 0.03, 0.03, 0.95)
	s.border_color = COR_ERRO
	s.set_border_width_all(2)
	s.set_corner_radius_all(12)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.shadow_color = Color(COR_ERRO.r, COR_ERRO.g, COR_ERRO.b, 0.45)
	s.shadow_size = 8
	edit.add_theme_stylebox_override("normal", s)
	edit.add_theme_stylebox_override("focus", s)


func _tentar_confirmar_cadastro() -> void:
	# Segurança extra: não passa sem 8 jogadores válidos e nomes corretos.
	if not _cadastro_ok_para_iniciar():
		_play_select()
		_validar_duplicatas_live()

		if is_instance_valid(label_erro_global):
			if _contar_nomes_validos() < MIN_JOGADORES_REAIS:
				label_erro_global.text = "⚠ Cadastre no mínimo %d jogadores (mínimo %d letras cada)." % [MIN_JOGADORES_REAIS, MIN_LETRAS_NOME]
			else:
				label_erro_global.text = "⚠ Corrija os nomes (mínimo %d letras e sem repetir)." % MIN_LETRAS_NOME
		return

	_preencher_boots()
	_montar_grupos()

	_play_confirm()
	_abrir_etapa_grupos()



func _preencher_boots() -> void:
	var boot_counter := 1

	for cor_index in range(PALETA.size()):
		for slot in range(JOGADORES_POR_GRUPO):
			var idx := _idx_cor_slot(cor_index, slot)
			var n := nomes[idx].strip_edges()

			if n == "":
				var nome_boot := ""

				while true:
					nome_boot = "Boot %d" % boot_counter

					var conflita := false
					for j in range(TOTAL_SLOTS):
						if nomes[j].strip_edges().to_upper() == nome_boot.to_upper():
							conflita = true
							break

					if not conflita:
						break

					boot_counter += 1

				nomes[idx] = nome_boot
				boot_counter += 1



# =========================================================
# MONTAGEM DOS GRUPOS
# =========================================================
func _montar_grupos() -> void:
	grupos.clear()

	var listas_por_cor: Array = []

	# Cria 4 potes: vermelho, verde, azul e amarelo.
	for cor_index in range(PALETA.size()):
		var lista_cor: Array = []

		for slot in range(JOGADORES_POR_GRUPO):
			var idx: int = _idx_cor_slot(cor_index, slot)
			var nome: String = nomes[idx].strip_edges()
			var eh_boot: bool = nome.begins_with("Boot ")

			lista_cor.append({
				"nome": nome,
				"cor_index": cor_index,
				"cor": PALETA[cor_index]["cor"],
				"cor_nome": PALETA[cor_index]["nome"],
				"boot": eh_boot,

				# Estatísticas já zeradas para o lobby não precisar corrigir depois.
				"pontos": 0,
				"jogos": 0,
				"gols": 0,
				"gols_pro": 0,
				"gols_contra": 0,
				"saldo": 0,
				"vitorias": 0,
				"empates": 0,
				"derrotas": 0,
				"melhor_posicao": 99,
				"ultima_posicao": 99
			})

		# Sorteia cada pote de cor.
		lista_cor.shuffle()
		listas_por_cor.append(lista_cor)

	# Cada grupo recebe 1 jogador de cada cor.
	for g in range(NUM_GRUPOS):
		var jogadores_grupo: Array = []

		for cor_index in range(PALETA.size()):
			jogadores_grupo.append(listas_por_cor[cor_index][g])

		# Sorteia a ordem visual dentro do grupo.
		jogadores_grupo.shuffle()

		grupos.append({
			"grupo": LETRAS_GRUPO[g],
			"jogadores": jogadores_grupo,
			"sorteio_confirmado_setup": true
		})


# =========================================================
# ETAPA 2 — EXIBIÇÃO DOS GRUPOS (layout SaaS elegante)
# =========================================================
func _abrir_etapa_grupos() -> void:
	etapa = 2
	_limpar_ui()

	var vp := get_viewport_rect().size

	# Header
	var header_bg := Panel.new()
	header_bg.size = Vector2(vp.x, 80)
	header_bg.position = Vector2(0, 0)
	header_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hbs := StyleBoxFlat.new()
	hbs.bg_color = Color(0.03, 0.04, 0.06, 0.98)
	hbs.border_color = COR_COPA
	hbs.set_border_width_all(0)
	hbs.border_width_bottom = 2
	hbs.shadow_color = Color(COR_COPA.r, COR_COPA.g, COR_COPA.b, 0.35)
	hbs.shadow_size = 16
	header_bg.add_theme_stylebox_override("panel", hbs)
	ui_root.add_child(header_bg)

	var titulo := _label("⚽  GRUPOS DA COPA", 36, Color.WHITE, COR_COPA)
	titulo.position = Vector2(0, 0)
	titulo.size = Vector2(vp.x, 80)
	ui_root.add_child(titulo)

	var sub := _label("Sorteio concluído  •  4 grupos  •  4 jogadores por grupo", 17, Color(0.70, 0.76, 0.86))
	sub.position = Vector2(0, 84)
	sub.size = Vector2(vp.x, 28)
	ui_root.add_child(sub)

	# Linha divisória
	var linha := ColorRect.new()
	linha.color = Color(COR_COPA.r, COR_COPA.g, COR_COPA.b, 0.25)
	linha.size = Vector2(vp.x * 0.7, 1)
	linha.position = Vector2(vp.x * 0.15, 116)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(linha)

	# Grid 2×2 centralizado
	var card_w := 520.0
	var card_h := 300.0
	var gap_x := 34.0
	var gap_y := 24.0
	var total_w := card_w * 2 + gap_x
	var total_h := card_h * 2 + gap_y
	var origin_x := (vp.x - total_w) / 2.0
	var origin_y := 142.0

	# Ajuste se não couber
	var available_h := vp.y - 220.0
	if total_h > available_h:
		var scale_factor := available_h / total_h
		card_h = card_h * scale_factor
		gap_y = gap_y * scale_factor
		total_h = card_h * 2 + gap_y

	for g in range(NUM_GRUPOS):
		var col := g % 2
		var row := g / 2
		var px := origin_x + col * (card_w + gap_x)
		var py := origin_y + row * (card_h + gap_y)

		var card := _criar_card_grupo_resultado(g, Vector2(card_w, card_h))
		card.position = Vector2(px, py)
		ui_root.add_child(card)

		# Animação de entrada
		card.modulate = Color(1, 1, 1, 0)
		card.position.y += 18
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_interval(0.06 * g)
		tw.tween_property(card, "modulate:a", 1.0, 0.30)
		tw.tween_property(card, "position:y", py, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Rodapé
	var footer_y := vp.y - 84.0

	var btn_voltar := _botao_neon("◀  EDITAR", Vector2(48, footer_y), Vector2(260, 60), Color(0.7, 0.75, 0.82))
	btn_voltar.pressed.connect(_voltar_para_cadastro)
	ui_root.add_child(btn_voltar)

	# Estatística de boots
	var total_boots := _contar_boots()
	var lbl_stat := ""
	if total_boots > 0:
		lbl_stat = "🤖  %d Boot%s incluído%s" % [total_boots, "s" if total_boots > 1 else "", "s" if total_boots > 1 else ""]
	else:
		lbl_stat = "✅  Sem Boots — todos os slots preenchidos"
	var lbl_boots := _label(lbl_stat, 16, COR_BOOT if total_boots > 0 else COR_OK)
	lbl_boots.position = Vector2(0, footer_y + 10)
	lbl_boots.size = Vector2(vp.x, 40)
	ui_root.add_child(lbl_boots)

	var btn_ok := _botao_neon("CONFIRMAR E INICIAR  ▶", Vector2(vp.x - 380, footer_y), Vector2(340, 60), COR_OK)
	btn_ok.pressed.connect(_salvar_e_ir)
	ui_root.add_child(btn_ok)


func _contar_boots() -> int:
	var c := 0
	for g in grupos:
		for j in g["jogadores"]:
			if j["boot"]:
				c += 1
	return c


func _criar_card_grupo_resultado(g: int, tam: Vector2) -> Panel:
	var dados: Dictionary = grupos[g]
	var jogadores: Array = dados["jogadores"]

	var panel := Panel.new()
	panel.size = tam

	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.018, 0.023, 0.033, 0.98)
	s.border_color = Color(1, 1, 1, 0.16)
	s.set_border_width_all(2)
	s.set_corner_radius_all(24)
	s.shadow_color = Color(0.25, 0.70, 1.0, 0.18)
	s.shadow_size = 22
	s.shadow_offset = Vector2.ZERO
	panel.add_theme_stylebox_override("panel", s)

	var faixa := Panel.new()
	faixa.position = Vector2.ZERO
	faixa.size = Vector2(tam.x, 54)
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fs := StyleBoxFlat.new()
	fs.bg_color = Color(0.04, 0.05, 0.07, 0.95)
	fs.set_border_width_all(0)
	fs.set_corner_radius_all(0)
	fs.corner_radius_top_left = 22
	fs.corner_radius_top_right = 22
	faixa.add_theme_stylebox_override("panel", fs)
	panel.add_child(faixa)

	var lbl_grupo := _label("GRUPO %s" % dados["grupo"], 24, Color.WHITE, Color(0.25, 0.70, 1.0, 0.45))
	lbl_grupo.position = Vector2(0, 0)
	lbl_grupo.size = Vector2(tam.x, 54)
	panel.add_child(lbl_grupo)

	var slot_h := (tam.y - 66.0) / float(JOGADORES_POR_GRUPO)

	for slot in range(jogadores.size()):
		var j: Dictionary = jogadores[slot]
		var cor: Color = j["cor"]
		var y_slot := 62.0 + slot * slot_h
		var eh_boot: bool = j["boot"]

		var row_bg := Panel.new()
		row_bg.position = Vector2(14, y_slot + 4)
		row_bg.size = Vector2(tam.x - 28, slot_h - 8)
		row_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var rs := StyleBoxFlat.new()
		rs.bg_color = Color(1, 1, 1, 0.035)
		rs.border_color = Color(cor.r, cor.g, cor.b, 0.28)
		rs.set_border_width_all(1)
		rs.set_corner_radius_all(14)
		row_bg.add_theme_stylebox_override("panel", rs)
		panel.add_child(row_bg)

		var chip := Panel.new()
		chip.position = Vector2(30, y_slot + (slot_h - 24) / 2.0)
		chip.size = Vector2(24, 24)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_theme_stylebox_override("panel", _style_chip(COR_BOOT if eh_boot else cor))
		panel.add_child(chip)

		var nome_cor := Color(0.62, 0.68, 0.78) if eh_boot else Color.WHITE
		var nome_lbl := _label(j["nome"], 19, nome_cor)
		nome_lbl.position = Vector2(68, y_slot)
		nome_lbl.size = Vector2(tam.x - 190, slot_h)
		nome_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		panel.add_child(nome_lbl)

		var tag_txt := "BOT" if eh_boot else str(j["cor_nome"])
		var tag_cor := COR_BOOT if eh_boot else cor

		var tag := _label(tag_txt, 12, tag_cor)
		tag.position = Vector2(tam.x - 120, y_slot)
		tag.size = Vector2(92, slot_h)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		panel.add_child(tag)

	return panel



func _voltar_para_cadastro() -> void:
	_play_select()

	for i in range(TOTAL_SLOTS):
		if nomes[i].begins_with("Boot "):
			nomes[i] = ""

	grupos.clear()
	_abrir_etapa_cadastro()



# =========================================================
# SALVAR E IR PARA CUP_LOBBY
# =========================================================
func _salvar_e_ir() -> void:
	_salvar_grupos_copa()

	if audio_fundo:
		audio_fundo.stop()

	_mostrar_tela_grupos_concluidos()
	await get_tree().create_timer(1.6).timeout

	if ResourceLoader.exists(CENA_SEGUINTE):
		get_tree().change_scene_to_file(CENA_SEGUINTE)
	else:
		push_warning("cup_lobby.tscn não encontrada ainda: " + CENA_SEGUINTE)
		_mostrar_aviso_pendente()


func _salvar_grupos_copa() -> void:
	_limpar_estado_copa_antigo_antes_de_salvar()

	var cg := get_node_or_null("/root/CupGlobal")

	if cg != null:
		cg.configurar_copa_grupos(TOTAL_SLOTS, grupos)
	else:
		push_warning("CupGlobal não encontrado; usando meta da árvore como backup.")

	get_tree().set_meta("copa_total", TOTAL_SLOTS)
	get_tree().set_meta("copa_grupos", grupos)
	get_tree().set_meta("copa_grupos_confirmados_setup", true)
	get_tree().set_meta("copa_sorteio_origem", "cup_setup")

	print("=".repeat(48))
	print("COPA — GRUPOS SALVOS DEFINITIVOS (%d JOGADORES):" % TOTAL_SLOTS)

	for g in grupos:
		print("  GRUPO %s:" % g["grupo"])

		for j in g["jogadores"]:
			var tag := " [BOT]" if bool(j["boot"]) else ""
			print("    [%s] %s%s" % [str(j["cor_nome"]), str(j["nome"]), tag])

	print("=".repeat(48))


func _mostrar_tela_grupos_concluidos() -> void:
	_limpar_ui()

	var vp: Vector2 = get_viewport_rect().size

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.82)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(overlay)

	var painel := Panel.new()
	painel.size = Vector2(900, 420)
	painel.position = (vp - painel.size) / 2.0
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(painel)

	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.018, 0.024, 0.035, 0.98)
	s.border_color = Color(0.24, 0.95, 0.65, 0.95)
	s.set_border_width_all(3)
	s.set_corner_radius_all(34)
	s.shadow_color = Color(0.24, 0.95, 0.65, 0.50)
	s.shadow_size = 34
	s.shadow_offset = Vector2.ZERO
	painel.add_theme_stylebox_override("panel", s)

	var titulo := _label("✅  GRUPOS CONCLUÍDOS", 38, Color.WHITE, Color(0.24, 0.95, 0.65, 0.65))
	titulo.position = Vector2(0, 70)
	titulo.size = Vector2(900, 58)
	painel.add_child(titulo)

	var msg := _label(
		"Os grupos foram sorteados e salvos com sucesso.\nPreparando lobby da Copa...",
		22,
		Color(0.78, 0.86, 0.96)
	)
	msg.position = Vector2(70, 152)
	msg.size = Vector2(760, 110)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	painel.add_child(msg)

	var detalhe := _label("4 grupos  •  4 jogadores por grupo  •  2 classificados por grupo", 17, Color(0.58, 0.66, 0.78))
	detalhe.position = Vector2(0, 298)
	detalhe.size = Vector2(900, 32)
	painel.add_child(detalhe)




func _mostrar_aviso_pendente() -> void:
	_limpar_ui()
	var vp := get_viewport_rect().size

	var painel := Panel.new()
	painel.size = Vector2(880, 360)
	painel.position = (vp - painel.size) / 2.0
	ui_root.add_child(painel)
	_aplicar_neon(painel, COR_OK)

	var t := _label("✅  GRUPOS SALVOS COM SUCESSO!", 36, Color.WHITE, COR_OK)
	t.position = Vector2(0, 52)
	t.size = Vector2(880, 52)
	painel.add_child(t)

	var m := _label("Crie a cena  cup_lobby.tscn  para continuar.\n(res://scenes/cup_lobby.tscn)", 20, Color(0.80, 0.88, 0.96))
	m.position = Vector2(40, 130)
	m.size = Vector2(800, 140)
	m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	painel.add_child(m)

	var d := _label("CTRL + TAB  para sair", 16, Color(0.6, 0.65, 0.72))
	d.position = Vector2(0, 300)
	d.size = Vector2(880, 28)
	painel.add_child(d)


# =========================================================
# INPUT
# =========================================================
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var vp := get_viewport()

		if event.ctrl_pressed and event.keycode == KEY_TAB:
			if vp: vp.set_input_as_handled()
			_fechar_programa()
			return

		for k in [KEY_ESCAPE, KEY_META]:
			if event.keycode == k:
				if vp: vp.set_input_as_handled()
				return

		if event.alt_pressed and event.keycode in [KEY_F4, KEY_TAB]:
			if vp: vp.set_input_as_handled()
			return

		if etapa == 2:
			if event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
				if vp: vp.set_input_as_handled()
				_salvar_e_ir()


func _fechar_programa() -> void:
	print("COPA LOBBY: ENCERRANDO (CTRL + TAB)")
	if audio_fundo: audio_fundo.stop()
	get_tree().quit()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST]:
		return


# =========================================================
# ÁUDIO
# =========================================================
func _criar_audio() -> void:
	sfx_select = AudioStreamPlayer.new()
	add_child(sfx_select)
	if ResourceLoader.exists(SFX_SELECT):
		sfx_select.stream = load(SFX_SELECT)

	sfx_confirm = AudioStreamPlayer.new()
	add_child(sfx_confirm)
	if ResourceLoader.exists(SFX_CONFIRM):
		sfx_confirm.stream = load(SFX_CONFIRM)

	audio_fundo = AudioStreamPlayer.new()
	add_child(audio_fundo)
	if ResourceLoader.exists(MUSICA_FUNDO):
		var st: AudioStream = load(MUSICA_FUNDO)
		if st is AudioStreamMP3:
			st.loop = true
		audio_fundo.stream = st
		audio_fundo.volume_db = -8.0
		audio_fundo.play()


func _play_select() -> void:
	if sfx_select and sfx_select.stream:
		sfx_select.stop()
		sfx_select.play()


func _play_confirm() -> void:
	if sfx_confirm and sfx_confirm.stream:
		sfx_confirm.play()


# =========================================================
# HELPERS DE UI
# =========================================================
func _label(txt: String, tam: int, cor: Color, sombra: Color = Color.TRANSPARENT) -> Label:
	var l := Label.new()
	l.text = txt
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if fonte_orbitron:
		l.add_theme_font_override("font", fonte_orbitron)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	if sombra.a > 0.0:
		l.add_theme_color_override("font_shadow_color", sombra)
		l.add_theme_constant_override("shadow_offset_x", 0)
		l.add_theme_constant_override("shadow_offset_y", 0)
	return l


func _aplicar_neon(panel: Panel, cor: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.010, 0.014, 0.020, 0.97)
	s.border_color = cor
	s.set_border_width_all(3)
	s.set_corner_radius_all(32)
	s.shadow_color = Color(cor.r, cor.g, cor.b, 0.55)
	s.shadow_size = 32
	s.shadow_offset = Vector2.ZERO
	panel.add_theme_stylebox_override("panel", s)


func _botao_neon(txt: String, pos: Vector2, tam: Vector2, cor: Color) -> Button:
	var b := Button.new()
	b.text = txt
	b.position = pos
	b.size = tam
	b.custom_minimum_size = tam
	if fonte_orbitron:
		b.add_theme_font_override("font", fonte_orbitron)
	b.add_theme_font_size_override("font_size", int(clamp(tam.y * 0.40, 16, 38)))
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", cor)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _style_botao(cor, 0.28))
	b.add_theme_stylebox_override("hover", _style_botao(cor, 0.55))
	b.add_theme_stylebox_override("pressed", _style_botao(cor, 0.85))
	b.add_theme_stylebox_override("focus", _style_botao(cor, 0.55))
	return b


func _style_botao(cor: Color, intensidade: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(cor.r * 0.10, cor.g * 0.10, cor.b * 0.10, 0.92)
	s.border_color = cor
	s.set_border_width_all(2)
	s.set_corner_radius_all(16)
	s.shadow_color = Color(cor.r, cor.g, cor.b, intensidade)
	s.shadow_size = 12
	s.shadow_offset = Vector2.ZERO
	return s


func _style_chip(cor: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = cor
	s.border_color = Color(1, 1, 1, 0.80)
	s.set_border_width_all(2)
	s.set_corner_radius_all(10)
	s.shadow_color = Color(cor.r, cor.g, cor.b, 0.65)
	s.shadow_size = 10
	s.shadow_offset = Vector2.ZERO
	return s


func _estilizar_lineedit(edit: LineEdit, cor: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.04, 0.05, 0.06, 0.95)
	normal.border_color = Color(cor.r, cor.g, cor.b, 0.45)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 12
	normal.content_margin_right = 12

	var foco := StyleBoxFlat.new()
	foco.bg_color = Color(0.05, 0.06, 0.08, 0.98)
	foco.border_color = cor
	foco.set_border_width_all(2)
	foco.set_corner_radius_all(10)
	foco.content_margin_left = 12
	foco.content_margin_right = 12
	foco.shadow_color = Color(cor.r, cor.g, cor.b, 0.45)
	foco.shadow_size = 8

	edit.add_theme_stylebox_override("normal", normal)
	edit.add_theme_stylebox_override("focus", foco)
	edit.add_theme_color_override("font_color", Color.WHITE)
	edit.add_theme_color_override("font_placeholder_color", Color(0.40, 0.45, 0.55))
	edit.add_theme_color_override("caret_color", cor)


func _idx_cor_slot(cor_index: int, slot: int) -> int:
	return cor_index * JOGADORES_POR_GRUPO + slot
	

func _criar_painel_cadastro_cor(cor_index: int, tam: Vector2) -> Panel:
	var dados_cor: Dictionary = PALETA[cor_index]
	var nome_cor: String = dados_cor["nome"]
	var cor: Color = dados_cor["cor"]

	var panel := Panel.new()
	panel.size = tam

	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.018, 0.023, 0.033, 0.97)
	s.border_color = Color(cor.r, cor.g, cor.b, 0.75)
	s.set_border_width_all(2)
	s.set_corner_radius_all(24)
	s.shadow_color = Color(cor.r, cor.g, cor.b, 0.28)
	s.shadow_size = 20
	s.shadow_offset = Vector2.ZERO
	panel.add_theme_stylebox_override("panel", s)

	# Faixa superior
	var faixa := Panel.new()
	faixa.position = Vector2.ZERO
	faixa.size = Vector2(tam.x, 58)
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fs := StyleBoxFlat.new()
	fs.bg_color = Color(cor.r * 0.15, cor.g * 0.15, cor.b * 0.15, 0.92)
	fs.border_color = Color(cor.r, cor.g, cor.b, 0.0)
	fs.set_border_width_all(0)
	fs.set_corner_radius_all(0)
	fs.corner_radius_top_left = 22
	fs.corner_radius_top_right = 22
	faixa.add_theme_stylebox_override("panel", fs)
	panel.add_child(faixa)

	var titulo_cor := _label(nome_cor, 23, cor, Color(cor.r, cor.g, cor.b, 0.45))
	titulo_cor.position = Vector2(0, 0)
	titulo_cor.size = Vector2(tam.x, 58)
	panel.add_child(titulo_cor)

	var slot_h := (tam.y - 82.0) / float(JOGADORES_POR_GRUPO)

	for slot in range(JOGADORES_POR_GRUPO):
		var idx := _idx_cor_slot(cor_index, slot)
		var y_slot := 74.0 + slot * slot_h

		var numero := _label(str(slot + 1), 16, Color.WHITE)
		numero.position = Vector2(18, y_slot + 4)
		numero.size = Vector2(34, 44)
		panel.add_child(numero)

		var chip := Panel.new()
		chip.position = Vector2(54, y_slot + 14)
		chip.size = Vector2(18, 18)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_theme_stylebox_override("panel", _style_chip(cor))
		panel.add_child(chip)

		var edit := LineEdit.new()
		edit.placeholder_text = "%s %d" % [nome_cor.capitalize(), slot + 1]
		edit.text = nomes[idx]
		edit.position = Vector2(82, y_slot)
		edit.size = Vector2(tam.x - 104, 46)
		edit.max_length = 14

		if fonte_orbitron:
			edit.add_theme_font_override("font", fonte_orbitron)

		edit.add_theme_font_size_override("font_size", 18)
		_estilizar_lineedit(edit, cor)

		edit.text_changed.connect(func(t): _ao_alterar_nome(idx, t))
		panel.add_child(edit)

		name_edits.append(edit)

		var lbl_e := _label("", 12, COR_ERRO)
		lbl_e.position = Vector2(82, y_slot + 48)
		lbl_e.size = Vector2(tam.x - 104, 18)
		lbl_e.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		panel.add_child(lbl_e)

		error_labels.append(lbl_e)

	return panel


func _limpar_estado_copa_antigo_antes_de_salvar() -> void:
	var cg := get_node_or_null("/root/CupGlobal")

	if cg != null and cg.has_method("resetar_copa"):
		cg.resetar_copa()

	for chave in [
		"copa_partidas",
		"copa_partida_atual_index",
		"partida_copa_atual",
		"partida_atual_copa_index",
		"resultado_copa_pendente",
		"copa_grupos_confirmados_setup",
		"copa_sorteio_origem"
	]:
		if get_tree().has_meta(chave):
			get_tree().remove_meta(chave)
