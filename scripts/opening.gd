extends Node2D

const CENA_TORNEIO: String = "res://scenes/cup_setup_36.tscn"
const COR_TORNEIO: Color = Color(0.95, 0.00, 1.00) # roxo/magenta bem forte
const COR_NEON: Color = Color(0.10, 0.75, 1.00)


const META_PULAR_PATROCINADORES_OPENING: String = "pular_patrocinadores_opening_uma_vez"

# ===== COMBO MURAL (segurar START + CUP juntos) =====
const COMBO_MURAL_SEGUNDOS: float = 2.4   # tempo segurando os dois para abrir o Mural
const COMBO_GRACE_MS: int = 130           # janela p/ tratar START e CUP como "juntos"

# ===== HOLD RANKING (segurar somente CUP / SELECT) =====
const RANKING_HOLD_SEGUNDOS: float = 1.65
const RANKING_HOLD_MOSTRAR_MODAL_SEGUNDOS: float = 0.72

const CENA_MURAL_CAMPEOES: String = "res://scenes/champions_wall.tscn"


const IMAGEM_FUNDO_MODAL_VERDE: String = "res://images/back_stadio.png"

const IMAGEM_FUNDO_MODAL_OPENING: String = "res://fundos/back.png"

const CENA_JOGO: String = "res://scenes/play.tscn"
const CENA_LOBBY: String = "res://scenes/lobby.tscn"
const IMAGEM_CAPA: String = "res://images/fut_cap.jpeg"
const VIDEO_CAPA: String = "res://medias/init.ogv"
const MUSICA_FUNDO: String = "res://songs/song_fut.ogg"


const CENA_RANKING: String = "res://scenes/champions_ranking.tscn"

const CENA_CONFIG: String = "res://scenes/config.tscn"

const SFX_SELECT_PLAYER: String = "res://songs/player_select.wav"
const SFX_GAME_START: String = "res://songs/game_start.wav"

const FONTE_ORBITRON: String = "res://fonts/orbitron-bold.ttf"
const FONTE_BUNGREE: String = "res://fonts/bungree.ttf"

const LOADING_OPENING_PASTA_PATROCINADORES: String = "res://patro/"
const LOADING_OPENING_EXTENSOES_PATRO: Array = ["png", "jpg", "jpeg", "webp"]

const LOADING_PATRO_ALTURA_MIN: float = 130.0
const LOADING_PATRO_ALTURA_MAX: float = 190.0
const LOADING_PATRO_CARD_W_MIN: float = 115.0
const LOADING_PATRO_CARD_W_MAX: float = 190.0
const LOADING_PATRO_CARD_H_MIN: float = 54.0
const LOADING_PATRO_CARD_H_MAX: float = 82.0
const LOADING_PATRO_GAP: float = 12.0
const LOADING_PATRO_TEMPO_PAGINA: float = 1.45

const LOADING_OUTDOOR_TEMPO_ENTRE_LOGOS: float = 0.92
const LOADING_OUTDOOR_CARD_W_MIN: float = 360.0
const LOADING_OUTDOOR_CARD_W_MAX: float = 780.0
const LOADING_OUTDOOR_CARD_H_MIN: float = 118.0
const LOADING_OUTDOOR_CARD_H_MAX: float = 190.0
const LOADING_MODAL_W_RATIO: float = 0.88
const LOADING_MODAL_H_RATIO: float = 0.70

const LOADING_OPENING_TIMEOUT_SERIAL: float = 2.2

const LOADING_PATRO_ENTRADA_TEMPO: float = 0.38
const LOADING_PATRO_PARADO_TEMPO: float = 0.95
const LOADING_PATRO_SAIDA_TEMPO: float = 0.38
const LOADING_PATRO_TEMPO_GRADE_FINAL: float = 6.00

const LOADING_BARRA_COMPACTA_W: float = 420.0
const LOADING_BARRA_COMPACTA_H: float = 8.0

const PATRO_REPLAY_INTERVALO: float = 40.0
const PATRO_REPLAY_TEMPO_GRADE_FINAL: float = 4.0

var patro_replay_timer: Timer = null
var patro_replay_layer: CanvasLayer = null
var patro_replay_root: Control = null
var patro_replay_panel: Panel = null
var patro_replay_stage: Control = null
var patro_replay_ativo: bool = false

var opening_patro_stage: Control = null
var opening_patro_index: int = 0

var opening_patro_panel: Panel = null
var opening_patro_grid: GridContainer = null
var opening_patro_info: Label = null
var opening_patro_timer: Timer = null

var opening_patro_imagens: Array = []
var opening_patro_pagina: int = 0
var opening_patro_por_pagina: int = 1
var opening_patro_cols: int = 1
var opening_patro_rows: int = 1
var opening_patro_card_size: Vector2 = Vector2(150, 70)


# Estado do combo do Mural.
var combo_mural_hold: float = 0.0
var combo_mural_ativo: bool = false
var combo_indo_mural: bool = false
var combo_start_pressed_ms: int = -100000
var combo_cup_pressed_ms: int = -100000

# Adiamento curto das ações soltas (pra detectar o combo sem confirmar modo/girar carrossel).
var confirmar_pendente: bool = false
var confirmar_pendente_ms: int = 0
var avancar_pendente: bool = false
var avancar_pendente_ms: int = 0

# Nós do modal do combo.
var combo_layer: CanvasLayer = null
var combo_fundo: ColorRect = null
var combo_modal: Panel = null
var combo_barra: ColorRect = null
var combo_barra_max_w: float = 0.0

# Estado do hold do Ranking.
var ranking_hold: float = 0.0
var ranking_hold_ativo: bool = false
var ranking_indo: bool = false

var ranking_hold_medindo: bool = false
var ranking_hold_visual_aberto: bool = false

var ranking_layer: CanvasLayer = null
var ranking_fundo: ColorRect = null
var ranking_modal: Panel = null
var ranking_barra: ColorRect = null
var ranking_barra_max_w: float = 0.0

var _alterna_som_modo: int = 0

var modos_jogo: Array = []
var modo_focado: int = 0
var carrossel_root: Control = null
var arcade_status_label: Label = null

const TEMPO_ESCOLHA: float = 12.0
const TEMPO_TELA_INICIANDO: float = 1.8
const MAX_PLAYERS: int = 4
const COOLDOWN_START_MS: int = 320


# ===== MODO COPA =====
const COPA_TEMPO_CONFIRMACAO: float = 9.0   # tempo até o modal fechar sozinho
const COPA_MIN_JOGADORES: int = 8
const COPA_MAX_JOGADORES: int = 16
const COR_COPA: Color = Color(1.0, 0.78, 0.12)   # dourado do modo Copa

const IMAGEM_LOADING_OPENING: String = "res://images/loading.png"


var opening_loading_layer: CanvasLayer = null
var opening_loading_root: Control = null
var opening_loading_label: Label = null
var opening_loading_sub: Label = null
var opening_loading_pct: Label = null
var opening_loading_barra: ColorRect = null
var opening_loading_barra_max_w: float = 0.0
var opening_loading_frac: float = 0.0
var opening_loading_tween: SceneTreeTween = null


const PATROCINADORES_FIXOS: Array = [
	"res://patro/logoofi.png",
	"res://patro/bar.png",
	"res://patro/bud.png",
	"res://patro/corona_logo.png",
	"res://patro/GA_Logo.png",
	"res://patro/Michelob-Ultra_stacked-color-Logo.png",
	"res://patro/stella.png",
]

# Ciclo de fundo (vídeo <-> foto)
const TEMPO_FOTO: float = 9.0   # quanto tempo a foto fica antes do vídeo voltar
const FADE_FUNDO: float = 0.65  # duração do crossfade suave entre vídeo e foto

const USAR_ARDUINO: bool = true
const SEGURAR_CREDITO_CONFIG_MS := 5000
var _credito_apertado_ms := -1
const USAR_PONTE_POWERSHELL: bool = true
const SERIAL_PORTA: String = "COM5"
const SERIAL_BAUD: int = 9600

const LEDS_LETRAS: Array = ["A", "B", "C", "D", "E", "F", "G"]
const LEDS_TOTAL: int = 7

# Fluxo inicial do atrativo:
# A → B → C → D → E → F → G → F → E → D → C → B → A
# H fica apagado nesse efeito porque você pediu até o G.
const LED_FLUXO_ORDEM_AG: Array = [0, 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1, 0]
const LED_FLUXO_INTERVALO: float = 0.60

const LED_ATRATIVO_REINICIO_DELAY: float = 0.10
const LED_ATRATIVO_REINICIO_DELAY_COPA: float = 0.15

const SFX_GOOD_PLAYER_PATRO: String = "res://songs/good_player.ogg"

var caminho_fila_arduino: String = ""
var caminho_log_arduino: String = ""
var caminho_script_arduino: String = ""
var ponte_ps_pid: int = -1

var _led_atrativo_timer: float = 0.0
var _led_atrativo_intervalo: float = 0.55
var _led_atrativo_etapa: int = 0
var _arduino_opening_pronto: bool = false

var bloquear_start_ate_ms: int = 0
var bloquear_cup_ate_ms: int = 0

var canvas: CanvasLayer
var root: Control
var fundo_base_solida: ColorRect
var fundo_imagem: TextureRect
var fundo_video: VideoPlayer

var audio_fundo: AudioStreamPlayer
var sfx_player_select: AudioStreamPlayer
var sfx_game_start: AudioStreamPlayer
var sfx_good_player_patro: AudioStreamPlayer

var fonte_orbitron: Font
var fonte_bungree: Font

# Botões da tela inicial (ARCADE e COPA)
var btn_arcade_panel: Panel
var btn_arcade_base: Panel
var btn_arcade_label: Label
var btn_copa_panel: Panel
var btn_copa_base: Panel
var btn_copa_label: Label
var glow_tween_arcade: SceneTreeTween
var glow_tween_copa: SceneTreeTween

var fechando_jogo: bool = false

var fundo_container: Control
var _fundo_em_transicao: bool = false

var modal_layer: CanvasLayer
var modal_fundo: ColorRect
var modal: Panel
var barra: ProgressBar
var contador_label: Label
var player_cards: Array = []
var player_labels: Array = []

# Modal do modo Copa
var copa_layer: CanvasLayer
var copa_fundo: ColorRect
var copa_modal: Panel
var copa_barra: ProgressBar
var copa_aviso_tempo: Label
var copa_modal_aberto: bool = false
var copa_fechando: bool = false
var copa_tempo_restante: float = 0.0

var iniciando_layer: CanvasLayer
var iniciando_panel: Panel
var iniciando_label: Label
var iniciando_sub_label: Label

var escolhendo_players: bool = false
var iniciando_jogo: bool = false
var tempo_restante: float = TEMPO_ESCOLHA
var ultimo_segundo_exibido: int = -1
var total_players: int = 0

var cores_players: Array = [
	Color(0.1, 0.75, 1.0),
	Color(0.2, 1.0, 0.3),
	Color(1.0, 0.15, 0.15),
	Color(1.0, 0.85, 0.05)
]



func _ready() -> void:
	var _g3_estado = null
	get_tree().auto_accept_quit = false
	_travar_modo_arcade()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	randomize()

	var retorno_direto: bool = bool(get_tree().get_meta(META_PULAR_PATROCINADORES_OPENING, false))

	if retorno_direto:
		get_tree().set_meta(META_PULAR_PATROCINADORES_OPENING, false)

	VisualServer.set_default_clear_color(Color(0.004, 0.007, 0.014, 1.0))

	_carregar_fontes()

	# =========================================================
	# RETORNO DO MURAL / RANKING
	# Não mostra loading.
	# Não mostra "VAI COMEÇAR".
	# Não mostra patrocinadores.
	# Vai direto para o layout principal.
	# =========================================================
	if retorno_direto:
		_g3_estado = _ready_retorno_direto_sem_loading()
		if _g3_estado is GDScriptFunctionState:
			_g3_estado = yield(_g3_estado, "completed")
		return

	# =========================================================
	# ABERTURA NORMAL DO JOGO
	# Aqui continua mostrando loading + patrocinadores.
	# =========================================================
	_criar_loading_opening("GOL FLASH ARENA", "ENTRANDO EM CAMPO...")
	_set_loading_opening(0.10, "ENTRANDO EM CAMPO...", 0.12)

	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")

	_garantir_acao_cup()

	_set_loading_opening(0.28, "ARRUMANDO O GRAMADO...", 0.15)
	_criar_tela()

	yield(get_tree(), "idle_frame")
	yield(get_tree().create_timer(0.08), "timeout")

	_set_loading_opening(0.45, "AQUECENDO A TORCIDA...", 0.15)
	_criar_audios()
	_tocar_musica()

	yield(get_tree().create_timer(0.06), "timeout")

	_set_loading_opening(0.62, "MONTANDO OS MODOS DE JOGO...", 0.14)

	yield(get_tree(), "idle_frame")

	_set_loading_opening(0.80, "ILUMINANDO A ARENA...", 0.25)

	_g3_estado = _abrir_serial_arduino_opening()
	if _g3_estado is GDScriptFunctionState:
		_g3_estado = yield(_g3_estado, "completed")

	_set_loading_opening(0.92, "QUASE LÁ...", 0.16)

	_arduino_opening_pronto = true
	_leds_atrativo_abertura_forte()

	yield(get_tree().create_timer(0.16), "timeout")

	_set_loading_opening(1.0, "TUDO PRONTO PARA JOGAR!", 0.16)

	yield(get_tree().create_timer(0.08), "timeout")

	_g3_estado = _remover_loading_opening()
	if _g3_estado is GDScriptFunctionState:
		_g3_estado = yield(_g3_estado, "completed")



func _ready_retorno_direto_sem_loading() -> void:
	var _g3_estado = null
	# Cria o menu principal imediatamente, sem janela de loading.
	_garantir_acao_cup()
	_criar_tela()

	yield(get_tree(), "idle_frame")

	_criar_audios()
	_tocar_musica()

	# Bloqueia START/SELECT por um instante para não confirmar modo sem querer
	# caso o botão ainda esteja sendo solto ao voltar do Mural ou Ranking.
	var agora_ms: int = Time.get_ticks_msec()
	bloquear_start_ate_ms = agora_ms + 650
	bloquear_cup_ate_ms = agora_ms + 650

	yield(get_tree(), "idle_frame")

	# Abre a ponte do Arduino depois que o layout já apareceu.
	# Assim não aparece a janela "VAI COMEÇAR".
	_g3_estado = _abrir_serial_arduino_opening()
	if _g3_estado is GDScriptFunctionState:
		_g3_estado = yield(_g3_estado, "completed")

	_arduino_opening_pronto = true
	_leds_atrativo_abertura_forte()

	print("================================")
	print("OPENING: RETORNO DIRETO DO MURAL/RANKING")
	print("SEM LOADING, SEM VAI COMEÇAR, SEM PATROCINADORES INICIAIS")
	print("================================")



func _garantir_acao_cup() -> void:
	# Se a ação input_cup não existir ainda, cria com a tecla C como fallback
	# para o jogo nunca quebrar. O ideal é mapear o botão SELECT do Zero Delay
	# em Project Settings > Input Map > input_cup (igual você fez no input_start).
	if InputMap.has_action("input_cup"):
		return

	InputMap.add_action("input_cup")

	var ev := InputEventKey.new()
	ev.scancode = KEY_C
	InputMap.action_add_event("input_cup", ev)

	print("================================")
	print("AVISO: ação 'input_cup' não existia.")
	print("Criada automaticamente com a tecla C como fallback.")
	print("Mapeie o botão SELECT do Zero Delay em:")
	print("Project Settings > Input Map > input_cup")
	print("================================")



func _travar_modo_arcade() -> void:
	pass  # (Android: a janela ja e a tela cheia)

	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	# Evita que o jogo aceite pedido automático de fechar.
	get_tree().auto_accept_quit = false


func _process(delta: float) -> void:
	if fundo_video != null:
		_enquadrar_video_cover()

	# Menu travado: durante loading/boot, patrocinadores, iniciando modo, ou indo pro Mural.
	var menu_bloqueado: bool = patro_replay_ativo or (opening_loading_layer != null) or iniciando_jogo or combo_indo_mural or ranking_indo

	# Leitura de input deste frame.
	var cup_acao: bool = InputMap.has_action("input_cup")
	var start_just: bool = Input.is_action_just_pressed("input_start")
	var cup_just: bool = cup_acao and Input.is_action_just_pressed("input_cup")
	var start_segurando: bool = Input.is_action_pressed("input_start")
	var cup_segurando: bool = cup_acao and Input.is_action_pressed("input_cup")
	var agora_ms: int = Time.get_ticks_msec()

	# L3 é a entrada física do moedeiro/crédito.
	# TV Box: toque curto (pulso do moedeiro) = +1 crédito ao soltar;
	# SEGURAR 5 s = abre a Configuração (a máquina não tem teclado/F9).
	if InputMap.has_action("input_credit"):
		if Input.is_action_just_pressed("input_credit"):
			_credito_apertado_ms = agora_ms
		elif _credito_apertado_ms >= 0 and Input.is_action_pressed("input_credit"):
			if agora_ms - _credito_apertado_ms >= SEGURAR_CREDITO_CONFIG_MS:
				_credito_apertado_ms = -1
				_abrir_tela_configuracoes()
				return
		elif _credito_apertado_ms >= 0:
			if agora_ms - _credito_apertado_ms < 1500:
				ArcadeData.adicionar_credito()
				_atualizar_status_arcade("CRÉDITO ADICIONADO")
			_credito_apertado_ms = -1

	if start_just:
		combo_start_pressed_ms = agora_ms
	if cup_just:
		combo_cup_pressed_ms = agora_ms

	# LEDs atrativos só quando NENHUM modal/combo está ativo.
	if _arduino_opening_pronto \
	and not escolhendo_players \
	and not iniciando_jogo \
	and not copa_modal_aberto \
	and not patro_replay_ativo \
	and not combo_mural_ativo \
	and not combo_indo_mural \
	and not ranking_hold_visual_aberto \
	and not ranking_indo:
		_led_atrativo_timer -= delta

		if _led_atrativo_timer <= 0.0:
			_led_atrativo_timer = _led_atrativo_intervalo
			_leds_atrativo_profissional()

	# Combo do Mural: segurar START + CUP juntos.
	_atualizar_combo_mural(delta)
	_atualizar_hold_ranking(delta)

	# Contagem regressiva do modal de Copa (fecha sozinho se não houver ação).
	if copa_modal_aberto and not copa_fechando and not iniciando_jogo:
		copa_tempo_restante -= delta

		if copa_tempo_restante < 0.0:
			copa_tempo_restante = 0.0

		if copa_barra:
			copa_barra.value = copa_tempo_restante

		if copa_aviso_tempo:
			copa_aviso_tempo.text = "Esta janela fecha sozinha em %ds" % int(ceil(copa_tempo_restante))

		if copa_tempo_restante <= 0.0:
			_fechar_modal_copa()

	if escolhendo_players and not iniciando_jogo:
		tempo_restante -= delta

		if tempo_restante < 0.0:
			tempo_restante = 0.0

		if barra:
			barra.value = tempo_restante

		_atualizar_contador_inteiro()

		if tempo_restante <= 0.0:
			_preparar_inicio_partida()

	# ===== START =====
	if start_just and agora_ms >= bloquear_start_ate_ms and not menu_bloqueado and not combo_mural_ativo:
		if escolhendo_players:
			# Na seleção de players, START adiciona player na hora.
			_adicionar_player()
			bloquear_start_ate_ms = Time.get_ticks_msec() + COOLDOWN_START_MS
		else:
			# No menu: pode ser começo de combo. Só confirma se o CUP não estiver junto.
			var cup_junto: bool = cup_segurando or (agora_ms - combo_cup_pressed_ms) <= COMBO_GRACE_MS
			if not cup_junto:
				confirmar_pendente = true
				confirmar_pendente_ms = agora_ms

	# ===== CUP (input_cup) =====
	if cup_just and agora_ms >= bloquear_cup_ate_ms and not menu_bloqueado and not escolhendo_players and not combo_mural_ativo:
		var start_junto: bool = start_segurando or (agora_ms - combo_start_pressed_ms) <= COMBO_GRACE_MS
		if not start_junto:
			avancar_pendente = true
			avancar_pendente_ms = agora_ms

	# ===== Resolve as ações adiadas =====
	# Se virou combo / menu travou / entrou na seleção, cancela as pendências.
	if combo_mural_ativo or ranking_hold_ativo or ranking_hold_visual_aberto or menu_bloqueado or escolhendo_players:
		confirmar_pendente = false
		avancar_pendente = false

	if confirmar_pendente:
		if cup_segurando:
			confirmar_pendente = false            # virou combo, não confirma
		elif agora_ms - confirmar_pendente_ms >= COMBO_GRACE_MS:
			confirmar_pendente = false
			_confirmar_modo_focado()
			bloquear_start_ate_ms = Time.get_ticks_msec() + COOLDOWN_START_MS

	if avancar_pendente:
		if start_segurando:
			avancar_pendente = false              # virou combo do mural
		elif ranking_indo:
			avancar_pendente = false
		elif cup_segurando:
			pass                                  # está segurando SELECT; pode virar Ranking
		elif agora_ms - avancar_pendente_ms >= COMBO_GRACE_MS:
			avancar_pendente = false
			_avancar_carrossel()
			bloquear_cup_ate_ms = Time.get_ticks_msec() + COOLDOWN_START_MS



func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:

			# F9 abre a tela de configurações (não aparece no menu público).
			if event.scancode == KEY_F9:
				var viewport = get_viewport()
				if viewport:
					viewport.set_input_as_handled()

				_abrir_tela_configuracoes()
				return

			# ÚNICO ATALHO QUE FECHA O JOGO:
			# CTRL + TAB
			if event.control and event.scancode == KEY_TAB:
				var viewport = get_viewport()
				if viewport:
					viewport.set_input_as_handled()

				_fechar_jogo_arcade()
				return

			# Tenta bloquear tecla Windows / Command / Meta
			if event.scancode == KEY_META:
				var viewport = get_viewport()
				if viewport:
					viewport.set_input_as_handled()
				return

			# Bloqueia ESC
			if event.scancode == KEY_ESCAPE:
				var viewport = get_viewport()
				if viewport:
					viewport.set_input_as_handled()
				return

			# Bloqueia ALT + F4
			if event.alt and event.scancode == KEY_F4:
				var viewport = get_viewport()
				if viewport:
					viewport.set_input_as_handled()
				return

			# Bloqueia ALT + TAB, se chegar na Godot
			if event.alt and event.scancode == KEY_TAB:
				var viewport = get_viewport()
				if viewport:
					viewport.set_input_as_handled()
				return

			# Bloqueia CTRL + ESC
			if event.control and event.scancode == KEY_ESCAPE:
				var viewport = get_viewport()
				if viewport:
					viewport.set_input_as_handled()
				return


func _abrir_tela_configuracoes() -> void:
	if iniciando_jogo:
		return

	if escolhendo_players:
		return

	if copa_modal_aberto:
		return

	print("ABRINDO TELA DE CONFIGURAÇÕES...")

	_serial_write_opening("OFF")

	if audio_fundo:
		audio_fundo.stop()

	get_tree().change_scene(CENA_CONFIG)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:

			var viewport = get_viewport()

			if event.scancode == KEY_META:
				if viewport:
					viewport.set_input_as_handled()
				return

			if event.scancode == KEY_ESCAPE:
				if viewport:
					viewport.set_input_as_handled()
				return

			if event.alt and event.scancode == KEY_F4:
				if viewport:
					viewport.set_input_as_handled()
				return

			if event.alt and event.scancode == KEY_TAB:
				if viewport:
					viewport.set_input_as_handled()
				return

			if event.control and event.scancode == KEY_ESCAPE:
				if viewport:
					viewport.set_input_as_handled()
				return



func _fechar_jogo_arcade() -> void:
	if fechando_jogo:
		return

	fechando_jogo = true

	print("FECHANDO JOGO SOMENTE COM CTRL + TAB...")

	_serial_write_opening("OFF")
	_parar_good_player_patrocinadores()

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


func _carregar_fontes() -> void:
	if ResourceLoader.exists(FONTE_ORBITRON):
		fonte_orbitron = load(FONTE_ORBITRON)

	if ResourceLoader.exists(FONTE_BUNGREE):
		fonte_bungree = load(FONTE_BUNGREE)


func _criar_tela() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)

	root = Control.new()
	root.set_anchors_preset(Control.PRESET_WIDE)
	# Mouse totalmente ignorado: a tela inicial é só botões físicos.
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	_criar_fundo()

	var vinheta := ColorRect.new()
	vinheta.set_anchors_preset(Control.PRESET_WIDE)
	vinheta.color = Color(0, 0, 0, 0.22)
	vinheta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vinheta)

	_criar_botoes()
	_criar_painel_mural_ranking()
	_criar_status_arcade()
	# Botão de mouse do Mural REMOVIDO de propósito.
	# O Mural agora abre segurando START + CUP juntos (combo).



func _atualizar_combo_mural(delta: float) -> void:
	# O combo só vale no menu de modos: sem modais, sem loading, sem patrocinadores.
	var pode_combo: bool = InputMap.has_action("input_cup") \
		and not escolhendo_players \
		and not iniciando_jogo \
		and not copa_modal_aberto \
		and not patro_replay_ativo \
		and opening_loading_layer == null \
		and not combo_indo_mural

	var ambos: bool = pode_combo \
		and Input.is_action_pressed("input_start") \
		and Input.is_action_pressed("input_cup")

	if ambos:
		if not combo_mural_ativo:
			combo_mural_ativo = true
			combo_mural_hold = 0.0
			_abrir_modal_combo_mural()
			# Feedback dourado nos LEDs enquanto segura.
			_set_leds_todos_rgb(_rgb_copa_forte())

		combo_mural_hold += delta
		_atualizar_barra_combo_mural()

		if combo_mural_hold >= COMBO_MURAL_SEGUNDOS:
			_ir_para_mural_campeoes()
	else:
		if combo_mural_ativo:
			combo_mural_ativo = false
			combo_mural_hold = 0.0
			_fechar_modal_combo_mural()
			_reiniciar_led_atrativo()


func _abrir_modal_combo_mural() -> void:
	if combo_layer != null and is_instance_valid(combo_layer):
		return

	var cor: Color = Color(1.00, 0.78, 0.18)

	combo_layer = CanvasLayer.new()
	combo_layer.layer = 940
	add_child(combo_layer)

	combo_fundo = ColorRect.new()
	combo_fundo.set_anchors_preset(Control.PRESET_WIDE)
	combo_fundo.color = Color(0, 0, 0, 0.0)
	combo_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_layer.add_child(combo_fundo)

	var tela: Vector2 = get_viewport_rect().size

	combo_modal = Panel.new()
	combo_modal.rect_size = Vector2(760, 360)
	combo_modal.rect_position = Vector2(
		(tela.x - combo_modal.rect_size.x) * 0.5,
		(tela.y - combo_modal.rect_size.y) * 0.5
	)
	combo_modal.rect_pivot_offset = combo_modal.rect_size * 0.5
	combo_modal.rect_scale = Vector2(0.92, 0.92)
	combo_modal.modulate = Color(1, 1, 1, 0)
	combo_modal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_layer.add_child(combo_modal)

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.010, 0.012, 0.018, 0.98)
	st.border_color = cor
	st.set_border_width_all(4)
	st.set_corner_radius_all(30)
	st.shadow_color = Color(cor.r, cor.g, cor.b, 0.85)
	st.shadow_size = 50
	st.shadow_offset = Vector2.ZERO
	combo_modal.add_stylebox_override("panel", st)

	# Faixa decorativa no topo.
	var faixa := ColorRect.new()
	faixa.rect_position = Vector2(40, 28)
	faixa.rect_size = Vector2(combo_modal.rect_size.x - 80, 5)
	faixa.color = Color(cor.r, cor.g, cor.b, 0.95)
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_modal.add_child(faixa)

	# Tag com troféu.
	var tag := Label.new()
	tag.text = "🏆 MURAL DE CAMPEÕES"
	tag.rect_position = Vector2(0, 52)
	tag.rect_size = Vector2(combo_modal.rect_size.x, 42)
	tag.align = Label.ALIGN_CENTER
	tag.valign = Label.VALIGN_CENTER
	if fonte_orbitron:
		Compat.fonte(tag, fonte_orbitron)
	Compat.tamanho(tag, 30)
	tag.add_color_override("font_color", Color.white)
	tag.add_color_override("font_color_shadow", cor)
	tag.add_constant_override("shadow_offset_x", 0)
	tag.add_constant_override("shadow_offset_y", 0)
	combo_modal.add_child(tag)

	# Instrução grande.
	var titulo := Label.new()
	titulo.text = "CONTINUE SEGURANDO"
	titulo.rect_position = Vector2(0, 116)
	titulo.rect_size = Vector2(combo_modal.rect_size.x, 64)
	titulo.align = Label.ALIGN_CENTER
	titulo.valign = Label.VALIGN_CENTER
	if fonte_orbitron:
		Compat.fonte(titulo, fonte_orbitron)
	Compat.tamanho(titulo, 44)
	titulo.add_color_override("font_color", Color.white)
	titulo.add_color_override("font_color_shadow", cor)
	titulo.add_constant_override("shadow_offset_x", 0)
	titulo.add_constant_override("shadow_offset_y", 0)
	combo_modal.add_child(titulo)

	# Subinstrução.
	var sub := Label.new()
	sub.text = "MANTENHA  START + SELECT  PRESSIONADOS"
	sub.rect_position = Vector2(0, 184)
	sub.rect_size = Vector2(combo_modal.rect_size.x, 32)
	sub.align = Label.ALIGN_CENTER
	sub.valign = Label.VALIGN_CENTER
	if fonte_orbitron:
		Compat.fonte(sub, fonte_orbitron)
	Compat.tamanho(sub, 19)
	sub.add_color_override("font_color", Color(cor.r, cor.g, cor.b, 0.95))
	combo_modal.add_child(sub)

	# Barra de progresso do hold.
	var barra_bg := ColorRect.new()
	barra_bg.rect_position = Vector2(90, 244)
	barra_bg.rect_size = Vector2(combo_modal.rect_size.x - 180, 16)
	barra_bg.color = Color(1, 1, 1, 0.12)
	barra_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_modal.add_child(barra_bg)

	combo_barra_max_w = barra_bg.rect_size.x

	combo_barra = ColorRect.new()
	combo_barra.rect_position = barra_bg.rect_position
	combo_barra.rect_size = Vector2(0, 16)
	combo_barra.color = cor
	combo_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_modal.add_child(combo_barra)

	# Rodapé: soltar cancela.
	var rodape := Label.new()
	rodape.text = "SOLTE PARA CANCELAR"
	rodape.rect_position = Vector2(0, 286)
	rodape.rect_size = Vector2(combo_modal.rect_size.x, 28)
	rodape.align = Label.ALIGN_CENTER
	rodape.valign = Label.VALIGN_CENTER
	if fonte_orbitron:
		Compat.fonte(rodape, fonte_orbitron)
	Compat.tamanho(rodape, 15)
	rodape.add_color_override("font_color", Color(0.70, 0.74, 0.80))
	combo_modal.add_child(rodape)

	# Entrada animada.
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(combo_fundo, "color", Color(0, 0, 0, 0.80), 0.18)
	t.tween_property(combo_modal, "modulate", Color.white, 0.18)
	t.tween_property(combo_modal, "rect_scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _atualizar_barra_combo_mural() -> void:
	if combo_barra == null or not is_instance_valid(combo_barra):
		return

	var frac: float = clamp(combo_mural_hold / COMBO_MURAL_SEGUNDOS, 0.0, 1.0)
	combo_barra.rect_size.x = combo_barra_max_w * frac


func _fechar_modal_combo_mural() -> void:
	# Guarda referências locais e zera as globais já,
	# pra um novo combo poder abrir outro modal sem conflito.
	var layer_ref: CanvasLayer = combo_layer
	var modal_ref: Panel = combo_modal
	var fundo_ref: ColorRect = combo_fundo

	combo_layer = null
	combo_modal = null
	combo_fundo = null
	combo_barra = null
	combo_barra_max_w = 0.0

	if layer_ref == null or not is_instance_valid(layer_ref):
		return

	var t = create_tween()
	t.set_parallel(true)

	if modal_ref and is_instance_valid(modal_ref):
		t.tween_property(modal_ref, "rect_scale", Vector2(0.92, 0.92), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		t.tween_property(modal_ref, "modulate", Color(1, 1, 1, 0), 0.14)

	if fundo_ref and is_instance_valid(fundo_ref):
		t.tween_property(fundo_ref, "color", Color(0, 0, 0, 0.0), 0.14)

	yield(t, "finished")

	if is_instance_valid(layer_ref):
		layer_ref.queue_free()


func _ir_para_mural_campeoes() -> void:
	if combo_indo_mural:
		return

	if not ResourceLoader.exists(CENA_MURAL_CAMPEOES):
		push_error("Cena do Mural de Campeões não encontrada: " + CENA_MURAL_CAMPEOES)
		combo_mural_ativo = false
		combo_mural_hold = 0.0
		_fechar_modal_combo_mural()
		return

	combo_indo_mural = true
	combo_mural_ativo = false

	if sfx_game_start and sfx_game_start.stream:
		sfx_game_start.stop()
		sfx_game_start.play()

	_set_leds_todos_rgb(_rgb_copa_forte())

	# Flash rápido de confirmação no modal antes de trocar de cena.
	if combo_modal and is_instance_valid(combo_modal):
		var t = combo_modal.create_tween()
		t.tween_property(combo_modal, "rect_scale", Vector2(1.05, 1.05), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	yield(get_tree().create_timer(0.22), "timeout")

	_serial_write_opening("OFF")

	if audio_fundo:
		audio_fundo.stop()

	_marcar_retorno_sem_patrocinadores()
	get_tree().change_scene(CENA_MURAL_CAMPEOES)


func _criar_fundo() -> void:
	# Container que recorta o excesso (igual ao "cover" do vídeo)
	fundo_container = Control.new()
	fundo_container.set_anchors_preset(Control.PRESET_WIDE)
	fundo_container.rect_clip_content = true
	fundo_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fundo_container)

	# BASE SÓLIDA: cor escura que preenche tudo desde o primeiro frame.
	# Garante que NUNCA aparece o cinza do clear color, mesmo que a imagem
	# ou o vídeo ainda estejam carregando.
	fundo_base_solida = ColorRect.new()
	fundo_base_solida.set_anchors_preset(Control.PRESET_WIDE)
	fundo_base_solida.color = Color(0.02, 0.03, 0.04, 1.0)
	fundo_base_solida.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo_container.add_child(fundo_base_solida)

	# Imagem como camada base permanente, preenchendo a TELA INTEIRA.
	# STRETCH_SCALE = preenche todo o retângulo (a tela) sem aquele zoom/corte
	# que o modo COVERED causava. Sem barras pretas, sem ampliação.
	fundo_imagem = TextureRect.new()
	fundo_imagem.set_anchors_preset(Control.PRESET_WIDE)
	fundo_imagem.expand = true
	fundo_imagem.stretch_mode = TextureRect.STRETCH_SCALE
	fundo_imagem.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if ResourceLoader.exists(IMAGEM_CAPA):
		fundo_imagem.texture = load(IMAGEM_CAPA)
	else:
		push_error("Imagem não encontrada: " + IMAGEM_CAPA)

	fundo_container.add_child(fundo_imagem)
	fundo_imagem.visible = true
	fundo_imagem.modulate = Color(1, 1, 1, 1)

	# Vídeo por cima, em modo cover (sem esticar). Fica vivo o tempo todo
	# para poder VOLTAR em loop com fade suave.
	if VIDEO_CAPA != "" and ResourceLoader.exists(VIDEO_CAPA):
		fundo_video = VideoPlayer.new()
		fundo_video.set_anchors_preset(Control.PRESET_TOP_LEFT)  # tamanho/posição manuais
		fundo_video.expand = true
		fundo_video.stream = load(VIDEO_CAPA)
		fundo_video.autoplay = false
		fundo_video.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# REMOVE O ÁUDIO DO VÍDEO (mantém só o som do jogo)
		fundo_video.volume_db = -80.0
		fundo_video.volume = 0.0

		fundo_video.modulate = Color(1, 1, 1, 1)

		fundo_container.add_child(fundo_video)

		if not fundo_video.is_connected("finished", self, "_on_video_capa_terminou"):
			fundo_video.connect("finished", self, "_on_video_capa_terminou")

		fundo_video.play()
	else:
		# Sem vídeo, a imagem já é o fundo (e já está visível).
		if VIDEO_CAPA != "":
			push_warning("Vídeo não encontrado: " + VIDEO_CAPA)



func _on_video_capa_terminou() -> void:
	# Vídeo acabou -> some suave revelando a foto.
	_fundo_video_para_foto()



func _fundo_video_para_foto() -> void:
	if _fundo_em_transicao:
		return
	if fundo_video == null:
		return

	_fundo_em_transicao = true

	# A foto já está visível por baixo em opacidade total.
	if fundo_imagem:
		fundo_imagem.visible = true
		fundo_imagem.modulate = Color(1, 1, 1, 1)

	# Vídeo some suave (crossfade), revelando a foto que já está atrás.
	var t = create_tween()
	t.tween_property(fundo_video, "modulate:a", 0.0, FADE_FUNDO) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	yield(t, "finished")

	_fundo_em_transicao = false

	# Mostra a foto por um tempo e depois traz o vídeo de volta.
	yield(get_tree().create_timer(TEMPO_FOTO), "timeout")

	# Se o jogo já começou nesse meio tempo, não reinicia o ciclo.
	if iniciando_jogo:
		return

	_fundo_foto_para_video()



func _fundo_foto_para_video() -> void:
	if _fundo_em_transicao:
		return
	if fundo_video == null:
		return

	_fundo_em_transicao = true

	# Reinicia o vídeo do começo, ainda invisível (alpha 0) para não dar flash.
	fundo_video.modulate = Color(1, 1, 1, 0)
	fundo_video.stop()
	fundo_video.play()

	# Vídeo volta suave por cima da foto.
	var t = create_tween()
	t.tween_property(fundo_video, "modulate:a", 1.0, FADE_FUNDO) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	yield(t, "finished")

	_fundo_em_transicao = false
	# Quando o vídeo terminar de novo, o "finished" recomeça o ciclo sozinho.


# =========================================================
# BOTÕES DA TELA INICIAL: ARCADE + COPA
# =========================================================
func _criar_botoes() -> void:
	_definir_modos()
	modo_focado = 0

	if carrossel_root != null and is_instance_valid(carrossel_root):
		carrossel_root.queue_free()

	carrossel_root = Control.new()
	carrossel_root.set_anchors_preset(Control.PRESET_WIDE)
	carrossel_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(carrossel_root)

	_montar_carrossel(false)



func _construir_botao(titulo: String, subtitulo: String, pos: Vector2, tamanho: Vector2, cor_neon: Color) -> Dictionary:
	var panel := Panel.new()
	panel.rect_size = tamanho
	panel.rect_position = pos
	root.add_child(panel)

	var style_glow := StyleBoxFlat.new()
	style_glow.bg_color = Color(0.0, 0.0, 0.0, 0.34)
	style_glow.border_color = cor_neon
	style_glow.set_border_width_all(4)
	style_glow.set_corner_radius_all(34)
	style_glow.shadow_color = Color(cor_neon.r, cor_neon.g, cor_neon.b, 0.95)
	style_glow.shadow_size = 26
	style_glow.shadow_offset = Vector2.ZERO
	panel.add_stylebox_override("panel", style_glow)

	var base := Panel.new()
	base.rect_position = Vector2(8, 8)
	base.rect_size = tamanho - Vector2(16, 16)
	panel.add_child(base)

	var style_base := StyleBoxFlat.new()
	style_base.bg_color = Color(0.012, 0.018, 0.018, 0.97)
	style_base.border_color = Color(0.85, 1.0, 0.92, 0.45)
	style_base.set_border_width_all(2)
	style_base.set_corner_radius_all(28)
	style_base.shadow_color = Color(0, 0, 0, 0.78)
	style_base.shadow_size = 10
	style_base.shadow_offset = Vector2(0, 4)
	base.add_stylebox_override("panel", style_base)

	var brilho_topo := ColorRect.new()
	brilho_topo.color = Color(1, 1, 1, 0.10)
	brilho_topo.rect_position = Vector2(26, 10)
	brilho_topo.rect_size = Vector2(base.rect_size.x - 52, 3)
	brilho_topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(brilho_topo)

	# ===== TÍTULO (metade de cima) =====
	# Fonte menor e caixa mais folgada: o texto não encosta nas bordas
	# nem no subtítulo. Centralizado na vertical dentro da própria faixa.
	var lbl := Label.new()
	lbl.text = titulo
	lbl.rect_position = Vector2(0, 8)
	lbl.rect_size = Vector2(base.rect_size.x, 44)
	lbl.align = Label.ALIGN_CENTER
	lbl.valign = Label.VALIGN_CENTER
	lbl.clip_text = true

	if fonte_orbitron:
		Compat.fonte(lbl, fonte_orbitron)

	Compat.tamanho(lbl, 36)
	lbl.add_color_override("font_color", Color.white)
	lbl.add_color_override("font_color_shadow", cor_neon)
	lbl.add_constant_override("shadow_offset_x", 0)
	lbl.add_constant_override("shadow_offset_y", 0)
	base.add_child(lbl)

	# ===== SUBTÍTULO (faixa de baixo, sem grudar no título) =====
	var sub := Label.new()
	sub.text = subtitulo
	sub.rect_position = Vector2(0, base.rect_size.y - 28)
	sub.rect_size = Vector2(base.rect_size.x, 22)
	sub.align = Label.ALIGN_CENTER
	sub.valign = Label.VALIGN_CENTER
	sub.clip_text = true

	if fonte_orbitron:
		Compat.fonte(sub, fonte_orbitron)

	Compat.tamanho(sub, 14)
	sub.add_color_override("font_color", Color(cor_neon.r, cor_neon.g, cor_neon.b, 0.92))
	base.add_child(sub)

	return {"panel": panel, "base": base, "label": lbl}



func _enquadrar_video_cover() -> void:
	if fundo_video == null:
		return

	# MODO TELA INTEIRA SEM ZOOM/CORTE:
	# O vídeo ocupa exatamente o tamanho da tela.
	# Não usa escala por proporção, então não corta as bordas.
	var tela: Vector2 = get_viewport_rect().size

	fundo_video.rect_position = Vector2.ZERO
	fundo_video.rect_size = tela
	fundo_video.rect_pivot_offset = tela * 0.5
	fundo_video.rect_scale = Vector2.ONE



func _criar_audios() -> void:
	sfx_player_select = AudioStreamPlayer.new()
	sfx_player_select.name = "SfxPlayerSelect"
	add_child(sfx_player_select)

	if ResourceLoader.exists(SFX_SELECT_PLAYER):
		sfx_player_select.stream = load(SFX_SELECT_PLAYER)
		sfx_player_select.volume_db = 0.0
	else:
		push_warning("SFX não encontrado: " + SFX_SELECT_PLAYER)

	sfx_game_start = AudioStreamPlayer.new()
	sfx_game_start.name = "SfxGameStart"
	add_child(sfx_game_start)

	if ResourceLoader.exists(SFX_GAME_START):
		sfx_game_start.stream = load(SFX_GAME_START)
		sfx_game_start.volume_db = 0.0
	else:
		push_warning("SFX não encontrado: " + SFX_GAME_START)

	# Som de torcida/aplausos para a apresentação dos patrocinadores.
	sfx_good_player_patro = AudioStreamPlayer.new()
	sfx_good_player_patro.name = "SfxGoodPlayerPatro"
	add_child(sfx_good_player_patro)

	if ResourceLoader.exists(SFX_GOOD_PLAYER_PATRO):
		sfx_good_player_patro.stream = load(SFX_GOOD_PLAYER_PATRO)
		sfx_good_player_patro.volume_db = 1.2

		if sfx_good_player_patro.stream is AudioStream:
			Compat.laco(sfx_good_player_patro.stream, false)
	else:
		push_warning("SFX good_player não encontrado: " + SFX_GOOD_PLAYER_PATRO)



func _tocar_musica() -> void:
	audio_fundo = AudioStreamPlayer.new()
	audio_fundo.name = "SongFut"
	add_child(audio_fundo)

	if ResourceLoader.exists(MUSICA_FUNDO):
		var stream: AudioStream = load(MUSICA_FUNDO)

		if stream is AudioStream:
			Compat.laco(stream, true)

		audio_fundo.stream = stream
		audio_fundo.volume_db = -5.0
		audio_fundo.play()
	else:
		push_error("Música não encontrada: " + MUSICA_FUNDO)


func _tocar_good_player_patrocinadores(forcar: bool = false) -> void:
	if sfx_good_player_patro == null:
		return

	if sfx_good_player_patro.stream == null:
		return

	if sfx_good_player_patro.playing and not forcar:
		return

	if forcar and sfx_good_player_patro.playing:
		sfx_good_player_patro.stop()

	sfx_good_player_patro.play()


func _parar_good_player_patrocinadores() -> void:
	if sfx_good_player_patro and sfx_good_player_patro.playing:
		sfx_good_player_patro.stop()

# =========================================================
# ANIMAÇÃO DOS BOTÕES
# ARCADE: cicla as 4 cores dos players (1 a 4)
# COPA: respiração dourada constante
# =========================================================
func _animar_botoes() -> void:
	_animar_arcade_ciclo()
	_animar_copa_pulse()


func _animar_arcade_ciclo() -> void:
	if glow_tween_arcade:
		glow_tween_arcade.kill()

	glow_tween_arcade = create_tween()
	glow_tween_arcade.set_loops()

	glow_tween_arcade.tween_callback(self, "_set_glow_arcade", [Color(0.0, 0.0, 1.0, 1.0), 34])
	glow_tween_arcade.tween_interval(0.45)

	glow_tween_arcade.tween_callback(self, "_set_glow_arcade", [Color(0.0, 1.0, 0.0, 1.0), 34])
	glow_tween_arcade.tween_interval(0.45)

	glow_tween_arcade.tween_callback(self, "_set_glow_arcade", [Color(1.0, 0.0, 0.0, 1.0), 34])
	glow_tween_arcade.tween_interval(0.45)

	glow_tween_arcade.tween_callback(self, "_set_glow_arcade", [Color(1.0, 1.0, 0.0, 1.0), 34])
	glow_tween_arcade.tween_interval(0.45)


func _set_glow_arcade(cor: Color, brilho: int = 30) -> void:
	if btn_arcade_panel == null:
		return

	var style_glow = btn_arcade_panel.get_stylebox("panel") as StyleBoxFlat
	if style_glow:
		style_glow.border_color = cor
		style_glow.shadow_color = Color(cor.r, cor.g, cor.b, 0.92)
		style_glow.shadow_size = brilho

	var style_base = btn_arcade_base.get_stylebox("panel") as StyleBoxFlat
	if style_base:
		style_base.border_color = Color(cor.r, cor.g, cor.b, 0.68)

	if btn_arcade_label:
		btn_arcade_label.add_color_override("font_color_shadow", cor)


func _animar_copa_pulse() -> void:
	if glow_tween_copa:
		glow_tween_copa.kill()

	glow_tween_copa = create_tween()
	glow_tween_copa.set_loops()

	glow_tween_copa.tween_method(self, "_set_glow_copa", 18.0, 36.0, 0.95) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	glow_tween_copa.tween_method(self, "_set_glow_copa", 36.0, 18.0, 0.95) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _set_glow_copa(tamanho: float) -> void:
	if btn_copa_panel == null:
		return

	var style_glow = btn_copa_panel.get_stylebox("panel") as StyleBoxFlat
	if style_glow:
		style_glow.shadow_size = int(tamanho)
		style_glow.border_color = COR_COPA
		style_glow.shadow_color = Color(COR_COPA.r, COR_COPA.g, COR_COPA.b, 0.95)


# =========================================================
# MODAL DE CONFIRMAÇÃO DO MODO COPA
# =========================================================
func _abrir_modal_copa() -> void:
	if copa_modal_aberto:
		return

	copa_modal_aberto = true
	copa_fechando = false
	copa_tempo_restante = COPA_TEMPO_CONFIRMACAO
	bloquear_cup_ate_ms = Time.get_ticks_msec() + COOLDOWN_START_MS

	_set_leds_todos_rgb(_rgb_copa())

	if sfx_player_select and sfx_player_select.stream:
		sfx_player_select.play()

	copa_layer = CanvasLayer.new()
	add_child(copa_layer)

	copa_fundo = ColorRect.new()
	copa_fundo.set_anchors_preset(Control.PRESET_WIDE)
	copa_fundo.color = Color(0, 0, 0, 0.0)
	copa_layer.add_child(copa_fundo)

	copa_modal = Panel.new()
	copa_modal.rect_size = Vector2(780, 470)
	copa_modal.rect_position = Vector2(
		(get_viewport_rect().size.x - copa_modal.rect_size.x) / 2.0,
		(get_viewport_rect().size.y - copa_modal.rect_size.y) / 2.0
	)
	copa_modal.rect_scale = Vector2(0.94, 0.94)
	copa_modal.modulate = Color(1, 1, 1, 0)
	copa_layer.add_child(copa_modal)

	_aplicar_neon_modal(copa_modal, COR_COPA)

	# Título
	var titulo := Label.new()
	titulo.text = "MODO COPA"
	titulo.align = Label.ALIGN_CENTER
	titulo.valign = Label.VALIGN_CENTER
	titulo.rect_position = Vector2(0, 30)
	titulo.rect_size = Vector2(780, 58)

	if fonte_orbitron:
		Compat.fonte(titulo, fonte_orbitron)

	Compat.tamanho(titulo, 46)
	titulo.add_color_override("font_color", Color.white)
	titulo.add_color_override("font_color_shadow", COR_COPA)
	titulo.add_constant_override("shadow_offset_x", 0)
	titulo.add_constant_override("shadow_offset_y", 0)
	copa_modal.add_child(titulo)

	# Traço dourado decorativo sob o título
	var traco := ColorRect.new()
	traco.color = COR_COPA
	traco.rect_size = Vector2(240, 4)
	traco.rect_position = Vector2((780 - 240) / 2.0, 92)
	copa_modal.add_child(traco)

	# Destaque: faixa de jogadores
	var destaque := Label.new()
	destaque.text = "%d A %d JOGADORES" % [COPA_MIN_JOGADORES, COPA_MAX_JOGADORES]
	destaque.align = Label.ALIGN_CENTER
	destaque.valign = Label.VALIGN_CENTER
	destaque.rect_position = Vector2(0, 116)
	destaque.rect_size = Vector2(780, 54)

	if fonte_orbitron:
		Compat.fonte(destaque, fonte_orbitron)

	Compat.tamanho(destaque, 38)
	destaque.add_color_override("font_color", COR_COPA)
	destaque.add_color_override("font_color_shadow", COR_COPA)
	destaque.add_constant_override("shadow_offset_x", 0)
	destaque.add_constant_override("shadow_offset_y", 0)
	copa_modal.add_child(destaque)

	# Descrição
	var descricao := Label.new()
	descricao.text = "Você vai cadastrar os nomes dos jogadores na tela de lobby."
	descricao.align = Label.ALIGN_CENTER
	descricao.valign = Label.VALIGN_CENTER
	descricao.rect_position = Vector2(40, 178)
	descricao.rect_size = Vector2(700, 30)

	if fonte_orbitron:
		Compat.fonte(descricao, fonte_orbitron)

	Compat.tamanho(descricao, 18)
	descricao.add_color_override("font_color", Color(0.82, 0.86, 0.92))
	copa_modal.add_child(descricao)

	# "Botão" de confirmação (visual) com pulso suave
	var hint := Panel.new()
	hint.rect_size = Vector2(560, 76)
	hint.rect_position = Vector2((780 - 560) / 2.0, 232)
	copa_modal.add_child(hint)

	var hint_style := StyleBoxFlat.new()
	hint_style.bg_color = Color(COR_COPA.r * 0.10, COR_COPA.g * 0.08, 0.02, 0.96)
	hint_style.border_color = COR_COPA
	hint_style.set_border_width_all(3)
	hint_style.set_corner_radius_all(22)
	hint_style.shadow_color = Color(COR_COPA.r, COR_COPA.g, COR_COPA.b, 0.55)
	hint_style.shadow_size = 18
	hint_style.shadow_offset = Vector2.ZERO
	hint.add_stylebox_override("panel", hint_style)

	# ===== TEXTO DO BOTÃO COM MARGEM INTERNA =====
	# Antes ocupava a largura toda (full rect) e encostava nas bordas.
	# Agora tem 18px de folga de cada lado e fonte um pouco menor,
	# então o texto fica bem enquadrado dentro do botão dourado.
	var hint_label := Label.new()
	hint_label.text = "APERTE NOVAMENTE PARA CONFIRMAR"
	hint_label.rect_position = Vector2(18, 0)
	hint_label.rect_size = Vector2(hint.rect_size.x - 36, hint.rect_size.y)
	hint_label.align = Label.ALIGN_CENTER
	hint_label.valign = Label.VALIGN_CENTER
	hint_label.autowrap = false
	hint_label.clip_text = true

	if fonte_orbitron:
		Compat.fonte(hint_label, fonte_orbitron)

	Compat.tamanho(hint_label, 21)
	hint_label.add_color_override("font_color", Color.white)
	hint_label.add_color_override("font_color_shadow", COR_COPA)
	hint_label.add_constant_override("shadow_offset_x", 0)
	hint_label.add_constant_override("shadow_offset_y", 0)
	hint.add_child(hint_label)

	# Pulso do hint (preso ao próprio nó, morre junto com ele)
	hint.rect_pivot_offset = hint.rect_size * 0.5
	var pulso = hint.create_tween()
	pulso.set_loops()
	pulso.tween_property(hint, "rect_scale", Vector2(1.035, 1.035), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulso.tween_property(hint, "rect_scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Aviso de tempo (atualizado no _process)
	copa_aviso_tempo = Label.new()
	copa_aviso_tempo.text = "Esta janela fecha sozinha em %ds" % int(COPA_TEMPO_CONFIRMACAO)
	copa_aviso_tempo.align = Label.ALIGN_CENTER
	copa_aviso_tempo.valign = Label.VALIGN_CENTER
	copa_aviso_tempo.rect_position = Vector2(0, 332)
	copa_aviso_tempo.rect_size = Vector2(780, 28)

	if fonte_orbitron:
		Compat.fonte(copa_aviso_tempo, fonte_orbitron)

	Compat.tamanho(copa_aviso_tempo, 16)
	copa_aviso_tempo.add_color_override("font_color", Color(0.70, 0.74, 0.80))
	copa_modal.add_child(copa_aviso_tempo)

	# Barra de tempo
	copa_barra = ProgressBar.new()
	copa_barra.min_value = 0
	copa_barra.max_value = COPA_TEMPO_CONFIRMACAO
	copa_barra.value = COPA_TEMPO_CONFIRMACAO
	copa_barra.rect_position = Vector2(90, 378)
	copa_barra.rect_size = Vector2(600, 30)
	copa_barra.percent_visible = false
	copa_modal.add_child(copa_barra)

	_aplicar_estilo_barra(copa_barra, COR_COPA)

	# Animação de entrada
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(copa_fundo, "color", Color(0, 0, 0, 0.78), 0.22)
	t.tween_property(copa_modal, "modulate", Color.white, 0.22)
	t.tween_property(copa_modal, "rect_scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)



func _fechar_modal_copa() -> void:
	# Fecha SEM ação (timeout ou cancelamento). Volta para a tela inicial.
	if copa_fechando:
		return

	copa_fechando = true

	# LEDs voltam para o modo atrativo automaticamente quando o flag liberar.
	if copa_layer == null:
		copa_modal_aberto = false
		copa_fechando = false
		return

	var t = create_tween()
	t.set_parallel(true)

	if copa_modal:
		t.tween_property(copa_modal, "rect_scale", Vector2(0.94, 0.94), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		t.tween_property(copa_modal, "modulate", Color(1, 1, 1, 0), 0.16)

	if copa_fundo:
		t.tween_property(copa_fundo, "color", Color(0, 0, 0, 0.0), 0.18)

	yield(t, "finished")

	if copa_layer:
		copa_layer.queue_free()

	copa_layer = null
	copa_modal = null
	copa_fundo = null
	copa_barra = null
	copa_aviso_tempo = null

	copa_modal_aberto = false
	copa_fechando = false

	# Reseta o passo do atrativo para reentrar bonito.
	_reiniciar_led_atrativo(LED_ATRATIVO_REINICIO_DELAY_COPA)


func _confirmar_copa_ir_lobby() -> void:
	if copa_fechando:
		return

	if not ResourceLoader.exists(CENA_LOBBY):
		push_error("Cena de lobby não encontrada: " + CENA_LOBBY)
		print("ERRO: crie a cena ", CENA_LOBBY, " antes de usar o Modo Copa.")
		return

	copa_fechando = true

	# Confirmação visual nos LEDs físicos (dourado forte).
	_set_leds_todos_rgb(_rgb_copa_forte())

	if sfx_game_start and sfx_game_start.stream:
		sfx_game_start.play()

	if copa_modal:
		var t = copa_modal.create_tween()
		t.set_parallel(true)
		t.tween_property(copa_modal, "rect_scale", Vector2(1.05, 1.05), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(copa_modal, "modulate", Color(1, 1, 1, 0), 0.22)

	yield(get_tree().create_timer(0.24), "timeout")

	_serial_write_opening("OFF")

	if audio_fundo:
		audio_fundo.stop()

	print("================================")
	print("MODO COPA CONFIRMADO -> ABRINDO LOBBY")
	print("FAIXA DE JOGADORES: ", COPA_MIN_JOGADORES, " a ", COPA_MAX_JOGADORES)
	print("================================")

	get_tree().change_scene(CENA_LOBBY)


func _abrir_modal_players() -> void:
	# Segurança: nunca abre durante os patrocinadores nem durante o loading.
	if patro_replay_ativo or opening_loading_layer != null:
		return

	escolhendo_players = true
	iniciando_jogo = false
	tempo_restante = TEMPO_ESCOLHA
	ultimo_segundo_exibido = int(ceil(TEMPO_ESCOLHA))
	total_players = 1
	bloquear_start_ate_ms = Time.get_ticks_msec() + COOLDOWN_START_MS
	
	# Ao abrir a seleção, todos os LEDs ficam na cor do Player 1.
	_leds_todos_cor_player(0)

	_tocar_som_confirmar_modo()

	modal_layer = CanvasLayer.new()
	add_child(modal_layer)

	modal_fundo = ColorRect.new()
	modal_fundo.set_anchors_preset(Control.PRESET_WIDE)
	modal_fundo.color = Color(0, 0, 0, 0.0)
	modal_layer.add_child(modal_fundo)

	modal = Panel.new()
	modal.rect_size = Vector2(820, 560)
	modal.rect_position = Vector2(
		(get_viewport_rect().size.x - modal.rect_size.x) / 2.0,
		(get_viewport_rect().size.y - modal.rect_size.y) / 2.0
	)
	modal.rect_scale = Vector2(0.94, 0.94)
	modal.modulate = Color(1, 1, 1, 0)
	modal_layer.add_child(modal)

	_aplicar_neon_modal(modal, cores_players[0])

	var titulo := Label.new()
	titulo.name = "TituloPlayers"
	titulo.text = "ESCOLHA OS PLAYERS"
	titulo.align = Label.ALIGN_CENTER
	titulo.valign = Label.VALIGN_CENTER
	titulo.rect_position = Vector2(0, 28)
	titulo.rect_size = Vector2(820, 58)

	if fonte_orbitron:
		Compat.fonte(titulo, fonte_orbitron)

	Compat.tamanho(titulo, 40)
	titulo.add_color_override("font_color", Color.white)
	titulo.add_color_override("font_color_shadow", cores_players[0])
	titulo.add_constant_override("shadow_offset_x", 0)
	titulo.add_constant_override("shadow_offset_y", 0)
	modal.add_child(titulo)

	var aviso := Label.new()
	aviso.name = "AvisoPlayers"
	aviso.text = "1 PLAYER SELECIONADO  •  PRÓXIMO: PLAYER 2"
	aviso.align = Label.ALIGN_CENTER
	aviso.valign = Label.VALIGN_CENTER
	aviso.rect_position = Vector2(0, 86)
	aviso.rect_size = Vector2(820, 36)

	if fonte_orbitron:
		Compat.fonte(aviso, fonte_orbitron)

	Compat.tamanho(aviso, 22)
	aviso.add_color_override("font_color", cores_players[0])
	aviso.add_color_override("font_color_shadow", cores_players[0])
	aviso.add_constant_override("shadow_offset_x", 0)
	aviso.add_constant_override("shadow_offset_y", 0)
	modal.add_child(aviso)

	# =========================
	# CONTADOR FIXO E LEGÍVEL
	# =========================
	contador_label = Label.new()
	contador_label.text = str(ultimo_segundo_exibido)
	contador_label.align = Label.ALIGN_CENTER
	contador_label.valign = Label.VALIGN_CENTER
	contador_label.rect_position = Vector2(705, 28)
	contador_label.rect_size = Vector2(74, 58)
	Compat.z(contador_label, 5)

	if fonte_orbitron:
		Compat.fonte(contador_label, fonte_orbitron)

	Compat.tamanho(contador_label, 38)
	contador_label.add_color_override("font_color", Color.white)
	contador_label.add_color_override("font_color_shadow", cores_players[0])
	contador_label.add_constant_override("shadow_offset_x", 0)
	contador_label.add_constant_override("shadow_offset_y", 0)

	var contador_bg := Panel.new()
	contador_bg.name = "ContadorBG"
	contador_bg.rect_position = contador_label.rect_position
	contador_bg.rect_size = contador_label.rect_size
	contador_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Compat.z(contador_bg, 4)

	var contador_style := StyleBoxFlat.new()
	var cor_contador_inicial = cores_players[0]

	contador_style.bg_color = Color(
		0.055 + cor_contador_inicial.r * 0.08,
		0.060 + cor_contador_inicial.g * 0.08,
		0.070 + cor_contador_inicial.b * 0.08,
		0.96
	)
	contador_style.border_color = Color(cor_contador_inicial.r, cor_contador_inicial.g, cor_contador_inicial.b, 0.95)
	contador_style.set_border_width_all(3)
	contador_style.set_corner_radius_all(18)
	contador_style.shadow_color = Color(cor_contador_inicial.r, cor_contador_inicial.g, cor_contador_inicial.b, 0.72)
	contador_style.shadow_size = 20
	contador_style.shadow_offset = Vector2.ZERO
	contador_bg.add_stylebox_override("panel", contador_style)

	# Fundo primeiro, número depois.
	modal.add_child(contador_bg)
	modal.add_child(contador_label)

	player_cards.clear()
	player_labels.clear()

	var start_x := 60
	var start_y := 155
	var card_w := 330
	var card_h := 82
	var gap_x := 40
	var gap_y := 30

	for i in range(MAX_PLAYERS):
		var card := Panel.new()
		card.rect_size = Vector2(card_w, card_h)

		var col = i % 2
		var row = int(i / 2)

		card.rect_position = Vector2(
			start_x + (col * (card_w + gap_x)),
			start_y + (row * (card_h + gap_y))
		)

		card.add_stylebox_override("panel", _style_card_player(false, cores_players[i]))

		modal.add_child(card)
		player_cards.append(card)

		var p := Label.new()
		p.text = "PLAYER %d" % [i + 1]
		p.set_anchors_preset(Control.PRESET_WIDE)
		p.align = Label.ALIGN_CENTER
		p.valign = Label.VALIGN_CENTER

		if fonte_orbitron:
			Compat.fonte(p, fonte_orbitron)

		Compat.tamanho(p, 28)
		p.add_color_override("font_color", Color(0.35, 0.35, 0.35))
		p.add_color_override("font_color_shadow", Color.transparent)
		p.add_constant_override("shadow_offset_x", 0)
		p.add_constant_override("shadow_offset_y", 0)

		card.add_child(p)
		player_labels.append(p)

	barra = ProgressBar.new()
	barra.min_value = 0
	barra.max_value = TEMPO_ESCOLHA
	barra.value = TEMPO_ESCOLHA
	barra.rect_position = Vector2(90, 448)
	barra.rect_size = Vector2(640, 34)
	barra.percent_visible = false
	modal.add_child(barra)

	_estilizar_barra_tempo(cores_players[0])

	var rodape := Label.new()
	rodape.text = "A partida começa automaticamente após a contagem"
	rodape.align = Label.ALIGN_CENTER
	rodape.valign = Label.VALIGN_CENTER
	rodape.rect_position = Vector2(0, 498)
	rodape.rect_size = Vector2(820, 30)

	if fonte_orbitron:
		Compat.fonte(rodape, fonte_orbitron)

	Compat.tamanho(rodape, 17)
	rodape.add_color_override("font_color", Color(0.65, 0.72, 0.78))
	modal.add_child(rodape)

	_animar_entrada_modal()
	_atualizar_players()



func _animar_entrada_modal() -> void:
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(modal_fundo, "color", Color(0, 0, 0, 0.76), 0.22)
	t.tween_property(modal, "modulate", Color.white, 0.22)
	t.tween_property(modal, "rect_scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _atualizar_contador_inteiro() -> void:
	var segundo_atual: int = int(ceil(tempo_restante))

	if segundo_atual != ultimo_segundo_exibido:
		ultimo_segundo_exibido = segundo_atual

		if contador_label:
			contador_label.text = str(segundo_atual)

			var t = create_tween()
			contador_label.rect_scale = Vector2(1.22, 1.22)
			t.tween_property(contador_label, "rect_scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _adicionar_player() -> void:
	if total_players >= MAX_PLAYERS:
		return

	total_players += 1

	# Cada player selecionado mostra sua cor em todos os LEDs.
	# Player 1 azul, Player 2 verde, Player 3 vermelho, Player 4 amarelo.
	_leds_todos_cor_player(total_players - 1)

	if sfx_player_select and sfx_player_select.stream:
		sfx_player_select.stop()
		sfx_player_select.play()

	_atualizar_players()
	_animar_card_player(total_players - 1)

	if total_players >= MAX_PLAYERS:
		yield(get_tree().create_timer(0.35), "timeout")
		_preparar_inicio_partida()



func _animar_card_player(index: int) -> void:
	if index < 0 or index >= player_cards.size():
		return

	var card = player_cards[index]
	card.rect_scale = Vector2(1.08, 1.08)

	var t = create_tween()
	t.tween_property(card, Compat.prop(card, "scale"), Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)



func _atualizar_players() -> void:
	if modal == null:
		return

	var cor_modal = cores_players[clamp(total_players - 1, 0, MAX_PLAYERS - 1)]

	_aplicar_neon_modal(modal, cor_modal)
	_estilizar_barra_tempo(cor_modal)
	_atualizar_contador_cor(cor_modal)

	var titulo = modal.get_node_or_null("TituloPlayers") as Label
	if titulo:
		titulo.add_color_override("font_color_shadow", cor_modal)

	var aviso = modal.get_node_or_null("AvisoPlayers") as Label
	if aviso:
		if total_players < MAX_PLAYERS:
			aviso.text = "%d PLAYER%s SELECIONADO%s  •  PRÓXIMO: PLAYER %d" % [
				total_players,
				"" if total_players == 1 else "S",
				"" if total_players == 1 else "S",
				total_players + 1
			]
		else:
			aviso.text = "4 PLAYERS SELECIONADOS  •  INICIANDO PARTIDA"

		aviso.add_color_override("font_color", cor_modal)
		aviso.add_color_override("font_color_shadow", cor_modal)

	for i in range(MAX_PLAYERS):
		if i >= player_labels.size() or i >= player_cards.size():
			continue

		var label = player_labels[i]
		var card = player_cards[i]
		var cor = cores_players[i]

		if i < total_players:
			label.text = "PLAYER %d  ✓" % [i + 1]
			label.add_color_override("font_color", cor)
			label.add_color_override("font_color_shadow", cor)
			label.add_constant_override("shadow_offset_x", 0)
			label.add_constant_override("shadow_offset_y", 0)

			card.add_stylebox_override("panel", _style_card_player(true, cor))
		else:
			label.text = "PLAYER %d" % [i + 1]
			label.add_color_override("font_color", Color(0.35, 0.35, 0.35))
			label.add_color_override("font_color_shadow", Color.transparent)

			card.add_stylebox_override("panel", _style_card_player(false, cor))


func _aplicar_estilo_barra(b: ProgressBar, cor: Color) -> void:
	if b == null:
		return

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.012, 0.016, 0.024, 0.96)
	bg.border_color = Color(cor.r, cor.g, cor.b, 0.45)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(16)
	bg.shadow_color = Color(cor.r, cor.g, cor.b, 0.28)
	bg.shadow_size = 10
	bg.shadow_offset = Vector2.ZERO

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(cor.r, cor.g, cor.b, 0.88)
	fill.border_color = Color(cor.r, cor.g, cor.b, 1.0)
	fill.set_border_width_all(1)
	fill.set_corner_radius_all(14)
	fill.shadow_color = Color(cor.r, cor.g, cor.b, 0.65)
	fill.shadow_size = 16
	fill.shadow_offset = Vector2.ZERO

	b.add_stylebox_override("bg", bg)
	b.add_stylebox_override("fg", fill)


func _estilizar_barra_tempo(cor: Color) -> void:
	_aplicar_estilo_barra(barra, cor)


func _atualizar_contador_cor(cor: Color) -> void:
	if contador_label == null:
		return

	# Número sempre branco para boa leitura.
	contador_label.add_color_override("font_color", Color.white)
	contador_label.add_color_override("font_color_shadow", cor)
	contador_label.add_constant_override("shadow_offset_x", 0)
	contador_label.add_constant_override("shadow_offset_y", 0)

	var parent = contador_label.get_parent()
	if parent == null:
		return

	var contador_bg = parent.get_node_or_null("ContadorBG") as Panel
	if contador_bg == null:
		return

	var style := StyleBoxFlat.new()

	# Fundo neutro, mas com leve tom da cor do player atual.
	style.bg_color = Color(
		0.055 + cor.r * 0.08,
		0.060 + cor.g * 0.08,
		0.070 + cor.b * 0.08,
		0.96
	)

	style.border_color = Color(cor.r, cor.g, cor.b, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(cor.r, cor.g, cor.b, 0.72)
	style.shadow_size = 20
	style.shadow_offset = Vector2.ZERO

	contador_bg.add_stylebox_override("panel", style)



func _cor_contador_fixa() -> Color:
	return Color(1.0, 0.82, 0.10, 1.0)

func _aplicar_neon_multicor(panel: Panel, quantidade: int) -> void:
	if panel == null:
		return

	quantidade = clamp(quantidade, 1, MAX_PLAYERS)

	# Base escura elegante.
	var base := StyleBoxFlat.new()
	base.bg_color = Color(0.010, 0.014, 0.020, 0.97)
	base.border_color = Color(0.75, 0.82, 0.90, 0.20)
	base.set_border_width_all(2)
	base.set_corner_radius_all(34)
	base.shadow_color = Color(0, 0, 0, 0.80)
	base.shadow_size = 20
	base.shadow_offset = Vector2.ZERO
	panel.add_stylebox_override("panel", base)

	# Remove neon antigo se existir.
	var antigo = panel.get_node_or_null("NeonMultiRoot")
	if antigo:
		antigo.queue_free()

	var neon_root := Control.new()
	neon_root.name = "NeonMultiRoot"
	neon_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	neon_root.rect_position = Vector2.ZERO
	neon_root.rect_size = panel.rect_size
	Compat.z(neon_root, 50)
	panel.add_child(neon_root)

	var esp := 8.0
	var w = panel.rect_size.x
	var h = panel.rect_size.y

	var seg_w = w / float(quantidade)
	var seg_h = h / float(quantidade)

	for i in range(quantidade):
		var cor = cores_players[i]

		# Topo dividido por cor.
		_criar_faixa_neon(
			neon_root,
			Vector2(float(i) * seg_w, 0),
			Vector2(seg_w, esp),
			cor
		)

		# Base dividida por cor.
		_criar_faixa_neon(
			neon_root,
			Vector2(float(i) * seg_w, h - esp),
			Vector2(seg_w, esp),
			cor
		)

		# Lateral esquerda dividida por cor.
		_criar_faixa_neon(
			neon_root,
			Vector2(0, float(i) * seg_h),
			Vector2(esp, seg_h),
			cor
		)

		# Lateral direita dividida por cor.
		_criar_faixa_neon(
			neon_root,
			Vector2(w - esp, float(i) * seg_h),
			Vector2(esp, seg_h),
			cor
		)


func _criar_faixa_neon(parent: Control, pos: Vector2, tamanho: Vector2, cor: Color) -> void:
	var faixa := Panel.new()
	faixa.rect_position = pos
	faixa.rect_size = tamanho
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(faixa)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(cor.r, cor.g, cor.b, 0.92)
	style.border_color = Color(cor.r, cor.g, cor.b, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.shadow_color = Color(cor.r, cor.g, cor.b, 0.85)
	style.shadow_size = 22
	style.shadow_offset = Vector2.ZERO
	faixa.add_stylebox_override("panel", style)



func _aplicar_neon_modal(panel: Panel, cor: Color) -> void:
	if panel == null:
		return

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.010, 0.014, 0.020, 0.97)
	style.border_color = cor
	style.set_border_width_all(4)
	style.set_corner_radius_all(34)
	style.shadow_color = Color(cor.r, cor.g, cor.b, 0.76)
	style.shadow_size = 40
	style.shadow_offset = Vector2.ZERO
	panel.add_stylebox_override("panel", style)


func _style_card_player(ativo: bool, cor: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.shadow_offset = Vector2(0, 4)

	if ativo:
		style.bg_color = Color(cor.r * 0.06, cor.g * 0.06, cor.b * 0.06, 0.96)
		style.border_color = cor
		style.shadow_color = Color(cor.r, cor.g, cor.b, 0.60)
		style.shadow_size = 20
	else:
		style.bg_color = Color(0.025, 0.030, 0.038, 0.92)
		style.border_color = Color(0.22, 0.25, 0.28, 1.0)
		style.shadow_color = Color(0, 0, 0, 0.45)
		style.shadow_size = 8

	return style


func _preparar_inicio_partida() -> void:
	var _g3_estado = null
	if iniciando_jogo:
		return

	iniciando_jogo = true
	escolhendo_players = false

	if total_players <= 0:
		total_players = 1

	# Antes de iniciar, faz uma confirmação rápida com as cores selecionadas.
	_g3_estado = _animacao_leds_players_confirmados()
	if _g3_estado is GDScriptFunctionState:
		_g3_estado = yield(_g3_estado, "completed")

	if sfx_game_start and sfx_game_start.stream:
		sfx_game_start.play()

	_g3_estado = _fechar_modal_players()
	if _g3_estado is GDScriptFunctionState:
		_g3_estado = yield(_g3_estado, "completed")
	_mostrar_tela_iniciando()

	yield(get_tree().create_timer(TEMPO_TELA_INICIANDO), "timeout")
	_iniciar_jogo()



func _fechar_modal_players() -> void:
	if modal_layer == null:
		return

	var t = create_tween()
	t.set_parallel(true)

	if modal:
		t.tween_property(modal, "rect_scale", Vector2(0.94, 0.94), 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		t.tween_property(modal, "modulate", Color(1, 1, 1, 0), 0.18)

	if modal_fundo:
		t.tween_property(modal_fundo, "color", Color(0, 0, 0, 0.0), 0.20)

	yield(t, "finished")

	if modal_layer:
		modal_layer.queue_free()

	modal_layer = null
	modal = null
	modal_fundo = null



func _mostrar_tela_iniciando() -> void:
	iniciando_layer = CanvasLayer.new()
	add_child(iniciando_layer)

	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_WIDE)
	fundo.color = Color(0, 0, 0, 0.68)
	iniciando_layer.add_child(fundo)

	iniciando_panel = Panel.new()
	iniciando_panel.rect_size = Vector2(880, 500)
	iniciando_panel.rect_position = Vector2(
		(get_viewport_rect().size.x - iniciando_panel.rect_size.x) / 2.0,
		(get_viewport_rect().size.y - iniciando_panel.rect_size.y) / 2.0
	)
	iniciando_panel.rect_scale = Vector2(0.92, 0.92)
	iniciando_panel.modulate = Color(1, 1, 1, 0)
	iniciando_panel.rect_clip_content = false
	iniciando_layer.add_child(iniciando_panel)

	# Aqui agora usa todas as cores selecionadas, não só a última.
	_aplicar_neon_multicor(iniciando_panel, total_players)

	var cor_titulo = Color.white

	iniciando_label = Label.new()
	iniciando_label.text = "INICIANDO PARTIDA"
	iniciando_label.rect_position = Vector2(0, 28)
	iniciando_label.rect_size = Vector2(880, 58)
	iniciando_label.align = Label.ALIGN_CENTER
	iniciando_label.valign = Label.VALIGN_CENTER
	Compat.z(iniciando_label, 80)

	if fonte_orbitron:
		Compat.fonte(iniciando_label, fonte_orbitron)

	Compat.tamanho(iniciando_label, 42)
	iniciando_label.add_color_override("font_color", cor_titulo)
	iniciando_label.add_color_override("font_color_shadow", cores_players[0])
	iniciando_label.add_constant_override("shadow_offset_x", 0)
	iniciando_label.add_constant_override("shadow_offset_y", 0)
	iniciando_panel.add_child(iniciando_label)

	iniciando_sub_label = Label.new()
	iniciando_sub_label.text = "%d PLAYER%s CONFIRMADO%s" % [
		total_players,
		"" if total_players == 1 else "S",
		"" if total_players == 1 else "S"
	]
	iniciando_sub_label.rect_position = Vector2(0, 92)
	iniciando_sub_label.rect_size = Vector2(880, 40)
	iniciando_sub_label.align = Label.ALIGN_CENTER
	iniciando_sub_label.valign = Label.VALIGN_CENTER
	Compat.z(iniciando_sub_label, 80)

	if fonte_orbitron:
		Compat.fonte(iniciando_sub_label, fonte_orbitron)

	Compat.tamanho(iniciando_sub_label, 22)
	iniciando_sub_label.add_color_override("font_color", Color(0.82, 0.90, 0.96))
	iniciando_sub_label.add_color_override("font_color_shadow", cores_players[clamp(total_players - 1, 0, MAX_PLAYERS - 1)])
	iniciando_sub_label.add_constant_override("shadow_offset_x", 0)
	iniciando_sub_label.add_constant_override("shadow_offset_y", 0)
	iniciando_panel.add_child(iniciando_sub_label)

	var cards_root := Control.new()
	cards_root.rect_position = Vector2(60, 165)
	cards_root.rect_size = Vector2(760, 190)
	Compat.z(cards_root, 80)
	iniciando_panel.add_child(cards_root)

	var card_w := 170.0
	var card_h := 170.0
	var gap := 24.0
	var largura_total = (card_w * float(total_players)) + (gap * float(total_players - 1))
	var start_x = (cards_root.rect_size.x - largura_total) / 2.0

	for i in range(total_players):
		var cor = cores_players[i]

		var card := Panel.new()
		card.rect_position = Vector2(start_x + float(i) * (card_w + gap), 0)
		card.rect_size = Vector2(card_w, card_h)
		card.add_stylebox_override("panel", _style_card_player(true, cor))
		cards_root.add_child(card)

		var nome := Label.new()
		nome.text = "PLAYER %d" % [i + 1]
		nome.rect_position = Vector2(0, 24)
		nome.rect_size = Vector2(card_w, 32)
		nome.align = Label.ALIGN_CENTER
		nome.valign = Label.VALIGN_CENTER
		Compat.tamanho(nome, 19)
		nome.add_color_override("font_color", cor)

		if fonte_orbitron:
			Compat.fonte(nome, fonte_orbitron)

		card.add_child(nome)

		var check := Label.new()
		check.text = "✓"
		check.rect_position = Vector2(0, 62)
		check.rect_size = Vector2(card_w, 58)
		check.align = Label.ALIGN_CENTER
		check.valign = Label.VALIGN_CENTER
		Compat.tamanho(check, 48)
		check.add_color_override("font_color", Color.white)
		check.add_color_override("font_color_shadow", cor)
		check.add_constant_override("shadow_offset_x", 0)
		check.add_constant_override("shadow_offset_y", 0)

		if fonte_orbitron:
			Compat.fonte(check, fonte_orbitron)

		card.add_child(check)

		var nome_cor := Label.new()
		match i:
			0:
				nome_cor.text = "AZUL"
			1:
				nome_cor.text = "VERDE"
			2:
				nome_cor.text = "VERMELHO"
			3:
				nome_cor.text = "AMARELO"

		nome_cor.rect_position = Vector2(0, 128)
		nome_cor.rect_size = Vector2(card_w, 26)
		nome_cor.align = Label.ALIGN_CENTER
		nome_cor.valign = Label.VALIGN_CENTER
		Compat.tamanho(nome_cor, 13)
		nome_cor.add_color_override("font_color", Color(0.72, 0.80, 0.86))

		if fonte_orbitron:
			Compat.fonte(nome_cor, fonte_orbitron)

		card.add_child(nome_cor)

	var rodape := Label.new()
	rodape.text = "PREPARE-SE"
	rodape.rect_position = Vector2(0, 405)
	rodape.rect_size = Vector2(880, 44)
	rodape.align = Label.ALIGN_CENTER
	rodape.valign = Label.VALIGN_CENTER
	Compat.z(rodape, 80)
	Compat.tamanho(rodape, 26)
	rodape.add_color_override("font_color", Color.white)
	rodape.add_color_override("font_color_shadow", cores_players[clamp(total_players - 1, 0, MAX_PLAYERS - 1)])
	rodape.add_constant_override("shadow_offset_x", 0)
	rodape.add_constant_override("shadow_offset_y", 0)

	if fonte_orbitron:
		Compat.fonte(rodape, fonte_orbitron)

	iniciando_panel.add_child(rodape)

	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(iniciando_panel, "modulate", Color.white, 0.24)
	t.tween_property(iniciando_panel, "rect_scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _iniciar_jogo() -> void:
	if total_players <= 0:
		total_players = 1

	total_players = clamp(total_players, 1, MAX_PLAYERS)

	var cores_selecionadas: Array = []

	for i in range(total_players):
		cores_selecionadas.append(cores_players[i])

	var players_global = get_node_or_null("/root/PlayersGlobal")

	if players_global != null:
		if players_global.has_method("configurar_players_futebol"):
			players_global.configurar_players_futebol(total_players, cores_selecionadas)
		else:
			players_global.set("total_players_futebol", total_players)
			players_global.set("cores_players_futebol", cores_selecionadas)
	else:
		push_error("ERRO: /root/PlayersGlobal não encontrado.")
		return

	# Backup forte: mesmo se o autoload falhar, a play ainda recebe.
	get_tree().set_meta("fut_total_players", total_players)
	get_tree().set_meta("fut_cores_players", cores_selecionadas)

	print("================================")
	print("OPENING VAI ABRIR PLAY")
	print("TOTAL PLAYERS SELECIONADO: ", total_players)
	print("GLOBAL TOTAL: ", players_global.get("total_players_futebol"))
	print("META TOTAL: ", get_tree().get_meta("fut_total_players"))
	print("================================")

	if audio_fundo:
		audio_fundo.stop()

	get_tree().change_scene(CENA_JOGO)


func _rgb_player(index: int) -> Array:
	match index:
		0:
			return [0, 0, 255]       # Player 1 - azul forte
		1:
			return [0, 255, 0]       # Player 2 - verde forte
		2:
			return [255, 0, 0]       # Player 3 - vermelho forte
		3:
			return [255, 255, 0]     # Player 4 - amarelo forte

	return [255, 255, 255]


func _rgb_copa() -> Array:
	# Dourado padrão do modo Copa (LED físico).
	return [255, 165, 0]


func _rgb_copa_forte() -> Array:
	# Dourado mais forte para a confirmação do modo Copa.
	return [255, 210, 0]


func _leds_todos_cor_player(index_player: int) -> void:
	var rgb = _rgb_player_suave(index_player)
	var partes: Array = []

	for letra in LEDS_LETRAS:
		partes.append("%s=%d,%d,%d" % [
			letra,
			rgb[0],
			rgb[1],
			rgb[2]
		])

	_serial_write_opening("SET:" + PoolStringArray(partes).join(";"))


func _leds_atrativo_aleatorio() -> void:
	_leds_atrativo_profissional()


func _animacao_leds_players_confirmados() -> void:
	for i in range(total_players):
		_leds_todos_cor_player(i)
		yield(get_tree().create_timer(0.55), "timeout")

	# Pisca todos coloridos antes de apagar.
	var mapa = {}
	for i in range(LEDS_TOTAL):
		mapa[i] = _rgb_player_suave(i % total_players)

	_set_leds_mapa_rgb(mapa)
	yield(get_tree().create_timer(0.55), "timeout")

	_serial_write_opening("OFF")
	yield(get_tree().create_timer(0.18), "timeout")



func _abrir_serial_arduino_opening() -> void:
	# TV Box: o Arduino Nano é do autoload Arduino (USB); não há ponte.
	if not USAR_ARDUINO:
		return
	_serial_write_opening("OFF")


func _iniciar_ponte_powershell_opening() -> void:
	pass  # TV Box: sem PowerShell; o autoload Arduino cuida da USB.


func _serial_write_opening(texto: String) -> void:
	if not USAR_ARDUINO:
		return
	Arduino.enviar(texto)


func _exit_tree() -> void:
	_serial_write_opening("OFF")
	_parar_good_player_patrocinadores()

	if USAR_PONTE_POWERSHELL and caminho_fila_arduino != "":
		var nome_arquivo = "%020d_EXIT.cmd" % Time.get_ticks_msec()
		var caminho_final = caminho_fila_arduino.plus_file(nome_arquivo)

		var f = Compat.abrir_arquivo(caminho_final, File.WRITE)
		if f:
			f.store_string("__EXIT__")
			f.close()

	if audio_fundo:
		audio_fundo.stop()



func _rgb_player_suave(index: int) -> Array:
	# Cores fortes para LED físico.
	# Iguais às cores reais usadas no jogo:
	# Player 1: azul forte
	# Player 2: verde forte
	# Player 3: vermelho forte
	# Player 4: amarelo forte

	match index:
		0:
			return [0, 0, 255]       # azul forte
		1:
			return [0, 255, 0]       # verde forte
		2:
			return [255, 0, 0]       # vermelho forte
		3:
			return [255, 255, 0]     # amarelo forte

	return [255, 255, 255]



func _set_leds_por_indices(indices: Array, rgb: Array) -> void:
	var partes: Array = []

	for index_led in indices:
		if index_led < 0 or index_led >= LEDS_TOTAL:
			continue

		partes.append("%s=%d,%d,%d" % [
			LEDS_LETRAS[index_led],
			rgb[0],
			rgb[1],
			rgb[2]
		])

	if partes.empty():
		_serial_write_opening("OFF")
	else:
		_serial_write_opening("SET:" + PoolStringArray(partes).join(";"))



func _set_leds_todos_rgb(rgb: Array) -> void:
	var partes: Array = []

	for letra in LEDS_LETRAS:
		partes.append("%s=%d,%d,%d" % [
			letra,
			rgb[0],
			rgb[1],
			rgb[2]
		])

	_serial_write_opening("SET:" + PoolStringArray(partes).join(";"))


func _set_leds_mapa_rgb(mapa: Dictionary) -> void:
	var partes: Array = []

	for i in range(LEDS_TOTAL):
		if not mapa.has(i):
			continue

		var rgb: Array = mapa[i]

		partes.append("%s=%d,%d,%d" % [
			LEDS_LETRAS[i],
			int(rgb[0]),
			int(rgb[1]),
			int(rgb[2])
		])

	if partes.empty():
		_serial_write_opening("OFF")
	else:
		_serial_write_opening("SET:" + PoolStringArray(partes).join(";"))



func _reiniciar_led_atrativo(delay: float = LED_ATRATIVO_REINICIO_DELAY) -> void:
	_led_atrativo_etapa = 0
	_led_atrativo_intervalo = LED_FLUXO_INTERVALO
	_led_atrativo_timer = delay



func _leds_atrativo_abertura_forte() -> void:
	if escolhendo_players or iniciando_jogo or copa_modal_aberto:
		return

	_serial_write_opening("OFF")

	_led_atrativo_intervalo = LED_FLUXO_INTERVALO
	_led_atrativo_etapa = 0

	# Mostra o primeiro LED imediatamente.
	_leds_fluxo_ida_volta_ag(0)

	# Próximo passo respeita o tempo que você colocou em LED_FLUXO_INTERVALO.
	_led_atrativo_etapa = 1
	_led_atrativo_timer = LED_FLUXO_INTERVALO



func _leds_atrativo_profissional() -> void:
	if escolhendo_players or iniciando_jogo or copa_modal_aberto:
		return

	var fluxo_total: int = LED_FLUXO_ORDEM_AG.size()

	# =========================================================
	# PRIMEIRO MOMENTO:
	# Onda A → B → C → D → E → F → G → F → E → D → C → B → A
	# =========================================================
	if _led_atrativo_etapa < fluxo_total:
		_leds_fluxo_ida_volta_ag(_led_atrativo_etapa)
		_led_atrativo_intervalo = LED_FLUXO_INTERVALO
		_led_atrativo_etapa += 1
		return

	# Depois da onda, entra no seu atrativo antigo.
	var etapa_normal: int = _led_atrativo_etapa - fluxo_total

	match etapa_normal:
		0:
			_set_leds_todos_rgb(_rgb_player_suave(0))
			_led_atrativo_intervalo = 0.85

		1:
			_set_leds_todos_rgb(_rgb_player_suave(1))
			_led_atrativo_intervalo = 0.85

		2:
			_set_leds_todos_rgb(_rgb_player_suave(2))
			_led_atrativo_intervalo = 0.85

		3:
			_set_leds_todos_rgb(_rgb_player_suave(3))
			_led_atrativo_intervalo = 0.85

		4:
			var mapa = {}
			for i in range(LEDS_TOTAL):
				mapa[i] = _rgb_player_suave(i % 4)
			_set_leds_mapa_rgb(mapa)
			_led_atrativo_intervalo = 0.95

		5:
			var mapa = {}
			for i in range(LEDS_TOTAL):
				mapa[i] = _rgb_player_suave((LEDS_TOTAL - 1 - i) % 4)
			_set_leds_mapa_rgb(mapa)
			_led_atrativo_intervalo = 0.95

		6:
			var mapa = {}
			for i in range(LEDS_TOTAL):
				if i < 4:
					mapa[i] = _rgb_player_suave(0)
				else:
					mapa[i] = _rgb_player_suave(1)
			_set_leds_mapa_rgb(mapa)
			_led_atrativo_intervalo = 0.85

		7:
			var mapa = {}
			for i in range(LEDS_TOTAL):
				if i < 4:
					mapa[i] = _rgb_player_suave(2)
				else:
					mapa[i] = _rgb_player_suave(3)
			_set_leds_mapa_rgb(mapa)
			_led_atrativo_intervalo = 0.85

		8:
			var mapa = {}
			for i in range(LEDS_TOTAL):
				if i % 2 == 0:
					mapa[i] = _rgb_player_suave(0)
				else:
					mapa[i] = _rgb_player_suave(3)
			_set_leds_mapa_rgb(mapa)
			_led_atrativo_intervalo = 0.75

		9:
			var mapa = {}
			for i in range(LEDS_TOTAL):
				if i % 2 == 0:
					mapa[i] = _rgb_player_suave(1)
				else:
					mapa[i] = _rgb_player_suave(2)
			_set_leds_mapa_rgb(mapa)
			_led_atrativo_intervalo = 0.75

		10:
			var mapa = {}
			var usados: Array = []

			while usados.size() < 5:
				var index_led = Compat.randi_range(0, LEDS_TOTAL - 1)

				if usados.has(index_led):
					continue

				usados.append(index_led)
				mapa[index_led] = _rgb_player_suave(Compat.randi_range(0, 3))

			_set_leds_mapa_rgb(mapa)
			_led_atrativo_intervalo = 0.80

		11:
			var mapa = {}
			for i in range(LEDS_TOTAL):
				mapa[i] = _rgb_player_suave(Compat.randi_range(0, 3))
			_set_leds_mapa_rgb(mapa)
			_led_atrativo_intervalo = 1.00

		_:
			_led_atrativo_etapa = 0
			_led_atrativo_intervalo = LED_FLUXO_INTERVALO
			return

	_led_atrativo_etapa += 1

	# 13 etapas da onda + 12 etapas antigas.
	if _led_atrativo_etapa >= fluxo_total + 12:
		_led_atrativo_etapa = 0
		_led_atrativo_intervalo = LED_FLUXO_INTERVALO



func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		return

	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		return


func _aguardar_ponte_opening_pronta(timeout_seg: float = 4.5) -> bool:
	return true  # TV Box: o autoload Arduino conecta sozinho.


func _criar_loading_opening(titulo_txt: String, sub_txt: String) -> void:
	if opening_loading_layer != null and is_instance_valid(opening_loading_layer):
		return

	opening_loading_layer = CanvasLayer.new()
	opening_loading_layer.layer = 900
	add_child(opening_loading_layer)

	opening_loading_root = Control.new()
	opening_loading_root.set_anchors_preset(Control.PRESET_WIDE)
	opening_loading_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opening_loading_layer.add_child(opening_loading_root)

	var tela = get_viewport_rect().size

	var fundo_base := ColorRect.new()
	fundo_base.set_anchors_preset(Control.PRESET_WIDE)
	fundo_base.color = Color(0.015, 0.075, 0.035, 1.0)
	fundo_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opening_loading_root.add_child(fundo_base)
	
	# Imagem de fundo da tela de carregamento (atrás de tudo).
	if ResourceLoader.exists(IMAGEM_LOADING_OPENING):
		var fundo_img := TextureRect.new()
		fundo_img.set_anchors_preset(Control.PRESET_WIDE)
		fundo_img.texture = load(IMAGEM_LOADING_OPENING)
		fundo_img.expand = true
		fundo_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		fundo_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		opening_loading_root.add_child(fundo_img)

	var brilho_amarelo := ColorRect.new()
	brilho_amarelo.set_anchors_preset(Control.PRESET_WIDE)
	brilho_amarelo.color = Color(1.0, 0.78, 0.05, 0.10)
	brilho_amarelo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opening_loading_root.add_child(brilho_amarelo)

	var vinheta := ColorRect.new()
	vinheta.set_anchors_preset(Control.PRESET_WIDE)
	vinheta.color = Color(0, 0, 0, 0.18)
	vinheta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opening_loading_root.add_child(vinheta)


	# Painel limpo de carregamento, sem logos ou apresentação de patrocinadores.
	var loading_panel := Panel.new()
	loading_panel.rect_size = Vector2(tela.x * 0.70, 230.0)
	loading_panel.rect_position = Vector2((tela.x - loading_panel.rect_size.x) * 0.5, (tela.y - loading_panel.rect_size.y) * 0.5)
	loading_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opening_loading_root.add_child(loading_panel)

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.02, 0.26, 0.10, 1.0)
	st.border_color = Color(1.0, 0.86, 0.05, 0.95)
	st.set_border_width_all(4)
	st.set_corner_radius_all(0)          # quadrado
	st.shadow_color = Color(1.0, 0.82, 0.05, 0.55)
	st.shadow_size = 36
	st.shadow_offset = Vector2.ZERO
	loading_panel.add_stylebox_override("panel", st)

	opening_loading_label = _label_loading_opening(titulo_txt, 42, Color.white, Color(0.1, 0.75, 1.0))
	opening_loading_label.rect_position = Vector2(20, 42)
	opening_loading_label.rect_size = Vector2(loading_panel.rect_size.x - 40, 62)
	loading_panel.add_child(opening_loading_label)

	opening_loading_sub = _label_loading_opening(sub_txt, 20, Color(0.82, 0.92, 1.0))
	opening_loading_sub.rect_position = Vector2(20, 126)
	opening_loading_sub.rect_size = Vector2(loading_panel.rect_size.x - 40, 38)
	loading_panel.add_child(opening_loading_sub)

	# Loading visual limpo:
	# sem texto embaixo, sem barra e sem porcentagem.
	# A porcentagem continua existindo internamente para controlar o fluxo.
	opening_loading_pct = null
	opening_loading_barra = null
	opening_loading_barra_max_w = 0.0
	opening_loading_frac = 0.0


func _iniciar_timer_patrocinadores_automatico() -> void:
	if patro_replay_timer != null and is_instance_valid(patro_replay_timer):
		patro_replay_timer.stop()
		patro_replay_timer.queue_free()

	patro_replay_timer = Timer.new()
	patro_replay_timer.wait_time = PATRO_REPLAY_INTERVALO
	patro_replay_timer.one_shot = false
	patro_replay_timer.autostart = false
	add_child(patro_replay_timer)

	patro_replay_timer.connect("timeout", self, "_on_timer_patrocinadores_automatico")
	patro_replay_timer.start()


func _on_timer_patrocinadores_automatico() -> void:
	if patro_replay_ativo:
		return

	if opening_loading_layer != null:
		return

	if escolhendo_players or iniciando_jogo or copa_modal_aberto:
		return

	if root == null or not is_instance_valid(root):
		return

	_rodar_patrocinadores_automatico()


func _rodar_patrocinadores_automatico() -> void:
	var _g3_estado = null
	if patro_replay_ativo:
		return

	var imagens = _buscar_imagens_patrocinadores_loading()

	if imagens.empty():
		return

	patro_replay_ativo = true

	# Enquanto mostra os patrocinadores, para o efeito atrativo dos LEDs.
	_serial_write_opening("OFF")

	# Toca good_player.mp3 quando os patrocinadores começam a passar.
	_tocar_good_player_patrocinadores(true)

	_criar_overlay_patrocinadores_automatico()

	yield(get_tree().create_timer(0.20), "timeout")

	for caminho in imagens:
		if not patro_replay_ativo:
			break

		if patro_replay_stage == null or not is_instance_valid(patro_replay_stage):
			break

		_g3_estado = _animar_logo_patrocinador_em_stage(patro_replay_stage, caminho)
		if _g3_estado is GDScriptFunctionState:
			_g3_estado = yield(_g3_estado, "completed")

	if patro_replay_stage != null and is_instance_valid(patro_replay_stage):
		_g3_estado = _mostrar_grade_final_patrocinadores_em_stage(
			patro_replay_stage,
			imagens,
			PATRO_REPLAY_TEMPO_GRADE_FINAL
		)
		if _g3_estado is GDScriptFunctionState:
			_g3_estado = yield(_g3_estado, "completed")

	_g3_estado = _fechar_overlay_patrocinadores_automatico()
	if _g3_estado is GDScriptFunctionState:
		_g3_estado = yield(_g3_estado, "completed")

	_parar_good_player_patrocinadores()

	patro_replay_ativo = false
	_reiniciar_led_atrativo()


func _criar_overlay_patrocinadores_automatico() -> void:
	if patro_replay_layer != null and is_instance_valid(patro_replay_layer):
		patro_replay_layer.queue_free()

	patro_replay_layer = CanvasLayer.new()
	patro_replay_layer.layer = 850
	add_child(patro_replay_layer)

	patro_replay_root = Control.new()
	patro_replay_root.set_anchors_preset(Control.PRESET_WIDE)
	patro_replay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patro_replay_root.modulate = Color(1, 1, 1, 0)
	patro_replay_layer.add_child(patro_replay_root)

	var tela = get_viewport_rect().size

	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_WIDE)
	fundo.color = Color(0, 0, 0, 0.82)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patro_replay_root.add_child(fundo)

	# Usa a imagem de fundo do opening, mas sem barra de carregamento.
	if ResourceLoader.exists(IMAGEM_LOADING_OPENING):
		var fundo_img := TextureRect.new()
		fundo_img.set_anchors_preset(Control.PRESET_WIDE)
		fundo_img.texture = load(IMAGEM_LOADING_OPENING)
		fundo_img.expand = true
		fundo_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		fundo_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fundo_img.modulate = Color(1, 1, 1, 0.72)
		patro_replay_root.add_child(fundo_img)

	var vinheta := ColorRect.new()
	vinheta.set_anchors_preset(Control.PRESET_WIDE)
	vinheta.color = Color(0, 0, 0, 0.26)
	vinheta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patro_replay_root.add_child(vinheta)

	patro_replay_panel = Panel.new()
	patro_replay_panel.rect_size = Vector2(tela.x * LOADING_MODAL_W_RATIO, tela.y * LOADING_MODAL_H_RATIO)
	patro_replay_panel.rect_position = Vector2(
		(tela.x - patro_replay_panel.rect_size.x) * 0.5,
		(tela.y - patro_replay_panel.rect_size.y) * 0.5 - 8.0
	)
	patro_replay_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patro_replay_root.add_child(patro_replay_panel)

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.02, 0.26, 0.10, 1.0)
	st.border_color = Color(1.0, 0.86, 0.05, 0.95)
	st.set_border_width_all(4)
	st.set_corner_radius_all(0)
	st.shadow_color = Color(1.0, 0.82, 0.05, 0.55)
	st.shadow_size = 36
	st.shadow_offset = Vector2.ZERO
	patro_replay_panel.add_stylebox_override("panel", st)

	if ResourceLoader.exists(IMAGEM_FUNDO_MODAL_VERDE):
		var fundo_modal := TextureRect.new()
		fundo_modal.rect_position = Vector2(4, 4)
		fundo_modal.rect_size = patro_replay_panel.rect_size - Vector2(8, 8)
		fundo_modal.texture = load(IMAGEM_FUNDO_MODAL_VERDE)
		fundo_modal.expand = true
		fundo_modal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		fundo_modal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		patro_replay_panel.add_child(fundo_modal)

	var titulo := Label.new()
	titulo.text = "PATROCINADORES"
	titulo.rect_position = Vector2(0, 16)
	titulo.rect_size = Vector2(patro_replay_panel.rect_size.x, 50)
	titulo.align = Label.ALIGN_CENTER
	titulo.valign = Label.VALIGN_CENTER
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Compat.tamanho(titulo, 22)
	titulo.add_color_override("font_color", Color.white)
	titulo.add_color_override("font_color_shadow", Color(1.0, 0.85, 0.05))
	titulo.add_constant_override("shadow_offset_x", 0)
	titulo.add_constant_override("shadow_offset_y", 0)

	if fonte_orbitron:
		Compat.fonte(titulo, fonte_orbitron)

	patro_replay_panel.add_child(titulo)

	patro_replay_stage = Control.new()
	patro_replay_stage.rect_position = Vector2(28, 72)
	patro_replay_stage.rect_size = Vector2(patro_replay_panel.rect_size.x - 56, patro_replay_panel.rect_size.y - 116)
	patro_replay_stage.rect_clip_content = true
	patro_replay_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patro_replay_panel.add_child(patro_replay_stage)

	var t = create_tween()
	t.tween_property(patro_replay_root, "modulate", Color.white, 0.25)


func _fechar_overlay_patrocinadores_automatico() -> void:
	if patro_replay_root != null and is_instance_valid(patro_replay_root):
		var t = create_tween()
		t.tween_property(patro_replay_root, "modulate", Color(1, 1, 1, 0), 0.28)
		yield(t, "finished")

	if patro_replay_layer != null and is_instance_valid(patro_replay_layer):
		patro_replay_layer.queue_free()

	patro_replay_layer = null
	patro_replay_root = null
	patro_replay_panel = null
	patro_replay_stage = null


func _limpar_stage_generico(stage: Control) -> void:
	if stage == null or not is_instance_valid(stage):
		return

	for child in stage.get_children():
		stage.remove_child(child)
		child.queue_free()


func _animar_logo_patrocinador_em_stage(stage: Control, caminho: String) -> void:
	if stage == null or not is_instance_valid(stage):
		return

	_limpar_stage_generico(stage)

	var stage_size = stage.rect_size

	var card_w = clamp(stage_size.x * 0.74, 520.0, 980.0)
	var card_h = clamp(stage_size.y * 0.58, 240.0, 390.0)

	var card = _criar_card_patrocinador_modal_loading(caminho, Vector2(card_w, card_h))
	stage.add_child(card)

	var x = (stage_size.x - card_w) * 0.5
	var y_inicio = -card_h - 60.0
	var y_centro = (stage_size.y - card_h) * 0.5
	var y_fim = stage_size.y + 70.0

	card.rect_position = Vector2(x, y_inicio)
	card.rect_scale = Vector2(0.94, 0.94)
	card.modulate = Color(1, 1, 1, 0)

	var t = create_tween()

	t.tween_property(card, Compat.prop(card, "position:y"), y_centro, LOADING_PATRO_ENTRADA_TEMPO) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	t.parallel().tween_property(card, "modulate", Color.white, LOADING_PATRO_ENTRADA_TEMPO * 0.70) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	t.parallel().tween_property(card, Compat.prop(card, "scale"), Vector2.ONE, LOADING_PATRO_ENTRADA_TEMPO) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	t.tween_interval(LOADING_PATRO_PARADO_TEMPO)

	t.tween_property(card, Compat.prop(card, "position:y"), y_fim, LOADING_PATRO_SAIDA_TEMPO) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	t.parallel().tween_property(card, "modulate", Color(1, 1, 1, 0), LOADING_PATRO_SAIDA_TEMPO * 0.75) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	t.parallel().tween_property(card, Compat.prop(card, "scale"), Vector2(0.96, 0.96), LOADING_PATRO_SAIDA_TEMPO) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	yield(t, "finished")

	if card != null and is_instance_valid(card):
		card.queue_free()

	yield(get_tree(), "idle_frame")


func _mostrar_grade_final_patrocinadores_em_stage(stage: Control, imagens: Array, tempo_final: float) -> void:
	if stage == null or not is_instance_valid(stage):
		return

	_limpar_stage_generico(stage)

	if imagens.empty():
		return

	var stage_size = stage.rect_size

	var qtd = imagens.size()
	var cols = Compat.ceili(sqrt(float(qtd)))
	cols = int(max(cols, 1))

	var rows = Compat.ceili(float(qtd) / float(cols))
	rows = int(max(rows, 1))

	var gap := 14.0
	var card_w = (stage_size.x - (gap * float(cols - 1))) / float(cols)
	var card_h = (stage_size.y - (gap * float(rows - 1))) / float(rows)

	card_w = clamp(card_w, 120.0, 260.0)
	card_h = clamp(card_h, 70.0, 140.0)

	var grid_w = (card_w * float(cols)) + (gap * float(cols - 1))
	var grid_h = (card_h * float(rows)) + (gap * float(rows - 1))

	var grid := GridContainer.new()
	grid.columns = cols
	grid.rect_position = Vector2(
		(stage_size.x - grid_w) * 0.5,
		(stage_size.y - grid_h) * 0.5
	)
	grid.rect_size = Vector2(grid_w, grid_h)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_constant_override("h_separation", int(gap))
	grid.add_constant_override("v_separation", int(gap))
	stage.add_child(grid)

	var delay := 0.0

	for caminho in imagens:
		var card = _criar_card_patrocinador_mini_loading(caminho, Vector2(card_w, card_h))
		grid.add_child(card)

		card.modulate = Color(1, 1, 1, 0)
		card.rect_scale = Vector2(0.94, 0.94)

		var t = create_tween()
		t.set_parallel(true)
		t.tween_property(card, "modulate", Color.white, 0.25).set_delay(delay)
		t.tween_property(card, Compat.prop(card, "scale"), Vector2.ONE, 0.25).set_delay(delay) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		delay += 0.035

	yield(get_tree().create_timer(tempo_final), "timeout")


func _label_loading_opening(txt: String, tam: int, cor: Color, sombra: Color = Color.transparent) -> Label:
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


func _aplicar_frac_loading_opening(v: float) -> void:
	var frac = clamp(v, 0.0, 1.0)

	if opening_loading_barra and is_instance_valid(opening_loading_barra):
		opening_loading_barra.rect_size.x = max(opening_loading_barra_max_w * frac, 6.0)

	if opening_loading_pct and is_instance_valid(opening_loading_pct):
		opening_loading_pct.text = "%d%%" % int(round(frac * 100.0))


func _set_loading_opening(p: float, texto: String, dur: float = 0.25) -> void:
	if opening_loading_layer == null or not is_instance_valid(opening_loading_layer):
		return

	var alvo = clamp(p, 0.0, 1.0)

	if opening_loading_sub and is_instance_valid(opening_loading_sub):
		opening_loading_sub.text = texto

	if opening_loading_tween != null:
		opening_loading_tween.kill()

	var inicio = opening_loading_frac
	opening_loading_frac = alvo

	opening_loading_tween = create_tween()
	opening_loading_tween.tween_method(
		self, "_aplicar_frac_loading_opening",
		inicio,
		alvo,
		dur
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _remover_loading_opening() -> void:
	_parar_good_player_patrocinadores()
	
	if opening_loading_layer == null or not is_instance_valid(opening_loading_layer):
		return

	if opening_patro_timer != null and is_instance_valid(opening_patro_timer):
		opening_patro_timer.stop()
		opening_patro_timer.queue_free()

	opening_patro_timer = null

	_limpar_stage_patrocinadores_loading()

	opening_patro_stage = null
	opening_patro_panel = null
	opening_patro_grid = null
	opening_patro_info = null
	opening_patro_imagens.clear()
	opening_patro_pagina = 0
	opening_patro_por_pagina = 1
	opening_patro_cols = 1
	opening_patro_rows = 1
	opening_patro_card_size = Vector2(150, 70)
	opening_patro_index = 0

	_aplicar_frac_loading_opening(1.0)

	if opening_loading_tween != null:
		opening_loading_tween.kill()

	opening_loading_tween = null

	if opening_loading_root != null and is_instance_valid(opening_loading_root):
		var t = create_tween()
		t.tween_property(opening_loading_root, "modulate", Color(1, 1, 1, 0), 0.35)
		yield(t, "finished")

	if opening_loading_layer != null and is_instance_valid(opening_loading_layer):
		opening_loading_layer.queue_free()

	opening_loading_layer = null
	opening_loading_root = null
	opening_loading_label = null
	opening_loading_sub = null
	opening_loading_pct = null
	opening_loading_barra = null
	opening_loading_barra_max_w = 0.0
	opening_loading_frac = 0.0



func _buscar_imagens_patrocinadores_loading() -> Array:
	var imagens: Array = []

	for caminho in PATROCINADORES_FIXOS:
		if ResourceLoader.exists(caminho):
			if not imagens.has(caminho):
				imagens.append(caminho)
		else:
			push_warning("Patrocinador da lista fixa não encontrado: " + caminho)

	print("PATROCINADORES (lista fixa): ", imagens.size(), " de ", PATROCINADORES_FIXOS.size())
	return imagens


func _mostrar_patrocinadores_depois_do_loading() -> void:
	var _g3_estado = null
	if opening_loading_layer == null or not is_instance_valid(opening_loading_layer):
		return

	if opening_patro_stage == null or not is_instance_valid(opening_patro_stage):
		return

	opening_patro_imagens = _buscar_imagens_patrocinadores_loading()

	if opening_patro_imagens.empty():
		if opening_patro_info:
			opening_patro_info.text = "SISTEMA PRONTO"
		yield(get_tree().create_timer(0.80), "timeout")
		return

	var titulo = opening_patro_panel.get_node_or_null("TituloPatroLoading") as Label
	if titulo:
		titulo.text = "PATROCINADORES"

	if opening_patro_info:
		opening_patro_info.visible = false

	# Toca good_player.mp3 quando os patrocinadores começam a passar.
	_tocar_good_player_patrocinadores(true)

	_set_loading_opening(1.0, "APRESENTANDO PATROCINADORES...", 0.18)

	yield(get_tree().create_timer(0.25), "timeout")

	# Mostra todos, um por vez, com rolagem mais lenta.
	for caminho in opening_patro_imagens:
		_g3_estado = _animar_logo_patrocinador_loading(caminho)
		if _g3_estado is GDScriptFunctionState:
			_g3_estado = yield(_g3_estado, "completed")

	# No final, mostra todos juntos por um tempo.
	_g3_estado = _mostrar_grade_final_patrocinadores_loading()
	if _g3_estado is GDScriptFunctionState:
		_g3_estado = yield(_g3_estado, "completed")

	# Para o som ao sair da apresentação dos patrocinadores.
	_parar_good_player_patrocinadores()


func _limpar_stage_patrocinadores_loading() -> void:
	if opening_patro_stage == null or not is_instance_valid(opening_patro_stage):
		return

	for child in opening_patro_stage.get_children():
		opening_patro_stage.remove_child(child)
		child.queue_free()


func _animar_logo_patrocinador_loading(caminho: String) -> void:
	if opening_patro_stage == null or not is_instance_valid(opening_patro_stage):
		return

	var stage_size = opening_patro_stage.rect_size

	var card_w = clamp(stage_size.x * 0.74, 520.0, 980.0)
	var card_h = clamp(stage_size.y * 0.58, 240.0, 390.0)

	var card = _criar_card_patrocinador_modal_loading(caminho, Vector2(card_w, card_h))
	opening_patro_stage.add_child(card)

	var x = (stage_size.x - card_w) * 0.5
	var y_inicio = -card_h - 60.0
	var y_centro = (stage_size.y - card_h) * 0.5
	var y_fim = stage_size.y + 70.0

	card.rect_position = Vector2(x, y_inicio)
	card.rect_scale = Vector2(0.94, 0.94)
	card.modulate = Color(1, 1, 1, 0)

	var t = create_tween()

	t.tween_property(card, Compat.prop(card, "position:y"), y_centro, LOADING_PATRO_ENTRADA_TEMPO) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	t.parallel().tween_property(card, "modulate", Color.white, LOADING_PATRO_ENTRADA_TEMPO * 0.70) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	t.parallel().tween_property(card, Compat.prop(card, "scale"), Vector2.ONE, LOADING_PATRO_ENTRADA_TEMPO) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	t.tween_interval(LOADING_PATRO_PARADO_TEMPO)

	t.tween_property(card, Compat.prop(card, "position:y"), y_fim, LOADING_PATRO_SAIDA_TEMPO) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	t.parallel().tween_property(card, "modulate", Color(1, 1, 1, 0), LOADING_PATRO_SAIDA_TEMPO * 0.75) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	t.parallel().tween_property(card, Compat.prop(card, "scale"), Vector2(0.96, 0.96), LOADING_PATRO_SAIDA_TEMPO) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	yield(t, "finished")

	if card != null and is_instance_valid(card):
		card.queue_free()

	yield(get_tree(), "idle_frame")


func _criar_card_patrocinador_modal_loading(caminho: String, tamanho: Vector2) -> Panel:
	var card := Panel.new()
	card.rect_size = tamanho
	card.rect_min_size = tamanho
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.rect_clip_content = true

	var fundo_especial: Color = _fundo_logo_loading(caminho)
	var tem_especial: bool = fundo_especial.a > 0.0
	var claro: bool = tem_especial and (fundo_especial.r + fundo_especial.g + fundo_especial.b) > 1.5

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.03, 0.05, 0.07, 1.0)
	st.border_color = Color(0.1, 0.75, 1.0, 1.0)
	st.set_border_width_all(3)
	st.set_corner_radius_all(0)          # quadrado
	st.shadow_color = Color(0.1, 0.75, 1.0, 0.75)
	st.shadow_size = 26
	st.shadow_offset = Vector2.ZERO
	card.add_stylebox_override("panel", st)

	# Fundo do card: back.png (quadrado, atrás de tudo).
	if ResourceLoader.exists(IMAGEM_FUNDO_MODAL_OPENING):
		var bg_img := TextureRect.new()
		bg_img.rect_position = Vector2(3, 3)
		bg_img.rect_size = tamanho - Vector2(6, 6)
		bg_img.texture = load(IMAGEM_FUNDO_MODAL_OPENING)
		bg_img.expand = true
		bg_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(bg_img)

	# Efeito de LED correndo na borda.
	_aplicar_led_card(card)

	var margem := 18.0

	var inner := Panel.new()
	inner.rect_position = Vector2(margem, margem)
	inner.rect_size = tamanho - Vector2(margem * 2.0, margem * 2.0)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.rect_clip_content = true
	card.add_child(inner)

	var inner_st := StyleBoxFlat.new()
	inner_st.set_border_width_all(3)
	inner_st.set_corner_radius_all(0)

	if tem_especial:
		# Logos com contraste próprio (bar=preto, corona/michelob=branco).
		inner_st.bg_color = fundo_especial
		inner_st.border_color = Color(0, 0, 0, 0.20) if claro else Color(1, 1, 1, 0.18)
	else:
		inner_st.bg_color = Color(0.98, 0.86, 0.12, 1.0)
		inner_st.border_color = Color(0.0, 0.42, 0.12, 0.95)

	inner.add_stylebox_override("panel", inner_st)

	# Tema verde/amarelo somente nos logos SEM fundo especial.
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

	# Brilho superior sutil (toque moderno).
	var brilho := ColorRect.new()
	brilho.rect_position = Vector2(16, 11)
	brilho.rect_size = Vector2(inner.rect_size.x - 32, 3)
	brilho.color = Color(1, 1, 1, 0.06 if claro else 0.16)
	brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(brilho)

	var tex = load(caminho) as Texture

	if tex != null:
		var pad := 26.0
		if tem_especial:
			pad = 40.0   # mais respiro para o logo sobre o plate sólido

		var img := TextureRect.new()
		img.rect_position = Vector2(pad, pad * 0.70)
		img.rect_size = inner.rect_size - Vector2(pad * 2.0, pad * 1.40)
		img.texture = tex
		img.expand = true
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(img)
	else:
		var erro := Label.new()
		erro.text = "LOGO NÃO CARREGOU"
		erro.set_anchors_preset(Control.PRESET_WIDE)
		erro.align = Label.ALIGN_CENTER
		erro.valign = Label.VALIGN_CENTER
		Compat.tamanho(erro, 18)
		erro.add_color_override("font_color", Color.red)
		inner.add_child(erro)

	return card



func _mostrar_grade_final_patrocinadores_loading() -> void:
	if opening_patro_stage == null or not is_instance_valid(opening_patro_stage):
		return

	_limpar_stage_patrocinadores_loading()

	if opening_patro_imagens.empty():
		return

	var stage_size = opening_patro_stage.rect_size

	var qtd = opening_patro_imagens.size()
	var cols = Compat.ceili(sqrt(float(qtd)))
	cols = int(max(cols, 1))

	var rows = Compat.ceili(float(qtd) / float(cols))
	rows = int(max(rows, 1))

	var gap := 14.0
	var card_w = (stage_size.x - (gap * float(cols - 1))) / float(cols)
	var card_h = (stage_size.y - (gap * float(rows - 1))) / float(rows)

	card_w = clamp(card_w, 120.0, 260.0)
	card_h = clamp(card_h, 70.0, 140.0)

	var grid_w = (card_w * float(cols)) + (gap * float(cols - 1))
	var grid_h = (card_h * float(rows)) + (gap * float(rows - 1))

	opening_patro_grid = GridContainer.new()
	opening_patro_grid.columns = cols
	opening_patro_grid.rect_position = Vector2(
		(stage_size.x - grid_w) * 0.5,
		(stage_size.y - grid_h) * 0.5
	)
	opening_patro_grid.rect_size = Vector2(grid_w, grid_h)
	opening_patro_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opening_patro_grid.add_constant_override("h_separation", int(gap))
	opening_patro_grid.add_constant_override("v_separation", int(gap))
	opening_patro_stage.add_child(opening_patro_grid)

	var delay := 0.0

	for caminho in opening_patro_imagens:
		var card = _criar_card_patrocinador_mini_loading(caminho, Vector2(card_w, card_h))
		opening_patro_grid.add_child(card)

		card.modulate = Color(1, 1, 1, 0)
		card.rect_scale = Vector2(0.94, 0.94)

		var t = create_tween()
		t.set_parallel(true)
		t.tween_property(card, "modulate", Color.white, 0.25).set_delay(delay)
		t.tween_property(card, Compat.prop(card, "scale"), Vector2.ONE, 0.25).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		delay += 0.035

	yield(get_tree().create_timer(LOADING_PATRO_TEMPO_GRADE_FINAL), "timeout")



func _criar_card_patrocinador_mini_loading(caminho: String, tamanho: Vector2) -> Panel:
	var card := Panel.new()
	card.rect_size = tamanho
	card.rect_min_size = tamanho
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.rect_clip_content = true

	var fundo_especial: Color = _fundo_logo_loading(caminho)
	var tem_especial: bool = fundo_especial.a > 0.0

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.03, 0.05, 0.07, 1.0)
	st.border_color = Color(0.1, 0.75, 1.0, 0.95)
	st.set_border_width_all(2)
	st.set_corner_radius_all(0)          # quadrado
	st.shadow_color = Color(0.1, 0.75, 1.0, 0.55)
	st.shadow_size = 12
	st.shadow_offset = Vector2.ZERO
	card.add_stylebox_override("panel", st)

	# Fundo do card: back.png (quadrado, atrás de tudo).
	if ResourceLoader.exists(IMAGEM_FUNDO_MODAL_OPENING):
		var bg_img := TextureRect.new()
		bg_img.rect_position = Vector2(2, 2)
		bg_img.rect_size = tamanho - Vector2(4, 4)
		bg_img.texture = load(IMAGEM_FUNDO_MODAL_OPENING)
		bg_img.expand = true
		bg_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(bg_img)

	# Efeito de LED correndo na borda.
	_aplicar_led_card(card)

	var fundo := ColorRect.new()
	fundo.rect_position = Vector2(6, 6)
	fundo.rect_size = tamanho - Vector2(12, 12)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if tem_especial:
		fundo.color = fundo_especial
	else:
		fundo.color = Color(0.98, 0.86, 0.12, 1.0)

	card.add_child(fundo)

	# Faixa verde só nos logos SEM fundo especial.
	if not tem_especial:
		var faixa := ColorRect.new()
		faixa.rect_position = Vector2(6, 6)
		faixa.rect_size = Vector2((tamanho.x - 12.0) * 0.46, tamanho.y - 12.0)
		faixa.color = Color(0.02, 0.42, 0.14, 1.0)
		faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(faixa)

	var tex = load(caminho) as Texture

	if tex != null:
		var pad := 12.0
		if tem_especial:
			pad = 16.0

		var img := TextureRect.new()
		img.rect_position = Vector2(pad, pad * 0.8)
		img.rect_size = tamanho - Vector2(pad * 2.0, pad * 1.6)
		img.texture = tex
		img.expand = true
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(img)

	return card


#cores de fundo dos patrocinadores
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

	# GA_Logo.png (Guaraná Antártica) -> VERDE da própria marca
	if base.begins_with("ga_") or Compat.contem(base, "guaran"):
		return Color(0.0, 0.60, 0.28, 1.0)

	# stella.png (Stella Artois) -> DOURADO/AMARELO
	if Compat.contem(base, "stella"):
		return Color(0.79, 0.65, 0.18, 1.0)

	# bud.png (Budweiser) -> VERMELHO
	if base == "bud.png" or base.begins_with("bud"):
		return Color(0.86, 0.10, 0.13, 1.0)

	# Sem fundo especial (usa o tema verde/amarelo).
	return Color(0.0, 0.0, 0.0, 0.0)



func _definir_modos() -> void:
	modos_jogo = [
		{
			"id": "ARCADE",
			"titulo": "ARCADE",
			"sub": "1 – 4 PLAYERS",
			"cor": Color(0.1, 1.0, 0.35),
			"acao": "arcade"
		},
		{
			"id": "COPA",
			"titulo": "COPA",
			"sub": "8 – 16 PLAYERS",
			"cor": COR_COPA,
			"acao": "copa"
		}
		# NOVOS MODOS AQUI
	]


func _offsets_carrossel(size: int) -> Array:
	if size <= 1:
		return []
	if size == 2:
		return [1]
	if size <= 4:
		return [-1, 1]
	return [-2, -1, 1, 2]



func _montar_carrossel(animar: bool = false) -> void:
	if carrossel_root == null or not is_instance_valid(carrossel_root):
		return

	for c in carrossel_root.get_children():
		c.queue_free()

	var vp: Vector2 = get_viewport_rect().size
	var cx: float = vp.x * 0.5

	# Mais baixo na tela.
	var cy: float = vp.y - 135.0

	var size: int = modos_jogo.size()

	if size == 0:
		return

	for o in _offsets_carrossel(size):
		_criar_card_modo(int(o), cx, cy)

	_criar_card_modo(0, cx, cy)

	# Dots também descem.
	_criar_dots_carrossel(cx, vp.y - 36.0)

	if animar:
		carrossel_root.rect_position.x = 54.0

		var t = create_tween()
		t.tween_property(carrossel_root, "rect_position:x", 0.0, 0.20) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		carrossel_root.rect_position.x = 0.0


func _criar_card_modo(offset: int, cx: float, cy: float) -> void:
	var size: int = modos_jogo.size()
	var idx: int = ((modo_focado + offset) % size + size) % size
	var modo: Dictionary = modos_jogo[idx]
	var cor: Color = modo.get("cor", COR_COPA)
	var eh_centro: bool = offset == 0

	var step: float = 286.0
	var card_w: float = 320.0
	var card_h: float = 132.0

	var escala: float = 1.0
	var alpha: float = 1.0
	var d: int = abs(offset)

	if d == 1:
		escala = 0.72
		alpha = 0.52
	elif d >= 2:
		escala = 0.52
		alpha = 0.26

	var card := Panel.new()
	card.rect_size = Vector2(card_w, card_h)
	card.rect_pivot_offset = card.rect_size * 0.5
	card.rect_scale = Vector2(escala, escala)
	card.modulate = Color(1, 1, 1, alpha)
	card.rect_position = Vector2(cx + float(offset) * step - card_w * 0.5, cy - card_h * 0.5)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	carrossel_root.add_child(card)

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.0, 0.0, 0.0, 0.34)
	st.border_color = cor
	st.set_border_width_all(4 if eh_centro else 3)
	st.set_corner_radius_all(28)
	st.shadow_color = Color(cor.r, cor.g, cor.b, 0.95 if eh_centro else 0.42)
	st.shadow_size = 26 if eh_centro else 12
	st.shadow_offset = Vector2.ZERO
	card.add_stylebox_override("panel", st)

	var base := Panel.new()
	base.rect_position = Vector2(7, 7)
	base.rect_size = card.rect_size - Vector2(14, 14)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(base)

	var st_base := StyleBoxFlat.new()
	st_base.bg_color = Color(0.012, 0.018, 0.018, 0.97)
	st_base.border_color = Color(cor.r, cor.g, cor.b, 0.45)
	st_base.set_border_width_all(2)
	st_base.set_corner_radius_all(23)
	st_base.shadow_color = Color(0, 0, 0, 0.78)
	st_base.shadow_size = 8
	st_base.shadow_offset = Vector2(0, 4)
	base.add_stylebox_override("panel", st_base)

	var brilho := ColorRect.new()
	brilho.color = Color(1, 1, 1, 0.10)
	brilho.rect_position = Vector2(24, 9)
	brilho.rect_size = Vector2(base.rect_size.x - 48, 3)
	brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(brilho)

	var lbl := Label.new()
	lbl.text = str(modo.get("titulo", "MODO"))
	lbl.align = Label.ALIGN_CENTER
	lbl.valign = Label.VALIGN_CENTER
	lbl.clip_text = true
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if fonte_orbitron:
		Compat.fonte(lbl, fonte_orbitron)

	lbl.add_color_override("font_color", Color.white)
	lbl.add_color_override("font_color_shadow", cor)
	lbl.add_constant_override("shadow_offset_x", 0)
	lbl.add_constant_override("shadow_offset_y", 0)

	if eh_centro:
		lbl.rect_position = Vector2(0, 16)
		lbl.rect_size = Vector2(base.rect_size.x, 44)
		Compat.tamanho(lbl, 36)
		base.add_child(lbl)

		var sub := Label.new()
		sub.text = str(modo.get("sub", ""))
		sub.rect_position = Vector2(0, 62)
		sub.rect_size = Vector2(base.rect_size.x, 22)
		sub.align = Label.ALIGN_CENTER
		sub.valign = Label.VALIGN_CENTER
		sub.clip_text = true
		sub.mouse_filter = Control.MOUSE_FILTER_IGNORE

		if fonte_orbitron:
			Compat.fonte(sub, fonte_orbitron)

		Compat.tamanho(sub, 13)
		sub.add_color_override("font_color", Color(cor.r, cor.g, cor.b, 0.92))
		base.add_child(sub)

		var hint := Label.new()
		hint.text = "▶ START PARA JOGAR"
		hint.rect_position = Vector2(0, base.rect_size.y - 30)
		hint.rect_size = Vector2(base.rect_size.x, 22)
		hint.align = Label.ALIGN_CENTER
		hint.valign = Label.VALIGN_CENTER
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE

		if fonte_orbitron:
			Compat.fonte(hint, fonte_orbitron)

		Compat.tamanho(hint, 12)
		hint.add_color_override("font_color", Color.white)
		hint.add_color_override("font_color_shadow", cor)
		hint.add_constant_override("shadow_offset_x", 0)
		hint.add_constant_override("shadow_offset_y", 0)
		base.add_child(hint)

		var pulso = card.create_tween()
		pulso.set_loops()
		pulso.tween_property(card, "rect_scale", Vector2(1.025, 1.025), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulso.tween_property(card, "rect_scale", Vector2.ONE, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		lbl.rect_position = Vector2(0, (base.rect_size.y - 44) * 0.5)
		lbl.rect_size = Vector2(base.rect_size.x, 44)
		Compat.tamanho(lbl, 27)
		base.add_child(lbl)


func _criar_dots_carrossel(cx: float, y: float) -> void:
	var size: int = modos_jogo.size()
	var dot: float = 10.0
	var gap: float = 11.0
	var total: float = float(size) * dot + float(size - 1) * gap
	var x0: float = cx - total * 0.5

	for i in range(size):
		var cor: Color = modos_jogo[i].get("cor", Color.white)

		var p := Panel.new()
		p.rect_position = Vector2(x0 + float(i) * (dot + gap), y)
		p.rect_size = Vector2(dot, dot)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var s := StyleBoxFlat.new()
		s.set_corner_radius_all(6)
		s.shadow_offset = Vector2.ZERO

		if i == modo_focado:
			s.bg_color = cor
			s.shadow_color = Color(cor.r, cor.g, cor.b, 0.85)
			s.shadow_size = 10
		else:
			s.bg_color = Color(1, 1, 1, 0.18)
			s.shadow_size = 0

		p.add_stylebox_override("panel", s)
		carrossel_root.add_child(p)



func _avancar_carrossel() -> void:
	# Durante a apresentação dos patrocinadores, o SELECT não muda o modo.
	if patro_replay_ativo:
		return

	if modos_jogo.size() <= 1:
		return

	modo_focado = (modo_focado + 1) % modos_jogo.size()

	_tocar_som_navegacao_modo()

	_montar_carrossel(true)


func _confirmar_modo_focado() -> void:
	# Durante a apresentação dos patrocinadores, o START não confirma modo.
	if patro_replay_ativo:
		return

	if modos_jogo.empty():
		return

	var modo: Dictionary = modos_jogo[modo_focado]
	var acao: String = str(modo.get("acao", ""))

	if not ArcadeData.consumir_credito():
		_atualizar_status_arcade("SEM CRÉDITO • PRESSIONE L3")
		_set_leds_todos_rgb([255, 0, 0])
		_reiniciar_led_atrativo(0.8)
		return
	ArcadeData.registrar_partida(acao)
	_atualizar_status_arcade("PARTIDA LIBERADA")

	match acao:
		"arcade":
			_abrir_modal_players()
		"copa":
			_entrar_copa_direto()
		"torneio":
			_entrar_torneio_direto()
		_:
			push_warning("Modo sem ação definida: " + str(modo.get("id", "")))


func _criar_status_arcade() -> void:
	arcade_status_label = Label.new()
	arcade_status_label.rect_position = Vector2(24, 18)
	arcade_status_label.rect_size = Vector2(650, 42)
	Compat.tamanho(arcade_status_label, 20)
	arcade_status_label.add_color_override("font_color", Color.white)
	arcade_status_label.add_color_override("font_color_shadow", Color(0.1, 0.75, 1.0))
	arcade_status_label.add_constant_override("shadow_offset_x", 2)
	arcade_status_label.add_constant_override("shadow_offset_y", 2)
	arcade_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(arcade_status_label)
	_atualizar_status_arcade()


func _atualizar_status_arcade(aviso: String = "") -> void:
	if arcade_status_label == null or not is_instance_valid(arcade_status_label):
		return
	var texto := ""
	if ArcadeData.modo_operacao == "credito":
		if ArcadeData.creditos <= 0:
			texto = "MODO CRÉDITO  •  SEM CRÉDITOS  •  PRESSIONE L3"
			arcade_status_label.add_color_override("font_color", Color(1.0, 0.30, 0.24))
		else:
			texto = "MODO CRÉDITO  •  CRÉDITOS DISPONÍVEIS: %d" % ArcadeData.creditos
			arcade_status_label.add_color_override("font_color", Color(1.0, 0.84, 0.14))
	else:
		texto = "MODO LIVRE  •  PARTIDAS JOGADAS: %d" % ArcadeData.partidas_total
		arcade_status_label.add_color_override("font_color", Color(0.22, 1.0, 0.48))
	if aviso != "":
		texto += "  •  " + aviso
	arcade_status_label.text = texto



# =========================================================
# TRANSIÇÃO MODERNA AO CONFIRMAR UM MODO (COPA / TORNEIO)
# Evita a sensação de travamento: mostra um overlay animado
# enquanto o som toca e a próxima cena carrega.
# =========================================================
func _mostrar_transicao_modo(titulo_txt: String, sub_txt: String, cor: Color) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 950
	add_child(layer)

	var tela = get_viewport_rect().size

	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_WIDE)
	fundo.color = Color(0, 0, 0, 0.0)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fundo)

	# Brilho sutil na cor do modo, cobrindo a tela.
	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_WIDE)
	glow.color = Color(cor.r, cor.g, cor.b, 0.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(glow)

	# Painel central neon.
	var painel := Panel.new()
	painel.rect_size = Vector2(720, 320)
	painel.rect_position = Vector2(
		(tela.x - painel.rect_size.x) * 0.5,
		(tela.y - painel.rect_size.y) * 0.5
	)
	painel.rect_pivot_offset = painel.rect_size * 0.5
	painel.rect_scale = Vector2(0.9, 0.9)
	painel.modulate = Color(1, 1, 1, 0)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(painel)

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.010, 0.014, 0.020, 0.98)
	st.border_color = cor
	st.set_border_width_all(4)
	st.set_corner_radius_all(30)
	st.shadow_color = Color(cor.r, cor.g, cor.b, 0.85)
	st.shadow_size = 50
	st.shadow_offset = Vector2.ZERO
	painel.add_stylebox_override("panel", st)

	# Faixa decorativa no topo.
	var faixa := ColorRect.new()
	faixa.rect_position = Vector2(40, 30)
	faixa.rect_size = Vector2(painel.rect_size.x - 80, 5)
	faixa.color = Color(cor.r, cor.g, cor.b, 0.95)
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(faixa)

	# Título grande.
	var titulo := Label.new()
	titulo.text = titulo_txt
	titulo.rect_position = Vector2(0, 74)
	titulo.rect_size = Vector2(painel.rect_size.x, 80)
	titulo.align = Label.ALIGN_CENTER
	titulo.valign = Label.VALIGN_CENTER
	titulo.clip_text = true
	if fonte_orbitron:
		Compat.fonte(titulo, fonte_orbitron)
	Compat.tamanho(titulo, 58)
	titulo.add_color_override("font_color", Color.white)
	titulo.add_color_override("font_color_shadow", cor)
	titulo.add_constant_override("shadow_offset_x", 0)
	titulo.add_constant_override("shadow_offset_y", 0)
	painel.add_child(titulo)

	# Subtítulo.
	var sub := Label.new()
	sub.text = sub_txt
	sub.rect_position = Vector2(0, 166)
	sub.rect_size = Vector2(painel.rect_size.x, 36)
	sub.align = Label.ALIGN_CENTER
	sub.valign = Label.VALIGN_CENTER
	if fonte_orbitron:
		Compat.fonte(sub, fonte_orbitron)
	Compat.tamanho(sub, 20)
	sub.add_color_override("font_color", Color(cor.r, cor.g, cor.b, 0.95))
	sub.add_color_override("font_color_shadow", cor)
	sub.add_constant_override("shadow_offset_x", 0)
	sub.add_constant_override("shadow_offset_y", 0)
	painel.add_child(sub)

	# Barra que enche (sensação de carregamento).
	var barra_bg := ColorRect.new()
	barra_bg.rect_position = Vector2(110, 228)
	barra_bg.rect_size = Vector2(painel.rect_size.x - 220, 8)
	barra_bg.color = Color(1, 1, 1, 0.12)
	barra_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(barra_bg)

	var barra := ColorRect.new()
	barra.rect_position = barra_bg.rect_position
	barra.rect_size = Vector2(0, 8)
	barra.color = Color(cor.r, cor.g, cor.b, 1.0)
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(barra)

	# Três pontos pulsando.
	var dot_size := 14.0
	var dot_gap := 18.0
	var n_dots := 3
	var total_w = dot_size * float(n_dots) + dot_gap * float(n_dots - 1)
	var dx0 = (painel.rect_size.x - total_w) * 0.5

	for i in range(n_dots):
		var d := Panel.new()
		d.rect_size = Vector2(dot_size, dot_size)
		d.rect_position = Vector2(dx0 + float(i) * (dot_size + dot_gap), 262)
		d.rect_pivot_offset = d.rect_size * 0.5
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var ds := StyleBoxFlat.new()
		ds.bg_color = Color(cor.r, cor.g, cor.b, 0.95)
		ds.set_corner_radius_all(int(dot_size * 0.5))
		ds.shadow_color = Color(cor.r, cor.g, cor.b, 0.60)
		ds.shadow_size = 10
		ds.shadow_offset = Vector2.ZERO
		d.add_stylebox_override("panel", ds)
		painel.add_child(d)

		var dt = d.create_tween()
		dt.set_loops()
		dt.tween_interval(float(i) * 0.12)
		dt.tween_property(d, "rect_scale", Vector2(1.45, 1.45), 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		dt.tween_property(d, "rect_scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		dt.tween_interval(0.26)

	# Entrada animada do overlay.
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(fundo, "color", Color(0, 0, 0, 0.92), 0.22)
	t.tween_property(glow, "color", Color(cor.r, cor.g, cor.b, 0.10), 0.22)
	t.tween_property(painel, "modulate", Color.white, 0.22)
	t.tween_property(painel, "rect_scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Barra enche junto.
	var tb = painel.create_tween()
	tb.tween_property(barra, "rect_size:x", barra_bg.rect_size.x, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	return layer


func _aguardar_transicao_modo(som: AudioStreamPlayer, tempo_min: float, tempo_max: float) -> void:
	var inicio_ms = Time.get_ticks_msec()

	# Garante um tempo mínimo do efeito na tela (para nunca parecer travado).
	while float(Time.get_ticks_msec() - inicio_ms) / 1000.0 < tempo_min:
		yield(get_tree(), "idle_frame")

	# Depois do mínimo, espera o som terminar (com teto de segurança).
	while som != null and som.playing:
		if float(Time.get_ticks_msec() - inicio_ms) / 1000.0 >= tempo_max:
			break
		yield(get_tree(), "idle_frame")



func _entrar_copa_direto() -> void:
	var _g3_estado = null
	if not ResourceLoader.exists(CENA_LOBBY):
		push_error("Cena de lobby não encontrada: " + CENA_LOBBY)
		return

	if iniciando_jogo:
		return

	iniciando_jogo = true
	escolhendo_players = false
	copa_modal_aberto = false

	# LEDs dourados fortes confirmando a entrada na Copa.
	_set_leds_todos_rgb(_rgb_copa_forte())

	# Abaixa a música de fundo para o som da confirmação aparecer bem.
	if audio_fundo and audio_fundo.playing:
		audio_fundo.volume_db = -18.0

	# Efeito visual moderno: o usuário vê na hora que a Copa foi escolhida.
	_mostrar_transicao_modo("MODO COPA", "ABRINDO LOBBY...", COR_COPA)

	if sfx_game_start and sfx_game_start.stream:
		sfx_game_start.stop()
		sfx_game_start.play()

	# Mantém o efeito por um tempo mínimo e espera o som (teto de 2s).
	_g3_estado = _aguardar_transicao_modo(sfx_game_start, 1.1, 2.0)
	if _g3_estado is GDScriptFunctionState:
		_g3_estado = yield(_g3_estado, "completed")

	_serial_write_opening("OFF")

	if audio_fundo:
		audio_fundo.stop()

	print("================================")
	print("MODO COPA CONFIRMADO -> ABRINDO LOBBY")
	print("FAIXA DE JOGADORES: ", COPA_MIN_JOGADORES, " a ", COPA_MAX_JOGADORES)
	print("================================")

	get_tree().change_scene(CENA_LOBBY)



func _entrar_torneio_direto() -> void:
	var _g3_estado = null
	if iniciando_jogo:
		return

	if not ResourceLoader.exists(CENA_TORNEIO):
		push_error("Cena de torneio não encontrada: " + CENA_TORNEIO)
		return

	iniciando_jogo = true
	escolhendo_players = false
	copa_modal_aberto = false
	combo_mural_ativo = false
	combo_indo_mural = false

	_set_leds_todos_rgb(_rgb_torneio_forte())
	yield(get_tree().create_timer(0.12), "timeout")
	_serial_write_opening("OFF")
	yield(get_tree().create_timer(0.06), "timeout")
	_set_leds_todos_rgb(_rgb_torneio_forte())

	if audio_fundo and audio_fundo.playing:
		audio_fundo.volume_db = -18.0

	_mostrar_transicao_modo("MODO TORNEIO", "ABRINDO SETUP 13 – 36 PLAYERS...", COR_TORNEIO)

	if sfx_game_start and sfx_game_start.stream:
		sfx_game_start.stop()
		sfx_game_start.play()

	_g3_estado = _aguardar_transicao_modo(sfx_game_start, 1.1, 2.0)
	if _g3_estado is GDScriptFunctionState:
		_g3_estado = yield(_g3_estado, "completed")

	_serial_write_opening("OFF")

	if audio_fundo:
		audio_fundo.stop()

	print("================================")
	print("MODO TORNEIO CONFIRMADO")
	print("ABRINDO: ", CENA_TORNEIO)
	print("================================")

	get_tree().change_scene(CENA_TORNEIO)



func _rgb_torneio_forte() -> Array:
	return [220, 0, 255] # roxo/magenta forte para LED físico



func _tocar_som_navegacao_modo() -> AudioStreamPlayer:
	# Som único para navegar e confirmar modo.
	# Usa somente player_select.mp3.
	if sfx_player_select and sfx_player_select.stream:
		sfx_player_select.stop()
		sfx_player_select.play()
		return sfx_player_select

	return null



func _tocar_som_confirmar_modo() -> AudioStreamPlayer:
	# Som usado quando aperta START para escolher o modo.
	# Usa game_start.mp3.
	if sfx_game_start and sfx_game_start.stream:
		sfx_game_start.stop()
		sfx_game_start.play()
		return sfx_game_start

	return null



func _confirmar_modo_com_som() -> void:
	# Ao confirmar um modo com START, toca game_start.mp3
	# e espera acabar com teto de segurança.
	var som = _tocar_som_confirmar_modo()

	if som != null:
		var inicio_ms = Time.get_ticks_msec()
		var tempo_maximo := 2.0

		while som.playing:
			if float(Time.get_ticks_msec() - inicio_ms) / 1000.0 >= tempo_maximo:
				break

			yield(get_tree(), "idle_frame")
	else:
		yield(get_tree().create_timer(0.6), "timeout")



func _set_led_card_cor(st: StyleBoxFlat, c: Color) -> void:
	if st == null:
		return
	st.border_color = c
	st.shadow_color = Color(c.r, c.g, c.b, 0.9)



func _aplicar_led_card(card: Panel) -> void:
	# Borda quadrada moderna com LED correndo (cores dos players).
	var st = card.get_stylebox("panel") as StyleBoxFlat
	if st == null:
		return

	var cores: Array = [
		Color(0.1, 0.75, 1.0),   # azul
		Color(0.2, 1.0, 0.3),    # verde
		Color(1.0, 0.15, 0.15),  # vermelho
		Color(1.0, 0.85, 0.05)   # amarelo
	]

	var tw = card.create_tween()
	tw.set_loops()

	for c in cores:
		var cc: Color = c
		tw.tween_callback(self, "_set_led_card_cor", [st, cc])
		tw.tween_interval(0.40)



func _abrir_mural_campeoes() -> void:
	if iniciando_jogo:
		return

	if opening_loading_layer != null:
		return

	if patro_replay_ativo:
		return

	if escolhendo_players:
		return

	if copa_modal_aberto:
		return

	if not ResourceLoader.exists(CENA_MURAL_CAMPEOES):
		push_error("Cena do Mural de Campeões não encontrada: " + CENA_MURAL_CAMPEOES)
		return

	iniciando_jogo = true

	if sfx_player_select and sfx_player_select.stream:
		sfx_player_select.stop()
		sfx_player_select.play()

	_serial_write_opening("OFF")

	if audio_fundo:
		audio_fundo.stop()
	
	
	_marcar_retorno_sem_patrocinadores()
	get_tree().change_scene(CENA_MURAL_CAMPEOES)



func _criar_painel_mural_ranking() -> void:
	if root == null:
		return

	var painel: Panel = Panel.new()
	painel.name = "PainelMuralRanking"

	# Painel maior e mais presente.
	painel.rect_position = Vector2(24.0, 30.0)
	painel.rect_size = Vector2(355.0, 188.0)

	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Compat.z(painel, 90)
	painel.add_stylebox_override("panel", _style_painel_mural_ranking(COR_NEON, 0.22))
	root.add_child(painel)

	var titulo: Label = Label.new()
	titulo.text = "ATALHOS"
	titulo.rect_position = Vector2(0, 8)
	titulo.rect_size = Vector2(painel.rect_size.x, 24)
	titulo.align = Label.ALIGN_CENTER
	titulo.valign = Label.VALIGN_CENTER
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if fonte_orbitron:
		Compat.fonte(titulo, fonte_orbitron)

	Compat.tamanho(titulo, 13)
	titulo.add_color_override("font_color", Color(0.78, 0.88, 0.96))
	titulo.add_color_override("font_color_shadow", COR_NEON)
	titulo.add_constant_override("shadow_offset_x", 0)
	titulo.add_constant_override("shadow_offset_y", 0)
	painel.add_child(titulo)

	# =========================
	# BOTÃO MURAL
	# =========================
	var btn_mural: Button = _botao_mural_ranking(
		"🏆  MURAL DE CAMPEÕES",
		Vector2(18, 40),
		Vector2(painel.rect_size.x - 36, 42),
		COR_COPA
	)
	btn_mural.connect("pressed", self, "_abrir_mural_campeoes")
	painel.add_child(btn_mural)

	var dica_mural: Label = Label.new()
	dica_mural.text = "ENTRAR: START + SELECT"
	dica_mural.rect_position = Vector2(0, 84)
	dica_mural.rect_size = Vector2(painel.rect_size.x, 20)
	dica_mural.align = Label.ALIGN_CENTER
	dica_mural.valign = Label.VALIGN_CENTER
	dica_mural.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if fonte_orbitron:
		Compat.fonte(dica_mural, fonte_orbitron)

	Compat.tamanho(dica_mural, 10)
	dica_mural.add_color_override("font_color", Color(0.76, 0.80, 0.88))
	painel.add_child(dica_mural)

	# =========================
	# BOTÃO RANKING
	# =========================
	var txt_ranking: String = "📊  RANKING"

	if not ResourceLoader.exists(CENA_RANKING):
		txt_ranking = "📊  RANKING  •  EM BREVE"

	var btn_ranking: Button = _botao_mural_ranking(
		txt_ranking,
		Vector2(18, 112),
		Vector2(painel.rect_size.x - 36, 42),
		Color(0.62, 0.50, 1.00)
	)

	if ResourceLoader.exists(CENA_RANKING):
		btn_ranking.disabled = false
		btn_ranking.modulate = Color(1, 1, 1, 0.92)
		btn_ranking.connect("pressed", self, "_abrir_ranking")
	else:
		btn_ranking.disabled = true
		btn_ranking.modulate = Color(1, 1, 1, 0.45)

	painel.add_child(btn_ranking)

	var dica_ranking: Label = Label.new()

	if ResourceLoader.exists(CENA_RANKING):
		dica_ranking.text = "ENTRAR: SEGURE SELECT"
	else:
		dica_ranking.text = "RANKING DISPONÍVEL EM BREVE"

	dica_ranking.rect_position = Vector2(0, 156)
	dica_ranking.rect_size = Vector2(painel.rect_size.x, 22)
	dica_ranking.align = Label.ALIGN_CENTER
	dica_ranking.valign = Label.VALIGN_CENTER
	dica_ranking.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if fonte_orbitron:
		Compat.fonte(dica_ranking, fonte_orbitron)

	Compat.tamanho(dica_ranking, 10)
	dica_ranking.add_color_override("font_color", Color(0.76, 0.80, 0.88))
	painel.add_child(dica_ranking)



func _botao_mural_ranking(txt: String, pos: Vector2, tam: Vector2, cor: Color) -> Button:
	var b: Button = Button.new()
	b.text = txt
	b.rect_position = pos
	b.rect_size = tam
	b.rect_min_size = tam
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if fonte_orbitron:
		Compat.fonte(b, fonte_orbitron)

	Compat.tamanho(b, int(clamp(tam.y * 0.34, 12.0, 16.0)))
	b.add_color_override("font_color", Color.white)
	b.add_color_override("font_color_hover", Color.white)
	b.add_color_override("font_color_pressed", cor)
	b.add_color_override("font_color_disabled", Color(0.72, 0.76, 0.84))

	b.add_stylebox_override("normal", _style_botao_mural_ranking(cor, 0.22))
	b.add_stylebox_override("hover", _style_botao_mural_ranking(cor, 0.50))
	b.add_stylebox_override("pressed", _style_botao_mural_ranking(cor, 0.76))
	b.add_stylebox_override("focus", _style_botao_mural_ranking(cor, 0.36))
	b.add_stylebox_override("disabled", _style_botao_mural_ranking(cor, 0.14))

	return b



func _atualizar_hold_ranking(delta: float) -> void:
	var pode_ranking: bool = InputMap.has_action("input_cup") \
		and not escolhendo_players \
		and not iniciando_jogo \
		and not copa_modal_aberto \
		and not patro_replay_ativo \
		and opening_loading_layer == null \
		and not combo_mural_ativo \
		and not combo_indo_mural \
		and not ranking_indo \
		and not Input.is_action_pressed("input_start")

	var segurando_select: bool = pode_ranking and Input.is_action_pressed("input_cup")

	if segurando_select:
		ranking_hold_medindo = true
		ranking_hold += delta

		# Antes desse tempo, é só uma medição silenciosa.
		# Não abre modal.
		# Não mexe nos LEDs.
		# Não bloqueia carrossel.
		if ranking_hold < RANKING_HOLD_MOSTRAR_MODAL_SEGUNDOS:
			return

		# A partir daqui virou HOLD real de Ranking.
		if not ranking_hold_ativo:
			ranking_hold_ativo = true
			ranking_hold_visual_aberto = true

			# Cancela o SELECT rápido, porque agora virou comando de segurar.
			avancar_pendente = false
			confirmar_pendente = false

			_abrir_modal_hold_ranking()
			_set_leds_todos_rgb(_rgb_ranking_forte())

		_atualizar_barra_hold_ranking()

		if ranking_hold >= RANKING_HOLD_SEGUNDOS:
			_ir_para_ranking_por_hold()

	else:
		if ranking_hold_medindo or ranking_hold_ativo or ranking_hold_visual_aberto:
			var tinha_visual: bool = ranking_hold_visual_aberto

			ranking_hold_medindo = false
			ranking_hold_ativo = false
			ranking_hold_visual_aberto = false
			ranking_hold = 0.0

			if tinha_visual:
				_fechar_modal_hold_ranking()
				_reiniciar_led_atrativo(0.16)



func _abrir_modal_hold_ranking() -> void:
	if ranking_layer != null and is_instance_valid(ranking_layer):
		return

	var cor: Color = Color(0.62, 0.50, 1.00)

	ranking_layer = CanvasLayer.new()
	ranking_layer.layer = 945
	add_child(ranking_layer)

	ranking_fundo = ColorRect.new()
	ranking_fundo.set_anchors_preset(Control.PRESET_WIDE)
	ranking_fundo.color = Color(0, 0, 0, 0.0)
	ranking_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ranking_layer.add_child(ranking_fundo)

	var tela: Vector2 = get_viewport_rect().size

	ranking_modal = Panel.new()
	ranking_modal.rect_size = Vector2(680, 300)
	ranking_modal.rect_position = Vector2(
		(tela.x - ranking_modal.rect_size.x) * 0.5,
		(tela.y - ranking_modal.rect_size.y) * 0.5
	)
	ranking_modal.rect_pivot_offset = ranking_modal.rect_size * 0.5
	ranking_modal.rect_scale = Vector2(0.92, 0.92)
	ranking_modal.modulate = Color(1, 1, 1, 0)
	ranking_modal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ranking_layer.add_child(ranking_modal)

	var st: StyleBoxFlat = StyleBoxFlat.new()
	st.bg_color = Color(0.010, 0.012, 0.022, 0.98)
	st.border_color = cor
	st.set_border_width_all(4)
	st.set_corner_radius_all(28)
	st.shadow_color = Color(cor.r, cor.g, cor.b, 0.78)
	st.shadow_size = 42
	st.shadow_offset = Vector2.ZERO
	ranking_modal.add_stylebox_override("panel", st)

	var faixa: ColorRect = ColorRect.new()
	faixa.rect_position = Vector2(38, 26)
	faixa.rect_size = Vector2(ranking_modal.rect_size.x - 76, 5)
	faixa.color = cor
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ranking_modal.add_child(faixa)

	var titulo: Label = Label.new()
	titulo.text = "📊 RANKING"
	titulo.rect_position = Vector2(0, 54)
	titulo.rect_size = Vector2(ranking_modal.rect_size.x, 48)
	titulo.align = Label.ALIGN_CENTER
	titulo.valign = Label.VALIGN_CENTER

	if fonte_orbitron:
		Compat.fonte(titulo, fonte_orbitron)

	Compat.tamanho(titulo, 34)
	titulo.add_color_override("font_color", Color.white)
	titulo.add_color_override("font_color_shadow", cor)
	titulo.add_constant_override("shadow_offset_x", 0)
	titulo.add_constant_override("shadow_offset_y", 0)
	ranking_modal.add_child(titulo)

	var sub: Label = Label.new()
	sub.text = "CONTINUE SEGURANDO SELECT"
	sub.rect_position = Vector2(0, 122)
	sub.rect_size = Vector2(ranking_modal.rect_size.x, 34)
	sub.align = Label.ALIGN_CENTER
	sub.valign = Label.VALIGN_CENTER

	if fonte_orbitron:
		Compat.fonte(sub, fonte_orbitron)

	Compat.tamanho(sub, 21)
	sub.add_color_override("font_color", Color(cor.r, cor.g, cor.b, 0.95))
	ranking_modal.add_child(sub)

	var barra_bg: ColorRect = ColorRect.new()
	barra_bg.rect_position = Vector2(82, 190)
	barra_bg.rect_size = Vector2(ranking_modal.rect_size.x - 164, 14)
	barra_bg.color = Color(1, 1, 1, 0.12)
	barra_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ranking_modal.add_child(barra_bg)

	ranking_barra_max_w = barra_bg.rect_size.x

	ranking_barra = ColorRect.new()
	ranking_barra.rect_position = barra_bg.rect_position
	ranking_barra.rect_size = Vector2(0, 14)
	ranking_barra.color = cor
	ranking_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ranking_modal.add_child(ranking_barra)

	var rodape: Label = Label.new()
	rodape.text = "SOLTE PARA CANCELAR"
	rodape.rect_position = Vector2(0, 226)
	rodape.rect_size = Vector2(ranking_modal.rect_size.x, 28)
	rodape.align = Label.ALIGN_CENTER
	rodape.valign = Label.VALIGN_CENTER

	if fonte_orbitron:
		Compat.fonte(rodape, fonte_orbitron)

	Compat.tamanho(rodape, 14)
	rodape.add_color_override("font_color", Color(0.70, 0.74, 0.82))
	ranking_modal.add_child(rodape)

	var t: SceneTreeTween = create_tween()
	t.set_parallel(true)
	t.tween_property(ranking_fundo, "color", Color(0, 0, 0, 0.78), 0.18)
	t.tween_property(ranking_modal, "modulate", Color.white, 0.18)
	t.tween_property(ranking_modal, "rect_scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _atualizar_barra_hold_ranking() -> void:
	if ranking_barra == null or not is_instance_valid(ranking_barra):
		return

	var frac: float = clamp(ranking_hold / RANKING_HOLD_SEGUNDOS, 0.0, 1.0)
	ranking_barra.rect_size.x = ranking_barra_max_w * frac


func _fechar_modal_hold_ranking() -> void:
	ranking_hold_medindo = false
	ranking_hold_ativo = false
	ranking_hold_visual_aberto = false
	ranking_hold = 0.0

	var layer_ref: CanvasLayer = ranking_layer
	var modal_ref: Panel = ranking_modal
	var fundo_ref: ColorRect = ranking_fundo

	ranking_layer = null
	ranking_modal = null
	ranking_fundo = null
	ranking_barra = null
	ranking_barra_max_w = 0.0

	if layer_ref == null or not is_instance_valid(layer_ref):
		return

	var t: SceneTreeTween = create_tween()
	t.set_parallel(true)

	if modal_ref and is_instance_valid(modal_ref):
		t.tween_property(modal_ref, "rect_scale", Vector2(0.92, 0.92), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		t.tween_property(modal_ref, "modulate", Color(1, 1, 1, 0), 0.14)

	if fundo_ref and is_instance_valid(fundo_ref):
		t.tween_property(fundo_ref, "color", Color(0, 0, 0, 0.0), 0.14)

	yield(t, "finished")

	if is_instance_valid(layer_ref):
		layer_ref.queue_free()



func _ir_para_ranking_por_hold() -> void:
	if ranking_indo:
		return

	if not ResourceLoader.exists(CENA_RANKING):
		push_warning("Cena do Ranking ainda não existe: " + CENA_RANKING)
		ranking_hold_ativo = false
		ranking_hold = 0.0
		_fechar_modal_hold_ranking()
		return

	ranking_indo = true
	ranking_hold_ativo = false
	avancar_pendente = false

	iniciando_jogo = true

	if sfx_game_start and sfx_game_start.stream:
		sfx_game_start.stop()
		sfx_game_start.play()

	_set_leds_todos_rgb(_rgb_ranking_forte())

	if ranking_modal and is_instance_valid(ranking_modal):
		var t: SceneTreeTween = ranking_modal.create_tween()
		t.tween_property(ranking_modal, "rect_scale", Vector2(1.05, 1.05), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	yield(get_tree().create_timer(0.22), "timeout")

	_serial_write_opening("OFF")

	if audio_fundo:
		audio_fundo.stop()

	_marcar_retorno_sem_patrocinadores()
	get_tree().change_scene(CENA_RANKING)


func _rgb_ranking_forte() -> Array:
	return [135, 80, 255]

func _style_painel_mural_ranking(cor: Color, intensidade: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(
		0.010 + cor.r * 0.045,
		0.014 + cor.g * 0.035,
		0.022 + cor.b * 0.035,
		0.90
	)
	s.border_color = Color(cor.r, cor.g, cor.b, 0.72)
	s.set_border_width_all(2)
	s.set_corner_radius_all(22)
	s.shadow_color = Color(cor.r, cor.g, cor.b, intensidade)
	s.shadow_size = 18
	s.shadow_offset = Vector2.ZERO
	return s


func _style_botao_mural_ranking(cor: Color, intensidade: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(cor.r * 0.10, cor.g * 0.08, cor.b * 0.08, 0.94)
	s.border_color = Color(cor.r, cor.g, cor.b, 0.92)
	s.set_border_width_all(2)
	s.set_corner_radius_all(15)
	s.shadow_color = Color(cor.r, cor.g, cor.b, intensidade)
	s.shadow_size = 14
	s.shadow_offset = Vector2.ZERO
	return s


func _abrir_ranking() -> void:
	if iniciando_jogo:
		return

	if opening_loading_layer != null:
		return

	if patro_replay_ativo:
		return

	if escolhendo_players:
		return

	if copa_modal_aberto:
		return

	if not ResourceLoader.exists(CENA_RANKING):
		push_warning("Cena do Ranking ainda não existe: " + CENA_RANKING)
		return

	iniciando_jogo = true

	if sfx_player_select and sfx_player_select.stream:
		sfx_player_select.stop()
		sfx_player_select.play()

	_serial_write_opening("OFF")

	if audio_fundo:
		audio_fundo.stop()

	_marcar_retorno_sem_patrocinadores()
	get_tree().change_scene(CENA_RANKING)



func _marcar_retorno_sem_patrocinadores() -> void:
	get_tree().set_meta(META_PULAR_PATROCINADORES_OPENING, true)


func _rgb_dim(rgb: Array, fator: float) -> Array:
	return [
		int(clamp(float(rgb[0]) * fator, 0.0, 255.0)),
		int(clamp(float(rgb[1]) * fator, 0.0, 255.0)),
		int(clamp(float(rgb[2]) * fator, 0.0, 255.0))
	]


func _rgb_fluxo_principal(passo: int) -> Array:
	# Usa as mesmas cores oficiais do jogo:
	# Player 1 azul, Player 2 verde, Player 3 vermelho, Player 4 amarelo.
	return _rgb_player_suave(passo % 4)



func _leds_fluxo_ida_volta_ag(passo: int) -> void:
	if passo < 0 or passo >= LED_FLUXO_ORDEM_AG.size():
		return

	var atual: int = LED_FLUXO_ORDEM_AG[passo]
	var rgb_main: Array = _rgb_fluxo_principal(passo)

	var mapa = {}

	# Apaga todos, inclusive H.
	for i in range(LEDS_TOTAL):
		mapa[i] = [0, 0, 0]

	# Rastro inteligente: luz principal forte + vizinhos mais fracos.
	var anterior_1: int = atual - 1
	var anterior_2: int = atual - 2
	var proximo_1: int = atual + 1

	if anterior_2 >= 0 and anterior_2 <= 6:
		mapa[anterior_2] = _rgb_dim(rgb_main, 0.12)

	if anterior_1 >= 0 and anterior_1 <= 6:
		mapa[anterior_1] = _rgb_dim(rgb_main, 0.34)

	if proximo_1 >= 0 and proximo_1 <= 6:
		mapa[proximo_1] = _rgb_dim(rgb_main, 0.22)

	# LED principal.
	mapa[atual] = rgb_main

	_set_leds_mapa_rgb(mapa)

