extends Node2D

# ============================================================
# TORMENT PLAY — PARTIDAS DO TORNEIO 36
#
# Lê a partida enviada pelo torment_lobby:
# - get_tree().get_meta("partida_torneio_atual")
# - get_tree().get_meta("torneio_partida_atual_index")
#
# Suporta:
# - 6 jogadores na fase 3x3.
# - 2 jogadores nas fases mata-mata.
# - Bots automáticos.
# - Empate entre jogadores reais vai DIRETO PARA PÊNALTIS.
# - NÃO TEM PRORROGAÇÃO.
#
# Retorna ao torment_lobby usando:
# get_tree().set_meta("resultado_torneio_pendente", {...})
#
# CTRL + TAB fecha o jogo.
# ============================================================

const CENA_TORMENT_LOBBY: String = "res://scenes/torment_lobby.tscn"

const FONTE_ORBITRON: String = "res://fonts/orbitron-bold.ttf"

const MUSICA_PLAY: String = "res://songs/song_fut_play.mp3"
const SFX_PONTO: String = "res://songs/goal.mp3"
const SFX_APITO_INIT: String = "res://songs/apito_init.mp3"
const SFX_APITO_TROCA: String = "res://songs/apito_troca.mp3"
const SFX_APITO_FIM: String = "res://songs/apito_fim.mp3"
const SFX_GAME_START: String = "res://songs/game_start.mp3"
const SFX_CAMPEAO: String = "res://songs/campeao.mp3"

const VOLUME_TORCIDA_PADRAO_DB: float = 0.0
const VOLUME_TORCIDA_123_DB: float = 6.5
const VOLUME_TORCIDA_ERRO_DB: float = 0.0

const MUSICAS_PLAYERS: Array[String] = [
	"res://songs/player_song1.mp3",
	"res://songs/player_song2.mp3",
	"res://songs/player_song3.mp3",
	"res://songs/player_song4.mp3",
	"res://songs/player_song5.mp3",
]


const SFX_GOOD_PLAYER: Array[String] = [
	"res://songs/good_player.mp3",
	"res://songs/good_player2.mp3"
]

const IMAGEM_FUNDO_FOOTER_PATRO: String = "res://fundos/fundo_logos.png"

const PATROCINADORES_FIXOS: Array[String] = [
	"res://patro/logoofi.png",
	"res://patro/bar.png",
	"res://patro/bud.png",
	"res://patro/corona_logo.png",
	"res://patro/GA_Logo.png",
	"res://patro/Michelob-Ultra_stacked-color-Logo.png",
	"res://patro/stella.png",
]

const SFX_TORCIDA_GOL: Array[String] = [
	"res://songs/torcida_1.mp3",
	"res://songs/torcida_2.mp3",
	"res://songs/torcida_3.mp3",
	"res://songs/good_player1.mp3",
	"res://songs/good_player2.mp3",
	"res://songs/leleo.mp3"
]

const SFX_TORCIDA_ERRO: Array[String] = [
	"res://songs/not_supress.mp3",
	"res://songs/vaia_1.mp3",
	"res://songs/vaia_2.mp3"
]

const SFX_INICIO_HYPE: Array[String] = [
	"res://songs/good_player1.mp3",
	"res://songs/good_player2.mp3",
	"res://songs/leleo.mp3"
]

const IMAGEM_LOADING: String = "res://images/loading.png"
const IMAGEM_FUNDO_STADIO: String = "res://images/back_stadio.png"
const FUNDO_RESULT: String = "res://fundos/fundo_result.png"

const FUNDO_CARD_AZUL: String = "res://fundos/azul.png"
const FUNDO_CARD_VERDE: String = "res://fundos/verde.png"
const FUNDO_CARD_VERMELHO: String = "res://fundos/vermelho.png"
const FUNDO_CARD_AMARELO: String = "res://fundos/amarelo.png"

const FUNDO_PREP_VERMELHO: String = "res://fundos/red.png"
const FUNDO_PREP_AMARELO: String  = "res://fundos/yellow.png"
const FUNDO_PREP_AZUL: String     = "res://fundos/blue.png"
const FUNDO_PREP_VERDE: String    = "res://fundos/green.png"

const TEMPO_PLAYER_REAL: float = 60.0
const TEMPO_PLAYER_BOT_FASE1: float = 6.0
const TEMPO_PLAYER_BOT_MATA: float = 9.0
const TEMPO_PLAYER_BOT_FINAL: float = 12.0

const TEMPO_CONTAGEM_INICIAL: int = 3
const START_DEBOUNCE_MS: float = 500.0

const AUTO_START_BOT: bool = true
const AUTO_START_DELAY_BOT: float = 0.55

const BOT_JOGA_SOZINHO: bool = true
const BOT_INTERVALO_GOL_MIN: float = 0.45
const BOT_INTERVALO_GOL_MAX: float = 0.95

const LEDS_TOTAL: int = 7
const LEDS_ATIVOS_MIN: int = 2
const LEDS_ATIVOS_MAX: int = 2
const LEDS_LETRAS: Array[String] = ["A", "B", "C", "D", "E", "F", "G"]
const CICLO_LEDS_MS: float = 3000.0


const PONTOS_MINIMOS_SEM_VAIA: int = 15

const COMBO_GOLS_PARA_SOM: int = 4
const COMBO_JANELA_MS: float = 2300.0
const COMBO_COOLDOWN_MS: float = 3200.0

const USAR_ARDUINO: bool = true
const USAR_PONTE_POWERSHELL: bool = true
const SERIAL_PORTA: String = "COM5"
const SERIAL_BAUD: int = 9600

const MOSTRAR_TECLAS_LED_HUD: bool = false

const PENALTI_QTD_BOCAS: int = 1
const PENALTI_TEMPO_ACERTO: float = 3.0
const PENALTI_RODADAS_INICIAIS: int = 2
const PENALTI_PROB_BOT: float = 0.60

const COR_OK: Color = Color(0.22, 0.95, 0.58)
const COR_ALERTA: Color = Color(1.00, 0.78, 0.18)
const COR_ERRO: Color = Color(1.00, 0.22, 0.22)
const COR_NEON: Color = Color(0.25, 0.72, 1.00)
const COR_TORNEIO: Color = Color(0.62, 0.30, 1.0)
const COR_BOOT: Color = Color(0.48, 0.54, 0.64)

const CORES_ALVOS_RGB: Array = [
	[255, 255, 0],
	[255, 0, 0],
	[0, 255, 0],
	[0, 0, 255]
]

enum FaseJogo { NORMAL, PENALTIS }

var fonte_orbitron: Font

var partida_torneio: Dictionary = {}
var jogadores_torneio: Array = []
var nomes_players: Array[String] = []

var partida_index: int = 0
var fase_torneio: String = "FASE_1"
var fase_nome: String = "FASE 1"
var chave_nome: String = "A"
var nome_partida: String = "PARTIDA"
var modo_partida: String = "3X3"

var total_players: int = 0
var player_atual: int = 0

var somente_penaltis: bool = false


var scores: Array[int] = []
var tempos: Array[float] = []
var terminou_player: Array[bool] = []

var gols_normais: Array[int] = []

var ida_volta: bool = false
var jogo_atual_confronto: int = 1 # 1 = ida, 2 = volta

var gols_ida: Array[int] = []
var gols_volta: Array[int] = []
var gols_agregado: Array[int] = []

var confronto_decidido_penaltis: bool = false
var vencedor_penaltis_index: int = -1

var penaltis_marcados: Array[int] = []
var jogou_penaltis: Array[bool] = []

var fase_jogo: int = FaseJogo.NORMAL

var partida_ativa: bool = false
var aguardando_start_turno: bool = false
var em_contagem_inicio: bool = false
var partida_finalizada: bool = false
var fechando_jogo: bool = false

var _ultimo_start_ms: float = -99999.0
var _ciclo_inicio_ms: float = 0.0

var leds_ativos: Array[int] = []
var cores_leds_ativos: Dictionary = {}
var _dupla_anterior: Array[int] = []


var sfx_good_player: Array[AudioStreamPlayer] = []
var _ultimo_sfx_good: int = -1

var bot_timer_gol: float = 0.0
var bot_proximo_gol_em: float = 0.0
var auto_start_token: int = 0

var _pen_aguardando: bool = false
var _pen_alvos: Array[int] = []
var _pen_resultado: int = 0

var cores_players: Array[Color] = [
	Color(1.00, 0.20, 0.20),
	Color(0.20, 0.92, 0.32),
	Color(0.12, 0.58, 1.00),
	Color(1.00, 0.84, 0.10),
	Color(1.00, 0.35, 0.95),
	Color(0.25, 1.00, 0.95)
]


var partida_id: String = ""

var _combo_gols_seguidos: int = 0
var _ultimo_combo_gol_ms: float = 0.0
var _ultimo_combo_som_ms: float = 0.0

var sfx_torcida_gol: Array[AudioStreamPlayer] = []
var sfx_torcida_erro: Array[AudioStreamPlayer] = []

var _ultimo_sfx_gol: int = -1
var _ultimo_sfx_erro: int = -1

var canvas: CanvasLayer
var root: Control

var player_panels: Array[Panel] = []
var score_labels: Array[Label] = []
var tempo_labels: Array[Label] = []
var status_labels: Array[Label] = []
var pos_labels: Array[Label] = []

var overlay_layer: CanvasLayer
var overlay_fundo: ColorRect
var overlay_panel: Panel
var overlay_titulo: Label
var overlay_numero: Label
var overlay_subtitulo: Label
var overlay_fundo_img: TextureRect

var leds_hud_layer: CanvasLayer
var leds_hud_root: Control
var leds_botoes: Array[Panel] = []
var leds_labels: Array[Label] = []

var loading_layer: CanvasLayer
var loading_root: Control
var loading_label: Label
var loading_sub: Label
var loading_pct: Label
var loading_barra: ColorRect
var loading_barra_w_max: float = 0.0
var loading_frac_atual: float = 0.0
var tween_loading_barra: Tween = null

var final_layer: CanvasLayer

var pen_layer: CanvasLayer = null
var pen_panel: Panel = null
var pen_titulo: Label = null
var pen_rodada: Label = null
var pen_chutador: Label = null
var pen_contagem: Label = null
var pen_feedback: Label = null
var pen_cards_box: HBoxContainer = null
var pen_card_score_labels: Dictionary = {}
var pen_card_status_labels: Dictionary = {}
var pen_card_panels: Dictionary = {}
var pen_participantes: Array[int] = []

var audio_fundo: AudioStreamPlayer
var musicas_por_player: Array = []
var _prep_piscar_ligado: bool = false
var _prep_piscar_token: int = 0

var sfx_ponto: AudioStreamPlayer
var sfx_apito_init: AudioStreamPlayer
var sfx_apito_troca: AudioStreamPlayer
var sfx_apito_fim: AudioStreamPlayer
var sfx_game_start: AudioStreamPlayer
var sfx_campeao: AudioStreamPlayer

var caminho_fila_arduino: String = ""
var caminho_log_arduino: String = ""
var caminho_script_arduino: String = ""
var ponte_ps_pid: int = -1

var sfx_inicio_hype: Array[AudioStreamPlayer] = []
var _ultimo_sfx_inicio: int = -1


# ============================================================
# READY / PROCESS
# ============================================================
func _ready() -> void:
	get_tree().auto_accept_quit = false
	randomize()

	_travar_modo_arcade()

	_criar_tela_carregamento("CARREGANDO PARTIDA", "INICIANDO TORNEIO...")
	_set_progresso_carregamento(0.06, "INICIANDO TORNEIO...", 0.20)

	await get_tree().process_frame

	# Abre a ponte do Arduino LOGO no começo, para os LEDs roxos
	# já acenderem no INÍCIO do carregamento (e não só no fim).
	_set_progresso_carregamento(0.25, "CONECTANDO LEDS...", 0.30)
	await _abrir_serial_arduino()

	# LEDs roxos/neon durante todo o restante do loading,
	# igual ao loading de volta do lobby.
	_leds_loading_roxo_on()

	_carregar_fontes()

	_set_progresso_carregamento(0.45, "CARREGANDO ÁUDIOS...", 0.20)
	_criar_audios()
	await get_tree().create_timer(0.12).timeout

	_set_progresso_carregamento(0.62, "LENDO PARTIDA...", 0.20)
	_carregar_partida_torneio()
	_inicializar_dados()
	_sortear_musicas_players()
	await get_tree().create_timer(0.12).timeout

	_set_progresso_carregamento(0.85, "MONTANDO ARENA...", 0.22)
	_criar_tela()
	await get_tree().process_frame

	_set_progresso_carregamento(1.0, "TUDO PRONTO!", 0.25)
	await get_tree().create_timer(0.35).timeout
	await _remover_tela_carregamento()

	if somente_penaltis:
		await _iniciar_penaltis_direto_da_partida()
	else:
		_mostrar_preparacao_player()



func _iniciar_penaltis_direto_da_partida() -> void:
	if total_players < 2:
		await _finalizar_partida()
		return

	await get_tree().create_timer(0.35).timeout

	await _mostrar_aviso_turno(
		"PÊNALTIS",
		"EMPATE NO AGREGADO  •  DECISÃO DIRETA",
		COR_ALERTA
	)

	await _rodar_penaltis([0, 1])
	await _finalizar_partida()


func _process(delta: float) -> void:
	if partida_finalizada:
		return

	if fase_jogo == FaseJogo.PENALTIS:
		_ler_inputs_leds()
		return

	if aguardando_start_turno:
		if _start_foi_pressionado():
			_iniciar_contagem_turno()
		return

	if not partida_ativa:
		return

	_checar_ciclo_leds()
	_ler_inputs_leds()
	_processar_bot(delta)

	if player_atual < 0 or player_atual >= total_players:
		return

	tempos[player_atual] -= delta

	if tempos[player_atual] <= 0.0:
		tempos[player_atual] = 0.0
		_finalizar_turno_player()
		return

	_atualizar_hud()


# ============================================================
# CONFIGURAÇÃO DA PARTIDA
# ============================================================
func _carregar_partida_torneio() -> void:
	partida_torneio.clear()
	jogadores_torneio.clear()
	nomes_players.clear()

	if get_tree().has_meta("partida_torneio_atual"):
		var p_meta: Variant = get_tree().get_meta("partida_torneio_atual")

		if p_meta is Dictionary:
			partida_torneio = (p_meta as Dictionary).duplicate(true)

	if partida_torneio.is_empty() and get_tree().has_meta("torneio_partida_atual"):
		var p_meta2: Variant = get_tree().get_meta("torneio_partida_atual")

		if p_meta2 is Dictionary:
			partida_torneio = (p_meta2 as Dictionary).duplicate(true)

	if get_tree().has_meta("torneio_partida_atual_index"):
		partida_index = int(get_tree().get_meta("torneio_partida_atual_index"))
	else:
		partida_index = int(partida_torneio.get("partida_index", 0))

	if get_tree().has_meta("torneio_partida_atual_id"):
		partida_id = str(get_tree().get_meta("torneio_partida_atual_id"))
	else:
		partida_id = str(partida_torneio.get("partida_id", partida_torneio.get("id", "")))

	if partida_torneio.is_empty():
		push_warning("TORMENT PLAY: nenhuma partida recebida. Criando fallback.")
		_criar_fallback()
		return

	fase_torneio = str(partida_torneio.get("fase", "FASE_1"))
	fase_nome = str(partida_torneio.get("fase_nome", _nome_fase(fase_torneio)))
	chave_nome = str(partida_torneio.get("chave", "-"))
	nome_partida = str(partida_torneio.get("nome", "PARTIDA"))
	modo_partida = str(partida_torneio.get("modo", "3X3"))
	ida_volta = bool(partida_torneio.get("ida_volta", false))
	somente_penaltis = bool(partida_torneio.get("somente_penaltis", false))

	# Segurança: só usa ida e volta no mata-mata 1x1.
	if modo_partida != "1X1":
		ida_volta = false

	if partida_torneio.has("jogadores") and partida_torneio["jogadores"] is Array:
		jogadores_torneio = partida_torneio["jogadores"].duplicate(true)

	if jogadores_torneio.is_empty():
		_criar_fallback()
		return

	total_players = clampi(jogadores_torneio.size(), 1, 6)

	for i in range(total_players):
		var j: Dictionary = jogadores_torneio[i]

		nomes_players.append(str(j.get("nome", "PLAYER %d" % (i + 1))))

		if j.has("cor") and j["cor"] is Color:
			cores_players[i] = j["cor"]

	print("================================")
	print("TORMENT PLAY CONFIGURADO")
	print("FASE: ", fase_torneio)
	print("NOME FASE: ", fase_nome)
	print("CHAVE: ", chave_nome)
	print("PARTIDA: ", nome_partida)
	print("MODO: ", modo_partida)
	print("PARTIDA INDEX: ", partida_index)
	print("TOTAL PLAYERS: ", total_players)
	print("NOMES: ", nomes_players)
	print("================================")


func _criar_fallback() -> void:
	partida_index = 0
	fase_torneio = "FASE_1"
	fase_nome = "FASE 1"
	chave_nome = "A"
	nome_partida = "PARTIDA TESTE"
	modo_partida = "3X3"

	jogadores_torneio.clear()
	nomes_players.clear()

	for i in range(6):
		jogadores_torneio.append({
			"nome": "Boot %d" % (i + 1),
			"cor": cores_players[i],
			"cor_nome": "BOT",
			"boot": true
		})
		nomes_players.append("Boot %d" % (i + 1))

	total_players = 6


func _inicializar_dados() -> void:
	scores.clear()
	tempos.clear()
	terminou_player.clear()
	gols_normais.clear()
	penaltis_marcados.clear()
	jogou_penaltis.clear()

	gols_ida.clear()
	gols_volta.clear()
	gols_agregado.clear()

	for i in range(total_players):
		scores.append(0)
		tempos.append(_tempo_do_player(i))
		terminou_player.append(false)

		gols_normais.append(0)
		penaltis_marcados.append(0)
		jogou_penaltis.append(false)

		gols_ida.append(0)
		gols_volta.append(0)
		gols_agregado.append(0)

	player_atual = 0
	partida_ativa = false
	aguardando_start_turno = false
	em_contagem_inicio = false
	partida_finalizada = false
	fase_jogo = FaseJogo.NORMAL

	jogo_atual_confronto = 1
	confronto_decidido_penaltis = false
	vencedor_penaltis_index = -1

	leds_ativos.clear()
	cores_leds_ativos.clear()
	_dupla_anterior.clear()
	_ciclo_inicio_ms = 0.0

	_pen_aguardando = false
	_pen_alvos.clear()
	_pen_resultado = 0

	bot_timer_gol = 0.0
	bot_proximo_gol_em = 0.0
	auto_start_token = 0

	_combo_gols_seguidos = 0
	_ultimo_combo_gol_ms = 0.0
	_ultimo_combo_som_ms = 0.0



# ============================================================
# INPUT
# ============================================================
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	if not event.pressed or event.echo:
		return

	var vp := get_viewport()

	if event.ctrl_pressed and event.keycode == KEY_TAB:
		if vp:
			vp.set_input_as_handled()

		_fechar_jogo_arcade()
		return

	if event.keycode == KEY_ESCAPE:
		if vp:
			vp.set_input_as_handled()
		return

	if event.keycode == KEY_META:
		if vp:
			vp.set_input_as_handled()
		return

	if event.alt_pressed and event.keycode in [KEY_F4, KEY_TAB]:
		if vp:
			vp.set_input_as_handled()
		return

	if event.ctrl_pressed and event.keycode == KEY_ESCAPE:
		if vp:
			vp.set_input_as_handled()
		return

	var mapa_teclas := {
		KEY_A: 0,
		KEY_S: 1,
		KEY_D: 2,
		KEY_F: 3,
		KEY_G: 4,
		KEY_H: 5,
		KEY_J: 6
	}

	if mapa_teclas.has(event.keycode):
		if vp:
			vp.set_input_as_handled()

		_processar_input_led(int(mapa_teclas[event.keycode]))
		return


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ESCAPE, KEY_META]:
			get_viewport().set_input_as_handled()
			return

		if event.alt_pressed and event.keycode in [KEY_F4, KEY_TAB]:
			get_viewport().set_input_as_handled()
			return


func _start_foi_pressionado() -> bool:
	if not Input.is_action_just_pressed("input_start"):
		return false

	var agora := float(Time.get_ticks_msec())

	if agora - _ultimo_start_ms < START_DEBOUNCE_MS:
		return false

	_ultimo_start_ms = agora
	return true


func _ler_inputs_leds() -> void:
	for i in range(LEDS_TOTAL):
		var acao := "input_led_" + LEDS_LETRAS[i].to_lower()

		if Input.is_action_just_pressed(acao):
			_processar_input_led(i)


# ============================================================
# TELA PRINCIPAL
# ============================================================
func _criar_tela() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)

	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)

	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.006, 0.008, 0.014, 1.0)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fundo)

	_adicionar_fundo_stadio()
	_criar_header()
	_criar_overlay_turno()
	_reconstruir_paineis()
	_criar_hud_leds()


func _criar_header() -> void:
	var tela := get_viewport().get_visible_rect().size

	var header := Panel.new()
	header.position = Vector2.ZERO
	header.size = Vector2(tela.x, 82)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(header)

	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.014, 0.018, 0.030, 0.96)
	s.border_color = Color(COR_TORNEIO.r, COR_TORNEIO.g, COR_TORNEIO.b, 0.70)
	s.set_border_width_all(0)
	s.set_border_width(SIDE_BOTTOM, 2)
	s.shadow_color = Color(COR_TORNEIO.r, COR_TORNEIO.g, COR_TORNEIO.b, 0.30)
	s.shadow_size = 14
	header.add_theme_stylebox_override("panel", s)

	var titulo := _novo_label(
		"🏆 %s" % _titulo_fase_cabecalho(),
		26,
		Color.WHITE,
		COR_TORNEIO
	)
	titulo.position = Vector2(44, 0)
	titulo.size = Vector2(tela.x * 0.65, 82)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	root.add_child(titulo)

	var regra := _novo_label(
		"EMPATE ENTRE REAIS: PÊNALTIS DIRETO",
		17,
		COR_ALERTA,
		COR_ALERTA
	)
	regra.position = Vector2(tela.x - 610, 0)
	regra.size = Vector2(560, 82)
	regra.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(regra)


func _reconstruir_paineis() -> void:
	for p in player_panels:
		if is_instance_valid(p):
			p.queue_free()

	player_panels.clear()
	score_labels.clear()
	tempo_labels.clear()
	status_labels.clear()
	pos_labels.clear()

	var tela := get_viewport().get_visible_rect().size
	var area_top := 92.0
	var area := Vector2(tela.x, tela.y - area_top)

	for i in range(total_players):
		var rect := _get_rect_player(i, total_players, area)
		rect.position.y += area_top
		_criar_painel_player(i, rect)

	_atualizar_hud()


func _get_rect_player(index: int, qtd: int, tela: Vector2) -> Rect2:
	if qtd <= 1:
		return Rect2(Vector2.ZERO, tela)

	# 2 jogadores: metade para cada um.
	if qtd == 2:
		var w := tela.x / 2.0
		return Rect2(
			Vector2(float(index) * w, 0.0),
			Vector2(w, tela.y)
		)

	# 3 jogadores:
	# jogador atual fica grande à esquerda;
	# os outros dois dividem a direita.
	if qtd == 3:
		var ativo := clampi(player_atual, 0, qtd - 1)

		var big_w := tela.x * 0.58
		var small_w := tela.x - big_w

		if index == ativo:
			return Rect2(
				Vector2.ZERO,
				Vector2(big_w, tela.y)
			)

		var slot := 0

		for j in range(qtd):
			if j == index:
				break

			if j != ativo:
				slot += 1

		var h := tela.y / 2.0

		return Rect2(
			Vector2(big_w, float(slot) * h),
			Vector2(small_w, h)
		)

	# 4 jogadores: grade 2x2.
	if qtd == 4:
		var w4 := tela.x / 2.0
		var h4 := tela.y / 2.0
		var col := index % 2
		var row := int(index / 2)

		return Rect2(
			Vector2(float(col) * w4, float(row) * h4),
			Vector2(w4, h4)
		)

	# 5 ou 6 jogadores: mantém grade 3 colunas x 2 linhas.
	var w3 := tela.x / 3.0
	var h3 := tela.y / 2.0
	var col3 := index % 3
	var row3 := int(index / 3)

	return Rect2(
		Vector2(float(col3) * w3, float(row3) * h3),
		Vector2(w3, h3)
	)



func _criar_painel_player(index: int, rect: Rect2) -> void:
	if root == null:
		return

	if index < 0 or index >= total_players:
		return

	if index >= cores_players.size():
		return

	var cor := cores_players[index]
	var margem := 10.0

	var panel := Panel.new()
	panel.position = rect.position + Vector2(margem, margem)
	panel.size = rect.size - Vector2(margem * 2.0, margem * 2.0)
	panel.clip_contents = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	var W := panel.size.x
	var H := panel.size.y

	var style := StyleBoxFlat.new()
	style.bg_color = Color(cor.r * 0.035, cor.g * 0.035, cor.b * 0.035, 0.96)
	style.border_color = Color(cor.r, cor.g, cor.b, 0.38)
	style.set_border_width_all(3)
	style.set_corner_radius_all(0)
	style.shadow_color = Color(cor.r, cor.g, cor.b, 0.22)
	style.shadow_size = 12
	style.shadow_offset = Vector2.ZERO
	panel.add_theme_stylebox_override("panel", style)

	_adicionar_fundo_imagem_card_player(panel, index, cor)

	var faixa := ColorRect.new()
	faixa.position = Vector2(22.0, maxf(H * 0.025, 12.0))
	faixa.size = Vector2(maxf(W - 44.0, 20.0), 4.0)
	faixa.color = Color(cor.r, cor.g, cor.b, 0.42)
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(faixa)

	var pos_lbl := _novo_label(
		"1º",
		int(clampf(H * 0.062, 18.0, 34.0)),
		Color.WHITE,
		cor
	)

	var pos_w := clampf(W * 0.22, 92.0, 150.0)

	pos_lbl.position = Vector2(W - pos_w - 22.0, maxf(H * 0.035, 14.0))
	pos_lbl.size = Vector2(pos_w, 46.0)
	pos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pos_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pos_lbl.clip_text = false
	pos_lbl.z_index = 95
	pos_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.98))
	pos_lbl.add_theme_constant_override("outline_size", 5)
	panel.add_child(pos_lbl)

	var nome := _nome_player(index)

	if _player_eh_bot(index):
		nome += " BOT"

	var fs_titulo := int(clampf(H * 0.068, 20.0, 46.0))
	var fs_score_titulo := int(clampf(H * 0.052, 17.0, 34.0))
	var fs_score := int(clampf(minf(H * 0.31, W * 0.42), 58.0, 150.0))
	var fs_tempo_titulo := int(clampf(H * 0.048, 15.0, 30.0))
	var fs_tempo := int(clampf(H * 0.105, 34.0, 72.0))
	var fs_status := int(clampf(H * 0.042, 14.0, 28.0))

	var titulo := _novo_label_card(nome, W, H * 0.110, fs_titulo, Color.WHITE)
	titulo.add_theme_color_override("font_shadow_color", cor)
	titulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	titulo.add_theme_constant_override("outline_size", 4)
	panel.add_child(titulo)

	var score_titulo := _novo_label_card("GOLS", W, H * 0.315, fs_score_titulo, Color(0.75, 0.84, 0.90))
	score_titulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.90))
	score_titulo.add_theme_constant_override("outline_size", 3)
	panel.add_child(score_titulo)

	var score := _novo_label_card("0", W, H * 0.500, fs_score, Color.WHITE)
	score.add_theme_color_override("font_shadow_color", cor)
	score.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.98))
	score.add_theme_constant_override("outline_size", 6)
	panel.add_child(score)

	var tempo_titulo := _novo_label_card("TEMPO", W, H * 0.735, fs_tempo_titulo, Color(0.65, 0.72, 0.80))
	tempo_titulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	tempo_titulo.add_theme_constant_override("outline_size", 3)
	panel.add_child(tempo_titulo)

	var tempo := _novo_label_card(str(int(_tempo_do_player(index))), W, H * 0.845, fs_tempo, COR_ALERTA)
	tempo.add_theme_color_override("font_shadow_color", Color(1.0, 0.35, 0.05))
	tempo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	tempo.add_theme_constant_override("outline_size", 4)
	panel.add_child(tempo)

	var status := _novo_label_card("AGUARDANDO", W, H * 0.955, fs_status, Color(0.65, 0.70, 0.78))
	status.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	status.add_theme_constant_override("outline_size", 3)
	panel.add_child(status)

	player_panels.append(panel)
	score_labels.append(score)
	tempo_labels.append(tempo)
	status_labels.append(status)
	pos_labels.append(pos_lbl)



func _atualizar_hud() -> void:
	if player_panels.size() < total_players:
		return

	for i in range(total_players):
		_aplicar_destaque_painel_player(i, i == player_atual and not terminou_player[i])
		if i < score_labels.size():
			score_labels[i].text = str(scores[i])

		if i < tempo_labels.size():
			tempo_labels[i].text = str(int(ceil(tempos[i])))

		if i < pos_labels.size():
			var posicao := _posicao_ao_vivo(i)

			pos_labels[i].visible = true
			pos_labels[i].text = _texto_colocacao_curta(posicao)
			pos_labels[i].z_index = 95
			pos_labels[i].modulate = Color.WHITE
			pos_labels[i].add_theme_color_override("font_color", _cor_colocacao(posicao))
			pos_labels[i].add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.98))
			pos_labels[i].add_theme_constant_override("outline_size", 5)

		if i >= status_labels.size():
			continue

		var style := player_panels[i].get_theme_stylebox("panel") as StyleBoxFlat
		var cor := cores_players[i]

		if terminou_player[i]:
			status_labels[i].text = "FINALIZADO"
			status_labels[i].add_theme_color_override("font_color", Color(0.58, 0.60, 0.65))

			if style:
				style.bg_color = Color(0.018, 0.018, 0.020, 0.96)
				style.border_color = Color(0.25, 0.25, 0.28)
				style.shadow_color = Color(0, 0, 0, 0.35)
				style.shadow_size = 5

			player_panels[i].modulate = Color(0.70, 0.70, 0.70, 1)

		elif i == player_atual:
			if partida_ativa:
				status_labels[i].text = "BOT JOGANDO" if _player_eh_bot(i) else "JOGANDO AGORA"
			elif aguardando_start_turno:
				status_labels[i].text = "BOT AUTOMÁTICO" if _player_eh_bot(i) else "APERTE START"
			else:
				status_labels[i].text = "PREPARANDO"

			status_labels[i].add_theme_color_override("font_color", cor)

			var pulso := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 330.0)

			if style:
				style.bg_color = Color(cor.r * 0.065, cor.g * 0.065, cor.b * 0.065, 0.98)
				style.border_color = Color(cor.r, cor.g, cor.b, 0.65 + pulso * 0.35)
				style.shadow_color = Color(cor.r, cor.g, cor.b, 0.55 + pulso * 0.35)
				style.shadow_size = int(24.0 + pulso * 18.0)

			player_panels[i].modulate = Color.WHITE

		else:
			status_labels[i].text = "AGUARDANDO"
			status_labels[i].add_theme_color_override("font_color", Color(0.45, 0.48, 0.54))

			if style:
				style.bg_color = Color(cor.r * 0.025, cor.g * 0.025, cor.b * 0.025, 0.94)
				style.border_color = Color(cor.r, cor.g, cor.b, 0.30)
				style.shadow_color = Color(cor.r, cor.g, cor.b, 0.16)
				style.shadow_size = 8

			player_panels[i].modulate = Color(0.58, 0.58, 0.58, 1)


func _posicao_ao_vivo(index: int) -> int:
	if index < 0 or index >= total_players:
		return total_players

	var ranking := _ranking_indices_ao_vivo()

	for i in range(ranking.size()):
		if int(ranking[i]) == index:
			return i + 1

	return index + 1



func _ranking_indices_ao_vivo() -> Array[int]:
	var indices: Array[int] = []

	for i in range(total_players):
		indices.append(i)

	indices.sort_custom(func(a: int, b: int) -> bool:
		var sa := int(scores[a])
		var sb := int(scores[b])

		if sa != sb:
			return sa > sb

		var pa := 0
		var pb := 0

		if a >= 0 and a < penaltis_marcados.size():
			pa = int(penaltis_marcados[a])

		if b >= 0 and b < penaltis_marcados.size():
			pb = int(penaltis_marcados[b])

		if pa != pb:
			return pa > pb

		var bot_a := _player_eh_bot(a)
		var bot_b := _player_eh_bot(b)

		if bot_a != bot_b:
			return not bot_a

		return a < b
	)

	return indices


func _texto_colocacao_curta(posicao: int) -> String:
	if posicao < 1:
		posicao = 1

	return "%dº" % posicao


func _vagas_classificacao_momento() -> int:
	if modo_partida == "1X1":
		return 1

	if fase_torneio == "FASE_1":
		return 2

	return 1


func _player_classificado_no_momento(index: int) -> bool:
	var pos := _posicao_ao_vivo(index)
	return pos <= _vagas_classificacao_momento()


func _cor_colocacao(posicao: int) -> Color:
	match posicao:
		1:
			return Color(1.00, 0.78, 0.12)
		2:
			return Color(0.82, 0.86, 0.92)
		3:
			return Color(0.78, 0.43, 0.18)
		_:
			return Color(0.55, 0.60, 0.68)


# ============================================================
# OVERLAY DE TURNO
# ============================================================
func _criar_overlay_turno() -> void:
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 120
	add_child(overlay_layer)

	overlay_fundo = ColorRect.new()
	overlay_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_fundo.color = Color(0, 0, 0, 0)
	overlay_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.add_child(overlay_fundo)

	overlay_panel = Panel.new()
	overlay_panel.size = Vector2(820, 330)
	overlay_panel.position = (get_viewport().get_visible_rect().size - overlay_panel.size) / 2.0
	overlay_panel.scale = Vector2(0.94, 0.94)
	overlay_panel.modulate = Color(1, 1, 1, 0)
	overlay_panel.clip_contents = true
	overlay_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.add_child(overlay_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.010, 0.014, 0.020, 0.97)
	style.border_color = COR_TORNEIO
	style.set_border_width_all(4)
	style.set_corner_radius_all(0)
	style.shadow_color = Color(COR_TORNEIO.r, COR_TORNEIO.g, COR_TORNEIO.b, 0.72)
	style.shadow_size = 38
	style.shadow_offset = Vector2.ZERO
	overlay_panel.add_theme_stylebox_override("panel", style)

	overlay_fundo_img = TextureRect.new()
	overlay_fundo_img.position = Vector2(4, 4)
	overlay_fundo_img.size = overlay_panel.size - Vector2(8, 8)
	overlay_fundo_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay_fundo_img.stretch_mode = TextureRect.STRETCH_SCALE
	overlay_fundo_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_fundo_img.modulate = Color(0.70, 0.70, 0.70, 1)
	overlay_panel.add_child(overlay_fundo_img)

	var escuro := ColorRect.new()
	escuro.position = Vector2(4, 4)
	escuro.size = overlay_panel.size - Vector2(8, 8)
	escuro.color = Color(0, 0, 0, 0.36)
	escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_panel.add_child(escuro)

	overlay_titulo = _novo_label("", 42, Color.WHITE, COR_TORNEIO)
	overlay_titulo.position = Vector2(0, 36)
	overlay_titulo.size = Vector2(820, 66)
	overlay_titulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.96))
	overlay_titulo.add_theme_constant_override("outline_size", 5)
	overlay_panel.add_child(overlay_titulo)

	overlay_numero = _novo_label("", 72, COR_ALERTA, COR_ALERTA)
	overlay_numero.position = Vector2(0, 112)
	overlay_numero.size = Vector2(820, 92)
	overlay_numero.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.96))
	overlay_numero.add_theme_constant_override("outline_size", 5)
	overlay_panel.add_child(overlay_numero)

	overlay_subtitulo = _novo_label("", 22, Color.WHITE, COR_TORNEIO)
	overlay_subtitulo.position = Vector2(40, 230)
	overlay_subtitulo.size = Vector2(740, 54)
	overlay_subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_subtitulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.96))
	overlay_subtitulo.add_theme_constant_override("outline_size", 4)
	overlay_panel.add_child(overlay_subtitulo)

	overlay_layer.visible = false

func _mostrar_preparacao_player() -> void:
	partida_ativa = false
	aguardando_start_turno = true
	em_contagem_inicio = false

	# Música exclusiva do jogador da vez.
	_tocar_musica_do_player(player_atual)

	var cor := cores_players[player_atual]
	var nome := _nome_player(player_atual)
	var eh_bot := _player_eh_bot(player_atual)

	overlay_titulo.text = nome

	if eh_bot:
		overlay_numero.text = "BOT"
		overlay_subtitulo.text = "%s  •  JOGADA AUTOMÁTICA" % fase_nome
	else:
		overlay_numero.text = "PRONTO?"
		overlay_subtitulo.text = "%s  •  APERTE START PARA COMEÇAR" % fase_nome

	overlay_titulo.add_theme_color_override("font_shadow_color", cor)
	overlay_numero.add_theme_color_override("font_color", Color.WHITE)
	overlay_numero.add_theme_color_override("font_shadow_color", cor)

	_aplicar_fundo_modal_prep(player_atual)
	_set_overlay_cor(cor)
	_mostrar_overlay()
	_atualizar_hud()

	# Player real: LEDs piscam na cor dele enquanto espera START.
	if not eh_bot:
		_iniciar_piscar_leds_prep(player_atual)
	else:
		_parar_piscar_leds_prep()

	_agendar_start_automatico()


func _agendar_start_automatico() -> void:
	if not AUTO_START_BOT:
		return

	if not _player_eh_bot(player_atual):
		return

	auto_start_token += 1
	var meu_token := auto_start_token

	await get_tree().create_timer(AUTO_START_DELAY_BOT).timeout

	if meu_token != auto_start_token:
		return

	if partida_finalizada:
		return

	if not aguardando_start_turno:
		return

	if not _player_eh_bot(player_atual):
		return

	_iniciar_contagem_turno()


func _iniciar_contagem_turno() -> void:
	if em_contagem_inicio:
		return

	em_contagem_inicio = true
	aguardando_start_turno = false

	# O som de intro/game_start agora fica no loading do lobby,
	# não dentro do play.
	_parar_piscar_leds_prep()

	await _rodar_contagem_inicio()
	_iniciar_turno_player()


func _rodar_contagem_inicio() -> void:
	var nome := _nome_player(player_atual)
	var eh_bot := _player_eh_bot(player_atual)

	overlay_titulo.text = "%s, PREPARE-SE" % nome

	if eh_bot:
		overlay_numero.text = "GO!"
		overlay_subtitulo.text = "BOT ENTRANDO EM CAMPO..."
		await get_tree().create_timer(0.45).timeout
		return

	overlay_subtitulo.text = "VALENDO EM..."

	for n in range(TEMPO_CONTAGEM_INICIAL, 0, -1):
		overlay_numero.text = str(n)
		overlay_numero.scale = Vector2(1.35, 1.35)

		var t := create_tween()
		t.tween_property(overlay_numero, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		await get_tree().create_timer(0.85).timeout

	overlay_titulo.text = "VAI, %s!" % nome
	overlay_numero.text = ""
	overlay_subtitulo.text = "MARQUE O MÁXIMO DE GOLS"

	await get_tree().create_timer(0.45).timeout



func _iniciar_turno_player() -> void:
	partida_ativa = false
	em_contagem_inicio = false
	aguardando_start_turno = false

	await _esconder_overlay()

	leds_ativos.clear()
	cores_leds_ativos.clear()
	_combo_gols_seguidos = 0
	_ultimo_combo_gol_ms = 0.0
	_ultimo_combo_som_ms = 0.0

	_atualizar_leds_hud()
	_serial_write("OFF")

	
	# Apito antes de começar o tempo.
	_tocar_audio(sfx_apito_init)

	# Player real: solta também um grito da torcida ao iniciar (good_player ou leleo).
	if not _player_eh_bot(player_atual):
		_tocar_inicio_hype()

	await get_tree().create_timer(0.28).timeout

	_sortear_novo_grupo_de_fileiras()

	if _player_eh_bot(player_atual):
		_sortear_proximo_gol_bot()

	if audio_fundo != null and audio_fundo.stream != null and not audio_fundo.playing:
		audio_fundo.play()

	# Agora sim começa a contar o tempo.
	partida_ativa = true

	_atualizar_hud()



func _mostrar_overlay() -> void:
	overlay_layer.visible = true

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(overlay_fundo, "color", Color(0, 0, 0, 0.64), 0.22)
	t.tween_property(overlay_panel, "modulate", Color.WHITE, 0.22)
	t.tween_property(overlay_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _esconder_overlay() -> void:
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(overlay_fundo, "color", Color(0, 0, 0, 0.0), 0.18)
	t.tween_property(overlay_panel, "modulate", Color(1, 1, 1, 0), 0.18)
	t.tween_property(overlay_panel, "scale", Vector2(0.94, 0.94), 0.18)

	await t.finished
	overlay_layer.visible = false


func _set_overlay_cor(cor: Color) -> void:
	var style := overlay_panel.get_theme_stylebox("panel") as StyleBoxFlat

	if style:
		style.border_color = cor
		style.shadow_color = Color(cor.r, cor.g, cor.b, 0.72)


# ============================================================
# LEDS / SENSORES
# ============================================================
func _checar_ciclo_leds() -> void:
	if not partida_ativa:
		return

	if leds_ativos.is_empty():
		_sortear_novo_grupo_de_fileiras()
		return

	var agora := float(Time.get_ticks_msec())

	if agora - _ciclo_inicio_ms >= _intervalo_ciclo_leds():
		_sortear_novo_grupo_de_fileiras()



func _sortear_novo_grupo_de_fileiras() -> void:
	var tentativas := 0

	while true:
		leds_ativos.clear()
		cores_leds_ativos.clear()

		var qtd := clampi(randi_range(LEDS_ATIVOS_MIN, LEDS_ATIVOS_MAX), 1, LEDS_TOTAL)

		while leds_ativos.size() < qtd:
			var novo := _sortear_led_disponivel()

			if novo < 0:
				break

			if not leds_ativos.has(novo):
				leds_ativos.append(novo)
				cores_leds_ativos[novo] = _rgb_aleatorio_alvo()

		tentativas += 1

		if tentativas >= 6 or not _mesma_combinacao(leds_ativos, _dupla_anterior):
			break

	_dupla_anterior = leds_ativos.duplicate()
	_ciclo_inicio_ms = float(Time.get_ticks_msec())

	_atualizar_leds_hud()
	# Apaga tudo antes de acender o novo grupo: garante que LEDs que
	# reaparecem na mesma posição/cor pisquem (feedback visível do acerto).
	_serial_write("OFF")
	_enviar_leds_para_arduino()


func _sortear_led_disponivel() -> int:
	var disponiveis: Array[int] = []

	for i in range(LEDS_TOTAL):
		if not leds_ativos.has(i):
			disponiveis.append(i)

	if disponiveis.is_empty():
		return -1

	return int(disponiveis[randi() % disponiveis.size()])


func _mesma_combinacao(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false

	for v in a:
		if not b.has(v):
			return false

	return true


func _processar_input_led(index_led: int, origem_bot: bool = false) -> void:
	if fase_jogo == FaseJogo.PENALTIS:
		_registrar_chute_penalti(index_led)
		return

	if not partida_ativa:
		return

	# Durante o turno de um BOT, ignora qualquer input físico/manual.
	# Só o próprio bot pontua (origem_bot = true). Evita que um player
	# real marque sem querer ao passar perto do sensor.
	if not origem_bot and _player_eh_bot(player_atual):
		return

	if index_led < 0 or index_led >= LEDS_TOTAL:
		return

	if leds_ativos.has(index_led):
		_flash_led(index_led, true)

		leds_ativos.erase(index_led)
		cores_leds_ativos.erase(index_led)

		registrar_ponto(1)

		if leds_ativos.is_empty():
			_sortear_novo_grupo_de_fileiras()
		else:
			_atualizar_leds_hud()
			_enviar_leds_para_arduino()
	else:
		_flash_led(index_led, false)



func registrar_ponto(valor: int = 1) -> void:
	if not partida_ativa:
		return

	if player_atual < 0 or player_atual >= total_players:
		return

	scores[player_atual] += valor

	if sfx_ponto and sfx_ponto.stream:
		sfx_ponto.stop()
		sfx_ponto.play()

	# Torcida positiva por combo (4 seguidos).
	_registrar_combo_gol_player()

	# Ao ultrapassar alguém que já finalizou: good_player (se nada de torcida tocando).
	if not _player_eh_bot(player_atual):
		_checar_superacao_e_tocar(player_atual)

	_efeito_gol_player(player_atual)
	_animar_score(player_atual)
	_atualizar_hud()


func _registrar_combo_gol_player() -> void:
	if player_atual < 0 or player_atual >= total_players:
		return

	# Bot não dispara torcida de combo.
	if _player_eh_bot(player_atual):
		return

	var agora := float(Time.get_ticks_msec())

	if _ultimo_combo_gol_ms <= 0.0:
		_combo_gols_seguidos = 1
	else:
		var intervalo := agora - _ultimo_combo_gol_ms

		if intervalo <= COMBO_JANELA_MS:
			_combo_gols_seguidos += 1
		else:
			_combo_gols_seguidos = 1

	_ultimo_combo_gol_ms = agora

	if _combo_gols_seguidos < COMBO_GOLS_PARA_SOM:
		return

	if agora - _ultimo_combo_som_ms < COMBO_COOLDOWN_MS:
		return

	if _algum_sfx_torcida_tocando():
		return

	_ultimo_combo_som_ms = agora
	_combo_gols_seguidos = 0

	_tocar_torcida_gol()


func _algum_sfx_torcida_tocando() -> bool:
	for p in sfx_torcida_gol:
		if p != null and p.playing:
			return true

	for p in sfx_torcida_erro:
		if p != null and p.playing:
			return true

	for p in sfx_inicio_hype:
		if p != null and p.playing:
			return true

	for p in sfx_good_player:
		if p != null and p.playing:
			return true

	return false



func _esperar_torcida_terminar(timeout_seg: float = 2.4) -> void:
	await get_tree().create_timer(0.05).timeout

	var t0 := float(Time.get_ticks_msec())

	while _algum_sfx_torcida_tocando():
		var passou := (float(Time.get_ticks_msec()) - t0) / 1000.0

		if passou >= timeout_seg:
			break

		await get_tree().process_frame

	await get_tree().create_timer(0.10).timeout

func _jogadores_ja_jogaram(exceto: int = -1) -> Array[int]:
	var lista: Array[int] = []

	for i in range(total_players):
		if i == exceto:
			continue

		if i >= 0 and i < terminou_player.size() and terminou_player[i]:
			lista.append(i)

	return lista


func _melhor_score_ja_jogado(exceto: int = -1) -> int:
	var melhor: int = -1

	for i in _jogadores_ja_jogaram(exceto):
		if i >= 0 and i < scores.size():
			melhor = maxi(melhor, scores[i])

	return melhor



func _tocar_som_fim_turno_reativo(player_index: int) -> void:
	if player_index < 0 or player_index >= scores.size():
		return

	if _player_eh_bot(player_index):
		return

	var meu_score: int = scores[player_index]
	var melhor_anterior: int = _melhor_score_ja_jogado(player_index)
	var ja_teve_anterior: bool = melhor_anterior >= 0
	var classificado_agora := _player_classificado_no_momento(player_index)

	# Muito baixo: vaia mesmo se estiver momentaneamente em posição boa.
	# Isso evita comemorar jogador que fez quase nada.
	if meu_score < 6:
		_tocar_torcida_erro()
		return

	# Se no momento ele está classificado, não merece vaia.
	# Fase 1: top 2.
	# Mata-mata: top 1.
	if classificado_agora:
		_tocar_torcida_gol()
		return

	# Abaixo de 15 e fora da zona de classificação: vaia.
	if meu_score < PONTOS_MINIMOS_SEM_VAIA:
		_tocar_torcida_erro()
		return

	# Primeiro jogador real com 15 ou mais: som bom.
	if not ja_teve_anterior:
		_tocar_torcida_gol()
		return

	# Se fez 15+ e superou o melhor anterior: som bom.
	if meu_score > melhor_anterior:
		_tocar_torcida_gol()
		return

	# Fez 15+, mas não superou e não está classificado: vaia.
	_tocar_torcida_erro()



func _flash_led(index_led: int, sucesso: bool) -> void:
	if index_led < 0 or index_led >= leds_botoes.size():
		return

	var btn := leds_botoes[index_led]

	btn.pivot_offset = btn.size * 0.5
	btn.scale = Vector2(1.30, 1.30)

	var t := create_tween()
	t.tween_property(btn, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if not sucesso:
		btn.modulate = Color(1.5, 0.45, 0.45, 1.0)

		var t2 := create_tween()
		t2.tween_property(btn, "modulate", Color.WHITE, 0.35)


func _rgb_aleatorio_alvo() -> Array[int]:
	if CORES_ALVOS_RGB.is_empty():
		return [255, 255, 255]

	var rgb: Array = CORES_ALVOS_RGB[int(randi() % CORES_ALVOS_RGB.size())]

	return [
		int(rgb[0]),
		int(rgb[1]),
		int(rgb[2])
	]


func _rgb_led_por_index(index_led: int) -> Array[int]:
	if cores_leds_ativos.has(index_led):
		var rgb_salvo: Array = cores_leds_ativos[index_led]

		return [
			int(rgb_salvo[0]),
			int(rgb_salvo[1]),
			int(rgb_salvo[2])
		]

	var novo_rgb := _rgb_aleatorio_alvo()
	cores_leds_ativos[index_led] = novo_rgb
	return novo_rgb


func _cor_led_ativo(index_led: int) -> Color:
	var rgb := _rgb_led_por_index(index_led)

	return Color(
		float(rgb[0]) / 255.0,
		float(rgb[1]) / 255.0,
		float(rgb[2]) / 255.0,
		1.0
	)


# ============================================================
# HUD LEDS
# ============================================================
func _criar_hud_leds() -> void:
	leds_hud_layer = CanvasLayer.new()
	leds_hud_layer.layer = 50
	leds_hud_layer.visible = MOSTRAR_TECLAS_LED_HUD
	add_child(leds_hud_layer)

	leds_hud_root = Control.new()
	leds_hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	leds_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leds_hud_layer.add_child(leds_hud_root)

	var tela := get_viewport().get_visible_rect().size
	var tam := 64.0
	var gap := 14.0
	var largura_total := (tam * float(LEDS_TOTAL)) + (gap * float(LEDS_TOTAL - 1))
	var start_x := (tela.x - largura_total) * 0.5
	var y := tela.y - tam - 18.0

	leds_botoes.clear()
	leds_labels.clear()

	for i in range(LEDS_TOTAL):
		var btn := Panel.new()
		btn.position = Vector2(start_x + float(i) * (tam + gap), y)
		btn.size = Vector2(tam, tam)
		leds_hud_root.add_child(btn)
		leds_botoes.append(btn)

		var lbl := Label.new()
		lbl.text = LEDS_LETRAS[i]
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 32)
		lbl.add_theme_constant_override("shadow_offset_x", 0)
		lbl.add_theme_constant_override("shadow_offset_y", 0)

		if fonte_orbitron:
			lbl.add_theme_font_override("font", fonte_orbitron)

		btn.add_child(lbl)
		leds_labels.append(lbl)

	_atualizar_leds_hud()



func _iniciar_piscar_leds_prep(index: int) -> void:
	_prep_piscar_token += 1
	_prep_piscar_ligado = true

	var meu_token := _prep_piscar_token

	_piscar_leds_prep_loop(index, meu_token)


func _parar_piscar_leds_prep() -> void:
	_prep_piscar_token += 1
	_prep_piscar_ligado = false

	leds_ativos.clear()
	cores_leds_ativos.clear()

	_atualizar_leds_hud()
	_serial_write("OFF")


func _piscar_leds_prep_loop(index: int, token: int) -> void:
	if not _prep_piscar_ligado:
		return

	if token != _prep_piscar_token:
		return

	if index < 0 or index >= cores_players.size():
		return

	var rgb := _rgb_player_para_led(index)

	leds_ativos.clear()
	cores_leds_ativos.clear()

	for i in range(LEDS_TOTAL):
		leds_ativos.append(i)
		cores_leds_ativos[i] = rgb

	_atualizar_leds_hud()

	var partes: Array[String] = []

	for i in range(LEDS_TOTAL):
		partes.append("%s=%d,%d,%d" % [
			LEDS_LETRAS[i],
			int(rgb[0]),
			int(rgb[1]),
			int(rgb[2])
		])

	_serial_write("SET:" + ";".join(partes))

	await get_tree().create_timer(0.40).timeout

	if not _prep_piscar_ligado:
		return

	if token != _prep_piscar_token:
		return

	leds_ativos.clear()
	cores_leds_ativos.clear()

	_atualizar_leds_hud()
	_serial_write("OFF")

	await get_tree().create_timer(0.35).timeout

	if not _prep_piscar_ligado:
		return

	if token != _prep_piscar_token:
		return

	_piscar_leds_prep_loop(index, token)


func _rgb_player_para_led(index: int) -> Array[int]:
	if index < 0 or index >= cores_players.size():
		return [255, 255, 255]

	var cor := cores_players[index]

	# Amarelo
	if cor.r >= 0.70 and cor.g >= 0.55 and cor.b <= 0.35:
		return [255, 200, 0]

	# Vermelho
	if cor.r >= cor.g and cor.r >= cor.b:
		return [255, 0, 0]

	# Verde
	if cor.g >= cor.r and cor.g >= cor.b:
		return [0, 255, 0]

	# Azul
	if cor.b >= cor.r and cor.b >= cor.g:
		return [0, 0, 255]

	return [
		int(clamp(cor.r * 255.0, 0.0, 255.0)),
		int(clamp(cor.g * 255.0, 0.0, 255.0)),
		int(clamp(cor.b * 255.0, 0.0, 255.0))
	]

func _atualizar_leds_hud() -> void:
	if leds_hud_layer:
		leds_hud_layer.visible = MOSTRAR_TECLAS_LED_HUD

	if leds_botoes.is_empty():
		return

	for i in range(LEDS_TOTAL):
		var btn := leds_botoes[i]
		var lbl := leds_labels[i]
		var aceso := leds_ativos.has(i)

		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(16)
		style.set_border_width_all(3)
		style.shadow_offset = Vector2.ZERO

		if aceso:
			var cor_led := _cor_led_ativo(i)

			style.bg_color = Color(cor_led.r * 0.18, cor_led.g * 0.18, cor_led.b * 0.18, 0.96)
			style.border_color = cor_led
			style.shadow_color = Color(cor_led.r, cor_led.g, cor_led.b, 0.90)
			style.shadow_size = 26

			lbl.add_theme_color_override("font_color", Color.WHITE)
			lbl.add_theme_color_override("font_shadow_color", cor_led)
		else:
			style.bg_color = Color(0.04, 0.05, 0.07, 0.92)
			style.border_color = Color(0.22, 0.24, 0.28, 1.0)
			style.shadow_color = Color(0, 0, 0, 0.3)
			style.shadow_size = 4

			lbl.add_theme_color_override("font_color", Color(0.35, 0.38, 0.42))
			lbl.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)

		btn.add_theme_stylebox_override("panel", style)


# ============================================================
# TURNOS / FINALIZAÇÃO
# ============================================================
func _finalizar_turno_player() -> void:
	if player_atual < 0 or player_atual >= total_players:
		return

	partida_ativa = false

	var player_finalizado := player_atual

	leds_ativos.clear()
	cores_leds_ativos.clear()
	_atualizar_leds_hud()
	_enviar_leds_para_arduino()

	# Primeiro apito final, sozinho.
	_tocar_audio(sfx_apito_fim)

	terminou_player[player_finalizado] = true
	_atualizar_hud()

	# Dá tempo do apito aparecer antes da reação.
	await get_tree().create_timer(0.85).timeout

	# Vaia/torcida só no fim do turno.
	# Nunca durante a partida.
	if not _player_eh_bot(player_finalizado):
		_tocar_som_fim_turno_reativo(player_finalizado)
		await _esperar_torcida_terminar(2.4)

	var proximo := -1

	for i in range(total_players):
		if not terminou_player[i]:
			proximo = i
			break

	if proximo == -1:
		await _resolver_fim_dos_turnos()
	else:
		var nome_finalizado := _nome_player(player_finalizado)
		var nome_proximo := _nome_player(proximo)

		await _mostrar_aviso_turno(
			"TEMPO ESGOTADO",
			"%s FEZ %d GOLS  •  PRÓXIMO: %s" % [
				nome_finalizado,
				scores[player_finalizado],
				nome_proximo
			],
			cores_players[player_finalizado]
		)

		_tocar_audio(sfx_apito_troca)

		player_atual = proximo
		_reconstruir_paineis()

		await get_tree().create_timer(0.18).timeout

		_mostrar_preparacao_player()



func _eh_mata_mata_ida_volta() -> bool:
	return ida_volta and modo_partida == "1X1" and total_players == 2



func _resolver_fim_dos_turnos() -> void:
	# PRIMEIRA FASE (chave 3x3): se houver empate em gols entre jogadores
	# REAIS na disputa pela classificação, decide nos pênaltis (pode ser
	# entre 3). O resultado entra como desempate dos gols da etapa.
	if modo_partida != "1X1" and fase_torneio == "FASE_1":
		await _resolver_empates_chave_fase1()

	for i in range(total_players):
		gols_normais[i] = scores[i]

	var titulo: String = "FIM DA PARTIDA"
	var subtitulo: String = "TODOS FINALIZARAM  •  ENVIANDO RESULTADO AO LOBBY"

	if modo_partida == "1X1" and total_players >= 2:
		titulo = "FIM DA ETAPA"
		subtitulo = "%s %d x %d %s  •  %s" % [
			_nome_player(0),
			int(scores[0]),
			int(scores[1]),
			_nome_player(1),
			str(partida_torneio.get("etapa", "ida")).to_upper()
		]
	elif fase_torneio == "FASE_1":
		titulo = "FIM DA CHAVE"
		subtitulo = "RANKING DA ETAPA ENVIADO PARA A PRIMEIRA FASE"

	await _mostrar_aviso_turno(
		titulo,
		subtitulo,
		COR_ALERTA
	)

	await _finalizar_partida()


func _preparar_jogo_volta() -> void:
	jogo_atual_confronto = 2

	for i in range(total_players):
		scores[i] = 0
		tempos[i] = _tempo_do_player(i)
		terminou_player[i] = false

	player_atual = 0

	partida_ativa = false
	aguardando_start_turno = false
	em_contagem_inicio = false
	fase_jogo = FaseJogo.NORMAL

	leds_ativos.clear()
	cores_leds_ativos.clear()
	_dupla_anterior.clear()
	_ciclo_inicio_ms = 0.0

	_combo_gols_seguidos = 0
	_ultimo_combo_gol_ms = 0.0
	_ultimo_combo_som_ms = 0.0

	_serial_write("OFF")
	_reconstruir_paineis()

	await get_tree().create_timer(0.25).timeout

	await _mostrar_aviso_turno(
		"JOGO DE VOLTA",
		_texto_resumo_ida(),
		COR_TORNEIO
	)

	_mostrar_preparacao_player()


func _texto_resumo_ida() -> String:
	if total_players < 2:
		return ""

	return "IDA: %s %d x %d %s" % [
		_nome_player(0),
		gols_ida[0],
		gols_ida[1],
		_nome_player(1)
	]


func _texto_resumo_agregado() -> String:
	if total_players < 2:
		return ""

	return "IDA %d x %d  •  VOLTA %d x %d  •  AGREGADO %d x %d" % [
		gols_ida[0],
		gols_ida[1],
		gols_volta[0],
		gols_volta[1],
		gols_agregado[0],
		gols_agregado[1]
	]


func _resolver_empate_agregado_penaltis() -> void:
	var grupos := _grupos_empatados_reais_por_valores(gols_agregado)

	if grupos.is_empty():
		await _finalizar_partida()
		return

	for grupo in grupos:
		await _rodar_penaltis(grupo)

	await _finalizar_partida()


func _resolver_empates_direto_penaltis() -> void:
	for i in range(total_players):
		gols_normais[i] = scores[i]

	var grupos := _grupos_empatados_reais()

	if grupos.is_empty():
		await _finalizar_partida()
		return

	for grupo in grupos:
		await _rodar_penaltis(grupo)

	await _finalizar_partida()


func _grupos_empatados_reais() -> Array:
	return _grupos_empatados_reais_por_valores(gols_normais)


func _grupos_empatados_reais_por_valores(valores: Array) -> Array:
	var por_score: Dictionary = {}

	for i in range(total_players):
		var s := int(valores[i])

		if not por_score.has(s):
			por_score[s] = []

		por_score[s].append(i)

	var chaves: Array = por_score.keys()
	chaves.sort()
	chaves.reverse()

	var grupos: Array = []

	for s in chaves:
		var grupo_total: Array = por_score[s]
		var somente_reais: Array[int] = []

		for p in grupo_total:
			var idx := int(p)

			if not _player_eh_bot(idx):
				somente_reais.append(idx)

		if somente_reais.size() >= 2:
			grupos.append(somente_reais)

	return grupos



func _finalizar_partida() -> void:
	partida_finalizada = true
	partida_ativa = false
	
	for i in range(total_players):
		if i >= 0 and i < scores.size():
			if i >= 0 and i < gols_normais.size():
				gols_normais[i] = int(scores[i])

	_serial_write("OFF")
	_atualizar_hud()

	if audio_fundo:
		audio_fundo.stop()

	var ranking := _montar_ranking_torneio()

	var fase_lobby: String = str(get_tree().get_meta("torneio_partida_atual_fase", fase_torneio))
	var etapa_lobby: String = str(get_tree().get_meta("torneio_partida_atual_etapa", str(partida_torneio.get("etapa", "ida"))))

	var id_lobby: String = str(get_tree().get_meta("torneio_partida_atual_id", partida_id))

	var resultado: Dictionary = {
		"fase": fase_lobby,
		"partida_index": partida_index,
		"partida_id": id_lobby,
		"etapa": etapa_lobby,
		"modo": modo_partida,
		"chave": chave_nome,
		"fase_play": fase_torneio
	}

	if modo_partida == "1X1":
		if somente_penaltis:
			resultado["pen_a"] = int(penaltis_marcados[0]) if penaltis_marcados.size() > 0 else 0
			resultado["pen_b"] = int(penaltis_marcados[1]) if penaltis_marcados.size() > 1 else 0
			resultado["gols_a"] = resultado["pen_a"]
			resultado["gols_b"] = resultado["pen_b"]
		else:
			resultado["gols_a"] = int(scores[0]) if scores.size() > 0 else 0
			resultado["gols_b"] = int(scores[1]) if scores.size() > 1 else 0
			resultado["pen_a"] = int(penaltis_marcados[0]) if penaltis_marcados.size() > 0 else 0
			resultado["pen_b"] = int(penaltis_marcados[1]) if penaltis_marcados.size() > 1 else 0
	else:
		resultado["ranking"] = ranking
		resultado["scores"] = scores.duplicate()

	get_tree().set_meta("resultado_torneio_pendente", resultado)

	print("================================")
	print("RESULTADO DO TORNEIO ENVIADO AO LOBBY")
	print("FASE LOBBY: ", fase_lobby)
	print("ETAPA: ", etapa_lobby)
	print("PARTIDA INDEX: ", partida_index)
	print("RESULTADO: ", resultado)
	print("================================")

	# O campeão real é decidido pelo lobby depois da volta/agregado.
	# O play só comemora a partida, não encerra o torneio sozinho.
	_tocar_torcida_gol()

	await _mostrar_modal_resultado(ranking)

	if ResourceLoader.exists(CENA_TORMENT_LOBBY):
		_cobrir_tela_para_transicao()
		await get_tree().process_frame
		get_tree().change_scene_to_file(CENA_TORMENT_LOBBY)
	else:
		push_warning("torment_lobby.tscn não encontrada: " + CENA_TORMENT_LOBBY)



func _montar_ranking_torneio() -> Array:
	var ranking: Array = []

	for i in range(total_players):
		var nome := _nome_player(i)
		var cor := cores_players[i]
		var j: Dictionary = jogadores_torneio[i]

		var gols_base := int(gols_normais[i])

		if _eh_mata_mata_ida_volta():
			gols_base = int(gols_agregado[i])

		var pens := int(penaltis_marcados[i])

		var item := {
			"player_index": i,
			"nome": nome,

			# Para o lobby ordenar e mostrar.
			"score": gols_base,
			"gols": gols_base,
			"gols_total": gols_base,
			"gols_normais": gols_base,

			# Ida e volta.
			"ida_volta": _eh_mata_mata_ida_volta(),
			"jogo_atual_confronto": jogo_atual_confronto,
			"gols_ida": int(gols_ida[i]),
			"gols_volta": int(gols_volta[i]),
			"gols_agregado": int(gols_agregado[i]),

			# Não tem prorrogação no TORMENT.
			"gols_prorrogacao": 0,
			"jogou_prorrogacao": false,

			# Pênaltis.
			"penaltis": pens,
			"penaltis_total": pens,
			"jogou_penaltis": bool(jogou_penaltis[i]),
			"passou_penaltis": confronto_decidido_penaltis and i == vencedor_penaltis_index,

			"cor": cor,
			"cor_nome": str(j.get("cor_nome", "")),
			"cor_index": int(j.get("cor_index", -1)),
			"boot": _player_eh_bot(i),
			"grupo": chave_nome,
			"fase_nome": fase_nome,
			"posicao": 1,
			"classificado": false
		}

		ranking.append(item)

	ranking.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ga := int(a.get("gols", 0))
		var gb := int(b.get("gols", 0))

		if ga != gb:
			return ga > gb

		var pa := int(a.get("penaltis", 0))
		var pb := int(b.get("penaltis", 0))

		if pa != pb:
			return pa > pb

		var bot_a := bool(a.get("boot", false))
		var bot_b := bool(b.get("boot", false))

		if bot_a != bot_b:
			return not bot_a

		return int(a.get("player_index", 0)) < int(b.get("player_index", 0))
	)

	var vagas: int = _vagas_classificacao_momento()

	for i in range(ranking.size()):
		ranking[i]["posicao"] = i + 1
		ranking[i]["classificado"] = i < vagas

	return ranking



# ============================================================
# PÊNALTIS DIRETO
# ============================================================
func _rodar_penaltis(participantes: Array) -> void:
	fase_jogo = FaseJogo.PENALTIS
	partida_ativa = false
	aguardando_start_turno = false
	em_contagem_inicio = false

	_serial_write("OFF")

	var jogadores_penalti: Array[int] = []

	for p in participantes:
		var idx := int(p)

		if idx < 0 or idx >= total_players:
			continue

		if _player_eh_bot(idx):
			continue

		if not jogadores_penalti.has(idx):
			jogadores_penalti.append(idx)

	if jogadores_penalti.size() <= 1:
		fase_jogo = FaseJogo.NORMAL
		return

	for p in jogadores_penalti:
		jogou_penaltis[p] = true
		penaltis_marcados[p] = 0

	var nomes: Array[String] = []

	for p in jogadores_penalti:
		nomes.append(_nome_player(p))

	await _mostrar_aviso_turno(
		"PÊNALTIS DIRETO",
		"EMPATE ENTRE %s  •  SEM PRORROGAÇÃO" % " E ".join(nomes),
		COR_ALERTA
	)

	_criar_overlay_penalti(jogadores_penalti)

	var pen: Dictionary = {}
	var cobrancas: Dictionary = {}

	for p in jogadores_penalti:
		pen[p] = 0
		cobrancas[p] = 0

	_atualizar_overlay_penalti(jogadores_penalti, pen, -1)

	var lider := -1
	var resolveu_antes := false

	for rodada in range(1, PENALTI_RODADAS_INICIAIS + 1):
		for p in jogadores_penalti:
			var marcou := await _cobrar_penalti(p, rodada, jogadores_penalti, pen)

			cobrancas[p] = int(cobrancas.get(p, 0)) + 1

			if marcou:
				pen[p] = int(pen[p]) + 1

			penaltis_marcados[p] = int(pen[p])
			_atualizar_overlay_penalti(jogadores_penalti, pen, p)

			lider = _lider_antecipado_penaltis(
				pen,
				cobrancas,
				jogadores_penalti,
				PENALTI_RODADAS_INICIAIS
			)

			if lider != -1:
				resolveu_antes = true
				break

		if resolveu_antes:
			break

	if lider == -1:
		var contestados: Array = jogadores_penalti.duplicate()
		lider = _lider_penaltis(pen, contestados)
		var rodada_sd := PENALTI_RODADAS_INICIAIS

		while lider == -1:
			rodada_sd += 1
			contestados = _empatados_topo_penaltis(pen, contestados)

			if contestados.size() <= 1:
				lider = int(contestados[0])
				break

			await _mostrar_aviso_turno(
				"MORTE SÚBITA",
				"EMPATE NOS PÊNALTIS  •  UMA COBRANÇA PARA CADA",
				COR_ALERTA
			)

			for p in contestados:
				var marcou_sd := await _cobrar_penalti(int(p), rodada_sd, contestados, pen)

				if marcou_sd:
					pen[p] = int(pen[p]) + 1

				penaltis_marcados[int(p)] = int(pen[p])
				_atualizar_overlay_penalti(contestados, pen, int(p))

			lider = _lider_penaltis(pen, contestados)

	await _mostrar_vencedor_penalti(lider)

	_remover_overlay_penalti()

	leds_ativos.clear()
	cores_leds_ativos.clear()
	_atualizar_leds_hud()
	_enviar_leds_para_arduino()

	fase_jogo = FaseJogo.NORMAL



func _lider_penaltis(pen: Dictionary, subset: Array) -> int:
	var maxg := -1

	for p in subset:
		var idx := int(p)

		if int(pen[idx]) > maxg:
			maxg = int(pen[idx])

	var topo: Array[int] = []

	for p in subset:
		var idx := int(p)

		if int(pen[idx]) == maxg:
			topo.append(idx)

	if topo.size() == 1:
		return topo[0]

	return -1


func _empatados_topo_penaltis(pen: Dictionary, subset: Array) -> Array:
	var maxg := -1

	for p in subset:
		var idx := int(p)

		if int(pen[idx]) > maxg:
			maxg = int(pen[idx])

	var res: Array[int] = []

	for p in subset:
		var idx := int(p)

		if int(pen[idx]) == maxg:
			res.append(idx)

	return res



func _lider_antecipado_penaltis(
	pen: Dictionary,
	cobrancas: Dictionary,
	participantes: Array,
	max_cobrancas: int
) -> int:
	var lider := -1
	var gols_lider := -1
	var empatado := false

	for pp in participantes:
		var p := int(pp)
		var gols := int(pen.get(p, 0))

		if gols > gols_lider:
			gols_lider = gols
			lider = p
			empatado = false
		elif gols == gols_lider:
			empatado = true

	if lider == -1 or empatado:
		return -1

	for pp in participantes:
		var p2 := int(pp)

		if p2 == lider:
			continue

		var feitas := int(cobrancas.get(p2, 0))
		var restantes := maxi(max_cobrancas - feitas, 0)
		var max_possivel := int(pen.get(p2, 0)) + restantes

		if max_possivel >= gols_lider:
			return -1

	return lider



func _cobrar_penalti(p: int, rodada: int, participantes: Array, pen: Dictionary) -> bool:
	if p < 0 or p >= total_players:
		return false

	player_atual = p

	var eh_bot := _player_eh_bot(p)

	_set_overlay_penalti_chute(p, rodada)
	_atualizar_overlay_penalti(participantes, pen, p)

	if not eh_bot:
		_pen_aguardando = false
		leds_ativos.clear()
		cores_leds_ativos.clear()
		_atualizar_leds_hud()
		_enviar_leds_para_arduino()

		pen_contagem.text = ""
		pen_feedback.text = "APERTE START PARA COBRAR"
		pen_feedback.add_theme_color_override("font_color", COR_OK)
		pen_feedback.add_theme_color_override("font_shadow_color", COR_OK)

		await get_tree().create_timer(0.25).timeout

		while not _start_foi_pressionado():
			await get_tree().process_frame

		pen_feedback.text = "PREPARE-SE..."
		pen_feedback.add_theme_color_override("font_color", COR_ALERTA)
		pen_feedback.add_theme_color_override("font_shadow_color", COR_ALERTA)

		for n in range(3, 0, -1):
			pen_contagem.text = str(n)
			pen_contagem.scale = Vector2(1.25, 1.25)

			var tc := create_tween()
			tc.tween_property(pen_contagem, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

			await get_tree().create_timer(0.85).timeout

		pen_contagem.text = ""
		pen_feedback.text = ""

	var bocas := _sortear_bocas_penalti()

	_pen_alvos.clear()
	leds_ativos.clear()
	cores_leds_ativos.clear()

	for a in bocas:
		var alvo := int(a)

		if alvo < 0 or alvo >= LEDS_TOTAL:
			continue

		if not _pen_alvos.has(alvo):
			_pen_alvos.append(alvo)

		if not leds_ativos.has(alvo):
			leds_ativos.append(alvo)
			cores_leds_ativos[alvo] = _rgb_aleatorio_alvo()

	_atualizar_leds_hud()
	_enviar_leds_para_arduino()

	_tocar_audio(sfx_apito_init)

	await get_tree().create_timer(0.35).timeout

	_pen_resultado = 0
	_pen_aguardando = true

	var marcou := false
	var bot_marca := false
	var bot_momento := 0.0

	if eh_bot:
		bot_marca = randf() < PENALTI_PROB_BOT
		bot_momento = randf_range(0.55, maxf(PENALTI_TEMPO_ACERTO - 0.45, 0.70))

	var t0 := float(Time.get_ticks_msec())

	while (float(Time.get_ticks_msec()) - t0) / 1000.0 < PENALTI_TEMPO_ACERTO:
		if _pen_resultado == 1:
			marcou = true
			break

		if _pen_resultado == 2:
			marcou = false
			break

		if eh_bot and bot_marca:
			var passou := (float(Time.get_ticks_msec()) - t0) / 1000.0

			if passou >= bot_momento and not _pen_alvos.is_empty():
				var alvo_bot := int(_pen_alvos[randi() % _pen_alvos.size()])
				_flash_led(alvo_bot, true)
				_pen_resultado = 1
				marcou = true
				break

		_atualizar_contagem_penalti(t0)
		await get_tree().process_frame

	_pen_aguardando = false

	leds_ativos.clear()
	cores_leds_ativos.clear()
	_atualizar_leds_hud()
	_enviar_leds_para_arduino()

	if marcou:
		if sfx_ponto and sfx_ponto.stream:
			sfx_ponto.stop()
			sfx_ponto.play()

		_tocar_torcida_gol()
		_efeito_gol_player(p)
		_feedback_penalti(true)
	else:
		_tocar_torcida_erro()
		_feedback_penalti(false)

	await get_tree().create_timer(1.1).timeout

	return marcou


func _registrar_chute_penalti(index_led: int) -> void:
	if not _pen_aguardando:
		return

	if index_led < 0 or index_led >= LEDS_TOTAL:
		return

	if _pen_alvos.has(index_led):
		_flash_led(index_led, true)
		_pen_resultado = 1
	else:
		_flash_led(index_led, false)
		_pen_resultado = 2

	_pen_aguardando = false


func _sortear_bocas_penalti() -> Array[int]:
	var todos: Array[int] = []

	for i in range(LEDS_TOTAL):
		todos.append(i)

	todos.shuffle()

	var res: Array[int] = []

	for i in range(mini(PENALTI_QTD_BOCAS, todos.size())):
		res.append(todos[i])

	return res


# ============================================================
# OVERLAY PÊNALTIS
# ============================================================
func _criar_overlay_penalti(participantes: Array) -> void:
	if pen_layer != null and is_instance_valid(pen_layer):
		return

	pen_participantes.clear()
	pen_card_score_labels.clear()
	pen_card_status_labels.clear()
	pen_card_panels.clear()

	for p in participantes:
		pen_participantes.append(int(p))

	pen_layer = CanvasLayer.new()
	pen_layer.layer = 280
	add_child(pen_layer)

	var tela := get_viewport().get_visible_rect().size

	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0, 0, 0, 0.86)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pen_layer.add_child(fundo)

	var qtd := pen_participantes.size()
	var card_w := 210.0
	var card_gap := 16.0
	var cards_total_w := card_w * float(qtd) + card_gap * float(qtd - 1)

	var painel_w := clampf(cards_total_w + 120.0, 560.0, tela.x * 0.90)
	var painel_h := 560.0

	pen_panel = Panel.new()
	pen_panel.size = Vector2(painel_w, painel_h)
	pen_panel.position = Vector2((tela.x - painel_w) * 0.5, (tela.y - painel_h) * 0.5)
	pen_panel.modulate = Color(1, 1, 1, 0)
	pen_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pen_layer.add_child(pen_panel)

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.010, 0.014, 0.020, 0.985)
	st.border_color = COR_ALERTA
	st.set_border_width_all(4)
	st.set_corner_radius_all(0)
	st.shadow_color = Color(COR_ALERTA.r, COR_ALERTA.g, COR_ALERTA.b, 0.90)
	st.shadow_size = 48
	st.shadow_offset = Vector2.ZERO
	pen_panel.add_theme_stylebox_override("panel", st)

	var W := pen_panel.size.x

	pen_titulo = _novo_label("DISPUTA DE PÊNALTIS", 34, Color.WHITE, COR_ALERTA)
	pen_titulo.position = Vector2(0, 16)
	pen_titulo.size = Vector2(W, 48)
	pen_panel.add_child(pen_titulo)

	pen_rodada = _novo_label("", 16, COR_ALERTA, COR_ALERTA)
	pen_rodada.position = Vector2(0, 64)
	pen_rodada.size = Vector2(W, 24)
	pen_panel.add_child(pen_rodada)

	pen_chutador = _novo_label("", 28, Color.WHITE)
	pen_chutador.position = Vector2(20, 94)
	pen_chutador.size = Vector2(W - 40, 44)
	pen_panel.add_child(pen_chutador)

	var cards_x := (W - cards_total_w) * 0.5

	pen_cards_box = HBoxContainer.new()
	pen_cards_box.position = Vector2(cards_x, 150)
	pen_cards_box.size = Vector2(cards_total_w, 210)
	pen_cards_box.add_theme_constant_override("separation", int(card_gap))
	pen_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	pen_cards_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pen_panel.add_child(pen_cards_box)

	for p in pen_participantes:
		_criar_card_penalti(p)

	pen_contagem = _novo_label("", 80, COR_ALERTA, COR_ALERTA)
	pen_contagem.position = Vector2(0, 374)
	pen_contagem.size = Vector2(W, 90)
	pen_panel.add_child(pen_contagem)

	pen_feedback = _novo_label("", 26, Color.WHITE)
	pen_feedback.position = Vector2(0, 474)
	pen_feedback.size = Vector2(W, 40)
	pen_panel.add_child(pen_feedback)

	var entrada := create_tween()
	entrada.tween_property(pen_panel, "modulate", Color.WHITE, 0.22)


func _criar_card_penalti(p: int) -> void:
	var cor := cores_players[p]

	var card := Panel.new()
	card.custom_minimum_size = Vector2(210, 204)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pen_cards_box.add_child(card)

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.014, 0.018, 0.026, 0.97)
	st.border_color = Color(cor.r, cor.g, cor.b, 0.55)
	st.set_border_width_all(2)
	st.set_corner_radius_all(0)
	st.shadow_color = Color(cor.r, cor.g, cor.b, 0.25)
	st.shadow_size = 10
	card.add_theme_stylebox_override("panel", st)

	var nome := _novo_label(_nome_player(p), 17, Color.WHITE, cor)
	nome.position = Vector2(0, 12)
	nome.size = Vector2(210, 32)
	card.add_child(nome)

	var tipo := _novo_label("BOT" if _player_eh_bot(p) else "JOGADOR", 11, Color(0.62, 0.68, 0.78))
	tipo.position = Vector2(0, 44)
	tipo.size = Vector2(210, 20)
	card.add_child(tipo)

	var sub := _novo_label("PÊNALTIS", 12, Color(0.50, 0.56, 0.66))
	sub.position = Vector2(0, 70)
	sub.size = Vector2(210, 20)
	card.add_child(sub)

	var score := _novo_label("0", 66, Color.WHITE, cor)
	score.position = Vector2(0, 88)
	score.size = Vector2(210, 78)
	card.add_child(score)

	var status := _novo_label("NA DISPUTA", 12, Color(0.70, 0.76, 0.86))
	status.position = Vector2(0, 166)
	status.size = Vector2(210, 26)
	card.add_child(status)

	pen_card_panels[p] = card
	pen_card_score_labels[p] = score
	pen_card_status_labels[p] = status


func _set_overlay_penalti_chute(p: int, rodada: int) -> void:
	var cor := cores_players[p]
	var nome := _nome_player(p)

	if _player_eh_bot(p):
		nome += " BOT"

	pen_chutador.text = "VEZ DE %s" % nome
	pen_chutador.add_theme_color_override("font_color", cor)
	pen_chutador.add_theme_color_override("font_shadow_color", cor)

	if rodada > PENALTI_RODADAS_INICIAIS:
		pen_rodada.text = "MORTE SÚBITA  •  COBRANÇA %d" % rodada
	else:
		pen_rodada.text = "RODADA %d DE %d" % [rodada, PENALTI_RODADAS_INICIAIS]

	pen_feedback.text = ""
	pen_contagem.text = ""


func _atualizar_overlay_penalti(participantes: Array, pen: Dictionary, destaque: int) -> void:
	for pp in participantes:
		var p := int(pp)

		if not pen_card_score_labels.has(p):
			continue

		var score := pen_card_score_labels[p] as Label
		var status := pen_card_status_labels[p] as Label
		var card := pen_card_panels[p] as Panel
		var cor := cores_players[p]

		score.text = str(int(pen.get(p, 0)))

		if p == destaque:
			status.text = "VEZ AGORA"
			status.add_theme_color_override("font_color", cor)

			var st := card.get_theme_stylebox("panel") as StyleBoxFlat

			if st:
				st.border_color = cor
				st.shadow_color = Color(cor.r, cor.g, cor.b, 0.85)
				st.shadow_size = 22
		else:
			status.text = "NA DISPUTA"
			status.add_theme_color_override("font_color", Color(0.70, 0.76, 0.86))


func _atualizar_contagem_penalti(t0: float) -> void:
	var restante := PENALTI_TEMPO_ACERTO - (float(Time.get_ticks_msec()) - t0) / 1000.0
	restante = clampf(restante, 0.0, PENALTI_TEMPO_ACERTO)

	pen_contagem.text = "%d" % int(ceil(restante))

	if restante <= 2.0:
		pen_contagem.add_theme_color_override("font_color", COR_ERRO)
		pen_contagem.add_theme_color_override("font_shadow_color", COR_ERRO)
	else:
		pen_contagem.add_theme_color_override("font_color", COR_ALERTA)
		pen_contagem.add_theme_color_override("font_shadow_color", COR_ALERTA)


func _feedback_penalti(ok: bool) -> void:
	if ok:
		pen_feedback.text = "GOL!"
		pen_feedback.add_theme_color_override("font_color", COR_OK)
		pen_feedback.add_theme_color_override("font_shadow_color", COR_OK)
	else:
		pen_feedback.text = "PERDEU!"
		pen_feedback.add_theme_color_override("font_color", COR_ERRO)
		pen_feedback.add_theme_color_override("font_shadow_color", COR_ERRO)

	pen_contagem.text = ""


func _mostrar_vencedor_penalti(vencedor: int) -> void:
	if vencedor < 0 or vencedor >= total_players:
		return

	confronto_decidido_penaltis = true
	vencedor_penaltis_index = vencedor

	var cor := cores_players[vencedor]
	var nome := _nome_player(vencedor)

	pen_titulo.text = "FIM DOS PÊNALTIS"

	if fase_torneio == "FINAL":
		pen_chutador.text = "%s VENCEU NOS PÊNALTIS!" % nome
		pen_feedback.text = "DECISÃO DA GRANDE FINAL"
	else:
		pen_chutador.text = "%s PASSOU NOS PÊNALTIS!" % nome
		pen_feedback.text = "CLASSIFICADO NO MATA-MATA"

	pen_chutador.add_theme_color_override("font_color", cor)
	pen_chutador.add_theme_color_override("font_shadow_color", cor)

	pen_rodada.text = "EMPATE RESOLVIDO"
	pen_contagem.text = ""

	pen_feedback.add_theme_color_override("font_color", COR_ALERTA)
	pen_feedback.add_theme_color_override("font_shadow_color", COR_ALERTA)

	_tocar_audio(sfx_apito_fim)

	await get_tree().create_timer(0.22).timeout

	# Som bom de classificação, mas sem tocar campeão aqui.
	_tocar_torcida_gol()

	await get_tree().create_timer(2.0).timeout



func _remover_overlay_penalti() -> void:
	if pen_layer and is_instance_valid(pen_layer):
		pen_layer.queue_free()

	pen_layer = null
	pen_panel = null
	pen_titulo = null
	pen_rodada = null
	pen_chutador = null
	pen_contagem = null
	pen_feedback = null
	pen_cards_box = null

	pen_card_score_labels.clear()
	pen_card_status_labels.clear()
	pen_card_panels.clear()
	pen_participantes.clear()


# ============================================================
# RESULTADO
# ============================================================
func _mostrar_modal_resultado(ranking: Array) -> void:
	final_layer = CanvasLayer.new()
	final_layer.layer = 300
	add_child(final_layer)

	var tela := get_viewport().get_visible_rect().size

	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0, 0, 0, 0.90)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	final_layer.add_child(fundo)

	var cor_destaque := COR_ALERTA
	if ranking.size() > 0 and ranking[0].has("cor") and ranking[0]["cor"] is Color:
		cor_destaque = ranking[0]["cor"]

	var panel := Panel.new()
	panel.size = Vector2(minf(tela.x * 0.82, 1200.0), minf(tela.y * 0.88, 820.0))
	panel.position = (tela - panel.size) / 2.0
	panel.scale = Vector2(0.94, 0.94)
	panel.modulate = Color(1, 1, 1, 0)
	panel.clip_contents = true
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	final_layer.add_child(panel)

	var W := panel.size.x
	var H := panel.size.y

	# Moldura neon: várias camadas de sombra para dar bloom.
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.008, 0.012, 0.020, 0.99)
	style.border_color = cor_destaque
	style.set_border_width_all(3)
	style.set_corner_radius_all(0)
	style.shadow_color = Color(cor_destaque.r, cor_destaque.g, cor_destaque.b, 0.95)
	style.shadow_size = 70
	style.shadow_offset = Vector2.ZERO
	panel.add_theme_stylebox_override("panel", style)

	if ResourceLoader.exists(FUNDO_RESULT):
		var img := TextureRect.new()
		img.position = Vector2(3, 3)
		img.size = Vector2(W - 6, H - 6)
		img.texture = load(FUNDO_RESULT)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(img)

		var escuro := ColorRect.new()
		escuro.position = Vector2(3, 3)
		escuro.size = Vector2(W - 6, H - 6)
		escuro.color = Color(0.004, 0.006, 0.014, 0.82)
		escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(escuro)

	# Linhas neon (topo e base) para reforçar a moldura.
	_neon_linha_modal(panel, Vector2(0, 0), Vector2(W, 6), cor_destaque)
	_neon_linha_modal(panel, Vector2(0, H - 6), Vector2(W, 6), cor_destaque)

	var etapa := _etapa_atual_txt()

	# Título.
	var titulo_txt := "RESULTADO DA ETAPA"
	if fase_torneio == "FASE_1":
		titulo_txt = "RANKING DA CHAVE"
	elif somente_penaltis:
		titulo_txt = "RESULTADO DOS PÊNALTIS"

	var titulo := _novo_label(titulo_txt, 36, Color.WHITE, cor_destaque)
	titulo.position = Vector2(20, 22)
	titulo.size = Vector2(W - 40, 52)
	titulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.96))
	titulo.add_theme_constant_override("outline_size", 5)
	panel.add_child(titulo)

	# Chips de contexto (fase / etapa / modo).
	var chip_y := 80.0
	var chip_h := 30.0
	var cx := 40.0
	cx = _chip_info_modal(panel, cx, chip_y, chip_h, _nome_fase_bonito(fase_torneio), COR_NEON)
	cx = _chip_info_modal(panel, cx + 10.0, chip_y, chip_h, "ETAPA " + etapa, COR_ALERTA)
	cx = _chip_info_modal(panel, cx + 10.0, chip_y, chip_h, modo_partida, COR_TORNEIO)

	# Linha de destaque (líder da etapa) para 1x1.
	var destaque_txt := ""
	if modo_partida == "1X1" and total_players >= 2:
		if int(scores[0]) == int(scores[1]):
			destaque_txt = "EMPATE NA ETAPA  •  %d x %d" % [int(scores[0]), int(scores[1])]
		else:
			var lider := 0 if int(scores[0]) > int(scores[1]) else 1
			destaque_txt = "%s LEVOU A ETAPA  •  %d x %d" % [
				_nome_player(lider),
				int(scores[0]),
				int(scores[1])
			]

	if destaque_txt != "":
		var dlbl := _novo_label(destaque_txt, 18, cor_destaque, cor_destaque)
		dlbl.position = Vector2(40, chip_y + chip_h + 8.0)
		dlbl.size = Vector2(W - 80, 26)
		dlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		panel.add_child(dlbl)

	# Linhas do ranking.
	var y := 170.0
	var linha_h := clampf((H - y - 110.0) / float(maxi(ranking.size(), 1)) - 10.0, 52.0, 76.0)
	var gap := 10.0

	for item in ranking:
		if not (item is Dictionary):
			continue

		var pos := int(item.get("posicao", 0))
		var nome := str(item.get("nome", "JOGADOR"))
		if bool(item.get("boot", false)):
			nome += " BOT"

		var gols := int(item.get("gols", item.get("score", 0)))
		var pens := int(item.get("penaltis", 0))
		var jogou_pen := bool(item.get("jogou_penaltis", false))
		var cor_pos := _cor_colocacao(pos)

		var row := Panel.new()
		row.position = Vector2(40, y)
		row.size = Vector2(W - 80, linha_h)
		row.clip_contents = true
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(row)

		var rs := StyleBoxFlat.new()
		rs.bg_color = Color(cor_pos.r * 0.09, cor_pos.g * 0.09, cor_pos.b * 0.09, 0.88)
		rs.border_color = Color(cor_pos.r, cor_pos.g, cor_pos.b, 0.70)
		rs.set_border_width_all(1)
		rs.set_corner_radius_all(10)
		rs.shadow_color = Color(cor_pos.r, cor_pos.g, cor_pos.b, 0.22)
		rs.shadow_size = 12
		rs.shadow_offset = Vector2.ZERO
		row.add_theme_stylebox_override("panel", rs)

		# Faixa colorida da posição.
		var faixa := ColorRect.new()
		faixa.position = Vector2(0, 0)
		faixa.size = Vector2(7, linha_h)
		faixa.color = cor_pos
		faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(faixa)

		# Badge da posição.
		var badge := Panel.new()
		badge.position = Vector2(16, (linha_h - 40.0) * 0.5)
		badge.size = Vector2(54, 40)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(badge)

		var bst := StyleBoxFlat.new()
		bst.bg_color = Color(cor_pos.r * 0.18, cor_pos.g * 0.18, cor_pos.b * 0.18, 0.96)
		bst.border_color = cor_pos
		bst.set_border_width_all(2)
		bst.set_corner_radius_all(8)
		bst.shadow_color = Color(cor_pos.r, cor_pos.g, cor_pos.b, 0.45)
		bst.shadow_size = 10
		badge.add_theme_stylebox_override("panel", bst)

		var lbl_pos := _novo_label("%dº" % pos, 22, Color.WHITE, cor_pos)
		lbl_pos.position = Vector2.ZERO
		lbl_pos.size = badge.size
		badge.add_child(lbl_pos)

		# Nome.
		var lbl_nome := _novo_label(nome, 21, Color.WHITE, cor_pos)
		lbl_nome.position = Vector2(86, 0)
		lbl_nome.size = Vector2(W * 0.32, linha_h)
		lbl_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl_nome.clip_text = true
		row.add_child(lbl_nome)

		# Gols (destaque).
		var lbl_gols := _novo_label("%d" % gols, 30, COR_OK, COR_OK)
		lbl_gols.position = Vector2(W * 0.45, 0)
		lbl_gols.size = Vector2(90, linha_h)
		lbl_gols.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(lbl_gols)

		var lbl_gols_txt := _novo_label("GOLS", 13, Color(0.66, 0.74, 0.84))
		lbl_gols_txt.position = Vector2(W * 0.45 + 96.0, 0)
		lbl_gols_txt.size = Vector2(70, linha_h)
		lbl_gols_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(lbl_gols_txt)

		# Chip extra (pênaltis / posição na etapa).
		var extra_txt := ""
		var extra_cor := Color(0.66, 0.74, 0.84)

		if jogou_pen or somente_penaltis:
			extra_txt = "PÊNALTIS %d" % pens
			extra_cor = COR_ALERTA
		elif modo_partida == "1X1":
			extra_txt = "ETAPA " + etapa
			extra_cor = COR_NEON
		else:
			extra_txt = "%dº NA CHAVE" % pos
			extra_cor = COR_OK if pos <= 2 else Color(0.60, 0.64, 0.72)

		var chip := Panel.new()
		var chip_w := 150.0
		chip.position = Vector2(row.size.x - chip_w - 12.0, (linha_h - 30.0) * 0.5)
		chip.size = Vector2(chip_w, 30.0)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(chip)

		var cst := StyleBoxFlat.new()
		cst.bg_color = Color(extra_cor.r * 0.14, extra_cor.g * 0.14, extra_cor.b * 0.14, 0.95)
		cst.border_color = extra_cor
		cst.set_border_width_all(1)
		cst.set_corner_radius_all(8)
		chip.add_theme_stylebox_override("panel", cst)

		var clbl := _novo_label(extra_txt, 14, Color.WHITE, extra_cor)
		clbl.position = Vector2.ZERO
		clbl.size = chip.size
		chip.add_child(clbl)

		y += linha_h + gap

	# Nota de regra (informativo).
	var nota_txt := "O CONFRONTO É DECIDIDO NO AGREGADO (IDA + VOLTA) NO LOBBY."
	if fase_torneio == "FASE_1":
		nota_txt = "OS 2 MELHORES DA CHAVE (SOMA IDA + VOLTA) AVANÇAM."

	var nota := _novo_label(nota_txt, 14, Color(0.70, 0.80, 0.92))
	nota.position = Vector2(40, H - 96)
	nota.size = Vector2(W - 80, 24)
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel.add_child(nota)

	# Contador + barra.
	var segundos := 8

	var contador := _novo_label("VOLTANDO EM %d" % segundos, 17, COR_ALERTA, COR_ALERTA)
	contador.position = Vector2(0, H - 70)
	contador.size = Vector2(W, 26)
	panel.add_child(contador)

	var barra_bg := ColorRect.new()
	barra_bg.position = Vector2(90, H - 38)
	barra_bg.size = Vector2(W - 180, 6)
	barra_bg.color = Color(1, 1, 1, 0.12)
	barra_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(barra_bg)

	var barra := ColorRect.new()
	barra.position = barra_bg.position
	barra.size = barra_bg.size
	barra.color = cor_destaque
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(barra)

	var entrada := create_tween()
	entrada.set_parallel(true)
	entrada.tween_property(panel, "modulate", Color.WHITE, 0.22)
	entrada.tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await entrada.finished

	for n in range(segundos, 0, -1):
		if is_instance_valid(contador):
			contador.text = "VOLTANDO EM %d" % n
		if is_instance_valid(barra):
			barra.size.x = (W - 180) * (float(n) / float(segundos))
		await get_tree().create_timer(1.0).timeout

	if is_instance_valid(final_layer):
		final_layer.queue_free()

	final_layer = null



func _mostrar_aviso_turno(titulo_texto: String, subtitulo_texto: String, cor: Color) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 260
	add_child(layer)

	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0, 0, 0, 0.0)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fundo)

	var panel := Panel.new()
	panel.size = Vector2(900, 270)
	panel.position = (get_viewport().get_visible_rect().size - panel.size) / 2.0
	panel.scale = Vector2(0.92, 0.92)
	panel.modulate = Color(1, 1, 1, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.010, 0.014, 0.020, 0.97)
	style.border_color = cor
	style.set_border_width_all(4)
	style.set_corner_radius_all(36)
	style.shadow_color = Color(cor.r, cor.g, cor.b, 0.78)
	style.shadow_size = 40
	style.shadow_offset = Vector2.ZERO
	panel.add_theme_stylebox_override("panel", style)

	var titulo := _novo_label(titulo_texto, 42, Color.WHITE, cor)
	titulo.position = Vector2(0, 44)
	titulo.size = Vector2(900, 70)
	panel.add_child(titulo)

	var subtitulo := _novo_label(subtitulo_texto, 23, Color(0.78, 0.90, 0.95))
	subtitulo.position = Vector2(40, 142)
	subtitulo.size = Vector2(820, 74)
	subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(subtitulo)

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(fundo, "color", Color(0, 0, 0, 0.68), 0.22)
	t.tween_property(panel, "modulate", Color.WHITE, 0.22)
	t.tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await t.finished
	await get_tree().create_timer(1.35).timeout

	var out := create_tween()
	out.set_parallel(true)
	out.tween_property(fundo, "color", Color(0, 0, 0, 0.0), 0.20)
	out.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.20)
	out.tween_property(panel, "scale", Vector2(0.94, 0.94), 0.20)

	await out.finished

	if is_instance_valid(layer):
		layer.queue_free()


# ============================================================
# BOT
# ============================================================
func _sortear_proximo_gol_bot() -> void:
	bot_timer_gol = 0.0
	bot_proximo_gol_em = randf_range(BOT_INTERVALO_GOL_MIN, BOT_INTERVALO_GOL_MAX)


func _pontuacao_alvo_bot() -> int:
	match fase_torneio:
		"FASE_1":
			return randi_range(2, 6)
		"FINAL":
			return randi_range(8, 15)
		_:
			return randi_range(4, 10)


func _processar_bot(delta: float) -> void:
	if not BOT_JOGA_SOZINHO:
		return

	if not partida_ativa:
		return

	if not _player_eh_bot(player_atual):
		return

	bot_timer_gol += delta

	if bot_timer_gol < bot_proximo_gol_em:
		return

	bot_timer_gol = 0.0
	bot_proximo_gol_em = randf_range(BOT_INTERVALO_GOL_MIN, BOT_INTERVALO_GOL_MAX)

	if scores[player_atual] >= _pontuacao_alvo_bot():
		return

	if leds_ativos.is_empty():
		return

	var index_led := int(leds_ativos[randi() % leds_ativos.size()])
	_processar_input_led(index_led, true)


# ============================================================
# LOADING
# ============================================================
func _criar_tela_carregamento(titulo_txt: String, sub_txt: String) -> void:
	loading_layer = CanvasLayer.new()
	loading_layer.layer = 500
	add_child(loading_layer)

	loading_root = Control.new()
	loading_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_layer.add_child(loading_root)

	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.004, 0.007, 0.014, 1.0)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_root.add_child(fundo)

	if ResourceLoader.exists(IMAGEM_LOADING):
		var img := TextureRect.new()
		img.set_anchors_preset(Control.PRESET_FULL_RECT)
		img.texture = load(IMAGEM_LOADING)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		loading_root.add_child(img)

	var escuro := ColorRect.new()
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	escuro.color = Color(0, 0, 0, 0.48)
	escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_root.add_child(escuro)


	var tela := get_viewport().get_visible_rect().size

	var painel := Panel.new()
	painel.size = Vector2(minf(tela.x * 0.62, 860.0), 300)
	painel.position = Vector2((tela.x - painel.size.x) * 0.5, (tela.y - painel.size.y) * 0.5)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_root.add_child(painel)

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.012, 0.018, 0.030, 0.965)
	st.border_color = COR_TORNEIO
	st.set_border_width_all(4)
	st.set_corner_radius_all(34)
	st.shadow_color = Color(COR_TORNEIO.r, COR_TORNEIO.g, COR_TORNEIO.b, 0.78)
	st.shadow_size = 42
	st.shadow_offset = Vector2.ZERO
	painel.add_theme_stylebox_override("panel", st)

	var W := painel.size.x
	var H := painel.size.y

	loading_label = _novo_label(titulo_txt, 36, Color.WHITE, COR_TORNEIO)
	loading_label.position = Vector2(30, 44)
	loading_label.size = Vector2(W - 60, 58)
	painel.add_child(loading_label)

	loading_sub = _novo_label(sub_txt, 19, Color(0.72, 0.84, 0.96))
	loading_sub.position = Vector2(30, 118)
	loading_sub.size = Vector2(W - 60, 36)
	painel.add_child(loading_sub)

	loading_pct = _novo_label("0%", 30, COR_ALERTA, COR_ALERTA)
	loading_pct.position = Vector2(0, H - 118)
	loading_pct.size = Vector2(W, 40)
	painel.add_child(loading_pct)

	var barra_bg := ColorRect.new()
	barra_bg.position = Vector2(70, H - 70)
	barra_bg.size = Vector2(W - 140, 10)
	barra_bg.color = Color(1, 1, 1, 0.12)
	barra_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(barra_bg)

	loading_barra_w_max = barra_bg.size.x

	loading_barra = ColorRect.new()
	loading_barra.position = barra_bg.position
	loading_barra.size = Vector2(6, 10)
	loading_barra.color = COR_TORNEIO
	loading_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(loading_barra)

	loading_frac_atual = 0.0


func _listar_imagens_patrocinadores() -> Array[String]:
	var imagens: Array[String] = []

	for caminho in PATROCINADORES_FIXOS:
		if ResourceLoader.exists(caminho):
			if not imagens.has(caminho):
				imagens.append(caminho)
		else:
			push_warning("Patrocinador não encontrado: " + caminho)

	return imagens


func _adicionar_rodape_patrocinadores_loading(alvo: Control) -> void:
	if alvo == null:
		return

	var imagens := _listar_imagens_patrocinadores()

	if imagens.is_empty():
		return

	var tela := get_viewport().get_visible_rect().size
	var total := imagens.size()

	var max_por_linha := 8

	if total <= 4:
		max_por_linha = total
	elif total <= 6:
		max_por_linha = 6
	else:
		max_por_linha = 8

	max_por_linha = maxi(max_por_linha, 1)

	var linhas := int(ceil(float(total) / float(max_por_linha)))
	linhas = maxi(linhas, 1)

	var margem_x := 54.0
	var gap := 18.0
	var row_gap := 12.0
	var card_h := 84.0

	if linhas == 2:
		card_h = 72.0
	elif linhas >= 3:
		card_h = 60.0

	var footer_h := float(linhas) * card_h + float(maxi(linhas - 1, 0)) * row_gap + 32.0
	var footer_y := tela.y - footer_h - 14.0

	var fundo := Panel.new()
	fundo.position = Vector2(32.0, footer_y)
	fundo.size = Vector2(tela.x - 64.0, footer_h)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.clip_contents = true
	alvo.add_child(fundo)

	var fundo_style := StyleBoxFlat.new()
	fundo_style.bg_color = Color(0.004, 0.012, 0.020, 0.86)
	fundo_style.border_color = Color(COR_TORNEIO.r, COR_TORNEIO.g, COR_TORNEIO.b, 0.50)
	fundo_style.set_border_width_all(2)
	fundo_style.set_corner_radius_all(0)
	fundo_style.shadow_color = Color(COR_TORNEIO.r, COR_TORNEIO.g, COR_TORNEIO.b, 0.40)
	fundo_style.shadow_size = 24
	fundo_style.shadow_offset = Vector2.ZERO
	fundo.add_theme_stylebox_override("panel", fundo_style)

	if ResourceLoader.exists(IMAGEM_FUNDO_FOOTER_PATRO):
		var img_fundo := TextureRect.new()
		img_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
		img_fundo.texture = load(IMAGEM_FUNDO_FOOTER_PATRO)
		img_fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img_fundo.stretch_mode = TextureRect.STRETCH_SCALE
		img_fundo.modulate = Color(1, 1, 1, 0.52)
		img_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fundo.add_child(img_fundo)

		var escuro := ColorRect.new()
		escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
		escuro.color = Color(0, 0, 0, 0.42)
		escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fundo.add_child(escuro)

	var brilho := ColorRect.new()
	brilho.position = Vector2(24, 10)
	brilho.size = Vector2(fundo.size.x - 48, 3)
	brilho.color = Color(1, 1, 1, 0.14)
	brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_child(brilho)

	for linha in range(linhas):
		var inicio := linha * max_por_linha
		var fim := mini(inicio + max_por_linha, total)
		var qtd := fim - inicio

		if qtd <= 0:
			continue

		var area_w := fundo.size.x - margem_x * 2.0
		var card_w := (area_w - gap * float(qtd - 1)) / float(qtd)
		card_w = clampf(card_w, 110.0, 230.0)

		var total_w := card_w * float(qtd) + gap * float(qtd - 1)
		var x0 := (fundo.size.x - total_w) * 0.5
		var y0 := 16.0 + float(linha) * (card_h + row_gap)

		for i in range(qtd):
			var caminho := imagens[inicio + i]
			var card := _criar_card_patrocinador_loading(caminho, Vector2(card_w, card_h))
			card.position = Vector2(x0 + float(i) * (card_w + gap), y0)
			card.modulate = Color(1, 1, 1, 0)
			card.scale = Vector2(0.94, 0.94)
			fundo.add_child(card)

			var delay := float(inicio + i) * 0.025
			var t := create_tween()
			t.set_parallel(true)
			t.tween_property(card, "modulate", Color.WHITE, 0.22).set_delay(delay)
			t.tween_property(card, "scale", Vector2.ONE, 0.22).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _criar_card_patrocinador_loading(caminho: String, tamanho: Vector2) -> Panel:
	var card := Panel.new()
	card.size = tamanho
	card.custom_minimum_size = tamanho
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.clip_contents = true

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.02, 0.04, 0.07, 0.92)
	st.border_color = Color(COR_TORNEIO.r, COR_TORNEIO.g, COR_TORNEIO.b, 0.70)
	st.set_border_width_all(2)
	st.set_corner_radius_all(14)
	st.shadow_color = Color(COR_TORNEIO.r, COR_TORNEIO.g, COR_TORNEIO.b, 0.30)
	st.shadow_size = 12
	st.shadow_offset = Vector2.ZERO
	card.add_theme_stylebox_override("panel", st)

	var img := TextureRect.new()
	img.position = Vector2(8, 8)
	img.size = tamanho - Vector2(16, 16)
	img.texture = load(caminho)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(img)

	return card


func _aplicar_frac_loading(v: float) -> void:
	var frac := clampf(v, 0.0, 1.0)

	if loading_barra and is_instance_valid(loading_barra):
		loading_barra.size.x = maxf(loading_barra_w_max * frac, 6.0)

	if loading_pct and is_instance_valid(loading_pct):
		loading_pct.text = "%d%%" % int(round(frac * 100.0))


func _set_progresso_carregamento(p: float, texto: String, dur: float = 0.3) -> void:
	if loading_layer == null or not is_instance_valid(loading_layer):
		return

	var alvo := clampf(p, 0.0, 1.0)

	if loading_sub:
		loading_sub.text = texto

	if tween_loading_barra != null and tween_loading_barra.is_running():
		tween_loading_barra.kill()

	var inicio := loading_frac_atual
	loading_frac_atual = alvo

	tween_loading_barra = create_tween()
	tween_loading_barra.tween_method(_aplicar_frac_loading, inicio, alvo, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)



func _remover_tela_carregamento() -> void:
	if loading_layer == null or not is_instance_valid(loading_layer):
		return

	_leds_loading_roxo_off()

	_aplicar_frac_loading(1.0)

	if loading_root and is_instance_valid(loading_root):
		var t := create_tween()
		t.tween_property(loading_root, "modulate", Color(1, 1, 1, 0), 0.30)
		await t.finished

	if is_instance_valid(loading_layer):
		loading_layer.queue_free()

	loading_layer = null
	loading_root = null
	loading_label = null
	loading_sub = null
	loading_pct = null
	loading_barra = null


# ============================================================
# ÁUDIO
# ============================================================
func _criar_audios() -> void:
	audio_fundo = AudioStreamPlayer.new()
	audio_fundo.name = "MusicaPlayerAtual"
	add_child(audio_fundo)

	# Música base fica apenas como fallback.
	# A música real de cada jogador será tocada em _mostrar_preparacao_player()
	# usando _tocar_musica_do_player(player_atual).
	if ResourceLoader.exists(MUSICA_PLAY):
		var stream_base: AudioStream = load(MUSICA_PLAY)

		if stream_base is AudioStreamMP3:
			stream_base.loop = true

		audio_fundo.stream = stream_base
		audio_fundo.volume_db = -7.0
	else:
		push_warning("Música base não encontrada: " + MUSICA_PLAY)

	sfx_ponto = _criar_sfx(SFX_PONTO, 0.0)
	sfx_apito_init = _criar_sfx(SFX_APITO_INIT, 1.5)
	sfx_apito_troca = _criar_sfx(SFX_APITO_TROCA, 1.5)
	sfx_apito_fim = _criar_sfx(SFX_APITO_FIM, 1.8)
	sfx_game_start = _criar_sfx(SFX_GAME_START, 0.0)
	sfx_campeao = _criar_sfx(SFX_CAMPEAO, 1.5)

	sfx_torcida_gol.clear()
	sfx_torcida_erro.clear()

	sfx_torcida_gol = _criar_banco_sfx(SFX_TORCIDA_GOL, VOLUME_TORCIDA_PADRAO_DB)
	sfx_inicio_hype = _criar_banco_sfx(SFX_INICIO_HYPE, VOLUME_TORCIDA_PADRAO_DB)
	sfx_torcida_erro = _criar_banco_sfx(SFX_TORCIDA_ERRO, VOLUME_TORCIDA_ERRO_DB)



func _sortear_musicas_players() -> void:
	musicas_por_player.clear()

	var disponiveis: Array[AudioStream] = []

	for caminho in MUSICAS_PLAYERS:
		if ResourceLoader.exists(caminho):
			var stream := load(caminho)

			if stream is AudioStreamMP3:
				stream.loop = true

			disponiveis.append(stream)
		else:
			push_warning("Música de player não encontrada: " + caminho)

	if disponiveis.is_empty():
		push_warning("Nenhuma música de player encontrada. Usando música base como fallback.")
		for i in range(total_players):
			musicas_por_player.append(null)
		return

	disponiveis.shuffle()

	for i in range(total_players):
		if i < disponiveis.size():
			musicas_por_player.append(disponiveis[i])
		else:
			var repetida: AudioStream = disponiveis[int(randi() % disponiveis.size())]
			musicas_por_player.append(repetida)

	print("MÚSICAS DOS PLAYERS SORTEADAS: ", musicas_por_player.size())



func _tocar_musica_do_player(index: int) -> void:
	if audio_fundo == null:
		return

	var stream: AudioStream = null

	if index >= 0 and index < musicas_por_player.size():
		if musicas_por_player[index] is AudioStream:
			stream = musicas_por_player[index]

	if stream == null:
		if ResourceLoader.exists(MUSICA_PLAY):
			stream = load(MUSICA_PLAY)

			if stream is AudioStreamMP3:
				stream.loop = true
		else:
			push_warning("Sem música para tocar no player: " + str(index))
			return

	audio_fundo.stop()
	audio_fundo.stream = stream
	audio_fundo.volume_db = -6.0
	audio_fundo.play()

	print("TOCANDO MÚSICA DO PLAYER ", index + 1, ": ", stream)


func _criar_banco_sfx(caminhos: Array[String], volume_db: float) -> Array[AudioStreamPlayer]:
	var banco: Array[AudioStreamPlayer] = []

	for caminho in caminhos:
		if not ResourceLoader.exists(caminho):
			push_warning("SFX não encontrado: " + caminho)
			continue

		var volume_final := volume_db
		var arquivo := caminho.get_file().to_lower()

		# Aumenta SOMENTE torcida_1, torcida_2 e torcida_3.
		if arquivo == "torcida_1.mp3" \
		or arquivo == "torcida_2.mp3" \
		or arquivo == "torcida_3.mp3":
			volume_final = VOLUME_TORCIDA_123_DB

		var p := _criar_sfx(caminho, volume_final)

		if p != null and p.stream != null:
			banco.append(p)

	return banco



func _garantir_musica_play() -> void:
	if audio_fundo == null:
		return

	if audio_fundo.stream == null:
		return

	if not audio_fundo.playing:
		audio_fundo.play()


func _parar_banco_sfx(banco: Array[AudioStreamPlayer]) -> void:
	for p in banco:
		if p != null and p.playing:
			p.stop()



func _tocar_torcida_gol() -> void:
	if sfx_torcida_gol.is_empty():
		return

	# Apenas UM som de torcida por vez (inclui o hype de início).
	_parar_banco_sfx(sfx_inicio_hype)
	_parar_banco_sfx(sfx_torcida_erro)
	_parar_banco_sfx(sfx_torcida_gol)
	_parar_banco_sfx(sfx_good_player)

	var idx := randi() % sfx_torcida_gol.size()

	if sfx_torcida_gol.size() > 1:
		var trava := 0

		while idx == _ultimo_sfx_gol and trava < 8:
			idx = randi() % sfx_torcida_gol.size()
			trava += 1

	_ultimo_sfx_gol = idx
	_tocar_audio(sfx_torcida_gol[idx])



func _tocar_inicio_hype() -> void:
	if sfx_inicio_hype.is_empty():
		return

	var idx := randi() % sfx_inicio_hype.size()

	if sfx_inicio_hype.size() > 1:
		var trava := 0
		while idx == _ultimo_sfx_inicio and trava < 8:
			idx = randi() % sfx_inicio_hype.size()
			trava += 1

	_ultimo_sfx_inicio = idx
	_tocar_audio(sfx_inicio_hype[idx])


func _tocar_torcida_erro() -> void:
	if sfx_torcida_erro.is_empty():
		return

	_parar_banco_sfx(sfx_inicio_hype)
	_parar_banco_sfx(sfx_torcida_gol)
	_parar_banco_sfx(sfx_torcida_erro)

	var idx := randi() % sfx_torcida_erro.size()

	if sfx_torcida_erro.size() > 1:
		var trava := 0

		while idx == _ultimo_sfx_erro and trava < 8:
			idx = randi() % sfx_torcida_erro.size()
			trava += 1

	_ultimo_sfx_erro = idx
	_tocar_audio(sfx_torcida_erro[idx])



func _criar_sfx(caminho: String, volume_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = caminho.get_file().get_basename()
	add_child(p)

	if ResourceLoader.exists(caminho):
		p.stream = load(caminho)
		p.volume_db = volume_db

		if p.stream is AudioStreamMP3:
			p.stream.loop = false
	else:
		push_warning("SFX não encontrado: " + caminho)

	return p


func _tocar_audio(player: AudioStreamPlayer) -> void:
	if player != null and player.stream != null:
		player.stop()
		player.play()



func _animar_score(index: int) -> void:
	if index < 0 or index >= score_labels.size():
		return

	var label := score_labels[index]
	var cor := cores_players[index]

	label.scale = Vector2(1.55, 1.55)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", cor)

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(label, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "modulate", Color(1.35, 1.35, 1.35, 1.0), 0.10)
	t.tween_property(label, "modulate", Color.WHITE, 0.22).set_delay(0.10)


# ============================================================
# ARDUINO
# ============================================================
func _abrir_serial_arduino() -> void:
	if not USAR_ARDUINO:
		return

	if not USAR_PONTE_POWERSHELL:
		return

	_matar_pontes_powershell_antigas()
	await get_tree().create_timer(0.35).timeout

	_iniciar_ponte_powershell()

	await get_tree().create_timer(2.6).timeout

	_serial_write("OFF")
	await get_tree().create_timer(0.15).timeout


func _matar_pontes_powershell_antigas() -> void:
	var output: Array = []

	var comando := """
Get-CimInstance Win32_Process -Filter "name = 'powershell.exe'" |
Where-Object { $_.CommandLine -like '*arduino_bridge_torment.ps1*' -or $_.CommandLine -like '*arduino_bridge_cup.ps1*' -or $_.CommandLine -like '*arduino_bridge.ps1*' } |
ForEach-Object {
	try { Stop-Process -Id $_.ProcessId -Force } catch {}
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


func _iniciar_ponte_powershell() -> void:
	caminho_log_arduino = ProjectSettings.globalize_path("user://arduino_log_torment.txt")
	caminho_script_arduino = ProjectSettings.globalize_path("user://arduino_bridge_torment.ps1")
	caminho_fila_arduino = ProjectSettings.globalize_path("user://arduino_queue_torment")

	DirAccess.make_dir_recursive_absolute(caminho_fila_arduino)

	var dir := DirAccess.open(caminho_fila_arduino)

	if dir:
		dir.list_dir_begin()
		var nome := dir.get_next()

		while nome != "":
			if not dir.current_is_dir() and nome.ends_with(".cmd"):
				dir.remove(nome)

			nome = dir.get_next()

		dir.list_dir_end()

	var flog := FileAccess.open(caminho_log_arduino, FileAccess.WRITE)

	if flog:
		flog.store_string("INICIANDO LOG DA PONTE ARDUINO TORMENT\n")
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
		SERIAL_PORTA,
		SERIAL_BAUD,
		caminho_fila_arduino.replace("\\", "\\\\"),
		caminho_log_arduino.replace("\\", "\\\\")
	]

	var fs := FileAccess.open(caminho_script_arduino, FileAccess.WRITE)

	if fs == null:
		push_error("Não consegui criar script da ponte PowerShell.")
		return

	fs.store_string(script)
	fs.close()

	var args := [
		"-NoProfile",
		"-ExecutionPolicy",
		"Bypass",
		"-File",
		caminho_script_arduino
	]

	ponte_ps_pid = OS.create_process("powershell.exe", args, false)


func _serial_write(texto: String) -> void:
	if not USAR_ARDUINO:
		return

	var cmd := texto.strip_edges()

	if cmd == "":
		return

	if not USAR_PONTE_POWERSHELL:
		return

	if caminho_fila_arduino == "":
		return

	DirAccess.make_dir_recursive_absolute(caminho_fila_arduino)

	var nome_arquivo := "%020d_%06d.cmd" % [
		Time.get_ticks_msec(),
		randi() % 1000000
	]

	var caminho_temp := caminho_fila_arduino.path_join(nome_arquivo + ".tmp")
	var caminho_final := caminho_fila_arduino.path_join(nome_arquivo)

	var f := FileAccess.open(caminho_temp, FileAccess.WRITE)

	if f == null:
		return

	f.store_string(cmd)
	f.close()

	DirAccess.rename_absolute(caminho_temp, caminho_final)


func _enviar_leds_para_arduino() -> void:
	if not USAR_ARDUINO:
		return

	# Envia SEMPRE o estado completo: ativos com cor, inativos apagados (0,0,0).
	# Assim o LED acertado apaga de fato, sem depender do firmware "lembrar".
	var partes: Array[String] = []

	for i in range(LEDS_TOTAL):
		if i < 0 or i >= LEDS_LETRAS.size():
			continue

		var rgb: Array

		if leds_ativos.has(i):
			rgb = _rgb_led_por_index(i)
		else:
			rgb = [0, 0, 0]

		partes.append("%s=%d,%d,%d" % [
			LEDS_LETRAS[i],
			int(clamp(rgb[0], 0, 255)),
			int(clamp(rgb[1], 0, 255)),
			int(clamp(rgb[2], 0, 255))
		])

	_serial_write("SET:" + ";".join(partes))


# ============================================================
# HELPERS
# ============================================================
func _travar_modo_arcade() -> void:
	RenderingServer.set_default_clear_color(Color(0.004, 0.007, 0.014, 1.0))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().auto_accept_quit = false


func _carregar_fontes() -> void:
	if ResourceLoader.exists(FONTE_ORBITRON):
		fonte_orbitron = load(FONTE_ORBITRON)


func _nome_player(index: int) -> String:
	if index >= 0 and index < nomes_players.size():
		return nomes_players[index]

	return "PLAYER %d" % (index + 1)


func _player_eh_bot(index: int) -> bool:
	if index < 0 or index >= jogadores_torneio.size():
		return false

	var j: Dictionary = jogadores_torneio[index]

	return bool(j.get("boot", false))



func _tempo_do_player(index: int) -> float:
	if not _player_eh_bot(index):
		return TEMPO_PLAYER_REAL

	match fase_torneio:
		"FASE_1":
			return 6.0
		"SEGUNDA_FASE", "PLAYIN_24_PARA_16":
			return 9.0
		"OITAVAS":
			return 12.0
		"QUARTAS":
			return 15.0
		"SEMIFINAL":
			return 18.0
		"FINAL":
			return 21.0

	return 9.0




func _nome_fase(fase: String) -> String:
	match fase:
		"FASE_1":
			return "PRIMEIRA FASE — CHAVE"
		"SEGUNDA_FASE":
			return "SEGUNDA FASE — 16→8"
		"PLAYIN_24_PARA_16":
			return "SEGUNDA FASE — 16→8"
		"OITAVAS":
			return "OITAVAS DE FINAL"
		"QUARTAS":
			return "QUARTAS DE FINAL"
		"SEMIFINAL":
			return "SEMIFINAL"
		"FINAL":
			return "GRANDE FINAL"

	return "TORNEIO"


func _novo_label(txt: String, tam: int, cor: Color, sombra: Color = Color.TRANSPARENT) -> Label:
	var l := Label.new()
	l.text = txt
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.clip_text = true

	if fonte_orbitron:
		l.add_theme_font_override("font", fonte_orbitron)

	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)

	if sombra.a > 0.0:
		l.add_theme_color_override("font_shadow_color", sombra)
		l.add_theme_constant_override("shadow_offset_x", 0)
		l.add_theme_constant_override("shadow_offset_y", 0)

	return l


func _novo_label_card(texto: String, largura: float, centro_y: float, fonte_size: int, cor: Color) -> Label:
	var lbl := Label.new()
	lbl.text = texto

	var altura := float(fonte_size) + 14.0

	lbl.position = Vector2(0, centro_y - altura * 0.5)
	lbl.size = Vector2(largura, altura)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", fonte_size)
	lbl.add_theme_color_override("font_color", cor)
	lbl.add_theme_constant_override("shadow_offset_x", 0)
	lbl.add_theme_constant_override("shadow_offset_y", 0)
	lbl.clip_text = true

	if fonte_orbitron:
		lbl.add_theme_font_override("font", fonte_orbitron)

	return lbl


func _adicionar_fundo_stadio() -> void:
	if not ResourceLoader.exists(IMAGEM_FUNDO_STADIO):
		return

	var tela := get_viewport().get_visible_rect().size
	var header_h := 82.0

	var img := TextureRect.new()
	img.position = Vector2(0, header_h)
	img.size = Vector2(tela.x, tela.y - header_h)
	img.texture = load(IMAGEM_FUNDO_STADIO)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(img)

	var escuro := ColorRect.new()
	escuro.position = Vector2(0, header_h)
	escuro.size = Vector2(tela.x, tela.y - header_h)
	escuro.color = Color(0, 0, 0, 0.36)
	escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(escuro)


func _adicionar_fundo_imagem_card_player(panel: Panel, index: int, cor: Color) -> void:
	var caminho := _caminho_fundo_card_player(index)

	if caminho == "" or not ResourceLoader.exists(caminho):
		return

	var inset := 5.0
	var tam_img := panel.size - Vector2(inset * 2.0, inset * 2.0)

	var img := TextureRect.new()
	img.position = Vector2(inset, inset)
	img.size = tam_img
	img.texture = load(caminho)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(img)

	var tint := ColorRect.new()
	tint.position = Vector2(inset, inset)
	tint.size = tam_img
	tint.color = Color(cor.r, cor.g, cor.b, 0.10)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(tint)

	var escuro := ColorRect.new()
	escuro.position = Vector2(inset, inset)
	escuro.size = tam_img
	escuro.color = Color(0, 0, 0, 0.44)
	escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(escuro)


func _caminho_fundo_card_player(index: int) -> String:
	if index >= 0 and index < jogadores_torneio.size():
		var j: Dictionary = jogadores_torneio[index]
		var nome_cor := str(j.get("cor_nome", "")).strip_edges().to_upper()

		if nome_cor.contains("AZUL"):
			return FUNDO_CARD_AZUL
		if nome_cor.contains("VERDE"):
			return FUNDO_CARD_VERDE
		if nome_cor.contains("VERMELHO"):
			return FUNDO_CARD_VERMELHO
		if nome_cor.contains("AMARELO"):
			return FUNDO_CARD_AMARELO

		var cor_index := int(j.get("cor_index", -1))

		match cor_index:
			0:
				return FUNDO_CARD_VERMELHO
			1:
				return FUNDO_CARD_VERDE
			2:
				return FUNDO_CARD_AZUL
			3:
				return FUNDO_CARD_AMARELO

	return ""


func _aplicar_fundo_modal_prep(index: int) -> void:
	if overlay_fundo_img == null:
		return

	var caminho := _caminho_fundo_prep_player(index)

	if caminho == "" or not ResourceLoader.exists(caminho):
		overlay_fundo_img.visible = false
		return

	overlay_fundo_img.texture = load(caminho)
	overlay_fundo_img.visible = true


func _caminho_fundo_prep_player(index: int) -> String:
	if index >= 0 and index < jogadores_torneio.size():
		var j: Dictionary = jogadores_torneio[index]
		var nome_cor := str(j.get("cor_nome", "")).strip_edges().to_upper()

		if nome_cor.contains("AZUL"):
			return FUNDO_PREP_AZUL
		if nome_cor.contains("VERDE"):
			return FUNDO_PREP_VERDE
		if nome_cor.contains("VERMELHO"):
			return FUNDO_PREP_VERMELHO
		if nome_cor.contains("AMARELO"):
			return FUNDO_PREP_AMARELO

		var cor_index := int(j.get("cor_index", -1))

		match cor_index:
			0:
				return FUNDO_PREP_VERMELHO
			1:
				return FUNDO_PREP_VERDE
			2:
				return FUNDO_PREP_AZUL
			3:
				return FUNDO_PREP_AMARELO

	return ""


func _cobrir_tela_para_transicao() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 9999
	add_child(cl)

	var cover := ColorRect.new()
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.color = Color(0.004, 0.007, 0.014, 1.0)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(cover)


# ============================================================
# FECHAMENTO
# ============================================================
func _fechar_jogo_arcade() -> void:
	if fechando_jogo:
		return

	fechando_jogo = true

	_serial_write("OFF")

	if audio_fundo:
		audio_fundo.stop()

	if USAR_PONTE_POWERSHELL and caminho_fila_arduino != "":
		var nome_arquivo := "%020d_EXIT.cmd" % Time.get_ticks_msec()
		var caminho_final := caminho_fila_arduino.path_join(nome_arquivo)

		var f := FileAccess.open(caminho_final, FileAccess.WRITE)

		if f:
			f.store_string("__EXIT__")
			f.close()

	# Garante que a ponte morra e libere a COM5, senão a tela de
	# abertura não acende os LEDs no próximo boot.
	await get_tree().create_timer(0.18).timeout
	_matar_pontes_powershell_antigas()
	await get_tree().create_timer(0.10).timeout

	get_tree().quit()



func _exit_tree() -> void:
	_serial_write("OFF")

	if audio_fundo:
		audio_fundo.stop()



func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST]:
		return



func _aplicar_destaque_painel_player(index: int, ativo: bool) -> void:
	if index < 0 or index >= player_panels.size():
		return

	var p := player_panels[index]

	if not is_instance_valid(p):
		return

	p.pivot_offset = p.size * 0.5

	if ativo:
		# Antes estava muito grande.
		# Agora só dá presença visual sem invadir os outros cards.
		if p.scale.x < 1.015:
			p.scale = Vector2(1.020, 1.020)

		p.z_index = 30
	else:
		if p.scale.x > 1.010:
			p.scale = Vector2.ONE

		p.z_index = 0


func _efeito_gol_player(index: int) -> void:
	_efeito_gol_card(index)
	_explosao_gol(index)
	_mostrar_popup_ponto(index, 1)


func _efeito_gol_card(index: int) -> void:
	if index < 0 or index >= player_panels.size():
		return

	var panel := player_panels[index]

	if not is_instance_valid(panel):
		return

	var cor := cores_players[index]

	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(cor.r, cor.g, cor.b, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 70
	panel.add_child(flash)

	var escala_original := panel.scale
	panel.pivot_offset = panel.size * 0.5

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(panel, "scale", escala_original * 1.07, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(panel, "scale", escala_original, 0.26).set_delay(0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(flash, "color", Color(cor.r, cor.g, cor.b, 0.55), 0.07)
	t.tween_property(flash, "color", Color(cor.r, cor.g, cor.b, 0.0), 0.38).set_delay(0.07)

	await t.finished

	if is_instance_valid(flash):
		flash.queue_free()


func _explosao_gol(index: int) -> void:
	if index < 0 or index >= player_panels.size():
		return

	var panel: Panel = player_panels[index]

	if not is_instance_valid(panel):
		return

	var cor: Color = cores_players[index]

	var W: float = float(panel.size.x)
	var H: float = float(panel.size.y)
	var centro: Vector2 = Vector2(W, H) * 0.5
	var ref: float = minf(W, H)

	var burst := Panel.new()
	var burst_tam: float = ref * 0.18

	burst.size = Vector2(burst_tam, burst_tam)
	burst.position = centro - burst.size * 0.5
	burst.pivot_offset = burst.size * 0.5
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.z_index = 78

	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(1, 1, 1, 0.85)
	bs.set_corner_radius_all(int(burst_tam * 0.5))
	bs.shadow_color = Color(cor.r, cor.g, cor.b, 0.9)
	bs.shadow_size = int(ref * 0.06)
	burst.add_theme_stylebox_override("panel", bs)
	panel.add_child(burst)

	var tb := create_tween()
	tb.set_parallel(true)
	tb.tween_property(burst, "scale", Vector2(2.2, 2.2), 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tb.tween_property(burst, "modulate", Color(1, 1, 1, 0), 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tb.chain().tween_callback(burst.queue_free)

	for k in range(3):
		var ring := Panel.new()
		var tam0: float = ref * 0.14

		ring.size = Vector2(tam0, tam0)
		ring.position = centro - ring.size * 0.5
		ring.pivot_offset = ring.size * 0.5
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.z_index = 80

		var rs := StyleBoxFlat.new()
		rs.bg_color = Color(0, 0, 0, 0)
		rs.border_color = Color(cor.r, cor.g, cor.b, 0.95)
		rs.set_border_width_all(maxi(int(ref * 0.012), 3))
		rs.set_corner_radius_all(int(tam0 * 0.5))
		ring.add_theme_stylebox_override("panel", rs)
		panel.add_child(ring)

		var diam_final: float = ref * (0.85 + float(k) * 0.18)
		var escala_final: float = diam_final / tam0
		var dur: float = 0.55 + float(k) * 0.12
		var delay_k: float = float(k) * 0.07

		var tr := create_tween()
		tr.set_parallel(true)
		tr.tween_property(ring, "scale", Vector2(escala_final, escala_final), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay_k)
		tr.tween_property(ring, "modulate", Color(1, 1, 1, 0), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay_k)
		tr.chain().tween_callback(ring.queue_free)

	var paleta: Array[Color] = [
		Color(1.0, 0.85, 0.08),
		Color(1.0, 0.35, 0.25),
		cor,
		Color.WHITE,
		Color(0.2, 0.9, 1.0)
	]

	for i in range(24):
		var faisca := ColorRect.new()

		var s: float = clampf(ref * 0.022, 6.0, 16.0)
		var altura: float = s * randf_range(0.45, 1.0)

		faisca.size = Vector2(s, altura)
		faisca.position = centro - faisca.size * 0.5
		faisca.color = paleta[int(randi() % paleta.size())]
		faisca.pivot_offset = faisca.size * 0.5
		faisca.rotation = randf_range(0.0, TAU)
		faisca.mouse_filter = Control.MOUSE_FILTER_IGNORE
		faisca.z_index = 85
		panel.add_child(faisca)

		var ang: float = randf_range(0.0, TAU)
		var dist: float = randf_range(ref * 0.20, ref * 0.42)
		var base: Vector2 = centro - faisca.size * 0.5

		var direcao: Vector2 = Vector2(cos(ang), sin(ang) - 0.55)
		var destino: Vector2 = base + direcao * dist
		var queda: Vector2 = destino + Vector2(0, randf_range(ref * 0.12, ref * 0.26))
		var dur_faisca: float = randf_range(0.6, 0.95)

		var tmov := create_tween()
		tmov.tween_property(faisca, "position", destino, dur_faisca * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tmov.tween_property(faisca, "position", queda, dur_faisca * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tmov.tween_callback(faisca.queue_free)

		var tvis := create_tween()
		tvis.set_parallel(true)
		tvis.tween_property(faisca, "rotation", faisca.rotation + randf_range(-6.0, 6.0), dur_faisca)
		tvis.tween_property(faisca, "modulate", Color(1, 1, 1, 0), dur_faisca * 0.6).set_delay(dur_faisca * 0.4)


func _mostrar_popup_ponto(index: int, valor: int) -> void:
	if index < 0 or index >= player_panels.size():
		return

	var panel := player_panels[index]

	if not is_instance_valid(panel):
		return

	var cor := cores_players[index]
	var W := panel.size.x
	var H := panel.size.y

	var popup := Label.new()
	popup.text = "GOOOL!"
	popup.size = Vector2(W, 90)
	popup.position = Vector2(0, H * 0.40)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.z_index = 95
	popup.pivot_offset = popup.size * 0.5
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if fonte_orbitron:
		popup.add_theme_font_override("font", fonte_orbitron)

	popup.add_theme_font_size_override("font_size", int(clampf(H * 0.16, 34.0, 76.0)))
	popup.add_theme_color_override("font_color", Color.WHITE)
	popup.add_theme_color_override("font_shadow_color", cor)
	popup.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.96))
	popup.add_theme_constant_override("outline_size", 6)
	popup.add_theme_constant_override("shadow_offset_x", 0)
	popup.add_theme_constant_override("shadow_offset_y", 0)
	panel.add_child(popup)

	popup.scale = Vector2(0.5, 0.5)

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(popup, "scale", Vector2(1.25, 1.25), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(popup, "position:y", popup.position.y - H * 0.22, 0.72).set_delay(0.12)
	t.tween_property(popup, "modulate", Color(1, 1, 1, 0), 0.42).set_delay(0.42)

	await t.finished

	if is_instance_valid(popup):
		popup.queue_free()



func _intervalo_ciclo_leds() -> float:
	match fase_torneio:
		"QUARTAS", "SEMIFINAL":
			return 2000.0
		"FINAL":
			return 1500.0
	return CICLO_LEDS_MS



func _etapa_atual_txt() -> String:
	return str(partida_torneio.get("etapa", "ida")).to_upper()


func _nome_fase_bonito(fase: String) -> String:
	match fase:
		"FASE_1":
			return "PRIMEIRA FASE"
		"SEGUNDA_FASE", "PLAYIN_24_PARA_16":
			return "SEGUNDA FASE • 16 AVOS"
		"OITAVAS":
			return "OITAVAS DE FINAL"
		"QUARTAS":
			return "QUARTAS DE FINAL"
		"SEMIFINAL":
			return "SEMIFINAL"
		"FINAL":
			return "GRANDE FINAL"
	return "TORNEIO"


func _titulo_fase_cabecalho() -> String:
	var etapa := _etapa_atual_txt()
	if fase_torneio == "FASE_1":
		# chave_nome é a letra do grupo (A..L).
		return "PRIMEIRA FASE  •  GRUPO %s  •  %s" % [chave_nome, etapa]
	return "TORNEIO  •  %s  •  %s" % [_nome_fase_bonito(fase_torneio), etapa]



func _resolver_empates_chave_fase1() -> void:
	# Só desempata grupos de reais que estão brigando pela classificação
	# (>= ao corte do 2º lugar). Empates lá embaixo não vão a pênaltis.
	var corte: int = _score_corte_classificacao()
	var grupos: Array = _grupos_empatados_reais_por_valores(scores)

	for grupo in grupos:
		if grupo.is_empty():
			continue

		var score_grupo: int = int(scores[int(grupo[0])])
		if score_grupo < corte:
			continue

		await _mostrar_aviso_turno(
			"EMPATE NA CHAVE",
			"%s EMPATARAM COM %d GOLS  •  PÊNALTIS PARA DESEMPATAR" % [
				_nomes_do_grupo(grupo),
				score_grupo
			],
			COR_ALERTA
		)

		await _rodar_penaltis(grupo)

		# Desempate "volátil": os pênaltis somam nos gols da etapa,
		# então quem converteu mais fica na frente.
		for pp in grupo:
			var idx: int = int(pp)
			scores[idx] += int(penaltis_marcados[idx])


func _score_corte_classificacao() -> int:
	if scores.is_empty():
		return 0

	var lista: Array = scores.duplicate()
	lista.sort()
	lista.reverse()

	var vagas: int = 2 if fase_torneio == "FASE_1" else 1
	var idx: int = mini(vagas, lista.size()) - 1
	idx = maxi(idx, 0)

	return int(lista[idx])


func _nomes_do_grupo(grupo: Array) -> String:
	var nomes: Array[String] = []
	for pp in grupo:
		nomes.append(_nome_player(int(pp)))
	return " E ".join(nomes)


func _tocar_good_player() -> void:
	if sfx_good_player.is_empty():
		return

	# Não toca por cima de nenhum som de torcida (música de fundo não conta).
	if _algum_sfx_torcida_tocando():
		return

	var idx := randi() % sfx_good_player.size()

	if sfx_good_player.size() > 1:
		var trava := 0
		while idx == _ultimo_sfx_good and trava < 8:
			idx = randi() % sfx_good_player.size()
			trava += 1

	_ultimo_sfx_good = idx
	_tocar_audio(sfx_good_player[idx])


func _checar_superacao_e_tocar(index: int) -> void:
	if index < 0 or index >= total_players:
		return

	var v := int(scores[index])

	for i in range(total_players):
		if i == index:
			continue
		if i < 0 or i >= terminou_player.size():
			continue
		if not terminou_player[i]:
			continue

		# Acabou de ultrapassar este jogador (estava igual, agora ficou maior).
		if int(scores[i]) == v - 1:
			_tocar_good_player()
			return



func _neon_linha_modal(parent: Control, pos: Vector2, tam: Vector2, cor: Color) -> void:
	# Linha com brilho (várias camadas de alpha) para efeito neon.
	var glow := ColorRect.new()
	glow.position = pos - Vector2(0, 6)
	glow.size = Vector2(tam.x, tam.y + 12.0)
	glow.color = Color(cor.r, cor.g, cor.b, 0.18)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(glow)

	var core := ColorRect.new()
	core.position = pos
	core.size = tam
	core.color = Color(cor.r, cor.g, cor.b, 0.95)
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(core)


func _chip_info_modal(parent: Control, x: float, y: float, h: float, txt: String, cor: Color) -> float:
	var w := clampf(float(txt.length()) * 11.0 + 28.0, 90.0, 320.0)

	var chip := Panel.new()
	chip.position = Vector2(x, y)
	chip.size = Vector2(w, h)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(chip)

	var st := StyleBoxFlat.new()
	st.bg_color = Color(cor.r * 0.14, cor.g * 0.14, cor.b * 0.14, 0.96)
	st.border_color = cor
	st.set_border_width_all(1)
	st.set_corner_radius_all(8)
	st.shadow_color = Color(cor.r, cor.g, cor.b, 0.35)
	st.shadow_size = 10
	chip.add_theme_stylebox_override("panel", st)

	var lbl := _novo_label(txt, 14, Color.WHITE, cor)
	lbl.position = Vector2.ZERO
	lbl.size = chip.size
	chip.add_child(lbl)

	return x + w



func _leds_loading_roxo_on() -> void:
	# Mesma vibe do loading de volta do lobby: LEDs em tons de roxo/neon
	# enquanto a partida termina de carregar.
	var paleta: Array = [
		[180, 0, 255],   # roxo forte
		[255, 0, 220],   # magenta neon
		[110, 0, 255],   # violeta
		[0, 160, 255]    # ciano/azul neon
	]

	var partes: Array[String] = []

	for i in range(LEDS_TOTAL):
		if i < 0 or i >= LEDS_LETRAS.size():
			continue

		var rgb: Array = paleta[i % paleta.size()]
		partes.append("%s=%d,%d,%d" % [
			LEDS_LETRAS[i],
			int(rgb[0]),
			int(rgb[1]),
			int(rgb[2])
		])

	_serial_write("SET:" + ";".join(partes))


func _leds_loading_roxo_off() -> void:
	_serial_write("OFF")
