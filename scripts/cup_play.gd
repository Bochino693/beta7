extends Node2D


# ============================================================
# CUP PLAY — MODO COPA COM 4 JOGADORES
#
# NOVO NESTA VERSÃO:
# - PRORROGAÇÃO em caso de empate entre jogadores REAIS (50% do tempo).
# - PÊNALTIS quando a prorrogação não desempata:
#     * 2 "bocas" acendem por cobrança
#     * 3s para acertar (acertar qualquer uma das duas = GOL)
#     * 2 cobranças iniciais por jogador, alternando
#     * quem fizer mais, vence
#     * empatou -> MORTE SÚBITA alternada até desempatar
# - Música de boas jogadas NUNCA repete seguidamente (histórico global).
# - Ranking enviado ao lobby com placar agregado:
#     gols_normais, gols_prorrogacao, jogou_prorrogacao,
#     penaltis, jogou_penaltis  (além de gols/score como antes).
#
# Bots NÃO disputam prorrogação/pênaltis: empate bot-vs-real fica
# com o real; bot-vs-bot pelo índice.
# ============================================================

# Ajuste fino do enquadramento da imagem do modal de preparação.
# Aumente o X um pouco mais que o Y até "encaixar" certinho.
const FUNDO_PREP_ESCALA_X: float = 1.30
const FUNDO_PREP_ESCALA_Y: float = 1.03

const FUNDO_RESULT: String = "res://fundos/fundo_result.png"


# Fundo dos modais de preparação, por cor do jogador.
const FUNDO_PREP_VERMELHO: String = "res://fundos/red.png"
const FUNDO_PREP_AMARELO: String  = "res://fundos/yellow.png"
const FUNDO_PREP_AZUL: String     = "res://fundos/blue.png"
const FUNDO_PREP_VERDE: String    = "res://fundos/green.png"

const IMAGEM_FUNDO_STADIO: String = "res://images/back_stadio.png"

const IMAGEM_FUNDO_FOOTER_PATRO: String = "res://fundos/fundo_logos.png"

const CENA_CUP_LOBBY: String = "res://scenes/cup_lobby.tscn"

const FONTE_ORBITRON: String = "res://fonts/orbitron-bold.ttf"

const MUSICA_PLAY: String = "res://songs/song_fut_play.mp3"
const SFX_PONTO: String = "res://songs/goal.wav"
const SFX_FIM_TURNO: String = "res://songs/turn_end.mp3"
const SFX_APITO_INIT: String = "res://songs/apito_init.wav"
const SFX_APITO_TROCA: String = "res://songs/apito_troca.wav"
const SFX_APITO_FIM: String = "res://songs/apito_fim.wav"
const SFX_FINAL: String = "res://songs/game_start.wav"

const IMAGEM_LOADING_COPA: String = "res://images/loading.png"
# Imagem pequena/retangular para ficar atrás dos patrocinadores.
# Crie/salve uma imagem 1920x180 ou 1920x220 neste caminho.
const IMAGEM_RODAPE_LOADING: String = "res://fundos/fundo_logos.png"

const FATOR_PRORROGACAO: float = 0.5
const PASTA_PATROCINADORES: String = "res://patro"
const EXT_PATROCINADORES: Array = ["png", "jpg", "jpeg", "webp"]
const PATRO_MAX_POR_LINHA: int = 8


const PATROCINADORES_FIXOS: Array = [
	"res://patro/logoofi.png",
	"res://patro/bar.png",
	"res://patro/bud.png",
	"res://patro/corona_logo.png",
	"res://patro/GA_Logo.png",	
	"res://patro/Michelob-Ultra_stacked-color-Logo.png",
	"res://patro/stella.png",
]

const SFX_CAMPEAO: String = "res://songs/campeao.ogg"

const TEMPO_PLAYER_REAL: float = 60.0
const TEMPO_PLAYER_BOT: float = 6.0

# PRORROGAÇÃO: 50% do tempo normal.
const TEMPO_PRORROGACAO_REAL: float = 30.0
const TEMPO_PRORROGACAO_BOT: float = 3.0

# PÊNALTIS
const PENALTI_QTD_BOCAS: int = 1
const PENALTI_TEMPO_ACERTO: float = 3.0
const PENALTI_RODADAS_INICIAIS: int = 2
const PENALTI_PROB_BOT: float = 0.6

# AUTO START: vale APENAS para bots. Jogadores reais sempre apertam START.
const AUTO_START_BOT: bool = true
const AUTO_START_DELAY_BOT: float = 0.55

const BOT_JOGA_SOZINHO: bool = true
const BOT_INTERVALO_GOL_MIN: float = 0.45
const BOT_INTERVALO_GOL_MAX: float = 0.95
const BOT_PRIORIDADE_REAL: bool = true

const MUSICAS_PLAYERS: Array = [
	"res://songs/player_song1.ogg",
	"res://songs/player_song2.ogg",
	"res://songs/player_song3.ogg",
	"res://songs/player_song4.ogg",
	"res://songs/player_song5.ogg",
]

const SONS_TURNO_BOM: Array = [
	"res://songs/good_player.ogg",
	"res://songs/leleo.ogg",
	"res://songs/torcida_1.ogg"
]

const SONS_SUPEROU_TURNO: Array = [
	"res://songs/supress_you.ogg",
	"res://songs/good_player.ogg",	
	"res://songs/torcida_1.ogg",	
	"res://songs/torcida_2.ogg",
	"res://songs/torcida_3.ogg"
]

const SONS_NAO_SUPEROU: Array = [
	"res://songs/not_supress.wav",
	"res://songs/erro_1.mp3",
	"res://songs/erro_2.mp3"
]

const SOM_NOT_SUPRESS_DIRETO: String = "res://songs/not_supress.wav"

# Torcida pressiona durante o turno se o jogador estiver abaixo de alguém que já jogou.
const REACAO_PRESSAO_ATRAS_APOS_SEGUNDOS: float = 10.0
const REACAO_PRESSAO_ATRAS_INTERVALO_MS: float = 8500.0

const SONS_SUPEROU_LIVE: Array = [
	"res://songs/live_superou_1.mp3",
	"res://songs/live_superou_2.mp3"
]

const SONS_VAIA: Array = [
	"res://songs/vaia_1.mp3",
	"res://songs/vaia_2.mp3"
]

const FUNDO_CARD_AZUL: String = "res://fundos/azul.png"
const FUNDO_CARD_VERDE: String = "res://fundos/verde.png"
const FUNDO_CARD_VERMELHO: String = "res://fundos/vermelho.png"
const FUNDO_CARD_AMARELO: String = "res://fundos/amarelo.png"

const PONTOS_MINIMOS_SEM_VAIA: int = 15
const PONTOS_PARA_TORCIDA: int = 10
const COMBO_GOLS_PARA_SOM: int = 4
const COMBO_JANELA_MS: float = 2300.0
const COMBO_COOLDOWN_MS: float = 3200.0
const MOTIVACIONAL_INTERVALO_MS: float = 7000.0
const MOTIVACIONAL_RITMO_BOM: float = 0.5

# Histórico global de sons reativos (evita repetir a mesma música seguida).
const HISTORICO_SONS_MAX: int = 3

const TEMPO_POR_PLAYER: float = 60.0
const TEMPO_CONTAGEM_INICIAL: int = 3

const LEDS_TOTAL: int = 7
const LEDS_ATIVOS_MIN: int = 2
const LEDS_ATIVOS_MAX: int = 2
const LEDS_LETRAS: Array = ["A", "B", "C", "D", "E", "F", "G"]

const CICLO_LEDS_MS: float = 3000.0
const START_DEBOUNCE_MS: float = 500.0

const USAR_ARDUINO: bool = true
const USAR_PONTE_POWERSHELL: bool = true
const SERIAL_PORTA: String = "COM5"
const SERIAL_BAUD: int = 9600

const MOSTRAR_TECLAS_LED_HUD: bool = false

const COR_OK: Color = Color(0.22, 0.95, 0.58)
const COR_ALERTA: Color = Color(1.00, 0.78, 0.18)
const COR_ERRO: Color = Color(1.00, 0.22, 0.22)
const COR_NEON: Color = Color(0.25, 0.72, 1.00)
const COR_BOOT: Color = Color(0.48, 0.54, 0.64)

const CORES_ALVOS_RGB: Array = [
	[255, 255, 0],
	[255, 0, 0],
	[0, 255, 0],
	[0, 0, 255]
]

# Fases internas do jogo.
enum Fase { NORMAL, PRORROGACAO, PENALTIS }

var fonte_orbitron: Font

var _dupla_anterior: Array = []

var overlay_fundo_img: TextureRect = null
var overlay_fundo_escuro: ColorRect = null

var partida_copa: Dictionary = {}
var jogadores_copa: Array = []
var nomes_players_copa: Array = []

var grupo_copa_nome: String = "A"
var rodada_copa: int = 1
var partida_copa_index: int = 0

var total_players: int = 4
var player_atual: int = 0

var scores: Array = []
var tempos: Array = []
var terminou_player: Array = []

# Instante em que a onda atual nasceu (controle do ciclo de 5s).
var _ciclo_inicio_ms: float = 0.0

# Placar agregado (preenchido na resolução de empates).
var gols_normais: Array = []
var gols_prorrogacao: Array = []
var jogou_prorrogacao: Array = []
var penaltis_marcados: Array = []
var jogou_penaltis: Array = []

var fase_jogo: int = Fase.NORMAL
var _ot_turno_acabou: bool = false

# Runtime dos pênaltis.
var _pen_aguardando: bool = false
var _pen_alvos: Array = []
var _pen_resultado: int = 0

var pen_panel_root: Panel = null
var pen_cards_box: HBoxContainer = null
var pen_card_panels: Dictionary = {}
var pen_card_score_labels: Dictionary = {}
var pen_card_status_labels: Dictionary = {}
var pen_card_nome_labels: Dictionary = {}
var pen_estado_cards: Dictionary = {}
var pen_participantes: Array = []

var partida_ativa: bool = false
var aguardando_start_turno: bool = false
var em_contagem_inicio: bool = false
var partida_finalizada: bool = false
var fechando_jogo: bool = false

var _ultimo_start_ms: float = -99999.0
var _ultimo_acerto_ms: float = 0.0

var leds_ativos: Array = []
var cores_leds_ativos: Dictionary = {}
var qtd_leds_alvo_atual: int = 3

var cores_players: Array = [
	Color(1.00, 0.20, 0.20),
	Color(0.20, 0.92, 0.32),
	Color(0.12, 0.58, 1.00),
	Color(1.00, 0.84, 0.10)
]

# ─── NOVA variável de estado (adicionar junto das outras vars) ───────────────
var _prep_timer_token: int = 0
var _prep_piscar_timer: SceneTreeTimer = null
var _prep_piscar_ligado: bool = false

var overlay_fundo_moldura: Panel = null

var canvas: CanvasLayer
var root: Control

var player_panels: Array = []
var score_labels: Array = []
var tempo_labels: Array = []
var status_labels: Array = []

var overlay_layer: CanvasLayer
var overlay_fundo: ColorRect
var overlay_panel: Panel
var overlay_titulo: Label
var overlay_numero: Label
var overlay_subtitulo: Label

var final_layer: CanvasLayer

# Overlay dos pênaltis.
var pen_layer: CanvasLayer = null
var pen_titulo: Label = null
var pen_rodada: Label = null
var pen_chutador: Label = null
var pen_placar: Label = null
var pen_contagem: Label = null
var pen_feedback: Label = null


# ====== TELA DE CARREGAMENTO (barra de progresso real) ======
var loading_layer: CanvasLayer = null
var loading_root: Control = null
var loading_label: Label = null
var loading_sub: Label = null
var loading_pct: Label = null
var loading_barra: ColorRect = null
var loading_barra_w_max: float = 0.0
var loading_frac_atual: float = 0.0
var tween_loading_barra: SceneTreeTween = null

var volume_musica_normal: float = -7.0
var volume_musica_duck: float = -16.0
var tween_volume_musica: SceneTreeTween = null

var leds_hud_layer: CanvasLayer
var leds_hud_root: Control
var leds_botoes: Array = []
var leds_labels: Array = []

var audio_fundo: AudioStreamPlayer
var sfx_ponto: AudioStreamPlayer
var sfx_fim_turno: AudioStreamPlayer
var sfx_apito_init: AudioStreamPlayer
var sfx_apito_troca: AudioStreamPlayer
var sfx_apito_fim: AudioStreamPlayer
var sfx_final: AudioStreamPlayer

var caminho_fila_arduino: String = ""
var caminho_log_arduino: String = ""
var caminho_script_arduino: String = ""
var ponte_ps_pid: int = -1

var fase_copa: String = "GRUPOS"
var nome_partida_copa: String = ""

var sfx_reativo: AudioStreamPlayer
var sfx_campeao: AudioStreamPlayer

var musicas_por_player: Array = []
var _ultimo_som_por_lista: Dictionary = {}
var _historico_sons_global: Array = []

var _acertos_torcida: int = 0
var _superou_adversario: Array = []
var _ultimo_motivacional_ms: float = 0.0
var _ultimo_ponto_ms: float = 0.0
var _ultima_pressao_ms: float = 0.0

var _combo_gols_seguidos: int = 0
var _ultimo_combo_gol_ms: float = 0.0
var _ultimo_combo_som_ms: float = 0.0

var _reativo_bloqueado_por_campeao: bool = false
var _campeao_pendente: bool = false
var _vitoria_antecipada_tocada: bool = false

var medalhas_players: Array = []


var bot_timer_gol: float = 0.0
var bot_proximo_gol_em: float = 0.0
var auto_start_token: int = 0

var disputa_terceiro_copa: bool = false
var permite_prorrogacao_penaltis: bool = false


# ============================================================
# READY / PROCESS
# ============================================================
func _ready() -> void:
	var _g3_estado = null
	get_tree().auto_accept_quit = false
	_travar_modo_arcade()
	randomize()

	_criar_tela_carregamento("CARREGANDO PARTIDA", "INICIANDO COPA...")
	_set_progresso_carregamento(0.06, "INICIANDO COPA...", 0.2)

	yield(get_tree(), "idle_frame")

	_carregar_fontes()
	_set_progresso_carregamento(0.20, "CARREGANDO ÁUDIOS...")
	_criar_audios()
	yield(get_tree().create_timer(0.18), "timeout")

	_set_progresso_carregamento(0.36, "LENDO DADOS DA PARTIDA...")
	_carregar_config_copa()
	_inicializar_dados()
	_sortear_musicas_players()
	yield(get_tree().create_timer(0.18), "timeout")

	_set_progresso_carregamento(0.54, "MONTANDO ARENA...")
	_criar_tela()

	yield(get_tree(), "idle_frame")
	yield(get_tree().create_timer(0.15), "timeout")

	# Creep lento da barra enquanto conecta os LEDs (passo mais demorado).
	_set_progresso_carregamento(0.92, "CONECTANDO LEDS...", 3.4)
	_g3_estado = _abrir_serial_arduino()
	if _g3_estado is GDScriptFunctionState:
		_g3_estado = yield(_g3_estado, "completed")

	_set_progresso_carregamento(1.0, "TUDO PRONTO!", 0.3)
	yield(get_tree().create_timer(0.5), "timeout")

	# Só remove o loading quando TUDO já está realmente pronto.
	_g3_estado = _remover_tela_carregamento()
	if _g3_estado is GDScriptFunctionState:
		_g3_estado = yield(_g3_estado, "completed")

	# Modal do primeiro jogador (real aguarda START; bot inicia sozinho).
	_mostrar_preparacao_player()



func _process(delta: float) -> void:
	if partida_finalizada:
		return

	# Durante os pênaltis só lemos os sensores; o fluxo é controlado
	# pela corrotina dos pênaltis.
	if fase_jogo == Fase.PENALTIS:
		_ler_inputs_leds()
		return

	if aguardando_start_turno:
		if _start_foi_pressionado():
			_iniciar_contagem_turno()
			return

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

		if fase_jogo == Fase.NORMAL:
			_finalizar_turno_player()
		else:
			# Fim do turno de prorrogação: sinaliza para a corrotina.
			partida_ativa = false
			_serial_write("OFF")
			_ot_turno_acabou = true

		return

	if fase_jogo == Fase.NORMAL or fase_jogo == Fase.PRORROGACAO:
		_avaliar_motivacao()

	_atualizar_hud()


func _tocar_vaia_fim(chave: String = "fim_vaia") -> void:
	if sfx_reativo == null:
		return

	if _reativo_bloqueado_por_campeao:
		return

	if sfx_campeao != null and sfx_campeao.playing:
		return

	_tocar_som_da_lista(SONS_VAIA, chave, 1.0, true)

# ============================================================
# TELA DE CARREGAMENTO (PROFISSIONAL / BARRA REAL)
# ============================================================
func _criar_tela_carregamento(titulo_txt: String, sub_txt: String) -> void:
	if loading_layer != null and is_instance_valid(loading_layer):
		return

	loading_layer = CanvasLayer.new()
	loading_layer.layer = 500
	add_child(loading_layer)

	loading_root = Control.new()
	loading_root.set_anchors_preset(Control.PRESET_WIDE)
	loading_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_layer.add_child(loading_root)

	var tela = get_viewport().get_visible_rect().size

	# Fundo com imagem completa, sem zoom.
	_criar_fundo_imagem_loading(loading_root)

	# Rodapé automático com todos patrocinadores da pasta res://patro/

	var painel := Panel.new()
	painel.rect_size = Vector2(min(tela.x * 0.62, 860.0), 300)

	# Sobe um pouco para não bater no rodapé dos patrocinadores.
	painel.rect_position = Vector2(
		(tela.x - painel.rect_size.x) * 0.5,
		max(60.0, (tela.y - painel.rect_size.y) * 0.5 - 44.0)
	)

	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_root.add_child(painel)

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.012, 0.018, 0.030, 0.965)
	st.border_color = COR_NEON
	st.set_border_width_all(4)
	st.set_corner_radius_all(34)
	st.shadow_color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 0.78)
	st.shadow_size = 42
	st.shadow_offset = Vector2.ZERO
	painel.add_stylebox_override("panel", st)

	var W = painel.rect_size.x
	var H = painel.rect_size.y

	loading_label = _novo_label(titulo_txt, 36, Color.white, COR_NEON)
	loading_label.rect_position = Vector2(30, 44)
	loading_label.rect_size = Vector2(W - 60, 58)
	painel.add_child(loading_label)

	loading_sub = _novo_label(sub_txt, 19, Color(0.72, 0.84, 0.96))
	loading_sub.rect_position = Vector2(30, 118)
	loading_sub.rect_size = Vector2(W - 60, 36)
	painel.add_child(loading_sub)

	loading_pct = _novo_label("0%", 30, COR_ALERTA, COR_ALERTA)
	loading_pct.rect_position = Vector2(0, H - 118)
	loading_pct.rect_size = Vector2(W, 40)
	painel.add_child(loading_pct)

	var barra_bg := ColorRect.new()
	barra_bg.rect_position = Vector2(70, H - 70)
	barra_bg.rect_size = Vector2(W - 140, 10)
	barra_bg.color = Color(1, 1, 1, 0.12)
	barra_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(barra_bg)

	loading_barra_w_max = barra_bg.rect_size.x

	loading_barra = ColorRect.new()
	loading_barra.rect_position = barra_bg.rect_position
	loading_barra.rect_size = Vector2(6, 10)
	loading_barra.color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 1.0)
	loading_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(loading_barra)

	loading_frac_atual = 0.0



func _aplicar_frac_loading(v: float) -> void:
	if loading_barra and is_instance_valid(loading_barra):
		loading_barra.rect_size.x = max(loading_barra_w_max * v, 6.0)

	if loading_pct and is_instance_valid(loading_pct):
		loading_pct.text = "%d%%" % int(round(clamp(v, 0.0, 1.0) * 100.0))


func _set_progresso_carregamento(p: float, texto: String, dur: float = 0.3) -> void:
	if loading_layer == null or not is_instance_valid(loading_layer):
		return

	var alvo: float = clamp(p, 0.0, 1.0)

	if loading_sub != null and is_instance_valid(loading_sub):
		loading_sub.text = texto

	if tween_loading_barra != null and tween_loading_barra.is_running():
		tween_loading_barra.kill()

	var inicio: float = loading_frac_atual
	loading_frac_atual = alvo

	tween_loading_barra = create_tween()
	tween_loading_barra.tween_method(
		self, "_aplicar_frac_loading",
		inicio,
		alvo,
		dur
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _remover_tela_carregamento() -> void:
	if loading_layer == null or not is_instance_valid(loading_layer):
		return

	_aplicar_frac_loading(1.0)

	if loading_root != null and is_instance_valid(loading_root):
		var t = create_tween()
		t.tween_property(loading_root, "modulate", Color(1, 1, 1, 0), 0.30)
		yield(t, "finished")

	if is_instance_valid(loading_layer):
		loading_layer.queue_free()

	loading_layer = null
	loading_root = null
	loading_label = null
	loading_sub = null
	loading_pct = null
	loading_barra = null



# ============================================================
# CONFIG COPA
# ============================================================
func _carregar_config_copa() -> void:
	partida_copa.clear()
	jogadores_copa.clear()
	nomes_players_copa.clear()

	var cg = get_node_or_null("/root/CupGlobal")

	if cg != null:
		if cg.partida_copa_atual is Dictionary and not cg.partida_copa_atual.empty():
			partida_copa = cg.partida_copa_atual.duplicate(true)

	if partida_copa.empty() and get_tree().has_meta("partida_copa_atual"):
		var p_meta = get_tree().get_meta("partida_copa_atual")

		if p_meta is Dictionary:
			partida_copa = p_meta

	if partida_copa.empty():
		push_warning("CUP PLAY: nenhuma partida da Copa recebida.")
		_criar_fallback_copa()
		return

	partida_copa_index = int(partida_copa.get("partida_index", 0))
	grupo_copa_nome = str(partida_copa.get("grupo", "A"))
	rodada_copa = int(partida_copa.get("rodada", 1))
	fase_copa = str(partida_copa.get("fase", "GRUPOS"))
	nome_partida_copa = str(partida_copa.get("nome_partida", ""))
	disputa_terceiro_copa = bool(partida_copa.get("disputa_terceiro", false))
	permite_prorrogacao_penaltis = bool(
		partida_copa.get(
			"permite_prorrogacao_penaltis",
			_fase_permite_prorrogacao_penaltis()
		)
	)

	if nome_partida_copa.strip_edges() == "":
		if fase_copa == "GRUPOS":
			nome_partida_copa = "GRUPO %s • RODADA %d" % [grupo_copa_nome, rodada_copa]
		else:
			nome_partida_copa = fase_copa

	if partida_copa.has("jogadores") and partida_copa["jogadores"] is Array:
		jogadores_copa = partida_copa["jogadores"].duplicate(true)

	if jogadores_copa.empty():
		_criar_fallback_copa()
		return

	total_players = clamp(jogadores_copa.size(), 1, 4)

	for i in range(total_players):
		var j: Dictionary = jogadores_copa[i]

		nomes_players_copa.append(str(j.get("nome", "PLAYER %d" % (i + 1))))

		if j.has("cor") and j["cor"] is Color:
			cores_players[i] = j["cor"]

	print("================================")
	print("CUP PLAY CONFIGURADO")
	print("FASE: ", fase_copa)
	print("PARTIDA: ", nome_partida_copa)
	print("GRUPO: ", grupo_copa_nome)
	print("RODADA: ", rodada_copa)
	print("PARTIDA INDEX: ", partida_copa_index)
	print("TOTAL PLAYERS: ", total_players)
	print("NOMES: ", nomes_players_copa)
	print("================================")


func _criar_fallback_copa() -> void:
	total_players = 4
	grupo_copa_nome = "A"
	rodada_copa = 1
	partida_copa_index = 0

	jogadores_copa.clear()
	nomes_players_copa.clear()

	for i in range(4):
		jogadores_copa.append({
			"nome": "Boot %d" % (i + 1),
			"cor": cores_players[i],
			"cor_nome": "BOT",
			"boot": true
		})
		nomes_players_copa.append("Boot %d" % (i + 1))


func _nome_player(index: int) -> String:
	if index >= 0 and index < nomes_players_copa.size():
		return nomes_players_copa[index]

	return "PLAYER %d" % (index + 1)


func _inicializar_dados() -> void:
	scores.clear()
	tempos.clear()
	terminou_player.clear()

	gols_normais.clear()
	gols_prorrogacao.clear()
	jogou_prorrogacao.clear()
	penaltis_marcados.clear()
	jogou_penaltis.clear()

	for i in range(total_players):
		scores.append(0)
		tempos.append(_tempo_do_player(i))
		terminou_player.append(false)

		gols_normais.append(0)
		gols_prorrogacao.append(0)
		jogou_prorrogacao.append(false)
		penaltis_marcados.append(0)
		jogou_penaltis.append(false)

	player_atual = 0
	partida_ativa = false
	aguardando_start_turno = false
	em_contagem_inicio = false
	partida_finalizada = false

	fase_jogo = Fase.NORMAL
	_ot_turno_acabou = false
	_pen_aguardando = false
	_pen_alvos.clear()
	_pen_resultado = 0

	leds_ativos.clear()
	cores_leds_ativos.clear()
	_dupla_anterior.clear()
	_ciclo_inicio_ms = 0.0

	_ultimo_start_ms = -99999.0
	_ultimo_acerto_ms = 0.0
	_ultimo_ponto_ms = 0.0
	_ultima_pressao_ms = 0.0
	_ultimo_motivacional_ms = 0.0

	_acertos_torcida = 0
	_ultimo_som_por_lista.clear()
	_historico_sons_global.clear()
	_combo_gols_seguidos = 0
	_ultimo_combo_gol_ms = 0.0
	_ultimo_combo_som_ms = 0.0

	_superou_adversario.clear()

	for i in range(total_players):
		var linha: Array = []

		for j in range(total_players):
			linha.append(false)

		_superou_adversario.append(linha)

	_reativo_bloqueado_por_campeao = false
	_campeao_pendente = false
	_vitoria_antecipada_tocada = false

	bot_timer_gol = 0.0
	bot_proximo_gol_em = 0.0
	auto_start_token = 0



# ============================================================
# INPUT
# ============================================================
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var vp = get_viewport()

		if event.control and event.scancode == KEY_TAB:
			if vp:
				vp.set_input_as_handled()
			_fechar_jogo_arcade()
			return

		if event.scancode == KEY_ESCAPE:
			if vp:
				vp.set_input_as_handled()
			return

		if event.scancode == KEY_META:
			if vp:
				vp.set_input_as_handled()
			return

		if event.alt and event.scancode in [KEY_F4, KEY_TAB]:
			if vp:
				vp.set_input_as_handled()
			return

		if event.control and event.scancode == KEY_ESCAPE:
			if vp:
				vp.set_input_as_handled()
			return

		var mapa_teclas = {
				KEY_A: 0,
				KEY_S: 1,
				KEY_D: 2,
				KEY_F: 3,
				KEY_G: 4,
				KEY_H: 5,
				KEY_J: 6
			}

		if mapa_teclas.has(event.scancode):
			if vp:
				vp.set_input_as_handled()
			_processar_input_led(int(mapa_teclas[event.scancode]))
			return


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.scancode in [KEY_ESCAPE, KEY_META]:
			get_viewport().set_input_as_handled()
			return

		if event.alt and event.scancode in [KEY_F4, KEY_TAB]:
			get_viewport().set_input_as_handled()
			return


func _start_foi_pressionado() -> bool:
	if not Input.is_action_just_pressed("input_start"):
		return false

	var agora = float(Time.get_ticks_msec())

	if agora - _ultimo_start_ms < START_DEBOUNCE_MS:
		return false

	_ultimo_start_ms = agora
	return true


func _ler_inputs_leds() -> void:
	for i in range(LEDS_TOTAL):
		var acao = "input_led_" + LEDS_LETRAS[i].to_lower()

		if Input.is_action_just_pressed(acao):
			print("INPUT SENSOR PRESSIONADO: ", acao, " / LED INDEX: ", i)
			_processar_input_led(i)


# ============================================================
# TELA
# ============================================================
func _criar_tela() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)

	root = Control.new()
	root.set_anchors_preset(Control.PRESET_WIDE)
	canvas.add_child(root)

	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_WIDE)
	fundo.color = Color(0.006, 0.008, 0.012, 1.0)
	root.add_child(fundo)

	# Fundo do estádio (abaixo do cabeçalho, atrás dos cards).
	_adicionar_fundo_stadio()

	_criar_header_copa()
	_criar_overlay_turno()
	_reconstruir_paineis()
	_criar_hud_leds()


func _criar_header_copa() -> void:
	var tela = get_viewport().get_visible_rect().size

	var header := Panel.new()
	header.rect_position = Vector2.ZERO
	header.rect_size = Vector2(tela.x, 82)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(header)

	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.014, 0.018, 0.028, 0.96)
	s.border_color = Color(1, 1, 1, 0.12)
	s.set_border_width_all(0)
	s.set_border_width(MARGIN_BOTTOM, 2)
	s.shadow_color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 0.25)
	s.shadow_size = 14
	header.add_stylebox_override("panel", s)

	var titulo = _novo_label(
		"🏆 %s" % nome_partida_copa,
		30,
		Color.white,
		COR_NEON
	)
	titulo.rect_position = Vector2(44, 0)
	titulo.rect_size = Vector2(tela.x * 0.62, 82)
	titulo.align = Label.ALIGN_LEFT
	root.add_child(titulo)

	var regra_txt: String = _texto_regra_desempate_partida()

	var regra = _novo_label(regra_txt, 17, COR_ALERTA)
	regra.rect_position = Vector2(tela.x - 610, 0)
	regra.rect_size = Vector2(560, 82)
	regra.align = Label.ALIGN_RIGHT
	root.add_child(regra)



func _reconstruir_paineis() -> void:
	for p in player_panels:
		if is_instance_valid(p):
			p.queue_free()

	player_panels.clear()
	score_labels.clear()
	tempo_labels.clear()
	status_labels.clear()
	medalhas_players.clear()

	var tela = get_viewport().get_visible_rect().size
	var area_top: float = 92.0
	var tela_jogo = Vector2(tela.x, tela.y - area_top)

	for i in range(total_players):
		var rect = _get_rect_player_dinamico(i, total_players, tela_jogo, player_atual)
		rect.position.y += area_top
		_criar_painel_player(i, rect)

	_atualizar_hud()


func _criar_painel_player(index: int, rect: Rect2) -> void:
	if root == null:
		return

	if index < 0 or index >= total_players:
		return

	if index >= cores_players.size():
		return

	var cor: Color = cores_players[index]
	var margem: float = 10.0

	var panel := Panel.new()
	panel.rect_position = rect.position + Vector2(margem, margem)
	panel.rect_size = rect.size - Vector2(margem * 2.0, margem * 2.0)
	panel.rect_clip_content = true
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	var W: float = panel.rect_size.x
	var H: float = panel.rect_size.y

	var style := StyleBoxFlat.new()
	style.bg_color = Color(cor.r * 0.035, cor.g * 0.035, cor.b * 0.035, 0.96)
	style.border_color = Color(cor.r, cor.g, cor.b, 0.35)
	style.set_border_width_all(3)
	style.set_corner_radius_all(0)
	style.shadow_color = Color(cor.r, cor.g, cor.b, 0.20)
	style.shadow_size = 10
	style.shadow_offset = Vector2.ZERO
	panel.add_stylebox_override("panel", style)

	_adicionar_fundo_imagem_card_player(panel, index, cor)

	var faixa := ColorRect.new()
	faixa.rect_position = Vector2(22.0, max(H * 0.025, 12.0))
	faixa.rect_size = Vector2(max(W - 44.0, 20.0), 4.0)
	faixa.color = Color(cor.r, cor.g, cor.b, 0.38)
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(faixa)

	var colocacao = _novo_label(
		"",
		int(clamp(H * 0.040, 16.0, 28.0)),
		Color.white,
		cor
	)
	colocacao.rect_position = Vector2(W - 152.0, max(H * 0.035, 16.0))
	colocacao.rect_size = Vector2(128.0, 42.0)
	colocacao.align = Label.ALIGN_RIGHT
	colocacao.valign = Label.VALIGN_CENTER
	colocacao.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.95))
	Compat.contorno(colocacao, 4)
	panel.add_child(colocacao)

	medalhas_players.append(colocacao)

	var nome_player: String = _nome_player(index)

	if _player_eh_bot(index):
		nome_player += " BOT"

	var fs_titulo: int = int(clamp(H * 0.060, 20.0, 42.0))
	var fs_score_titulo: int = int(clamp(H * 0.048, 18.0, 34.0))
	var fs_score: int = int(clamp(min(H * 0.23, W * 0.40), 52.0, 132.0))
	var fs_tempo_titulo: int = int(clamp(H * 0.046, 16.0, 30.0))
	var fs_tempo: int = int(clamp(H * 0.100, 34.0, 64.0))
	var fs_status: int = int(clamp(H * 0.038, 15.0, 26.0))

	var titulo = _novo_label_card(nome_player, W, H * 0.090, fs_titulo, cor)
	titulo.add_color_override("font_color_shadow", cor)
	panel.add_child(titulo)

	var score_titulo = _novo_label_card("GOLS", W, H * 0.285, fs_score_titulo, Color(0.75, 0.84, 0.90))
	panel.add_child(score_titulo)

	var score = _novo_label_card("0", W, H * 0.455, fs_score, Color.white)
	score.add_color_override("font_color_shadow", cor)
	score.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.95))
	Compat.contorno(score, 5)
	panel.add_child(score)

	var tempo_titulo = _novo_label_card("TEMPO", W, H * 0.680, fs_tempo_titulo, Color(0.65, 0.72, 0.78))
	panel.add_child(tempo_titulo)

	var tempo_inicial: int = int(_tempo_do_player(index))
	var tempo = _novo_label_card(str(tempo_inicial), W, H * 0.790, fs_tempo, Color(1.0, 0.85, 0.08))
	tempo.add_color_override("font_color_shadow", Color(1.0, 0.4, 0.05))
	tempo.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.95))
	Compat.contorno(tempo, 4)
	panel.add_child(tempo)

	var status = _novo_label_card("AGUARDANDO", W, H * 0.918, fs_status, Color(0.65, 0.70, 0.75))
	status.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.95))
	Compat.contorno(status, 3)
	panel.add_child(status)

	player_panels.append(panel)
	score_labels.append(score)
	tempo_labels.append(tempo)
	status_labels.append(status)


func _get_rect_player_dinamico(index: int, qtd: int, tela: Vector2, ativo: int) -> Rect2:
	if qtd <= 1:
		return Rect2(Vector2.ZERO, tela)

	if qtd == 2:
		var w = tela.x / 2.0
		return Rect2(
			Vector2(float(index) * w, 0.0),
			Vector2(w, tela.y)
		)

	if qtd == 3:
		var big_w = tela.x * 0.58
		var small_w = tela.x - big_w

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

		var h = tela.y / 2.0

		return Rect2(
			Vector2(big_w, float(slot) * h),
			Vector2(small_w, h)
		)

	var w4 = tela.x / 2.0
	var h4 = tela.y / 2.0
	var col = index % 2
	var row = int(index / 2)

	return Rect2(
		Vector2(float(col) * w4, float(row) * h4),
		Vector2(w4, h4)
	)



func _atualizar_hud() -> void:
	if player_panels.size() < total_players:
		return

	if score_labels.size() < total_players:
		return

	if tempo_labels.size() < total_players:
		return

	if status_labels.size() < total_players:
		return

	for i in range(total_players):
		if i < medalhas_players.size():
			var lbl_colocacao = medalhas_players[i] as Label

			if lbl_colocacao != null and is_instance_valid(lbl_colocacao):
				var pos_live: int = _posicao_ao_vivo(i)
				var cor_pos: Color = _cor_colocacao_ao_vivo(pos_live, i)

				lbl_colocacao.text = "%dº LUGAR" % pos_live
				lbl_colocacao.add_color_override("font_color", cor_pos)

				if pos_live == 4:
					lbl_colocacao.add_color_override("font_outline_modulate", Color(1, 1, 1, 0.90))
					lbl_colocacao.add_color_override("font_color_shadow", Color(1, 1, 1, 0.75))
				else:
					lbl_colocacao.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.95))
					lbl_colocacao.add_color_override("font_color_shadow", cor_pos)

				Compat.contorno(lbl_colocacao, 4)

		if not is_instance_valid(player_panels[i]):
			continue

		if i < scores.size():
			score_labels[i].text = str(scores[i])

		if i < tempos.size():
			tempo_labels[i].text = str(int(ceil(tempos[i])))

		var style = player_panels[i].get_stylebox("panel") as StyleBoxFlat

		if style == null:
			continue

		var cor = cores_players[i]

		if i < terminou_player.size() and terminou_player[i]:
			status_labels[i].text = "FINALIZADO"
			status_labels[i].add_color_override("font_color", Color(0.55, 0.58, 0.62))

			style.bg_color = Color(0.018, 0.018, 0.020, 0.96)
			style.border_color = Color(0.25, 0.25, 0.25)
			style.shadow_color = Color(0, 0, 0, 0.4)
			style.shadow_size = 6

			player_panels[i].modulate = Color(0.72, 0.72, 0.72, 1.0)

		elif i == player_atual:
			if partida_ativa:
				if _player_eh_bot(i):
					status_labels[i].text = "BOT JOGANDO"
				elif fase_jogo == Fase.PRORROGACAO:
					status_labels[i].text = "PRORROGAÇÃO"
				else:
					status_labels[i].text = "JOGANDO AGORA"
			elif aguardando_start_turno:
				if _player_eh_bot(i):
					status_labels[i].text = "BOT AUTOMÁTICO"
				elif fase_jogo == Fase.PRORROGACAO:
					status_labels[i].text = "PRORROGAÇÃO • START"
				else:
					status_labels[i].text = "APERTE START"
			else:
				status_labels[i].text = "PREPARANDO"

			status_labels[i].add_color_override("font_color", cor)

			var pulso = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 340.0)

			style.bg_color = Color(cor.r * 0.065, cor.g * 0.065, cor.b * 0.065, 0.98)
			style.border_color = Color(cor.r, cor.g, cor.b, 0.65 + pulso * 0.35)
			style.shadow_color = Color(cor.r, cor.g, cor.b, 0.55 + pulso * 0.35)
			style.shadow_size = int(26.0 + pulso * 20.0)

			player_panels[i].modulate = Color.white

		else:
			status_labels[i].text = "AGUARDANDO"
			status_labels[i].add_color_override("font_color", Color(0.45, 0.48, 0.52))

			style.bg_color = Color(cor.r * 0.025, cor.g * 0.025, cor.b * 0.025, 0.94)
			style.border_color = Color(cor.r, cor.g, cor.b, 0.30)
			style.shadow_color = Color(cor.r, cor.g, cor.b, 0.18)
			style.shadow_size = 8

			player_panels[i].modulate = Color(0.58, 0.58, 0.58, 1.0)



func _posicao_ao_vivo(index: int) -> int:
	if index < 0 or index >= scores.size():
		return 99

	var meu_score: int = scores[index]
	var acima: int = 0

	for i in range(scores.size()):
		if i == index:
			continue

		# Agora empate fica na mesma colocação.
		# Exemplo:
		# 10 x 10 x 8 x 5 = 1º, 1º, 3º, 4º.
		if scores[i] > meu_score:
			acima += 1

	return acima + 1



func _cor_colocacao_ao_vivo(posicao: int, index: int) -> Color:
	match posicao:
		1:
			# Ouro
			return Color(1.00, 0.78, 0.12)
		2:
			# Prata
			return Color(0.82, 0.86, 0.92)
		3:
			# Bronze
			return Color(0.78, 0.43, 0.18)
		4:
			# Preto
			return Color(0.02, 0.02, 0.025)
		_:
			return Color(0.58, 0.62, 0.68)



# ============================================================
# OVERLAY / TURNO
# ============================================================
func _criar_overlay_turno() -> void:
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 120
	add_child(overlay_layer)

	overlay_fundo = ColorRect.new()
	overlay_fundo.set_anchors_preset(Control.PRESET_WIDE)
	overlay_fundo.color = Color(0, 0, 0, 0.0)
	overlay_layer.add_child(overlay_fundo)

	overlay_panel = Panel.new()
	overlay_panel.rect_size = Vector2(820, 330)
	overlay_panel.rect_position = (get_viewport().get_visible_rect().size - overlay_panel.rect_size) / 2.0
	overlay_panel.rect_scale = Vector2(0.94, 0.94)
	overlay_panel.modulate = Color(1, 1, 1, 0)
	overlay_panel.rect_clip_content = true
	overlay_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.add_child(overlay_panel)

	# Modal QUADRADO (sem cantos arredondados).
	var raio_modal: float = 0.0
	var borda_modal: float = 4.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.010, 0.014, 0.020, 0.97)
	style.border_color = COR_NEON
	style.set_border_width_all(int(borda_modal))
	style.set_corner_radius_all(int(raio_modal))
	style.shadow_color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 0.72)
	style.shadow_size = 38
	style.shadow_offset = Vector2.ZERO
	overlay_panel.add_stylebox_override("panel", style)

	# Moldura interna quadrada que segura a imagem dentro da borda neon.
	var inset: float = borda_modal
	var tam_fundo: Vector2 = overlay_panel.rect_size - Vector2(inset * 2.0, inset * 2.0)

	overlay_fundo_moldura = Panel.new()
	overlay_fundo_moldura.rect_position = Vector2(inset, inset)
	overlay_fundo_moldura.rect_size = tam_fundo
	overlay_fundo_moldura.rect_clip_content = true
	overlay_fundo_moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var moldura_st := StyleBoxFlat.new()
	moldura_st.bg_color = Color(0.006, 0.009, 0.014, 1.0)
	moldura_st.set_corner_radius_all(0)
	overlay_fundo_moldura.add_stylebox_override("panel", moldura_st)
	overlay_fundo_moldura.visible = false
	overlay_panel.add_child(overlay_fundo_moldura)

	# Imagem FULL: estica para preencher TODO o modal, sem zoom e sem cortar.
	# (STRETCH_SCALE ignora a proporção e ocupa o retângulo inteiro.)
	overlay_fundo_img = TextureRect.new()
	overlay_fundo_img.rect_position = Vector2.ZERO
	overlay_fundo_img.rect_size = tam_fundo
	overlay_fundo_img.rect_pivot_offset = tam_fundo * 0.5
	overlay_fundo_img.rect_scale = Vector2.ONE
	overlay_fundo_img.expand = true
	overlay_fundo_img.stretch_mode = TextureRect.STRETCH_SCALE
	overlay_fundo_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_fundo_img.modulate = Color(0.74, 0.74, 0.74, 1.0)  # escurece p/ texto legível
	overlay_fundo_moldura.add_child(overlay_fundo_img)

	overlay_titulo = _novo_label("", 42, Color.white, COR_NEON)
	overlay_titulo.rect_position = Vector2(0, 36)
	overlay_titulo.rect_size = Vector2(820, 66)
	overlay_panel.add_child(overlay_titulo)

	overlay_numero = _novo_label("", 72, Color(1.0, 0.85, 0.08), Color(1.0, 0.35, 0.05))
	overlay_numero.rect_position = Vector2(0, 112)
	overlay_numero.rect_size = Vector2(820, 92)
	overlay_panel.add_child(overlay_numero)

	overlay_subtitulo = _novo_label("", 22, COR_ALERTA, COR_ALERTA)
	overlay_subtitulo.rect_position = Vector2(40, 230)
	overlay_subtitulo.rect_size = Vector2(740, 54)
	overlay_subtitulo.autowrap = true
	overlay_subtitulo.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.95))
	Compat.contorno(overlay_subtitulo, 4)
	overlay_panel.add_child(overlay_subtitulo)

	overlay_layer.visible = false



# ─── Substitua _mostrar_preparacao_player() ──────────────────────────────────
func _mostrar_preparacao_player() -> void:
	partida_ativa = false
	aguardando_start_turno = true
	em_contagem_inicio = false

	_tocar_musica_do_player(player_atual)

	var cor = cores_players[player_atual]
	var nome = _nome_player(player_atual)
	var eh_bot = _player_eh_bot(player_atual)

	var ctx = nome_partida_copa
	if fase_jogo == Fase.PRORROGACAO:
		ctx = "PRORROGAÇÃO"

	overlay_titulo.text = nome

	if eh_bot:
		overlay_numero.text = "BOT"
		overlay_subtitulo.text = "%s  •  JOGADA AUTOMÁTICA" % ctx
	else:
		overlay_numero.text = "PRONTO?"
		overlay_subtitulo.text = "%s  •  APERTE START PARA COMEÇAR" % ctx

	overlay_titulo.add_color_override("font_color_shadow", cor)
	overlay_numero.add_color_override("font_color", Color.white)
	overlay_numero.add_color_override("font_color_shadow", cor)

	_aplicar_fundo_modal_prep(player_atual)
	_set_overlay_cor(cor)
	_mostrar_overlay()
	_atualizar_hud()
	_animar_painel_atual()

	# LEDs piscam somente para players reais durante o modal.
	if not eh_bot:
		_iniciar_piscar_leds_prep(player_atual)
		_agendar_timeout_prep()

	_agendar_start_automatico()



func _aplicar_fundo_modal_prep(index: int) -> void:
	if overlay_fundo_img == null or not is_instance_valid(overlay_fundo_img):
		return

	var caminho = _caminho_fundo_prep_player(index)
	var tem: bool = caminho != "" and ResourceLoader.exists(caminho)

	if overlay_fundo_moldura and is_instance_valid(overlay_fundo_moldura):
		overlay_fundo_moldura.visible = tem

	if not tem:
		overlay_fundo_img.visible = false
		return

	overlay_fundo_img.texture = load(caminho)
	overlay_fundo_img.visible = true



func _caminho_fundo_prep_player(index: int) -> String:
	# Primeiro tenta pela cor salva no jogador.
	if index >= 0 and index < jogadores_copa.size():
		var j: Dictionary = jogadores_copa[index]
		var nome_cor: String = str(j.get("cor_nome", "")).strip_edges().to_upper()

		if Compat.contem(nome_cor, "AZUL"):
			return FUNDO_PREP_AZUL
		if Compat.contem(nome_cor, "VERDE"):
			return FUNDO_PREP_VERDE
		if Compat.contem(nome_cor, "VERMELHO"):
			return FUNDO_PREP_VERMELHO
		if Compat.contem(nome_cor, "AMARELO"):
			return FUNDO_PREP_AMARELO

		var cor_index: int = int(j.get("cor_index", -1))
		match cor_index:
			0:
				return FUNDO_PREP_VERMELHO
			1:
				return FUNDO_PREP_VERDE
			2:
				return FUNDO_PREP_AZUL
			3:
				return FUNDO_PREP_AMARELO

	# Fallback: identifica pela cor visual.
	if index >= 0 and index < cores_players.size():
		var c: Color = cores_players[index]

		if c.r >= 0.70 and c.g >= 0.55 and c.b <= 0.35:
			return FUNDO_PREP_AMARELO
		if c.r >= c.g and c.r >= c.b:
			return FUNDO_PREP_VERMELHO
		if c.g >= c.r and c.g >= c.b:
			return FUNDO_PREP_VERDE
		if c.b >= c.r and c.b >= c.g:
			return FUNDO_PREP_AZUL

	return ""



func _agendar_start_automatico() -> void:
	if not AUTO_START_BOT:
		return

	if not _player_eh_bot(player_atual):
		return

	auto_start_token += 1
	var meu_token: int = auto_start_token

	yield(get_tree().create_timer(AUTO_START_DELAY_BOT), "timeout")

	if meu_token != auto_start_token:
		return

	if partida_finalizada:
		return

	if not aguardando_start_turno:
		return

	if not _player_eh_bot(player_atual):
		return

	_iniciar_contagem_turno()


# ─── Substitua _iniciar_contagem_turno() ─────────────────────────────────────
func _iniciar_contagem_turno() -> void:
	var _g3_estado = null
	if em_contagem_inicio:
		return

	em_contagem_inicio = true
	aguardando_start_turno = false

	# Cancela o timer de 30s e para o piscar dos LEDs.
	_prep_timer_token += 1
	_parar_piscar_leds_prep()

	_g3_estado = _rodar_contagem_inicio()
	if _g3_estado is GDScriptFunctionState:
		_g3_estado = yield(_g3_estado, "completed")
	_iniciar_turno_player()


func _agendar_timeout_prep() -> void:
	var _g3_estado = null
	# Timer de 30 segundos para passar a vez se o player não apertar START.
	_prep_timer_token += 1
	var meu_token = _prep_timer_token

	yield(get_tree().create_timer(30.0), "timeout")

	# Token mudou = player apertou START ou o jogo avançou.
	if meu_token != _prep_timer_token:
		return

	if partida_finalizada:
		return

	if not aguardando_start_turno:
		return

	if _player_eh_bot(player_atual):
		return

	# Para o piscar antes de qualquer coisa.
	_parar_piscar_leds_prep()

	# Toca o som de "não superou" (not_supress).
	_tocar_som_da_lista(SONS_NAO_SUPEROU, "prep_timeout", 1.0, true)

	# Marca o player como finalizado e avança.
	aguardando_start_turno = false
	partida_ativa = false
	terminou_player[player_atual] = true
	_atualizar_hud()

	# Verifica se há próximo player.
	var proximo := -1
	for i in range(total_players):
		if not terminou_player[i]:
			proximo = i
			break

	if proximo == -1:
		# Era o último: finaliza a partida.
		_g3_estado = _resolver_empates_e_finalizar()
		if _g3_estado is GDScriptFunctionState:
			_g3_estado = yield(_g3_estado, "completed")
	else:
		# Passa a vez.
		_tocar_audio(sfx_apito_troca)
		player_atual = proximo
		_reconstruir_paineis()
		yield(get_tree().create_timer(0.20), "timeout")
		_mostrar_preparacao_player()


func _iniciar_piscar_leds_prep(index: int) -> void:
	_prep_piscar_ligado = true
	_piscar_leds_prep_loop(index)


func _parar_piscar_leds_prep() -> void:
	_prep_piscar_ligado = false
	# Desliga todos os LEDs imediatamente.
	leds_ativos.clear()
	cores_leds_ativos.clear()
	_atualizar_leds_hud()
	_serial_write("OFF")


func _piscar_leds_prep_loop(index: int) -> void:
	if not _prep_piscar_ligado:
		return

	if index < 0 or index >= cores_players.size():
		return

	# Mapeia para RGB puro baseado na cor dominante do player,
	# igual às cores reais dos LEDs do jogo (sem mistura residual).
	var cor = cores_players[index]
	var r: int
	var g: int
	var b: int

	if cor.r >= 0.70 and cor.g >= 0.55 and cor.b <= 0.35:
		# Amarelo
		r = 255; g = 200; b = 0
	elif cor.r >= cor.g and cor.r >= cor.b:
		# Vermelho
		r = 255; g = 0; b = 0
	elif cor.g >= cor.r and cor.g >= cor.b:
		# Verde
		r = 0; g = 255; b = 0
	elif cor.b >= cor.r and cor.b >= cor.g:
		# Azul
		r = 0; g = 0; b = 255
	else:
		# Fallback: converte direto
		r = int(clamp(cor.r * 255.0, 0, 255))
		g = int(clamp(cor.g * 255.0, 0, 255))
		b = int(clamp(cor.b * 255.0, 0, 255))

	# Liga todos os LEDs na cor do player.
	leds_ativos.clear()
	cores_leds_ativos.clear()

	for i in range(LEDS_TOTAL):
		leds_ativos.append(i)
		cores_leds_ativos[i] = [r, g, b]

	_atualizar_leds_hud()

	var partes: Array = []
	for i in range(LEDS_TOTAL):
		partes.append("%s=%d,%d,%d" % [LEDS_LETRAS[i], r, g, b])
	_serial_write("SET:" + PoolStringArray(partes).join(";"))

	# Aguarda 0.4s aceso.
	yield(get_tree().create_timer(0.40), "timeout")

	if not _prep_piscar_ligado:
		return

	# Apaga.
	leds_ativos.clear()
	cores_leds_ativos.clear()
	_atualizar_leds_hud()
	_serial_write("OFF")

	# Aguarda 0.35s apagado.
	yield(get_tree().create_timer(0.35), "timeout")

	if not _prep_piscar_ligado:
		return

	# Repete o loop.
	_piscar_leds_prep_loop(index)

func _rodar_contagem_inicio() -> void:
	var cor = cores_players[player_atual]
	var nome = _nome_player(player_atual)
	var eh_bot = _player_eh_bot(player_atual)

	overlay_titulo.text = "%s, PREPARE-SE" % nome

	if eh_bot:
		overlay_subtitulo.text = "BOT ENTRANDO EM CAMPO..."
		overlay_numero.text = "GO!"
		yield(get_tree().create_timer(0.45), "timeout")
		return

	if fase_jogo == Fase.PRORROGACAO:
		overlay_subtitulo.text = "PRORROGAÇÃO • VALENDO EM..."
	else:
		overlay_subtitulo.text = "VALENDO EM..."

	for n in range(TEMPO_CONTAGEM_INICIAL, 0, -1):
		overlay_numero.text = str(n)
		overlay_numero.rect_scale = Vector2(1.35, 1.35)
		overlay_numero.add_color_override("font_color", Color(1.0, 0.85, 0.08))
		overlay_numero.add_color_override("font_color_shadow", Color(1.0, 0.35, 0.05))

		var t = create_tween()
		t.tween_property(overlay_numero, "rect_scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		yield(get_tree().create_timer(0.85), "timeout")

	overlay_titulo.text = "VAI, %s!" % nome
	overlay_numero.text = ""
	overlay_subtitulo.text = "MARQUE O MÁXIMO DE GOLS"
	overlay_titulo.add_color_override("font_color_shadow", cor)

	yield(get_tree().create_timer(0.45), "timeout")



func _iniciar_turno_player() -> void:
	var _g3_estado = null
	partida_ativa = true
	em_contagem_inicio = false
	aguardando_start_turno = false

	_g3_estado = _esconder_overlay()
	if _g3_estado is GDScriptFunctionState:
		_g3_estado = yield(_g3_estado, "completed")

	leds_ativos.clear()
	cores_leds_ativos.clear()
	_acertos_torcida = 0
	_combo_gols_seguidos = 0
	_ultimo_combo_gol_ms = 0.0
	_ultimo_combo_som_ms = 0.0

	var agora = float(Time.get_ticks_msec())
	_ultimo_motivacional_ms = agora
	_ultimo_acerto_ms = agora
	_ultimo_ponto_ms = agora
	_ultima_pressao_ms = agora

	_atualizar_leds_hud()
	_serial_write("OFF")

	_tocar_audio(sfx_apito_init)

	yield(get_tree().create_timer(0.18), "timeout")

	_sortear_novo_grupo_de_fileiras()

	if _player_eh_bot(player_atual):
		_sortear_proximo_gol_bot()
	else:
		_tocar_som_da_lista(SONS_TURNO_BOM, "inicio_turno", 1.0, true)

	_atualizar_hud()



func _registrar_combo_gol_player() -> void:
	if player_atual < 0 or player_atual >= total_players:
		return

	if _player_eh_bot(player_atual):
		return

	var agora = float(Time.get_ticks_msec())

	if _ultimo_combo_gol_ms <= 0.0:
		_combo_gols_seguidos = 1
	else:
		var intervalo = agora - _ultimo_combo_gol_ms

		if intervalo <= COMBO_JANELA_MS:
			_combo_gols_seguidos += 1
		else:
			_combo_gols_seguidos = 1

	_ultimo_combo_gol_ms = agora

	if _combo_gols_seguidos < COMBO_GOLS_PARA_SOM:
		return

	if agora - _ultimo_combo_som_ms < COMBO_COOLDOWN_MS:
		return

	_ultimo_combo_som_ms = agora
	_combo_gols_seguidos = 0

	# Não sobrepõe em cima de campeão.
	if sfx_campeao != null and sfx_campeao.playing:
		return

	# Se já tem reativo tocando, não empilha vários sons.
	if sfx_reativo != null and sfx_reativo.playing:
		return

	_tocar_som_da_lista(
		SONS_TURNO_BOM,
		"combo_gols_%s_player_%d" % [fase_copa, player_atual],
		1.25,
		true
	)


func _mostrar_overlay() -> void:
	overlay_layer.visible = true

	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(overlay_fundo, "color", Color(0, 0, 0, 0.64), 0.22)
	t.tween_property(overlay_panel, "modulate", Color.white, 0.22)
	t.tween_property(overlay_panel, "rect_scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _esconder_overlay() -> void:
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(overlay_fundo, "color", Color(0, 0, 0, 0.0), 0.18)
	t.tween_property(overlay_panel, "modulate", Color(1, 1, 1, 0), 0.18)
	t.tween_property(overlay_panel, "rect_scale", Vector2(0.94, 0.94), 0.18)

	yield(t, "finished")
	overlay_layer.visible = false


func _set_overlay_cor(cor: Color) -> void:
	var style = overlay_panel.get_stylebox("panel") as StyleBoxFlat

	if style:
		style.border_color = cor
		style.shadow_color = Color(cor.r, cor.g, cor.b, 0.72)


func _animar_painel_atual() -> void:
	if player_atual < 0 or player_atual >= player_panels.size():
		return

	var panel = player_panels[player_atual]
	panel.rect_scale = Vector2(1.025, 1.025)

	var t = create_tween()
	t.tween_property(panel, Compat.prop(panel, "scale"), Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ============================================================
# LEDS / SENSORES
# ============================================================
func _checar_ciclo_leds() -> void:
	if not partida_ativa:
		return

	if leds_ativos.empty():
		_sortear_novo_grupo_de_fileiras()
		return

	var agora = float(Time.get_ticks_msec())
	var tempo_onda = agora - _ciclo_inicio_ms

	if tempo_onda >= CICLO_LEDS_MS:
		print("TEMPO DA ONDA ESGOTADO EM %.1fs -> TROCOU LEDS" % (CICLO_LEDS_MS / 1000.0))
		_sortear_novo_grupo_de_fileiras()



func _sortear_novo_grupo_de_fileiras() -> void:
	var tentativas: int = 0

	while true:
		leds_ativos.clear()
		cores_leds_ativos.clear()

		var qtd: int = int(clamp(Compat.randi_range(LEDS_ATIVOS_MIN, LEDS_ATIVOS_MAX), 1, LEDS_TOTAL))
		qtd_leds_alvo_atual = qtd

		while leds_ativos.size() < qtd:
			var novo = _sortear_led_disponivel()

			if novo < 0:
				break

			if not leds_ativos.has(novo):
				leds_ativos.append(novo)
				cores_leds_ativos[novo] = _rgb_aleatorio_alvo()

		tentativas += 1

		# Evita repetir EXATAMENTE a mesma dupla seguida.
		if tentativas >= 6 or not _mesma_combinacao(leds_ativos, _dupla_anterior):
			break

	_dupla_anterior = leds_ativos.duplicate()

	# Reinicia o relógio: esta dupla tem CICLO_LEDS_MS para ser limpa.
	_ciclo_inicio_ms = float(Time.get_ticks_msec())
	_ultimo_acerto_ms = _ciclo_inicio_ms

	print("NOVA DUPLA: ", _texto_fileiras_ativas(), " (", _nome_player(player_atual), ")")

	_atualizar_leds_hud()
	_enviar_leds_para_arduino()


func _mesma_combinacao(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false

	for v in a:
		if not b.has(v):
			return false

	return true


func _completar_leds_ativos() -> void:
	qtd_leds_alvo_atual = clamp(qtd_leds_alvo_atual, LEDS_ATIVOS_MIN, LEDS_ATIVOS_MAX)

	while leds_ativos.size() < qtd_leds_alvo_atual:
		var novo = _sortear_led_disponivel()

		if novo < 0:
			break

		if not leds_ativos.has(novo):
			leds_ativos.append(novo)
			cores_leds_ativos[novo] = _rgb_aleatorio_alvo()

	_atualizar_leds_hud()
	_enviar_leds_para_arduino()


func _processar_input_led(index_led: int) -> void:
	# Durante os pênaltis o sensor vira cobrança.
	if fase_jogo == Fase.PENALTIS:
		_registrar_chute_penalti(index_led)
		return

	if not partida_ativa:
		return

	if index_led < 0 or index_led >= LEDS_TOTAL:
		return

	if leds_ativos.has(index_led):
		print("ACERTOU: ", LEDS_LETRAS[index_led])

		_ultimo_acerto_ms = float(Time.get_ticks_msec())

		_flash_led(index_led, true)

		leds_ativos.erase(index_led)
		cores_leds_ativos.erase(index_led)

		registrar_ponto(1)

		# Limpou a dupla inteira -> nasce outra na hora (sem OFF, sem piscar).
		# Se ainda restar 1, ele FICA FIRME até ser acertado ou estourar 5s.
		if leds_ativos.empty():
			_sortear_novo_grupo_de_fileiras()
		else:
			_atualizar_leds_hud()
			_enviar_leds_para_arduino()
	else:
		print("ERROU: ", LEDS_LETRAS[index_led])

		_flash_led(index_led, false)
		registrar_erro(0)


func registrar_erro(penalidade: int = 0) -> void:
	if not partida_ativa:
		return

	if penalidade > 0:
		scores[player_atual] -= penalidade

		if scores[player_atual] < 0:
			scores[player_atual] = 0

	_atualizar_hud()


func _flash_led(index_led: int, sucesso: bool) -> void:
	if index_led < 0 or index_led >= leds_botoes.size():
		return

	var btn = leds_botoes[index_led]

	btn.rect_pivot_offset = btn.rect_size * 0.5
	btn.rect_scale = Vector2(1.30, 1.30)

	var t = create_tween()
	t.tween_property(btn, Compat.prop(btn, "scale"), Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if not sucesso:
		btn.modulate = Color(1.5, 0.45, 0.45, 1.0)

		var t2 = create_tween()
		t2.tween_property(btn, "modulate", Color.white, 0.35)

func _explosao_gol(index: int) -> void:
	if index < 0 or index >= player_panels.size():
		return

	var panel: Panel = player_panels[index]
	var cor: Color = cores_players[index]

	var W: float = float(panel.rect_size.x)
	var H: float = float(panel.rect_size.y)
	var centro: Vector2 = Vector2(W, H) * 0.5
	var ref: float = min(W, H)

	var burst := Panel.new()
	var burst_tam: float = ref * 0.18

	burst.rect_size = Vector2(burst_tam, burst_tam)
	burst.rect_position = centro - burst.rect_size * 0.5
	burst.rect_pivot_offset = burst.rect_size * 0.5
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Compat.z(burst, 78)

	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(1, 1, 1, 0.85)
	bs.set_corner_radius_all(int(burst_tam * 0.5))
	bs.shadow_color = Color(cor.r, cor.g, cor.b, 0.9)
	bs.shadow_size = int(ref * 0.06)
	burst.add_stylebox_override("panel", bs)
	panel.add_child(burst)

	var tb = create_tween()
	tb.set_parallel(true)
	tb.tween_property(burst, "rect_scale", Vector2(2.2, 2.2), 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tb.tween_property(burst, "modulate", Color(1, 1, 1, 0), 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tb.chain().tween_callback(burst, "queue_free")

	for k in range(3):
		var ring := Panel.new()
		var tam0: float = ref * 0.14

		ring.rect_size = Vector2(tam0, tam0)
		ring.rect_position = centro - ring.rect_size * 0.5
		ring.rect_pivot_offset = ring.rect_size * 0.5
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Compat.z(ring, 80)

		var rs := StyleBoxFlat.new()
		rs.bg_color = Color(0, 0, 0, 0)
		rs.border_color = Color(cor.r, cor.g, cor.b, 0.95)
		rs.set_border_width_all(int(max(int(ref * 0.012), 3)))
		rs.set_corner_radius_all(int(tam0 * 0.5))
		ring.add_stylebox_override("panel", rs)
		panel.add_child(ring)

		var diam_final: float = ref * (0.85 + float(k) * 0.18)
		var escala_final: float = diam_final / tam0
		var dur: float = 0.55 + float(k) * 0.12
		var delay_k: float = float(k) * 0.07

		var tr = create_tween()
		tr.set_parallel(true)
		tr.tween_property(ring, "rect_scale", Vector2(escala_final, escala_final), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay_k)
		tr.tween_property(ring, "modulate", Color(1, 1, 1, 0), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay_k)
		tr.chain().tween_callback(ring, "queue_free")

	var paleta: Array = [
		Color(1.0, 0.85, 0.08),
		Color(1.0, 0.35, 0.25),
		cor,
		Color.white,
		Color(0.2, 0.9, 1.0)
	]

	for i in range(24):
		var faisca := ColorRect.new()

		var s: float = clamp(ref * 0.022, 6.0, 16.0)
		var altura: float = s * rand_range(0.45, 1.0)

		faisca.rect_size = Vector2(s, altura)
		faisca.rect_position = centro - faisca.rect_size * 0.5
		faisca.color = paleta[int(randi() % paleta.size())]
		faisca.rect_pivot_offset = faisca.rect_size * 0.5
		faisca.rect_rotation = rand_range(0.0, 360.0)
		faisca.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Compat.z(faisca, 85)
		panel.add_child(faisca)

		var ang: float = rand_range(0.0, TAU)
		var dist: float = rand_range(ref * 0.20, ref * 0.42)
		var base: Vector2 = centro - faisca.rect_size * 0.5

		var direcao: Vector2 = Vector2(cos(ang), sin(ang) - 0.55)
		var destino: Vector2 = base + direcao * dist
		var queda: Vector2 = destino + Vector2(0, rand_range(ref * 0.12, ref * 0.26))
		var dur_faisca: float = rand_range(0.6, 0.95)

		var tmov = create_tween()
		tmov.tween_property(faisca, "rect_position", destino, dur_faisca * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tmov.tween_property(faisca, "rect_position", queda, dur_faisca * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tmov.tween_callback(faisca, "queue_free")

		var tvis = create_tween()
		tvis.set_parallel(true)
		tvis.tween_property(faisca, "rect_rotation", faisca.rect_rotation + rad2deg(rand_range(-6.0, 6.0)), dur_faisca)
		tvis.tween_property(faisca, "modulate", Color(1, 1, 1, 0), dur_faisca * 0.6).set_delay(dur_faisca * 0.4)
	


func registrar_ponto(valor: int = 1) -> void:
	if not partida_ativa:
		return

	if player_atual < 0 or player_atual >= total_players:
		return

	var score_antes: int = scores[player_atual]

	scores[player_atual] += valor
	_registrar_combo_gol_player()

	if sfx_ponto != null and sfx_ponto.stream != null:
		sfx_ponto.stop()
		sfx_ponto.play()

	# Torcida só reage para jogador real.
	if not _player_eh_bot(player_atual):
		var superou_agora: bool = false

		if fase_jogo == Fase.NORMAL or fase_jogo == Fase.PRORROGACAO:
			superou_agora = _checar_superacao_ao_vivo(score_antes, scores[player_atual])

			_acertos_torcida += valor

			# A cada sequência boa de gols, torcida reage positivamente.
			if _acertos_torcida >= PONTOS_PARA_TORCIDA:
				_acertos_torcida = 0

				if not superou_agora:
					# Só comemora sequência se ele não estiver claramente atrás.
					if not _esta_abaixo_de_alguem_ja_jogado(player_atual):
						_tocar_som_da_lista(SONS_TURNO_BOM, "torcida_sequencia_boa", 1.2)

		if fase_jogo == Fase.NORMAL:
			_verificar_vitoria_antecipada()

	_animar_score(player_atual)
	_efeito_gol_card(player_atual)
	_explosao_gol(player_atual)
	_mostrar_popup_ponto(player_atual, valor)

	_atualizar_hud()



func _jogadores_ja_jogaram(exceto: int = -1) -> Array:
	var lista: Array = []

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
			melhor = int(max(melhor, scores[i]))

	return melhor


func _esta_abaixo_de_alguem_ja_jogado(index: int) -> bool:
	if index < 0 or index >= scores.size():
		return false

	var melhor_anterior: int = _melhor_score_ja_jogado(index)

	if melhor_anterior < 0:
		return false

	return scores[index] < melhor_anterior


func _checar_superacao_ao_vivo(score_antes: int, score_agora: int) -> bool:
	if player_atual < 0 or player_atual >= total_players:
		return false

	if _player_eh_bot(player_atual):
		return false

	for j in range(total_players):
		if j == player_atual:
			continue

		if j < 0 or j >= terminou_player.size():
			continue

		# Só compara com quem já jogou.
		if not terminou_player[j]:
			continue

		if j < 0 or j >= scores.size():
			continue

		var score_alvo: int = scores[j]

		if score_alvo <= 0:
			continue

		if _superou_adversario[player_atual][j]:
			continue

		# Passou alguém que já tinha jogado.
		if score_antes <= score_alvo and score_agora > score_alvo:
			_superou_adversario[player_atual][j] = true

			# Som de torcida boa / superação.
			if not SONS_SUPEROU_LIVE.empty():
				_tocar_som_da_lista(SONS_SUPEROU_LIVE, "superou_ao_vivo", 1.5, true)
			else:
				_tocar_som_da_lista(SONS_SUPEROU_TURNO, "superou_ao_vivo", 1.5, true)

			return true

	return false


func _tocar_not_supress(chave: String = "not_supress") -> void:
	if ResourceLoader.exists(SOM_NOT_SUPRESS_DIRETO):
		_tocar_som_arquivo(SOM_NOT_SUPRESS_DIRETO, 1.2, true)
	else:
		_tocar_som_da_lista(SONS_NAO_SUPEROU, chave, 1.2, true)


func _tocar_som_arquivo(caminho: String, volume_db: float = 0.0, forcar: bool = true) -> void:
	if sfx_reativo == null:
		return

	if _reativo_bloqueado_por_campeao:
		return

	if sfx_campeao != null and sfx_campeao.playing:
		return

	if sfx_reativo.playing and not forcar:
		return

	if not ResourceLoader.exists(caminho):
		return

	var stream = load(caminho) as AudioStream

	if stream == null:
		return

	if stream is AudioStream:
		Compat.laco(stream, false)

	if forcar and sfx_reativo.playing:
		sfx_reativo.stop()

	_duck_musica(true, 0.16)

	sfx_reativo.stream = stream
	sfx_reativo.volume_db = volume_db
	sfx_reativo.play()


func _avaliar_pressao_torcida() -> void:
	if not partida_ativa:
		return

	if player_atual < 0 or player_atual >= total_players:
		return

	if _player_eh_bot(player_atual):
		return

	if sfx_reativo != null and sfx_reativo.playing:
		return

	if not _esta_abaixo_de_alguem_ja_jogado(player_atual):
		return

	var agora = float(Time.get_ticks_msec())

	if agora - _ultima_pressao_ms < REACAO_PRESSAO_ATRAS_INTERVALO_MS:
		return

	var tempo_base: float = _tempo_do_player(player_atual)
	var decorrido: float = tempo_base - tempos[player_atual]

	if decorrido < REACAO_PRESSAO_ATRAS_APOS_SEGUNDOS:
		return

	_ultima_pressao_ms = agora

	# Está jogando abaixo de alguém que já jogou: torcida vaia/pressiona.
	_tocar_not_supress("pressao_atras")

func _sortear_led_disponivel() -> int:
	var disponiveis: Array = []

	for i in range(LEDS_TOTAL):
		if not leds_ativos.has(i):
			disponiveis.append(i)

	if disponiveis.empty():
		return -1

	return disponiveis[randi() % disponiveis.size()]


func _rgb_aleatorio_alvo() -> Array:
	if CORES_ALVOS_RGB.empty():
		return [255, 255, 255]

	var index = int(randi() % CORES_ALVOS_RGB.size())
	var rgb: Array = CORES_ALVOS_RGB[index]

	return [
		int(rgb[0]),
		int(rgb[1]),
		int(rgb[2])
	]


func _rgb_led_por_index(index_led: int) -> Array:
	if cores_leds_ativos.has(index_led):
		var rgb_salvo: Array = cores_leds_ativos[index_led]

		return [
			int(rgb_salvo[0]),
			int(rgb_salvo[1]),
			int(rgb_salvo[2])
		]

	var novo_rgb = _rgb_aleatorio_alvo()
	cores_leds_ativos[index_led] = novo_rgb
	return novo_rgb


func _cor_led_ativo(index_led: int) -> Color:
	var rgb = _rgb_led_por_index(index_led)

	return Color(
		float(rgb[0]) / 255.0,
		float(rgb[1]) / 255.0,
		float(rgb[2]) / 255.0,
		1.0
	)


func _texto_fileiras_ativas() -> String:
	var partes: Array = []

	for index_led in leds_ativos:
		if index_led >= 0 and index_led < LEDS_LETRAS.size():
			partes.append(LEDS_LETRAS[index_led])

	return PoolStringArray(partes).join(", ")


# ============================================================
# HUD LEDS
# ============================================================
func _criar_hud_leds() -> void:
	leds_hud_layer = CanvasLayer.new()
	leds_hud_layer.layer = 50
	leds_hud_layer.visible = MOSTRAR_TECLAS_LED_HUD
	add_child(leds_hud_layer)

	leds_hud_root = Control.new()
	leds_hud_root.set_anchors_preset(Control.PRESET_WIDE)
	leds_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leds_hud_layer.add_child(leds_hud_root)

	var tela = get_viewport().get_visible_rect().size
	var tam: float = 64.0
	var gap: float = 14.0
	var largura_total: float = (tam * float(LEDS_TOTAL)) + (gap * float(LEDS_TOTAL - 1))
	var start_x: float = (tela.x - largura_total) * 0.5
	var y: float = tela.y - tam - 18.0

	leds_botoes.clear()
	leds_labels.clear()

	for i in range(LEDS_TOTAL):
		var btn := Panel.new()
		btn.rect_position = Vector2(start_x + float(i) * (tam + gap), y)
		btn.rect_size = Vector2(tam, tam)
		leds_hud_root.add_child(btn)
		leds_botoes.append(btn)

		var lbl := Label.new()
		lbl.text = LEDS_LETRAS[i]
		lbl.set_anchors_preset(Control.PRESET_WIDE)
		lbl.align = Label.ALIGN_CENTER
		lbl.valign = Label.VALIGN_CENTER
		Compat.tamanho(lbl, 32)
		lbl.add_constant_override("shadow_offset_x", 0)
		lbl.add_constant_override("shadow_offset_y", 0)

		if fonte_orbitron:
			Compat.fonte(lbl, fonte_orbitron)

		btn.add_child(lbl)
		leds_labels.append(lbl)

	_atualizar_leds_hud()


func _atualizar_leds_hud() -> void:
	if leds_hud_layer:
		leds_hud_layer.visible = MOSTRAR_TECLAS_LED_HUD

	if leds_botoes.empty():
		return

	for i in range(LEDS_TOTAL):
		var btn = leds_botoes[i]
		var lbl = leds_labels[i]
		var aceso = leds_ativos.has(i)

		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(16)
		style.set_border_width_all(3)
		style.shadow_offset = Vector2.ZERO

		if aceso:
			var cor_led = _cor_led_ativo(i)

			style.bg_color = Color(cor_led.r * 0.18, cor_led.g * 0.18, cor_led.b * 0.18, 0.96)
			style.border_color = cor_led
			style.shadow_color = Color(cor_led.r, cor_led.g, cor_led.b, 0.90)
			style.shadow_size = 26

			lbl.add_color_override("font_color", Color.white)
			lbl.add_color_override("font_color_shadow", cor_led)
		else:
			style.bg_color = Color(0.04, 0.05, 0.07, 0.92)
			style.border_color = Color(0.22, 0.24, 0.28, 1.0)
			style.shadow_color = Color(0, 0, 0, 0.3)
			style.shadow_size = 4

			lbl.add_color_override("font_color", Color(0.35, 0.38, 0.42))
			lbl.add_color_override("font_color_shadow", Color.transparent)

		btn.add_stylebox_override("panel", style)


# ============================================================
# FINALIZAÇÃO TURNO / PARTIDA
# ============================================================
func _finalizar_turno_player() -> void:
	var _g3_estado = null
	if player_atual < 0 or player_atual >= total_players:
		return

	partida_ativa = false

	leds_ativos.clear()
	cores_leds_ativos.clear()

	_atualizar_leds_hud()
	_enviar_leds_para_arduino()

	# Apito final SOA primeiro, sozinho, antes do modal de próximo player.
	_tocar_audio(sfx_apito_fim)

	terminou_player[player_atual] = true
	_atualizar_hud()

	# Folga para o apito ser ouvido antes de qualquer modal subir.
	yield(get_tree().create_timer(0.6), "timeout")

	if not _player_eh_bot(player_atual):
		_tocar_som_fim_turno_reativo(player_atual)
		_g3_estado = _esperar_som_reativo_terminar(2.6)
		if _g3_estado is GDScriptFunctionState:
			_g3_estado = yield(_g3_estado, "completed")

	var player_finalizado = player_atual
	var proximo := -1

	for i in range(total_players):
		if not terminou_player[i]:
			proximo = i
			break

	var nome_finalizado = _nome_player(player_finalizado)

	if proximo == -1:
		_g3_estado = _mostrar_aviso_turno(
			"TEMPO ESGOTADO",
			"%s FINALIZOU COM %d GOLS" % [
				nome_finalizado,
				scores[player_finalizado]
			],
			cores_players[player_finalizado]
		)
		if _g3_estado is GDScriptFunctionState:
			_g3_estado = yield(_g3_estado, "completed")

		# Em vez de finalizar direto, checa empate -> prorrogação -> pênaltis.
		_g3_estado = _resolver_empates_e_finalizar()
		if _g3_estado is GDScriptFunctionState:
			_g3_estado = yield(_g3_estado, "completed")
	else:
		var nome_proximo = _nome_player(proximo)

		if _player_eh_bot(player_finalizado):
			yield(get_tree().create_timer(0.35), "timeout")
		else:
			_g3_estado = _mostrar_aviso_turno(
				"TEMPO ESGOTADO",
				"%s FEZ %d GOLS  •  PRÓXIMO: %s" % [
					nome_finalizado,
					scores[player_finalizado],
					nome_proximo
				],
				cores_players[player_finalizado]
			)
			if _g3_estado is GDScriptFunctionState:
				_g3_estado = yield(_g3_estado, "completed")

		_tocar_audio(sfx_apito_troca)

		player_atual = proximo
		_reconstruir_paineis()

		yield(get_tree().create_timer(0.20), "timeout")

		_mostrar_preparacao_player()



func _finalizar_partida() -> void:
	partida_finalizada = true
	partida_ativa = false

	_serial_write("OFF")
	_atualizar_hud()

	yield(get_tree().create_timer(0.25), "timeout")

	_finalizar_partida_copa()



func _finalizar_partida_copa() -> void:
	var _g3_estado = null
	_serial_write("OFF")

	if audio_fundo:
		audio_fundo.stop()

	var ranking = _montar_ranking_copa()

	var cg = get_node_or_null("/root/CupGlobal")

	if cg != null:
		cg.salvar_resultado_pendente(partida_copa_index, ranking)
	else:
		push_warning("CupGlobal não encontrado; usando meta como backup.")

	get_tree().set_meta("resultado_copa_pendente", {
		"partida_index": partida_copa_index,
		"ranking": ranking
	})

	print("================================")
	print("RESULTADO DA COPA ENVIADO AO LOBBY")
	print("GRUPO: ", grupo_copa_nome)
	print("RODADA: ", rodada_copa)
	print("PARTIDA INDEX: ", partida_copa_index)
	print("RANKING: ", ranking)
	print("================================")

	# Mostra o modal de resultado UMA única vez.
	_g3_estado = _mostrar_modal_resultado_copa(ranking)
	if _g3_estado is GDScriptFunctionState:
		_g3_estado = yield(_g3_estado, "completed")

	if ResourceLoader.exists(CENA_CUP_LOBBY):
		# A tela de DESTINO (cup_lobby) é a dona do loading.
		_serial_write("OFF")
		_cobrir_tela_para_transicao()
		yield(get_tree(), "idle_frame")

		get_tree().change_scene(CENA_CUP_LOBBY)
	else:
		push_warning("cup_lobby.tscn não encontrada: " + CENA_CUP_LOBBY)



func _montar_ranking_copa() -> Array:
	var ranking: Array = []

	for i in range(total_players):
		var nome: String = _nome_player(i)

		var normais: int = 0
		if i < gols_normais.size():
			normais = int(gols_normais[i])

		var jogou_ot: bool = (i < jogou_prorrogacao.size()) and jogou_prorrogacao[i]
		var teve_resolucao: bool = jogou_ot or _algum_jogou_pen()

		if not teve_resolucao:
			normais = int(scores[i]) if i < scores.size() else 0

		var ot: int = 0
		if i < gols_prorrogacao.size():
			ot = int(gols_prorrogacao[i])

		var pens: int = 0
		if i < penaltis_marcados.size():
			pens = int(penaltis_marcados[i])

		var total: int = normais + ot

		var cor: Color = Color.white
		if i < cores_players.size():
			cor = cores_players[i]

		var eh_bot: bool = _player_eh_bot(i)

		ranking.append({
			"player_index": i,
			"nome": nome,
			"score": total,
			"gols": total,
			"gols_normais": normais,
			"gols_prorrogacao": ot,
			"jogou_prorrogacao": jogou_ot,
			"penaltis": pens,
			"jogou_penaltis": (i < jogou_penaltis.size()) and jogou_penaltis[i],
			"cor": cor,
			"boot": eh_bot,
			"posicao": 1,
			"pontos_tabela": 0
		})

	# Desempate em cascata: gols normais -> prorrogação -> pênaltis -> real > bot -> índice.
	ranking.sort_custom(self, "_ordem_1")

	# Posição sequencial ÚNICA (já desempatada em cascata acima).
	# É a posição usada no mata-mata, onde o critério SEMPRE decide.
	for i in range(ranking.size()):
		ranking[i]["posicao"] = i + 1

	# Pontos da tabela (fase de GRUPOS) com EMPATE:
	# quem tem o mesmo total de gols divide a MESMA colocação e
	# todos recebem os pontos da posição mais alta do grupo.
	# Ex.: 10 / 5 / 5 / 5  ->  1º = 3pts, e os três de 5 gols recebem 2pts cada.
	var i_grp: int = 0
	while i_grp < ranking.size():
		var gols_grp: int = int(ranking[i_grp].get("gols", 0))
		var j_grp: int = i_grp

		while j_grp < ranking.size() and int(ranking[j_grp].get("gols", 0)) == gols_grp:
			j_grp += 1

		var pts_grp: int = _pontos_copa_por_posicao(i_grp + 1)

		for k in range(i_grp, j_grp):
			ranking[k]["pontos_tabela"] = pts_grp

		i_grp = j_grp

	return ranking


func _algum_jogou_pen() -> bool:
	for v in jogou_penaltis:
		if v:
			return true
	return false



func _pontos_copa_por_posicao(posicao: int) -> int:
	match posicao:
		1: return 3
		2: return 2
		3: return 1
		_: return 0



# ============================================================
# MODAL DE RESULTADO DA COPA — TEXTO DE POSIÇÃO CORRETO
# ============================================================
func _mostrar_modal_resultado_copa(ranking: Array) -> void:
	_tocar_som_da_lista(SONS_TURNO_BOM, "modal_resultado", 1.0, true)

	final_layer = CanvasLayer.new()
	final_layer.layer = 300
	add_child(final_layer)

	var tela = get_viewport().get_visible_rect().size

	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_WIDE)
	fundo.color = Color(0, 0, 0, 0.86)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	final_layer.add_child(fundo)

	var cor_destaque = COR_ALERTA
	if ranking.size() > 0 and ranking[0].has("cor") and ranking[0]["cor"] is Color:
		cor_destaque = ranking[0]["cor"]

	var panel := Panel.new()
	panel.rect_size = Vector2(min(tela.x * 0.74, 1020.0), min(tela.y * 0.84, 740.0))
	panel.rect_position = (tela - panel.rect_size) / 2.0
	panel.rect_scale = Vector2(0.94, 0.94)
	panel.modulate = Color(1, 1, 1, 0)
	panel.rect_clip_content = true
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	final_layer.add_child(panel)

	var W = panel.rect_size.x
	var H = panel.rect_size.y

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.010, 0.014, 0.020, 0.985)
	style.border_color = cor_destaque
	style.set_border_width_all(4)
	style.set_corner_radius_all(0)
	style.shadow_color = Color(cor_destaque.r, cor_destaque.g, cor_destaque.b, 0.88)
	style.shadow_size = 52
	style.shadow_offset = Vector2.ZERO
	panel.add_stylebox_override("panel", style)

	if ResourceLoader.exists(FUNDO_RESULT):
		var img_fundo := TextureRect.new()
		img_fundo.rect_position = Vector2(4, 4)
		img_fundo.rect_size = Vector2(W - 8, H - 8)
		img_fundo.texture = load(FUNDO_RESULT)
		img_fundo.expand = true
		img_fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(img_fundo)

		var escuro_fundo := ColorRect.new()
		escuro_fundo.rect_position = Vector2(4, 4)
		escuro_fundo.rect_size = Vector2(W - 8, H - 8)
		escuro_fundo.color = Color(0.008, 0.012, 0.020, 0.80)
		escuro_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(escuro_fundo)

		var brilho_topo := ColorRect.new()
		brilho_topo.rect_position = Vector2(4, 4)
		brilho_topo.rect_size = Vector2(W - 8, 2)
		brilho_topo.color = Color(cor_destaque.r, cor_destaque.g, cor_destaque.b, 0.55)
		brilho_topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(brilho_topo)

	var faixa := ColorRect.new()
	faixa.rect_position = Vector2(48, 26)
	faixa.rect_size = Vector2(W - 96, 5)
	faixa.color = Color(cor_destaque.r, cor_destaque.g, cor_destaque.b, 0.95)
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(faixa)

	# ── Título da fase ──
	var titulo_txt: String
	if fase_copa == "FINAL" and not disputa_terceiro_copa:
		titulo_txt = "🏆 GRANDE FINAL"
	elif disputa_terceiro_copa:
		titulo_txt = "DISPUTA DO 3º LUGAR"
	elif fase_copa == "SEMIFINAL":
		titulo_txt = "SEMIFINAL"
	elif fase_copa == "OITAVAS":
		titulo_txt = "TOP 8"
	else:
		titulo_txt = "GRUPO %s  •  RODADA %d" % [grupo_copa_nome, rodada_copa]

	var lbl_titulo = _novo_label(titulo_txt, 34, Color.white, cor_destaque)
	lbl_titulo.rect_position = Vector2(20, 38)
	lbl_titulo.rect_size = Vector2(W - 40, 52)
	lbl_titulo.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.96))
	Compat.contorno(lbl_titulo, 5)
	panel.add_child(lbl_titulo)

	var lbl_sub = _novo_label(nome_partida_copa + "  •  RETORNANDO AO LOBBY", 15, Color(0.74, 0.82, 0.92))
	lbl_sub.rect_position = Vector2(30, 94)
	lbl_sub.rect_size = Vector2(W - 60, 26)
	lbl_sub.clip_text = true
	lbl_sub.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.85))
	Compat.contorno(lbl_sub, 3)
	panel.add_child(lbl_sub)

	# ── Cabeçalho das colunas ──
	var header_y := 132.0
	var col_x_pos   := 50.0
	var col_w_pos   := 64.0
	var col_x_nome  := 124.0
	var col_w_nome = W * 0.34
	var col_x_gols = col_x_nome + col_w_nome + 8.0
	var col_w_gols = W * 0.18
	var col_x_extra = col_x_gols + col_w_gols + 8.0
	var col_w_extra = W - col_x_extra - 50.0

	var eh_grupos = (fase_copa == "GRUPOS")
	var col_extra_titulo = "PONTOS" if eh_grupos else "RESULTADO"

	_g3_fazer_header(panel, header_y, "POS", col_x_pos, col_w_pos, Label.ALIGN_CENTER)
	_g3_fazer_header(panel, header_y, "JOGADOR", col_x_nome, col_w_nome, Label.ALIGN_LEFT)
	_g3_fazer_header(panel, header_y, "GOLS", col_x_gols, col_w_gols, Label.ALIGN_CENTER)
	_g3_fazer_header(panel, header_y, col_extra_titulo, col_x_extra, col_w_extra, Label.ALIGN_RIGHT)

	var sep_h := ColorRect.new()
	sep_h.rect_position = Vector2(50, header_y + 25)
	sep_h.rect_size = Vector2(W - 100, 2)
	sep_h.color = Color(cor_destaque.r, cor_destaque.g, cor_destaque.b, 0.55)
	sep_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sep_h)

	# ════════════════════════════════════════════════════════
	# POSIÇÕES E PONTOS
	# - GRUPOS: empate = MESMA colocação; pontos da posição mais
	#   alta do grupo (10/5/5/5 -> 1º=3pts, três de 5 = 2pts cada).
	# - MATA-MATA: posição ÚNICA, decidida pelo desempate em cascata
	#   (prorrogação/pênaltis ou critério). Nunca dois na mesma vaga.
	# ════════════════════════════════════════════════════════
	var grupos_pos: Dictionary = {}
	for item in ranking:
		var s: int = int(item.get("gols", item.get("score", 0)))
		if not grupos_pos.has(s):
			grupos_pos[s] = []
		grupos_pos[s].append(item)

	var scores_ord: Array = grupos_pos.keys()
	scores_ord.sort()
	scores_ord.invert()

	var posicao_exibida: Dictionary = {}
	var pontos_exibidos: Dictionary = {}
	var total_posicoes: int = 0

	if eh_grupos:
		var pos_cursor: int = 1
		for sc in scores_ord:
			var grupo: Array = grupos_pos[sc] as Array
			var qtd: int = grupo.size()
			var pts: int = _pontos_copa_por_posicao(pos_cursor)
			for item in grupo:
				var pidx: int = int(item["player_index"])
				posicao_exibida[pidx] = pos_cursor
				pontos_exibidos[pidx] = pts
			pos_cursor += qtd
		total_posicoes = pos_cursor - 1
	else:
		for item in ranking:
			var pidx: int = int(item["player_index"])
			posicao_exibida[pidx] = int(item.get("posicao", 0))
		total_posicoes = ranking.size()

	# Quantos jogadores têm cada total de gols (detecta desempate por critério).
	var contagem_gols: Dictionary = {}
	for item in ranking:
		var g: int = int(item.get("gols", item.get("score", 0)))
		contagem_gols[g] = int(contagem_gols.get(g, 0)) + 1

	# ── Linhas do ranking ──
	var y := 168.0
	var linha_h := 64.0
	var gap_linha := 10.0

	for item in ranking:
		var pidx: int = int(item.get("player_index", 0))
		var posicao: int = int(posicao_exibida.get(pidx, int(item.get("posicao", 0))))
		var score: int = int(item.get("gols", item.get("score", 0)))
		var nome: String = str(item.get("nome", "JOGADOR"))
		if bool(item.get("boot", false)):
			nome += " BOT"

		var jogou_ot: bool = bool(item.get("jogou_prorrogacao", false))
		var jogou_pen: bool = bool(item.get("jogou_penaltis", false))
		var empatou_criterio: bool = (not eh_grupos) and (int(contagem_gols.get(score, 0)) > 1)

		var detalhe_resultado: String = "TEMPO NORMAL"
		if jogou_ot and jogou_pen:
			detalhe_resultado = "PRORROGAÇÃO + PÊNALTIS"
		elif jogou_ot:
			detalhe_resultado = "COM PRORROGAÇÃO"
		elif jogou_pen:
			detalhe_resultado = "PÊNALTIS"
		elif empatou_criterio:
			detalhe_resultado = "CRITÉRIO DE DESEMPATE"

		# ── Coluna extra (pontos nos grupos / resultado no mata-mata) ──
		var extra_txt: String
		var extra_cor: Color

		if eh_grupos:
			var pts: int = int(pontos_exibidos.get(pidx, 0))
			extra_txt = "+%d PTS" % pts
			match pts:
				3: extra_cor = COR_OK
				2: extra_cor = Color(0.82, 0.86, 0.92)
				1: extra_cor = COR_ALERTA
				_: extra_cor = Color(0.55, 0.58, 0.64)
		else:
			extra_txt = _texto_posicao_resultado(posicao, total_posicoes)
			match extra_txt:
				"🏆 CAMPEÃO":
					extra_cor = COR_ALERTA
				"VICE-CAMPEÃO":
					extra_cor = Color(0.82, 0.86, 0.92)
				"🥉 3º LUGAR", "3º LUGAR":
					extra_cor = Color(0.78, 0.43, 0.18)
				"4º LUGAR":
					extra_cor = Color(0.45, 0.48, 0.52)
				"CLASSIFICADO À FINAL", "CLASSIFICADO":
					extra_cor = COR_OK
				"ELIMINADO":
					extra_cor = COR_ERRO
				_:
					extra_cor = Color(0.55, 0.58, 0.64)

		# ── Texto da coluna POS ──
		var pos_txt: String
		var usar_final = (fase_copa == "FINAL" and not disputa_terceiro_copa)

		if usar_final:
			match posicao:
				1: pos_txt = "🥇"
				2: pos_txt = "🥈"
				3: pos_txt = "🥉"
				_: pos_txt = "%dº" % posicao
		else:
			pos_txt = "%dº" % posicao

		# ── Cor da linha ──
		var linha_cor: Color
		match posicao:
			1: linha_cor = cor_destaque
			2: linha_cor = Color(0.82, 0.86, 0.92)
			3: linha_cor = Color(0.78, 0.43, 0.18)
			_: linha_cor = Color(0.50, 0.54, 0.60)

		# ── Painel da linha ──
		var row := Panel.new()
		row.rect_position = Vector2(50, y)
		row.rect_size = Vector2(W - 100, linha_h)
		row.rect_clip_content = true
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var rs := StyleBoxFlat.new()
		rs.bg_color = Color(linha_cor.r * 0.08, linha_cor.g * 0.08, linha_cor.b * 0.08, 0.88 if posicao == 1 else 0.74)
		rs.border_color = Color(linha_cor.r, linha_cor.g, linha_cor.b, 0.85 if posicao == 1 else 0.22)
		rs.set_border_width_all(2 if posicao == 1 else 1)
		rs.set_corner_radius_all(0)
		rs.shadow_color = Color(linha_cor.r, linha_cor.g, linha_cor.b, 0.28 if posicao == 1 else 0.05)
		rs.shadow_size = 14 if posicao == 1 else 4
		rs.shadow_offset = Vector2.ZERO
		row.add_stylebox_override("panel", rs)
		panel.add_child(row)

		var acento := ColorRect.new()
		acento.rect_position = Vector2(0, 0)
		acento.rect_size = Vector2(6, linha_h)
		acento.color = Color(linha_cor.r, linha_cor.g, linha_cor.b, 0.95)
		acento.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(acento)

		# Posição
		var lbl_pos = _novo_label(pos_txt, 22, linha_cor)
		lbl_pos.rect_position = Vector2(col_x_pos - 50, 0)
		lbl_pos.rect_size = Vector2(col_w_pos, linha_h)
		lbl_pos.align = Label.ALIGN_CENTER
		row.add_child(lbl_pos)

		var div1 := ColorRect.new()
		div1.rect_position = Vector2(col_x_nome - 50 - 8, linha_h * 0.18)
		div1.rect_size = Vector2(1, linha_h * 0.64)
		div1.color = Color(linha_cor.r, linha_cor.g, linha_cor.b, 0.18)
		div1.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(div1)

		# Nome
		var lbl_nome := Label.new()
		lbl_nome.text = nome
		lbl_nome.rect_position = Vector2(col_x_nome - 50, linha_h * 0.10)
		lbl_nome.rect_size = Vector2(col_w_nome, linha_h * 0.55)
		lbl_nome.align = Label.ALIGN_LEFT
		lbl_nome.valign = Label.VALIGN_CENTER
		lbl_nome.clip_text = true
		Compat.tamanho(lbl_nome, 21)
		lbl_nome.add_color_override("font_color", linha_cor)
		lbl_nome.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.85))
		Compat.contorno(lbl_nome, 3)
		if fonte_orbitron:
			Compat.fonte(lbl_nome, fonte_orbitron)
		row.add_child(lbl_nome)

		var tipo_str = "BOT" if bool(item.get("boot", false)) else "JOGADOR"
		var lbl_tipo := Label.new()
		lbl_tipo.text = tipo_str
		lbl_tipo.rect_position = Vector2(col_x_nome - 50, linha_h * 0.62)
		lbl_tipo.rect_size = Vector2(col_w_nome, linha_h * 0.32)
		lbl_tipo.align = Label.ALIGN_LEFT
		lbl_tipo.valign = Label.VALIGN_CENTER
		Compat.tamanho(lbl_tipo, 12)
		lbl_tipo.add_color_override("font_color", Color(0.56, 0.62, 0.72))
		lbl_tipo.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.70))
		Compat.contorno(lbl_tipo, 2)
		if fonte_orbitron:
			Compat.fonte(lbl_tipo, fonte_orbitron)
		row.add_child(lbl_tipo)

		var div2 := ColorRect.new()
		div2.rect_position = Vector2(col_x_gols - 50 - 8, linha_h * 0.18)
		div2.rect_size = Vector2(1, linha_h * 0.64)
		div2.color = Color(linha_cor.r, linha_cor.g, linha_cor.b, 0.18)
		div2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(div2)

		# Gols
		var lbl_score_num := Label.new()
		lbl_score_num.text = str(score)
		lbl_score_num.rect_position = Vector2(col_x_gols - 50, linha_h * 0.04)
		lbl_score_num.rect_size = Vector2(col_w_gols, linha_h * 0.60)
		lbl_score_num.align = Label.ALIGN_CENTER
		lbl_score_num.valign = Label.VALIGN_CENTER
		Compat.tamanho(lbl_score_num, 28)
		lbl_score_num.add_color_override("font_color", Color.white)
		lbl_score_num.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.90))
		Compat.contorno(lbl_score_num, 4)
		if fonte_orbitron:
			Compat.fonte(lbl_score_num, fonte_orbitron)
		row.add_child(lbl_score_num)

		var lbl_det := Label.new()
		lbl_det.text = detalhe_resultado
		lbl_det.rect_position = Vector2(col_x_gols - 50, linha_h * 0.62)
		lbl_det.rect_size = Vector2(col_w_gols, linha_h * 0.34)
		lbl_det.align = Label.ALIGN_CENTER
		lbl_det.valign = Label.VALIGN_CENTER
		Compat.tamanho(lbl_det, 11)
		lbl_det.add_color_override("font_color", Color(0.66, 0.74, 0.84))
		lbl_det.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.70))
		Compat.contorno(lbl_det, 2)
		if fonte_orbitron:
			Compat.fonte(lbl_det, fonte_orbitron)
		row.add_child(lbl_det)

		var div3 := ColorRect.new()
		div3.rect_position = Vector2(col_x_extra - 50 - 8, linha_h * 0.18)
		div3.rect_size = Vector2(1, linha_h * 0.64)
		div3.color = Color(linha_cor.r, linha_cor.g, linha_cor.b, 0.18)
		div3.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(div3)

		# Extra (pontos ou resultado)
		var lbl_extra := Label.new()
		lbl_extra.text = extra_txt
		lbl_extra.rect_position = Vector2(col_x_extra - 50, 0)
		lbl_extra.rect_size = Vector2(col_w_extra, linha_h)
		lbl_extra.align = Label.ALIGN_RIGHT
		lbl_extra.valign = Label.VALIGN_CENTER
		lbl_extra.clip_text = true
		Compat.tamanho(lbl_extra, 18)
		lbl_extra.add_color_override("font_color", extra_cor)
		lbl_extra.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.85))
		Compat.contorno(lbl_extra, 3)
		if fonte_orbitron:
			Compat.fonte(lbl_extra, fonte_orbitron)
		row.add_child(lbl_extra)

		y += linha_h + gap_linha

	# ── Separador e contador regressivo ──
	var sep_b := ColorRect.new()
	sep_b.rect_position = Vector2(50, H - 86)
	sep_b.rect_size = Vector2(W - 100, 1)
	sep_b.color = Color(1, 1, 1, 0.10)
	sep_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sep_b)

	var segundos := 8

	var contador = _novo_label("VOLTANDO EM %d" % segundos, 17, COR_ALERTA, COR_ALERTA)
	contador.rect_position = Vector2(0, H - 78)
	contador.rect_size = Vector2(W, 28)
	contador.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.85))
	Compat.contorno(contador, 3)
	panel.add_child(contador)

	var barra_bg := ColorRect.new()
	barra_bg.rect_position = Vector2(90, H - 38)
	barra_bg.rect_size = Vector2(W - 180, 6)
	barra_bg.color = Color(1, 1, 1, 0.12)
	barra_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(barra_bg)

	var barra := ColorRect.new()
	barra.rect_position = barra_bg.rect_position
	barra.rect_size = barra_bg.rect_size
	barra.color = Color(cor_destaque.r, cor_destaque.g, cor_destaque.b, 1.0)
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(barra)

	var entrada = create_tween()
	entrada.set_parallel(true)
	entrada.tween_property(panel, "modulate", Color.white, 0.22)
	entrada.tween_property(panel, "rect_scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	yield(entrada, "finished")

	for n in range(segundos, 0, -1):
		if is_instance_valid(contador):
			contador.text = "VOLTANDO EM %d" % n
		if is_instance_valid(barra):
			barra.rect_size.x = (W - 180) * (float(n) / float(segundos))
		yield(get_tree().create_timer(1.0), "timeout")

	var saida = create_tween()
	saida.set_parallel(true)
	saida.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.20)
	saida.tween_property(panel, "rect_scale", Vector2(0.95, 0.95), 0.20)

	yield(saida, "finished")

	if is_instance_valid(final_layer):
		final_layer.queue_free()

	final_layer = null



func _mostrar_aviso_turno(titulo_texto: String, subtitulo_texto: String, cor: Color) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 260
	add_child(layer)

	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_WIDE)
	fundo.color = Color(0, 0, 0, 0.0)
	layer.add_child(fundo)

	var panel := Panel.new()
	panel.rect_size = Vector2(900, 270)
	panel.rect_position = (get_viewport().get_visible_rect().size - panel.rect_size) / 2.0
	panel.rect_scale = Vector2(0.92, 0.92)
	panel.modulate = Color(1, 1, 1, 0)
	layer.add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.010, 0.014, 0.020, 0.97)
	style.border_color = cor
	style.set_border_width_all(4)
	style.set_corner_radius_all(36)
	style.shadow_color = Color(cor.r, cor.g, cor.b, 0.78)
	style.shadow_size = 40
	style.shadow_offset = Vector2.ZERO
	panel.add_stylebox_override("panel", style)

	var titulo = _novo_label(titulo_texto, 44, Color.white, cor)
	titulo.rect_position = Vector2(0, 44)
	titulo.rect_size = Vector2(900, 70)
	panel.add_child(titulo)

	var subtitulo = _novo_label(subtitulo_texto, 24, Color(0.78, 0.90, 0.95))
	subtitulo.rect_position = Vector2(40, 142)
	subtitulo.rect_size = Vector2(820, 74)
	subtitulo.autowrap = true
	panel.add_child(subtitulo)

	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(fundo, "color", Color(0, 0, 0, 0.68), 0.22)
	t.tween_property(panel, "modulate", Color.white, 0.22)
	t.tween_property(panel, "rect_scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	yield(t, "finished")
	yield(get_tree().create_timer(1.45), "timeout")

	var out = create_tween()
	out.set_parallel(true)
	out.tween_property(fundo, "color", Color(0, 0, 0, 0.0), 0.20)
	out.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.20)
	out.tween_property(panel, "rect_scale", Vector2(0.94, 0.94), 0.20)

	yield(out, "finished")

	if is_instance_valid(layer):
		layer.queue_free()


# ============================================================
# PRORROGAÇÃO E PÊNALTIS
# ============================================================
# Tempo de prorrogação = 50% do tempo ATUAL da fase (bot ou real).
func _tempo_prorrogacao(index: int) -> float:
	return max(_tempo_do_player(index) * FATOR_PRORROGACAO, 1.0)


# ============================================================
# MODAL DE RESULTADO — TEXTO CORRETO POR FASE
# ============================================================
func _texto_posicao_resultado(posicao: int, total_pos: int) -> String:
	# Grande Final: campeão, vice, 3º e 4º.
	if fase_copa == "FINAL" and not disputa_terceiro_copa:
		match posicao:
			1: return "🏆 CAMPEÃO"
			2: return "VICE-CAMPEÃO"
			3: return "3º LUGAR"
			_: return "4º LUGAR"

	# Disputa do 3º lugar: 1º leva o bronze, 2º fica em 4º.
	if disputa_terceiro_copa:
		if posicao == 1:
			return "🥉 3º LUGAR"
		return "4º LUGAR"

	# Semifinal: passa SOMENTE o 1º colocado.
	if fase_copa == "SEMIFINAL":
		if posicao == 1:
			return "CLASSIFICADO À FINAL"
		return "ELIMINADO"

	# Oitavas (TOP 8): passam os 2 primeiros.
	if fase_copa == "OITAVAS":
		if posicao <= 2:
			return "CLASSIFICADO"
		return "ELIMINADO"

	return ""



func _resolver_empates_e_finalizar() -> void:
	var _g3_estado = null
	# Congela o placar normal antes de qualquer desempate.
	for i in range(total_players):
		gols_normais[i] = scores[i]

	# GRUPOS / OITAVAS / fases sem desempate extra:
	# não tem prorrogação nem pênaltis.
	if not permite_prorrogacao_penaltis or not _fase_permite_prorrogacao_penaltis():
		fase_jogo = Fase.NORMAL
		_atualizar_hud()
		_finalizar_partida()
		return

	var grupos = _grupos_empatados_reais()

	# Se o empate foi só com bot, ou bot x bot, não roda prorrogação.
	# O ranking já resolve: real > bot > índice.
	if grupos.empty():
		fase_jogo = Fase.NORMAL
		_atualizar_hud()
		_finalizar_partida()
		return

	for grupo in grupos:
		_g3_estado = _resolver_grupo_empatado(grupo)
		if _g3_estado is GDScriptFunctionState:
			_g3_estado = yield(_g3_estado, "completed")

	# Restaura placar de exibição = normal + prorrogação.
	for i in range(total_players):
		scores[i] = gols_normais[i] + gols_prorrogacao[i]

	fase_jogo = Fase.NORMAL
	_atualizar_hud()
	_finalizar_partida()



# ============================================================
# PRORROGAÇÃO E PÊNALTIS — VERSÃO CORRIGIDA
# ============================================================

# Agrupa TODOS os jogadores (incluindo bots) com o mesmo placar normal.
func _grupos_empatados_reais() -> Array:
	var por_score: Dictionary = {}

	for i in range(total_players):
		var s: int = gols_normais[i]

		if not por_score.has(s):
			por_score[s] = []

		por_score[s].append(i)

	var chaves: Array = por_score.keys()
	chaves.sort()
	chaves.invert()

	var grupos: Array = []

	for s in chaves:
		var grupo_total: Array = por_score[s]
		var somente_reais: Array = []

		for p in grupo_total:
			var idx: int = int(p)

			if not _player_eh_bot(idx):
				somente_reais.append(idx)

		# Só existe prorrogação/pênaltis se 2 ou mais jogadores REAIS empataram.
		# Real x Bot empatado: o real ganha no critério do ranking.
		# Bot x Bot empatado: resolve por índice no ranking.
		if somente_reais.size() >= 2:
			grupos.append(somente_reais)

	return grupos



func _resolver_grupo_empatado(grupo: Array) -> void:
	var _g3_estado = null
	var grupo_real: Array = []

	for p in grupo:
		var idx: int = int(p)

		if idx < 0 or idx >= total_players:
			continue

		if not _player_eh_bot(idx):
			grupo_real.append(idx)

	if grupo_real.size() <= 1:
		return

	var nomes: Array = []

	for p in grupo_real:
		nomes.append(_nome_player(int(p)))

	_g3_estado = _mostrar_aviso_turno(
		"PRORROGAÇÃO",
		"EMPATE ENTRE %s  •  VALE 50%% DO TEMPO" % PoolStringArray(nomes).join(" E "),
		COR_ALERTA
	)
	if _g3_estado is GDScriptFunctionState:
		_g3_estado = yield(_g3_estado, "completed")

	fase_jogo = Fase.PRORROGACAO

	for p in grupo_real:
		jogou_prorrogacao[p] = true
		_g3_estado = _jogar_turno_prorrogacao(p)
		if _g3_estado is GDScriptFunctionState:
			_g3_estado = yield(_g3_estado, "completed")

	var ainda = _subset_max_ot(grupo_real)

	if ainda.size() <= 1:
		fase_jogo = Fase.NORMAL
		return

	_g3_estado = _rodar_penaltis(ainda)
	if _g3_estado is GDScriptFunctionState:
		_g3_estado = yield(_g3_estado, "completed")

	fase_jogo = Fase.NORMAL



func _subset_max_ot(grupo: Array) -> Array:
	var maxg: int = -1
	for p in grupo:
		if gols_prorrogacao[p] > maxg:
			maxg = gols_prorrogacao[p]

	var res: Array = []
	for p in grupo:
		if gols_prorrogacao[p] == maxg:
			res.append(p)

	return res



func _jogar_turno_prorrogacao(p: int) -> void:
	if _player_eh_bot(p):
		return

	fase_jogo = Fase.PRORROGACAO
	player_atual = p

	var base: int = gols_normais[p]
	scores[p] = base
	terminou_player[p] = false
	tempos[p] = _tempo_prorrogacao(p)
	_ot_turno_acabou = false

	leds_ativos.clear()
	cores_leds_ativos.clear()

	_reconstruir_paineis()
	_mostrar_preparacao_player()

	while not _ot_turno_acabou:
		yield(get_tree(), "idle_frame")

	gols_prorrogacao[p] = int(max(scores[p] - base, 0))
	terminou_player[p] = true
	_serial_write("OFF")

	# ── NOVO: apito de fim igual ao turno normal ──
	_tocar_audio(sfx_apito_fim)
	yield(get_tree().create_timer(0.6), "timeout")

	_atualizar_hud()
	yield(get_tree().create_timer(0.10), "timeout")


func _sortear_bocas_penalti() -> Array:
	var todos: Array = []
	for i in range(LEDS_TOTAL):
		todos.append(i)
	todos.shuffle()

	var res: Array = []
	for i in range(int(min(PENALTI_QTD_BOCAS, todos.size()))):
		res.append(todos[i])
	return res


func _rodar_penaltis(participantes: Array) -> void:
	var _g3_estado = null
	fase_jogo = Fase.PENALTIS
	partida_ativa = false
	aguardando_start_turno = false
	em_contagem_inicio = false

	_serial_write("OFF")

	var jogadores_penalti: Array = []

	for p in participantes:
		var idx: int = int(p)

		if idx < 0 or idx >= total_players:
			continue

		if _player_eh_bot(idx):
			continue

		if jogadores_penalti.has(idx):
			continue

		jogadores_penalti.append(idx)

	if jogadores_penalti.size() <= 1:
		fase_jogo = Fase.NORMAL
		return

	for p in jogadores_penalti:
		jogou_penaltis[p] = true
		penaltis_marcados[p] = 0

	_g3_estado = _mostrar_aviso_turno(
		"DISPUTA DE PÊNALTIS",
		"%d BOCA%s ACENDEM  •  %ds PARA ACERTAR  •  %d COBRANÇAS" % [
			PENALTI_QTD_BOCAS,
			"S" if PENALTI_QTD_BOCAS > 1 else "",
			int(PENALTI_TEMPO_ACERTO),
			PENALTI_RODADAS_INICIAIS
		],
		COR_NEON
	)
	if _g3_estado is GDScriptFunctionState:
		_g3_estado = yield(_g3_estado, "completed")

	_criar_overlay_penalti(jogadores_penalti)

	var pen: Dictionary = {}

	for p in jogadores_penalti:
		pen[p] = 0

	_atualizar_overlay_penalti(jogadores_penalti, pen, -1)

	# Cada jogador faz TODAS as cobranças iniciais antes de passar a vez.
	for p in jogadores_penalti:
		for rodada in range(PENALTI_RODADAS_INICIAIS):
			_g3_estado = _cobrar_penalti(p, rodada + 1, jogadores_penalti, pen)
			if _g3_estado is GDScriptFunctionState:
				_g3_estado = yield(_g3_estado, "completed")
			var marcou: bool = _g3_estado

			if marcou:
				pen[p] = int(pen[p]) + 1

			penaltis_marcados[p] = int(pen[p])
			_atualizar_overlay_penalti(jogadores_penalti, pen, p)

	var contestados: Array = jogadores_penalti.duplicate()
	var lider: int = _lider_penaltis(pen, contestados)
	var rodada_sd: int = PENALTI_RODADAS_INICIAIS

	# Morte súbita: só continuam os empatados no topo.
	while lider == -1:
		rodada_sd += 1
		contestados = _empatados_topo_penaltis(pen, contestados)

		if contestados.size() <= 1:
			lider = int(contestados[0])
			break

		_g3_estado = _mostrar_aviso_turno(
			"MORTE SÚBITA",
			"EMPATE NOS PÊNALTIS  •  UMA COBRANÇA PARA CADA",
			COR_ALERTA
		)
		if _g3_estado is GDScriptFunctionState:
			_g3_estado = yield(_g3_estado, "completed")

		_atualizar_overlay_penalti(contestados, pen, -1)

		for p in contestados:
			_g3_estado = _cobrar_penalti(p, rodada_sd, contestados, pen)
			if _g3_estado is GDScriptFunctionState:
				_g3_estado = yield(_g3_estado, "completed")
			var marcou_sd: bool = _g3_estado

			if marcou_sd:
				pen[p] = int(pen[p]) + 1

			penaltis_marcados[p] = int(pen[p])
			_atualizar_overlay_penalti(contestados, pen, p)

		lider = _lider_penaltis(pen, contestados)

	_g3_estado = _mostrar_vencedor_penalti(lider)
	if _g3_estado is GDScriptFunctionState:
		_g3_estado = yield(_g3_estado, "completed")

	_remover_overlay_penalti()

	leds_ativos.clear()
	cores_leds_ativos.clear()
	_atualizar_leds_hud()
	_enviar_leds_para_arduino()

	fase_jogo = Fase.NORMAL


func _lider_penaltis(pen: Dictionary, subset: Array) -> int:
	var maxg: int = -1
	for p in subset:
		if int(pen[p]) > maxg:
			maxg = int(pen[p])

	var topo: Array = []
	for p in subset:
		if int(pen[p]) == maxg:
			topo.append(p)

	if topo.size() == 1:
		return int(topo[0])
	return -1


func _empatados_topo_penaltis(pen: Dictionary, subset: Array) -> Array:
	var maxg: int = -1
	for p in subset:
		if int(pen[p]) > maxg:
			maxg = int(pen[p])

	var res: Array = []
	for p in subset:
		if int(pen[p]) == maxg:
			res.append(p)
	return res



func _cobrar_penalti(p: int, num_rodada: int, participantes: Array, pen: Dictionary) -> bool:
	var _g3_estado = null
	if p < 0 or p >= total_players:
		return false

	player_atual = p

	var eh_bot = _player_eh_bot(p)

	_set_overlay_penalti_chute(p, num_rodada)
	_atualizar_overlay_penalti(participantes, pen, p)

	# Jogador REAL: exibe "APERTE START", aguarda, depois conta 3s para se posicionar.
	if not eh_bot:
		_pen_aguardando = false
		leds_ativos.clear()
		cores_leds_ativos.clear()
		_atualizar_leds_hud()
		_enviar_leds_para_arduino()

		if pen_contagem and is_instance_valid(pen_contagem):
			pen_contagem.text = ""
		if pen_feedback and is_instance_valid(pen_feedback):
			pen_feedback.text = "APERTE START PARA COBRAR"
			pen_feedback.add_color_override("font_color", COR_OK)
			pen_feedback.add_color_override("font_color_shadow", COR_OK)

		yield(get_tree().create_timer(0.25), "timeout")

		while not _start_foi_pressionado():
			yield(get_tree(), "idle_frame")

		if pen_feedback and is_instance_valid(pen_feedback):
			pen_feedback.text = "PREPARE-SE..."
			pen_feedback.add_color_override("font_color", COR_ALERTA)
			pen_feedback.add_color_override("font_color_shadow", COR_ALERTA)

		# Contagem de 3s para o player se posicionar antes da boca acender.
		for n in range(3, 0, -1):
			if pen_contagem and is_instance_valid(pen_contagem):
				pen_contagem.text = str(n)
				pen_contagem.add_color_override("font_color", Color(1.0, 0.85, 0.08))
				pen_contagem.add_color_override("font_color_shadow", Color(1.0, 0.35, 0.05))
				pen_contagem.rect_scale = Vector2(1.25, 1.25)
				var tc = create_tween()
				tc.tween_property(pen_contagem, "rect_scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			yield(get_tree().create_timer(0.85), "timeout")

		if pen_contagem and is_instance_valid(pen_contagem):
			pen_contagem.text = ""
		if pen_feedback and is_instance_valid(pen_feedback):
			pen_feedback.text = ""

	# Sorteia e acende SOMENTE uma boca.
	var bocas = _sortear_bocas_penalti()

	_pen_alvos.clear()
	leds_ativos.clear()
	cores_leds_ativos.clear()

	for a in bocas:
		var alvo: int = int(a)
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

	yield(get_tree().create_timer(0.35), "timeout")

	_pen_resultado = 0
	_pen_aguardando = true

	var marcou := false
	var bot_marca := false
	var bot_momento := 0.0

	if eh_bot:
		bot_marca = randf() < PENALTI_PROB_BOT
		bot_momento = rand_range(0.6, max(PENALTI_TEMPO_ACERTO - 0.5, 0.7))

	var t0 = float(Time.get_ticks_msec())

	while (float(Time.get_ticks_msec()) - t0) / 1000.0 < PENALTI_TEMPO_ACERTO:
		if _pen_resultado == 1:
			marcou = true
			break

		if _pen_resultado == 2:
			marcou = false
			break

		if eh_bot and bot_marca:
			var tempo_passado = (float(Time.get_ticks_msec()) - t0) / 1000.0
			if tempo_passado >= bot_momento and not _pen_alvos.empty():
				var alvo_bot = int(_pen_alvos[randi() % _pen_alvos.size()])
				_flash_led(alvo_bot, true)
				_pen_resultado = 1
				marcou = true
				break

		_atualizar_contagem_penalti(t0)
		yield(get_tree(), "idle_frame")

	_pen_aguardando = false

	leds_ativos.clear()
	cores_leds_ativos.clear()
	_atualizar_leds_hud()
	_enviar_leds_para_arduino()

	if marcou:
		if sfx_ponto and sfx_ponto.stream:
			sfx_ponto.stop()
			sfx_ponto.play()
		_tocar_som_da_lista(SONS_TURNO_BOM, "penalti_gol", 1.2, true)
		_feedback_penalti(true)
	else:
		_tocar_som_da_lista(SONS_VAIA, "penalti_erro", 1.0, true)
		_feedback_penalti(false)

	_g3_estado = _esperar_som_reativo_terminar(3.5)
	if _g3_estado is GDScriptFunctionState:
		_g3_estado = yield(_g3_estado, "completed")

	return marcou


func _registrar_chute_penalti(index_led: int) -> void:
	if not _pen_aguardando:
		return

	if index_led < 0 or index_led >= LEDS_TOTAL:
		return

	if _pen_alvos.has(index_led):
		_flash_led(index_led, true)
		_pen_resultado = 1   # GOL
	else:
		_flash_led(index_led, false)
		_pen_resultado = 2   # ERROU (encerra a cobrança no único impacto)

	_pen_aguardando = false



func _esperar_som_reativo_terminar(timeout_seg: float = 3.5) -> void:
	# Garante que o som comece e espera ele terminar (com teto de segurança).
	yield(get_tree().create_timer(0.05), "timeout")

	var t0 = float(Time.get_ticks_msec())

	while sfx_reativo and sfx_reativo.playing:
		if (float(Time.get_ticks_msec()) - t0) / 1000.0 >= timeout_seg:
			break

		yield(get_tree(), "idle_frame")

	yield(get_tree().create_timer(0.12), "timeout")



# ============================================================
# OVERLAY DE PÊNALTIS — COR DINÂMICA + BARRA CORRIGIDA
# ============================================================
func _criar_overlay_penalti(participantes: Array) -> void:
	if pen_layer != null and is_instance_valid(pen_layer):
		return

	pen_participantes = participantes.duplicate()
	pen_card_panels.clear()
	pen_card_score_labels.clear()
	pen_card_status_labels.clear()
	pen_card_nome_labels.clear()
	pen_estado_cards.clear()

	pen_layer = CanvasLayer.new()
	pen_layer.layer = 280
	add_child(pen_layer)

	var tela = get_viewport().get_visible_rect().size

	var cor_modal: Color = COR_NEON
	if participantes.size() > 0:
		var rv = 0.0; var gv := 0.0; var bv := 0.0
		for p in participantes:
			var idx = int(p)
			if idx >= 0 and idx < cores_players.size():
				rv += cores_players[idx].r
				gv += cores_players[idx].g
				bv += cores_players[idx].b
		var n = float(participantes.size())
		cor_modal = Color(rv / n, gv / n, bv / n, 1.0)

	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_WIDE)
	fundo.color = Color(cor_modal.r * 0.06, cor_modal.g * 0.06, cor_modal.b * 0.06, 0.82)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pen_layer.add_child(fundo)

	# Tamanho proporcional ao número de participantes.
	var qtd: int = participantes.size()
	var card_w: float = 220.0
	var card_gap: float = 18.0
	var cards_total_w: float = card_w * float(qtd) + card_gap * float(qtd - 1)
	var painel_w: float = clamp(cards_total_w + 120.0, 500.0, tela.x * 0.90)
	var painel_h: float = 560.0

	pen_panel_root = Panel.new()
	pen_panel_root.rect_size = Vector2(painel_w, painel_h)
	# Centralização explícita.
	pen_panel_root.rect_position = Vector2(
		(tela.x - painel_w) * 0.5,
		(tela.y - painel_h) * 0.5
	)
	pen_panel_root.modulate = Color(1, 1, 1, 0)
	pen_panel_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pen_layer.add_child(pen_panel_root)

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.010, 0.014, 0.020, 0.985)
	st.border_color = cor_modal
	st.set_border_width_all(4)
	st.set_corner_radius_all(0)
	st.shadow_color = Color(cor_modal.r, cor_modal.g, cor_modal.b, 0.90)
	st.shadow_size = 48
	st.shadow_offset = Vector2.ZERO
	pen_panel_root.add_stylebox_override("panel", st)

	var W = pen_panel_root.rect_size.x

	var faixa_topo := ColorRect.new()
	faixa_topo.rect_position = Vector2(0, 0)
	faixa_topo.rect_size = Vector2(W, 6)
	faixa_topo.color = Color(cor_modal.r, cor_modal.g, cor_modal.b, 0.95)
	faixa_topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pen_panel_root.add_child(faixa_topo)

	pen_titulo = _novo_label("DISPUTA DE PÊNALTIS", 34, Color.white, cor_modal)
	pen_titulo.rect_position = Vector2(0, 14)
	pen_titulo.rect_size = Vector2(W, 48)
	pen_titulo.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.96))
	Compat.contorno(pen_titulo, 4)
	pen_panel_root.add_child(pen_titulo)

	pen_rodada = _novo_label("", 16, COR_ALERTA, COR_ALERTA)
	pen_rodada.rect_position = Vector2(0, 62)
	pen_rodada.rect_size = Vector2(W, 24)
	pen_panel_root.add_child(pen_rodada)

	pen_chutador = _novo_label("", 28, Color.white)
	pen_chutador.rect_position = Vector2(20, 90)
	pen_chutador.rect_size = Vector2(W - 40, 44)
	pen_chutador.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.96))
	Compat.contorno(pen_chutador, 4)
	pen_panel_root.add_child(pen_chutador)

	# Cards centralizados horizontalmente.
	var cards_x: float = (W - cards_total_w) * 0.5
	pen_cards_box = HBoxContainer.new()
	pen_cards_box.rect_position = Vector2(cards_x, 144)
	pen_cards_box.rect_size = Vector2(cards_total_w, 220)
	pen_cards_box.add_constant_override("separation", int(card_gap))
	pen_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	pen_cards_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pen_panel_root.add_child(pen_cards_box)

	for p in pen_participantes:
		_criar_card_penalti(int(p))

	pen_contagem = _novo_label("", 80, Color(1.0, 0.85, 0.08), Color(1.0, 0.35, 0.05))
	pen_contagem.rect_position = Vector2(0, 376)
	pen_contagem.rect_size = Vector2(W, 90)
	pen_panel_root.add_child(pen_contagem)

	pen_feedback = _novo_label("", 26, Color.white)
	pen_feedback.rect_position = Vector2(0, 474)
	pen_feedback.rect_size = Vector2(W, 40)
	pen_feedback.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.96))
	Compat.contorno(pen_feedback, 4)
	pen_panel_root.add_child(pen_feedback)

	var sep_base := ColorRect.new()
	sep_base.rect_position = Vector2(40, 472)
	sep_base.rect_size = Vector2(W - 80, 1)
	sep_base.color = Color(1, 1, 1, 0.08)
	sep_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pen_panel_root.add_child(sep_base)

	var entrada = create_tween()
	entrada.set_parallel(true)
	entrada.tween_property(pen_panel_root, "modulate", Color.white, 0.22)

	for p in pen_participantes:
		pen_estado_cards[int(p)] = "NA DISPUTA"
		_aplicar_visual_card_penalti(int(p), "NA DISPUTA", false)


func _criar_card_penalti(p: int) -> void:
	if pen_cards_box == null or not is_instance_valid(pen_cards_box):
		return

	var cor = cores_players[p]

	var card := Panel.new()
	card.rect_min_size = Vector2(220, 216)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pen_cards_box.add_child(card)

	var W: float = 220.0
	var H: float = 216.0

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.014, 0.018, 0.026, 0.97)
	st.border_color = Color(cor.r * 0.5, cor.g * 0.5, cor.b * 0.5, 0.6)
	st.set_border_width_all(2)
	st.set_corner_radius_all(0)
	st.shadow_color = Color(0, 0, 0, 0.35)
	st.shadow_size = 10
	st.shadow_offset = Vector2.ZERO
	card.add_stylebox_override("panel", st)

	# Faixa de cor no topo do card.
	var faixa := ColorRect.new()
	faixa.rect_position = Vector2(0, 0)
	faixa.rect_size = Vector2(W, 6)
	faixa.color = Color(cor.r, cor.g, cor.b, 1.0)
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(faixa)

	# Nome do jogador.
	var lbl_nome = _novo_label(_nome_player(p), 18, Color.white, cor)
	lbl_nome.rect_position = Vector2(0, 10)
	lbl_nome.rect_size = Vector2(W, 30)
	lbl_nome.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.90))
	Compat.contorno(lbl_nome, 3)
	card.add_child(lbl_nome)

	# Tipo.
	var tipo_txt = "BOT" if _player_eh_bot(p) else "JOGADOR"
	var lbl_tipo = _novo_label(tipo_txt, 12, Color(0.60, 0.66, 0.76))
	lbl_tipo.rect_position = Vector2(0, 40)
	lbl_tipo.rect_size = Vector2(W, 18)
	card.add_child(lbl_tipo)

	# Separador.
	var sep := ColorRect.new()
	sep.rect_position = Vector2(W * 0.10, 62)
	sep.rect_size = Vector2(W * 0.80, 1)
	sep.color = Color(1, 1, 1, 0.10)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sep)

	# Label "PÊNALTIS".
	var lbl_sub = _novo_label("PÊNALTIS", 12, Color(0.46, 0.52, 0.62))
	lbl_sub.rect_position = Vector2(0, 66)
	lbl_sub.rect_size = Vector2(W, 18)
	card.add_child(lbl_sub)

	# Placar grande — ocupa bem a área central.
	var lbl_score = _novo_label("0", 72, Color.white, cor)
	lbl_score.rect_position = Vector2(0, 82)
	lbl_score.rect_size = Vector2(W, 88)
	lbl_score.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.96))
	Compat.contorno(lbl_score, 6)
	card.add_child(lbl_score)

	# Status na base.
	var lbl_status = _novo_label("NA DISPUTA", 13, Color(0.70, 0.76, 0.86))
	lbl_status.rect_position = Vector2(0, H - 32)
	lbl_status.rect_size = Vector2(W, 28)
	lbl_status.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.90))
	Compat.contorno(lbl_status, 3)
	card.add_child(lbl_status)

	pen_card_panels[p] = card
	pen_card_score_labels[p] = lbl_score
	pen_card_status_labels[p] = lbl_status
	pen_card_nome_labels[p] = lbl_nome



func _aplicar_visual_card_penalti(p: int, status_texto: String, destaque: bool = false) -> void:
	var card = pen_card_panels.get(p, null) as Panel
	var lbl_score = pen_card_score_labels.get(p, null) as Label
	var lbl_status = pen_card_status_labels.get(p, null) as Label
	var lbl_nome = pen_card_nome_labels.get(p, null) as Label

	if card == null or lbl_score == null or lbl_status == null or lbl_nome == null:
		return

	pen_estado_cards[p] = status_texto

	var cor_player: Color = cores_players[p]
	var bg = Color(0.018, 0.022, 0.032, 0.96)
	var borda = Color(0.22, 0.26, 0.34, 1.0)
	var sombra = Color(0, 0, 0, 0.28)
	var cor_status = Color(0.74, 0.80, 0.88)
	var escala_alvo = Vector2.ONE
	var mod_alvo = Color(0.94, 0.94, 0.94, 1.0)

	match status_texto:
		"COBRANDO", "VEZ AGORA", "PREPARANDO":
			bg = Color(cor_player.r * 0.10, cor_player.g * 0.10, cor_player.b * 0.10, 0.98)
			borda = cor_player
			sombra = Color(cor_player.r, cor_player.g, cor_player.b, 0.85)
			cor_status = cor_player
			escala_alvo = Vector2(1.03, 1.03)
			mod_alvo = Color.white

		"GOL":
			bg = Color(0.02, 0.09, 0.04, 0.98)
			borda = COR_OK
			sombra = Color(COR_OK.r, COR_OK.g, COR_OK.b, 0.88)
			cor_status = COR_OK
			escala_alvo = Vector2(1.02, 1.02)
			mod_alvo = Color.white

		"PERDEU":
			bg = Color(0.10, 0.025, 0.025, 0.98)
			borda = COR_ERRO
			sombra = Color(COR_ERRO.r, COR_ERRO.g, COR_ERRO.b, 0.88)
			cor_status = COR_ERRO
			escala_alvo = Vector2(1.01, 1.01)
			mod_alvo = Color.white

		"VENCEU":
			bg = Color(0.12, 0.08, 0.02, 0.99)
			borda = COR_ALERTA
			sombra = Color(COR_ALERTA.r, COR_ALERTA.g, COR_ALERTA.b, 0.92)
			cor_status = COR_ALERTA
			escala_alvo = Vector2(1.06, 1.06)
			mod_alvo = Color.white

		"FIM":
			bg = Color(0.028, 0.030, 0.034, 0.96)
			borda = Color(0.30, 0.32, 0.36, 1.0)
			sombra = Color(0, 0, 0, 0.18)
			cor_status = Color(0.62, 0.66, 0.72)
			escala_alvo = Vector2.ONE
			mod_alvo = Color(0.86, 0.86, 0.86, 1.0)

		_:
			if destaque:
				bg = Color(cor_player.r * 0.08, cor_player.g * 0.08, cor_player.b * 0.08, 0.98)
				borda = cor_player
				sombra = Color(cor_player.r, cor_player.g, cor_player.b, 0.78)
				cor_status = cor_player
				escala_alvo = Vector2(1.02, 1.02)
				mod_alvo = Color.white

	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = borda
	st.set_border_width_all(3 if destaque or status_texto in ["COBRANDO", "VEZ AGORA", "GOL", "PERDEU", "VENCEU"] else 2)
	st.set_corner_radius_all(22)
	st.shadow_color = sombra
	st.shadow_size = 20 if destaque or status_texto in ["COBRANDO", "VEZ AGORA", "GOL", "PERDEU", "VENCEU"] else 6
	st.shadow_offset = Vector2.ZERO
	card.add_stylebox_override("panel", st)

	lbl_nome.add_color_override("font_color_shadow", borda if destaque else cor_player)
	lbl_score.add_color_override("font_color_shadow", borda)
	lbl_status.text = status_texto
	lbl_status.add_color_override("font_color", cor_status)
	lbl_status.add_color_override("font_color_shadow", cor_status)

	card.rect_pivot_offset = card.rect_size * 0.5
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(card, "rect_scale", escala_alvo, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(card, "modulate", mod_alvo, 0.14)



func _set_overlay_penalti_chute(p: int, num_rodada: int) -> void:
	if pen_chutador == null or not is_instance_valid(pen_chutador):
		return

	var cor = cores_players[p]
	var nome = _nome_player(p)

	if _player_eh_bot(p):
		nome += " BOT"

	pen_chutador.text = "VEZ DE %s" % nome
	pen_chutador.add_color_override("font_color", cor)
	pen_chutador.add_color_override("font_color_shadow", cor)

	if num_rodada > PENALTI_RODADAS_INICIAIS:
		pen_rodada.text = "MORTE SÚBITA • COBRANÇA %d" % num_rodada
	else:
		pen_rodada.text = "COBRANÇA %d DE %d" % [num_rodada, PENALTI_RODADAS_INICIAIS]

	pen_feedback.text = ""
	pen_contagem.text = ""

	for pp in pen_participantes:
		var idx = int(pp)

		if idx == p:
			_aplicar_visual_card_penalti(idx, "VEZ AGORA", true)
		else:
			var estado_atual: String = str(pen_estado_cards.get(idx, "NA DISPUTA"))

			if estado_atual in ["COBRANDO", "VEZ AGORA", "PREPARANDO"]:
				estado_atual = "NA DISPUTA"

			_aplicar_visual_card_penalti(idx, estado_atual, false)





func _atualizar_overlay_penalti(participantes: Array, pen: Dictionary, destaque: int) -> void:
	if pen_cards_box == null or not is_instance_valid(pen_cards_box):
		return

	for pp in participantes:
		var p = int(pp)

		if not pen_card_panels.has(p):
			_criar_card_penalti(p)

		var lbl_score = pen_card_score_labels.get(p, null) as Label

		if lbl_score != null:
			lbl_score.text = str(int(pen.get(p, 0)))

		var status_txt: String = str(pen_estado_cards.get(p, "NA DISPUTA"))

		if p == destaque:
			if _pen_aguardando:
				status_txt = "COBRANDO"
			elif not (status_txt in ["GOL", "PERDEU", "VENCEU"]):
				status_txt = "VEZ AGORA"
		else:
			if status_txt in ["COBRANDO", "VEZ AGORA", "PREPARANDO"]:
				status_txt = "NA DISPUTA"

		_aplicar_visual_card_penalti(p, status_txt, p == destaque)


func _atualizar_contagem_penalti(t0: float) -> void:
	if pen_contagem == null or not is_instance_valid(pen_contagem):
		return

	var restante = PENALTI_TEMPO_ACERTO - (float(Time.get_ticks_msec()) - t0) / 1000.0
	restante = clamp(restante, 0.0, PENALTI_TEMPO_ACERTO)

	pen_contagem.text = "%d" % int(ceil(restante))

	if restante <= 2.0:
		pen_contagem.add_color_override("font_color", COR_ERRO)
		pen_contagem.add_color_override("font_color_shadow", COR_ERRO)
	else:
		pen_contagem.add_color_override("font_color", Color(1.0, 0.85, 0.08))
		pen_contagem.add_color_override("font_color_shadow", Color(1.0, 0.35, 0.05))


func _feedback_penalti(ok: bool) -> void:
	if pen_feedback == null or not is_instance_valid(pen_feedback):
		return

	if ok:
		pen_feedback.text = "GOL!"
		pen_feedback.add_color_override("font_color", COR_OK)
		pen_feedback.add_color_override("font_color_shadow", COR_OK)
		_aplicar_visual_card_penalti(player_atual, "GOL", true)
	else:
		pen_feedback.text = "PERDEU!"
		pen_feedback.add_color_override("font_color", COR_ERRO)
		pen_feedback.add_color_override("font_color_shadow", COR_ERRO)
		_aplicar_visual_card_penalti(player_atual, "PERDEU", true)

	if pen_contagem and is_instance_valid(pen_contagem):
		pen_contagem.text = ""


func _mostrar_vencedor_penalti(vencedor: int) -> void:
	if vencedor < 0 or vencedor >= total_players:
		return

	var cor = cores_players[vencedor]
	var nome = _nome_player(vencedor)

	if _player_eh_bot(vencedor):
		nome += " BOT"

	if pen_titulo and is_instance_valid(pen_titulo):
		pen_titulo.text = "FIM DOS PÊNALTIS"

	if pen_chutador and is_instance_valid(pen_chutador):
		pen_chutador.text = "%s VENCEU NOS PÊNALTIS!" % nome
		pen_chutador.add_color_override("font_color", cor)
		pen_chutador.add_color_override("font_color_shadow", cor)

	if pen_rodada and is_instance_valid(pen_rodada):
		pen_rodada.text = "CLASSIFICAÇÃO DEFINIDA"

	if pen_contagem and is_instance_valid(pen_contagem):
		pen_contagem.text = ""

	if pen_feedback and is_instance_valid(pen_feedback):
		pen_feedback.text = "🏆 CLASSIFICADO!"
		pen_feedback.add_color_override("font_color", COR_ALERTA)
		pen_feedback.add_color_override("font_color_shadow", COR_ALERTA)

	for pp in pen_participantes:
		var p = int(pp)

		if p == vencedor:
			_aplicar_visual_card_penalti(p, "VENCEU", true)
		else:
			_aplicar_visual_card_penalti(p, "FIM", false)

	if sfx_reativo and sfx_reativo.playing:
		sfx_reativo.stop()

	if sfx_campeao and sfx_campeao.stream:
		if sfx_campeao.stream is AudioStream:
			Compat.laco(sfx_campeao.stream, false)

		_duck_musica(true, 0.12)
		sfx_campeao.stop()
		sfx_campeao.play()
	else:
		_tocar_som_da_lista(SONS_SUPEROU_TURNO, "penalti_vitoria", 1.4, true)

	yield(get_tree().create_timer(0.1), "timeout")

	var _t0_vit = float(Time.get_ticks_msec())

	while true:
		var passou = (float(Time.get_ticks_msec()) - _t0_vit) / 1000.0
		var tocando = (sfx_campeao and sfx_campeao.playing) or (sfx_reativo and sfx_reativo.playing)

		if passou >= 8.0:
			break

		if passou >= 2.5 and not tocando:
			break

		yield(get_tree(), "idle_frame")

	if sfx_campeao and not sfx_campeao.playing:
		_duck_musica(false, 0.25)



func _remover_overlay_penalti() -> void:
	if pen_layer != null and is_instance_valid(pen_layer):
		pen_layer.queue_free()

	pen_layer = null
	pen_panel_root = null
	pen_cards_box = null

	pen_titulo = null
	pen_rodada = null
	pen_chutador = null
	pen_placar = null
	pen_contagem = null
	pen_feedback = null

	pen_card_panels.clear()
	pen_card_score_labels.clear()
	pen_card_status_labels.clear()
	pen_card_nome_labels.clear()
	pen_estado_cards.clear()
	pen_participantes.clear()



# ============================================================
# EFEITOS VISUAIS
# ============================================================
func _animar_score(index: int) -> void:
	if index < 0 or index >= score_labels.size():
		return

	var label = score_labels[index]
	var cor = cores_players[index]

	label.rect_scale = Vector2(1.55, 1.55)
	label.add_color_override("font_color", Color.white)
	label.add_color_override("font_color_shadow", cor)

	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(label, Compat.prop(label, "scale"), Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "modulate", Color(1.35, 1.35, 1.35, 1.0), 0.10)
	t.tween_property(label, "modulate", Color.white, 0.22).set_delay(0.10)


func _efeito_gol_card(index: int) -> void:
	if index < 0 or index >= player_panels.size():
		return

	var panel = player_panels[index]
	var cor = cores_players[index]

	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_WIDE)
	flash.color = Color(cor.r, cor.g, cor.b, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Compat.z(flash, 70)
	panel.add_child(flash)

	var escala_original = panel.rect_scale
	panel.rect_pivot_offset = panel.rect_size * 0.5

	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(panel, Compat.prop(panel, "scale"), escala_original * 1.07, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(panel, Compat.prop(panel, "scale"), escala_original, 0.26).set_delay(0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(flash, "color", Color(cor.r, cor.g, cor.b, 0.55), 0.07)
	t.tween_property(flash, "color", Color(cor.r, cor.g, cor.b, 0.0), 0.38).set_delay(0.07)

	yield(t, "finished")

	if is_instance_valid(flash):
		flash.queue_free()


func _mostrar_popup_ponto(index: int, valor: int) -> void:
	if index < 0 or index >= player_panels.size():
		return

	var panel = player_panels[index]
	var cor = cores_players[index]
	var W = panel.rect_size.x
	var H = panel.rect_size.y

	var popup := Label.new()
	popup.text = "GOOOL!"
	popup.rect_size = Vector2(W, 90)
	popup.rect_position = Vector2(0, H * 0.40)
	popup.align = Label.ALIGN_CENTER
	popup.valign = Label.VALIGN_CENTER
	Compat.z(popup, 95)
	popup.rect_pivot_offset = popup.rect_size * 0.5

	if fonte_orbitron:
		Compat.fonte(popup, fonte_orbitron)

	Compat.tamanho(popup, int(clamp(H * 0.16, 34.0, 76.0)))
	popup.add_color_override("font_color", Color.white)
	popup.add_color_override("font_color_shadow", cor)
	popup.add_constant_override("shadow_offset_x", 0)
	popup.add_constant_override("shadow_offset_y", 0)
	panel.add_child(popup)

	popup.rect_scale = Vector2(0.5, 0.5)

	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(popup, "rect_scale", Vector2(1.25, 1.25), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(popup, "rect_position:y", popup.rect_position.y - H * 0.22, 0.72).set_delay(0.12)
	t.tween_property(popup, "modulate", Color(1, 1, 1, 0), 0.42).set_delay(0.42)

	yield(t, "finished")

	if is_instance_valid(popup):
		popup.queue_free()


# ============================================================
# ÁUDIO
# ============================================================
func _criar_audios() -> void:
	audio_fundo = AudioStreamPlayer.new()
	audio_fundo.name = "MusicaPlay"
	add_child(audio_fundo)

	sfx_ponto = AudioStreamPlayer.new()
	sfx_ponto.name = "SfxPonto"
	add_child(sfx_ponto)

	sfx_fim_turno = AudioStreamPlayer.new()
	sfx_fim_turno.name = "SfxFimTurno"
	add_child(sfx_fim_turno)

	sfx_apito_init = AudioStreamPlayer.new()
	sfx_apito_init.name = "SfxApitoInit"
	add_child(sfx_apito_init)

	sfx_apito_troca = AudioStreamPlayer.new()
	sfx_apito_troca.name = "SfxApitoTroca"
	add_child(sfx_apito_troca)

	sfx_apito_fim = AudioStreamPlayer.new()
	sfx_apito_fim.name = "SfxApitoFim"
	add_child(sfx_apito_fim)

	sfx_final = AudioStreamPlayer.new()
	sfx_final.name = "SfxFinal"
	add_child(sfx_final)

	sfx_reativo = AudioStreamPlayer.new()
	sfx_reativo.name = "SfxReativo"
	add_child(sfx_reativo)
	sfx_reativo.connect("finished", self, "_on_sfx_reativo_finished")

	sfx_campeao = AudioStreamPlayer.new()
	sfx_campeao.name = "SfxCampeao"
	add_child(sfx_campeao)

	if ResourceLoader.exists(SFX_PONTO):
		sfx_ponto.stream = load(SFX_PONTO)
		sfx_ponto.volume_db = 0.0

	if ResourceLoader.exists(SFX_FIM_TURNO):
		sfx_fim_turno.stream = load(SFX_FIM_TURNO)
		sfx_fim_turno.volume_db = 0.0

	if ResourceLoader.exists(SFX_APITO_INIT):
		sfx_apito_init.stream = load(SFX_APITO_INIT)
		sfx_apito_init.volume_db = 1.5

	if ResourceLoader.exists(SFX_APITO_TROCA):
		sfx_apito_troca.stream = load(SFX_APITO_TROCA)
		sfx_apito_troca.volume_db = 1.5

	if ResourceLoader.exists(SFX_APITO_FIM):
		sfx_apito_fim.stream = load(SFX_APITO_FIM)
		sfx_apito_fim.volume_db = 1.5

	if ResourceLoader.exists(SFX_FINAL):
		sfx_final.stream = load(SFX_FINAL)
		sfx_final.volume_db = 0.0

	if ResourceLoader.exists(SFX_CAMPEAO):
		sfx_campeao.stream = load(SFX_CAMPEAO)
		sfx_campeao.volume_db = 1.5


func _sortear_musicas_players() -> void:
	musicas_por_player.clear()

	var disponiveis: Array = []

	for caminho in MUSICAS_PLAYERS:
		if ResourceLoader.exists(caminho):
			var s: AudioStream = load(caminho)

			if s is AudioStream:
				Compat.laco(s, true)

			disponiveis.append(s)

	disponiveis.shuffle()

	for i in range(total_players):
		if i < disponiveis.size():
			musicas_por_player.append(disponiveis[i])
		else:
			musicas_por_player.append(null)

	print("MÚSICAS DA COPA SORTEADAS: ", musicas_por_player.size())



func _tocar_musica_do_player(index: int) -> void:
	if audio_fundo == null:
		return

	if index < 0 or index >= musicas_por_player.size():
		return

	var stream: AudioStream = musicas_por_player[index]

	if stream == null:
		if ResourceLoader.exists(MUSICA_PLAY):
			stream = load(MUSICA_PLAY)

			if stream is AudioStream:
				Compat.laco(stream, true)
		else:
			return

	audio_fundo.stop()
	audio_fundo.stream = stream
	audio_fundo.volume_db = volume_musica_normal
	audio_fundo.play()

func _tocar_audio(player: AudioStreamPlayer) -> void:
	if player and player.stream:
		player.stop()
		player.play()


# ============================================================
# ARDUINO / POWERSHELL
# ============================================================
func _abrir_serial_arduino() -> void:
	# TV Box: o Arduino Nano é do autoload Arduino (USB); não há ponte.
	if not USAR_ARDUINO:
		return
	_serial_write("OFF")


func _matar_pontes_powershell_antigas() -> void:
	pass  # TV Box: sem PowerShell.


func _iniciar_ponte_powershell() -> void:
	pass  # TV Box: sem PowerShell; o autoload Arduino cuida da USB.


func _serial_write(texto: String) -> void:
	if not USAR_ARDUINO:
		return
	Arduino.enviar(texto)


func _enviar_leds_para_arduino() -> void:
	if not USAR_ARDUINO:
		return

	if leds_ativos.empty():
		_serial_write("OFF")
		return

	var partes: Array = []

	for index_led in leds_ativos:
		if index_led < 0 or index_led >= LEDS_LETRAS.size():
			continue

		var letra = LEDS_LETRAS[index_led]
		var rgb = _rgb_led_por_index(index_led)

		var r = int(clamp(rgb[0], 0, 255))
		var g = int(clamp(rgb[1], 0, 255))
		var b = int(clamp(rgb[2], 0, 255))

		partes.append("%s=%d,%d,%d" % [letra, r, g, b])

	if partes.empty():
		_serial_write("OFF")
		return

	var comando = "SET:" + PoolStringArray(partes).join(";")
	_serial_write(comando)


# ============================================================
# FECHAMENTO
# ============================================================
func _fechar_jogo_arcade() -> void:
	if fechando_jogo:
		return

	fechando_jogo = true

	print("FECHANDO CUP PLAY SOMENTE COM CTRL + TAB...")

	_serial_write("OFF")
	_parar_sons_reativos()
	_parar_campeao()

	if audio_fundo:
		audio_fundo.stop()

	if USAR_PONTE_POWERSHELL and caminho_fila_arduino != "":
		var nome_arquivo = "%020d_EXIT.cmd" % Time.get_ticks_msec()
		var caminho_final = caminho_fila_arduino.plus_file(nome_arquivo)

		var f = Compat.abrir_arquivo(caminho_final, File.WRITE)

		if f:
			f.store_string("__EXIT__")
			f.close()

	yield(get_tree().create_timer(0.12), "timeout")

	get_tree().quit()


func _exit_tree() -> void:
	_serial_write("OFF")

	if USAR_PONTE_POWERSHELL and caminho_fila_arduino != "":
		var nome_arquivo = "%020d_EXIT.cmd" % Time.get_ticks_msec()
		var caminho_final = caminho_fila_arduino.plus_file(nome_arquivo)

		var f = Compat.abrir_arquivo(caminho_final, File.WRITE)

		if f:
			f.store_string("__EXIT__")
			f.close()
	
	_parar_sons_reativos()
	_parar_campeao()

	if audio_fundo:
		audio_fundo.stop()


func _notification(what: int) -> void:
	if what in [MainLoop.NOTIFICATION_WM_QUIT_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST]:
		return


# ============================================================
# HELPERS VISUAIS
# ============================================================
func _travar_modo_arcade() -> void:
	VisualServer.set_default_clear_color(Color(0.004, 0.007, 0.014, 1.0))
	pass  # (Android: a janela ja e a tela cheia)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().auto_accept_quit = false



func _carregar_fontes() -> void:
	if ResourceLoader.exists(FONTE_ORBITRON):
		fonte_orbitron = load(FONTE_ORBITRON)


func _novo_label(txt: String, tam: int, cor: Color, sombra: Color = Color.transparent) -> Label:
	var l := Label.new()
	l.text = txt
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.align = Label.ALIGN_CENTER
	l.valign = Label.VALIGN_CENTER

	if fonte_orbitron:
		Compat.fonte(l, fonte_orbitron)

	Compat.tamanho(l, tam)
	l.add_color_override("font_color", cor)

	if sombra.a > 0.0:
		l.add_color_override("font_color_shadow", sombra)
		l.add_constant_override("shadow_offset_x", 0)
		l.add_constant_override("shadow_offset_y", 0)

	return l


func _novo_label_card(texto: String, largura: float, centro_y: float, fonte_size: int, cor: Color) -> Label:
	var lbl := Label.new()
	lbl.text = texto

	var altura = float(fonte_size) + 14.0

	lbl.rect_position = Vector2(0, centro_y - altura * 0.5)
	lbl.rect_size = Vector2(largura, altura)
	lbl.align = Label.ALIGN_CENTER
	lbl.valign = Label.VALIGN_CENTER
	Compat.tamanho(lbl, fonte_size)
	lbl.add_color_override("font_color", cor)
	lbl.add_constant_override("shadow_offset_x", 0)
	lbl.add_constant_override("shadow_offset_y", 0)

	if fonte_orbitron:
		Compat.fonte(lbl, fonte_orbitron)

	return lbl


func _escolher_som_aleatorio(lista: Array, chave: String) -> String:
	var disponiveis: Array = []

	for caminho in lista:
		if ResourceLoader.exists(caminho):
			disponiveis.append(caminho)

	if disponiveis.empty():
		return ""

	var ultimo_global: String = ""
	if not _historico_sons_global.empty():
		ultimo_global = str(_historico_sons_global.back())

	var ultimo_chave: String = str(_ultimo_som_por_lista.get(chave, ""))

	var candidatos: Array = []

	# Prioridade 1:
	# Não pode estar no histórico recente, não pode ser o último global,
	# e não pode ser o último desta lista.
	for caminho in disponiveis:
		if caminho == ultimo_global:
			continue
		if caminho == ultimo_chave:
			continue
		if _historico_sons_global.has(caminho):
			continue

		candidatos.append(caminho)

	# Prioridade 2:
	# Pode estar no histórico, mas não pode repetir o último global.
	if candidatos.empty():
		for caminho in disponiveis:
			if caminho == ultimo_global:
				continue
			if caminho == ultimo_chave:
				continue

			candidatos.append(caminho)

	# Prioridade 3:
	# Pelo menos não repete imediatamente.
	if candidatos.empty():
		for caminho in disponiveis:
			if caminho != ultimo_global:
				candidatos.append(caminho)

	# Se só existe exatamente o mesmo som disponível, não toca agora.
	# Isso garante: nunca toca a mesma música seguida.
	if candidatos.empty():
		return ""

	var escolhido: String = candidatos[randi() % candidatos.size()]

	_ultimo_som_por_lista[chave] = escolhido
	_registrar_som_global(escolhido)

	return escolhido




func _registrar_som_global(caminho: String) -> void:
	_historico_sons_global.append(caminho)

	while _historico_sons_global.size() > HISTORICO_SONS_MAX:
		_historico_sons_global.pop_front()


func _tocar_som_da_lista(lista: Array, chave: String, volume_db: float = 0.0, forcar: bool = false) -> void:
	if sfx_reativo == null:
		return

	if _reativo_bloqueado_por_campeao:
		return

	if sfx_campeao and sfx_campeao.playing:
		return

	if sfx_reativo.playing and not forcar:
		return

	var caminho = _escolher_som_aleatorio(lista, chave)

	if caminho == "":
		return

	var stream = load(caminho) as AudioStream

	if stream == null:
		return

	if stream is AudioStream:
		Compat.laco(stream, false)

	if forcar and sfx_reativo.playing:
		sfx_reativo.stop()

	_duck_musica(true, 0.16)

	sfx_reativo.stream = stream
	sfx_reativo.volume_db = volume_db
	sfx_reativo.play()



func _on_sfx_reativo_finished() -> void:
	_acertos_torcida = 0

	if _campeao_pendente:
		_tocar_campeao_agora()
		return

	if not _reativo_bloqueado_por_campeao:
		_duck_musica(false, 0.30)



func _tocar_som_fim_turno_reativo(player_index: int) -> void:
	if player_index < 0 or player_index >= scores.size():
		return

	if _player_eh_bot(player_index):
		return

	var meu_score: int = scores[player_index]
	var melhor_anterior: int = _melhor_score_ja_jogado(player_index)
	var ja_teve_anterior: bool = melhor_anterior >= 0

	# REGRA 1:
	# Fez menos de 10 gols: vaia no fim da vez.
	# Isso vale inclusive para o primeiro jogador.
	if meu_score < PONTOS_MINIMOS_SEM_VAIA:
		_tocar_vaia_fim("fim_menos_de_10_%s" % fase_copa)
		return

	# REGRA 2:
	# Primeiro jogador da rodada/fase.
	# Como ninguém jogou antes, ele nunca está abaixo de alguém.
	# Se fez 10 ou mais, recebe som positivo.
	if not ja_teve_anterior:
		_tocar_som_da_lista(
			SONS_TURNO_BOM,
			"fim_primeiro_bom_%s" % fase_copa,
			1.1,
			true
		)
		return

	# REGRA 3:
	# Terminou abaixo de alguém que já jogou: vaia.
	if meu_score < melhor_anterior:
		_tocar_vaia_fim("fim_abaixo_de_alguem_%s" % fase_copa)
		return

	# REGRA 4:
	# Terminou empatado com o primeiro: não vaia.
	if meu_score == melhor_anterior:
		_tocar_som_da_lista(
			SONS_TURNO_BOM,
			"fim_empate_primeiro_%s" % fase_copa,
			1.1,
			true
		)
		return

	# REGRA 5:
	# Terminou passando todo mundo: som de superação.
	if meu_score > melhor_anterior:
		_tocar_som_da_lista(
			SONS_SUPEROU_TURNO,
			"fim_superou_%s" % fase_copa,
			1.4,
			true
		)
		return



func _avaliar_motivacao() -> void:
	if not partida_ativa:
		return

	if sfx_reativo == null or sfx_reativo.playing:
		return

	if player_atual < 0 or player_atual >= total_players:
		return

	if _player_eh_bot(player_atual):
		return

	# Se está atrás de alguém que já jogou, não toca motivacional bom.
	if _esta_abaixo_de_alguem_ja_jogado(player_atual):
		return

	var agora = float(Time.get_ticks_msec())

	if agora - _ultimo_motivacional_ms < MOTIVACIONAL_INTERVALO_MS:
		return

	var tempo_base: float = _tempo_do_player(player_atual)
	var decorrido: float = tempo_base - tempos[player_atual]

	if decorrido < 5.0:
		return

	var ritmo: float = float(scores[player_atual]) / max(decorrido, 1.0)

	if ritmo >= MOTIVACIONAL_RITMO_BOM:
		_ultimo_motivacional_ms = agora
		_tocar_som_da_lista(SONS_TURNO_BOM, "motivacao_boa_%s" % fase_copa, 1.0)


func _verificar_vitoria_antecipada() -> void:
	if _vitoria_antecipada_tocada:
		return

	if total_players < 2:
		return

	if player_atual < 0 or player_atual >= total_players:
		return

	for j in range(total_players):
		if j == player_atual:
			continue
		if not terminou_player[j]:
			return

	for j in range(total_players):
		if j == player_atual:
			continue
		if scores[player_atual] <= scores[j]:
			return

	_vitoria_antecipada_tocada = true

	# Som de campeão SOMENTE na grande final (não semifinal, não 3º lugar).
	if fase_copa == "FINAL" and not disputa_terceiro_copa:
		_tocar_vitoria_antecipada_final()
	else:
		_tocar_vitoria_antecipada_normal()



func _tocar_vitoria_antecipada_normal() -> void:
	_reativo_bloqueado_por_campeao = false
	_campeao_pendente = false

	if sfx_campeao and sfx_campeao.playing:
		sfx_campeao.stop()

	_tocar_som_da_lista(SONS_TURNO_BOM, "passou_todos_normal", 1.3, true)


func _tocar_vitoria_antecipada_final() -> void:
	if sfx_reativo and sfx_reativo.playing:
		_campeao_pendente = true
		_reativo_bloqueado_por_campeao = true
		return

	_tocar_campeao_agora()



func _duck_musica(baixo: bool = true, tempo: float = 0.22) -> void:
	if audio_fundo == null:
		return

	if tween_volume_musica != null and tween_volume_musica.is_running():
		tween_volume_musica.kill()

	var alvo: float = volume_musica_duck if baixo else volume_musica_normal

	tween_volume_musica = create_tween()
	tween_volume_musica.tween_property(audio_fundo, "volume_db", alvo, tempo)


func _tocar_audio_com_duck(player: AudioStreamPlayer, tempo_duck: float = 1.2) -> void:
	if player == null:
		return

	if player.stream == null:
		return

	_duck_musica(true, 0.16)

	player.stop()
	player.play()

	yield(get_tree().create_timer(tempo_duck), "timeout")

	if not sfx_reativo.playing and not sfx_campeao.playing:
		_duck_musica(false, 0.30)


func _tocar_campeao_agora() -> void:
	if sfx_campeao == null:
		return

	if sfx_campeao.stream == null:
		return

	_reativo_bloqueado_por_campeao = true
	_campeao_pendente = false

	if sfx_reativo and sfx_reativo.playing:
		sfx_reativo.stop()

	if sfx_campeao.stream is AudioStream:
		Compat.laco(sfx_campeao.stream, false)

	_duck_musica(true, 0.12)

	sfx_campeao.stop()
	sfx_campeao.play()



func _parar_sons_reativos() -> void:
	if sfx_reativo and sfx_reativo.playing:
		sfx_reativo.stop()

	if sfx_campeao and sfx_campeao.playing:
		sfx_campeao.stop()


func _parar_campeao() -> void:
	if sfx_campeao and sfx_campeao.playing:
		sfx_campeao.stop()

	if sfx_campeao and sfx_campeao.stream and sfx_campeao.stream is AudioStream:
		Compat.laco(sfx_campeao.stream, false)

	_reativo_bloqueado_por_campeao = false
	_campeao_pendente = false
	_duck_musica(false, 0.20)



func _player_eh_bot(index: int) -> bool:
	if index < 0 or index >= jogadores_copa.size():
		return false

	var j: Dictionary = jogadores_copa[index]

	return bool(j.get("boot", false))


func _tempo_do_player(index: int) -> float:
	if _player_eh_bot(index):
		return _tempo_bot_por_fase()

	return TEMPO_PLAYER_REAL


func _tempo_bot_por_fase() -> float:
	# Bots evoluem conforme a Copa avança.
	match fase_copa:
		"OITAVAS":
			return 9.0
		"SEMIFINAL":
			return 12.0
		"FINAL":
			return 18.0
		_:
			return TEMPO_PLAYER_BOT  # GRUPOS = 6s



func _sortear_proximo_gol_bot() -> void:
	bot_timer_gol = 0.0
	bot_proximo_gol_em = rand_range(BOT_INTERVALO_GOL_MIN, BOT_INTERVALO_GOL_MAX)



func _pontuacao_alvo_bot() -> int:
	# Mais tempo = mais gols nas fases avançadas.
	match fase_copa:
		"OITAVAS":
			return Compat.randi_range(4, 9)
		"SEMIFINAL":
			return Compat.randi_range(6, 13)
		"FINAL":
			return Compat.randi_range(9, 18)
		_:
			return Compat.randi_range(2, 6)  # GRUPOS



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
	bot_proximo_gol_em = rand_range(BOT_INTERVALO_GOL_MIN, BOT_INTERVALO_GOL_MAX)

	if scores[player_atual] >= _pontuacao_alvo_bot():
		return

	if leds_ativos.empty():
		return

	var index_led: int = int(leds_ativos[randi() % leds_ativos.size()])
	_processar_input_led(index_led)


func _criar_fundo_imagem_loading(alvo: Control) -> void:
	if alvo == null:
		return

	var fundo_base := ColorRect.new()
	fundo_base.set_anchors_preset(Control.PRESET_WIDE)
	fundo_base.color = Color(0.004, 0.007, 0.014, 1.0)
	fundo_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alvo.add_child(fundo_base)

	if ResourceLoader.exists(IMAGEM_LOADING_COPA):
		var img := TextureRect.new()
		img.set_anchors_preset(Control.PRESET_WIDE)
		img.texture = load(IMAGEM_LOADING_COPA)
		img.expand = true

		# Imagem completa, sem zoom e sem corte.
		# Pode sobrar barra escura se a proporção da imagem for diferente da tela.
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		alvo.add_child(img)
	else:
		push_warning("Imagem de loading não encontrada: " + IMAGEM_LOADING_COPA)

	var escurecer := ColorRect.new()
	escurecer.set_anchors_preset(Control.PRESET_WIDE)
	escurecer.color = Color(0, 0, 0, 0.42)
	escurecer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alvo.add_child(escurecer)

	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_WIDE)
	glow.color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 0.075)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alvo.add_child(glow)


func _listar_imagens_patrocinadores() -> Array:
	var imagens: Array = []

	for caminho in PATROCINADORES_FIXOS:
		if ResourceLoader.exists(caminho):
			if not imagens.has(caminho):
				imagens.append(caminho)
		else:
			push_warning("Patrocinador da lista fixa não encontrado: " + caminho)

	print("PATROCINADORES CUP PLAY (lista fixa): ", imagens.size(), " de ", PATROCINADORES_FIXOS.size())
	return imagens


func _adicionar_rodape_patrocinadores_loading(alvo: Control) -> void:
	if alvo == null:
		return

	var imagens: Array = _listar_imagens_patrocinadores()
	if imagens.empty():
		return

	var tela = get_viewport().get_visible_rect().size
	var total: int = imagens.size()

	var max_por_linha: int = 8
	if total <= 4:
		max_por_linha = total
	elif total <= 6:
		max_por_linha = 6
	else:
		max_por_linha = 8
	max_por_linha = int(max(max_por_linha, 1))

	var linhas: int = int(ceil(float(total) / float(max_por_linha)))
	linhas = int(max(linhas, 1))

	var margem_x: float = 54.0
	var gap: float = 18.0
	var row_gap: float = 12.0
	var card_h: float = 96.0
	if linhas == 2:
		card_h = 78.0
	elif linhas >= 3:
		card_h = 64.0

	var footer_h: float = float(linhas) * card_h + float(int(max(linhas - 1, 0))) * row_gap + 34.0
	var footer_h_max: float = tela.y * 0.34
	if footer_h > footer_h_max:
		var fator: float = footer_h_max / footer_h
		card_h *= fator
		row_gap *= fator
		footer_h = footer_h_max

	var footer_y: float = tela.y - footer_h - 14.0

	var fundo := Panel.new()
	fundo.rect_position = Vector2(32.0, footer_y)
	fundo.rect_size = Vector2(tela.x - 64.0, footer_h)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.rect_clip_content = true

	var fundo_style := StyleBoxFlat.new()
	fundo_style.bg_color = Color(0.004, 0.012, 0.020, 0.86)
	fundo_style.border_color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 0.42)
	fundo_style.set_border_width_all(2)
	fundo_style.set_corner_radius_all(0)
	fundo_style.shadow_color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 0.36)
	fundo_style.shadow_size = 24
	fundo_style.shadow_offset = Vector2.ZERO
	fundo.add_stylebox_override("panel", fundo_style)
	alvo.add_child(fundo)

	if ResourceLoader.exists(IMAGEM_FUNDO_FOOTER_PATRO):
		var foto := TextureRect.new()
		foto.set_anchors_preset(Control.PRESET_WIDE)
		foto.texture = load(IMAGEM_FUNDO_FOOTER_PATRO)
		foto.expand = true
		foto.stretch_mode = TextureRect.STRETCH_SCALE
		foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		foto.modulate = Color(1, 1, 1, 0.55)
		fundo.add_child(foto)

		var escuro_foto := ColorRect.new()
		escuro_foto.set_anchors_preset(Control.PRESET_WIDE)
		escuro_foto.color = Color(0, 0, 0, 0.42)
		escuro_foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fundo.add_child(escuro_foto)
	else:
		var verde := ColorRect.new()
		verde.set_anchors_preset(Control.PRESET_WIDE)
		verde.color = Color(0.00, 0.26, 0.10, 0.72)
		verde.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fundo.add_child(verde)

		var amarelo := ColorRect.new()
		amarelo.rect_position = Vector2(fundo.rect_size.x * 0.50, 0)
		amarelo.rect_size = Vector2(fundo.rect_size.x * 0.50, fundo.rect_size.y)
		amarelo.color = Color(1.0, 0.82, 0.06, 0.22)
		amarelo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fundo.add_child(amarelo)

	var brilho := ColorRect.new()
	brilho.rect_position = Vector2(24, 10)
	brilho.rect_size = Vector2(fundo.rect_size.x - 48, 3)
	brilho.color = Color(1, 1, 1, 0.14)
	brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_child(brilho)

	for linha in range(linhas):
		var inicio: int = linha * max_por_linha
		var fim: int = int(min(inicio + max_por_linha, total))
		var qtd: int = fim - inicio
		if qtd <= 0:
			continue

		var area_w: float = fundo.rect_size.x - margem_x * 2.0
		var card_w: float = (area_w - gap * float(qtd - 1)) / float(qtd)

		if total <= 4:
			card_w = clamp(card_w, 180.0, 310.0)
		elif total <= 8:
			card_w = clamp(card_w, 135.0, 230.0)
		else:
			card_w = clamp(card_w, 105.0, 190.0)

		var total_w: float = card_w * float(qtd) + gap * float(qtd - 1)
		var x0: float = (fundo.rect_size.x - total_w) * 0.5
		var y0: float = 17.0 + float(linha) * (card_h + row_gap)

		for i in range(qtd):
			var caminho: String = imagens[inicio + i]
			var card = _criar_card_patrocinador_footer_loading(caminho, Vector2(card_w, card_h))
			card.rect_position = Vector2(x0 + float(i) * (card_w + gap), y0)
			card.modulate = Color(1, 1, 1, 0)
			card.rect_scale = Vector2(0.94, 0.94)
			fundo.add_child(card)

			var delay: float = float(inicio + i) * 0.025
			var t = create_tween()
			t.set_parallel(true)
			t.tween_property(card, "modulate", Color.white, 0.22).set_delay(delay)
			t.tween_property(card, Compat.prop(card, "scale"), Vector2.ONE, 0.22).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _fundo_logo_loading(caminho: String) -> Color:
	var base: String = caminho.get_file().to_lower()

	# bar.png -> fundo PRETO
	if base == "bar.png" or base.begins_with("bar."):
		return Color(0.0, 0.0, 0.0, 1.0)

	# corona_logo.png -> fundo BRANCO
	if Compat.contem(base, "corona"):
		return Color(1.0, 1.0, 1.0, 1.0)

	# Michelob-Ultra -> fundo BRANCO
	if Compat.contem(base, "michelob"):
		return Color(1.0, 1.0, 1.0, 1.0)

	# GA_Logo.png / Guaraná -> verde da marca
	if base.begins_with("ga_") or Compat.contem(base, "guaran"):
		return Color(0.0, 0.60, 0.28, 1.0)

	# Stella -> dourado/amarelo
	if Compat.contem(base, "stella"):
		return Color(0.79, 0.65, 0.18, 1.0)

	# Budweiser -> vermelho
	if base == "bud.png" or base.begins_with("bud"):
		return Color(0.86, 0.10, 0.13, 1.0)

	# Sem fundo especial: usa o tema verde/amarelo.
	return Color(0.0, 0.0, 0.0, 0.0)


func _criar_card_patrocinador_footer_loading(caminho: String, tamanho: Vector2) -> Panel:
	var card := Panel.new()
	card.rect_size = tamanho
	card.rect_min_size = tamanho
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.rect_clip_content = true

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
	card.add_stylebox_override("panel", st)

	var margem := 7.0
	var inner := Panel.new()
	inner.rect_position = Vector2(margem, margem)
	inner.rect_size = tamanho - Vector2(margem * 2.0, margem * 2.0)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.rect_clip_content = true
	card.add_child(inner)

	var inner_st := StyleBoxFlat.new()
	inner_st.set_border_width_all(2)
	inner_st.set_corner_radius_all(12)
	if tem_especial:
		inner_st.bg_color = fundo_especial
		inner_st.border_color = Color(0, 0, 0, 0.22) if claro else Color(1, 1, 1, 0.20)
	else:
		inner_st.bg_color = Color(0.98, 0.86, 0.12, 1.0)
		inner_st.border_color = Color(0.0, 0.42, 0.12, 0.95)
	inner.add_stylebox_override("panel", inner_st)

	if not tem_especial:
		var faixa_verde := ColorRect.new()
		faixa_verde.rect_position = Vector2.ZERO
		faixa_verde.rect_size = Vector2(inner.rect_size.x * 0.50, inner.rect_size.y)
		faixa_verde.color = Color(0.02, 0.42, 0.14, 1.0)
		faixa_verde.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(faixa_verde)

		var faixa_amarela := ColorRect.new()
		faixa_amarela.rect_position = Vector2(inner.rect_size.x * 0.50, 0)
		faixa_amarela.rect_size = Vector2(inner.rect_size.x * 0.50, inner.rect_size.y)
		faixa_amarela.color = Color(1.0, 0.86, 0.10, 1.0)
		faixa_amarela.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(faixa_amarela)

	var brilho := ColorRect.new()
	brilho.rect_position = Vector2(10, 7)
	brilho.rect_size = Vector2(inner.rect_size.x - 20, 2)
	brilho.color = Color(1, 1, 1, 0.08 if claro else 0.18)
	brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(brilho)

	var tex = load(caminho) as Texture
	if tex != null:
		var pad := 8.0
		if tem_especial:
			pad = 12.0
		var img := TextureRect.new()
		img.rect_position = Vector2(pad, pad * 0.72)
		img.rect_size = inner.rect_size - Vector2(pad * 2.0, pad * 1.44)
		img.texture = tex
		img.expand = true
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(img)
	else:
		var erro := Label.new()
		erro.text = "LOGO"
		erro.set_anchors_preset(Control.PRESET_WIDE)
		erro.align = Label.ALIGN_CENTER
		erro.valign = Label.VALIGN_CENTER
		Compat.tamanho(erro, 14)
		erro.add_color_override("font_color", Color.red)
		inner.add_child(erro)

	return card



func _adicionar_imagem_fundo_rodape_loading(fundo: Panel) -> void:
	if fundo == null:
		return

	if not ResourceLoader.exists(IMAGEM_RODAPE_LOADING):
		push_warning("Imagem de fundo do rodapé não encontrada: " + IMAGEM_RODAPE_LOADING)
		return

	var img := TextureRect.new()
	img.set_anchors_preset(Control.PRESET_WIDE)
	img.texture = load(IMAGEM_RODAPE_LOADING)
	img.expand = true

	# Estica para cobrir todo o rodapé.
	img.stretch_mode = TextureRect.STRETCH_SCALE

	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_child(img)

	var escurecer := ColorRect.new()
	escurecer.set_anchors_preset(Control.PRESET_WIDE)
	escurecer.color = Color(0, 0, 0, 0.36)
	escurecer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_child(escurecer)

	var brilho := ColorRect.new()
	brilho.set_anchors_preset(Control.PRESET_WIDE)
	brilho.color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 0.065)
	brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_child(brilho)



func _style_card_patrocinador_loading() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 1, 1, 0.115)
	s.border_color = Color(1, 1, 1, 0.24)
	s.set_border_width_all(1)
	s.set_corner_radius_all(14)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 10
	s.shadow_offset = Vector2.ZERO
	return s


func _adicionar_fundo_imagem_card_player(panel: Panel, index: int, cor: Color) -> void:
	if panel == null:
		return

	var caminho: String = _caminho_fundo_card_player(index)

	if caminho == "":
		return

	if not ResourceLoader.exists(caminho):
		push_warning("Imagem de fundo do card não encontrada: " + caminho)
		return

	var inset: float = 5.0
	var raio: float = 0.0

	var tam_img: Vector2 = panel.rect_size - Vector2(inset * 2.0, inset * 2.0)

	if tam_img.x <= 0.0 or tam_img.y <= 0.0:
		return

	# Imagem de fundo arredondada.
	var img := TextureRect.new()
	img.rect_position = Vector2(inset, inset)
	img.rect_size = tam_img
	img.texture = load(caminho)
	img.expand = true
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	img.material = _material_fundo_card_arredondado(tam_img, raio)
	panel.add_child(img)

	# Camada de cor do jogador por cima da imagem.
	var tint := Panel.new()
	tint.rect_position = Vector2(inset, inset)
	tint.rect_size = tam_img
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tint_style := StyleBoxFlat.new()
	tint_style.bg_color = Color(cor.r, cor.g, cor.b, 0.10)
	tint_style.border_color = Color(cor.r, cor.g, cor.b, 0.14)
	tint_style.set_border_width_all(1)
	tint_style.set_corner_radius_all(int(raio))
	tint.add_stylebox_override("panel", tint_style)

	panel.add_child(tint)

	# Camada escura para manter nome, tempo e placar legíveis.
	var escuro := Panel.new()
	escuro.rect_position = Vector2(inset, inset)
	escuro.rect_size = tam_img
	escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var escuro_style := StyleBoxFlat.new()
	escuro_style.bg_color = Color(0, 0, 0, 0.43)
	escuro_style.border_color = Color(1, 1, 1, 0.05)
	escuro_style.set_border_width_all(1)
	escuro_style.set_corner_radius_all(int(raio))
	escuro.add_stylebox_override("panel", escuro_style)

	panel.add_child(escuro)


func _caminho_fundo_card_player(index: int) -> String:
	# Primeiro tenta identificar pela cor salva no jogador.
	if index >= 0 and index < jogadores_copa.size():
		var j: Dictionary = jogadores_copa[index]

		var nome_cor: String = str(j.get("cor_nome", "")).strip_edges().to_upper()

		if Compat.contem(nome_cor, "AZUL"):
			return FUNDO_CARD_AZUL

		if Compat.contem(nome_cor, "VERDE"):
			return FUNDO_CARD_VERDE

		if Compat.contem(nome_cor, "VERMELHO"):
			return FUNDO_CARD_VERMELHO

		if Compat.contem(nome_cor, "AMARELO"):
			return FUNDO_CARD_AMARELO

		var cor_index: int = int(j.get("cor_index", -1))

		match cor_index:
			0:
				return FUNDO_CARD_VERMELHO
			1:
				return FUNDO_CARD_VERDE
			2:
				return FUNDO_CARD_AZUL
			3:
				return FUNDO_CARD_AMARELO

	# Fallback: identifica pela cor visual do player.
	if index >= 0 and index < cores_players.size():
		var c: Color = cores_players[index]

		# Amarelo
		if c.r >= 0.70 and c.g >= 0.55 and c.b <= 0.35:
			return FUNDO_CARD_AMARELO

		# Vermelho
		if c.r >= c.g and c.r >= c.b:
			return FUNDO_CARD_VERMELHO

		# Verde
		if c.g >= c.r and c.g >= c.b:
			return FUNDO_CARD_VERDE

		# Azul
		if c.b >= c.r and c.b >= c.g:
			return FUNDO_CARD_AZUL

	return ""


func _material_fundo_card_arredondado(tam: Vector2, raio_px: float) -> ShaderMaterial:
	var shader := Shader.new()

	shader.code = """
shader_type canvas_item;

uniform vec2 rect_size = vec2(100.0, 100.0);
uniform float radius_px = 24.0;

void fragment() {
	vec2 p = UV * rect_size - rect_size * 0.5;
	vec2 b = rect_size * 0.5 - vec2(radius_px);
	vec2 q = abs(p) - b;

	float dist = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius_px;
	float alpha = 1.0 - smoothstep(0.0, 2.0, dist);

	vec4 tex = texture(TEXTURE, UV);
	vec4 modulate_color = COLOR;

	COLOR = tex * modulate_color;
	COLOR.a *= alpha;
}
"""

	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_param("rect_size", tam)
	mat.set_shader_param("radius_px", raio_px)

	return mat



func _fase_permite_prorrogacao_penaltis() -> bool:
	# Prorrogação e pênaltis somente em:
	# - SEMIFINAL
	# - GRANDE FINAL
	# - DECISÃO DO 3º LUGAR
	#
	# A decisão do 3º lugar vem como fase FINAL com disputa_terceiro = true.
	if fase_copa == "SEMIFINAL":
		return true

	if fase_copa == "FINAL":
		return true

	return false


func _texto_regra_desempate_partida() -> String:
	if fase_copa == "OITAVAS":
		return "TOP 8: PASSAM 2  •  EMPATE POR CRITÉRIO"

	if _fase_permite_prorrogacao_penaltis():
		if disputa_terceiro_copa:
			return "3º LUGAR: EMPATE TEM PRORROGAÇÃO + PÊNALTIS"

		if fase_copa == "SEMIFINAL":
			return "SEMIFINAL: EMPATE TEM PRORROGAÇÃO + PÊNALTIS"

		return "FINAL: EMPATE TEM PRORROGAÇÃO + PÊNALTIS"

	if fase_copa == "GRUPOS":
		return "1º=3PTS  •  2º=2PTS  •  3º=1PT  •  4º=0"

	return "EMPATE RESOLVIDO POR CRITÉRIO"



func _cobrir_tela_para_transicao() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 9999
	add_child(cl)

	var cover := ColorRect.new()
	cover.set_anchors_preset(Control.PRESET_WIDE)
	cover.color = Color(0.004, 0.007, 0.014, 1.0)   # mesma cor base do loading, nunca cinza
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(cover)



func _adicionar_fundo_stadio() -> void:
	if root == null:
		return

	if not ResourceLoader.exists(IMAGEM_FUNDO_STADIO):
		push_warning("Imagem de fundo do estádio não encontrada: " + IMAGEM_FUNDO_STADIO)
		return

	var tela = get_viewport().get_visible_rect().size
	var header_h: float = 82.0  # mesma altura do cabeçalho criado em _criar_header_copa()

	# Imagem do estádio: começa logo abaixo do cabeçalho e cobre o resto da tela.
	var img := TextureRect.new()
	img.rect_position = Vector2(0.0, header_h)
	img.rect_size = Vector2(tela.x, tela.y - header_h)
	img.texture = load(IMAGEM_FUNDO_STADIO)
	img.expand = true
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(img)

	# Camada escura sutil para manter os cards/textos legíveis por cima do estádio.
	var escuro := ColorRect.new()
	escuro.rect_position = Vector2(0.0, header_h)
	escuro.rect_size = Vector2(tela.x, tela.y - header_h)
	escuro.color = Color(0, 0, 0, 0.35)
	escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(escuro)


func _ordem_1(a, b) -> bool:
	var na: int = int(a.get("gols_normais", 0))
	var nb: int = int(b.get("gols_normais", 0))
	if na != nb:
		return na > nb

	var pa: int = int(a.get("gols_prorrogacao", 0))
	var pb: int = int(b.get("gols_prorrogacao", 0))
	if pa != pb:
		return pa > pb

	var ka: int = int(a.get("penaltis", 0))
	var kb: int = int(b.get("penaltis", 0))
	if ka != kb:
		return ka > kb

	var bot_a: bool = bool(a.get("boot", false))
	var bot_b: bool = bool(b.get("boot", false))
	if bot_a != bot_b:
		return bot_b

	return int(a.get("player_index", 0)) < int(b.get("player_index", 0))


func _g3_fazer_header(panel, header_y, txt: String, x: float, w: float, alin: int) -> void:
	var h := Label.new()
	h.text = txt
	h.rect_position = Vector2(x, header_y)
	h.rect_size = Vector2(w, 22)
	h.align = alin
	h.valign = Label.VALIGN_CENTER
	Compat.tamanho(h, 13)
	h.add_color_override("font_color", Color(0.62, 0.70, 0.80))
	h.add_color_override("font_outline_modulate", Color(0, 0, 0, 0.80))
	Compat.contorno(h, 2)
	if fonte_orbitron:
		Compat.fonte(h, fonte_orbitron)
	panel.add_child(h)
