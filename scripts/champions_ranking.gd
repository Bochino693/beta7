extends Node2D

# ============================================================
# CHAMPIONS RANKING
# Ranking geral baseado no banco ChampionsDb.
#
# Lê todas as competições salvas em:
# /root/ChampionsDb -> listar_copas()
#
# Usa o TOP 3 salvo de cada competição para montar:
# - Maiores goleadores
# - Maiores campeões
# - Mais vitórias
# - Mais pódios
# - Melhores campanhas
#
# CTRL + TAB fecha o jogo.
# ESC bloqueado.
# VOLTAR retorna ao Mural.
# ============================================================

const CENA_OPENING: String = "res://scenes/opening.tscn"
const CENA_MURAL: String = "res://scenes/champions_wall.tscn"

const FONTE_ORBITRON: String = "res://fonts/orbitron-bold.ttf"
const IMAGEM_FUNDO: String = "res://fundos/back.png"

const COR_FUNDO: Color = Color(0.004, 0.007, 0.014, 1.0)
const COR_NEON: Color = Color(0.10, 0.75, 1.00)
const COR_ROXO: Color = Color(0.62, 0.18, 1.00)
const COR_MAGENTA: Color = Color(1.00, 0.00, 0.82)
const COR_OURO: Color = Color(1.00, 0.78, 0.16)
const COR_PRATA: Color = Color(0.78, 0.84, 0.92)
const COR_BRONZE: Color = Color(0.95, 0.52, 0.22)
const COR_VERDE: Color = Color(0.20, 1.00, 0.35)
const COR_VERMELHO: Color = Color(1.00, 0.18, 0.18)
const COR_TEXTO: Color = Color(0.78, 0.86, 0.94)

const MODO_CAMPANHA: String = "CAMPANHA"
const MODO_GOLS: String = "GOLS"
const MODO_TITULOS: String = "TITULOS"
const MODO_VITORIAS: String = "VITORIAS"
const MODO_PODIOS: String = "PODIOS"

const MODOS: Array = [
	{"id": MODO_CAMPANHA, "label": "MELHORES CAMPANHAS"},
	{"id": MODO_GOLS, "label": "GOLEADORES"},
	{"id": MODO_TITULOS, "label": "CAMPEÕES"},
	{"id": MODO_VITORIAS, "label": "MAIS VITÓRIAS"},
	{"id": MODO_PODIOS, "label": "MAIS PÓDIOS"},
]

var canvas: CanvasLayer
var root: Control
var fonte_orbitron: Font = null

var copas: Array = []
var ranking_jogadores: Array = []

var modo_atual: String = MODO_CAMPANHA
var jogador_selecionado_key: String = ""

var total_label: Label = null
var tabs_box: HBoxContainer = null
var tabela_box: VBoxContainer = null
var detalhe_panel: Panel = null
var resumo_panel: Panel = null

var fechando_jogo: bool = false

var tabela_linha_w: float = 900.0
var detalhe_conquista_w: float = 420.0


func _ready() -> void:
	randomize()
	get_tree().auto_accept_quit = false

	_travar_tela()
	_carregar_fonte()
	_criar_interface()
	_carregar_dados()


func _travar_tela() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	RenderingServer.set_default_clear_color(COR_FUNDO)


func _carregar_fonte() -> void:
	if ResourceLoader.exists(FONTE_ORBITRON):
		var f: Resource = load(FONTE_ORBITRON)
		if f is Font:
			fonte_orbitron = f


# ============================================================
# TELA
# ============================================================
func _criar_interface() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)

	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)

	_criar_fundo()
	_criar_header()
	_criar_tabs()
	_criar_resumo()
	_criar_layout()
	_criar_rodape()


func _criar_fundo() -> void:
	var base := ColorRect.new()
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.color = COR_FUNDO
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(base)

	if ResourceLoader.exists(IMAGEM_FUNDO):
		var img := TextureRect.new()
		img.set_anchors_preset(Control.PRESET_FULL_RECT)
		img.texture = load(IMAGEM_FUNDO)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.modulate = Color(1, 1, 1, 0.46)
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(img)

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.62)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)

	var aura := ColorRect.new()
	aura.set_anchors_preset(Control.PRESET_FULL_RECT)
	aura.color = Color(COR_ROXO.r, COR_ROXO.g, COR_ROXO.b, 0.07)
	aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(aura)


func _criar_header() -> void:
	var vp: Vector2 = get_viewport_rect().size

	var header := Panel.new()
	header.position = Vector2(24, 20)
	header.size = Vector2(vp.x - 48, 92)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_stylebox_override("panel", _style_panel(COR_ROXO, 0.26, 26, 3))
	root.add_child(header)

	_label(
		header,
		"RANKING DOS CAMPEÕES",
		Vector2(30, 10),
		Vector2(header.size.x - 470, 48),
		38,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER,
		COR_ROXO
	)

	_label(
		header,
		"Estatísticas acumuladas dos jogadores registrados no TOP 3 das competições salvas",
		Vector2(34, 58),
		Vector2(header.size.x - 500, 24),
		14,
		COR_TEXTO,
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER
	)

	total_label = _label(
		header,
		"0 PLAYERS",
		Vector2(header.size.x - 410, 18),
		Vector2(170, 46),
		20,
		COR_OURO,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER,
		COR_OURO
	)

	_criar_botao(
		header,
		"ATUALIZAR",
		Vector2(header.size.x - 230, 20),
		Vector2(96, 46),
		COR_VERDE,
		Callable(self, "_carregar_dados")
	)

	_criar_botao(
		header,
		"VOLTAR",
		Vector2(header.size.x - 122, 20),
		Vector2(96, 46),
		COR_NEON,
		Callable(self, "_voltar_mural")
	)


func _criar_tabs() -> void:
	var vp: Vector2 = get_viewport_rect().size

	var barra := Panel.new()
	barra.position = Vector2(24, 122)
	barra.size = Vector2(vp.x - 48, 56)
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra.add_theme_stylebox_override("panel", _style_panel(COR_NEON, 0.14, 18, 2))
	root.add_child(barra)

	tabs_box = HBoxContainer.new()
	tabs_box.position = Vector2(18, 8)
	tabs_box.size = Vector2(barra.size.x - 36, 40)
	tabs_box.add_theme_constant_override("separation", 12)
	barra.add_child(tabs_box)

	_montar_tabs()


func _criar_resumo() -> void:
	var vp: Vector2 = get_viewport_rect().size

	resumo_panel = Panel.new()
	resumo_panel.position = Vector2(24, 190)
	resumo_panel.size = Vector2(vp.x - 48, 86)
	resumo_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resumo_panel.add_theme_stylebox_override("panel", _style_panel(COR_OURO, 0.10, 18, 2))
	root.add_child(resumo_panel)


func _criar_layout() -> void:
	var vp: Vector2 = get_viewport_rect().size

	var margem_x: float = 28.0
	var gap: float = 22.0
	var y: float = 292.0
	var h: float = vp.y - y - 66.0

	# Layout centralizado e proporcional.
	var largura_total: float = vp.x - (margem_x * 2.0)
	var tabela_w: float = largura_total * 0.64
	var detalhe_w: float = largura_total - tabela_w - gap

	# Segurança para resoluções menores.
	if detalhe_w < 420.0:
		detalhe_w = 420.0
		tabela_w = largura_total - detalhe_w - gap

	if tabela_w < 720.0:
		tabela_w = 720.0
		detalhe_w = largura_total - tabela_w - gap

	var tabela_x: float = margem_x
	var detalhe_x: float = tabela_x + tabela_w + gap

	var tabela_panel := Panel.new()
	tabela_panel.position = Vector2(tabela_x, y)
	tabela_panel.size = Vector2(tabela_w, h)
	tabela_panel.clip_contents = true
	tabela_panel.add_theme_stylebox_override("panel", _style_panel(COR_NEON, 0.16, 24, 2))
	root.add_child(tabela_panel)

	_label(
		tabela_panel,
		"CLASSIFICAÇÃO GERAL",
		Vector2(24, 16),
		Vector2(tabela_panel.size.x - 48, 34),
		22,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER,
		COR_NEON
	)

	var linha := ColorRect.new()
	linha.position = Vector2(24, 62)
	linha.size = Vector2(tabela_panel.size.x - 48, 2)
	linha.color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 0.58)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tabela_panel.add_child(linha)

	tabela_linha_w = tabela_panel.size.x - 40.0

	var header := Panel.new()
	header.position = Vector2(20, 78)
	header.size = Vector2(tabela_linha_w, 38)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_stylebox_override("panel", _style_panel(COR_ROXO, 0.08, 10, 1))
	tabela_panel.add_child(header)

	_criar_header_tabela(header)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 126)
	scroll.size = Vector2(tabela_linha_w, tabela_panel.size.y - 150)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabela_panel.add_child(scroll)

	tabela_box = VBoxContainer.new()
	tabela_box.custom_minimum_size = Vector2(tabela_linha_w, 0)
	tabela_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabela_box.add_theme_constant_override("separation", 8)
	scroll.add_child(tabela_box)

	detalhe_panel = Panel.new()
	detalhe_panel.position = Vector2(detalhe_x, y)
	detalhe_panel.size = Vector2(detalhe_w, h)
	detalhe_panel.clip_contents = true
	detalhe_panel.add_theme_stylebox_override("panel", _style_panel(COR_OURO, 0.15, 24, 2))
	root.add_child(detalhe_panel)



func _criar_rodape() -> void:
	var vp: Vector2 = get_viewport_rect().size

	var rodape := Panel.new()
	rodape.position = Vector2(24, vp.y - 50)
	rodape.size = Vector2(vp.x - 48, 30)
	rodape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rodape.add_theme_stylebox_override("panel", _style_panel(Color.WHITE, 0.04, 10, 1))
	root.add_child(rodape)

	_label(
		rodape,
		"CLICK: selecionar player   •   Ranking calculado pelo TOP 3 salvo no ChampionsDb   •   VOLTAR: mural   •   CTRL + TAB: fechar",
		Vector2.ZERO,
		rodape.size,
		13,
		Color(0.70, 0.78, 0.86),
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER
	)


func _montar_tabs() -> void:
	if tabs_box == null:
		return

	_limpar_filhos(tabs_box)

	for m in MODOS:
		var d: Dictionary = m
		var id: String = str(d.get("id", ""))
		var label: String = str(d.get("label", id))
		var ativo: bool = id == modo_atual
		var cor: Color = _cor_modo(id)

		var b := Button.new()
		b.text = label
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.custom_minimum_size = Vector2(0, 40)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		if fonte_orbitron:
			b.add_theme_font_override("font", fonte_orbitron)

		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", Color.WHITE if ativo else Color(0.78, 0.84, 0.92))
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.add_theme_color_override("font_pressed_color", cor)

		b.add_theme_stylebox_override("normal", _style_button(cor, 0.62 if ativo else 0.18, 13))
		b.add_theme_stylebox_override("hover", _style_button(cor, 0.52, 13))
		b.add_theme_stylebox_override("pressed", _style_button(cor, 0.85, 13))
		b.add_theme_stylebox_override("focus", _style_button(cor, 0.40, 13))

		var id_local: String = id
		b.pressed.connect(func() -> void:
			_aplicar_modo(id_local)
		)

		tabs_box.add_child(b)



func _aplicar_modo(id: String) -> void:
	modo_atual = id
	_montar_tabs()
	_ordenar_ranking()
	_montar_resumo()
	_montar_tabela()
	_selecionar_inicial()


# ============================================================
# DADOS
# ============================================================
func _carregar_dados() -> void:
	copas.clear()
	ranking_jogadores.clear()

	var db := get_node_or_null("/root/ChampionsDb")

	if db == null:
		push_warning("ChampionsRanking: Autoload ChampionsDb não encontrado.")
		_mostrar_sem_dados("ChampionsDb não encontrado no Autoload.")
		return

	if not db.has_method("listar_copas"):
		push_warning("ChampionsRanking: ChampionsDb não tem listar_copas().")
		_mostrar_sem_dados("ChampionsDb não tem listar_copas().")
		return

	var retorno: Variant = db.call("listar_copas")

	if retorno is Array:
		copas = retorno

	_gerar_ranking()
	_ordenar_ranking()

	if total_label:
		total_label.text = "%d PLAYER%s" % [
			ranking_jogadores.size(),
			"" if ranking_jogadores.size() == 1 else "S"
		]

	_montar_resumo()
	_montar_tabela()
	_selecionar_inicial()


func _gerar_ranking() -> void:
	var mapa: Dictionary = {}

	for copa_var in copas:
		if not (copa_var is Dictionary):
			continue

		var copa: Dictionary = copa_var
		var tipo: String = str(copa.get("tipo", "COPA")).to_upper()
		var tipo_nome: String = str(copa.get("tipo_nome", _tipo_nome_local(tipo)))
		var titulo: String = str(copa.get("titulo", "Competição"))
		var data_txt: String = str(copa.get("finished_at_text", ""))
		var top3_var: Variant = copa.get("top3", [])

		if not (top3_var is Array):
			continue

		var top3: Array = top3_var

		for i in range(top3.size()):
			if i >= 3:
				break

			if not (top3[i] is Dictionary):
				continue

			var item: Dictionary = top3[i]
			var nome: String = _ler_txt(item, ["nome", "name", "jogador", "player_name", "player"], "---")

			if nome == "---" or nome.strip_edges() == "":
				continue

			var key: String = _player_key(nome)

			if not mapa.has(key):
				mapa[key] = _novo_player_rank(nome, key)

			var p: Dictionary = mapa[key]
			var posicao: int = i + 1

			var gols: int = _ler_gols(item)
			var vitorias: int = _ler_num(item, ["vitorias_total", "vitorias", "wins", "partidas_vencidas"])
			var jogos: int = _ler_num(item, ["jogos_total", "jogos", "partidas", "partidas_jogadas", "jogos_disputados", "matches"])
			var pontos_grupo: int = _ler_num(item, ["pontos_grupo", "pontos", "pontos_tabela", "pts"])
			var penaltis: int = _ler_num(item, ["penaltis_total", "penaltis", "penaltis_marcados", "gols_penalti", "gols_penaltis"])

			p["competicoes"] = int(p.get("competicoes", 0)) + 1
			p["podios"] = int(p.get("podios", 0)) + 1

			p["gols_total"] = int(p.get("gols_total", 0)) + gols
			p["vitorias_total"] = int(p.get("vitorias_total", 0)) + vitorias
			p["jogos_total"] = int(p.get("jogos_total", 0)) + jogos
			p["pontos_grupo"] = int(p.get("pontos_grupo", 0)) + pontos_grupo
			p["penaltis_total"] = int(p.get("penaltis_total", 0)) + penaltis

			if posicao == 1:
				p["titulos"] = int(p.get("titulos", 0)) + 1
			elif posicao == 2:
				p["vices"] = int(p.get("vices", 0)) + 1
			elif posicao == 3:
				p["terceiros"] = int(p.get("terceiros", 0)) + 1

			var melhor_pos: int = int(p.get("melhor_posicao", 99))
			p["melhor_posicao"] = mini(melhor_pos, posicao)

			var pontos_posicao: int = _pontos_por_posicao(posicao)

			# SCORE DA CAMPANHA:
			# Valoriza título, vice, 3º lugar, vitórias, gols, pontos e pênaltis.
			var score_add: int = 0
			score_add += pontos_posicao
			score_add += vitorias * 35
			score_add += gols * 8
			score_add += pontos_grupo * 5
			score_add += penaltis * 3

			p["score_campanha"] = int(p.get("score_campanha", 0)) + score_add

			var conquistas: Array = _as_array(p.get("conquistas", []))
			conquistas.append({
				"titulo": titulo,
				"tipo": tipo,
				"tipo_nome": tipo_nome,
				"data": data_txt,
				"posicao": posicao,
				"gols": gols,
				"vitorias": vitorias,
				"jogos": jogos,
				"pontos": pontos_grupo,
				"penaltis": penaltis,
				"score": score_add
			})
			p["conquistas"] = conquistas

			mapa[key] = p

	ranking_jogadores.clear()

	for k in mapa.keys():
		var player: Dictionary = mapa[k]
		player["aproveitamento"] = _calcular_aproveitamento(
			int(player.get("vitorias_total", 0)),
			int(player.get("jogos_total", 0))
		)
		ranking_jogadores.append(player)


func _novo_player_rank(nome: String, key: String) -> Dictionary:
	return {
		"key": key,
		"nome": nome,
		"competicoes": 0,
		"titulos": 0,
		"vices": 0,
		"terceiros": 0,
		"podios": 0,
		"gols_total": 0,
		"vitorias_total": 0,
		"jogos_total": 0,
		"pontos_grupo": 0,
		"penaltis_total": 0,
		"score_campanha": 0,
		"aproveitamento": 0.0,
		"melhor_posicao": 99,
		"conquistas": []
	}


func _pontos_por_posicao(posicao: int) -> int:
	match posicao:
		1:
			return 1000
		2:
			return 550
		3:
			return 320
	return 0


func _ordenar_ranking() -> void:
	ranking_jogadores.sort_custom(func(a: Variant, b: Variant) -> bool:
		var pa: Dictionary = _as_dict(a)
		var pb: Dictionary = _as_dict(b)

		match modo_atual:
			MODO_GOLS:
				return _comparar_por_lista(pa, pb, ["gols_total", "titulos", "vitorias_total", "podios", "score_campanha"])

			MODO_TITULOS:
				return _comparar_por_lista(pa, pb, ["titulos", "vices", "terceiros", "gols_total", "vitorias_total"])

			MODO_VITORIAS:
				return _comparar_por_lista(pa, pb, ["vitorias_total", "titulos", "gols_total", "podios", "score_campanha"])

			MODO_PODIOS:
				return _comparar_por_lista(pa, pb, ["podios", "titulos", "vices", "terceiros", "gols_total"])

			_:
				return _comparar_por_lista(pa, pb, ["score_campanha", "titulos", "vitorias_total", "gols_total", "podios"])
	)


func _comparar_por_lista(a: Dictionary, b: Dictionary, campos: Array) -> bool:
	for campo_var in campos:
		var campo: String = str(campo_var)
		var va: float = float(a.get(campo, 0))
		var vb: float = float(b.get(campo, 0))

		if va != vb:
			return va > vb

	return str(a.get("nome", "")).to_lower() < str(b.get("nome", "")).to_lower()


# ============================================================
# RESUMO / TABELA
# ============================================================
func _montar_resumo() -> void:
	if resumo_panel == null:
		return

	_limpar_filhos(resumo_panel)

	var total_comp: int = copas.size()
	var total_players: int = ranking_jogadores.size()
	var total_gols: int = 0
	var total_titulos: int = 0
	var total_podios: int = 0
	var total_vitorias: int = 0

	for pvar in ranking_jogadores:
		var p: Dictionary = _as_dict(pvar)
		total_gols += int(p.get("gols_total", 0))
		total_titulos += int(p.get("titulos", 0))
		total_podios += int(p.get("podios", 0))
		total_vitorias += int(p.get("vitorias_total", 0))

	var col_w: float = resumo_panel.size.x / 5.0

	_criar_bloco_resumo(resumo_panel, "COMPETIÇÕES", str(total_comp), Vector2(0, 12), Vector2(col_w, 64), COR_OURO)
	_criar_bloco_resumo(resumo_panel, "PLAYERS", str(total_players), Vector2(col_w, 12), Vector2(col_w, 64), COR_NEON)
	_criar_bloco_resumo(resumo_panel, "TÍTULOS", str(total_titulos), Vector2(col_w * 2.0, 12), Vector2(col_w, 64), COR_ROXO)
	_criar_bloco_resumo(resumo_panel, "GOLS", str(total_gols), Vector2(col_w * 3.0, 12), Vector2(col_w, 64), COR_BRONZE)
	_criar_bloco_resumo(resumo_panel, "VITÓRIAS", str(total_vitorias), Vector2(col_w * 4.0, 12), Vector2(col_w, 64), COR_VERDE)


func _criar_header_tabela(parent: Control) -> void:
	var W: float = parent.size.x
	var H: float = parent.size.y
	var c: Dictionary = _colunas_tabela(W)

	var r: Rect2

	r = c["pos"]
	_label(parent, "POS", Vector2(r.position.x, 0), Vector2(r.size.x, H), 12, COR_TEXTO, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)

	r = c["player"]
	_label(parent, "PLAYER", Vector2(r.position.x, 0), Vector2(r.size.x, H), 12, COR_TEXTO, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER)

	r = c["destaque"]
	_label(parent, "DESTAQUE", Vector2(r.position.x, 0), Vector2(r.size.x, H), 12, COR_TEXTO, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)

	r = c["titulos"]
	_label(parent, "TÍT.", Vector2(r.position.x, 0), Vector2(r.size.x, H), 12, COR_TEXTO, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)

	r = c["vitorias"]
	_label(parent, "VIT.", Vector2(r.position.x, 0), Vector2(r.size.x, H), 12, COR_TEXTO, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)

	r = c["gols"]
	_label(parent, "GOLS", Vector2(r.position.x, 0), Vector2(r.size.x, H), 12, COR_TEXTO, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)

	r = c["podios"]
	_label(parent, "PÓDIOS", Vector2(r.position.x, 0), Vector2(r.size.x, H), 12, COR_TEXTO, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER)



func _montar_tabela() -> void:
	if tabela_box == null:
		return

	_limpar_filhos(tabela_box)

	if ranking_jogadores.is_empty():
		var vazio := _label(
			tabela_box,
			"Nenhum ranking ainda.\n\nFinalize uma Copa, Torneio ou Campeonato para alimentar o ChampionsDb.",
			Vector2.ZERO,
			Vector2(760, 170),
			18,
			COR_TEXTO,
			HORIZONTAL_ALIGNMENT_CENTER,
			VERTICAL_ALIGNMENT_CENTER
		)
		vazio.custom_minimum_size = Vector2(760, 170)
		_mostrar_sem_dados("Nenhum player registrado no TOP 3 ainda.")
		return

	for i in range(ranking_jogadores.size()):
		var p: Dictionary = _as_dict(ranking_jogadores[i])
		_adicionar_linha_player(p, i + 1)


func _adicionar_linha_player(p: Dictionary, posicao: int) -> void:
	var key: String = str(p.get("key", ""))
	var selecionado: bool = key == jogador_selecionado_key

	var cor: Color = _cor_posicao(posicao)
	if selecionado:
		cor = COR_OURO

	var W: float = tabela_linha_w
	var H: float = 62.0

	var wrap := Panel.new()
	wrap.custom_minimum_size = Vector2(W, H)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_theme_stylebox_override("panel", _style_button(cor, 0.54 if selecionado else 0.18, 14))
	tabela_box.add_child(wrap)

	var faixa := ColorRect.new()
	faixa.position = Vector2(0, 7)
	faixa.size = Vector2(6, H - 14)
	faixa.color = cor
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(faixa)

	var c: Dictionary = _colunas_tabela(W)
	var r: Rect2

	r = c["pos"]
	_label(
		wrap,
		"%02d" % posicao,
		Vector2(r.position.x, 0),
		Vector2(r.size.x, H),
		17,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER,
		cor
	)

	r = c["player"]
	_label(
		wrap,
		str(p.get("nome", "---")),
		Vector2(r.position.x, 0),
		Vector2(r.size.x, H),
		17,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER,
		cor
	)

	var destaque: String = _valor_destaque(p)

	r = c["destaque"]
	_label(
		wrap,
		destaque,
		Vector2(r.position.x, 0),
		Vector2(r.size.x, H),
		20,
		_cor_modo(modo_atual),
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER,
		_cor_modo(modo_atual)
	)

	r = c["titulos"]
	_label(
		wrap,
		str(int(p.get("titulos", 0))),
		Vector2(r.position.x, 0),
		Vector2(r.size.x, H),
		18,
		COR_OURO,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER
	)

	r = c["vitorias"]
	_label(
		wrap,
		str(int(p.get("vitorias_total", 0))),
		Vector2(r.position.x, 0),
		Vector2(r.size.x, H),
		18,
		COR_VERDE,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER
	)

	r = c["gols"]
	_label(
		wrap,
		str(int(p.get("gols_total", 0))),
		Vector2(r.position.x, 0),
		Vector2(r.size.x, H),
		18,
		COR_BRONZE,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER
	)

	r = c["podios"]
	_label(
		wrap,
		str(int(p.get("podios", 0))),
		Vector2(r.position.x, 0),
		Vector2(r.size.x, H),
		18,
		COR_NEON,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER
	)

	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.position = Vector2.ZERO
	btn.size = Vector2(W, H)
	btn.custom_minimum_size = Vector2(W, H)

	var vazio_sb := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", vazio_sb)
	btn.add_theme_stylebox_override("hover", vazio_sb)
	btn.add_theme_stylebox_override("pressed", vazio_sb)
	btn.add_theme_stylebox_override("focus", vazio_sb)

	var key_local: String = key
	btn.pressed.connect(func() -> void:
		_selecionar_player(key_local)
	)

	wrap.add_child(btn)



func _valor_destaque(p: Dictionary) -> String:
	match modo_atual:
		MODO_GOLS:
			return str(int(p.get("gols_total", 0)))
		MODO_TITULOS:
			return str(int(p.get("titulos", 0)))
		MODO_VITORIAS:
			return str(int(p.get("vitorias_total", 0)))
		MODO_PODIOS:
			return str(int(p.get("podios", 0)))
		_:
			return str(int(p.get("score_campanha", 0)))


func _selecionar_inicial() -> void:
	if ranking_jogadores.is_empty():
		jogador_selecionado_key = ""
		_mostrar_sem_dados("Nenhum player encontrado.")
		return

	var existe: bool = false

	for pvar in ranking_jogadores:
		var p: Dictionary = _as_dict(pvar)
		if str(p.get("key", "")) == jogador_selecionado_key:
			existe = true
			break

	if not existe:
		jogador_selecionado_key = str(_as_dict(ranking_jogadores[0]).get("key", ""))

	_mostrar_player_por_key(jogador_selecionado_key)
	_montar_tabela()


func _selecionar_player(key: String) -> void:
	jogador_selecionado_key = key
	_montar_tabela()
	_mostrar_player_por_key(key)


func _mostrar_player_por_key(key: String) -> void:
	for pvar in ranking_jogadores:
		var p: Dictionary = _as_dict(pvar)
		if str(p.get("key", "")) == key:
			_mostrar_player(p)
			return

	_mostrar_sem_dados("Player não encontrado.")


# ============================================================
# DETALHE PLAYER
# ============================================================
func _mostrar_sem_dados(msg: String) -> void:
	if detalhe_panel == null:
		return

	_limpar_filhos(detalhe_panel)

	_label(
		detalhe_panel,
		"RANKING VAZIO",
		Vector2(0, detalhe_panel.size.y * 0.35),
		Vector2(detalhe_panel.size.x, 48),
		30,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER,
		COR_OURO
	)

	_label(
		detalhe_panel,
		msg,
		Vector2(36, detalhe_panel.size.y * 0.47),
		Vector2(detalhe_panel.size.x - 72, 80),
		16,
		COR_TEXTO,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER
	)

func _mostrar_player(p: Dictionary) -> void:
	if detalhe_panel == null:
		return

	_limpar_filhos(detalhe_panel)

	var nome: String = str(p.get("nome", "---"))
	var conquistas: Array = _as_array(p.get("conquistas", []))

	var W: float = detalhe_panel.size.x
	var H: float = detalhe_panel.size.y
	var margem: float = 26.0
	var inner_w: float = W - margem * 2.0

	_label(
		detalhe_panel,
		nome,
		Vector2(margem, 18),
		Vector2(inner_w, 46),
		28,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER,
		COR_OURO
	)

	_label(
		detalhe_panel,
		"Resumo acumulado das conquistas registradas no TOP 3",
		Vector2(margem + 2, 64),
		Vector2(inner_w, 24),
		12,
		COR_TEXTO,
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER
	)

	var linha := ColorRect.new()
	linha.position = Vector2(margem, 100)
	linha.size = Vector2(inner_w, 2)
	linha.color = Color(COR_OURO.r, COR_OURO.g, COR_OURO.b, 0.55)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detalhe_panel.add_child(linha)

	var gap: float = 14.0
	var card_w: float = (inner_w - gap) / 2.0
	var card_h: float = 76.0
	var y0: float = 120.0

	_criar_card_detalhe(detalhe_panel, "TÍTULOS", str(int(p.get("titulos", 0))), Vector2(margem, y0), Vector2(card_w, card_h), COR_OURO)
	_criar_card_detalhe(detalhe_panel, "PÓDIOS", str(int(p.get("podios", 0))), Vector2(margem + card_w + gap, y0), Vector2(card_w, card_h), COR_NEON)

	_criar_card_detalhe(detalhe_panel, "GOLS", str(int(p.get("gols_total", 0))), Vector2(margem, y0 + 88), Vector2(card_w, card_h), COR_BRONZE)
	_criar_card_detalhe(detalhe_panel, "VITÓRIAS", str(int(p.get("vitorias_total", 0))), Vector2(margem + card_w + gap, y0 + 88), Vector2(card_w, card_h), COR_VERDE)

	_criar_card_detalhe(detalhe_panel, "SCORE CAMPANHA", str(int(p.get("score_campanha", 0))), Vector2(margem, y0 + 176), Vector2(card_w, card_h), COR_ROXO)
	_criar_card_detalhe(detalhe_panel, "APROVEITAMENTO", "%.1f%%" % float(p.get("aproveitamento", 0.0)), Vector2(margem + card_w + gap, y0 + 176), Vector2(card_w, card_h), COR_MAGENTA)

	var lista_y: float = y0 + 266.0

	_label(
		detalhe_panel,
		"CONQUISTAS",
		Vector2(margem + 2, lista_y),
		Vector2(inner_w, 30),
		19,
		COR_OURO,
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER,
		COR_OURO
	)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(margem, lista_y + 38)
	scroll.size = Vector2(inner_w, H - lista_y - 56)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detalhe_panel.add_child(scroll)

	detalhe_conquista_w = scroll.size.x - 4.0

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(detalhe_conquista_w, 0)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)

	conquistas.sort_custom(func(a: Variant, b: Variant) -> bool:
		var da: Dictionary = _as_dict(a)
		var db: Dictionary = _as_dict(b)
		return int(da.get("score", 0)) > int(db.get("score", 0))
	)

	for cvar in conquistas:
		var c: Dictionary = _as_dict(cvar)
		_adicionar_card_conquista(box, c)



func _criar_card_detalhe(parent: Control, titulo: String, valor: String, pos: Vector2, tam: Vector2, cor: Color) -> void:
	var card := Panel.new()
	card.position = pos
	card.size = tam
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _style_button(cor, 0.32, 16))
	parent.add_child(card)

	_label(
		card,
		titulo,
		Vector2(10, 8),
		Vector2(card.size.x - 20, 20),
		12,
		Color(0.72, 0.80, 0.88),
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER
	)

	_label(
		card,
		valor,
		Vector2(10, 28),
		Vector2(card.size.x - 20, 42),
		26,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER,
		cor
	)


func _adicionar_card_conquista(parent: VBoxContainer, c: Dictionary) -> void:
	var posicao: int = int(c.get("posicao", 0))
	var cor: Color = _cor_medalha(posicao)

	var W: float = detalhe_conquista_w
	var H: float = 90.0

	var card := Panel.new()
	card.custom_minimum_size = Vector2(W, H)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _style_button(cor, 0.22, 14))
	parent.add_child(card)

	var medalha_txt: String = "%dº" % posicao
	if posicao == 1:
		medalha_txt = "CAMPEÃO"
	elif posicao == 2:
		medalha_txt = "VICE"
	elif posicao == 3:
		medalha_txt = "3º LUGAR"

	_label(
		card,
		medalha_txt,
		Vector2(14, 8),
		Vector2(150, 24),
		12,
		cor,
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER,
		cor
	)

	_label(
		card,
		str(c.get("tipo_nome", "Competição")),
		Vector2(W - 160, 8),
		Vector2(140, 24),
		11,
		COR_TEXTO,
		HORIZONTAL_ALIGNMENT_RIGHT,
		VERTICAL_ALIGNMENT_CENTER
	)

	_label(
		card,
		str(c.get("titulo", "Competição")),
		Vector2(14, 34),
		Vector2(W - 28, 24),
		14,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER,
		cor
	)

	_label(
		card,
		"Gols %d  •  Vitórias %d  •  Jogos %d  •  Score %d  •  %s" % [
			int(c.get("gols", 0)),
			int(c.get("vitorias", 0)),
			int(c.get("jogos", 0)),
			int(c.get("score", 0)),
			str(c.get("data", ""))
		],
		Vector2(14, 62),
		Vector2(W - 28, 20),
		11,
		COR_TEXTO,
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER
	)



# ============================================================
# BOTÕES / NAVEGAÇÃO
# ============================================================
func _voltar_mural() -> void:
	if ResourceLoader.exists(CENA_MURAL):
		get_tree().change_scene_to_file(CENA_MURAL)
	elif ResourceLoader.exists(CENA_OPENING):
		get_tree().change_scene_to_file(CENA_OPENING)


func _fechar_jogo_arcade() -> void:
	if fechando_jogo:
		return

	fechando_jogo = true
	await get_tree().create_timer(0.08).timeout
	get_tree().quit()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	if not event.pressed or event.echo:
		return

	var viewport := get_viewport()

	if event.ctrl_pressed and event.keycode == KEY_TAB:
		if viewport:
			viewport.set_input_as_handled()

		_fechar_jogo_arcade()
		return

	if event.keycode == KEY_ESCAPE:
		if viewport:
			viewport.set_input_as_handled()
		return

	if event.alt_pressed and event.keycode == KEY_F4:
		if viewport:
			viewport.set_input_as_handled()
		return

	if event.alt_pressed and event.keycode == KEY_TAB:
		if viewport:
			viewport.set_input_as_handled()
		return

	if event.ctrl_pressed and event.keycode == KEY_ESCAPE:
		if viewport:
			viewport.set_input_as_handled()
		return


func _unhandled_input(event: InputEvent) -> void:
	_input(event)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		return

	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		return


# ============================================================
# HELPERS VISUAIS
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

	b.add_theme_font_size_override("font_size", 13)
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
	sombra: Color = Color(0, 0, 0, 0)
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
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	if fonte_orbitron:
		l.add_theme_font_override("font", fonte_orbitron)

	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", cor)

	if sombra.a > 0.0:
		l.add_theme_color_override("font_shadow_color", sombra)
		l.add_theme_constant_override("shadow_offset_x", 0)
		l.add_theme_constant_override("shadow_offset_y", 0)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		l.add_theme_constant_override("outline_size", 3)

	parent.add_child(l)
	return l


func _style_panel(cor: Color, alpha_bg: float, radius: int, border: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(
		0.008 + cor.r * 0.040,
		0.012 + cor.g * 0.035,
		0.022 + cor.b * 0.045,
		0.90 + alpha_bg * 0.20
	)
	s.border_color = Color(cor.r, cor.g, cor.b, 0.80)
	s.set_border_width_all(border)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(cor.r, cor.g, cor.b, 0.22 + alpha_bg)
	s.shadow_size = 22
	s.shadow_offset = Vector2.ZERO
	return s


func _style_button(cor: Color, intensidade: float, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(cor.r * 0.075, cor.g * 0.075, cor.b * 0.090, 0.94)
	s.border_color = Color(cor.r, cor.g, cor.b, 0.90)
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(cor.r, cor.g, cor.b, intensidade)
	s.shadow_size = 13
	s.shadow_offset = Vector2.ZERO
	return s


func _criar_bloco_resumo(parent: Control, titulo: String, valor: String, pos: Vector2, tamanho: Vector2, cor: Color) -> void:
	_label(
		parent,
		titulo,
		pos,
		Vector2(tamanho.x, 22),
		12,
		Color(0.68, 0.76, 0.84),
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER
	)

	_label(
		parent,
		valor,
		pos + Vector2(0, 25),
		Vector2(tamanho.x, 42),
		31,
		Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER,
		cor
	)


# ============================================================
# HELPERS DE DADOS
# ============================================================
func _as_dict(v: Variant) -> Dictionary:
	if v is Dictionary:
		return v
	return {}


func _as_array(v: Variant) -> Array:
	if v is Array:
		return v
	return []


func _limpar_filhos(n: Node) -> void:
	if n == null:
		return

	for child in n.get_children():
		n.remove_child(child)
		child.queue_free()


func _player_key(nome: String) -> String:
	var s: String = nome.strip_edges().to_lower()
	s = s.replace(" ", "_")
	s = s.replace(".", "")
	s = s.replace(",", "")
	s = s.replace("-", "_")
	return s


func _ler_num(item: Dictionary, chaves: Array, padrao: int = 0) -> int:
	for k in chaves:
		if item.has(k):
			var v: Variant = item[k]

			if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
				return int(v)

			if typeof(v) == TYPE_STRING:
				var s := str(v).strip_edges()

				if s.is_valid_int():
					return int(s)

				if s.is_valid_float():
					return int(float(s))

	return padrao


func _ler_txt(item: Dictionary, chaves: Array, padrao: String = "-") -> String:
	for k in chaves:
		if item.has(k):
			var s := str(item[k]).strip_edges()
			if s != "":
				return s

	return padrao


func _ler_gols(item: Dictionary) -> int:
	var gols_normais: int = _ler_num(item, [
		"gols_normais",
		"gols_normal",
		"gols_tempo_normal",
		"normal_gols"
	])

	var gols_prorrogacao: int = _ler_num(item, [
		"gols_prorrogacao",
		"gols_prorro",
		"gols_extra",
		"prorrogacao_gols"
	])

	var penaltis: int = _ler_num(item, [
		"penaltis_total",
		"penaltis",
		"penaltis_marcados",
		"gols_penalti",
		"gols_penaltis"
	])

	var gols_total: int = _ler_num(item, [
		"gols_total",
		"gols",
		"score",
		"pontuacao"
	], -1)

	if gols_total < 0:
		gols_total = gols_normais + gols_prorrogacao + penaltis

	return gols_total


func _calcular_aproveitamento(vitorias: int, jogos: int) -> float:
	if jogos <= 0:
		return 0.0

	return float(vitorias) / float(jogos) * 100.0


func _cor_modo(modo: String) -> Color:
	match modo:
		MODO_GOLS:
			return COR_BRONZE
		MODO_TITULOS:
			return COR_OURO
		MODO_VITORIAS:
			return COR_VERDE
		MODO_PODIOS:
			return COR_NEON
		_:
			return COR_ROXO


func _cor_posicao(posicao: int) -> Color:
	if posicao == 1:
		return COR_OURO
	if posicao == 2:
		return COR_PRATA
	if posicao == 3:
		return COR_BRONZE
	return COR_NEON


func _cor_medalha(posicao: int) -> Color:
	match posicao:
		1:
			return COR_OURO
		2:
			return COR_PRATA
		3:
			return COR_BRONZE
	return COR_NEON


func _tipo_nome_local(tipo: String) -> String:
	match tipo.to_upper():
		"TORNEIO":
			return "Torneio"
		"CAMPEONATO":
			return "Campeonato"
		_:
			return "Copa"


func _colunas_tabela(W: float) -> Dictionary:
	var gap: float = 8.0

	var pos_w: float = 58.0
	var destaque_w: float = 128.0
	var tit_w: float = 66.0
	var vit_w: float = 72.0
	var gols_w: float = 76.0
	var podios_w: float = 82.0

	var fixo: float = pos_w + destaque_w + tit_w + vit_w + gols_w + podios_w + (gap * 6.0)
	var player_w: float = W - fixo

	if player_w < 210.0:
		player_w = 210.0

	var x: float = 0.0

	var cols := {}

	cols["pos"] = Rect2(Vector2(x, 0), Vector2(pos_w, 1))
	x += pos_w + gap

	cols["player"] = Rect2(Vector2(x, 0), Vector2(player_w, 1))
	x += player_w + gap

	cols["destaque"] = Rect2(Vector2(x, 0), Vector2(destaque_w, 1))
	x += destaque_w + gap

	cols["titulos"] = Rect2(Vector2(x, 0), Vector2(tit_w, 1))
	x += tit_w + gap

	cols["vitorias"] = Rect2(Vector2(x, 0), Vector2(vit_w, 1))
	x += vit_w + gap

	cols["gols"] = Rect2(Vector2(x, 0), Vector2(gols_w, 1))
	x += gols_w + gap

	cols["podios"] = Rect2(Vector2(x, 0), Vector2(podios_w, 1))

	return cols
