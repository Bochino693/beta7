extends Node2D

# ============================================================
# CUP LOBBY — v2.0
#
# Recebe grupos da tela anterior.
# Fase de grupos: mostra a tabela de classificação.
# Mata-mata: mostra o CHAVEAMENTO (bracket) estilo futebol.
# A barra de fases no topo é CLICÁVEL: dá para revisitar as
#   fases já jogadas e a atual; as futuras ficam bloqueadas.
# Tela final: PÓDIUM com TOP 3 enquadrado e bonito.
# Cria partidas por grupo.
# Envia partida selecionada para cup_play.tscn.
# CTRL + TAB fecha o jogo.
# ============================================================

# ===== NAVEGAÇÃO POR BOTÃO (START / CUP) =====
const PODIO_HOLD_SEGUNDOS: float = 1.4   # tempo segurando START no pódio p/ voltar

var tela_modo: String = "LOBBY"          # "LOBBY", "SEQUENCIA", "PODIO"
var podio_hold_start: float = 0.0
var podio_aguardando_soltar_start: bool = true
var podio_indo_opening: bool = false
var podio_hold_layer_w: float = 0.0
var podio_hold_barra: ColorRect = null
var podio_hold_barra_w: float = 0.0
var podio_hold_label: Label = null


const PATROCINADORES_FIXOS: Array[String] = [
	"res://patro/logoofi.png",
	"res://patro/bar.png",
	"res://patro/bud.png",
	"res://patro/corona_logo.png",
	"res://patro/GA_Logo.png",	
	"res://patro/Michelob-Ultra_stacked-color-Logo.png",
	"res://patro/stella.png",
]



const MOUSE_HIBERNAR_SEGUNDOS: float = 12.0
const MOUSE_MOVIMENTO_MINIMO: float = 2.0

var mouse_hibernacao_timer: float = 0.0
var mouse_pos_anterior: Vector2 = Vector2.ZERO
var mouse_pos_inicializada: bool = false
var mouse_arcade_visivel: bool = false

const IMAGEM_FUNDO_FOOTER_PATRO: String = "res://fundos/fundo_logos.png"

const CENA_CUP_PLAY: String = "res://scenes/cup_play.tscn"
const CENA_MENU_COPA: String = "res://scenes/cup_setup.tscn"
const CENA_OPENING: String = "res://scenes/opening.tscn"
const FONTE_ORBITRON: String = "res://fonts/orbitron-bold.ttf"

const COR_OK: Color = Color(0.22, 0.95, 0.58)
const COR_ALERTA: Color = Color(1.00, 0.78, 0.18)
const COR_ERRO: Color = Color(1.00, 0.22, 0.22)
const COR_NEON: Color = Color(0.25, 0.72, 1.00)
const COR_BOOT: Color = Color(0.48, 0.54, 0.64)
const COR_PRATA: Color = Color(0.80, 0.84, 0.92)
const COR_BRONZE: Color = Color(0.86, 0.55, 0.28)

const NUM_GRUPOS: int = 4
const JOGADORES_POR_GRUPO: int = 4
const LETRAS_GRUPO: Array[String] = ["A", "B", "C", "D"]

const MUSICA_CUP_LOBBY: String = "res://songs/cup_song.mp3"
const SFX_SELECT_CUP: String = "res://songs/player_select.mp3"
const SFX_CONFIRM_CUP: String = "res://songs/game_start.mp3"

const IMAGEM_LOADING_COPA: String = "res://images/loading.png"
const IMAGEM_BACK_COPA: String = "res://fundos/back.png"

const USAR_ARDUINO_LOBBY: bool = true
const USAR_PONTE_POWERSHELL_LOBBY: bool = true
const SERIAL_PORTA_LOBBY: String = "COM5"
const SERIAL_BAUD_LOBBY: int = 9600

const LEDS_TOTAL: int = 7
const LEDS_LETRAS: Array[String] = ["A", "B", "C", "D", "E", "F", "G"]

const TEMPO_LED_LOBBY: float = 0.26
const LEDS_LOBBY_MIN: int = 1
const LEDS_LOBBY_MAX: int = 4

const FASE_GRUPOS: String = "GRUPOS"
const FASE_OITAVAS: String = "OITAVAS"
const FASE_SEMIFINAL: String = "SEMIFINAL"
const FASE_FINAL: String = "FINAL"
const FASE_ENCERRADA: String = "ENCERRADA"

const PASTA_PATROCINADORES: String = "res://patro"
const EXT_PATROCINADORES: Array[String] = ["png", "jpg", "jpeg", "webp"]


const SFX_CAMPEAO_CUP: String = "res://songs/campeao.mp3"
const TEMPO_RETORNO_OPENING_FINAL: float = 21.0

var sfx_campeao_cup: AudioStreamPlayer = null

var contagem_retorno_final_ativa: bool = false
var contagem_retorno_final_total: float = TEMPO_RETORNO_OPENING_FINAL
var contagem_retorno_final_inicio_ms: float = 0.0

var final_timer_layer: CanvasLayer = null
var final_timer_label: Label = null
var final_timer_barra: ColorRect = null
var final_timer_barra_w: float = 0.0


var confete_layer: CanvasLayer = null
var confetes: Array = []
var confete_cor_base: Color = COR_ALERTA

var modal_campeao_exibido: bool = false

# Controle da sequência final (campeão -> classificação -> pódio -> opening).
var em_sequencia_final: bool = false
var retorno_opening_ativo: bool = false

var fase_atual: String = FASE_GRUPOS
# Fase que está sendo VISUALIZADA na tela (pode diferir da fase em jogo).
var fase_visualizada: String = FASE_GRUPOS

var audio_cup_lobby: AudioStreamPlayer
var sfx_select_cup: AudioStreamPlayer
var sfx_confirm_cup: AudioStreamPlayer

var fonte_orbitron: Font

var ui_layer: CanvasLayer
var ui_root: Control
var ponteiro_layer: CanvasLayer
var ponteiro: Control

var grupos: Array = []
var partidas: Array = []
var partida_atual_index: int = 0

var label_status: Label

var copa_id_atual: String = ""

var led_lobby_timer: float = 0.0

var caminho_fila_arduino_lobby: String = ""
var caminho_log_arduino_lobby: String = ""
var caminho_script_arduino_lobby: String = ""
var ponte_ps_pid_lobby: int = -1

var ponte_lobby_pronta: bool = false


func _ready() -> void:
	randomize()
	get_tree().auto_accept_quit = false
	RenderingServer.set_default_clear_color(Color(0.004, 0.007, 0.014, 1.0))

	_travar_arcade()
	_carregar_fontes()

	# Cria base visual imediatamente para nunca aparecer tela cinza.
	_criar_fundo()
	_criar_ui_root()

	var loading_lobby := _mostrar_tela_carregamento_lobby(
		"CARREGANDO LOBBY",
		"PREPARANDO COPA..."
	)

	await get_tree().process_frame

	_criar_audios_cup()

	_carregar_dados_copa()
	_garantir_id_copa_atual()
	_garantir_estatisticas()
	_gerar_partidas_grupos()

	_criar_ponteiro()

	_verificar_resultado_pendente()
	_auto_resolver_partidas_so_boots()

	fase_visualizada = _fase_visualizavel_padrao()

	# Monta a tela por trás do loading.
	_montar_tela_lobby()

	await get_tree().process_frame

	# Conecta LEDs ainda com loading na tela.
	await _abrir_serial_lobby()

	await get_tree().process_frame

	_tocar_musica_cup()

	await _remover_tela_carregamento_lobby(loading_lobby)



func _process(delta: float) -> void:
	_processar_mouse_hibernacao(delta)

	if ponteiro:
		ponteiro.position = get_viewport().get_mouse_position()

	_processar_leds_lobby(delta)
	_processar_confetes(delta)
	_processar_hold_podio(delta)


# ============================================================
# DADOS
# ============================================================
func _carregar_dados_copa() -> void:
	var cg := get_node_or_null("/root/CupGlobal")

	if cg != null:
		if cg.grupos_copa is Array and cg.grupos_copa.size() > 0:
			grupos = cg.grupos_copa.duplicate(true)

	if grupos.is_empty() and get_tree().has_meta("copa_grupos"):
		var g_meta: Variant = get_tree().get_meta("copa_grupos")
		if g_meta is Array:
			grupos = g_meta

	if grupos.is_empty():
		push_warning("Nenhum grupo recebido. Criando grupos vazios para evitar erro.")
		grupos = _criar_grupos_fallback()



func _criar_grupos_fallback() -> Array:
	var saida: Array = []

	for g in range(NUM_GRUPOS):
		var jogadores: Array = []

		for i in range(JOGADORES_POR_GRUPO):
			jogadores.append({
				"nome": "Boot %d" % ((g * JOGADORES_POR_GRUPO) + i + 1),
				"cor_index": i,
				"cor": Color(0.5, 0.55, 0.65),
				"cor_nome": "BOT",
				"boot": true
			})

		saida.append({
			"grupo": LETRAS_GRUPO[g],
			"jogadores": jogadores
		})

	return saida


func _garantir_estatisticas() -> void:
	for g in grupos:
		if not g.has("jogadores"):
			continue

		for j in g["jogadores"]:
			if not j.has("pontos"):
				j["pontos"] = 0

			if not j.has("jogos"):
				j["jogos"] = 0

			if not j.has("gols"):
				j["gols"] = 0

			if not j.has("gols_pro"):
				j["gols_pro"] = 0

			if not j.has("melhor_posicao"):
				j["melhor_posicao"] = 99

			if not j.has("ultima_posicao"):
				j["ultima_posicao"] = 99

			# Mantém compatibilidade com sua tabela antiga.
			if not j.has("vitorias"):
				j["vitorias"] = 0

			if not j.has("empates"):
				j["empates"] = 0

			if not j.has("derrotas"):
				j["derrotas"] = 0

			if not j.has("saldo"):
				j["saldo"] = 0

			if not j.has("gols_contra"):
				j["gols_contra"] = 0



func _salvar_estado_copa() -> void:
	var cg := get_node_or_null("/root/CupGlobal")

	if cg != null:
		cg.salvar_estado_copa(grupos, partidas, partida_atual_index)

	get_tree().set_meta("copa_grupos", grupos)
	get_tree().set_meta("copa_partidas", partidas)
	get_tree().set_meta("copa_partida_atual_index", partida_atual_index)


# ============================================================
# PARTIDAS
# Cada grupo com 4 jogadores gera 2 rodadas de 4 jogadores.
# ============================================================
func _gerar_partidas_grupos() -> void:
	var cg := get_node_or_null("/root/CupGlobal")

	if cg != null:
		if cg.partidas_copa is Array and cg.partidas_copa.size() > 0:
			partidas = cg.partidas_copa.duplicate(true)
			_atualizar_fase_atual()
			return

	if get_tree().has_meta("copa_partidas"):
		var p_meta: Variant = get_tree().get_meta("copa_partidas")
		if p_meta is Array and p_meta.size() > 0:
			partidas = p_meta
			_atualizar_fase_atual()
			return

	partidas.clear()

	for g_index in range(grupos.size()):
		var grupo: Dictionary = grupos[g_index]
		var jogadores: Array = grupo["jogadores"]

		for rodada in range(1, 3):
			partidas.append({
				"fase": FASE_GRUPOS,
				"grupo_index": g_index,
				"grupo": grupo["grupo"],
				"rodada": rodada,
				"jogadores": jogadores.duplicate(true),
				"finalizada": false,
				"ranking": [],
				"classificados": []
			})

	fase_atual = FASE_GRUPOS
	_salvar_estado_copa()


func _atualizar_fase_atual() -> void:
	if partidas.is_empty():
		fase_atual = FASE_GRUPOS
		return

	var ordem_fases: Array[String] = [
		FASE_GRUPOS,
		FASE_OITAVAS,
		FASE_SEMIFINAL,
		FASE_FINAL
	]

	for fase in ordem_fases:
		for p in partidas:
			if str(p.get("fase", "")) == fase and not bool(p.get("finalizada", false)):
				fase_atual = fase
				return

	fase_atual = FASE_ENCERRADA


func _partidas_da_fase(fase: String) -> Array:
	var saida: Array = []

	for p in partidas:
		if str(p.get("fase", "")) == fase:
			saida.append(p)

	return saida


func _fase_tem_partida_pendente(fase: String) -> bool:
	for p in partidas:
		if str(p.get("fase", "")) == fase and not bool(p.get("finalizada", false)):
			return true

	return false


func _fase_totalmente_finalizada(fase: String) -> bool:
	var encontrou: bool = false

	for p in partidas:
		if str(p.get("fase", "")) == fase:
			encontrou = true

			if not bool(p.get("finalizada", false)):
				return false

	return encontrou



func _buscar_proxima_partida_pendente() -> int:
	var ordem_fases: Array[String] = [
		FASE_GRUPOS,
		FASE_OITAVAS,
		FASE_SEMIFINAL,
		FASE_FINAL
	]

	for fase in ordem_fases:
		for i in range(partidas.size()):
			var p: Dictionary = partidas[i]

			if str(p.get("fase", "")) == fase and not bool(p.get("finalizada", false)):
				return i

	return -1



func _todas_partidas_finalizadas() -> bool:
	for p in partidas:
		if not bool(p.get("finalizada", false)):
			return false

	return partidas.size() > 0


# Define qual fase mostrar por padrão (a atual, ou a final se a copa encerrou).
func _fase_visualizavel_padrao() -> String:
	_atualizar_fase_atual()

	if fase_atual == FASE_ENCERRADA:
		return FASE_FINAL

	if fase_atual == FASE_GRUPOS:
		return FASE_GRUPOS

	if fase_atual == FASE_OITAVAS:
		return FASE_OITAVAS

	if fase_atual == FASE_SEMIFINAL:
		return FASE_SEMIFINAL

	if fase_atual == FASE_FINAL:
		return FASE_FINAL

	return FASE_GRUPOS



# ============================================================
# UI PRINCIPAL
# ============================================================
func _montar_tela_lobby() -> void:
	if em_sequencia_final:
		return
	

	tela_modo = "LOBBY"
	_limpar_ui()
	_parar_confetes()
	_atualizar_fase_atual()

	if fase_visualizada == "" or fase_visualizada == FASE_ENCERRADA:
		fase_visualizada = _fase_visualizavel_padrao()

	if _estado_visual_fase(fase_visualizada) == "BLOQUEADA":
		fase_visualizada = _fase_visualizavel_padrao()

	var vp: Vector2 = get_viewport_rect().size

	var header := Panel.new()
	header.position = Vector2.ZERO
	header.size = Vector2(vp.x, 86)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_stylebox_override(
		"panel",
		_style_panel(Color(1, 1, 1, 0.12), Color(0.016, 0.020, 0.030, 0.98), 0.20)
	)
	ui_root.add_child(header)

	var titulo := _label("🏆  LOBBY DA COPA", 36, Color.WHITE, COR_NEON)
	titulo.position = Vector2(44, 0)
	titulo.size = Vector2(vp.x * 0.50, 86)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ui_root.add_child(titulo)

	var badge := _label(_texto_fase_atual(), 17, COR_ALERTA)
	badge.position = Vector2(vp.x - 430, 0)
	badge.size = Vector2(380, 86)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui_root.add_child(badge)

	# Fundo da Copa abaixo do cabeçalho.
	_criar_back_copa(true, 0.58, 0.060)

	_criar_fluxograma_copa(vp)

	if fase_visualizada == FASE_GRUPOS:
		_criar_grid_grupos(vp)
	else:
		_criar_bracket_knockout(vp)

	_criar_footer(vp)



func _criar_fluxograma_copa(vp: Vector2) -> void:
	var y: float = 96.0
	var h: float = 68.0

	# Mais largura para respirar em X.
	var total_w: float = minf(vp.x - 96.0, 1320.0)
	var x: float = (vp.x - total_w) / 2.0

	# Gap maior para a seta ficar bonita.
	var gap: float = 54.0

	if vp.x < 1280.0:
		gap = 38.0

	var etapas: Array = [
		{
			"fase": FASE_GRUPOS,
			"titulo": "GRUPOS",
			"sub": "16 → 8"
		},
		{
			"fase": FASE_OITAVAS,
			"titulo": "TOP 8",
			"sub": "2 JOGOS DE 4"
		},
		{
			"fase": FASE_SEMIFINAL,
			"titulo": "SEMIFINAL",
			"sub": "4 → 2"
		},
		{
			"fase": FASE_FINAL,
			"titulo": "FINAL",
			"sub": "2 → CAMPEÃO"
		}
	]

	var box_w: float = (total_w - gap * float(etapas.size() - 1)) / float(etapas.size())

	for i in range(etapas.size()):
		var e: Dictionary = etapas[i]
		var fase: String = str(e["fase"])

		var estado: String = _estado_visual_fase(fase)
		var sendo_vista: bool = fase == fase_visualizada

		var cor: Color = Color(0.35, 0.40, 0.50)
		var fundo: Color = Color(0.025, 0.030, 0.042, 0.95)
		var brilho: float = 0.08

		if estado == "ATUAL":
			cor = COR_ALERTA
			fundo = Color(0.070, 0.050, 0.015, 0.98)
			brilho = 0.62
		elif estado == "CONCLUIDA":
			cor = COR_OK
			fundo = Color(0.020, 0.055, 0.035, 0.96)
			brilho = 0.28
		elif estado == "LIBERADA":
			cor = COR_NEON
			fundo = Color(0.018, 0.030, 0.045, 0.96)
			brilho = 0.22
		elif estado == "BLOQUEADA":
			cor = Color(0.20, 0.24, 0.30)
			fundo = Color(0.014, 0.018, 0.026, 0.92)
			brilho = 0.02

		if sendo_vista:
			brilho = maxf(brilho, 0.72)
			fundo = Color(
				minf(fundo.r + 0.018, 1.0),
				minf(fundo.g + 0.018, 1.0),
				minf(fundo.b + 0.026, 1.0),
				fundo.a
			)

		var box_pos := Vector2(x + float(i) * (box_w + gap), y)

		var box := Panel.new()
		box.position = box_pos
		box.size = Vector2(box_w, h)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_theme_stylebox_override("panel", _style_panel(cor, fundo, brilho))
		ui_root.add_child(box)

		# Número pequeno da etapa.
		var num_box := Panel.new()
		num_box.position = Vector2(14, 15)
		num_box.size = Vector2(32, 32)
		num_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		num_box.add_theme_stylebox_override("panel", _style_chip(cor))
		box.add_child(num_box)

		var num_lbl := _label(str(i + 1), 15, Color.WHITE)
		num_lbl.position = Vector2.ZERO
		num_lbl.size = num_box.size
		num_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
		num_lbl.add_theme_constant_override("outline_size", 3)
		num_box.add_child(num_lbl)

		var titulo := _label(str(e["titulo"]), 19, Color.WHITE, cor)
		titulo.position = Vector2(54, 8)
		titulo.size = Vector2(box_w - 68, 32)
		titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		titulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
		titulo.add_theme_constant_override("outline_size", 4)
		box.add_child(titulo)

		var sub := _label(str(e["sub"]), 13, Color(0.74, 0.84, 0.96))
		sub.position = Vector2(54, 38)
		sub.size = Vector2(box_w - 68, 24)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		box.add_child(sub)

		if sendo_vista:
			var underline := ColorRect.new()
			underline.color = Color(cor.r, cor.g, cor.b, 1.0)
			underline.position = Vector2(box_w * 0.18, h - 7)
			underline.size = Vector2(box_w * 0.64, 4)
			underline.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_child(underline)

		var acessivel: bool = estado != "BLOQUEADA"

		if acessivel:
			var btn := Button.new()
			btn.position = box.position
			btn.size = box.size
			btn.focus_mode = Control.FOCUS_NONE
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn.add_theme_stylebox_override("normal", _style_transparente(0.0))
			btn.add_theme_stylebox_override("hover", _style_transparente(0.12, cor))
			btn.add_theme_stylebox_override("pressed", _style_transparente(0.20, cor))
			btn.add_theme_stylebox_override("focus", _style_transparente(0.0))

			var fase_alvo: String = fase
			btn.pressed.connect(func():
				_tocar_select_cup()
				fase_visualizada = fase_alvo
				_montar_tela_lobby()
			)

			ui_root.add_child(btn)

		# Seta moderna entre os cards.
		if i < etapas.size() - 1:
			var seta_tam: float = 38.0
			var seta_x: float = box_pos.x + box_w + (gap - seta_tam) * 0.5
			var seta_y: float = y + h * 0.5 - seta_tam * 0.5

			var seta_box := Panel.new()
			seta_box.position = Vector2(seta_x, seta_y)
			seta_box.size = Vector2(seta_tam, seta_tam)
			seta_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

			var seta_style := StyleBoxFlat.new()
			seta_style.bg_color = Color(0.012, 0.018, 0.030, 0.92)
			seta_style.border_color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 0.72)
			seta_style.set_border_width_all(2)
			seta_style.set_corner_radius_all(int(seta_tam * 0.5))
			seta_style.shadow_color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 0.42)
			seta_style.shadow_size = 14
			seta_style.shadow_offset = Vector2.ZERO
			seta_box.add_theme_stylebox_override("panel", seta_style)
			ui_root.add_child(seta_box)

			var seta_lbl := _label("➜", 25, Color.WHITE, COR_NEON)
			seta_lbl.position = Vector2(0, -1)
			seta_lbl.size = Vector2(seta_tam, seta_tam)
			seta_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.94))
			seta_lbl.add_theme_constant_override("outline_size", 4)
			seta_box.add_child(seta_lbl)


func _estado_visual_fase(fase: String) -> String:
	_atualizar_fase_atual()

	if fase_atual == FASE_ENCERRADA:
		if fase == FASE_GRUPOS:
			return "CONCLUIDA"

		if fase == FASE_OITAVAS and not _partidas_da_fase(FASE_OITAVAS).is_empty():
			return "CONCLUIDA"

		if fase == FASE_SEMIFINAL and not _partidas_da_fase(FASE_SEMIFINAL).is_empty():
			return "CONCLUIDA"

		if fase == FASE_FINAL and not _partidas_da_fase(FASE_FINAL).is_empty():
			return "CONCLUIDA"

		return "BLOQUEADA"

	if fase == fase_atual:
		return "ATUAL"

	if fase == FASE_GRUPOS:
		if _fase_totalmente_finalizada(FASE_GRUPOS):
			return "CONCLUIDA"

		return "ATUAL"

	if fase == FASE_OITAVAS:
		if _partidas_da_fase(FASE_OITAVAS).is_empty():
			return "BLOQUEADA"

		if _fase_totalmente_finalizada(FASE_OITAVAS):
			return "CONCLUIDA"

		if fase_atual == FASE_OITAVAS:
			return "ATUAL"

		return "LIBERADA"

	if fase == FASE_SEMIFINAL:
		if _partidas_da_fase(FASE_SEMIFINAL).is_empty():
			return "BLOQUEADA"

		if _fase_totalmente_finalizada(FASE_SEMIFINAL):
			return "CONCLUIDA"

		if fase_atual == FASE_SEMIFINAL:
			return "ATUAL"

		return "LIBERADA"

	if fase == FASE_FINAL:
		if _partidas_da_fase(FASE_FINAL).is_empty():
			return "BLOQUEADA"

		if _fase_totalmente_finalizada(FASE_FINAL):
			return "CONCLUIDA"

		if fase_atual == FASE_FINAL:
			return "ATUAL"

		return "LIBERADA"

	return "BLOQUEADA"


func _texto_fase_atual() -> String:
	match fase_atual:
		FASE_GRUPOS:
			return "FASE DE GRUPOS"
		FASE_OITAVAS:
			return "TOP 8  •  2 PARTIDAS COM 4"
		FASE_SEMIFINAL:
			return "SEMIFINAL  •  2x2"
		FASE_FINAL:
			return "FINAL  •  DECISÃO"
		FASE_ENCERRADA:
			return "COPA FINALIZADA"
		_:
			return fase_atual



func _criar_grid_grupos(vp: Vector2) -> void:
	var grid_w: float = minf(vp.x - 88.0, 1380.0)
	var grid_h: float = vp.y - 310.0
	var grid_x: float = (vp.x - grid_w) / 2.0
	var grid_y: float = 212.0

	var gap_x: float = 26.0
	var gap_y: float = 22.0

	var card_w: float = (grid_w - gap_x) / 2.0
	var card_h: float = (grid_h - gap_y) / 2.0

	var prox_index: int = _buscar_proxima_partida_pendente()
	var grupo_ativo: String = ""

	if prox_index >= 0:
		grupo_ativo = str(partidas[prox_index].get("grupo", ""))

	for g in range(grupos.size()):
		var col: int = g % 2
		var row: int = int(g / 2)

		var px: float = grid_x + float(col) * (card_w + gap_x)
		var py: float = grid_y + float(row) * (card_h + gap_y)

		var grupo_nome: String = str(grupos[g].get("grupo", ""))
		var destaque: bool = fase_atual == FASE_GRUPOS and grupo_nome == grupo_ativo

		var card := _criar_card_grupo(g, Vector2(card_w, card_h), destaque)
		card.position = Vector2(px, py)
		ui_root.add_child(card)



func _desenhar_cruzamentos_top8_grupos(rects_grupos: Dictionary) -> void:
	if rects_grupos.has("A") and rects_grupos.has("B"):
		var rect_a: Rect2 = rects_grupos["A"]
		var rect_b: Rect2 = rects_grupos["B"]

		# A1 encontra B2.
		_desenhar_cruzamento_grupo_para_top8(rect_a, 0, rect_b, 1, COR_ALERTA)

		# B1 encontra A2.
		_desenhar_cruzamento_grupo_para_top8(rect_b, 0, rect_a, 1, COR_NEON)

	if rects_grupos.has("C") and rects_grupos.has("D"):
		var rect_c: Rect2 = rects_grupos["C"]
		var rect_d: Rect2 = rects_grupos["D"]

		# C1 encontra D2.
		_desenhar_cruzamento_grupo_para_top8(rect_c, 0, rect_d, 1, COR_OK)

		# D1 encontra C2.
		_desenhar_cruzamento_grupo_para_top8(rect_d, 0, rect_c, 1, COR_BRONZE)


func _desenhar_cruzamento_grupo_para_top8(
	origem: Rect2,
	pos_origem: int,
	destino: Rect2,
	pos_destino: int,
	cor: Color
) -> void:
	var y_origem: float = _y_linha_jogador_grupo(origem, pos_origem)
	var y_destino: float = _y_linha_jogador_grupo(destino, pos_destino)

	var origem_esquerda: bool = origem.position.x < destino.position.x

	var a: Vector2
	var b: Vector2

	if origem_esquerda:
		a = Vector2(origem.position.x + origem.size.x + 5.0, y_origem)
		b = Vector2(destino.position.x - 5.0, y_destino)
	else:
		a = Vector2(origem.position.x - 5.0, y_origem)
		b = Vector2(destino.position.x + destino.size.x + 5.0, y_destino)

	_desenhar_linha_diagonal_neon(a, b, cor, 4.0, 0.62)


func _y_linha_jogador_grupo(rect: Rect2, pos_rank: int) -> float:
	var linha_y: float = 92.0
	var linha_h: float = (rect.size.y - 104.0) / 4.0

	return rect.position.y + linha_y + float(pos_rank) * linha_h + linha_h * 0.5


func _desenhar_linha_diagonal_neon(a: Vector2, b: Vector2, cor: Color, espessura: float = 4.0, brilho: float = 0.52) -> void:
	var sombra := Line2D.new()
	sombra.points = PackedVector2Array([a, b])
	sombra.width = espessura * 3.4
	sombra.default_color = Color(cor.r, cor.g, cor.b, brilho * 0.24)
	sombra.antialiased = true
	sombra.z_index = 8
	ui_root.add_child(sombra)

	var linha := Line2D.new()
	linha.points = PackedVector2Array([a, b])
	linha.width = espessura
	linha.default_color = Color(cor.r, cor.g, cor.b, 0.95)
	linha.antialiased = true
	linha.z_index = 9
	ui_root.add_child(linha)

	var brilho_centro := Line2D.new()
	brilho_centro.points = PackedVector2Array([a, b])
	brilho_centro.width = maxf(1.0, espessura * 0.30)
	brilho_centro.default_color = Color(1, 1, 1, 0.45)
	brilho_centro.antialiased = true
	brilho_centro.z_index = 10
	ui_root.add_child(brilho_centro)

	_criar_no_conexao(a, cor)
	_criar_no_conexao(b, cor)


# ============================================================
# BRACKET / CHAVEAMENTO — FUNIL ABERTO DOS DOIS LADOS
# LADO A → SEMI A → FINAL ← SEMI B ← LADO B
# Campeão fica abaixo da final, sem sobrepor.
# ============================================================
func _criar_bracket_knockout(vp: Vector2) -> void:
	var area_x: float = 34.0
	var area_y: float = 180.0
	var footer_limite: float = vp.y - 88.0

	var oitavas: Array = _partidas_da_fase(FASE_OITAVAS)
	var semis: Array = _partidas_da_fase(FASE_SEMIFINAL)
	var finais: Array = _partidas_da_fase(FASE_FINAL)

	var corpo_y: float = area_y + 30.0
	var corpo_h: float = footer_limite - corpo_y
	var centro_x: float = vp.x * 0.5

	var mostrar_top8: bool = fase_visualizada == FASE_OITAVAS or fase_visualizada == FASE_SEMIFINAL or fase_visualizada == FASE_FINAL
	var mostrar_semi: bool = fase_visualizada == FASE_SEMIFINAL or fase_visualizada == FASE_FINAL
	var mostrar_final: bool = fase_visualizada == FASE_FINAL

	var p_top8_a: Dictionary = {}
	var p_top8_b: Dictionary = {}
	var p_semi_a: Dictionary = {}
	var p_semi_b: Dictionary = {}
	var p_final: Dictionary = {}
	var p_terceiro: Dictionary = {}

	if oitavas.size() > 0:
		p_top8_a = oitavas[0]

	if oitavas.size() > 1:
		p_top8_b = oitavas[1]

	if semis.size() > 0:
		p_semi_a = semis[0]

	if semis.size() > 1:
		p_semi_b = semis[1]

	for p in finais:
		if bool(p.get("disputa_terceiro", false)):
			p_terceiro = p
		else:
			p_final = p

	# ========================================================
	# MODO TOP 8 — MOSTRA SÓ AS DUAS PARTIDAS GRANDES
	# ========================================================
	if fase_visualizada == FASE_OITAVAS:
		var gap_top8: float = 42.0
		var card_w: float = minf((vp.x - area_x * 2.0 - gap_top8) / 2.0, 560.0)
		var card_h: float = minf(corpo_h - 18.0, 430.0)

		card_w = maxf(card_w, 390.0)
		card_h = maxf(card_h, 300.0)

		var total_w: float = card_w * 2.0 + gap_top8
		var x_a: float = centro_x - total_w * 0.5
		var x_b: float = x_a + card_w + gap_top8
		var y: float = corpo_y + (corpo_h - card_h) * 0.5

		var titulo := _label("TOP 8 DA COPA", 24, Color.WHITE, COR_NEON)
		titulo.position = Vector2(0, area_y - 2)
		titulo.size = Vector2(vp.x, 34)
		ui_root.add_child(titulo)

		var sub := _label("2 PARTIDAS COM 4 JOGADORES  •  PASSAM 2 DE CADA  •  EMPATE POR CRITÉRIO", 13, Color(0.68, 0.78, 0.90))
		sub.position = Vector2(0, area_y + 28)
		sub.size = Vector2(vp.x, 22)
		ui_root.add_child(sub)

		ui_root.add_child(_card_partida_knockout_moderno(
			p_top8_a,
			"TOP 8 • JOGO 1",
			Rect2(Vector2(x_a, y), Vector2(card_w, card_h)),
			fase_atual == FASE_OITAVAS
		))

		ui_root.add_child(_card_partida_knockout_moderno(
			p_top8_b,
			"TOP 8 • JOGO 2",
			Rect2(Vector2(x_b, y), Vector2(card_w, card_h)),
			fase_atual == FASE_OITAVAS
		))

		return

	# ========================================================
	# MODO SEMIFINAL — MOSTRA TOP 8 + SEMIFINAL, SEM FINAL
	# ========================================================
	if fase_visualizada == FASE_SEMIFINAL:
		var top8_w: float = clampf(vp.x * 0.245, 320.0, 430.0)
		var semi_w: float = clampf(vp.x * 0.245, 320.0, 430.0)

		var top8_h: float = clampf(corpo_h * 0.42, 230.0, 300.0)
		var semi_h: float = clampf(corpo_h * 0.34, 180.0, 250.0)

		var gap_x: float = 54.0
		var total_w_semi: float = top8_w + gap_x + semi_w + gap_x + semi_w + gap_x + top8_w

		if total_w_semi > vp.x - area_x * 2.0:
			var fator_w: float = (vp.x - area_x * 2.0) / total_w_semi
			top8_w *= fator_w
			semi_w *= fator_w
			gap_x *= fator_w

		var x_top8_a: float = area_x
		var x_semi_a: float = x_top8_a + top8_w + gap_x
		var x_semi_b: float = vp.x - area_x - top8_w - gap_x - semi_w
		var x_top8_b: float = vp.x - area_x - top8_w

		var y_top8: float = corpo_y + 18.0
		var y_semi: float = corpo_y + top8_h + 46.0

		if y_semi + semi_h > footer_limite:
			y_semi = footer_limite - semi_h - 4.0

		var rect_top8_a := Rect2(Vector2(x_top8_a, y_top8), Vector2(top8_w, top8_h))
		var rect_top8_b := Rect2(Vector2(x_top8_b, y_top8), Vector2(top8_w, top8_h))
		var rect_semi_a := Rect2(Vector2(x_semi_a, y_semi), Vector2(semi_w, semi_h))
		var rect_semi_b := Rect2(Vector2(x_semi_b, y_semi), Vector2(semi_w, semi_h))

		var titulo2 := _label("SEMIFINAL DA COPA", 24, Color.WHITE, COR_ALERTA)
		titulo2.position = Vector2(0, area_y - 2)
		titulo2.size = Vector2(vp.x, 34)
		ui_root.add_child(titulo2)

		var sub2 := _label("TOP 8 CLASSIFICOU 4 JOGADORES  •  EMPATE TEM PRORROGAÇÃO + PÊNALTIS", 13, Color(0.68, 0.78, 0.90))
		sub2.position = Vector2(0, area_y + 28)
		sub2.size = Vector2(vp.x, 22)
		ui_root.add_child(sub2)

		_desenhar_conexao_lado_aberto(rect_top8_a, rect_semi_a, _cor_caminho_partida(p_top8_a), "ESQ")
		_desenhar_conexao_lado_aberto(rect_top8_b, rect_semi_b, _cor_caminho_partida(p_top8_b), "DIR")

		ui_root.add_child(_card_partida_knockout_moderno(
			p_top8_a,
			"TOP 8 • JOGO 1",
			rect_top8_a,
			false
		))

		ui_root.add_child(_card_partida_knockout_moderno(
			p_top8_b,
			"TOP 8 • JOGO 2",
			rect_top8_b,
			false
		))

		ui_root.add_child(_card_partida_knockout_moderno(
			p_semi_a,
			"SEMIFINAL A",
			rect_semi_a,
			fase_atual == FASE_SEMIFINAL
		))

		ui_root.add_child(_card_partida_knockout_moderno(
			p_semi_b,
			"SEMIFINAL B",
			rect_semi_b,
			fase_atual == FASE_SEMIFINAL
		))

		return

	# ========================================================
	# MODO FINAL — MOSTRA BRACKET COMPLETO
	# ========================================================
	if mostrar_final:
		var compacto: bool = corpo_h < 620.0 or vp.x < 1320.0

		var top8_w: float
		var semi_w: float
		var centro_w: float

		var top8_h: float
		var semi_h: float
		var final_h: float
		var terceiro_h: float

		var gap_x_top8_semi: float
		var gap_x_semi_centro: float

		var gap_y_1: float
		var gap_y_2: float
		var gap_y_3: float

		if compacto:
			top8_w = clampf(vp.x * 0.188, 245.0, 292.0)
			semi_w = clampf(vp.x * 0.150, 182.0, 230.0)
			centro_w = clampf(vp.x * 0.222, 280.0, 345.0)

			top8_h = clampf(corpo_h * 0.315, 188.0, 218.0)
			semi_h = clampf(corpo_h * 0.205, 124.0, 150.0)
			final_h = clampf(corpo_h * 0.215, 136.0, 164.0)
			terceiro_h = clampf(corpo_h * 0.195, 118.0, 146.0)

			gap_x_top8_semi = 8.0
			gap_x_semi_centro = 12.0

			gap_y_1 = 8.0
			gap_y_2 = 10.0
			gap_y_3 = 8.0
		else:
			top8_w = clampf(vp.x * 0.198, 300.0, 350.0)
			semi_w = clampf(vp.x * 0.155, 220.0, 265.0)
			centro_w = clampf(vp.x * 0.222, 320.0, 395.0)

			top8_h = 224.0
			semi_h = 158.0
			final_h = 176.0
			terceiro_h = 152.0

			gap_x_top8_semi = 14.0
			gap_x_semi_centro = 24.0

			gap_y_1 = 10.0
			gap_y_2 = 12.0
			gap_y_3 = 8.0

		var total_h: float = top8_h + semi_h + final_h + terceiro_h + gap_y_1 + gap_y_2 + gap_y_3

		if total_h > corpo_h - 6.0:
			var fator: float = (corpo_h - 6.0) / total_h

			top8_h *= fator
			semi_h *= fator
			final_h *= fator
			terceiro_h *= fator

			gap_y_1 *= fator
			gap_y_2 *= fator
			gap_y_3 *= fator

		var x_final: float = centro_x - centro_w * 0.5
		var x_terceiro: float = x_final

		var x_semi_a: float = x_final - gap_x_semi_centro - semi_w
		var x_semi_b: float = x_final + centro_w + gap_x_semi_centro

		var x_top8_a: float = x_semi_a - gap_x_top8_semi - top8_w
		var x_top8_b: float = x_semi_b + semi_w + gap_x_top8_semi

		if x_top8_a < area_x:
			var ajuste_esq: float = area_x - x_top8_a
			x_top8_a += ajuste_esq
			x_semi_a += ajuste_esq * 0.40

		if x_top8_b + top8_w > vp.x - area_x:
			var ajuste_dir: float = (x_top8_b + top8_w) - (vp.x - area_x)
			x_top8_b -= ajuste_dir
			x_semi_b -= ajuste_dir * 0.40

		if x_semi_a + semi_w > x_final - 6.0:
			x_semi_a = x_final - semi_w - 8.0
			x_top8_a = maxf(area_x, x_semi_a - top8_w - 6.0)

		if x_semi_b < x_final + centro_w + 6.0:
			x_semi_b = x_final + centro_w + 8.0
			x_top8_b = minf(vp.x - area_x - top8_w, x_semi_b + semi_w + 6.0)

		var y_top8: float = corpo_y + 2.0
		var y_semi: float = y_top8 + top8_h + gap_y_1
		var y_final: float = y_semi + semi_h + gap_y_2
		var y_terceiro: float = y_final + final_h + gap_y_3

		var bottom_real: float = y_terceiro + terceiro_h

		if bottom_real > footer_limite:
			var excesso_y: float = bottom_real - footer_limite

			y_top8 -= excesso_y
			y_semi -= excesso_y
			y_final -= excesso_y
			y_terceiro -= excesso_y

		if y_top8 < corpo_y:
			var volta: float = corpo_y - y_top8

			y_top8 += volta
			y_semi += volta
			y_final += volta
			y_terceiro += volta

		var rect_top8_a := Rect2(Vector2(x_top8_a, y_top8), Vector2(top8_w, top8_h))
		var rect_top8_b := Rect2(Vector2(x_top8_b, y_top8), Vector2(top8_w, top8_h))

		var rect_semi_a := Rect2(Vector2(x_semi_a, y_semi), Vector2(semi_w, semi_h))
		var rect_semi_b := Rect2(Vector2(x_semi_b, y_semi), Vector2(semi_w, semi_h))

		var rect_final := Rect2(Vector2(x_final, y_final), Vector2(centro_w, final_h))
		var rect_terceiro := Rect2(Vector2(x_terceiro, y_terceiro), Vector2(centro_w, terceiro_h))

		var titulo3 := _label("GRANDE FINAL DA COPA", 24, Color.WHITE, COR_ALERTA)
		titulo3.position = Vector2(0, area_y - 2)
		titulo3.size = Vector2(vp.x, 34)
		ui_root.add_child(titulo3)

		var sub3 := _label("CHAVEAMENTO COMPLETO  •  FINAL  •  DECISÃO DO 3º LUGAR", 13, Color(0.68, 0.78, 0.90))
		sub3.position = Vector2(0, area_y + 28)
		sub3.size = Vector2(vp.x, 22)
		ui_root.add_child(sub3)

		_desenhar_conexao_lado_aberto(rect_top8_a, rect_semi_a, _cor_caminho_partida(p_top8_a), "ESQ")
		_desenhar_conexao_lado_aberto(rect_top8_b, rect_semi_b, _cor_caminho_partida(p_top8_b), "DIR")

		_desenhar_conexao_lado_aberto(rect_semi_a, rect_final, _cor_caminho_partida(p_semi_a), "ESQ")
		_desenhar_conexao_lado_aberto(rect_semi_b, rect_final, _cor_caminho_partida(p_semi_b), "DIR")

		var cor_terceiro: Color = COR_BRONZE
		if not p_terceiro.is_empty():
			cor_terceiro = _cor_caminho_partida(p_terceiro)

		_desenhar_conexao_lado_aberto(rect_semi_a, rect_terceiro, cor_terceiro, "ESQ")
		_desenhar_conexao_lado_aberto(rect_semi_b, rect_terceiro, cor_terceiro, "DIR")

		ui_root.add_child(_card_partida_knockout_moderno(
			p_top8_a,
			"TOP 8 • JOGO 1",
			rect_top8_a,
			false
		))

		ui_root.add_child(_card_partida_knockout_moderno(
			p_top8_b,
			"TOP 8 • JOGO 2",
			rect_top8_b,
			false
		))

		ui_root.add_child(_card_partida_knockout_moderno(
			p_semi_a,
			"SEMIFINAL A",
			rect_semi_a,
			false
		))

		ui_root.add_child(_card_partida_knockout_moderno(
			p_semi_b,
			"SEMIFINAL B",
			rect_semi_b,
			false
		))

		ui_root.add_child(_card_partida_knockout_moderno(
			p_final,
			"🏆 GRANDE FINAL",
			rect_final,
			fase_atual == FASE_FINAL,
			true
		))

		ui_root.add_child(_card_partida_knockout_moderno(
			p_terceiro,
			"🥉 DECISÃO 3º LUGAR",
			rect_terceiro,
			fase_atual == FASE_FINAL
		))


func _desenhar_conexao_lado_aberto(origem: Rect2, destino: Rect2, cor: Color, lado: String) -> void:
	if cor.a <= 0.0:
		cor = COR_NEON

	var start: Vector2
	var end: Vector2

	if lado == "DIR":
		# Sai da esquerda do card da direita e entra pela direita do destino.
		start = Vector2(
			origem.position.x,
			origem.position.y + origem.size.y * 0.5
		)

		end = Vector2(
			destino.position.x + destino.size.x,
			destino.position.y + destino.size.y * 0.5
		)
	else:
		# Sai da direita do card da esquerda e entra pela esquerda do destino.
		start = Vector2(
			origem.position.x + origem.size.x,
			origem.position.y + origem.size.y * 0.5
		)

		end = Vector2(
			destino.position.x,
			destino.position.y + destino.size.y * 0.5
		)

	var distancia_x: float = abs(end.x - start.x)
	var recuo: float = clampf(distancia_x * 0.45, 24.0, 70.0)

	var meio_x: float

	if lado == "DIR":
		meio_x = start.x - recuo
	else:
		meio_x = start.x + recuo

	var p1 := start
	var p2 := Vector2(meio_x, start.y)
	var p3 := Vector2(meio_x, end.y)
	var p4 := end

	_desenhar_linha_neon(p1, p2, cor, 4.0, 0.52)
	_desenhar_linha_neon(p2, p3, cor, 4.0, 0.52)
	_desenhar_linha_neon(p3, p4, cor, 4.0, 0.52)

	_criar_no_conexao(p1, cor)
	_criar_no_conexao(p4, cor)


func _criar_titulo_coluna_chave(titulo_txt: String, sub_txt: String, x: float, y: float, w: float, destaque: bool) -> void:
	var cor: Color = COR_ALERTA if destaque else COR_NEON

	var box := Panel.new()
	box.position = Vector2(x, y)
	box.size = Vector2(w, 36)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fundo: Color = Color(0.018, 0.026, 0.038, 0.88)
	if destaque:
		fundo = Color(0.055, 0.042, 0.012, 0.96)

	box.add_theme_stylebox_override("panel", _style_panel(cor, fundo, 0.42 if destaque else 0.14))
	ui_root.add_child(box)

	var titulo := _label(titulo_txt, 14, Color.WHITE, cor)
	titulo.position = Vector2(0, -1)
	titulo.size = Vector2(w, 22)
	box.add_child(titulo)

	var sub := _label(sub_txt, 10, Color(0.68, 0.76, 0.88))
	sub.position = Vector2(0, 18)
	sub.size = Vector2(w, 16)
	box.add_child(sub)



func _card_partida_knockout_moderno(
	p: Dictionary,
	titulo_txt: String,
	rect: Rect2,
	destaque: bool,
	eh_final: bool = false
) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.clip_contents = true

	var vazia: bool = p.is_empty()
	var finalizada: bool = not vazia and bool(p.get("finalizada", false))

	var cor: Color = COR_NEON
	var fundo: Color = Color(0.014, 0.020, 0.032, 0.98)
	var brilho: float = 0.18

	if vazia:
		cor = Color(0.24, 0.28, 0.34)
		fundo = Color(0.010, 0.014, 0.022, 0.94)
		brilho = 0.03
	elif finalizada:
		cor = _cor_caminho_partida(p)
		fundo = Color(cor.r * 0.045, cor.g * 0.045, cor.b * 0.045, 0.98)
		brilho = 0.34
	elif destaque:
		cor = COR_ALERTA
		fundo = Color(0.055, 0.040, 0.012, 0.98)
		brilho = 0.58

	if eh_final:
		cor = COR_ALERTA if not finalizada else _cor_caminho_partida(p)
		fundo = Color(0.060, 0.046, 0.010, 0.98)
		brilho = 0.75

	panel.add_theme_stylebox_override("panel", _style_panel(cor, fundo, brilho))

	var W: float = rect.size.x
	var H: float = rect.size.y

	var faixa := ColorRect.new()
	faixa.color = Color(cor.r, cor.g, cor.b, 0.30)
	faixa.position = Vector2(14, 8)
	faixa.size = Vector2(W - 28, 3)
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(faixa)

	var titulo_size: int = 13
	if H >= 170.0:
		titulo_size = 15
	if eh_final:
		titulo_size += 1

	var titulo := _label(titulo_txt, titulo_size, Color.WHITE, cor)
	titulo.position = Vector2(8, 13)
	titulo.size = Vector2(W - 16, 26)
	titulo.clip_text = true
	titulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.90))
	titulo.add_theme_constant_override("outline_size", 3)
	panel.add_child(titulo)

	if vazia:
		var ag := _label("AGUARDANDO", 15, Color(0.48, 0.54, 0.62))
		ag.position = Vector2(0, H * 0.5 - 18)
		ag.size = Vector2(W, 36)
		panel.add_child(ag)
		return panel

	var lista: Array = []

	if finalizada and p.has("ranking") and p["ranking"] is Array and (p["ranking"] as Array).size() > 0:
		lista = p["ranking"] as Array
	else:
		var jogadores_raw: Variant = p.get("jogadores", [])
		if jogadores_raw is Array:
			lista = jogadores_raw as Array

	var classificados_nomes: Array[String] = []

	var classificados_raw: Variant = p.get("classificados", [])
	if classificados_raw is Array:
		for c in classificados_raw:
			if c is Dictionary:
				classificados_nomes.append(str(c.get("nome", "")))

	var top_y: float = 43.0
	var bottom_pad: float = 8.0
	var disp_h: float = H - top_y - bottom_pad
	var n: int = maxi(lista.size(), 1)
	var row_h: float = disp_h / float(n)

	var nome_font: int = 12
	var chip_tam: float = 16.0

	if row_h >= 36.0:
		nome_font = 16
		chip_tam = 22.0
	elif row_h >= 31.0:
		nome_font = 15
		chip_tam = 20.0
	elif row_h >= 26.0:
		nome_font = 14
		chip_tam = 18.0
	elif row_h >= 21.0:
		nome_font = 12
		chip_tam = 16.0
	else:
		nome_font = 10
		chip_tam = 13.0

	if lista.size() <= 2 and H >= 120.0:
		nome_font += 2
		chip_tam += 2.0

	for i in range(lista.size()):
		if not (lista[i] is Dictionary):
			continue

		var j: Dictionary = lista[i]
		var nome: String = str(j.get("nome", "?"))
		var eh_boot: bool = bool(j.get("boot", false))
		var classificou: bool = classificados_nomes.has(nome)
		var eliminado: bool = finalizada and not classificou

		if finalizada and classificados_nomes.is_empty():
			var posicao_item: int = int(j.get("posicao", i + 1))
			var fase_card: String = str(p.get("fase", ""))

			if fase_card == FASE_OITAVAS and posicao_item <= 2:
				classificou = true
				eliminado = false
			elif (fase_card == FASE_SEMIFINAL or fase_card == FASE_FINAL) and posicao_item == 1:
				classificou = true
				eliminado = false
			else:
				eliminado = true

		var y: float = top_y + float(i) * row_h
		var cor_j: Color = _cor_jogador_dict(j)

		var row := Panel.new()
		row.position = Vector2(10, y + 3)
		row.size = Vector2(W - 20, maxf(row_h - 6, 16.0))
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var row_bg: Color = Color(cor_j.r * 0.070, cor_j.g * 0.070, cor_j.b * 0.070, 0.82)
		var row_border: Color = Color(cor_j.r, cor_j.g, cor_j.b, 0.35)
		var row_shadow: float = 0.06
		var border_w: int = 1

		if eliminado:
			row_bg = Color(0.018, 0.019, 0.023, 0.98)
			row_border = Color(0.24, 0.25, 0.29, 0.95)
			row_shadow = 0.00
			border_w = 1
		elif classificou:
			row_bg = Color(cor_j.r * 0.190, cor_j.g * 0.190, cor_j.b * 0.190, 0.98)
			row_border = Color(cor_j.r, cor_j.g, cor_j.b, 1.0)
			row_shadow = 0.42
			border_w = 3

		var rs := StyleBoxFlat.new()
		rs.bg_color = row_bg
		rs.border_color = row_border
		rs.set_border_width_all(border_w)
		rs.set_corner_radius_all(12)
		rs.shadow_color = Color(cor_j.r, cor_j.g, cor_j.b, row_shadow)
		rs.shadow_size = 14 if classificou else 4
		rs.shadow_offset = Vector2.ZERO
		row.add_theme_stylebox_override("panel", rs)
		panel.add_child(row)

		var chip := Panel.new()
		chip.position = Vector2(20, y + row_h * 0.5 - chip_tam * 0.5)
		chip.size = Vector2(chip_tam, chip_tam)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_theme_stylebox_override("panel", _style_chip(cor_j))
		panel.add_child(chip)

		if eliminado:
			chip.modulate = Color(0.32, 0.32, 0.32, 0.70)

		var nome_txt: String = nome
		if eh_boot:
			nome_txt += " BOT"

		var nome_cor: Color = Color.WHITE

		if eliminado:
			nome_cor = Color(0.46, 0.48, 0.52)
		elif eh_boot:
			nome_cor = COR_BOOT

		if classificou:
			nome_cor = Color(0.96, 1.0, 0.96)

		# Layout profissional:
		# esquerda: chip + nome
		# direita: placar compacto + check
		var layout_compacto: bool = W < 230.0

		var nome_x: float = 44.0 if layout_compacto else 48.0
		var check_w: float = 18.0 if layout_compacto else 24.0
		var check_x: float = W - check_w - (4.0 if layout_compacto else 8.0)

		var placar_w: float = 0.0
		var placar_x: float = check_x
		var nome_w: float = W - nome_x - 42.0

		if finalizada:
			var tem_extra_placar: bool = (
				bool(j.get("jogou_prorrogacao", false))
				or bool(j.get("jogou_penaltis", false))
				or int(j.get("gols_prorrogacao", 0)) > 0
				or int(j.get("penaltis", 0)) > 0
			)

			if layout_compacto:
				placar_w = 48.0 if tem_extra_placar else 42.0
			else:
				placar_w = 82.0 if tem_extra_placar else 62.0

			placar_x = check_x - placar_w - (2.0 if layout_compacto else 5.0)
			nome_w = maxf(42.0, placar_x - nome_x - 6.0)

		var nome_lbl := _label(nome_txt, nome_font, nome_cor)
		nome_lbl.position = Vector2(nome_x, y)
		nome_lbl.size = Vector2(nome_w, row_h)
		nome_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		nome_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nome_lbl.clip_text = true
		nome_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
		nome_lbl.add_theme_constant_override("outline_size", 4 if classificou else 3)
		panel.add_child(nome_lbl)

		if finalizada:
			_adicionar_placar_knockout_profissional(
				panel,
				j,
				Vector2(placar_x, y + 4.0),
				Vector2(placar_w, maxf(row_h - 8.0, 18.0)),
				cor_j,
				eliminado
			)

		if classificou:
			var ok := _label("✓", 18, COR_OK, COR_OK)
			ok.position = Vector2(check_x, y)
			ok.size = Vector2(check_w, row_h)
			ok.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ok.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			ok.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
			ok.add_theme_constant_override("outline_size", 4)
			panel.add_child(ok)
		elif eliminado:
			var fora := _label("✕", 18, Color(0.48, 0.50, 0.55))
			fora.position = Vector2(check_x, y)
			fora.size = Vector2(check_w, row_h)
			fora.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			fora.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			fora.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
			fora.add_theme_constant_override("outline_size", 4)
			panel.add_child(fora)

	return panel



func _desenhar_conexao_chave(origem: Rect2, destino: Rect2, cor: Color, destino_central: bool = false) -> void:
	var start := Vector2(origem.position.x + origem.size.x, origem.position.y + origem.size.y * 0.5)
	var end := Vector2(destino.position.x, destino.position.y + destino.size.y * 0.5)

	var meio_x: float = start.x + (end.x - start.x) * 0.52

	if destino_central:
		meio_x = start.x + (end.x - start.x) * 0.46

	var p1 := start
	var p2 := Vector2(meio_x, start.y)
	var p3 := Vector2(meio_x, end.y)
	var p4 := end

	_desenhar_linha_neon(p1, p2, cor, 5.0, 0.50)
	_desenhar_linha_neon(p2, p3, cor, 5.0, 0.50)
	_desenhar_linha_neon(p3, p4, cor, 5.0, 0.50)

	_criar_no_conexao(p1, cor)
	_criar_no_conexao(p4, cor)


func _desenhar_linha_neon(a: Vector2, b: Vector2, cor: Color, espessura: float = 4.0, brilho: float = 0.45) -> void:
	if abs(a.x - b.x) >= abs(a.y - b.y):
		_desenhar_linha_horizontal(a, b, cor, espessura, brilho)
	else:
		_desenhar_linha_vertical(a, b, cor, espessura, brilho)


func _desenhar_linha_horizontal(a: Vector2, b: Vector2, cor: Color, espessura: float, brilho: float) -> void:
	var x1: float = minf(a.x, b.x)
	var x2: float = maxf(a.x, b.x)
	var y: float = a.y - espessura * 0.5

	var sombra := ColorRect.new()
	sombra.position = Vector2(x1, y - espessura * 1.2)
	sombra.size = Vector2(x2 - x1, espessura * 3.4)
	sombra.color = Color(cor.r, cor.g, cor.b, brilho * 0.22)
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(sombra)

	var linha := ColorRect.new()
	linha.position = Vector2(x1, y)
	linha.size = Vector2(x2 - x1, espessura)
	linha.color = Color(cor.r, cor.g, cor.b, 0.92)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(linha)

	var brilho_centro := ColorRect.new()
	brilho_centro.position = Vector2(x1, y + espessura * 0.35)
	brilho_centro.size = Vector2(x2 - x1, maxf(1.0, espessura * 0.25))
	brilho_centro.color = Color.WHITE
	brilho_centro.modulate = Color(1, 1, 1, 0.42)
	brilho_centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(brilho_centro)


func _desenhar_linha_vertical(a: Vector2, b: Vector2, cor: Color, espessura: float, brilho: float) -> void:
	var y1: float = minf(a.y, b.y)
	var y2: float = maxf(a.y, b.y)
	var x: float = a.x - espessura * 0.5

	var sombra := ColorRect.new()
	sombra.position = Vector2(x - espessura * 1.2, y1)
	sombra.size = Vector2(espessura * 3.4, y2 - y1)
	sombra.color = Color(cor.r, cor.g, cor.b, brilho * 0.22)
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(sombra)

	var linha := ColorRect.new()
	linha.position = Vector2(x, y1)
	linha.size = Vector2(espessura, y2 - y1)
	linha.color = Color(cor.r, cor.g, cor.b, 0.92)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(linha)

	var brilho_centro := ColorRect.new()
	brilho_centro.position = Vector2(x + espessura * 0.35, y1)
	brilho_centro.size = Vector2(maxf(1.0, espessura * 0.25), y2 - y1)
	brilho_centro.color = Color.WHITE
	brilho_centro.modulate = Color(1, 1, 1, 0.42)
	brilho_centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(brilho_centro)


func _criar_no_conexao(pos: Vector2, cor: Color) -> void:
	var no := Panel.new()
	no.size = Vector2(14, 14)
	no.position = pos - no.size * 0.5
	no.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var s := StyleBoxFlat.new()
	s.bg_color = Color.WHITE
	s.border_color = cor
	s.set_border_width_all(2)
	s.set_corner_radius_all(7)
	s.shadow_color = Color(cor.r, cor.g, cor.b, 0.90)
	s.shadow_size = 12
	s.shadow_offset = Vector2.ZERO

	no.add_theme_stylebox_override("panel", s)
	ui_root.add_child(no)


func _cor_caminho_partida(p: Dictionary) -> Color:
	if p.is_empty():
		return Color(0.28, 0.34, 0.42)

	var classificados: Array = p.get("classificados", [])

	if classificados.size() > 0:
		var j: Dictionary = classificados[0]
		return _cor_jogador_dict(j)

	if bool(p.get("finalizada", false)) and p.has("ranking") and p["ranking"] is Array and p["ranking"].size() > 0:
		var vencedor: Dictionary = p["ranking"][0]
		return _cor_jogador_dict(vencedor)

	var jogadores: Array = p.get("jogadores", [])
	if jogadores.size() > 0:
		var soma := Color(0, 0, 0, 1)

		for item in jogadores:
			var c: Color = _cor_jogador_dict(item)
			soma.r += c.r
			soma.g += c.g
			soma.b += c.b

		soma.r /= float(jogadores.size())
		soma.g /= float(jogadores.size())
		soma.b /= float(jogadores.size())

		return soma.lightened(0.25)

	return COR_NEON



func _desenhar_conexao_campeao(origem: Rect2, destino: Rect2, cor: Color) -> void:
	if cor.a <= 0.0:
		cor = COR_ALERTA

	var start := Vector2(
		origem.position.x + origem.size.x,
		origem.position.y + origem.size.y * 0.5
	)

	var end := Vector2(
		destino.position.x,
		destino.position.y + destino.size.y * 0.5
	)

	var meio_x: float = start.x + (end.x - start.x) * 0.5

	var p1 := start
	var p2 := Vector2(meio_x, start.y)
	var p3 := Vector2(meio_x, end.y)
	var p4 := end

	_desenhar_linha_neon(p1, p2, cor, 6.0, 0.72)
	_desenhar_linha_neon(p2, p3, cor, 6.0, 0.72)
	_desenhar_linha_neon(p3, p4, cor, 6.0, 0.72)

	_criar_no_conexao(p1, cor)
	_criar_no_conexao(p4, cor)



func _cor_jogador_dict(j: Dictionary) -> Color:
	if j.has("cor") and j["cor"] is Color:
		return j["cor"]

	var nome: String = str(j.get("nome", "")).to_lower()

	if nome.contains("vermelho") or nome.contains("red"):
		return Color(1.0, 0.15, 0.15)

	if nome.contains("verde") or nome.contains("green"):
		return Color(0.2, 1.0, 0.3)

	if nome.contains("azul") or nome.contains("blue"):
		return Color(0.1, 0.75, 1.0)

	if nome.contains("amarelo") or nome.contains("yellow"):
		return Color(1.0, 0.85, 0.05)

	return COR_NEON


func _montar_coluna_partidas(lista: Array, esperado: int, titulos: Array, cx: float, cy: float, cw: float, ch: float, destaque: bool) -> void:
	var gap: float = 18.0
	var card_h: float = ch

	if esperado > 1:
		card_h = (ch - gap * float(esperado - 1)) / float(esperado)

	for i in range(esperado):
		var p: Dictionary = {}

		if i < lista.size():
			p = lista[i]

		var titulo: String = ""
		if i < titulos.size():
			titulo = str(titulos[i])

		var y: float = cy + float(i) * (card_h + gap)

		var card := _card_partida_knockout(
			p, titulo, Rect2(Vector2(cx, y), Vector2(cw, card_h)), destaque
		)
		ui_root.add_child(card)


func _card_partida_knockout(p: Dictionary, titulo: String, rect: Rect2, destaque: bool) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size

	var vazia: bool = p.is_empty()
	var finalizada: bool = not vazia and bool(p.get("finalizada", false))

	var cor: Color = COR_NEON
	var fundo: Color = Color(0.018, 0.024, 0.035, 0.98)
	var brilho: float = 0.16

	if vazia:
		cor = Color(0.22, 0.26, 0.32)
		fundo = Color(0.014, 0.018, 0.026, 0.92)
		brilho = 0.02
	elif finalizada:
		cor = COR_OK
		fundo = Color(0.016, 0.045, 0.030, 0.97)
		brilho = 0.20
	elif destaque:
		cor = COR_ALERTA
		fundo = Color(0.045, 0.035, 0.012, 0.98)
		brilho = 0.50

	panel.add_theme_stylebox_override("panel", _style_panel(cor, fundo, brilho))

	var W: float = rect.size.x
	var H: float = rect.size.y

	var tl := _label(titulo, 14, Color.WHITE, cor)
	tl.position = Vector2(0, 8)
	tl.size = Vector2(W, 24)
	panel.add_child(tl)

	if vazia:
		var ag := _label("AGUARDANDO", 14, Color(0.45, 0.50, 0.58))
		ag.position = Vector2(0, H / 2.0 - 14)
		ag.size = Vector2(W, 28)
		panel.add_child(ag)
		return panel

	# Lista de jogadores: ranking se finalizada, senão jogadores da partida.
	var lista: Array = []

	if finalizada and p.has("ranking") and (p["ranking"] as Array).size() > 0:
		lista = p["ranking"]
	else:
		lista = p.get("jogadores", [])

	var classificados_nomes: Array[String] = []
	for c in p.get("classificados", []):
		classificados_nomes.append(str(c.get("nome", "")))

	var top_y: float = 38.0
	var disp_h: float = H - top_y - 10.0
	var n: int = max(lista.size(), 1)
	var row_h: float = disp_h / float(n)

	for i in range(lista.size()):
		var j: Dictionary = lista[i]
		var nome: String = str(j.get("nome", "?"))
		var ehboot: bool = bool(j.get("boot", false))
		var classificou: bool = classificados_nomes.has(nome)
		var y: float = top_y + float(i) * row_h

		# Chip da cor.
		var cor_chip: Color = Color(0.5, 0.5, 0.5)
		if j.has("cor") and j["cor"] is Color:
			cor_chip = j["cor"]

		var chip := Panel.new()
		chip.position = Vector2(14, y + row_h / 2.0 - 8)
		chip.size = Vector2(16, 16)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_theme_stylebox_override("panel", _style_chip(cor_chip))
		panel.add_child(chip)

		# Nome (+ gols se finalizada).
		var nome_txt: String = nome
		if ehboot:
			nome_txt += " BOT"
		if finalizada:
			var gols: int = int(j.get("gols", j.get("score", 0)))
			nome_txt += "  (%d)" % gols

		var cor_nome: Color = Color.WHITE
		if classificou:
			cor_nome = COR_OK
		elif ehboot:
			cor_nome = COR_BOOT

		var lbl := _label(nome_txt, 13, cor_nome)
		lbl.position = Vector2(38, y)
		lbl.size = Vector2(W - 64, row_h)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.clip_text = true
		panel.add_child(lbl)

		if classificou:
			var mark := _label("✓", 14, COR_OK)
			mark.position = Vector2(W - 30, y)
			mark.size = Vector2(22, row_h)
			panel.add_child(mark)

	return panel


func _montar_coluna_campeao_moderno(rect: Rect2) -> void:
	var campeao: Dictionary = {}

	var finais: Array = _partidas_da_fase(FASE_FINAL)

	if finais.size() > 0 and bool(finais[0].get("finalizada", false)):
		var rk: Array = finais[0].get("ranking", [])

		if rk.size() > 0:
			campeao = rk[0]

	var tem_campeao: bool = not campeao.is_empty()
	var cor: Color = COR_ALERTA

	if tem_campeao:
		cor = _cor_jogador_dict(campeao)

	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.clip_contents = true

	var fundo: Color = Color(0.052, 0.040, 0.010, 0.98) if tem_campeao else Color(0.014, 0.018, 0.026, 0.94)
	var brilho: float = 0.70 if tem_campeao else 0.08

	panel.add_theme_stylebox_override(
		"panel",
		_style_panel(COR_ALERTA if tem_campeao else Color(0.26, 0.30, 0.38), fundo, brilho)
	)
	ui_root.add_child(panel)

	var W: float = rect.size.x
	var H: float = rect.size.y

	var label_resultado := _label("RESULTADO", int(clampf(H * 0.070, 12.0, 15.0)), Color(0.82, 0.88, 0.96))
	label_resultado.position = Vector2(0, H * 0.05)
	label_resultado.size = Vector2(W, H * 0.12)
	panel.add_child(label_resultado)

	var coroa := _label("👑", int(clampf(H * 0.22, 34.0, 46.0)), Color.WHITE, COR_ALERTA)
	coroa.position = Vector2(0, H * 0.17)
	coroa.size = Vector2(W, H * 0.24)
	panel.add_child(coroa)

	var titulo := _label("GRANDE CAMPEÃO", int(clampf(H * 0.095, 17.0, 22.0)), Color.WHITE, COR_ALERTA)
	titulo.position = Vector2(0, H * 0.40)
	titulo.size = Vector2(W, H * 0.16)
	panel.add_child(titulo)

	if tem_campeao:
		var nome: String = str(campeao.get("nome", "?"))
		var gols: int = int(campeao.get("gols", campeao.get("score", 0)))

		var chip_tam: float = clampf(H * 0.15, 30.0, 40.0)

		var chip := Panel.new()
		chip.position = Vector2(W * 0.5 - chip_tam * 0.5, H * 0.58)
		chip.size = Vector2(chip_tam, chip_tam)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_theme_stylebox_override("panel", _style_chip(cor))
		panel.add_child(chip)

		var nome_lbl := _label(nome, int(clampf(H * 0.078, 15.0, 20.0)), Color.WHITE, cor)
		nome_lbl.position = Vector2(14, H * 0.75)
		nome_lbl.size = Vector2(W - 28, H * 0.13)
		nome_lbl.clip_text = true
		panel.add_child(nome_lbl)

		var gols_lbl := _label("%d GOLS NA FINAL" % gols, int(clampf(H * 0.055, 10.0, 13.0)), Color(0.82, 0.90, 1.0))
		gols_lbl.position = Vector2(0, H * 0.88)
		gols_lbl.size = Vector2(W, H * 0.10)
		panel.add_child(gols_lbl)
	else:
		var indef := _label("A DEFINIR", int(clampf(H * 0.082, 15.0, 18.0)), Color(0.48, 0.54, 0.62))
		indef.position = Vector2(0, H * 0.66)
		indef.size = Vector2(W, H * 0.16)
		panel.add_child(indef)



func _criar_footer(vp: Vector2) -> void:
	var footer_y: float = vp.y - 74.0
	var prox_index: int = _buscar_proxima_partida_pendente()

	var cor: Color = COR_OK if prox_index >= 0 else COR_ALERTA

	var painel := Panel.new()
	painel.position = Vector2((vp.x - 900.0) / 2.0, footer_y)
	painel.size = Vector2(900, 58)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_theme_stylebox_override(
		"panel",
		_style_panel(cor, Color(0.012, 0.018, 0.030, 0.96), 0.42)
	)
	ui_root.add_child(painel)

	var texto: String = ""

	if prox_index >= 0:
		# Existe partida pendente, mas o jogador está olhando uma fase antiga.
		# START primeiro avança a visualização: GRUPOS -> TOP 8 -> SEMI -> fase atual.
		if fase_visualizada != fase_atual:
			var alvo_fase: String = _proxima_fase_acessivel(fase_visualizada)
			texto = "START ▶ AVANÇAR PARA %s          CUP ◀ FASE ANTERIOR" % _nome_fase_footer(alvo_fase)
		else:
			# Já está vendo a fase atual. START inicia a próxima partida.
			var p: Dictionary = partidas[prox_index]
			var fase_p: String = str(p.get("fase", FASE_GRUPOS))
			var nome: String = ""

			if fase_p == FASE_GRUPOS:
				nome = "GRUPO %s • RODADA %d" % [
					str(p.get("grupo", "")),
					int(p.get("rodada", 1))
				]
			elif bool(p.get("disputa_terceiro", false)):
				nome = "DECISÃO DO 3º LUGAR"
			else:
				nome = str(p.get("nome_partida", fase_p))

			texto = "START ▶  INICIAR  %s" % nome
	else:
		# Não existe mais partida pendente.
		if fase_visualizada == FASE_FINAL:
			texto = "START ▶ VER PÓDIO          CUP ◀ FASE ANTERIOR"
		else:
			var proxima: String = _proxima_fase_acessivel(fase_visualizada)

			if proxima != fase_visualizada:
				texto = "START ▶ AVANÇAR PARA %s          CUP ◀ FASE ANTERIOR" % _nome_fase_footer(proxima)
			else:
				texto = "START ▶ VER PÓDIO          CUP ◀ FASE ANTERIOR"

	var lbl := _label(texto, 20, Color.WHITE, cor)
	lbl.position = Vector2.ZERO
	lbl.size = Vector2(900, 58)
	painel.add_child(lbl)



func _criar_card_grupo(g_index: int, tam: Vector2, destaque_grupo: bool = false) -> Panel:
	var grupo: Dictionary = grupos[g_index]
	var jogadores: Array = _jogadores_ordenados(grupo["jogadores"])
	var grupo_encerrado: bool = _grupo_ja_fechou(str(grupo.get("grupo", "")))
	
	var panel := Panel.new()
	panel.size = tam
	var cor_card: Color = COR_ALERTA if destaque_grupo else COR_NEON
	var brilho_card: float = 0.55 if destaque_grupo else 0.18
	var fundo_card: Color = Color(0.050, 0.040, 0.012, 0.98) if destaque_grupo else Color(0.018, 0.024, 0.035, 0.98)

	panel.add_theme_stylebox_override("panel", _style_panel(cor_card, fundo_card, brilho_card))

	# =========================
	# FAIXA SUPERIOR
	# =========================
	var faixa := Panel.new()
	faixa.position = Vector2.ZERO
	faixa.size = Vector2(tam.x, 50)
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faixa.add_theme_stylebox_override("panel", _style_faixa())
	panel.add_child(faixa)

	var titulo := _label("GRUPO %s" % grupo["grupo"], 23, Color.WHITE, COR_NEON)
	titulo.position = Vector2(0, 0)
	titulo.size = Vector2(tam.x, 50)
	panel.add_child(titulo)
	
	if destaque_grupo:
		var jogando := _label("JOGA AGORA", 13, Color(1.0, 0.92, 0.25), COR_ALERTA)
		jogando.position = Vector2(tam.x - 160, 0)
		jogando.size = Vector2(145, 50)
		jogando.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		panel.add_child(jogando)

	# =========================
	# COLUNAS FIXAS
	# =========================
	var margem_x: float = 18.0
	var pos_x: float = 22.0
	var chip_x: float = 70.0
	var nome_x: float = 104.0

	var gols_w: float = 74.0
	var jogos_w: float = 42.0
	var pts_w: float = 58.0
	var gap_stats: float = 12.0

	var gols_x: float = tam.x - margem_x - gols_w
	var jogos_x: float = gols_x - gap_stats - jogos_w
	var pts_x: float = jogos_x - gap_stats - pts_w

	var nome_w: float = pts_x - nome_x - 14.0

	# =========================
	# CABEÇALHO ALINHADO
	# =========================
	var header_y: float = 54.0
	var header_h: float = 28.0

	var h_pos := _label("POS", 12, Color(0.66, 0.73, 0.84))
	h_pos.position = Vector2(pos_x, header_y)
	h_pos.size = Vector2(44, header_h)
	h_pos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(h_pos)

	var h_jogador := _label("JOGADOR", 12, Color(0.66, 0.73, 0.84))
	h_jogador.position = Vector2(nome_x, header_y)
	h_jogador.size = Vector2(nome_w, header_h)
	h_jogador.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel.add_child(h_jogador)

	var h_pts := _label("PTS", 12, Color(0.66, 0.73, 0.84))
	h_pts.position = Vector2(pts_x, header_y)
	h_pts.size = Vector2(pts_w, header_h)
	h_pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(h_pts)

	var h_j := _label("J", 12, Color(0.66, 0.73, 0.84))
	h_j.position = Vector2(jogos_x, header_y)
	h_j.size = Vector2(jogos_w, header_h)
	h_j.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(h_j)

	var h_gols := _label("GOLS", 12, Color(0.66, 0.73, 0.84))
	h_gols.position = Vector2(gols_x, header_y)
	h_gols.size = Vector2(gols_w, header_h)
	h_gols.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(h_gols)

	# Linha sutil abaixo do cabeçalho
	var linha_header := ColorRect.new()
	linha_header.color = Color(1, 1, 1, 0.08)
	linha_header.position = Vector2(18, 84)
	linha_header.size = Vector2(tam.x - 36, 1)
	linha_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(linha_header)

	# =========================
	# LINHAS DOS JOGADORES
	# =========================
	var linha_y: float = 92.0
	var linha_h: float = (tam.y - 104.0) / 4.0

	for i in range(jogadores.size()):
		var j: Dictionary = jogadores[i]
		var classificado: bool = i < 2
		var eliminado: bool = grupo_encerrado and not classificado

		var y_row: float = linha_y + float(i) * linha_h

		var row := Panel.new()
		row.position = Vector2(14, y_row + 3)
		row.size = Vector2(tam.x - 28, linha_h - 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var cor_row: Color = COR_OK if classificado else Color(1, 1, 1, 0.10)
		var bg_row: Color = Color(0.04, 0.07, 0.055, 0.85) if classificado else Color(1, 1, 1, 0.025)
		var brilho_row: float = 0.10 if classificado else 0.0

		if eliminado:
			cor_row = Color(0.24, 0.25, 0.29)
			bg_row = Color(0.018, 0.019, 0.023, 0.96)
			brilho_row = 0.0

		row.add_theme_stylebox_override("panel", _style_panel(cor_row, bg_row, brilho_row))
		panel.add_child(row)

		# POSIÇÃO
		var pos_txt := "%dº" % (i + 1)
		var pos := _label(pos_txt, 16, COR_OK if classificado else Color(0.72, 0.78, 0.88))
		pos.position = Vector2(pos_x, y_row)
		pos.size = Vector2(44, linha_h)
		pos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(pos)

		# CHIP DA COR
		var cor_chip: Color = j["cor"] if j.has("cor") else Color(0.5, 0.5, 0.5)

		var chip := Panel.new()
		chip.position = Vector2(chip_x, y_row + (linha_h - 20.0) / 2.0)
		chip.size = Vector2(20, 20)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_theme_stylebox_override("panel", _style_chip(cor_chip))
		panel.add_child(chip)
		
		if eliminado:
			chip.modulate = Color(0.32, 0.32, 0.32, 0.70)

		# NOME
		var nome_txt: String = str(j.get("nome", "Jogador"))
		if bool(j.get("boot", false)):
			nome_txt += "  BOT"

		var cor_nome_final: Color = Color.WHITE

		if bool(j.get("boot", false)):
			cor_nome_final = COR_BOOT

		if eliminado:
			cor_nome_final = Color(0.46, 0.48, 0.52)

		var nome := _label(nome_txt, 15, cor_nome_final)
		nome.position = Vector2(nome_x, y_row)
		nome.size = Vector2(nome_w, linha_h)
		nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		nome.clip_text = true
		panel.add_child(nome)

		# PONTOS
		var cor_stats: Color = Color(0.86, 0.94, 1.0)

		if eliminado:
			cor_stats = Color(0.46, 0.48, 0.52)

		var pts := _label(str(int(j.get("pontos", 0))), 15, cor_stats)
		pts.position = Vector2(pts_x, y_row)
		pts.size = Vector2(pts_w, linha_h)
		pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(pts)

		var cor_stats_jogos:Color = Color(0.86, 0.94, 1.0)
		if eliminado:
			cor_stats_jogos = Color(0.46, 0.48, 0.52)
		
		# JOGOS
		var jogos := _label(str(int(j.get("jogos", 0))), 15, cor_stats_jogos)
		jogos.position = Vector2(jogos_x, y_row)
		jogos.size = Vector2(jogos_w, linha_h)
		jogos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(jogos)

		# GOLS
		var gols_total: int = int(j.get("gols", j.get("gols_pro", 0)))

		var cor_status_gols:Color = Color(0.86, 0.94, 1.0)
		if eliminado:
			cor_status_gols = Color(0.46, 0.48, 0.52)
			
		var gols := _label(str(gols_total), 15, cor_status_gols)
		gols.position = Vector2(gols_x, y_row)
		gols.size = Vector2(gols_w, linha_h)
		gols.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(gols)

	return panel


func _jogadores_ordenados(jogadores: Array) -> Array:
	var lista: Array = jogadores.duplicate(true)

	lista.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pontos_a: int = int(a.get("pontos", 0))
		var pontos_b: int = int(b.get("pontos", 0))

		if pontos_a != pontos_b:
			return pontos_a > pontos_b

		var gols_a: int = int(a.get("gols", a.get("gols_pro", 0)))
		var gols_b: int = int(b.get("gols", b.get("gols_pro", 0)))

		if gols_a != gols_b:
			return gols_a > gols_b

		var melhor_a: int = int(a.get("melhor_posicao", 99))
		var melhor_b: int = int(b.get("melhor_posicao", 99))

		if melhor_a != melhor_b:
			return melhor_a < melhor_b

		var ultima_a: int = int(a.get("ultima_posicao", 99))
		var ultima_b: int = int(b.get("ultima_posicao", 99))

		if ultima_a != ultima_b:
			return ultima_a < ultima_b

		return str(a.get("nome", "")) < str(b.get("nome", ""))
	)

	return lista



func _texto_status() -> String:
	var pendentes: int = 0

	for p in partidas:
		if not bool(p.get("finalizada", false)):
			pendentes += 1

	var finalizadas: int = partidas.size() - pendentes

	# Aviso quando se está visualizando uma fase diferente da que está em jogo.
	var vendo: String = ""
	if fase_visualizada != fase_atual and fase_atual != FASE_ENCERRADA:
		vendo = "  •  VENDO: %s" % fase_visualizada

	match fase_atual:
		FASE_GRUPOS:
			return "Grupos %d/%d  •  Passam 2 de cada grupo  •  Próxima fase: TOP 8%s" % [
				finalizadas,
				partidas.size(),
				vendo
			]
		FASE_OITAVAS:
			return "TOP 8  •  2 partidas com 4 jogadores  •  Passam 2 de cada%s" % vendo
		FASE_SEMIFINAL:
			return "Semifinal  •  2 partidas de 2 jogadores  •  Vencedores vão para a final%s" % vendo
		FASE_FINAL:
			return "Grande Final  •  2 jogadores  •  Quem vencer é campeão%s" % vendo
		FASE_ENCERRADA:
			return "Copa finalizada  •  Campeão definido  •  Toque nas fases acima para revisar"
		_:
			return "Rodadas %d/%d" % [finalizadas, partidas.size()]


# ============================================================
# PÓDIO FINAL — TOP 3
# ============================================================
func _obter_podio_final() -> Array:
	var nomes_podio: Array[String] = []
	var origem_por_nome: Dictionary = {}

	var partida_final: Dictionary = {}
	var partida_terceiro: Dictionary = {}

	for p_var in _partidas_da_fase(FASE_FINAL):
		if not (p_var is Dictionary):
			continue

		var p: Dictionary = p_var

		if bool(p.get("disputa_terceiro", false)):
			partida_terceiro = p
		else:
			partida_final = p

	if not partida_final.is_empty() and bool(partida_final.get("finalizada", false)):
		var rk_final: Array = partida_final.get("ranking", [])

		if rk_final.size() > 0 and rk_final[0] is Dictionary:
			var n1: String = str(rk_final[0].get("nome", ""))
			if n1 != "":
				nomes_podio.append(n1)
				origem_por_nome[n1] = rk_final[0].duplicate(true)

		if rk_final.size() > 1 and rk_final[1] is Dictionary:
			var n2: String = str(rk_final[1].get("nome", ""))
			if n2 != "":
				nomes_podio.append(n2)
				origem_por_nome[n2] = rk_final[1].duplicate(true)

	if not partida_terceiro.is_empty() and bool(partida_terceiro.get("finalizada", false)):
		var rk_terceiro: Array = partida_terceiro.get("ranking", [])

		if rk_terceiro.size() > 0 and rk_terceiro[0] is Dictionary:
			var n3: String = str(rk_terceiro[0].get("nome", ""))
			if n3 != "":
				nomes_podio.append(n3)
				origem_por_nome[n3] = rk_terceiro[0].duplicate(true)

	var mapa_stats: Dictionary = _mapa_estatisticas_gerais_competicao()
	var podio_final: Array = []

	for i in range(min(3, nomes_podio.size())):
		var nome: String = nomes_podio[i]

		var origem_var: Variant = origem_por_nome.get(nome, {})
		var origem: Dictionary = origem_var if origem_var is Dictionary else {}

		var stat: Dictionary = {}

		if mapa_stats.has(nome) and mapa_stats[nome] is Dictionary:
			stat = mapa_stats[nome].duplicate(true)
		else:
			stat = origem.duplicate(true)

		# Garante nome e posição do pódio.
		stat["nome"] = nome
		stat["podio_pos"] = i + 1
		stat["posicao"] = i + 1

		# Garante cor.
		if not stat.has("cor") and origem.has("cor"):
			stat["cor"] = origem["cor"]

		# Garante boot.
		if not stat.has("boot"):
			stat["boot"] = bool(origem.get("boot", false))

		# Garante grupo.
		if not stat.has("grupo") or str(stat.get("grupo", "")).strip_edges() == "":
			stat["grupo"] = str(origem.get("grupo", ""))

		# Garante fase.
		if not stat.has("fase_nome") or str(stat.get("fase_nome", "")).strip_edges() == "":
			match i:
				0:
					stat["fase_nome"] = "CAMPEÃO"
				1:
					stat["fase_nome"] = "VICE"
				2:
					stat["fase_nome"] = "3º LUGAR"

		# Garante estatísticas acumuladas.
		stat["gols_total"] = int(stat.get("gols_total", origem.get("gols", origem.get("score", 0))))
		stat["jogos_total"] = int(stat.get("jogos_total", origem.get("jogos", 0)))
		stat["vitorias_total"] = int(stat.get("vitorias_total", origem.get("vitorias", 0)))
		stat["pontos_grupo"] = int(stat.get("pontos_grupo", origem.get("pontos", 0)))
		stat["penaltis_total"] = int(stat.get("penaltis_total", origem.get("penaltis", 0)))

		podio_final.append(stat)

	return podio_final


func _mostrar_podio(mostrar_modal_campeao: bool = true) -> void:
	tela_modo = "PODIO"
	podio_hold_start = 0.0
	podio_aguardando_soltar_start = true
	podio_indo_opening = false
	podio_hold_barra = null
	podio_hold_label = null

	_limpar_ui()

	var vp: Vector2 = get_viewport_rect().size
	var podio: Array = _obter_podio_final()

	_criar_back_copa(false, 0.62, 0.070)

	var campeao: Dictionary = {}
	var cor_campeao: Color = COR_ALERTA

	if podio.size() > 0:
		campeao = podio[0]
		cor_campeao = _cor_jogador_dict(campeao)

	var titulo := _label("🏆 PÓDIO DA COPA", 42, Color.WHITE, COR_ALERTA)
	titulo.position = Vector2(0, 30)
	titulo.size = Vector2(vp.x, 72)
	ui_root.add_child(titulo)

	var sub_txt: String = ""
	if podio.size() > 0:
		sub_txt = "CAMPEÃO: %s  •  %d GOLS  •  %d VITÓRIAS" % [
			str(podio[0].get("nome", "")),
			int(podio[0].get("gols_total", podio[0].get("gols", 0))),
			int(podio[0].get("vitorias_total", 0))
		]

	var subt := _label(sub_txt, 22, COR_OK)
	subt.position = Vector2(0, 104)
	subt.size = Vector2(vp.x, 38)
	ui_root.add_child(subt)

	var centro_x: float = vp.x / 2.0
	var ped_w: float = minf(vp.x * 0.18, 280.0)
	var gap: float = ped_w + 60.0
	var base_y: float = vp.y - 110.0

	_criar_pedestal(podio, 1, centro_x - gap, base_y, ped_w, 215.0, 2, COR_PRATA, "PRATA")
	_criar_pedestal(podio, 0, centro_x, base_y, ped_w, 300.0, 1, COR_ALERTA, "OURO")
	_criar_pedestal(podio, 2, centro_x + gap, base_y, ped_w, 165.0, 3, COR_BRONZE, "BRONZE")

	# Sem botão de mouse: o retorno é só segurando o START.
	_criar_hud_hold_podio(vp)

	if podio.size() > 0:
		_iniciar_confetes_campeao(cor_campeao)

		if mostrar_modal_campeao and not modal_campeao_exibido:
			modal_campeao_exibido = true
			_mostrar_modal_campeao_com_contagem(campeao, cor_campeao)


func _mostrar_modal_campeao_com_contagem(campeao: Dictionary, cor_campeao: Color) -> void:
	var vp: Vector2 = get_viewport_rect().size

	var modal_layer := CanvasLayer.new()
	modal_layer.layer = 120
	add_child(modal_layer)

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.004, 0.007, 0.014, 0.92)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_layer.add_child(overlay)

	var confetes_modal: Array = []

	for i in range(95):
		var c := ColorRect.new()
		c.size = Vector2(randf_range(5.0, 12.0), randf_range(9.0, 18.0))
		c.position = Vector2(randf_range(0.0, vp.x), randf_range(-vp.y * 0.45, vp.y * 0.25))
		c.rotation = randf_range(0.0, TAU)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var cor_c: Color = cor_campeao
		var tipo: int = randi_range(0, 4)

		if tipo == 0:
			cor_c = cor_campeao.lightened(0.35)
		elif tipo == 1:
			cor_c = Color.WHITE
		elif tipo == 2:
			cor_c = COR_ALERTA
		elif tipo == 3:
			cor_c = cor_campeao.darkened(0.18)

		c.color = Color(cor_c.r, cor_c.g, cor_c.b, randf_range(0.76, 1.0))
		modal_layer.add_child(c)

		confetes_modal.append({
			"node": c,
			"vel": Vector2(randf_range(-70.0, 70.0), randf_range(120.0, 260.0)),
			"rot": randf_range(-6.0, 6.0),
			"fase": randf_range(0.0, TAU),
			"onda": randf_range(20.0, 62.0)
		})

	var painel_w: float = minf(vp.x * 0.66, 880.0)
	var painel_h: float = minf(vp.y * 0.70, 600.0)

	painel_w = maxf(painel_w, 680.0)
	painel_h = maxf(painel_h, 520.0)

	var painel := Panel.new()
	painel.size = Vector2(painel_w, painel_h)
	painel.position = Vector2(
		(vp.x - painel_w) * 0.5,
		(vp.y - painel_h) * 0.5
	)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_theme_stylebox_override(
		"panel",
		_style_panel(
			cor_campeao,
			Color(cor_campeao.r * 0.070, cor_campeao.g * 0.070, cor_campeao.b * 0.070, 0.985),
			1.0
		)
	)
	modal_layer.add_child(painel)

	var W: float = painel.size.x
	var H: float = painel.size.y

	var brilho_fundo := ColorRect.new()
	brilho_fundo.color = Color(cor_campeao.r, cor_campeao.g, cor_campeao.b, 0.10)
	brilho_fundo.position = Vector2(24, 24)
	brilho_fundo.size = Vector2(W - 48, H - 48)
	brilho_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(brilho_fundo)

	var faixa_top := ColorRect.new()
	faixa_top.color = Color(cor_campeao.r, cor_campeao.g, cor_campeao.b, 0.92)
	faixa_top.position = Vector2(54, 28)
	faixa_top.size = Vector2(W - 108, 5)
	faixa_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(faixa_top)

	var coroa := _label("👑", 64, Color.WHITE, COR_ALERTA)
	coroa.position = Vector2(0, 38)
	coroa.size = Vector2(W, 72)
	painel.add_child(coroa)

	var parabens := _label("PARABÉNS!", 42, Color.WHITE, cor_campeao)
	parabens.position = Vector2(0, 112)
	parabens.size = Vector2(W, 58)
	parabens.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.96))
	parabens.add_theme_constant_override("outline_size", 6)
	painel.add_child(parabens)

	var nome_campeao: String = str(campeao.get("nome", "CAMPEÃO"))

	var nome := _label(nome_campeao, 36, Color.WHITE, cor_campeao)
	nome.position = Vector2(42, 178)
	nome.size = Vector2(W - 84, 58)
	nome.clip_text = true
	nome.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.96))
	nome.add_theme_constant_override("outline_size", 6)
	painel.add_child(nome)

	var subtitulo := _label("VOCÊ É O GRANDE CAMPEÃO DA COPA", 19, Color(0.86, 0.94, 1.0))
	subtitulo.position = Vector2(42, 240)
	subtitulo.size = Vector2(W - 84, 34)
	painel.add_child(subtitulo)

	var chip_tam: float = 58.0

	var chip := Panel.new()
	chip.position = Vector2(W * 0.5 - chip_tam * 0.5, 286)
	chip.size = Vector2(chip_tam, chip_tam)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", _style_chip(cor_campeao))
	painel.add_child(chip)

	var contador := _label("CARREGANDO RESULTADOS EM 5", 20, COR_ALERTA, COR_ALERTA)
	contador.position = Vector2(0, H - 82)
	contador.size = Vector2(W, 36)
	painel.add_child(contador)

	var barra_bg := ColorRect.new()
	barra_bg.color = Color(1, 1, 1, 0.12)
	barra_bg.position = Vector2(80, H - 38)
	barra_bg.size = Vector2(W - 160, 6)
	barra_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(barra_bg)

	var barra := ColorRect.new()
	barra.color = Color(cor_campeao.r, cor_campeao.g, cor_campeao.b, 1.0)
	barra.position = barra_bg.position
	barra.size = barra_bg.size
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(barra)

	var duracao_total: float = 5.0
	var tempo_passado: float = 0.0
	var ultimo_numero: int = 5

	while tempo_passado < duracao_total:
		if not is_instance_valid(modal_layer):
			return

		var delta: float = 0.016
		await get_tree().create_timer(delta).timeout
		tempo_passado += delta

		var restante: float = maxf(0.0, duracao_total - tempo_passado)
		var numero: int = int(ceil(restante))

		if numero != ultimo_numero:
			ultimo_numero = numero
			contador.text = "CARREGANDO RESULTADOS EM %d" % maxi(numero, 1)

		var progresso: float = clampf(restante / duracao_total, 0.0, 1.0)
		barra.size.x = (W - 160) * progresso

		for i in range(confetes_modal.size() - 1, -1, -1):
			var item: Dictionary = confetes_modal[i]
			var node: ColorRect = item.get("node", null)

			if node == null or not is_instance_valid(node):
				confetes_modal.remove_at(i)
				continue

			var vel: Vector2 = item.get("vel", Vector2.ZERO)
			var rot: float = float(item.get("rot", 0.0))
			var fase: float = float(item.get("fase", 0.0))
			var onda: float = float(item.get("onda", 30.0))

			fase += delta * 3.0
			item["fase"] = fase

			node.position.x += (vel.x + sin(fase) * onda) * delta
			node.position.y += vel.y * delta
			node.rotation += rot * delta

			if node.position.y > vp.y + 60.0:
				node.position.y = randf_range(-90.0, -20.0)
				node.position.x = randf_range(0.0, vp.x)

	if is_instance_valid(modal_layer):
		modal_layer.queue_free()


# ============================================================
# SEQUÊNCIA FINAL DA COPA
# 1) Modal do campeão (barra de carregamento)
# 2) Tela de classificação
# 3) Pódio com contador de 21s
# 4) Retorno automático ao opening.tscn
# ============================================================
func _iniciar_sequencia_vitoria() -> void:
	tela_modo = "SEQUENCIA"
	em_sequencia_final = true
	modal_campeao_exibido = true

	var podio: Array = _obter_podio_final()
	var campeao: Dictionary = {}
	var cor_campeao: Color = COR_ALERTA

	if podio.size() > 0:
		campeao = podio[0]
		cor_campeao = _cor_jogador_dict(campeao)

	_limpar_ui()

	# 1) MODAL DO CAMPEÃO + BARRA.
	if not campeao.is_empty():
		await _mostrar_modal_campeao_com_contagem(campeao, cor_campeao)

	if not em_sequencia_final or not is_inside_tree():
		return

	# 2) TABELA GERAL DA COMPETIÇÃO.
	await _mostrar_tabela_geral_sequencia(9.0)

	if not em_sequencia_final or not is_inside_tree():
		return

	# 3) PÓDIO (sem contagem regressiva — volta só segurando START).
	_mostrar_podio_final_com_retorno()



func _mostrar_classificados_sequencia(segundos: float = 6.0) -> void:
	_limpar_ui()

	var vp: Vector2 = get_viewport_rect().size
	
	_criar_back_copa(false, 0.62, 0.070)

	var titulo := _label("🏆 CLASSIFICAÇÃO FINAL DA COPA", 34, Color.WHITE, COR_ALERTA)
	titulo.position = Vector2(0, 30)
	titulo.size = Vector2(vp.x, 70)
	ui_root.add_child(titulo)

	var box_w: float = minf(vp.x - 100.0, 1100.0)
	var box_h: float = vp.y - 240.0
	var box_x: float = (vp.x - box_w) / 2.0
	var box_y: float = 120.0

	var painel := Panel.new()
	painel.position = Vector2(box_x, box_y)
	painel.size = Vector2(box_w, box_h)
	painel.add_theme_stylebox_override(
		"panel",
		_style_panel(COR_ALERTA, Color(0.018, 0.024, 0.035, 0.98), 0.24)
	)
	ui_root.add_child(painel)

	var y: float = 24.0

	for g in grupos:
		var lbl_g := _label("GRUPO %s" % str(g.get("grupo", "")), 22, COR_ALERTA)
		lbl_g.position = Vector2(0, y)
		lbl_g.size = Vector2(box_w, 34)
		painel.add_child(lbl_g)

		y += 42.0

		var ordenados: Array = _jogadores_ordenados(g.get("jogadores", []))

		for i in range(min(2, ordenados.size())):
			var j: Dictionary = ordenados[i]
			var texto: String = "%dº  %s   —   %d pts" % [
				i + 1,
				str(j.get("nome", "?")),
				int(j.get("pontos", 0))
			]

			var lbl := _label(texto, 19, Color.WHITE)
			lbl.position = Vector2(90, y)
			lbl.size = Vector2(box_w - 180, 32)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			painel.add_child(lbl)

			y += 34.0

		y += 18.0

	var aviso := _label("ABRINDO O PÓDIO...", 20, COR_NEON, COR_NEON)
	aviso.position = Vector2(0, vp.y - 92)
	aviso.size = Vector2(vp.x, 36)
	ui_root.add_child(aviso)

	await get_tree().create_timer(segundos).timeout


func _mostrar_podio_final_com_retorno() -> void:
	em_sequencia_final = false

	# Pódio sem repetir o modal de campeão.
	# O retorno agora é só segurando o START (sem contagem regressiva).
	_mostrar_podio(false)

	_tocar_campeao_cup()



func _iniciar_contagem_retorno_final(total: float = 21.0) -> void:
	contagem_retorno_final_ativa = true
	retorno_opening_ativo = true
	contagem_retorno_final_total = total
	contagem_retorno_final_inicio_ms = float(Time.get_ticks_msec())

	_criar_hud_contagem_retorno_final()


func _criar_hud_contagem_retorno_final() -> void:
	if final_timer_layer != null and is_instance_valid(final_timer_layer):
		final_timer_layer.queue_free()

	var vp: Vector2 = get_viewport_rect().size

	final_timer_layer = CanvasLayer.new()
	final_timer_layer.layer = 260
	add_child(final_timer_layer)

	var root_timer := Control.new()
	root_timer.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_timer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	final_timer_layer.add_child(root_timer)

	var box_w: float = 560.0
	var box_h: float = 76.0
	var box_x: float = vp.x - box_w - 34.0
	var box_y: float = vp.y - box_h - 18.0

	var painel := Panel.new()
	painel.position = Vector2(box_x, box_y)
	painel.size = Vector2(box_w, box_h)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_theme_stylebox_override(
		"panel",
		_style_panel(COR_NEON, Color(0.010, 0.016, 0.028, 0.94), 0.52)
	)
	root_timer.add_child(painel)

	final_timer_label = _label("RETORNANDO À TELA INICIAL EM 21", 18, COR_NEON, COR_NEON)
	final_timer_label.position = Vector2(18, 8)
	final_timer_label.size = Vector2(box_w - 36, 34)
	final_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	painel.add_child(final_timer_label)

	var barra_bg := ColorRect.new()
	barra_bg.position = Vector2(24, 52)
	barra_bg.size = Vector2(box_w - 48, 7)
	barra_bg.color = Color(1, 1, 1, 0.12)
	barra_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(barra_bg)

	final_timer_barra_w = barra_bg.size.x

	final_timer_barra = ColorRect.new()
	final_timer_barra.position = barra_bg.position
	final_timer_barra.size = barra_bg.size
	final_timer_barra.color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 1.0)
	final_timer_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(final_timer_barra)


func _processar_contagem_retorno_final() -> void:
	if not contagem_retorno_final_ativa:
		return

	if not retorno_opening_ativo:
		return

	var agora: float = float(Time.get_ticks_msec())
	var passado: float = (agora - contagem_retorno_final_inicio_ms) / 1000.0
	var restante: float = maxf(0.0, contagem_retorno_final_total - passado)
	var numero: int = int(ceil(restante))

	if final_timer_label != null and is_instance_valid(final_timer_label):
		final_timer_label.text = "RETORNANDO À TELA INICIAL EM %d" % maxi(numero, 0)

	if final_timer_barra != null and is_instance_valid(final_timer_barra):
		var frac: float = clampf(restante / contagem_retorno_final_total, 0.0, 1.0)
		final_timer_barra.size.x = final_timer_barra_w * frac

	if restante <= 0.0:
		contagem_retorno_final_ativa = false
		_retornar_opening()


func _parar_contagem_retorno_final() -> void:
	contagem_retorno_final_ativa = false

	if final_timer_layer != null and is_instance_valid(final_timer_layer):
		final_timer_layer.queue_free()

	final_timer_layer = null
	final_timer_label = null
	final_timer_barra = null
	final_timer_barra_w = 0.0



func _retornar_opening() -> void:
	retorno_opening_ativo = false
	em_sequencia_final = false
	contagem_retorno_final_ativa = false

	_parar_contagem_retorno_final()
	_parar_confetes()
	_parar_musica_cup()
	_parar_campeao_cup()
	_fechar_ponte_lobby_leds()

	# Limpa o estado da copa para a próxima começar do zero.
	var cg := get_node_or_null("/root/CupGlobal")

	if cg != null and cg.has_method("resetar_copa"):
		cg.resetar_copa()

	for chave in [
		"copa_grupos",
		"copa_partidas",
		"copa_partida_atual_index",
		"partida_copa_atual",
		"partida_atual_copa_index",
		"resultado_copa_pendente",
		"copa_id_atual",
		"copa_mural_salva_id"
	]:
		if get_tree().has_meta(chave):
			get_tree().remove_meta(chave)

	await get_tree().create_timer(0.18).timeout

	if ResourceLoader.exists(CENA_OPENING):
		get_tree().change_scene_to_file(CENA_OPENING)
	else:
		_mostrar_modal_aviso(
			"Cena opening.tscn não encontrada",
			"Crie a cena:\nres://scenes/opening.tscn"
		)



func _criar_pedestal(
	podio: Array,
	idx: int,
	centro_x: float,
	base_y: float,
	ped_w: float,
	altura: float,
	colocacao: int,
	cor: Color,
	metal: String
) -> void:
	var tem: bool = idx < podio.size() and not (podio[idx] as Dictionary).is_empty()
	var px: float = centro_x - ped_w / 2.0
	var top_y: float = base_y - altura

	# ========================================================
	# CARD DO JOGADOR — AGORA ENQUADRADO ACIMA DO PEDESTAL
	# ========================================================
	var limite_top: float = 150.0
	var card_gap: float = 14.0
	var card_h: float = clampf(top_y - limite_top - card_gap, 92.0, 132.0)
	var card_w: float = ped_w + 84.0
	var card_x: float = centro_x - card_w * 0.5
	var card_y: float = top_y - card_h - card_gap

	if card_y < limite_top:
		card_y = limite_top

	var cor_chip: Color = cor
	var nome: String = "A DEFINIR"
	var gols: int = 0
	var vitorias: int = 0
	var jogos: int = 0
	var pontos: int = 0
	var penaltis: int = 0

	if tem:
		var j: Dictionary = podio[idx]

		nome = str(j.get("nome", "?"))
		gols = int(j.get("gols_total", j.get("gols", j.get("score", 0))))
		vitorias = int(j.get("vitorias_total", j.get("vitorias", 0)))
		jogos = int(j.get("jogos_total", j.get("jogos", 0)))
		pontos = int(j.get("pontos_grupo", j.get("pontos", 0)))
		penaltis = int(j.get("penaltis_total", j.get("penaltis", 0)))

		if j.has("cor") and j["cor"] is Color:
			cor_chip = j["cor"]

	var card := Panel.new()
	card.position = Vector2(card_x, card_y)
	card.size = Vector2(card_w, card_h)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(cor_chip.r * 0.045, cor_chip.g * 0.045, cor_chip.b * 0.045, 0.96)
	card_style.border_color = Color(cor_chip.r, cor_chip.g, cor_chip.b, 0.92)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(20)
	card_style.shadow_color = Color(cor_chip.r, cor_chip.g, cor_chip.b, 0.42)
	card_style.shadow_size = 18
	card_style.shadow_offset = Vector2.ZERO
	card.add_theme_stylebox_override("panel", card_style)
	ui_root.add_child(card)

	var faixa := ColorRect.new()
	faixa.position = Vector2(18, 10)
	faixa.size = Vector2(card_w - 36, 3)
	faixa.color = Color(cor_chip.r, cor_chip.g, cor_chip.b, 0.90)
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(faixa)

	if colocacao == 1:
		var coroa := _label("👑", 34, Color.WHITE, COR_ALERTA)
		coroa.position = Vector2(0, 10)
		coroa.size = Vector2(card_w, 38)
		card.add_child(coroa)

	var chip_tam: float = 32.0
	var chip_y: float = 44.0

	if colocacao == 1:
		chip_y = 48.0
	else:
		chip_y = 34.0

	var chip := Panel.new()
	chip.position = Vector2(22, chip_y)
	chip.size = Vector2(chip_tam, chip_tam)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", _style_chip(cor_chip))
	card.add_child(chip)

	var nome_font: int = 18
	if colocacao == 1:
		nome_font = 20

	var nome_lbl := _label(nome, nome_font, Color.WHITE, cor_chip)
	nome_lbl.position = Vector2(66, chip_y - 4)
	nome_lbl.size = Vector2(card_w - 84, 34)
	nome_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	nome_lbl.clip_text = true
	nome_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	nome_lbl.add_theme_constant_override("outline_size", 4)
	card.add_child(nome_lbl)

	var info_txt: String = "%d GOLS  •  %d JOGOS  •  %d VIT" % [
		gols,
		jogos,
		vitorias
	]

	var info_lbl := _label(info_txt, 13, Color(0.82, 0.92, 1.0))
	info_lbl.position = Vector2(66, chip_y + 30)
	info_lbl.size = Vector2(card_w - 84, 26)
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info_lbl.clip_text = true
	card.add_child(info_lbl)

	# ========================================================
	# PEDESTAL
	# ========================================================
	var ped := Panel.new()
	ped.position = Vector2(px, top_y)
	ped.size = Vector2(ped_w, altura)
	ped.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var brilho: float = 0.65 if colocacao == 1 else 0.30
	ped.add_theme_stylebox_override(
		"panel",
		_style_panel(
			cor,
			Color(cor.r * 0.06, cor.g * 0.06, cor.b * 0.06, 0.98),
			brilho
		)
	)
	ui_root.add_child(ped)

	# Brilho interno do pedestal.
	var glow := ColorRect.new()
	glow.position = Vector2(14, 14)
	glow.size = Vector2(ped_w - 28, altura - 28)
	glow.color = Color(cor.r, cor.g, cor.b, 0.07)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ped.add_child(glow)

	# Número da colocação — subido e mais centralizado.
	var num_font: int = int(clampf(altura * 0.18, 40.0, 72.0))
	var num := _label("%dº" % colocacao, num_font, Color.WHITE, cor)
	num.position = Vector2(0, altura * 0.18)
	num.size = Vector2(ped_w, altura * 0.26)
	num.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	num.add_theme_constant_override("outline_size", 5)
	ped.add_child(num)

	# Texto OURO / PRATA / BRONZE — também subido.
	var metal_lbl := _label(metal, 16, cor, cor)
	metal_lbl.position = Vector2(0, altura * 0.50)
	metal_lbl.size = Vector2(ped_w, 28)
	metal_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	metal_lbl.add_theme_constant_override("outline_size", 3)
	ped.add_child(metal_lbl)

	var resumo := ""

	if tem:
		if colocacao == 1:
			resumo = "CAMPEÃO"
		elif colocacao == 2:
			resumo = "VICE"
		else:
			resumo = "3º LUGAR"
	else:
		resumo = "A DEFINIR"

	var resumo_lbl := _label(resumo, 13, Color(0.82, 0.90, 1.0))
	resumo_lbl.position = Vector2(0, altura * 0.66)
	resumo_lbl.size = Vector2(ped_w, 26)
	ped.add_child(resumo_lbl)
	
	if tem:
		_adicionar_stats_podio_no_pedestal(
			ped,
			ped_w,
			altura,
			gols,
			jogos,
			vitorias,
			pontos,
			penaltis,
			cor
		)



func _adicionar_stats_podio_no_pedestal(
	ped: Panel,
	ped_w: float,
	altura: float,
	gols: int,
	jogos: int,
	vitorias: int,
	pontos: int,
	penaltis: int,
	cor: Color
) -> void:
	if altura >= 230.0:
		var margem: float = 14.0
		var gap: float = 8.0
		var box_w: float = (ped_w - margem * 2.0 - gap) / 2.0
		var box_h: float = 34.0
		var y1: float = altura * 0.76
		var y2: float = y1 + box_h + 7.0

		_criar_mini_stat_podio(ped, "GOLS", str(gols), Vector2(margem, y1), Vector2(box_w, box_h), cor)
		_criar_mini_stat_podio(ped, "JOGOS", str(jogos), Vector2(margem + box_w + gap, y1), Vector2(box_w, box_h), cor)
		_criar_mini_stat_podio(ped, "VIT", str(vitorias), Vector2(margem, y2), Vector2(box_w, box_h), cor)
		_criar_mini_stat_podio(ped, "PTS", str(pontos), Vector2(margem + box_w + gap, y2), Vector2(box_w, box_h), cor)

		if penaltis > 0:
			var pen_lbl := _label("PÊNALTIS: %d" % penaltis, 10, Color(0.86, 0.92, 1.0))
			pen_lbl.position = Vector2(0, altura - 24)
			pen_lbl.size = Vector2(ped_w, 18)
			ped.add_child(pen_lbl)
	else:
		var txt := "GOLS %d  •  JOGOS %d\nVIT %d  •  PTS %d" % [
			gols,
			jogos,
			vitorias,
			pontos
		]

		if penaltis > 0:
			txt += "  •  PÊN %d" % penaltis

		var lbl := _label(txt, 10, Color(0.86, 0.92, 1.0))
		lbl.position = Vector2(8, altura * 0.76)
		lbl.size = Vector2(ped_w - 16, altura * 0.22)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
		lbl.add_theme_constant_override("outline_size", 3)
		ped.add_child(lbl)


func _criar_mini_stat_podio(
	parent: Control,
	titulo: String,
	valor: String,
	pos: Vector2,
	tam: Vector2,
	cor: Color
) -> void:
	var box := Panel.new()
	box.position = pos
	box.size = tam
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var st := StyleBoxFlat.new()
	st.bg_color = Color(cor.r * 0.075, cor.g * 0.075, cor.b * 0.075, 0.88)
	st.border_color = Color(cor.r, cor.g, cor.b, 0.42)
	st.set_border_width_all(1)
	st.set_corner_radius_all(9)
	st.shadow_color = Color(cor.r, cor.g, cor.b, 0.16)
	st.shadow_size = 5
	st.shadow_offset = Vector2.ZERO
	box.add_theme_stylebox_override("panel", st)

	parent.add_child(box)

	var t := _label(titulo, 8, Color(0.68, 0.76, 0.86))
	t.position = Vector2(0, 2)
	t.size = Vector2(tam.x, 12)
	box.add_child(t)

	var v := _label(valor, 14, Color.WHITE, cor)
	v.position = Vector2(0, 13)
	v.size = Vector2(tam.x, 20)
	v.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
	v.add_theme_constant_override("outline_size", 3)
	box.add_child(v)


# ============================================================
# INICIAR PARTIDA
# ============================================================
func _iniciar_partida(index: int) -> void:
	if index < 0 or index >= partidas.size():
		return

	partida_atual_index = index

	var partida: Dictionary = partidas[index]

	var nome_partida: String = str(partida.get("nome_partida", ""))

	if nome_partida == "":
		if str(partida.get("fase", FASE_GRUPOS)) == FASE_GRUPOS:
			nome_partida = "GRUPO %s • RODADA %d" % [
				str(partida.get("grupo", "")),
				int(partida.get("rodada", 1))
			]
		else:
			nome_partida = str(partida.get("fase", ""))

	var fase_partida: String = str(partida.get("fase", FASE_GRUPOS))
	var disputa_terceiro: bool = bool(partida.get("disputa_terceiro", false))

	var permite_desempate_em_campo: bool = false

	if fase_partida == FASE_SEMIFINAL:
		permite_desempate_em_campo = true
	elif fase_partida == FASE_FINAL:
		permite_desempate_em_campo = true

	var dados_partida := {
		"partida_index": index,
		"fase": fase_partida,
		"grupo_index": int(partida.get("grupo_index", -1)),
		"grupo": str(partida.get("grupo", "")),
		"rodada": int(partida.get("rodada", 1)),
		"nome_partida": nome_partida,
		"jogadores": partida["jogadores"],
		"disputa_terceiro": disputa_terceiro,
		"permite_prorrogacao_penaltis": permite_desempate_em_campo
	}

	var cg := get_node_or_null("/root/CupGlobal")

	if cg != null:
		cg.configurar_partida_atual(dados_partida, index, grupos, partidas)

	get_tree().set_meta("partida_copa_atual", dados_partida)
	get_tree().set_meta("partida_atual_copa_index", index)
	get_tree().set_meta("copa_grupos", grupos)
	get_tree().set_meta("copa_partidas", partidas)

	if ResourceLoader.exists(CENA_CUP_PLAY):
		_parar_musica_cup()
		_fechar_ponte_lobby_leds()

		# A tela de DESTINO (cup_play) é a dona do loading.
		# Aqui só cobrimos para não piscar cinza na troca.
		_cobrir_tela_para_transicao()
		await get_tree().process_frame

		get_tree().change_scene_to_file(CENA_CUP_PLAY)
	else:
		_mostrar_modal_aviso("Cena cup_play.tscn não encontrada", "Crie a cena:\nres://scenes/cup_play.tscn")



func _texto_placar_agregado_lobby(item: Dictionary) -> String:
	var total: int = int(item.get("gols", item.get("score", 0)))
	var normais: int = int(item.get("gols_normais", total))
	var prorro: int = int(item.get("gols_prorrogacao", 0))
	var pen: int = int(item.get("penaltis", 0))

	var texto: String = str(total)

	if bool(item.get("jogou_prorrogacao", false)):
		texto = "%d+%d" % [normais, prorro]

	if bool(item.get("jogou_penaltis", false)):
		texto += "  P%d" % pen

	return texto


func _rebalancear_grupos_reais() -> void:
	# Se veio do cup_setup confirmado, NÃO sorteia de novo.
	if get_tree().has_meta("copa_grupos_confirmados_setup"):
		if bool(get_tree().get_meta("copa_grupos_confirmados_setup")):
			print("LOBBY: grupos já confirmados pelo setup. Rebalanceamento ignorado.")
			return

	if get_tree().has_meta("copa_sorteio_origem"):
		if str(get_tree().get_meta("copa_sorteio_origem")) == "cup_setup":
			print("LOBBY: sorteio veio do cup_setup. Rebalanceamento ignorado.")
			return

	if grupos.size() != NUM_GRUPOS:
		return

	# Se já existe partida salva ou finalizada, não mexe mais nos grupos.
	if not partidas.is_empty():
		return

	var cg := get_node_or_null("/root/CupGlobal")

	if cg != null:
		if cg.partidas_copa is Array and cg.partidas_copa.size() > 0:
			return

	if get_tree().has_meta("copa_partidas"):
		var p_meta: Variant = get_tree().get_meta("copa_partidas")
		if p_meta is Array and p_meta.size() > 0:
			return

	var todos_reais: Array = []
	var todos_bots: Array = []

	for g in grupos:
		if not g.has("jogadores"):
			continue

		for j in g["jogadores"]:
			if bool(j.get("boot", false)):
				todos_bots.append(j)
			else:
				todos_reais.append(j)

	todos_reais.shuffle()
	todos_bots.shuffle()

	var novos_grupos: Array = []

	for i in range(NUM_GRUPOS):
		novos_grupos.append({
			"grupo": LETRAS_GRUPO[i],
			"jogadores": []
		})

	var gi: int = 0

	for jogador_real in todos_reais:
		var jogadores_do_grupo: Array = novos_grupos[gi]["jogadores"]

		if jogadores_do_grupo.size() < JOGADORES_POR_GRUPO:
			jogadores_do_grupo.append(jogador_real)

		gi += 1
		if gi >= NUM_GRUPOS:
			gi = 0

	for i in range(NUM_GRUPOS):
		var jogadores_do_grupo: Array = novos_grupos[i]["jogadores"]

		while jogadores_do_grupo.size() < JOGADORES_POR_GRUPO and not todos_bots.is_empty():
			jogadores_do_grupo.append(todos_bots.pop_front())

	var boot_id: int = 1

	for i in range(NUM_GRUPOS):
		var jogadores_do_grupo: Array = novos_grupos[i]["jogadores"]

		while jogadores_do_grupo.size() < JOGADORES_POR_GRUPO:
			jogadores_do_grupo.append({
				"nome": "Boot Extra %d" % boot_id,
				"cor_index": jogadores_do_grupo.size(),
				"cor": Color(0.5, 0.55, 0.65),
				"cor_nome": "BOT",
				"boot": true,
				"pontos": 0,
				"jogos": 0,
				"gols": 0,
				"gols_pro": 0,
				"melhor_posicao": 99,
				"ultima_posicao": 99,
				"vitorias": 0,
				"empates": 0,
				"derrotas": 0,
				"saldo": 0,
				"gols_contra": 0
			})

			boot_id += 1

	grupos = novos_grupos
	_garantir_estatisticas()
	_salvar_estado_copa()

	print("================================")
	print("LOBBY: GRUPOS REBALANCEADOS APENAS COMO FALLBACK")
	print("================================")


# ============================================================
# RECEBER RESULTADO DA PARTIDA
# Essa função será chamada quando voltar do cup_play,
# ou você pode usar a mesma lógica no _ready lendo meta.
# ============================================================
func registrar_resultado_partida(partida_index: int, ranking_recebido: Array) -> void:
	if partida_index < 0 or partida_index >= partidas.size():
		return

	if ranking_recebido.is_empty():
		return

	var p: Dictionary = partidas[partida_index]

	if bool(p.get("finalizada", false)):
		return

	var fase_partida: String = str(p.get("fase", FASE_GRUPOS))

	# Normaliza o ranking no lobby usando a mesma regra do cup_play.
	# Assim TOP 8, SEMI, FINAL e 3º lugar ficam com o mesmo critério.
	var ranking_final: Array = _normalizar_ranking_lobby(fase_partida, ranking_recebido)

	p["ranking"] = ranking_final.duplicate(true)
	p["finalizada"] = true
	p["classificados"] = _extrair_classificados_da_partida(fase_partida, ranking_final)

	if fase_partida == FASE_GRUPOS:
		_registrar_resultado_grupo(p, ranking_final)

	partidas[partida_index] = p

	_salvar_estado_copa()

	_auto_resolver_partidas_so_boots()

	if fase_partida == FASE_GRUPOS and _fase_totalmente_finalizada(FASE_GRUPOS):
		_criar_oitavas()
		fase_visualizada = FASE_OITAVAS

	elif fase_partida == FASE_OITAVAS and _fase_totalmente_finalizada(FASE_OITAVAS):
		_criar_semifinal()
		fase_visualizada = FASE_SEMIFINAL

	elif fase_partida == FASE_SEMIFINAL and _fase_totalmente_finalizada(FASE_SEMIFINAL):
		_criar_final()
		fase_visualizada = FASE_FINAL

	elif fase_partida == FASE_FINAL and _fase_totalmente_finalizada(FASE_FINAL):
		_finalizar_copa()
		fase_visualizada = FASE_FINAL

	else:
		fase_visualizada = _fase_visualizavel_padrao()

	_atualizar_fase_atual()
	_salvar_estado_copa()

	if fase_atual == FASE_ENCERRADA:
		_iniciar_sequencia_vitoria()
	else:
		_montar_tela_lobby()



# ============================================================
# AUTO RESOLVER PARTIDAS SÓ DE BOT
# Evita assistir partidas onde não existe jogador real.
# Funciona em GRUPOS, TOP 8, SEMIFINAL e FINAL.
# ============================================================
func _auto_resolver_partidas_so_boots() -> void:
	var mudou: bool = true
	var seguranca: int = 0

	while mudou and seguranca < 20:
		seguranca += 1
		mudou = false

		for i in range(partidas.size()):
			var p: Dictionary = partidas[i]

			if bool(p.get("finalizada", false)):
				continue

			if not _partida_tem_so_boots(p):
				continue

			var fase_partida: String = str(p.get("fase", FASE_GRUPOS))
			var rodada: int = int(p.get("rodada", 1))
			var jogadores: Array = p.get("jogadores", [])

			var ranking_auto: Array = _criar_ranking_automatico_boots(jogadores, rodada)
			ranking_auto = _normalizar_ranking_lobby(fase_partida, ranking_auto)

			p["ranking"] = ranking_auto.duplicate(true)
			p["finalizada"] = true
			p["classificados"] = _extrair_classificados_da_partida(fase_partida, ranking_auto)

			partidas[i] = p

			if fase_partida == FASE_GRUPOS:
				_registrar_resultado_grupo(p, ranking_auto)

			mudou = true

			print("AUTO BOT RESOLVIDO: ", str(p.get("nome_partida", p.get("grupo", "PARTIDA"))))

		if mudou:
			_salvar_estado_copa()

			if _fase_totalmente_finalizada(FASE_GRUPOS):
				_criar_oitavas()
				fase_visualizada = FASE_OITAVAS

			if _fase_totalmente_finalizada(FASE_OITAVAS):
				_criar_semifinal()
				fase_visualizada = FASE_SEMIFINAL

			if _fase_totalmente_finalizada(FASE_SEMIFINAL):
				_criar_final()
				fase_visualizada = FASE_FINAL

			if _fase_totalmente_finalizada(FASE_FINAL):
				_finalizar_copa()
				fase_visualizada = FASE_FINAL

			_atualizar_fase_atual()
			_salvar_estado_copa()


func _partida_tem_so_boots(p: Dictionary) -> bool:
	if p.is_empty():
		return false

	if not p.has("jogadores"):
		return false

	var jogadores: Array = p.get("jogadores", [])

	if jogadores.is_empty():
		return false

	for j in jogadores:
		if not bool(j.get("boot", false)):
			return false

	return true


func _criar_ranking_automatico_boots(jogadores: Array, rodada: int = 1) -> Array:
	var lista: Array = jogadores.duplicate(true)

	# Ordem estável por nome para não ficar aleatório demais.
	lista.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("nome", "")) < str(b.get("nome", ""))
	)

	# Na rodada 2, gira a ordem para não ficar sempre exatamente igual.
	if rodada % 2 == 0 and lista.size() > 1:
		var primeiro: Dictionary = lista.pop_front()
		lista.append(primeiro)

	var ranking: Array = []

	for i in range(lista.size()):
		var item: Dictionary = lista[i].duplicate(true)
		var posicao: int = i + 1

		var gols_auto: int = maxi(lista.size() - i, 1)

		item["posicao"] = posicao
		item["gols"] = gols_auto
		item["score"] = gols_auto
		item["pontos_tabela"] = _pontos_por_posicao(posicao)

		ranking.append(item)

	return ranking



func _registrar_resultado_grupo(p: Dictionary, ranking_recebido: Array) -> void:
	var g_index: int = int(p["grupo_index"])

	if g_index < 0 or g_index >= grupos.size():
		return

	var jogadores_grupo: Array = grupos[g_index]["jogadores"]

	for item in ranking_recebido:
		var nome_resultado: String = str(item.get("nome", ""))
		var gols_rodada: int = int(item.get("gols", item.get("score", 0)))
		var posicao: int = int(item.get("posicao", 99))
		var pontos_tabela: int = int(item.get("pontos_tabela", _pontos_por_posicao(posicao)))

		for idx in range(jogadores_grupo.size()):
			var j: Dictionary = jogadores_grupo[idx]

			if str(j.get("nome", "")) != nome_resultado:
				continue

			j["jogos"] = int(j.get("jogos", 0)) + 1
			j["gols"] = int(j.get("gols", j.get("gols_pro", 0))) + gols_rodada
			j["gols_pro"] = int(j["gols"])
			j["saldo"] = int(j["gols"])
			j["pontos"] = int(j.get("pontos", 0)) + pontos_tabela
			j["ultima_posicao"] = posicao

			var melhor_atual: int = int(j.get("melhor_posicao", 99))
			if posicao < melhor_atual:
				j["melhor_posicao"] = posicao

			if posicao <= 2:
				j["vitorias"] = int(j.get("vitorias", 0)) + 1
			else:
				j["derrotas"] = int(j.get("derrotas", 0)) + 1

			jogadores_grupo[idx] = j
			break

	grupos[g_index]["jogadores"] = jogadores_grupo



func _extrair_classificados_da_partida(fase: String, ranking_recebido: Array) -> Array:
	var classificados: Array = []
	var ranking: Array = _normalizar_ranking_lobby(fase, ranking_recebido)

	var qtd_passa: int = 1

	if fase == FASE_GRUPOS:
		qtd_passa = 0
	elif fase == FASE_OITAVAS:
		qtd_passa = 2
	elif fase == FASE_SEMIFINAL:
		qtd_passa = 1
	elif fase == FASE_FINAL:
		qtd_passa = 1

	for i in range(min(qtd_passa, ranking.size())):
		var nome: String = str(ranking[i].get("nome", ""))
		var jogador: Dictionary = _buscar_jogador_por_nome(nome)

		if not jogador.is_empty():
			var jogador_classificado: Dictionary = jogador.duplicate(true)

			# Mantém também os dados do resultado da partida.
			jogador_classificado["gols"] = int(ranking[i].get("gols", ranking[i].get("score", 0)))
			jogador_classificado["score"] = int(ranking[i].get("score", ranking[i].get("gols", 0)))
			jogador_classificado["gols_normais"] = int(ranking[i].get("gols_normais", jogador_classificado["gols"]))
			jogador_classificado["gols_prorrogacao"] = int(ranking[i].get("gols_prorrogacao", 0))
			jogador_classificado["penaltis"] = int(ranking[i].get("penaltis", 0))
			jogador_classificado["jogou_prorrogacao"] = bool(ranking[i].get("jogou_prorrogacao", false))
			jogador_classificado["jogou_penaltis"] = bool(ranking[i].get("jogou_penaltis", false))
			jogador_classificado["posicao"] = int(ranking[i].get("posicao", i + 1))

			classificados.append(jogador_classificado)

	return classificados



func _buscar_jogador_por_nome(nome: String) -> Dictionary:
	for g in grupos:
		if not g.has("jogadores"):
			continue

		for j in g["jogadores"]:
			if str(j.get("nome", "")) == nome:
				return j

	for p in partidas:
		if not p.has("jogadores"):
			continue

		for j in p["jogadores"]:
			if str(j.get("nome", "")) == nome:
				return j

	return {}


func _obter_classificados_grupos() -> Array:
	var classificados: Array = []

	for g in grupos:
		var ordenados: Array = _jogadores_ordenados(g["jogadores"])

		for i in range(min(2, ordenados.size())):
			classificados.append(ordenados[i].duplicate(true))

	return classificados


func _criar_oitavas() -> void:
	for p in partidas:
		if str(p.get("fase", "")) == FASE_OITAVAS:
			return

	var classificados: Array = _obter_classificados_grupos()

	if classificados.size() < 8:
		push_warning("Não há 8 classificados para criar as oitavas.")
		return

	# Cruzamento equilibrado:
	# Jogo 1: A1, B2, C1, D2
	# Jogo 2: B1, A2, D1, C2
	var por_grupo: Dictionary = {}

	for g in grupos:
		var letra: String = str(g.get("grupo", ""))
		var ordenados: Array = _jogadores_ordenados(g["jogadores"])
		por_grupo[letra] = ordenados

	var jogo_1: Array = [
		por_grupo["A"][0],
		por_grupo["B"][1],
		por_grupo["C"][0],
		por_grupo["D"][1]
	]

	var jogo_2: Array = [
		por_grupo["B"][0],
		por_grupo["A"][1],
		por_grupo["D"][0],
		por_grupo["C"][1]
	]

	partidas.append({
		"fase": FASE_OITAVAS,
		"grupo_index": -1,
		"grupo": "TOP 8",
		"rodada": 1,
		"jogadores": jogo_1.duplicate(true),
		"finalizada": false,
		"ranking": [],
		"classificados": [],
		"nome_partida": "TOP 8 • JOGO 1"
	})

	partidas.append({
		"fase": FASE_OITAVAS,
		"grupo_index": -1,
		"grupo": "TOP 8",
		"rodada": 2,
		"jogadores": jogo_2.duplicate(true),
		"finalizada": false,
		"ranking": [],
		"classificados": [],
		"nome_partida": "TOP 8 • JOGO 2"
	})

	fase_atual = FASE_OITAVAS
	_salvar_estado_copa()

	print("OITAVAS / TOP 8 CRIADAS")


func _criar_semifinal() -> void:
	for p in partidas:
		if str(p.get("fase", "")) == FASE_SEMIFINAL:
			return

	var classificados: Array = []

	for p in partidas:
		if str(p.get("fase", "")) == FASE_OITAVAS:
			if p.has("classificados"):
				for j in p["classificados"]:
					classificados.append(j)

	if classificados.size() < 4:
		push_warning("Não há 4 classificados para criar semifinal.")
		return

	var semi_1: Array = [
		classificados[0],
		classificados[3]
	]

	var semi_2: Array = [
		classificados[1],
		classificados[2]
	]

	partidas.append({
		"fase": FASE_SEMIFINAL,
		"grupo_index": -1,
		"grupo": "SEMI",
		"rodada": 1,
		"jogadores": semi_1.duplicate(true),
		"finalizada": false,
		"ranking": [],
		"classificados": [],
		"nome_partida": "SEMIFINAL 1"
	})

	partidas.append({
		"fase": FASE_SEMIFINAL,
		"grupo_index": -1,
		"grupo": "SEMI",
		"rodada": 2,
		"jogadores": semi_2.duplicate(true),
		"finalizada": false,
		"ranking": [],
		"classificados": [],
		"nome_partida": "SEMIFINAL 2"
	})

	fase_atual = FASE_SEMIFINAL
	_salvar_estado_copa()

	print("SEMIFINAL CRIADA")


func _criar_final() -> void:
	for p in partidas:
		if str(p.get("fase", "")) == FASE_FINAL:
			return

	var finalistas: Array = []
	var disputa_terceiro: Array = []

	for p in partidas:
		if str(p.get("fase", "")) != FASE_SEMIFINAL:
			continue

		if not bool(p.get("finalizada", false)):
			continue

		var rk: Array = p.get("ranking", [])

		if rk.size() > 0:
			finalistas.append(rk[0].duplicate(true))

		if rk.size() > 1:
			disputa_terceiro.append(rk[1].duplicate(true))

	if finalistas.size() < 2:
		push_warning("Não há 2 finalistas para criar final.")
		return

	partidas.append({
		"fase": FASE_FINAL,
		"grupo_index": -1,
		"grupo": "FINAL",
		"rodada": 1,
		"jogadores": finalistas.duplicate(true),
		"finalizada": false,
		"ranking": [],
		"classificados": [],
		"nome_partida": "GRANDE FINAL",
		"disputa_terceiro": false
	})

	if disputa_terceiro.size() >= 2:
		partidas.append({
			"fase": FASE_FINAL,
			"grupo_index": -1,
			"grupo": "3_LUGAR",
			"rodada": 2,
			"jogadores": disputa_terceiro.duplicate(true),
			"finalizada": false,
			"ranking": [],
			"classificados": [],
			"nome_partida": "DECISÃO DO 3º LUGAR",
			"disputa_terceiro": true
		})

	fase_atual = FASE_FINAL
	_salvar_estado_copa()

	print("FINAL E DECISÃO DO 3º LUGAR CRIADAS")


func _finalizar_copa() -> void:
	fase_atual = FASE_ENCERRADA

	var campeao: Dictionary = {}

	for p in partidas:
		if str(p.get("fase", "")) != FASE_FINAL:
			continue

		if bool(p.get("disputa_terceiro", false)):
			continue

		if p.has("classificados") and p["classificados"].size() > 0:
			campeao = p["classificados"][0]
			break

	if not campeao.is_empty():
		print("================================")
		print("CAMPEÃO DA COPA: ", campeao.get("nome", ""))
		print("================================")

	# Salva uma única vez no ChampionsDb.
	_registrar_copa_no_mural()

	_salvar_estado_copa()


func _pontos_por_posicao(posicao: int) -> int:
	match posicao:
		1:
			return 3
		2:
			return 2
		3:
			return 1
		_:
			return 0


# ============================================================
# CLASSIFICADOS (visão simples dos grupos, mantida como apoio)
# ============================================================
func _mostrar_classificados() -> void:
	_limpar_ui()

	var vp: Vector2 = get_viewport_rect().size

	var titulo := _label("🏆 CLASSIFICADOS PARA A PRÓXIMA FASE", 34, Color.WHITE, COR_ALERTA)
	titulo.position = Vector2(0, 30)
	titulo.size = Vector2(vp.x, 70)
	ui_root.add_child(titulo)

	var box_w: float = minf(vp.x - 100.0, 1100.0)
	var box_h: float = vp.y - 190.0
	var box_x: float = (vp.x - box_w) / 2.0
	var box_y: float = 120.0

	var painel := Panel.new()
	painel.position = Vector2(box_x, box_y)
	painel.size = Vector2(box_w, box_h)
	painel.add_theme_stylebox_override("panel", _style_panel(COR_ALERTA, Color(0.018, 0.024, 0.035, 0.98), 0.24))
	ui_root.add_child(painel)

	var y: float = 24.0

	for g in grupos:
		var lbl_g := _label("GRUPO %s" % g["grupo"], 22, COR_ALERTA)
		lbl_g.position = Vector2(0, y)
		lbl_g.size = Vector2(box_w, 34)
		painel.add_child(lbl_g)

		y += 42.0

		var ordenados: Array = _jogadores_ordenados(g["jogadores"])

		for i in range(2):
			var j: Dictionary = ordenados[i]
			var texto := "%dº  %s   —   %d pts" % [i + 1, j["nome"], int(j["pontos"])]

			var lbl := _label(texto, 19, Color.WHITE)
			lbl.position = Vector2(90, y)
			lbl.size = Vector2(box_w - 180, 32)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			painel.add_child(lbl)

			y += 34.0

		y += 18.0

	var btn_voltar := _botao_neon("◀ VOLTAR AO LOBBY", Vector2(44, vp.y - 76), Vector2(320, 56), COR_NEON)
	btn_voltar.pressed.connect(_montar_tela_lobby)
	ui_root.add_child(btn_voltar)


# ============================================================
# NAVEGAÇÃO / INPUT
# ============================================================
func _voltar_setup() -> void:
	_mostrar_modal_aviso(
		"Copa já iniciada",
		"Depois que os grupos foram sorteados, não é possível voltar sem reiniciar a Copa."
	)



func _input(event: InputEvent) -> void:
	# Atalhos de sistema (fechar / bloquear).
	if event is InputEventKey and event.pressed and not event.echo:
		var vp_key := get_viewport()

		if event.ctrl_pressed and event.keycode == KEY_TAB:
			if vp_key:
				vp_key.set_input_as_handled()
			_fechar_programa()
			return

		if event.keycode == KEY_ESCAPE:
			if vp_key:
				vp_key.set_input_as_handled()
			return

		if event.alt_pressed and event.keycode in [KEY_F4, KEY_TAB]:
			if vp_key:
				vp_key.set_input_as_handled()
			return

	# Navegação por START / CUP — somente no lobby.
	# (No pódio, o START é tratado como "segurar" lá no _process.)
	if tela_modo != "LOBBY":
		return

	if em_sequencia_final:
		return

	if InputMap.has_action("input_start") and event.is_action_pressed("input_start"):
		get_viewport().set_input_as_handled()
		_on_start_lobby()
		return

	if InputMap.has_action("input_cup") and event.is_action_pressed("input_cup"):
		get_viewport().set_input_as_handled()
		_on_cup_lobby()
		return



func _fechar_programa() -> void:
	print("CUP LOBBY: ENCERRANDO COM CTRL + TAB")
	retorno_opening_ativo = false
	em_sequencia_final = false
	_parar_musica_cup()
	_fechar_ponte_lobby_leds()
	get_tree().quit()


func _exit_tree() -> void:
	retorno_opening_ativo = false
	em_sequencia_final = false
	contagem_retorno_final_ativa = false

	_parar_contagem_retorno_final()
	_parar_musica_cup()
	_parar_campeao_cup()
	_fechar_ponte_lobby_leds()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST]:
		return


# ============================================================
# BASE VISUAL
# ============================================================
func _travar_arcade() -> void:
	RenderingServer.set_default_clear_color(Color(0.004, 0.007, 0.014, 1.0))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _carregar_fontes() -> void:
	if ResourceLoader.exists(FONTE_ORBITRON):
		fonte_orbitron = load(FONTE_ORBITRON)


func _criar_fundo() -> void:
	var cl := CanvasLayer.new()
	cl.layer = -10
	add_child(cl)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.010, 0.014, 0.022, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(bg)

	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.color = Color(0.12, 0.58, 1.0, 0.035)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(glow)


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
	anel.add_theme_stylebox_override("panel", _style_mira())
	ponteiro.add_child(anel)

	var dot := Panel.new()
	dot.size = Vector2(8, 8)
	dot.position = Vector2(-4, -4)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sd := StyleBoxFlat.new()
	sd.bg_color = Color.WHITE
	sd.set_corner_radius_all(4)
	sd.shadow_color = Color(0.20, 1.0, 0.85, 0.8)
	sd.shadow_size = 6
	dot.add_theme_stylebox_override("panel", sd)
	ponteiro.add_child(dot)
	
	_set_mouse_arcade_visivel(false)


func _limpar_ui() -> void:
	if ui_root:
		for c in ui_root.get_children():
			ui_root.remove_child(c)
			c.queue_free()



func _criar_back_copa(abaixo_cabecalho: bool = true, escurecer: float = 0.56, brilho_azul: float = 0.055) -> void:
	if ui_root == null:
		return

	var vp: Vector2 = get_viewport_rect().size

	# Começa abaixo do cabeçalho quando for tela de lobby.
	var y_inicio: float = 86.0 if abaixo_cabecalho else 0.0
	var altura: float = vp.y - y_inicio

	if altura <= 0.0:
		return

	# Base escura atrás da imagem.
	var bg_base := ColorRect.new()
	bg_base.position = Vector2(0, y_inicio)
	bg_base.size = Vector2(vp.x, altura)
	bg_base.color = Color(0.006, 0.010, 0.018, 1.0)
	bg_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(bg_base)

	if ResourceLoader.exists(IMAGEM_BACK_COPA):
		var img := TextureRect.new()
		img.position = Vector2(0, y_inicio)
		img.size = Vector2(vp.x, altura)
		img.texture = load(IMAGEM_BACK_COPA)

		# IMPORTANTE:
		# STRETCH_SCALE mostra a imagem completa, sem zoom e sem corte,
		# preenchendo toda a área abaixo do cabeçalho.
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_SCALE

		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui_root.add_child(img)
	else:
		push_warning("Imagem de fundo da Copa não encontrada: " + IMAGEM_BACK_COPA)

	# Camada escura para as informações ficarem legíveis.
	var escuro := ColorRect.new()
	escuro.position = Vector2(0, y_inicio)
	escuro.size = Vector2(vp.x, altura)
	escuro.color = Color(0, 0, 0, escurecer)
	escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(escuro)

	# Brilho azul leve para combinar com o neon.
	var glow := ColorRect.new()
	glow.position = Vector2(0, y_inicio)
	glow.size = Vector2(vp.x, altura)
	glow.color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, brilho_azul)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(glow)

	# Vinheta superior suave abaixo do cabeçalho.
	var sombra_top := ColorRect.new()
	sombra_top.position = Vector2(0, y_inicio)
	sombra_top.size = Vector2(vp.x, 70)
	sombra_top.color = Color(0, 0, 0, 0.30)
	sombra_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(sombra_top)



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


func _botao_neon(txt: String, pos: Vector2, tam: Vector2, cor: Color) -> Button:
	var b := Button.new()
	b.text = txt
	b.position = pos
	b.size = tam
	b.custom_minimum_size = tam

	if fonte_orbitron:
		b.add_theme_font_override("font", fonte_orbitron)

	b.add_theme_font_size_override("font_size", int(clamp(tam.y * 0.35, 15, 28)))
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", cor)
	b.add_theme_stylebox_override("normal", _style_botao(cor, 0.24))
	b.add_theme_stylebox_override("hover", _style_botao(cor, 0.50))
	b.add_theme_stylebox_override("pressed", _style_botao(cor, 0.78))
	b.add_theme_stylebox_override("focus", _style_botao(cor, 0.50))

	return b


func _style_botao(cor: Color, intensidade: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(cor.r * 0.10, cor.g * 0.10, cor.b * 0.10, 0.93)
	s.border_color = cor
	s.set_border_width_all(2)
	s.set_corner_radius_all(15)
	s.shadow_color = Color(cor.r, cor.g, cor.b, intensidade)
	s.shadow_size = 12
	s.shadow_offset = Vector2.ZERO
	return s


# StyleBox transparente para botões invisíveis sobre os cards de fase.
func _style_transparente(alpha: float = 0.0, cor: Color = Color.WHITE) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(cor.r, cor.g, cor.b, alpha)
	s.set_corner_radius_all(14)
	s.set_border_width_all(0)
	s.shadow_size = 0
	return s


func _style_panel(cor_borda: Color, cor_fundo: Color, brilho: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = cor_fundo
	s.border_color = Color(cor_borda.r, cor_borda.g, cor_borda.b, maxf(cor_borda.a, 0.18))
	s.set_border_width_all(2)
	s.set_corner_radius_all(22)
	s.shadow_color = Color(cor_borda.r, cor_borda.g, cor_borda.b, brilho)
	s.shadow_size = 18
	s.shadow_offset = Vector2.ZERO
	return s


func _style_faixa() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.035, 0.045, 0.065, 0.96)
	s.set_border_width_all(0)
	s.set_corner_radius_all(0)
	s.corner_radius_top_left = 20
	s.corner_radius_top_right = 20
	return s


func _style_chip(cor: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = cor
	s.border_color = Color(1, 1, 1, 0.75)
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	s.shadow_color = Color(cor.r, cor.g, cor.b, 0.55)
	s.shadow_size = 8
	s.shadow_offset = Vector2.ZERO
	return s


func _style_mira() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.border_color = Color(0.20, 1.0, 0.85, 0.95)
	s.set_border_width_all(3)
	s.set_corner_radius_all(17)
	s.shadow_color = Color(0.20, 1.0, 0.85, 0.55)
	s.shadow_size = 10
	s.shadow_offset = Vector2.ZERO
	return s


func _mostrar_modal_aviso(titulo_txt: String, msg_txt: String) -> void:
	var vp: Vector2 = get_viewport_rect().size

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.72)
	ui_root.add_child(overlay)

	var painel := Panel.new()
	painel.size = Vector2(760, 320)
	painel.position = (vp - painel.size) / 2.0
	painel.add_theme_stylebox_override("panel", _style_panel(COR_ERRO, Color(0.018, 0.024, 0.035, 0.98), 0.34))
	ui_root.add_child(painel)

	var t := _label(titulo_txt, 28, Color.WHITE, COR_ERRO)
	t.position = Vector2(0, 44)
	t.size = Vector2(760, 48)
	painel.add_child(t)

	var m := _label(msg_txt, 18, Color(0.78, 0.84, 0.92))
	m.position = Vector2(60, 116)
	m.size = Vector2(640, 92)
	m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	painel.add_child(m)

	var btn := _botao_neon("OK", Vector2(260, 238), Vector2(240, 52), COR_ERRO)
	btn.pressed.connect(func():
		overlay.queue_free()
		painel.queue_free()
	)
	painel.add_child(btn)


func _verificar_resultado_pendente() -> void:
	var resultado: Dictionary = {}

	var cg := get_node_or_null("/root/CupGlobal")

	if cg != null:
		var r: Dictionary = cg.consumir_resultado_pendente()
		if not r.is_empty():
			resultado = r

	if resultado.is_empty() and get_tree().has_meta("resultado_copa_pendente"):
		var r_meta: Variant = get_tree().get_meta("resultado_copa_pendente")
		if r_meta is Dictionary:
			resultado = r_meta
			get_tree().remove_meta("resultado_copa_pendente")

	if resultado.is_empty():
		return

	var partida_index: int = int(resultado["partida_index"])
	var ranking: Array = resultado["ranking"]

	registrar_resultado_partida(partida_index, ranking)



func _criar_audios_cup() -> void:
	audio_cup_lobby = AudioStreamPlayer.new()
	audio_cup_lobby.name = "MusicaCupLobby"
	add_child(audio_cup_lobby)

	sfx_select_cup = AudioStreamPlayer.new()
	sfx_select_cup.name = "SfxSelectCup"
	add_child(sfx_select_cup)

	sfx_confirm_cup = AudioStreamPlayer.new()
	sfx_confirm_cup.name = "SfxConfirmCup"
	add_child(sfx_confirm_cup)

	sfx_campeao_cup = AudioStreamPlayer.new()
	sfx_campeao_cup.name = "SfxCampeaoCup"
	add_child(sfx_campeao_cup)

	if ResourceLoader.exists(MUSICA_CUP_LOBBY):
		var stream: AudioStream = load(MUSICA_CUP_LOBBY)

		if stream is AudioStreamMP3:
			stream.loop = true

		audio_cup_lobby.stream = stream
		audio_cup_lobby.volume_db = -7.0
	else:
		push_warning("Música da Copa não encontrada: " + MUSICA_CUP_LOBBY)

	if ResourceLoader.exists(SFX_SELECT_CUP):
		sfx_select_cup.stream = load(SFX_SELECT_CUP)
		sfx_select_cup.volume_db = 0.0
	else:
		push_warning("SFX select Copa não encontrado: " + SFX_SELECT_CUP)

	if ResourceLoader.exists(SFX_CONFIRM_CUP):
		sfx_confirm_cup.stream = load(SFX_CONFIRM_CUP)
		sfx_confirm_cup.volume_db = 0.0
	else:
		push_warning("SFX confirm Copa não encontrado: " + SFX_CONFIRM_CUP)

	if ResourceLoader.exists(SFX_CAMPEAO_CUP):
		sfx_campeao_cup.stream = load(SFX_CAMPEAO_CUP)
		sfx_campeao_cup.volume_db = 1.5
	else:
		push_warning("SFX campeão Copa não encontrado: " + SFX_CAMPEAO_CUP)



func _tocar_musica_cup() -> void:
	if audio_cup_lobby and audio_cup_lobby.stream:
		if not audio_cup_lobby.playing:
			audio_cup_lobby.play()


func _parar_musica_cup() -> void:
	if audio_cup_lobby and audio_cup_lobby.playing:
		audio_cup_lobby.stop()


func _tocar_select_cup() -> void:
	if sfx_select_cup and sfx_select_cup.stream:
		sfx_select_cup.stop()
		sfx_select_cup.play()


func _tocar_confirm_cup() -> void:
	if sfx_confirm_cup and sfx_confirm_cup.stream:
		sfx_confirm_cup.stop()
		sfx_confirm_cup.play()




func _processar_leds_lobby(delta: float) -> void:
	if not USAR_ARDUINO_LOBBY:
		return

	if not ponte_lobby_pronta:
		return

	led_lobby_timer += delta

	if led_lobby_timer < TEMPO_LED_LOBBY:
		return

	led_lobby_timer = 0.0

	var cores_disponiveis: Array[Color] = _cores_jogadores_reais_ativos()

	if cores_disponiveis.is_empty():
		cores_disponiveis = [
			Color(0.1, 0.75, 1.0),
			Color(0.2, 1.0, 0.3),
			Color(1.0, 0.15, 0.15),
			Color(1.0, 0.85, 0.05)
		]

	var qtd_leds: int = randi_range(LEDS_LOBBY_MIN, LEDS_LOBBY_MAX)
	qtd_leds = clamp(qtd_leds, 1, LEDS_TOTAL)

	var indices: Array[int] = []

	while indices.size() < qtd_leds:
		var novo: int = randi_range(0, LEDS_TOTAL - 1)

		if not indices.has(novo):
			indices.append(novo)

	var partes: Array[String] = []

	for index_led in indices:
		var letra: String = LEDS_LETRAS[index_led]
		var cor: Color = cores_disponiveis[randi() % cores_disponiveis.size()]
		var rgb: Array[int] = _cor_para_rgb255(cor)

		partes.append("%s=%d,%d,%d" % [
			letra,
			rgb[0],
			rgb[1],
			rgb[2]
		])

	if partes.is_empty():
		_serial_write_lobby("OFF")
		return

	var comando: String = "SET:" + ";".join(partes)
	_serial_write_lobby(comando)



func _cores_jogadores_reais_ativos() -> Array[Color]:
	var cores: Array[Color] = []

	var usar_classificados: bool = _todas_partidas_finalizadas()

	if usar_classificados:
		for g in grupos:
			if not g.has("jogadores"):
				continue

			var ordenados: Array = _jogadores_ordenados(g["jogadores"])

			for i in range(min(2, ordenados.size())):
				var j: Dictionary = ordenados[i]

				if bool(j.get("boot", false)):
					continue

				if j.has("cor") and j["cor"] is Color:
					cores.append(_normalizar_cor_player_led(j["cor"]))

		return cores

	for g in grupos:
		if not g.has("jogadores"):
			continue

		for j in g["jogadores"]:
			if bool(j.get("boot", false)):
				continue

			if j.has("cor") and j["cor"] is Color:
				cores.append(_normalizar_cor_player_led(j["cor"]))

	return cores


func _normalizar_cor_player_led(c: Color) -> Color:
	var r: float = c.r
	var g: float = c.g
	var b: float = c.b

	# Amarelo
	if r >= 0.70 and g >= 0.55 and b <= 0.35:
		return Color(1.0, 1.0, 0.0)

	# Vermelho
	if r >= g and r >= b:
		return Color(1.0, 0.0, 0.0)

	# Verde
	if g >= r and g >= b:
		return Color(0.0, 1.0, 0.0)

	# Azul
	if b >= r and b >= g:
		return Color(0.0, 0.0, 1.0)

	return Color.WHITE


func _cor_para_rgb255(c: Color) -> Array[int]:
	# Converte a cor visual do player para RGB forte de LED.
	# Isso evita vermelho rosado, azul claro ou verde apagado no NeoPixel.

	var r: float = c.r
	var g: float = c.g
	var b: float = c.b

	# AMARELO: vermelho + verde altos
	if r >= 0.70 and g >= 0.55 and b <= 0.35:
		return [255, 255, 0]

	# VERMELHO: vermelho dominante
	if r >= g and r >= b:
		return [255, 0, 0]

	# VERDE: verde dominante
	if g >= r and g >= b:
		return [0, 255, 0]

	# AZUL: azul dominante
	if b >= r and b >= g:
		return [0, 0, 255]

	# Segurança
	return [255, 255, 255]


func _abrir_serial_lobby() -> void:
	if not USAR_ARDUINO_LOBBY:
		return

	if not USAR_PONTE_POWERSHELL_LOBBY:
		return

	ponte_lobby_pronta = false

	_matar_pontes_lobby_antigas()

	await get_tree().create_timer(0.35).timeout

	_iniciar_ponte_powershell_lobby()

	await get_tree().create_timer(2.6).timeout

	ponte_lobby_pronta = true
	_serial_write_lobby("OFF")

	print("================================")
	print("ARDUINO LOBBY COPA PRONTO")
	print("LEDs em modo atrativo com cores dos jogadores reais")
	print("================================")


func _matar_pontes_lobby_antigas() -> void:
	var output: Array = []

	var comando := """
Get-CimInstance Win32_Process -Filter "name = 'powershell.exe'" |
Where-Object {
	$_.CommandLine -like '*arduino_bridge_cup_lobby.ps1*' -or
	$_.CommandLine -like '*arduino_bridge_cup.ps1*' -or
	$_.CommandLine -like '*arduino_bridge.ps1*'
} |
ForEach-Object {
	try {
		Stop-Process -Id $_.ProcessId -Force
	} catch {}
}
"""

	var args := [
		"-NoProfile",
		"-ExecutionPolicy",
		"Bypass",
		"-Command",
		comando
	]

	OS.execute("powershell.exe", args, output, true, false)

	print("PONTES POWERSHELL ANTIGAS DO LOBBY FINALIZADAS")


func _iniciar_ponte_powershell_lobby() -> void:
	caminho_log_arduino_lobby = ProjectSettings.globalize_path("user://arduino_log_cup_lobby.txt")
	caminho_script_arduino_lobby = ProjectSettings.globalize_path("user://arduino_bridge_cup_lobby.ps1")
	caminho_fila_arduino_lobby = ProjectSettings.globalize_path("user://arduino_queue_cup_lobby")

	DirAccess.make_dir_recursive_absolute(caminho_fila_arduino_lobby)

	var dir := DirAccess.open(caminho_fila_arduino_lobby)

	if dir:
		dir.list_dir_begin()
		var nome := dir.get_next()

		while nome != "":
			if not dir.current_is_dir() and nome.ends_with(".cmd"):
				dir.remove(nome)

			nome = dir.get_next()

		dir.list_dir_end()

	var flog := FileAccess.open(caminho_log_arduino_lobby, FileAccess.WRITE)

	if flog:
		flog.store_string("INICIANDO LOG DA PONTE ARDUINO CUP LOBBY\n")
		flog.close()

	var script := """
$ErrorActionPreference = 'Continue'

$porta = '%s'
$baud = %d
$queueDir = '%s'
$logFile = '%s'

function Log($txt) {
	$linha = ("{0} - {1}" -f (Get-Date -Format "HH:mm:ss.fff"), $txt)
	Add-Content -Path $logFile -Value $linha
	Write-Host $linha
}

Log "ABRINDO PORTA $porta / $baud"
Log "FILA: $queueDir"

try {
	$port = New-Object System.IO.Ports.SerialPort $porta, $baud, 'None', 8, 'One'
	$port.DtrEnable = $true
	$port.RtsEnable = $true
	$port.NewLine = "`n"
	$port.Open()

	Log "PORTA ABERTA"

	Start-Sleep -Milliseconds 2300

	$port.WriteLine("OFF")
	Log "TX: OFF"

	while ($true) {
		if (-not (Test-Path $queueDir)) {
			New-Item -ItemType Directory -Path $queueDir | Out-Null
		}

		$files = Get-ChildItem -Path $queueDir -Filter "*.cmd" | Sort-Object Name

		foreach ($file in $files) {
			$cmd = ""

			try {
				$cmd = Get-Content $file.FullName -Raw
				$cmd = $cmd.Trim()
				Remove-Item $file.FullName -Force
			}
			catch {
				continue
			}

			if ($cmd.Length -le 0) {
				continue
			}

			if ($cmd -eq "__EXIT__") {
				Log "SAINDO"
				$port.WriteLine("OFF")
				Start-Sleep -Milliseconds 100
				$port.Close()
				Log "PORTA FECHADA"
				exit
			}

			Log "TX: $cmd"
			$port.WriteLine($cmd)
			Start-Sleep -Milliseconds 25
		}

		Start-Sleep -Milliseconds 8
	}
}
catch {
	Log ("ERRO: " + $_.Exception.Message)
}
""" % [
		SERIAL_PORTA_LOBBY,
		SERIAL_BAUD_LOBBY,
		caminho_fila_arduino_lobby.replace("\\", "\\\\"),
		caminho_log_arduino_lobby.replace("\\", "\\\\")
	]

	var fs := FileAccess.open(caminho_script_arduino_lobby, FileAccess.WRITE)

	if fs == null:
		push_error("Não consegui criar script da ponte PowerShell do lobby.")
		return

	fs.store_string(script)
	fs.close()

	var args := [
		"-NoProfile",
		"-ExecutionPolicy",
		"Bypass",
		"-File",
		caminho_script_arduino_lobby
	]

	ponte_ps_pid_lobby = OS.create_process("powershell.exe", args, false)

	print("================================")
	print("PONTE POWERSHELL CUP LOBBY INICIADA")
	print("PID: ", ponte_ps_pid_lobby)
	print("QUEUE: ", caminho_fila_arduino_lobby)
	print("LOG FILE: ", caminho_log_arduino_lobby)
	print("================================")


func _serial_write_lobby(texto: String) -> void:
	if not USAR_ARDUINO_LOBBY:
		return

	var cmd := texto.strip_edges()

	if cmd == "":
		return

	if not USAR_PONTE_POWERSHELL_LOBBY:
		return

	if caminho_fila_arduino_lobby == "":
		return

	DirAccess.make_dir_recursive_absolute(caminho_fila_arduino_lobby)

	var nome_arquivo := "%020d_%06d.cmd" % [
		Time.get_ticks_msec(),
		randi() % 1000000
	]

	var caminho_temp := caminho_fila_arduino_lobby.path_join(nome_arquivo + ".tmp")
	var caminho_final := caminho_fila_arduino_lobby.path_join(nome_arquivo)

	var f := FileAccess.open(caminho_temp, FileAccess.WRITE)

	if f == null:
		push_warning("Não consegui criar comando temporário Arduino Lobby: " + caminho_temp)
		return

	f.store_string(cmd)
	f.close()

	var err := DirAccess.rename_absolute(caminho_temp, caminho_final)

	if err != OK:
		push_warning("Não consegui mover comando para fila Arduino Lobby. Erro: " + str(err))


func _fechar_ponte_lobby_leds() -> void:
	ponte_lobby_pronta = false

	_serial_write_lobby("OFF")

	if USAR_PONTE_POWERSHELL_LOBBY and caminho_fila_arduino_lobby != "":
		var nome_arquivo := "%020d_EXIT.cmd" % Time.get_ticks_msec()
		var caminho_final := caminho_fila_arduino_lobby.path_join(nome_arquivo)

		var f := FileAccess.open(caminho_final, FileAccess.WRITE)

		if f:
			f.store_string("__EXIT__")
			f.close()


func _iniciar_confetes_campeao(cor_base: Color) -> void:
	_parar_confetes()

	confete_cor_base = cor_base
	confetes.clear()

	confete_layer = CanvasLayer.new()
	confete_layer.layer = 40
	add_child(confete_layer)

	var vp: Vector2 = get_viewport_rect().size

	for i in range(120):
		_criar_confete(Vector2(randf_range(0.0, vp.x), randf_range(-vp.y, 0.0)), true)


func _criar_confete(pos: Vector2, inicial: bool = false) -> void:
	if confete_layer == null:
		return

	var vp: Vector2 = get_viewport_rect().size

	var c := ColorRect.new()

	var largura: float = randf_range(5.0, 12.0)
	var altura: float = randf_range(9.0, 18.0)

	c.size = Vector2(largura, altura)
	c.position = pos
	c.rotation = randf_range(0.0, TAU)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var cor: Color = confete_cor_base

	var variacao: int = randi_range(0, 4)
	if variacao == 0:
		cor = confete_cor_base.lightened(0.35)
	elif variacao == 1:
		cor = Color.WHITE
	elif variacao == 2:
		cor = COR_ALERTA
	elif variacao == 3:
		cor = confete_cor_base.darkened(0.15)

	c.color = Color(cor.r, cor.g, cor.b, randf_range(0.72, 1.0))

	confete_layer.add_child(c)

	var velocidade_y: float = randf_range(95.0, 230.0)
	var velocidade_x: float = randf_range(-55.0, 55.0)

	if inicial:
		velocidade_y = randf_range(65.0, 190.0)

	confetes.append({
		"node": c,
		"vel": Vector2(velocidade_x, velocidade_y),
		"rot": randf_range(-5.0, 5.0),
		"fase": randf_range(0.0, TAU),
		"onda": randf_range(18.0, 55.0)
	})


func _processar_confetes(delta: float) -> void:
	if confete_layer == null:
		return

	var vp: Vector2 = get_viewport_rect().size

	# Gera confete infinito.
	for n in range(3):
		_criar_confete(Vector2(randf_range(0.0, vp.x), randf_range(-40.0, -10.0)))

	for i in range(confetes.size() - 1, -1, -1):
		var item: Dictionary = confetes[i]
		var node: ColorRect = item.get("node", null)

		if node == null or not is_instance_valid(node):
			confetes.remove_at(i)
			continue

		var vel: Vector2 = item.get("vel", Vector2.ZERO)
		var rot: float = float(item.get("rot", 0.0))
		var fase: float = float(item.get("fase", 0.0))
		var onda: float = float(item.get("onda", 30.0))

		fase += delta * 3.0
		item["fase"] = fase

		node.position.x += (vel.x + sin(fase) * onda) * delta
		node.position.y += vel.y * delta
		node.rotation += rot * delta

		if node.position.y > vp.y + 80.0:
			node.queue_free()
			confetes.remove_at(i)


func _parar_confetes() -> void:
	confetes.clear()

	if confete_layer != null and is_instance_valid(confete_layer):
		confete_layer.queue_free()

	confete_layer = null


func _mostrar_tela_carregamento_lobby(titulo_txt: String, sub_txt: String) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 500
	add_child(layer)

	var loading_root := Control.new()
	loading_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(loading_root)

	var tela := get_viewport_rect().size

	# Fundo base escuro para preencher possíveis barras laterais/superiores.
	var fundo_base := ColorRect.new()
	fundo_base.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo_base.color = Color(0.004, 0.007, 0.014, 1.0)
	fundo_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_root.add_child(fundo_base)

	# Imagem de carregamento COMPLETA, sem zoom e sem corte.
	if ResourceLoader.exists(IMAGEM_LOADING_COPA):
		var img := TextureRect.new()
		img.set_anchors_preset(Control.PRESET_FULL_RECT)
		img.texture = load(IMAGEM_LOADING_COPA)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

		# Mostra a imagem inteira sem cortar.
		# Se a proporção da imagem for diferente da tela, sobram barras escuras.
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		loading_root.add_child(img)
	else:
		push_warning("Imagem de loading não encontrada: " + IMAGEM_LOADING_COPA)

	var escuro := ColorRect.new()
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	escuro.color = Color(0, 0, 0, 0.42)
	escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_root.add_child(escuro)

	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 0.070)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_root.add_child(glow)

	# Rodapé com todas as imagens da pasta res://patro/
	_adicionar_rodape_patrocinadores_loading(loading_root)

	var painel := Panel.new()
	painel.size = Vector2(minf(tela.x * 0.62, 860.0), 300)

	# Sobe um pouco o painel para não brigar com os patrocinadores no rodapé.
	painel.position = Vector2(
		(tela.x - painel.size.x) * 0.5,
		maxf(70.0, (tela.y - painel.size.y) * 0.5 - 42.0)
	)

	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_theme_stylebox_override(
		"panel",
		_style_panel(COR_NEON, Color(0.012, 0.018, 0.030, 0.965), 0.82)
	)
	loading_root.add_child(painel)

	var W := painel.size.x
	var H := painel.size.y

	var titulo := _label(titulo_txt, 36, Color.WHITE, COR_NEON)
	titulo.position = Vector2(30, 44)
	titulo.size = Vector2(W - 60, 58)
	painel.add_child(titulo)

	var sub := _label(sub_txt, 19, Color(0.72, 0.84, 0.96))
	sub.position = Vector2(30, 118)
	sub.size = Vector2(W - 60, 36)
	painel.add_child(sub)

	var pct := _label("CARREGANDO...", 28, COR_ALERTA, COR_ALERTA)
	pct.position = Vector2(0, H - 118)
	pct.size = Vector2(W, 40)
	painel.add_child(pct)

	var barra_bg := ColorRect.new()
	barra_bg.position = Vector2(70, H - 70)
	barra_bg.size = Vector2(W - 140, 10)
	barra_bg.color = Color(1, 1, 1, 0.12)
	barra_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(barra_bg)

	var barra := ColorRect.new()
	barra.position = barra_bg.position
	barra.size = Vector2(6, 10)
	barra.color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 1.0)
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(barra)

	var t := create_tween()
	t.tween_property(barra, "size:x", barra_bg.size.x, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	return layer


func _listar_imagens_patrocinadores() -> Array[String]:
	var imagens: Array[String] = []

	for caminho in PATROCINADORES_FIXOS:
		if ResourceLoader.exists(caminho):
			if not imagens.has(caminho):
				imagens.append(caminho)
		else:
			push_warning("Patrocinador da lista fixa não encontrado: " + caminho)

	print("PATROCINADORES LOBBY (lista fixa): ", imagens.size(), " de ", PATROCINADORES_FIXOS.size())
	return imagens



func _material_cantos_redondos(tamanho: Vector2, raio: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform vec2 tamanho;
uniform float raio;

void fragment() {
	vec2 pos = UV * tamanho;
	vec2 meia = tamanho * 0.5;
	vec2 d = abs(pos - meia) - (meia - vec2(raio));
	float dist = length(max(d, vec2(0.0))) - raio;
	float a = 1.0 - smoothstep(0.0, 1.5, dist);

	COLOR = texture(TEXTURE, UV);
	COLOR.a *= a;
}
"""

	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("tamanho", tamanho)
	mat.set_shader_parameter("raio", raio)
	return mat



func _adicionar_rodape_patrocinadores_loading(alvo: Control) -> void:
	if alvo == null:
		return

	var imagens: Array[String] = _listar_imagens_patrocinadores()

	if imagens.is_empty():
		return

	var tela := get_viewport_rect().size
	var total: int = imagens.size()

	# Flexível:
	# poucos patrocinadores = logos grandes
	# muitos patrocinadores = quebra em linhas mantendo leitura boa
	var max_por_linha: int = 8

	if total <= 4:
		max_por_linha = total
	elif total <= 6:
		max_por_linha = 6
	else:
		max_por_linha = 8

	max_por_linha = maxi(max_por_linha, 1)

	var linhas: int = int(ceil(float(total) / float(max_por_linha)))
	linhas = maxi(linhas, 1)

	var margem_x: float = 54.0
	var gap: float = 18.0
	var row_gap: float = 12.0

	var card_h: float = 96.0

	if linhas == 2:
		card_h = 78.0
	elif linhas >= 3:
		card_h = 64.0

	var footer_h: float = float(linhas) * card_h + float(maxi(linhas - 1, 0)) * row_gap + 34.0
	var footer_h_max: float = tela.y * 0.34

	# Se tiver muitos logos, reduz proporcionalmente para caber.
	if footer_h > footer_h_max:
		var fator: float = footer_h_max / footer_h
		card_h *= fator
		row_gap *= fator
		footer_h = footer_h_max

	var footer_y: float = tela.y - footer_h - 14.0

	var fundo := Panel.new()
	fundo.position = Vector2(32.0, footer_y)
	fundo.size = Vector2(tela.x - 64.0, footer_h)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.clip_contents = true

	var fundo_style := StyleBoxFlat.new()
	fundo_style.bg_color = Color(0.004, 0.012, 0.020, 0.86)
	fundo_style.border_color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 0.42)
	fundo_style.set_border_width_all(2)
	fundo_style.set_corner_radius_all(0)
	fundo_style.shadow_color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 0.36)
	fundo_style.shadow_size = 24
	fundo_style.shadow_offset = Vector2.ZERO
	fundo.add_theme_stylebox_override("panel", fundo_style)

	alvo.add_child(fundo)

	# FOTO DE FUNDO DO FOOTER (cantos arredondados seguindo o molde do painel)
	var raio_footer: float = 24.0

	# FOTO DE FUNDO DO FOOTER
	if ResourceLoader.exists(IMAGEM_FUNDO_FOOTER_PATRO):
		var foto := TextureRect.new()
		foto.set_anchors_preset(Control.PRESET_FULL_RECT)
		foto.texture = load(IMAGEM_FUNDO_FOOTER_PATRO)
		foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		foto.stretch_mode = TextureRect.STRETCH_SCALE
		foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		foto.modulate = Color(1, 1, 1, 0.55)
		fundo.add_child(foto)

		var escuro_foto := ColorRect.new()
		escuro_foto.set_anchors_preset(Control.PRESET_FULL_RECT)
		escuro_foto.color = Color(0, 0, 0, 0.42)
		escuro_foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fundo.add_child(escuro_foto)
	else:
		# Fallback bonito se não tiver imagem de fundo.
		var verde := ColorRect.new()
		verde.set_anchors_preset(Control.PRESET_FULL_RECT)
		verde.color = Color(0.00, 0.26, 0.10, 0.72)
		verde.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fundo.add_child(verde)

		var amarelo := ColorRect.new()
		amarelo.position = Vector2(fundo.size.x * 0.50, 0)
		amarelo.size = Vector2(fundo.size.x * 0.50, fundo.size.y)
		amarelo.color = Color(1.0, 0.82, 0.06, 0.22)
		amarelo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fundo.add_child(amarelo)

	var brilho := ColorRect.new()
	brilho.position = Vector2(24, 10)
	brilho.size = Vector2(fundo.size.x - 48, 3)
	brilho.color = Color(1, 1, 1, 0.14)
	brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_child(brilho)

	for linha in range(linhas):
		var inicio: int = linha * max_por_linha
		var fim: int = mini(inicio + max_por_linha, total)
		var qtd: int = fim - inicio

		if qtd <= 0:
			continue

		var area_w: float = fundo.size.x - margem_x * 2.0
		var card_w: float = (area_w - gap * float(qtd - 1)) / float(qtd)

		# Logos maiores quando tem poucos patrocinadores.
		if total <= 4:
			card_w = clampf(card_w, 180.0, 310.0)
		elif total <= 8:
			card_w = clampf(card_w, 135.0, 230.0)
		else:
			card_w = clampf(card_w, 105.0, 190.0)

		var total_w: float = card_w * float(qtd) + gap * float(qtd - 1)
		var x0: float = (fundo.size.x - total_w) * 0.5
		var y0: float = 17.0 + float(linha) * (card_h + row_gap)

		for i in range(qtd):
			var caminho: String = imagens[inicio + i]
			var card := _criar_card_patrocinador_footer_loading(
				caminho,
				Vector2(card_w, card_h)
			)

			card.position = Vector2(x0 + float(i) * (card_w + gap), y0)
			card.modulate = Color(1, 1, 1, 0)
			card.scale = Vector2(0.94, 0.94)
			fundo.add_child(card)

			var delay: float = float(inicio + i) * 0.025
			var t := create_tween()
			t.set_parallel(true)
			t.tween_property(card, "modulate", Color.WHITE, 0.22).set_delay(delay)
			t.tween_property(card, "scale", Vector2.ONE, 0.22).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _criar_card_patrocinador_footer_loading(caminho: String, tamanho: Vector2) -> Panel:
	var card := Panel.new()
	card.size = tamanho
	card.custom_minimum_size = tamanho
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.clip_contents = true

	var fundo_especial: Color = _fundo_logo_loading(caminho)
	var tem_especial: bool = fundo_especial.a > 0.0
	var claro: bool = tem_especial and (fundo_especial.r + fundo_especial.g + fundo_especial.b) > 1.5

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.0, 0.30, 0.10, 1.0)
	st.border_color = Color(1.0, 0.86, 0.05, 0.96)
	st.set_border_width_all(2)
	st.set_corner_radius_all(16)
	st.shadow_color = Color(1.0, 0.82, 0.05, 0.42)
	st.shadow_size = 14
	st.shadow_offset = Vector2.ZERO
	card.add_theme_stylebox_override("panel", st)

	var margem := 7.0

	var inner := Panel.new()
	inner.position = Vector2(margem, margem)
	inner.size = tamanho - Vector2(margem * 2.0, margem * 2.0)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.clip_contents = true
	card.add_child(inner)

	var inner_st := StyleBoxFlat.new()
	inner_st.set_border_width_all(2)
	inner_st.set_corner_radius_all(12)

	if tem_especial:
		inner_st.bg_color = fundo_especial
		inner_st.border_color = Color(0, 0, 0, 0.22) if claro else Color(1, 1, 1, 0.20)
	else:
		# Mesmo sistema verde/amarelo do opening.
		inner_st.bg_color = Color(0.98, 0.86, 0.12, 1.0)
		inner_st.border_color = Color(0.0, 0.42, 0.12, 0.95)

	inner.add_theme_stylebox_override("panel", inner_st)

	# Fundo verde/amarelo apenas para logos sem fundo especial.
	if not tem_especial:
		var faixa_verde := ColorRect.new()
		faixa_verde.position = Vector2.ZERO
		faixa_verde.size = Vector2(inner.size.x * 0.50, inner.size.y)
		faixa_verde.color = Color(0.02, 0.42, 0.14, 1.0)
		faixa_verde.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(faixa_verde)

		var faixa_amarela := ColorRect.new()
		faixa_amarela.position = Vector2(inner.size.x * 0.50, 0)
		faixa_amarela.size = Vector2(inner.size.x * 0.50, inner.size.y)
		faixa_amarela.color = Color(1.0, 0.86, 0.10, 1.0)
		faixa_amarela.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(faixa_amarela)

	var brilho := ColorRect.new()
	brilho.position = Vector2(10, 7)
	brilho.size = Vector2(inner.size.x - 20, 2)
	brilho.color = Color(1, 1, 1, 0.08 if claro else 0.18)
	brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(brilho)

	var tex := load(caminho) as Texture2D

	if tex != null:
		var pad := 8.0

		if tem_especial:
			pad = 12.0

		# Logos bem maiores.
		var img := TextureRect.new()
		img.position = Vector2(pad, pad * 0.72)
		img.size = inner.size - Vector2(pad * 2.0, pad * 1.44)
		img.texture = tex
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(img)
	else:
		var erro := Label.new()
		erro.text = "LOGO"
		erro.set_anchors_preset(Control.PRESET_FULL_RECT)
		erro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		erro.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		erro.add_theme_font_size_override("font_size", 14)
		erro.add_theme_color_override("font_color", Color.RED)
		inner.add_child(erro)

	return card

func _fundo_logo_loading(caminho: String) -> Color:
	var base: String = caminho.get_file().to_lower()

	# bar.png -> fundo PRETO
	if base == "bar.png" or base.begins_with("bar."):
		return Color(0.0, 0.0, 0.0, 1.0)

	# corona_logo.png -> fundo BRANCO
	if base.contains("corona"):
		return Color(1.0, 1.0, 1.0, 1.0)

	# Michelob-Ultra -> fundo BRANCO
	if base.contains("michelob"):
		return Color(1.0, 1.0, 1.0, 1.0)

	# GA_Logo.png / Guaraná -> verde da marca
	if base.begins_with("ga_") or base.contains("guaran"):
		return Color(0.0, 0.60, 0.28, 1.0)

	# Stella -> dourado/amarelo
	if base.contains("stella"):
		return Color(0.79, 0.65, 0.18, 1.0)

	# Budweiser -> vermelho
	if base == "bud.png" or base.begins_with("bud"):
		return Color(0.86, 0.10, 0.13, 1.0)

	# Sem fundo especial: usa o tema verde/amarelo.
	return Color(0.0, 0.0, 0.0, 0.0)


func _style_card_patrocinador() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 1, 1, 0.090)
	s.border_color = Color(1, 1, 1, 0.20)
	s.set_border_width_all(1)
	s.set_corner_radius_all(14)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 8
	s.shadow_offset = Vector2.ZERO
	return s


func _remover_tela_carregamento_lobby(layer: CanvasLayer) -> void:
	if layer == null:
		return

	if not is_instance_valid(layer):
		return

	var root_loading: Control = null

	if layer.get_child_count() > 0 and layer.get_child(0) is Control:
		root_loading = layer.get_child(0)

	if root_loading != null and is_instance_valid(root_loading):
		var t := create_tween()
		t.tween_property(root_loading, "modulate", Color(1, 1, 1, 0), 0.28)
		await t.finished

	if is_instance_valid(layer):
		layer.queue_free()

func _grupo_ja_fechou(letra_grupo: String) -> bool:
	var achou: bool = false

	for p in partidas:
		if str(p.get("fase", "")) != FASE_GRUPOS:
			continue

		if str(p.get("grupo", "")) != letra_grupo:
			continue

		achou = true

		if not bool(p.get("finalizada", false)):
			return false

	return achou


func _tocar_campeao_cup() -> void:
	if sfx_campeao_cup == null:
		return

	if sfx_campeao_cup.stream == null:
		return

	if sfx_campeao_cup.stream is AudioStreamMP3:
		sfx_campeao_cup.stream.loop = false

	sfx_campeao_cup.stop()
	sfx_campeao_cup.play()


func _parar_campeao_cup() -> void:
	if sfx_campeao_cup and sfx_campeao_cup.playing:
		sfx_campeao_cup.stop()
		

func _mapa_estatisticas_gerais_competicao() -> Dictionary:
	var mapa: Dictionary = {}

	# Base pelos grupos.
	for g in grupos:
		var grupo_nome: String = str(g.get("grupo", ""))

		for j in g.get("jogadores", []):
			var nome: String = str(j.get("nome", ""))

			if nome == "":
				continue

			mapa[nome] = {
				"nome": nome,
				"cor": _cor_jogador_dict(j),
				"boot": bool(j.get("boot", false)),
				"grupo": grupo_nome,
				"pontos_grupo": int(j.get("pontos", 0)),
				"gols_grupo_tabela": int(j.get("gols", j.get("gols_pro", 0))),
				"jogos_grupo_tabela": int(j.get("jogos", 0)),
				"jogos_total": 0,
				"gols_total": 0,
				"penaltis_total": 0,
				"vitorias_total": 0,
				"fase_valor": 0,
				"fase_nome": "GRUPOS",
				"podio_pos": 99
			}

	# Soma real partida por partida.
	for p in partidas:
		if not bool(p.get("finalizada", false)):
			continue

		var fase_p: String = str(p.get("fase", ""))
		var fase_valor: int = _valor_fase_geral(fase_p)
		var ranking: Array = p.get("ranking", [])

		for item in ranking:
			var nome_item: String = str(item.get("nome", ""))

			if nome_item == "":
				continue

			if not mapa.has(nome_item):
				mapa[nome_item] = {
					"nome": nome_item,
					"cor": _cor_jogador_dict(item),
					"boot": bool(item.get("boot", false)),
					"grupo": "",
					"pontos_grupo": 0,
					"gols_grupo_tabela": 0,
					"jogos_grupo_tabela": 0,
					"jogos_total": 0,
					"gols_total": 0,
					"penaltis_total": 0,
					"vitorias_total": 0,
					"fase_valor": 0,
					"fase_nome": "GRUPOS",
					"podio_pos": 99
				}

			var st: Dictionary = mapa[nome_item]

			st["jogos_total"] = int(st.get("jogos_total", 0)) + 1
			st["gols_total"] = int(st.get("gols_total", 0)) + int(item.get("gols", item.get("score", 0)))
			st["penaltis_total"] = int(st.get("penaltis_total", 0)) + int(item.get("penaltis", 0))

			var posicao: int = int(item.get("posicao", 99))

			if _posicao_conta_vitoria(fase_p, posicao):
				st["vitorias_total"] = int(st.get("vitorias_total", 0)) + 1

			if fase_valor > int(st.get("fase_valor", 0)):
				st["fase_valor"] = fase_valor
				st["fase_nome"] = _nome_fase_geral(fase_p)

			mapa[nome_item] = st

	# Define pódio real.
	var partida_final: Dictionary = {}
	var partida_terceiro: Dictionary = {}

	for p in _partidas_da_fase(FASE_FINAL):
		if bool(p.get("disputa_terceiro", false)):
			partida_terceiro = p
		else:
			partida_final = p

	if not partida_final.is_empty() and bool(partida_final.get("finalizada", false)):
		var rk_final: Array = partida_final.get("ranking", [])

		if rk_final.size() > 0:
			var n1: String = str(rk_final[0].get("nome", ""))
			if mapa.has(n1):
				mapa[n1]["podio_pos"] = 1

		if rk_final.size() > 1:
			var n2: String = str(rk_final[1].get("nome", ""))
			if mapa.has(n2):
				mapa[n2]["podio_pos"] = 2

	if not partida_terceiro.is_empty() and bool(partida_terceiro.get("finalizada", false)):
		var rk_terceiro: Array = partida_terceiro.get("ranking", [])

		if rk_terceiro.size() > 0:
			var n3: String = str(rk_terceiro[0].get("nome", ""))
			if mapa.has(n3):
				mapa[n3]["podio_pos"] = 3

	return mapa


func _estatisticas_gerais_competicao() -> Array:
	var mapa: Dictionary = _mapa_estatisticas_gerais_competicao()
	var lista: Array = mapa.values()

	lista.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pod_a: int = int(a.get("podio_pos", 99))
		var pod_b: int = int(b.get("podio_pos", 99))

		if pod_a != pod_b:
			return pod_a < pod_b

		var fase_a: int = int(a.get("fase_valor", 0))
		var fase_b: int = int(b.get("fase_valor", 0))

		if fase_a != fase_b:
			return fase_a > fase_b

		var vit_a: int = int(a.get("vitorias_total", 0))
		var vit_b: int = int(b.get("vitorias_total", 0))

		if vit_a != vit_b:
			return vit_a > vit_b

		var gols_a: int = int(a.get("gols_total", 0))
		var gols_b: int = int(b.get("gols_total", 0))

		if gols_a != gols_b:
			return gols_a > gols_b

		var pts_a: int = int(a.get("pontos_grupo", 0))
		var pts_b: int = int(b.get("pontos_grupo", 0))

		if pts_a != pts_b:
			return pts_a > pts_b

		return str(a.get("nome", "")) < str(b.get("nome", ""))
	)

	for i in range(lista.size()):
		lista[i]["colocacao_geral"] = i + 1

	return lista


func _valor_fase_geral(fase: String) -> int:
	match fase:
		FASE_GRUPOS:
			return 1
		FASE_OITAVAS:
			return 2
		FASE_SEMIFINAL:
			return 3
		FASE_FINAL:
			return 4
		_:
			return 0


func _nome_fase_geral(fase: String) -> String:
	match fase:
		FASE_GRUPOS:
			return "GRUPOS"
		FASE_OITAVAS:
			return "TOP 8"
		FASE_SEMIFINAL:
			return "SEMIFINAL"
		FASE_FINAL:
			return "FINAL"
		_:
			return str(fase)


func _posicao_conta_vitoria(fase: String, posicao: int) -> bool:
	if fase == FASE_GRUPOS:
		return posicao <= 2

	if fase == FASE_OITAVAS:
		return posicao <= 2

	if fase == FASE_SEMIFINAL:
		return posicao == 1

	if fase == FASE_FINAL:
		return posicao == 1

	return false


func _mostrar_tabela_geral_sequencia(segundos: float = 8.0) -> void:
	_limpar_ui()

	var vp: Vector2 = get_viewport_rect().size
	var tabela_completa: Array = _estatisticas_gerais_competicao()
	var tabela: Array = _filtrar_top10_jogadores_reais(tabela_completa, 10)

	_criar_back_copa(false, 0.62, 0.070)

	var titulo := _label("🏆 CLASSIFICAÇÃO FINAL DA COPA", 38, Color.WHITE, COR_ALERTA)
	titulo.position = Vector2(0, 22)
	titulo.size = Vector2(vp.x, 56)
	ui_root.add_child(titulo)

	var subt := _label("TOP 10 DA COMPETIÇÃO  •  SOMENTE JOGADORES REAIS", 16, Color(0.72, 0.82, 0.94))
	subt.position = Vector2(0, 78)
	subt.size = Vector2(vp.x, 28)
	ui_root.add_child(subt)

	var box_w: float = minf(vp.x - 90.0, 1260.0)
	var box_x: float = (vp.x - box_w) * 0.5

	var destaque_y: float = 116.0
	var destaque_h: float = 112.0
	var destaque_gap: float = 28.0
	var destaque_w: float = (box_w - destaque_gap) * 0.5

	var artilheiro: Dictionary = _obter_artilheiro_da_tabela(tabela)
	var melhor_campanha: Dictionary = _obter_melhor_campanha_da_tabela(tabela)

	_criar_card_destaque_classificacao(
		ui_root,
		"⚽ MAIOR GOLEADOR",
		artilheiro,
		Vector2(box_x, destaque_y),
		Vector2(destaque_w, destaque_h),
		COR_ALERTA,
		"goleador"
	)

	_criar_card_destaque_classificacao(
		ui_root,
		"⭐ MELHOR CAMPANHA",
		melhor_campanha,
		Vector2(box_x + destaque_w + destaque_gap, destaque_y),
		Vector2(destaque_w, destaque_h),
		COR_OK,
		"campanha"
	)

	var painel_y: float = 248.0
	var painel_h: float = vp.y - painel_y - 118.0

	var painel := Panel.new()
	painel.position = Vector2(box_x, painel_y)
	painel.size = Vector2(box_w, painel_h)
	painel.add_theme_stylebox_override(
		"panel",
		_style_panel(COR_NEON, Color(0.014, 0.020, 0.032, 0.985), 0.30)
	)
	ui_root.add_child(painel)

	var W: float = box_w
	var H: float = painel_h

	var header_h: float = 40.0

	var header := ColorRect.new()
	header.position = Vector2(18, 18)
	header.size = Vector2(W - 36, header_h)
	header.color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 0.16)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(header)

	_adicionar_header_tabela_geral(painel, W)

	if tabela.is_empty():
		var vazio := _label("NENHUM JOGADOR REAL ENCONTRADO NA CLASSIFICAÇÃO", 22, Color(0.70, 0.76, 0.86))
		vazio.position = Vector2(0, H * 0.46)
		vazio.size = Vector2(W, 50)
		painel.add_child(vazio)

		await get_tree().create_timer(segundos).timeout
		return

	var max_linhas: int = mini(tabela.size(), 10)
	var area_y: float = 68.0
	var area_h: float = H - 94.0
	var row_gap: float = 6.0
	var row_h: float = (area_h - row_gap * float(max_linhas - 1)) / float(maxi(max_linhas, 1))
	row_h = clampf(row_h, 34.0, 52.0)

	for i in range(max_linhas):
		var st: Dictionary = tabela[i]
		var posicao: int = i + 1
		var cor_j: Color = _cor_jogador_dict(st)

		var cor_linha: Color = Color(0.75, 0.84, 0.96)
		var fundo_linha: Color = Color(1, 1, 1, 0.030)
		var brilho: float = 0.02
		var borda: Color = Color(1, 1, 1, 0.12)

		if posicao == 1:
			cor_linha = COR_ALERTA
			fundo_linha = Color(0.075, 0.055, 0.012, 0.98)
			borda = COR_ALERTA
			brilho = 0.55
		elif posicao == 2:
			cor_linha = COR_PRATA
			fundo_linha = Color(0.055, 0.060, 0.075, 0.96)
			borda = COR_PRATA
			brilho = 0.32
		elif posicao == 3:
			cor_linha = COR_BRONZE
			fundo_linha = Color(0.070, 0.040, 0.020, 0.96)
			borda = COR_BRONZE
			brilho = 0.28
		elif int(st.get("fase_valor", 0)) >= 2:
			cor_linha = COR_OK
			fundo_linha = Color(0.020, 0.052, 0.034, 0.90)
			borda = Color(COR_OK.r, COR_OK.g, COR_OK.b, 0.40)
			brilho = 0.10

		var y: float = area_y + float(i) * (row_h + row_gap)

		var row := Panel.new()
		row.position = Vector2(18, y)
		row.size = Vector2(W - 36, row_h)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var rs := StyleBoxFlat.new()
		rs.bg_color = fundo_linha
		rs.border_color = borda
		rs.set_border_width_all(2 if posicao <= 3 else 1)
		rs.set_corner_radius_all(14)
		rs.shadow_color = Color(borda.r, borda.g, borda.b, brilho)
		rs.shadow_size = 16 if posicao <= 3 else 5
		rs.shadow_offset = Vector2.ZERO
		row.add_theme_stylebox_override("panel", rs)
		painel.add_child(row)

		var nome_txt: String = str(st.get("nome", "?"))

		var medalha: String = ""
		if posicao == 1:
			medalha = "👑 "
		elif posicao == 2:
			medalha = "🥈 "
		elif posicao == 3:
			medalha = "🥉 "

		var chip := Panel.new()
		chip.position = Vector2(72, y + row_h * 0.5 - 9.0)
		chip.size = Vector2(18, 18)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_theme_stylebox_override("panel", _style_chip(cor_j))
		painel.add_child(chip)

		_adicionar_celula_tabela_geral(painel, "%dº" % posicao, 20, y, 70, row_h, 15, cor_linha, HORIZONTAL_ALIGNMENT_CENTER)
		_adicionar_celula_tabela_geral(painel, medalha + nome_txt, 104, y, W * 0.33, row_h, 15, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		_adicionar_celula_tabela_geral(painel, str(st.get("fase_nome", "GRUPOS")), W * 0.47, y, 150, row_h, 14, cor_linha, HORIZONTAL_ALIGNMENT_CENTER)
		_adicionar_celula_tabela_geral(painel, str(int(st.get("jogos_total", 0))), W * 0.61, y, 70, row_h, 14, Color(0.86, 0.94, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
		_adicionar_celula_tabela_geral(painel, str(int(st.get("vitorias_total", 0))), W * 0.69, y, 80, row_h, 14, COR_OK, HORIZONTAL_ALIGNMENT_CENTER)
		_adicionar_celula_tabela_geral(painel, str(int(st.get("gols_total", 0))), W * 0.78, y, 90, row_h, 14, COR_ALERTA, HORIZONTAL_ALIGNMENT_CENTER)
		_adicionar_celula_tabela_geral(painel, str(int(st.get("pontos_grupo", 0))), W * 0.89, y, 80, row_h, 14, Color(0.80, 0.88, 1.0), HORIZONTAL_ALIGNMENT_CENTER)

	var aviso := _label("ABRINDO O PÓDIO FINAL...", 20, COR_NEON, COR_NEON)
	aviso.position = Vector2(0, vp.y - 74)
	aviso.size = Vector2(vp.x, 34)
	ui_root.add_child(aviso)

	await get_tree().create_timer(segundos).timeout


func _adicionar_header_tabela_geral(painel: Panel, W: float) -> void:
	var y: float = 18.0
	var h: float = 42.0

	_adicionar_celula_tabela_geral(painel, "POS", 20, y, 70, h, 12, Color(0.70, 0.80, 0.92), HORIZONTAL_ALIGNMENT_CENTER)
	_adicionar_celula_tabela_geral(painel, "JOGADOR", 104, y, W * 0.33, h, 12, Color(0.70, 0.80, 0.92), HORIZONTAL_ALIGNMENT_LEFT)
	_adicionar_celula_tabela_geral(painel, "FASE", W * 0.47, y, 150, h, 12, Color(0.70, 0.80, 0.92), HORIZONTAL_ALIGNMENT_CENTER)
	_adicionar_celula_tabela_geral(painel, "J", W * 0.61, y, 70, h, 12, Color(0.70, 0.80, 0.92), HORIZONTAL_ALIGNMENT_CENTER)
	_adicionar_celula_tabela_geral(painel, "VIT", W * 0.69, y, 80, h, 12, Color(0.70, 0.80, 0.92), HORIZONTAL_ALIGNMENT_CENTER)
	_adicionar_celula_tabela_geral(painel, "GOLS", W * 0.78, y, 90, h, 12, Color(0.70, 0.80, 0.92), HORIZONTAL_ALIGNMENT_CENTER)
	_adicionar_celula_tabela_geral(painel, "PTS", W * 0.89, y, 80, h, 12, Color(0.70, 0.80, 0.92), HORIZONTAL_ALIGNMENT_CENTER)


func _adicionar_celula_tabela_geral(
	pai: Control,
	txt: String,
	x: float,
	y: float,
	w: float,
	h: float,
	tam: int,
	cor: Color,
	align: HorizontalAlignment
) -> void:
	var lbl := _label(txt, tam, cor)
	lbl.position = Vector2(x, y)
	lbl.size = Vector2(w, h)
	lbl.horizontal_alignment = align
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.clip_text = true
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.90))
	lbl.add_theme_constant_override("outline_size", 3)
	pai.add_child(lbl)



func _filtrar_top10_jogadores_reais(tabela_completa: Array, limite: int = 10) -> Array:
	var saida: Array = []

	for item in tabela_completa:
		if not (item is Dictionary):
			continue

		var st: Dictionary = item.duplicate(true)

		if bool(st.get("boot", false)):
			continue

		var nome: String = str(st.get("nome", "")).strip_edges()
		if nome == "":
			continue

		var jogos: int = int(st.get("jogos_total", 0))
		var gols: int = int(st.get("gols_total", 0))
		var pontos: int = int(st.get("pontos_grupo", 0))

		# Remove qualquer jogador sem participação real.
		if jogos <= 0 and gols <= 0 and pontos <= 0:
			continue

		st["colocacao_geral"] = saida.size() + 1
		saida.append(st)

		if saida.size() >= limite:
			break

	return saida


func _obter_artilheiro_da_tabela(tabela: Array) -> Dictionary:
	if tabela.is_empty():
		return {}

	var lista: Array = tabela.duplicate(true)

	lista.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var gols_a: int = int(a.get("gols_total", 0))
		var gols_b: int = int(b.get("gols_total", 0))

		if gols_a != gols_b:
			return gols_a > gols_b

		var vit_a: int = int(a.get("vitorias_total", 0))
		var vit_b: int = int(b.get("vitorias_total", 0))

		if vit_a != vit_b:
			return vit_a > vit_b

		var fase_a: int = int(a.get("fase_valor", 0))
		var fase_b: int = int(b.get("fase_valor", 0))

		if fase_a != fase_b:
			return fase_a > fase_b

		return str(a.get("nome", "")) < str(b.get("nome", ""))
	)

	return lista[0]


func _obter_melhor_campanha_da_tabela(tabela: Array) -> Dictionary:
	if tabela.is_empty():
		return {}

	# A tabela já vem ordenada por pódio, fase, vitórias, gols e pontos.
	return tabela[0]


func _criar_card_destaque_classificacao(
	pai: Control,
	titulo_txt: String,
	st: Dictionary,
	pos: Vector2,
	tam: Vector2,
	cor_base: Color,
	tipo: String
) -> void:
	var card := Panel.new()
	card.position = pos
	card.size = tam
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override(
		"panel",
		_style_panel(cor_base, Color(cor_base.r * 0.045, cor_base.g * 0.045, cor_base.b * 0.045, 0.985), 0.52)
	)
	pai.add_child(card)

	var W: float = tam.x
	var H: float = tam.y

	var titulo := _label(titulo_txt, 17, Color.WHITE, cor_base)
	titulo.position = Vector2(18, 8)
	titulo.size = Vector2(W - 36, 30)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.add_child(titulo)

	if st.is_empty():
		var vazio := _label("A DEFINIR", 22, Color(0.62, 0.68, 0.76))
		vazio.position = Vector2(0, 44)
		vazio.size = Vector2(W, 44)
		card.add_child(vazio)
		return

	var cor_j: Color = _cor_jogador_dict(st)

	var chip := Panel.new()
	chip.position = Vector2(24, 54)
	chip.size = Vector2(30, 30)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", _style_chip(cor_j))
	card.add_child(chip)

	var nome_txt: String = str(st.get("nome", "?"))

	var nome := _label(nome_txt, 24, Color.WHITE, cor_j)
	nome.position = Vector2(70, 42)
	nome.size = Vector2(W - 92, 36)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	nome.clip_text = true
	nome.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	nome.add_theme_constant_override("outline_size", 4)
	card.add_child(nome)

	var info_txt: String = ""

	if tipo == "goleador":
		info_txt = "%d GOLS  •  %d JOGOS  •  %d VITÓRIAS" % [
			int(st.get("gols_total", 0)),
			int(st.get("jogos_total", 0)),
			int(st.get("vitorias_total", 0))
		]
	else:
		info_txt = "%s  •  %d VITÓRIAS  •  %d GOLS" % [
			str(st.get("fase_nome", "GRUPOS")),
			int(st.get("vitorias_total", 0)),
			int(st.get("gols_total", 0))
		]

	var info := _label(info_txt, 15, Color(0.82, 0.91, 1.0))
	info.position = Vector2(70, 78)
	info.size = Vector2(W - 92, 28)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.clip_text = true
	card.add_child(info)


func _normalizar_ranking_lobby(fase_partida: String, ranking_recebido: Array) -> Array:
	var ranking: Array = []

	for item in ranking_recebido:
		if not (item is Dictionary):
			continue

		var j: Dictionary = item.duplicate(true)

		var gols_total: int = int(j.get("gols", j.get("score", 0)))
		var gols_normais: int = int(j.get("gols_normais", gols_total))
		var gols_prorro: int = int(j.get("gols_prorrogacao", 0))
		var penaltis: int = int(j.get("penaltis", 0))

		j["gols"] = gols_total
		j["score"] = gols_total
		j["gols_normais"] = gols_normais
		j["gols_prorrogacao"] = gols_prorro
		j["penaltis"] = penaltis

		ranking.append(j)

	ranking.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var total_a: int = int(a.get("gols", a.get("score", 0)))
		var total_b: int = int(b.get("gols", b.get("score", 0)))

		if total_a != total_b:
			return total_a > total_b

		var normal_a: int = int(a.get("gols_normais", total_a))
		var normal_b: int = int(b.get("gols_normais", total_b))

		if normal_a != normal_b:
			return normal_a > normal_b

		var prorro_a: int = int(a.get("gols_prorrogacao", 0))
		var prorro_b: int = int(b.get("gols_prorrogacao", 0))

		if prorro_a != prorro_b:
			return prorro_a > prorro_b

		var pen_a: int = int(a.get("penaltis", 0))
		var pen_b: int = int(b.get("penaltis", 0))

		if pen_a != pen_b:
			return pen_a > pen_b

		var gols_hist_a: int = _gols_acumulados_para_criterio_lobby(str(a.get("nome", "")))
		var gols_hist_b: int = _gols_acumulados_para_criterio_lobby(str(b.get("nome", "")))

		if gols_hist_a != gols_hist_b:
			return gols_hist_a > gols_hist_b

		var vit_a: int = _vitorias_para_criterio_lobby(str(a.get("nome", "")))
		var vit_b: int = _vitorias_para_criterio_lobby(str(b.get("nome", "")))

		if vit_a != vit_b:
			return vit_a > vit_b

		var bot_a: bool = bool(a.get("boot", false))
		var bot_b: bool = bool(b.get("boot", false))

		if bot_a != bot_b:
			return bot_b

		# Último critério: nome.
		return str(a.get("nome", "")) < str(b.get("nome", ""))
	)

	for i in range(ranking.size()):
		var posicao: int = i + 1
		ranking[i]["posicao"] = posicao

		if fase_partida == FASE_GRUPOS:
			ranking[i]["pontos_tabela"] = _pontos_grupo_por_empate(i, ranking)
		else:
			ranking[i]["pontos_tabela"] = 0

	return ranking

func _pontos_grupo_por_empate(index: int, ranking: Array) -> int:
	if index < 0 or index >= ranking.size():
		return 0

	var gols_ref: int = int(ranking[index].get("gols", ranking[index].get("score", 0)))

	# Regra oficial: empate com 0 gols recebe 0 pontos.
	if gols_ref <= 0:
		return 0

	var primeira_posicao_do_empate: int = index + 1

	for i in range(index - 1, -1, -1):
		var gols_i: int = int(ranking[i].get("gols", ranking[i].get("score", 0)))

		if gols_i == gols_ref:
			primeira_posicao_do_empate = i + 1
		else:
			break

	return _pontos_por_posicao(primeira_posicao_do_empate)


func _gols_acumulados_para_criterio_lobby(nome: String) -> int:
	var j: Dictionary = _buscar_jogador_por_nome(nome)

	if j.is_empty():
		return 0

	return int(j.get("gols", j.get("gols_pro", 0)))


func _vitorias_para_criterio_lobby(nome: String) -> int:
	var j: Dictionary = _buscar_jogador_por_nome(nome)

	if j.is_empty():
		return 0

	return int(j.get("vitorias", 0))
	


func _cobrir_tela_para_transicao() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 9999
	add_child(cl)

	var cover := ColorRect.new()
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.color = Color(0.004, 0.007, 0.014, 1.0)   # mesma cor base do loading, nunca cinza
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(cover)




# ============================================================
# MURAL DE CAMPEÕES — BANCO LOCAL DAS COPAS FINALIZADAS
# Salva TOP 3, estatísticas, data/hora e ID único.
# ============================================================
func _salvar_copa_finalizada_no_mural() -> void:
	if get_tree().has_meta("copa_mural_salva"):
		if bool(get_tree().get_meta("copa_mural_salva")):
			return

	var podio: Array = _obter_podio_final()

	if podio.is_empty():
		push_warning("Mural de Campeões: Copa finalizada sem pódio. Nada foi salvo.")
		return

	var db := get_node_or_null("/root/ChampionsDB")

	if db == null or not db.has_method("registrar_copa"):
		push_warning("Mural de Campeões: Autoload ChampionsDB não encontrado.")
		return

	var copa_id: String = ""

	if get_tree().has_meta("copa_mural_id"):
		copa_id = str(get_tree().get_meta("copa_mural_id"))

	if copa_id == "":
		if db.has_method("gerar_id"):
			copa_id = str(db.call("gerar_id"))
		else:
			copa_id = _gerar_id_copa_mural_fallback()

		get_tree().set_meta("copa_mural_id", copa_id)

	var top3: Array = []

	for i in range(min(3, podio.size())):
		var item: Dictionary = podio[i]
		top3.append(_normalizar_jogador_para_mural(item, i + 1))

	var tabela_completa: Array = _estatisticas_gerais_competicao()
	var top10_reais: Array = _filtrar_top10_jogadores_reais(tabela_completa, 10)

	var top10: Array = []

	for i in range(top10_reais.size()):
		var st: Dictionary = top10_reais[i]
		top10.append(_normalizar_jogador_para_mural(st, i + 1))

	var artilheiro: Dictionary = {}

	if not top10_reais.is_empty():
		var art: Dictionary = _obter_artilheiro_da_tabela(top10_reais)
		artilheiro = _normalizar_jogador_para_mural(art, int(art.get("colocacao_geral", 0)))

	var agora_iso: String = Time.get_datetime_string_from_system(false, false)
	var data_br: String = _formatar_data_hora_br_mural()

	var objeto_copa: Dictionary = {
		"id": copa_id,
		"tipo": "COPA",
		"titulo": "Copa dos Campeões",
		"criado_em_iso": agora_iso,
		"data_hora_br": data_br,
		"timestamp_unix": Time.get_unix_time_from_system(),

		"top3": top3,
		"top10": top10,

		"estatisticas": {
			"total_jogadores": _contar_jogadores_total_mural(),
			"total_jogadores_reais": _contar_jogadores_reais_mural(),
			"total_partidas": partidas.size(),
			"partidas_finalizadas": _contar_partidas_finalizadas_mural(),
			"fase_final": fase_atual,
			"campeao": top3[0] if top3.size() > 0 else {},
			"vice": top3[1] if top3.size() > 1 else {},
			"terceiro": top3[2] if top3.size() > 2 else {},
			"artilheiro": artilheiro
		}
	}

	var ok: bool = bool(db.call("registrar_copa", objeto_copa))

	if ok:
		get_tree().set_meta("copa_mural_salva", true)
		print("================================")
		print("COPA SALVA NO MURAL DE CAMPEÕES")
		print("ID: ", copa_id)
		print("DATA: ", data_br)
		print("================================")
	else:
		push_warning("Mural de Campeões: falha ao salvar Copa.")


func _normalizar_jogador_para_mural(j: Dictionary, posicao: int) -> Dictionary:
	var cor_j: Color = _cor_jogador_dict(j)

	return {
		"posicao": posicao,
		"nome": str(j.get("nome", "?")),
		"grupo": str(j.get("grupo", "")),
		"boot": bool(j.get("boot", false)),
		"cor_hex": _cor_para_hex_mural(cor_j),

		"gols_total": int(j.get("gols_total", j.get("gols", j.get("score", 0)))),
		"vitorias_total": int(j.get("vitorias_total", j.get("vitorias", 0))),
		"jogos_total": int(j.get("jogos_total", j.get("jogos", 0))),
		"penaltis_total": int(j.get("penaltis_total", j.get("penaltis", 0))),
		"pontos_grupo": int(j.get("pontos_grupo", j.get("pontos", 0))),
		"fase_nome": str(j.get("fase_nome", "")),
		"fase_valor": int(j.get("fase_valor", 0))
	}


func _cor_para_hex_mural(c: Color) -> String:
	var r: int = int(clampf(c.r, 0.0, 1.0) * 255.0)
	var g: int = int(clampf(c.g, 0.0, 1.0) * 255.0)
	var b: int = int(clampf(c.b, 0.0, 1.0) * 255.0)

	return "#%02x%02x%02x" % [r, g, b]


func _formatar_data_hora_br_mural() -> String:
	var d := Time.get_datetime_dict_from_system()

	return "%02d/%02d/%04d às %02d:%02d:%02d" % [
		int(d["day"]),
		int(d["month"]),
		int(d["year"]),
		int(d["hour"]),
		int(d["minute"]),
		int(d["second"])
	]


func _gerar_id_copa_mural_fallback() -> String:
	var d := Time.get_datetime_dict_from_system()

	return "CUP-%04d%02d%02d-%02d%02d%02d-%04d" % [
		int(d["year"]),
		int(d["month"]),
		int(d["day"]),
		int(d["hour"]),
		int(d["minute"]),
		int(d["second"]),
		randi_range(1000, 9999)
	]


func _contar_jogadores_total_mural() -> int:
	var nomes: Dictionary = {}

	for g in grupos:
		if not g.has("jogadores"):
			continue

		for j in g["jogadores"]:
			var nome: String = str(j.get("nome", "")).strip_edges()

			if nome != "":
				nomes[nome] = true

	return nomes.size()


func _contar_jogadores_reais_mural() -> int:
	var nomes: Dictionary = {}

	for g in grupos:
		if not g.has("jogadores"):
			continue

		for j in g["jogadores"]:
			if bool(j.get("boot", false)):
				continue

			var nome: String = str(j.get("nome", "")).strip_edges()

			if nome != "":
				nomes[nome] = true

	return nomes.size()


func _contar_partidas_finalizadas_mural() -> int:
	var total: int = 0

	for p in partidas:
		if bool(p.get("finalizada", false)):
			total += 1

	return total


func _garantir_id_copa_atual() -> void:
	var cg := get_node_or_null("/root/CupGlobal")

	if cg != null and cg.has_meta("copa_id_atual"):
		copa_id_atual = str(cg.get_meta("copa_id_atual"))
	elif get_tree().has_meta("copa_id_atual"):
		copa_id_atual = str(get_tree().get_meta("copa_id_atual"))
	else:
		var db := get_node_or_null("/root/ChampionsDb")

		if db != null and db.has_method("criar_id_copa"):
			copa_id_atual = str(db.criar_id_copa())
		else:
			var d := Time.get_datetime_dict_from_system()
			copa_id_atual = "CUP_%04d%02d%02d_%02d%02d%02d_%06d" % [
				int(d["year"]),
				int(d["month"]),
				int(d["day"]),
				int(d["hour"]),
				int(d["minute"]),
				int(d["second"]),
				int(Time.get_ticks_msec() % 1000000)
			]

	get_tree().set_meta("copa_id_atual", copa_id_atual)

	if cg != null:
		cg.set_meta("copa_id_atual", copa_id_atual)


func _registrar_copa_no_mural() -> void:
	if copa_id_atual == "":
		_garantir_id_copa_atual()

	var cg := get_node_or_null("/root/CupGlobal")

	if get_tree().has_meta("copa_mural_salva_id"):
		if str(get_tree().get_meta("copa_mural_salva_id")) == copa_id_atual:
			return

	if cg != null and cg.has_meta("copa_mural_salva_id"):
		if str(cg.get_meta("copa_mural_salva_id")) == copa_id_atual:
			return

	var db := get_node_or_null("/root/ChampionsDb")

	if db == null:
		push_warning("Mural de Campeões não salvou: ChampionsDb não está no Autoload.")
		return

	if not db.has_method("registrar_copa"):
		push_warning("Mural de Campeões não salvou: ChampionsDb não tem registrar_copa().")
		return

	var registro: Dictionary = _criar_registro_mural_copa()

	if registro.is_empty():
		push_warning("Mural de Campeões não salvou: registro vazio.")
		return

	var salvo: Dictionary = db.registrar_copa(registro)
	var id_salvo: String = str(salvo.get("id", copa_id_atual))

	get_tree().set_meta("copa_mural_salva_id", id_salvo)

	if cg != null:
		cg.set_meta("copa_mural_salva_id", id_salvo)

	print("================================")
	print("COPA SALVA NO MURAL DE CAMPEÕES")
	print("ID: ", id_salvo)
	print("================================")


func _criar_registro_mural_copa() -> Dictionary:
	var podio: Array = _obter_podio_final()

	if podio.is_empty():
		return {}

	var d := Time.get_datetime_dict_from_system()
	var unix: float = Time.get_unix_time_from_system()

	var top3: Array = []
	var gols_top3: int = 0

	for i in range(min(3, podio.size())):
		var item: Dictionary = podio[i]
		var cor: Color = _cor_jogador_dict(item)

		var gols_total: int = int(item.get("gols_total", item.get("gols", item.get("score", 0))))
		var vitorias_total: int = int(item.get("vitorias_total", item.get("vitorias", 0)))
		var jogos_total: int = int(item.get("jogos_total", 0))
		var penaltis_total: int = int(item.get("penaltis_total", item.get("penaltis", 0)))

		gols_top3 += gols_total

		top3.append({
			"posicao": i + 1,
			"nome": str(item.get("nome", "?")),
			"boot": bool(item.get("boot", false)),
			"grupo": str(item.get("grupo", "")),
			"fase_nome": str(item.get("fase_nome", "")),
			"gols_total": gols_total,
			"vitorias_total": vitorias_total,
			"jogos_total": jogos_total,
			"pontos_grupo": int(item.get("pontos_grupo", item.get("pontos", 0))),
			"penaltis_total": penaltis_total,
			"cor_rgba": _cor_para_json_mural(cor)
		})

	var jogadores_reais: int = 0

	for g in grupos:
		for j in g.get("jogadores", []):
			if not bool(j.get("boot", false)):
				jogadores_reais += 1

	var registro := {
		"id": copa_id_atual,
		"schema_version": 1,
		"titulo": "Copa %02d/%02d/%04d %02d:%02d" % [
			int(d["day"]),
			int(d["month"]),
			int(d["year"]),
			int(d["hour"]),
			int(d["minute"])
		],
		"finished_at_unix": unix,
		"finished_at_text": "%02d/%02d/%04d às %02d:%02d" % [
			int(d["day"]),
			int(d["month"]),
			int(d["year"]),
			int(d["hour"]),
			int(d["minute"])
		],
		"top3": top3,
		"resumo": {
			"partidas_total": partidas.size(),
			"grupos_total": grupos.size(),
			"jogadores_reais": jogadores_reais,
			"gols_top3": gols_top3,
			"fase_final": fase_atual
		}
	}

	return registro


func _cor_para_json_mural(c: Color) -> Array:
	return [c.r, c.g, c.b, c.a]


# ============================================================
# AÇÕES START / CUP NO LOBBY
# ============================================================
func _on_start_lobby() -> void:
	var prox: int = _buscar_proxima_partida_pendente()

	# Se existe partida pendente, mas o jogador está vendo uma fase antiga,
	# START primeiro avança visualmente até a fase atual.
	# Exemplo: está na SEMIFINAL, voltou para GRUPOS:
	# START -> TOP 8
	# START -> SEMIFINAL
	# START -> inicia a partida
	if prox >= 0:
		if fase_visualizada != fase_atual:
			var prox_fase: String = _proxima_fase_acessivel(fase_visualizada)

			if prox_fase != fase_visualizada:
				fase_visualizada = prox_fase
				_tocar_select_cup()
				_montar_tela_lobby()
				return

		_tocar_confirm_cup()
		_iniciar_partida(prox)
		return

	# Competição finalizada.
	if fase_visualizada == FASE_FINAL:
		_tocar_confirm_cup()
		_mostrar_podio(false)
		return

	var proxima: String = _proxima_fase_acessivel(fase_visualizada)

	if proxima != fase_visualizada:
		fase_visualizada = proxima
		_tocar_select_cup()
		_montar_tela_lobby()
	else:
		_tocar_confirm_cup()
		_mostrar_podio(false)



func _nome_fase_footer(fase: String) -> String:
	match fase:
		FASE_GRUPOS:
			return "GRUPOS"
		FASE_OITAVAS:
			return "TOP 8"
		FASE_SEMIFINAL:
			return "SEMIFINAL"
		FASE_FINAL:
			return "FINAL"
		_:
			return str(fase)


func _on_cup_lobby() -> void:
	var ant: String = _fase_acessivel_anterior(fase_visualizada)

	if ant != fase_visualizada:
		fase_visualizada = ant
		_tocar_select_cup()
		_montar_tela_lobby()


func _fases_acessiveis_ordenadas() -> Array:
	var ordem: Array[String] = [FASE_GRUPOS, FASE_OITAVAS, FASE_SEMIFINAL, FASE_FINAL]
	var saida: Array = []

	for f in ordem:
		if _estado_visual_fase(f) != "BLOQUEADA":
			saida.append(f)

	return saida


func _proxima_fase_acessivel(atual: String) -> String:
	var lista: Array = _fases_acessiveis_ordenadas()
	var idx: int = lista.find(atual)

	if idx == -1:
		return atual

	if idx + 1 < lista.size():
		return lista[idx + 1]

	return atual


func _fase_acessivel_anterior(atual: String) -> String:
	var lista: Array = _fases_acessiveis_ordenadas()
	var idx: int = lista.find(atual)

	if idx <= 0:
		return atual

	return lista[idx - 1]


# ============================================================
# PÓDIO: SEGURAR START PARA VOLTAR À TELA INICIAL
# ============================================================
func _processar_hold_podio(delta: float) -> void:
	if tela_modo != "PODIO":
		return

	if podio_indo_opening:
		return

	var apertado: bool = InputMap.has_action("input_start") and Input.is_action_pressed("input_start")

	# Exige soltar o START antes de começar a contar
	# (evita que o mesmo toque que abriu o pódio já dispare o retorno).
	if podio_aguardando_soltar_start:
		if apertado:
			return
		podio_aguardando_soltar_start = false

	if apertado:
		podio_hold_start += delta
		_atualizar_hold_podio()

		if podio_hold_start >= PODIO_HOLD_SEGUNDOS:
			podio_indo_opening = true
			_tocar_confirm_cup()
			_retornar_opening()
	else:
		if podio_hold_start > 0.0:
			podio_hold_start = 0.0
			_atualizar_hold_podio()


func _atualizar_hold_podio() -> void:
	if podio_hold_barra == null or not is_instance_valid(podio_hold_barra):
		return

	var frac: float = clampf(podio_hold_start / PODIO_HOLD_SEGUNDOS, 0.0, 1.0)
	podio_hold_barra.size.x = podio_hold_barra_w * frac

	if podio_hold_label and is_instance_valid(podio_hold_label):
		if frac > 0.02:
			podio_hold_label.text = "CONTINUE SEGURANDO START  •  SOLTAR CANCELA"
		else:
			podio_hold_label.text = "SEGURE START PARA VOLTAR À TELA INICIAL"


func _criar_hud_hold_podio(vp: Vector2) -> void:
	var box_w: float = 600.0
	var box_h: float = 70.0
	var box_x: float = (vp.x - box_w) * 0.5
	var box_y: float = vp.y - box_h - 14.0

	var painel := Panel.new()
	painel.position = Vector2(box_x, box_y)
	painel.size = Vector2(box_w, box_h)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_theme_stylebox_override(
		"panel",
		_style_panel(COR_NEON, Color(0.010, 0.016, 0.028, 0.94), 0.52)
	)
	ui_root.add_child(painel)

	podio_hold_label = _label("SEGURE START PARA VOLTAR À TELA INICIAL", 17, COR_NEON, COR_NEON)
	podio_hold_label.position = Vector2(18, 8)
	podio_hold_label.size = Vector2(box_w - 36, 30)
	painel.add_child(podio_hold_label)

	var barra_bg := ColorRect.new()
	barra_bg.position = Vector2(24, 48)
	barra_bg.size = Vector2(box_w - 48, 8)
	barra_bg.color = Color(1, 1, 1, 0.12)
	barra_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(barra_bg)

	podio_hold_barra_w = barra_bg.size.x

	podio_hold_barra = ColorRect.new()
	podio_hold_barra.position = barra_bg.position
	podio_hold_barra.size = Vector2(0, 8)
	podio_hold_barra.color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 1.0)
	podio_hold_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(podio_hold_barra)


func _processar_mouse_hibernacao(delta: float) -> void:
	var pos_atual: Vector2 = get_viewport().get_mouse_position()

	if not mouse_pos_inicializada:
		mouse_pos_anterior = pos_atual
		mouse_pos_inicializada = true
		_set_mouse_arcade_visivel(false)
		return

	var moveu: bool = pos_atual.distance_to(mouse_pos_anterior) >= MOUSE_MOVIMENTO_MINIMO

	if moveu:
		mouse_pos_anterior = pos_atual
		mouse_hibernacao_timer = 0.0
		_set_mouse_arcade_visivel(true)
		return

	if mouse_arcade_visivel:
		mouse_hibernacao_timer += delta

		if mouse_hibernacao_timer >= MOUSE_HIBERNAR_SEGUNDOS:
			_set_mouse_arcade_visivel(false)


func _set_mouse_arcade_visivel(visivel: bool) -> void:
	mouse_arcade_visivel = visivel

	# Cursor real sempre escondido.
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	# Seu ponteiro customizado aparece só quando o mouse se mexe.
	if ponteiro != null and is_instance_valid(ponteiro):
		ponteiro.visible = visivel



func _adicionar_placar_knockout_profissional(
	pai: Control,
	item: Dictionary,
	pos: Vector2,
	tam: Vector2,
	cor_j: Color,
	eliminado: bool
) -> void:
	var total: int = int(item.get("gols", item.get("score", 0)))
	var normais: int = int(item.get("gols_normais", total))
	var prorro: int = int(item.get("gols_prorrogacao", 0))
	var pen: int = int(item.get("penaltis", 0))

	var jogou_ot: bool = bool(item.get("jogou_prorrogacao", false)) or prorro > 0
	var jogou_pen: bool = bool(item.get("jogou_penaltis", false)) or pen > 0
	var tem_extra: bool = jogou_ot or jogou_pen

	var box := Panel.new()
	box.position = pos
	box.size = tam
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.clip_contents = true

	var st := StyleBoxFlat.new()

	if eliminado:
		st.bg_color = Color(0.025, 0.026, 0.030, 0.92)
		st.border_color = Color(0.30, 0.31, 0.35, 0.90)
		st.shadow_color = Color.TRANSPARENT
	else:
		st.bg_color = Color(cor_j.r * 0.10, cor_j.g * 0.10, cor_j.b * 0.10, 0.92)
		st.border_color = Color(cor_j.r, cor_j.g, cor_j.b, 0.78)
		st.shadow_color = Color(cor_j.r, cor_j.g, cor_j.b, 0.22)

	st.set_border_width_all(1)
	st.set_corner_radius_all(8)
	st.shadow_size = 6
	st.shadow_offset = Vector2.ZERO
	box.add_theme_stylebox_override("panel", st)
	pai.add_child(box)

	var cor_texto: Color = Color.WHITE
	var sombra: Color = cor_j

	if eliminado:
		cor_texto = Color(0.52, 0.54, 0.58)
		sombra = Color.TRANSPARENT

	if not tem_extra:
		var unico := _label(str(total), int(clampf(tam.y * 0.56, 12.0, 22.0)), cor_texto, sombra)
		unico.position = Vector2.ZERO
		unico.size = tam
		unico.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
		unico.add_theme_constant_override("outline_size", 3)
		box.add_child(unico)
		return

	var detalhe: String = ""

	if jogou_ot and jogou_pen:
		detalhe = "%d+%d P%d" % [normais, prorro, pen]
	elif jogou_ot:
		detalhe = "%d+%d" % [normais, prorro]
	elif jogou_pen:
		detalhe = "P%d" % pen

	var total_lbl := _label(str(total), int(clampf(tam.y * 0.42, 11.0, 18.0)), cor_texto, sombra)
	total_lbl.position = Vector2(0, -2)
	total_lbl.size = Vector2(tam.x, tam.y * 0.55)
	total_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	total_lbl.add_theme_constant_override("outline_size", 3)
	box.add_child(total_lbl)

	var det_lbl := _label(detalhe, int(clampf(tam.y * 0.24, 8.0, 11.0)), Color(0.78, 0.88, 1.0))
	det_lbl.position = Vector2(2, tam.y * 0.48)
	det_lbl.size = Vector2(tam.x - 4, tam.y * 0.48)
	det_lbl.clip_text = true
	det_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
	det_lbl.add_theme_constant_override("outline_size", 2)
	box.add_child(det_lbl)
