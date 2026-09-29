extends Node

const MOSTRAR_TECLAS_LED_HUD: bool = false
const CORES_LED_ALEATORIAS_DOS_PLAYERS: bool = true


# ===================== CONTROLE DOS SONS REATIVOS =====================
# Gol e apito podem sobrepor.
# Torcida, incentivo, vaia, bom/ruim e campeão NÃO podem sobrepor.

var _reativo_bloqueado_por_campeao: bool = false

var _campeao_pendente: bool = false

var fechando_jogo: bool = false

# Vitória antecipada: último player ultrapassa todos os já finalizados
var _vitoria_antecipada_tocada: bool = false

var medalhas_players: Array[Control] = []

# Vaia ao terminar com pontuação baixa
const PONTOS_MINIMOS_SEM_VAIA: int = 15
const SONS_VAIA: Array[String] = [
	"res://songs/vaia_1.mp3",
	"res://songs/vaia_2.mp3",
]

# Timeout do alvo: se não acertar em 15s, troca o grupo
const ALVO_TIMEOUT_MS: float = 15000.0
var _ultimo_acerto_ms: float = 0.0


@warning_ignore("unused_private_class_variable")
var _ultimo_motivacional_ms: float = 0.0

const MOTIVACIONAL_INTERVALO_MS: float = 7000.0   # mínimo 7s entre incentivos
const MOTIVACIONAL_RITMO_BOM: float = 0.5         # gols/seg considerado "indo bem"

const CENA_OPENING: String = "res://scenes/opening.tscn"

const START_DEBOUNCE_MS: float = 500.0
var _ultimo_start_ms: float = -99999.0


const SFX_CAMPEAO: String = "res://songs/campeao.mp3"

var _acertos_torcida: int = 0
const PONTOS_PARA_TORCIDA: int = 10


var sfx_campeao: AudioStreamPlayer


const PRESSAO_JANELA_MS: float = 9000.0   # 9s sem pontuar -> pressão da torcida

const COMBO_JANELA_MS: float = 6000.0     # 6 segundos
const COMBO_MIN_GOLS: int = 4             # "mais que 3" gols
const TEMPO_REINICIO_AUTO: float = 21.0   # auto-reinício do modal final

var _gols_timestamps: Array[float] = []
var _ultimo_combo_ms: float = -99999.0
var pode_reiniciar: bool = false
var _final_token: int = 0

const TEMPO_POR_PLAYER: float = 60.0
const TEMPO_CONTAGEM_INICIAL: int = 3
const FONTE_ORBITRON: String = "res://fonts/orbitron-bold.ttf"
const MUSICA_PLAY: String = "res://songs/song_fut_play.mp3"
const SFX_PONTO: String = "res://songs/goal.mp3"
const SFX_FIM_TURNO: String = "res://songs/turn_end.mp3"
const SFX_FINAL: String = "res://songs/game_start.mp3"
const SFX_APITO_INIT: String = "res://songs/apito_init.mp3"
const SFX_APITO_TROCA: String = "res://songs/apito_troca.mp3"
const SFX_APITO_FIM: String = "res://songs/apito_fim.mp3"


const LEDS_TOTAL: int = 7
const LEDS_ATIVOS_MAX: int = 3
const LEDS_LETRAS: Array[String] = ["A", "B", "C", "D", "E", "F", "G"]

const LEDS_ATIVOS_MIN: int = 1


var qtd_leds_alvo_atual: int = 3

const MUSICAS_PLAYERS: Array[String] = [
	"res://songs/player_song1.mp3",
	"res://songs/player_song2.mp3",
	"res://songs/player_song3.mp3",
	"res://songs/player_song4.mp3",
	"res://songs/player_song5.mp3",
]

# Sons reativos. Adicione quantos quiser por lista — quanto mais, mais variedade.
const SONS_TURNO_BOM: Array[String] = [
	"res://songs/good_player.mp3",
	"res://songs/leleo.mp3",
	"res://songs/torcida_1.mp3",	
	
]

const SONS_SUPEROU_TURNO: Array[String] = [
	"res://songs/supress_you.mp3",
	"res://songs/good_player.mp3",
	"res://songs/torcida_2.mp3",
	"res://songs/torcida_3.mp3",
]

const SONS_NAO_SUPEROU: Array[String] = [
	"res://songs/not_supress.mp3",
	"res://songs/erro_1.mp3",
	"res://songs/erro_2.mp3",
]

const SONS_SUPEROU_LIVE: Array[String] = [
	"res://songs/live_superou_1.mp3",
	"res://songs/live_superou_2.mp3",
]

const USAR_ARDUINO: bool = true
const SERIAL_BAUD: int = 9600
const SERIAL_PORTA: String = "COM5"

var serial_arduino = null
var serial_buffer: String = ""


var sfx_reativo: AudioStreamPlayer
var _ultimo_som_por_lista: Dictionary = {}
var _superou_adversario: Array = []   # [player][adversario] = já anunciou que passou?
var _ultimo_ponto_ms: float = 0.0
var _ultima_pressao_ms: float = 0.0

var musicas_por_player: Array[AudioStream] = []

var loading_layer: CanvasLayer = null
var loading_fundo: ColorRect = null
var loading_panel: Panel = null
var loading_label: Label = null
var loading_sub_label: Label = null

var canvas: CanvasLayer
var root: Control

var fonte_orbitron: Font

var leds_ativos: Array[int] = []

var cores_leds_ativos: Dictionary = {}

var leds_hud_layer: CanvasLayer
var leds_hud_root: Control
var leds_botoes: Array[Panel] = []
var leds_labels: Array[Label] = []

var total_players: int = 1
var player_atual: int = 0

var partida_ativa: bool = false
var aguardando_start_turno: bool = true
var em_contagem_inicio: bool = false
var partida_finalizada: bool = false

var scores: Array[int] = []
var tempos: Array[float] = []
var terminou_player: Array[bool] = []

var player_panels: Array[Panel] = []
var score_labels: Array[Label] = []
var tempo_labels: Array[Label] = []
var status_labels: Array[Label] = []
var rodada_labels: Array[Label] = []

var overlay_layer: CanvasLayer
var overlay_fundo: ColorRect
var overlay_panel: Panel
var overlay_titulo: Label
var overlay_subtitulo: Label
var overlay_numero: Label
var audio_fundo: AudioStreamPlayer
var sfx_ponto: AudioStreamPlayer
var sfx_fim_turno: AudioStreamPlayer
var sfx_final: AudioStreamPlayer

var turno_layer: CanvasLayer
var turno_panel: Panel
var turno_titulo: Label
var turno_subtitulo: Label

var final_layer: CanvasLayer


const USAR_PONTE_POWERSHELL: bool = true

var ponte_ps_pid: int = -1
var caminho_cmd_arduino: String = ""
var caminho_log_arduino: String = ""
var caminho_script_arduino: String = ""

var caminho_fila_arduino: String = ""

var sfx_apito_init: AudioStreamPlayer
var sfx_apito_troca: AudioStreamPlayer
var sfx_apito_fim: AudioStreamPlayer

var cores_players: Array[Color] = [
	Color(0.1, 0.75, 1.0),
	Color(0.2, 1.0, 0.3),
	Color(1.0, 0.15, 0.15),
	Color(1.0, 0.85, 0.05)
	]


const CORES_ALVOS_RGB: Array = [
	[255, 255, 0], # amarelo forte
	[255, 0, 0],   # vermelho forte
	[0, 255, 0],   # verde forte
	[0, 0, 255]    # azul forte
]


func _ready() -> void:
	get_tree().auto_accept_quit = false
	_travar_modo_arcade()

	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	randomize()

	await get_tree().process_frame

	_carregar_fontes()
	_criar_audios()
	_carregar_config_players()
	_inicializar_dados()
	_sortear_musicas_players()

	_criar_tela()
	_mostrar_loading_play()

	await get_tree().process_frame

	await _abrir_serial_arduino()

	await _remover_loading_play()

	_mostrar_preparacao_player()

func _travar_modo_arcade() -> void:
	# Tela cheia exclusiva para dificultar o acesso ao Windows.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

	# Remove bordas da janela.
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)

	# Mantém o jogo por cima.
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)

	# Mouse escondido.
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	# O jogo não aceita fechamento automático por sistema.
	get_tree().auto_accept_quit = false




func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			# ÚNICO ATALHO QUE FECHA O JOGO:
			# CTRL + TAB
			if event.ctrl_pressed and event.keycode == KEY_TAB:
				_fechar_jogo_arcade()
				get_viewport().set_input_as_handled()
				return

			# Tenta bloquear tecla Windows / Meta, se o evento chegar na Godot.
			if event.keycode == KEY_META:
				get_viewport().set_input_as_handled()
				return

			# Bloqueia ESC.
			if event.keycode == KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				return

			# Bloqueia ALT + F4.
			if event.alt_pressed and event.keycode == KEY_F4:
				get_viewport().set_input_as_handled()
				return

			# Bloqueia ALT + TAB, se chegar na Godot.
			if event.alt_pressed and event.keycode == KEY_TAB:
				get_viewport().set_input_as_handled()
				return

			# Bloqueia CTRL + ESC, que abre o iniciar.
			if event.ctrl_pressed and event.keycode == KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				return


func _start_foi_pressionado() -> bool:
	if not Input.is_action_just_pressed("input_start"):
		return false

	# Debounce: ignora um segundo start dentro da janela (bounce / clique duplo).
	var agora := float(Time.get_ticks_msec())
	if agora - _ultimo_start_ms < START_DEBOUNCE_MS:
		return false

	_ultimo_start_ms = agora
	return true



func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_META:
				get_viewport().set_input_as_handled()
				return

			if event.keycode == KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				return

			if event.alt_pressed and event.keycode == KEY_F4:
				get_viewport().set_input_as_handled()
				return

			if event.alt_pressed and event.keycode == KEY_TAB:
				get_viewport().set_input_as_handled()
				return

			if event.ctrl_pressed and event.keycode == KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				return

func _process(delta: float) -> void:
	if partida_finalizada:
		if pode_reiniciar and _start_foi_pressionado():
			pode_reiniciar = false
			_reiniciar_partida()
		return

	if aguardando_start_turno and _start_foi_pressionado():
		_iniciar_contagem_turno()
		return

	if not partida_ativa:
		return

	_checar_timeout_alvo()

	for i in range(LEDS_TOTAL):
		var acao: String = "input_led_" + LEDS_LETRAS[i].to_lower()

		if Input.is_action_just_pressed(acao):
			print("INPUT SENSOR PRESSIONADO: ", acao, " / LED INDEX: ", i)
			_processar_input_led(i)

	if player_atual < 0 or player_atual >= total_players:
		return

	tempos[player_atual] -= delta

	if tempos[player_atual] <= 0.0:
		tempos[player_atual] = 0.0
		_finalizar_turno_player()

	_avaliar_motivacao()
	_atualizar_hud()



func _checar_timeout_alvo() -> void:
	if not partida_ativa:
		return
	if leds_ativos.is_empty():
		return

	var agora := float(Time.get_ticks_msec())
	if agora - _ultimo_acerto_ms >= ALVO_TIMEOUT_MS:
		_ultimo_acerto_ms = agora
		print("ALVO SEM ACERTO POR 15s -> TROCANDO GRUPO")
		_sortear_novo_grupo_de_fileiras()



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

	sfx_final = AudioStreamPlayer.new()
	sfx_final.name = "SfxFinal"
	add_child(sfx_final)

	sfx_apito_init = AudioStreamPlayer.new()
	sfx_apito_init.name = "SfxApitoInit"
	add_child(sfx_apito_init)

	sfx_apito_troca = AudioStreamPlayer.new()
	sfx_apito_troca.name = "SfxApitoTroca"
	add_child(sfx_apito_troca)

	sfx_apito_fim = AudioStreamPlayer.new()
	sfx_apito_fim.name = "SfxApitoFim"
	add_child(sfx_apito_fim)

	sfx_reativo = AudioStreamPlayer.new()
	sfx_reativo.name = "SfxReativo"
	add_child(sfx_reativo)
	sfx_reativo.finished.connect(_on_sfx_reativo_finished)   # recomeça a contagem ao terminar

	sfx_campeao = AudioStreamPlayer.new()
	sfx_campeao.name = "SfxCampeao"
	add_child(sfx_campeao)

	if ResourceLoader.exists(SFX_CAMPEAO):
		sfx_campeao.stream = load(SFX_CAMPEAO)
		sfx_campeao.volume_db = 1.5
	else:
		push_warning("Som campeão não encontrado: " + SFX_CAMPEAO)

	if ResourceLoader.exists(SFX_PONTO):
		sfx_ponto.stream = load(SFX_PONTO)
		sfx_ponto.volume_db = 0.0
	else:
		push_warning("Som de ponto não encontrado: " + SFX_PONTO)

	if ResourceLoader.exists(SFX_FIM_TURNO):
		sfx_fim_turno.stream = load(SFX_FIM_TURNO)
		sfx_fim_turno.volume_db = 0.0
	else:
		push_warning("Som de fim de turno não encontrado: " + SFX_FIM_TURNO)

	if ResourceLoader.exists(SFX_FINAL):
		sfx_final.stream = load(SFX_FINAL)
		sfx_final.volume_db = 0.0
	else:
		push_warning("Som final não encontrado: " + SFX_FINAL)

	if ResourceLoader.exists(SFX_APITO_INIT):
		sfx_apito_init.stream = load(SFX_APITO_INIT)
		sfx_apito_init.volume_db = 1.5
	else:
		push_warning("Apito inicial não encontrado: " + SFX_APITO_INIT)

	if ResourceLoader.exists(SFX_APITO_TROCA):
		sfx_apito_troca.stream = load(SFX_APITO_TROCA)
		sfx_apito_troca.volume_db = 1.5
	else:
		push_warning("Apito de troca não encontrado: " + SFX_APITO_TROCA)

	if ResourceLoader.exists(SFX_APITO_FIM):
		sfx_apito_fim.stream = load(SFX_APITO_FIM)
		sfx_apito_fim.volume_db = 1.5
	else:
		push_warning("Apito final não encontrado: " + SFX_APITO_FIM)



func _parar_sons_reativos() -> void:
	if sfx_reativo and sfx_reativo.playing:
		sfx_reativo.stop()

	if sfx_campeao and sfx_campeao.playing:
		sfx_campeao.stop()


func _parar_tudo_exceto_musica() -> void:
	# Para efeitos de jogo, mas mantém música de fundo se estiver tocando.
	if sfx_ponto and sfx_ponto.playing:
		sfx_ponto.stop()

	if sfx_fim_turno and sfx_fim_turno.playing:
		sfx_fim_turno.stop()

	if sfx_final and sfx_final.playing:
		sfx_final.stop()

	if sfx_apito_init and sfx_apito_init.playing:
		sfx_apito_init.stop()

	if sfx_apito_troca and sfx_apito_troca.playing:
		sfx_apito_troca.stop()

	if sfx_apito_fim and sfx_apito_fim.playing:
		sfx_apito_fim.stop()

	_parar_sons_reativos()



func _tocar_apito_init() -> void:
	if sfx_apito_init and sfx_apito_init.stream:
		sfx_apito_init.stop()
		sfx_apito_init.play()


func _tocar_apito_troca() -> void:
	if sfx_apito_troca and sfx_apito_troca.stream:
		sfx_apito_troca.stop()
		sfx_apito_troca.play()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Bloqueia qualquer pedido externo de fechamento.
		return

	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		# Bloqueia botão voltar.
		return


func _fechar_jogo_arcade() -> void:
	if fechando_jogo:
		return

	fechando_jogo = true

	print("FECHANDO PLAY SOMENTE COM CTRL + TAB...")

	_serial_write("OFF")

	_parar_tudo_exceto_musica()
	_parar_campeao()

	if audio_fundo:
		audio_fundo.stop()

	if USAR_PONTE_POWERSHELL and caminho_fila_arduino != "":
		var nome_arquivo := "%020d_EXIT.cmd" % Time.get_ticks_msec()
		var caminho_final := caminho_fila_arduino.path_join(nome_arquivo)

		var f := FileAccess.open(caminho_final, FileAccess.WRITE)
		if f:
			f.store_string("__EXIT__")
			f.close()

	await get_tree().create_timer(0.12).timeout

	get_tree().quit()


func _tocar_apito_fim() -> void:
	if sfx_apito_fim and sfx_apito_fim.stream:
		sfx_apito_fim.stop()
		sfx_apito_fim.play()



func _tocar_musica_play() -> void:
	if not audio_fundo:
		return

	if ResourceLoader.exists(MUSICA_PLAY):
		var stream: AudioStream = load(MUSICA_PLAY)

		if stream is AudioStreamMP3:
			stream.loop = true

		audio_fundo.stream = stream
		audio_fundo.volume_db = -7.0
		audio_fundo.play()
	else:
		push_warning("Música do play não encontrada: " + MUSICA_PLAY)



func _carregar_fontes() -> void:
	if ResourceLoader.exists(FONTE_ORBITRON):
		fonte_orbitron = load(FONTE_ORBITRON)



func _carregar_config_players() -> void:
	total_players = 1

	var cores_recebidas: Array = []

	# Primeiro tenta ler da metadata da SceneTree.
	if get_tree().has_meta("fut_total_players"):
		total_players = int(get_tree().get_meta("fut_total_players"))
		print("PLAY LEU PLAYERS PELA META: ", total_players)

	if get_tree().has_meta("fut_cores_players"):
		cores_recebidas = get_tree().get_meta("fut_cores_players")

	# Depois confirma pelo Autoload.
	var players_global := get_node_or_null("/root/PlayersGlobal")

	if players_global != null:
		var qtd_global = players_global.get("total_players_futebol")

		if qtd_global != null:
			var qtd_int := int(qtd_global)

			# Usa o maior valor válido, para evitar voltar para 1 indevidamente.
			if qtd_int > total_players:
				total_players = qtd_int

		var cores_global = players_global.get("cores_players_futebol")

		if cores_recebidas.is_empty() and cores_global != null and cores_global is Array:
			cores_recebidas = cores_global
	else:
		push_warning("PLAY: /root/PlayersGlobal não encontrado. Usando metadata ou 1 player.")

	total_players = clamp(total_players, 1, 4)

	if cores_recebidas != null and cores_recebidas is Array and cores_recebidas.size() > 0:
		for i in range(min(cores_recebidas.size(), cores_players.size())):
			cores_players[i] = cores_recebidas[i]

	print("================================")
	print("PLAY MONTOU COM PLAYERS: ", total_players)
	print("PLAY CORES RECEBIDAS: ", cores_recebidas.size())
	print("================================")



func _inicializar_dados() -> void:
	scores.clear()
	tempos.clear()
	terminou_player.clear()

	for i in range(total_players):
		scores.append(0)
		tempos.append(TEMPO_POR_PLAYER)
		terminou_player.append(false)

	player_atual = 0
	partida_ativa = false
	aguardando_start_turno = false
	em_contagem_inicio = false
	partida_finalizada = false

	_acertos_torcida = 0
	_ultimo_som_por_lista.clear()
	_superou_adversario.clear()
	for i in range(total_players):
		var linha: Array[bool] = []
		for j in range(total_players):
			linha.append(false)
		_superou_adversario.append(linha)

	_gols_timestamps.clear()
	_ultimo_combo_ms = -99999.0
	pode_reiniciar = false
	_ultimo_ponto_ms = 0.0
	_ultima_pressao_ms = 0.0

	_vitoria_antecipada_tocada = false
	_reativo_bloqueado_por_campeao = false
	_campeao_pendente = false
	_ultimo_acerto_ms = 0.0



func _escolher_som_aleatorio(lista: Array[String], chave: String) -> String:
	var disponiveis: Array[String] = []
	for caminho in lista:
		if ResourceLoader.exists(caminho):
			disponiveis.append(caminho)

	if disponiveis.is_empty():
		return ""

	if disponiveis.size() == 1:
		return disponiveis[0]

	# Filtra o último tocado dessa categoria pra não repetir
	var ultimo: String = String(_ultimo_som_por_lista.get(chave, ""))
	var candidatos: Array[String] = []
	for caminho in disponiveis:
		if caminho != ultimo:
			candidatos.append(caminho)

	if candidatos.is_empty():
		candidatos = disponiveis

	var escolhido: String = candidatos[randi() % candidatos.size()]
	_ultimo_som_por_lista[chave] = escolhido
	return escolhido


func _tocar_som_da_lista(lista: Array[String], chave: String, volume_db: float = 0.0, forcar: bool = false) -> void:
	if sfx_reativo == null:
		return

	# Se campeão antecipado já tocou, nenhum incentivo/vaia/torcida entra por cima.
	if _reativo_bloqueado_por_campeao:
		return

	# Sem sobrepor cantos/incentivos:
	# se já tem torcida, vaia, som bom ou ruim tocando, ignora o próximo,
	# a menos que seja forçado.
	if sfx_reativo.playing and not forcar:
		return

	# Campeão nunca deve ser atropelado por som reativo.
	if sfx_campeao and sfx_campeao.playing:
		return

	var caminho := _escolher_som_aleatorio(lista, chave)
	if caminho == "":
		push_warning("Nenhum som disponível para: " + chave)
		return

	var stream := load(caminho) as AudioStream
	if stream == null:
		return

	if stream is AudioStreamMP3:
		stream.loop = false

	# Se for forçado, ele pode cortar outro reativo,
	# mas não corta campeão.
	if forcar and sfx_reativo.playing:
		sfx_reativo.stop()

	sfx_reativo.stream = stream
	sfx_reativo.volume_db = volume_db
	sfx_reativo.play()



func _on_sfx_reativo_finished() -> void:
	_acertos_torcida = 0

	if _campeao_pendente:
		_tocar_campeao_agora()



func _tocar_som_fim_turno_reativo(player_index: int) -> void:
	# Terminou com menos de 15 gols => VAIA (tem prioridade, forçada).
	if scores[player_index] < PONTOS_MINIMOS_SEM_VAIA:
		_tocar_som_da_lista(SONS_VAIA, "vaia_fim", 1.0, true)
		return

	var meu_score: int = scores[player_index]

	var jogadores_anteriores: int = 0
	var melhor_anterior: int = 0
	for i in range(total_players):
		if i == player_index:
			continue
		if terminou_player[i]:
			jogadores_anteriores += 1
			if scores[i] > melhor_anterior:
				melhor_anterior = scores[i]

	# Primeiro a jogar — não há com quem comparar, nunca toca o som ruim
	if jogadores_anteriores == 0:
		_tocar_som_da_lista(SONS_TURNO_BOM, "fim_bom")
		return

	# Com referência
	if meu_score > melhor_anterior:
		_tocar_som_da_lista(SONS_SUPEROU_TURNO, "fim_superou", 1.0)
	elif meu_score < melhor_anterior:
		_tocar_som_da_lista(SONS_NAO_SUPEROU, "fim_ruim")
	else:
		_tocar_som_da_lista(SONS_TURNO_BOM, "fim_bom")


func _criar_tela() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)

	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)

	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.006, 0.008, 0.012, 1.0)
	root.add_child(fundo)

	_criar_overlay_turno()
	_reconstruir_paineis()
	_criar_hud_leds()


func _reconstruir_paineis() -> void:
	for p in player_panels:
		if is_instance_valid(p):
			p.queue_free()

	player_panels.clear()
	score_labels.clear()
	tempo_labels.clear()
	status_labels.clear()
	rodada_labels.clear()
	medalhas_players.clear()

	var tela := get_viewport().get_visible_rect().size

	for i in range(total_players):
		_criar_painel_player(
			i,
			_get_rect_player_dinamico(i, total_players, tela, player_atual)
		)

	await get_tree().process_frame
	_atualizar_hud()


func _get_rect_player_dinamico(index: int, qtd: int, tela: Vector2, ativo: int) -> Rect2:
	@warning_ignore("unused_variable")
	var margem_externa: float = 8.0

	if qtd <= 1:
		return Rect2(Vector2.ZERO, tela)

	if qtd == 2:
		var w := tela.x / 2.0
		return Rect2(Vector2(index * w, 0), Vector2(w, tela.y))

	if qtd == 3:
		# Layout mais equilibrado para 3 players:
		# Player ativo grande na esquerda.
		# Dois players restantes empilhados na direita.
		var big_w := tela.x * 0.58
		var small_w := tela.x - big_w

		if index == ativo:
			return Rect2(Vector2.ZERO, Vector2(big_w, tela.y))

		var slot := 0
		for j in range(qtd):
			if j == index:
				break
			if j != ativo:
				slot += 1

		var h := tela.y / 2.0
		return Rect2(Vector2(big_w, float(slot) * h), Vector2(small_w, h))

	# 4 players: grade 2x2 bem limpa.
	var w4 := tela.x / 2.0
	var h4 := tela.y / 2.0
	var col := index % 2
	@warning_ignore("integer_division")
	var row := int(index / 2)

	return Rect2(Vector2(float(col) * w4, float(row) * h4), Vector2(w4, h4))



func _criar_painel_player(index: int, rect: Rect2) -> void:
	if index < 0 or index >= cores_players.size():
		return

	var cor := cores_players[index]

	var margem := 10.0
	var panel := Panel.new()
	panel.position = rect.position + Vector2(margem, margem)
	panel.size = rect.size - Vector2(margem * 2.0, margem * 2.0)
	panel.clip_contents = true
	root.add_child(panel)

	var W := panel.size.x
	var H := panel.size.y

	# fontes proporcionais ao tamanho real do card (enquadra em 1/2/3/4 players)
	var fs_titulo := int(clampf(H * 0.060, 20.0, 42.0))
	var fs_score_titulo := int(clampf(H * 0.030, 12.0, 22.0))
	var fs_score := int(clampf(min(H * 0.21, W * 0.36), 46.0, 120.0))
	var fs_tempo_titulo := int(clampf(H * 0.028, 11.0, 19.0))
	var fs_tempo := int(clampf(H * 0.086, 28.0, 54.0))
	var fs_status := int(clampf(H * 0.038, 15.0, 26.0))

	# centros verticais proporcionais (sempre bem distribuídos)
	var c_titulo := H * 0.085
	var c_gol_label := H * 0.275
	var c_score := H * 0.440
	var c_tempo_label := H * 0.670
	var c_tempo := H * 0.780
	var c_status := H * 0.910

	var style := StyleBoxFlat.new()
	style.bg_color = Color(cor.r * 0.035, cor.g * 0.035, cor.b * 0.035, 0.96)
	style.border_color = Color(cor.r, cor.g, cor.b, 0.35)
	style.set_border_width_all(3)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(cor.r, cor.g, cor.b, 0.20)
	style.shadow_size = 10
	style.shadow_offset = Vector2.ZERO
	panel.add_theme_stylebox_override("panel", style)

	# faixa decorativa no topo
	var faixa := ColorRect.new()
	faixa.color = Color(cor.r, cor.g, cor.b, 0.22)
	faixa.position = Vector2(22, max(H * 0.025, 12.0))
	faixa.size = Vector2(max(W - 44.0, 20.0), 4)
	panel.add_child(faixa)

	# TÍTULO
	var titulo := _novo_label_card("PLAYER %d" % [index + 1], W, c_titulo, fs_titulo, cor)
	titulo.add_theme_color_override("font_shadow_color", cor)
	panel.add_child(titulo)

	# rótulo GOL
	var score_titulo := _novo_label_card("GOL", W, c_gol_label, fs_score_titulo, Color(0.75, 0.84, 0.90))
	panel.add_child(score_titulo)

	# número GOL (herói)
	var score := _novo_label_card("0", W, c_score, fs_score, Color.WHITE)
	score.add_theme_color_override("font_shadow_color", cor)
	panel.add_child(score)

	# rótulo TEMPO
	var tempo_titulo := _novo_label_card("TEMPO", W, c_tempo_label, fs_tempo_titulo, Color(0.65, 0.72, 0.78))
	panel.add_child(tempo_titulo)

	# número TEMPO
	var tempo := _novo_label_card(str(int(TEMPO_POR_PLAYER)), W, c_tempo, fs_tempo, Color(1.0, 0.85, 0.08))
	tempo.add_theme_color_override("font_shadow_color", Color(1.0, 0.4, 0.05))
	panel.add_child(tempo)

	# STATUS
	var status := _novo_label_card("AGUARDANDO", W, c_status, fs_status, Color(0.65, 0.7, 0.75))
	panel.add_child(status)

	# rodada (mantida só por compatibilidade com o _atualizar_hud, fica invisível)
	var rodada := Label.new()
	rodada.text = ""
	rodada.position = Vector2(0, H - 4)
	rodada.size = Vector2(W, 2)
	panel.add_child(rodada)
	
	var medalha := _criar_medalha_ranking(panel, cor, 1, 0.82)
	medalha.position = Vector2(panel.size.x - 92.0, 12.0)
	medalha.visible = false
	panel.add_child(medalha)
	medalhas_players.append(medalha)

	player_panels.append(panel)
	score_labels.append(score)
	tempo_labels.append(tempo)
	status_labels.append(status)
	rodada_labels.append(rodada)


func _criar_medalha_ranking(panel: Panel, cor_player: Color, posicao: int, escala_base: float = 1.0) -> Control:
	var root_medalha := Control.new()
	root_medalha.name = "MedalhaRanking"
	root_medalha.size = Vector2(92, 96) * escala_base
	root_medalha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_medalha.z_index = 120

	var cor_base := Color(1.0, 0.70, 0.06)
	var cor_borda := Color(1.0, 0.96, 0.45)
	var cor_sombra := Color(1.0, 0.75, 0.08, 0.72)
	var cor_texto := Color(0.18, 0.10, 0.01)

	if posicao == 2:
		cor_base = Color(0.76, 0.80, 0.86)
		cor_borda = Color(0.96, 0.98, 1.0)
		cor_sombra = Color(0.72, 0.82, 1.0, 0.60)
		cor_texto = Color(0.08, 0.10, 0.13)
	elif posicao == 3:
		cor_base = Color(0.78, 0.39, 0.14)
		cor_borda = Color(1.0, 0.68, 0.34)
		cor_sombra = Color(1.0, 0.45, 0.16, 0.62)
		cor_texto = Color(0.16, 0.07, 0.02)

	# fitas superiores
	var fita_esq := Panel.new()
	fita_esq.size = Vector2(24, 34) * escala_base
	fita_esq.position = Vector2(23, 0) * escala_base
	fita_esq.rotation = deg_to_rad(-10)
	fita_esq.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_medalha.add_child(fita_esq)

	var fita_esq_style := StyleBoxFlat.new()
	fita_esq_style.bg_color = cor_player.darkened(0.10)
	fita_esq_style.border_color = Color.WHITE
	fita_esq_style.set_border_width_all(int(1 * escala_base))
	fita_esq_style.set_corner_radius_all(int(6 * escala_base))
	fita_esq.add_theme_stylebox_override("panel", fita_esq_style)

	var fita_dir := Panel.new()
	fita_dir.size = Vector2(24, 34) * escala_base
	fita_dir.position = Vector2(45, 0) * escala_base
	fita_dir.rotation = deg_to_rad(10)
	fita_dir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_medalha.add_child(fita_dir)

	var fita_dir_style := StyleBoxFlat.new()
	fita_dir_style.bg_color = cor_player.lightened(0.18)
	fita_dir_style.border_color = Color.WHITE
	fita_dir_style.set_border_width_all(int(1 * escala_base))
	fita_dir_style.set_corner_radius_all(int(6 * escala_base))
	fita_dir.add_theme_stylebox_override("panel", fita_dir_style)

	# sombra externa
	var sombra := Panel.new()
	sombra.size = Vector2(76, 76) * escala_base
	sombra.position = Vector2(8, 18) * escala_base
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_medalha.add_child(sombra)

	var sombra_style := StyleBoxFlat.new()
	sombra_style.bg_color = Color(0, 0, 0, 0.26)
	sombra_style.set_corner_radius_all(int(38 * escala_base))
	sombra_style.shadow_color = cor_sombra
	sombra_style.shadow_size = int(22 * escala_base)
	sombra_style.shadow_offset = Vector2.ZERO
	sombra.add_theme_stylebox_override("panel", sombra_style)

	# medalha externa
	var medalha := Panel.new()
	medalha.size = Vector2(72, 72) * escala_base
	medalha.position = Vector2(10, 14) * escala_base
	medalha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_medalha.add_child(medalha)

	var medalha_style := StyleBoxFlat.new()
	medalha_style.bg_color = cor_base
	medalha_style.border_color = cor_borda
	medalha_style.set_border_width_all(int(5 * escala_base))
	medalha_style.set_corner_radius_all(int(36 * escala_base))
	medalha_style.shadow_color = cor_sombra
	medalha_style.shadow_size = int(18 * escala_base)
	medalha_style.shadow_offset = Vector2.ZERO
	medalha.add_theme_stylebox_override("panel", medalha_style)

	# aro interno
	var aro := Panel.new()
	aro.size = Vector2(54, 54) * escala_base
	aro.position = Vector2(9, 9) * escala_base
	aro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	medalha.add_child(aro)

	var aro_style := StyleBoxFlat.new()
	aro_style.bg_color = Color(0, 0, 0, 0)
	aro_style.border_color = Color(1, 1, 1, 0.38)
	aro_style.set_border_width_all(int(3 * escala_base))
	aro_style.set_corner_radius_all(int(27 * escala_base))
	aro.add_theme_stylebox_override("panel", aro_style)

	# brilho diagonal
	var brilho := Panel.new()
	brilho.size = Vector2(42, 16) * escala_base
	brilho.position = Vector2(15, 12) * escala_base
	brilho.rotation = deg_to_rad(-18)
	brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brilho.modulate = Color(1, 1, 1, 0.72)
	medalha.add_child(brilho)

	var brilho_style := StyleBoxFlat.new()
	brilho_style.bg_color = Color(1, 1, 1, 0.28)
	brilho_style.set_corner_radius_all(int(10 * escala_base))
	brilho.add_theme_stylebox_override("panel", brilho_style)

	# número central
	var numero := Label.new()
	numero.text = str(posicao)
	numero.set_anchors_preset(Control.PRESET_FULL_RECT)
	numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	numero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	numero.add_theme_font_size_override("font_size", int(38 * escala_base))
	numero.add_theme_color_override("font_color", cor_texto)
	numero.add_theme_color_override("font_shadow_color", Color.WHITE)
	numero.add_theme_constant_override("shadow_offset_x", 0)
	numero.add_theme_constant_override("shadow_offset_y", 0)

	if fonte_orbitron:
		numero.add_theme_font_override("font", fonte_orbitron)

	medalha.add_child(numero)

	# base inferior na cor do player
	var base := Panel.new()
	base.size = Vector2(56, 11) * escala_base
	base.position = Vector2(18, 83) * escala_base
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_medalha.add_child(base)

	var base_style := StyleBoxFlat.new()
	base_style.bg_color = cor_player
	base_style.border_color = Color.WHITE
	base_style.set_border_width_all(int(1 * escala_base))
	base_style.set_corner_radius_all(int(7 * escala_base))
	base_style.shadow_color = Color(cor_player.r, cor_player.g, cor_player.b, 0.75)
	base_style.shadow_size = int(8 * escala_base)
	base.add_theme_stylebox_override("panel", base_style)

	return root_medalha



func _posicoes_atuais_players() -> Dictionary:
	var lista: Array[Dictionary] = []

	for i in range(total_players):
		lista.append({
			"index": i,
			"score": scores[i]
		})

	lista.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["score"]) == int(b["score"]):
			return int(a["index"]) < int(b["index"])
		return int(a["score"]) > int(b["score"])
	)

	var posicoes: Dictionary = {}
	var posicao_atual := 1
	var ultimo_score := -999999

	for i in range(lista.size()):
		var score_atual := int(lista[i]["score"])

		if i == 0:
			posicao_atual = 1
		elif score_atual < ultimo_score:
			posicao_atual = i + 1

		posicoes[int(lista[i]["index"])] = posicao_atual
		ultimo_score = score_atual

	return posicoes


func _atualizar_medalhas_lider() -> void:
	if medalhas_players.size() < total_players:
		return
	if scores.size() < total_players:
		return

	var maior_score := -999999
	for i in range(total_players):
		if scores[i] > maior_score:
			maior_score = scores[i]

	if maior_score <= 0:
		for m in medalhas_players:
			if is_instance_valid(m):
				m.visible = false
				m.scale = Vector2.ONE
				m.modulate = Color.WHITE
		return

	var posicoes := _posicoes_atuais_players()

	for i in range(total_players):
		var medalha := medalhas_players[i]
		if not is_instance_valid(medalha):
			continue

		var pos := int(posicoes.get(i, 99))
		var deve_mostrar := pos >= 1 and pos <= 3 and scores[i] > 0

		if not deve_mostrar:
			medalha.visible = false
			medalha.scale = Vector2.ONE
			medalha.modulate = Color.WHITE
			continue

		# Se mudou a posição, recria a medalha com ouro/prata/bronze certo.
		if medalha.get_meta("posicao", 0) != pos:
			var panel := player_panels[i]
			var nova := _criar_medalha_ranking(panel, cores_players[i], pos, 0.82)
			nova.position = Vector2(panel.size.x - 92.0, 12.0)
			nova.visible = true
			nova.set_meta("posicao", pos)

			panel.add_child(nova)
			medalha.queue_free()
			medalhas_players[i] = nova
			medalha = nova

			medalha.scale = Vector2(0.45, 0.45)
			medalha.modulate = Color(1, 1, 1, 0)

			var t := create_tween()
			t.set_parallel(true)
			t.tween_property(medalha, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t.tween_property(medalha, "modulate", Color.WHITE, 0.22)
		else:
			medalha.visible = true
			var pulso := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 280.0)
			medalha.scale = Vector2.ONE * (1.0 + pulso * 0.025)



func _criar_overlay_turno() -> void:
	overlay_layer = CanvasLayer.new()
	add_child(overlay_layer)

	overlay_fundo = ColorRect.new()
	overlay_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_fundo.color = Color(0, 0, 0, 0.0)
	overlay_layer.add_child(overlay_fundo)

	overlay_panel = Panel.new()
	overlay_panel.size = Vector2(760, 300)
	overlay_panel.position = Vector2(
		(get_viewport().get_visible_rect().size.x - overlay_panel.size.x) / 2.0,
		(get_viewport().get_visible_rect().size.y - overlay_panel.size.y) / 2.0
	)
	overlay_panel.scale = Vector2(0.94, 0.94)
	overlay_panel.modulate = Color(1, 1, 1, 0)
	overlay_layer.add_child(overlay_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.010, 0.014, 0.020, 0.97)
	style.border_color = Color(0.1, 0.75, 1.0, 1.0)
	style.set_border_width_all(4)
	style.set_corner_radius_all(36)
	style.shadow_color = Color(0.1, 0.75, 1.0, 0.72)
	style.shadow_size = 38
	style.shadow_offset = Vector2.ZERO
	overlay_panel.add_theme_stylebox_override("panel", style)

	overlay_titulo = Label.new()
	overlay_titulo.text = ""
	overlay_titulo.position = Vector2(0, 34)
	overlay_titulo.size = Vector2(760, 62)
	overlay_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_titulo.add_theme_font_size_override("font_size", 42)
	overlay_titulo.add_theme_color_override("font_color", Color.WHITE)
	overlay_titulo.add_theme_constant_override("shadow_offset_x", 0)
	overlay_titulo.add_theme_constant_override("shadow_offset_y", 0)

	if fonte_orbitron:
		overlay_titulo.add_theme_font_override("font", fonte_orbitron)

	overlay_panel.add_child(overlay_titulo)

	overlay_numero = Label.new()
	overlay_numero.text = ""
	overlay_numero.position = Vector2(0, 104)
	overlay_numero.size = Vector2(760, 92)
	overlay_numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_numero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_numero.add_theme_font_size_override("font_size", 72)
	overlay_numero.add_theme_color_override("font_color", Color(1.0, 0.85, 0.08))
	overlay_numero.add_theme_color_override("font_shadow_color", Color(1.0, 0.35, 0.05))
	overlay_numero.add_theme_constant_override("shadow_offset_x", 0)
	overlay_numero.add_theme_constant_override("shadow_offset_y", 0)

	if fonte_orbitron:
		overlay_numero.add_theme_font_override("font", fonte_orbitron)

	overlay_panel.add_child(overlay_numero)

	overlay_subtitulo = Label.new()
	overlay_subtitulo.text = ""
	overlay_subtitulo.position = Vector2(0, 212)
	overlay_subtitulo.size = Vector2(760, 46)
	overlay_subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_subtitulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_subtitulo.add_theme_font_size_override("font_size", 22)
	overlay_subtitulo.add_theme_color_override("font_color", Color(0.65, 1.0, 0.75))

	if fonte_orbitron:
		overlay_subtitulo.add_theme_font_override("font", fonte_orbitron)

	overlay_panel.add_child(overlay_subtitulo)


func _texto_placar_gols() -> String:
	var partes: Array[String] = []

	for i in range(total_players):
		if i < scores.size():
			partes.append(str(scores[i]))
		else:
			partes.append("0")

	return "PLACAR: " + " x ".join(partes)

func _mostrar_preparacao_player() -> void:
	partida_ativa = false
	aguardando_start_turno = true
	em_contagem_inicio = false
	
	_tocar_musica_do_player(player_atual)

	var cor := cores_players[player_atual]

	overlay_titulo.text = "PLAYER %d" % [player_atual + 1]
	overlay_numero.text = "PRONTO?"
	overlay_subtitulo.text = "APERTE START PARA COMEÇAR"
	overlay_titulo.add_theme_color_override("font_shadow_color", cor)
	overlay_numero.add_theme_color_override("font_color", cor)
	overlay_numero.add_theme_color_override("font_shadow_color", cor)

	_set_overlay_cor(cor)
	_mostrar_overlay()
	_atualizar_hud()
	_animar_painel_atual()


func _iniciar_contagem_turno() -> void:
	if em_contagem_inicio:
		return

	em_contagem_inicio = true
	aguardando_start_turno = false

	await _rodar_contagem_inicio()
	_iniciar_turno_player()


func _rodar_contagem_inicio() -> void:
	var cor := cores_players[player_atual]

	overlay_titulo.text = "PLAYER %d PREPARE-SE" % [player_atual + 1]
	overlay_subtitulo.text = "VALENDO EM..."

	for n in range(TEMPO_CONTAGEM_INICIAL, 0, -1):
		overlay_numero.text = str(n)
		overlay_numero.scale = Vector2(1.35, 1.35)
		overlay_numero.add_theme_color_override("font_color", Color(1.0, 0.85, 0.08))
		overlay_numero.add_theme_color_override("font_shadow_color", Color(1.0, 0.35, 0.05))

		var t := create_tween()
		t.tween_property(overlay_numero, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		await get_tree().create_timer(0.85).timeout

	overlay_titulo.text = "VAI!"
	overlay_numero.text = ""
	overlay_subtitulo.text = "MARQUE O MÁXIMO DE GOLS"
	overlay_titulo.add_theme_color_override("font_shadow_color", cor)

	await get_tree().create_timer(0.45).timeout



func _iniciar_turno_player() -> void:
	partida_ativa = true
	em_contagem_inicio = false

	await _esconder_overlay()

	leds_ativos.clear()
	cores_leds_ativos.clear()
	_gols_timestamps.clear()
	_acertos_torcida = 0

	var agora := float(Time.get_ticks_msec())
	_ultimo_motivacional_ms = agora
	_ultimo_acerto_ms = agora
	_ultimo_ponto_ms = agora
	_ultima_pressao_ms = agora

	_atualizar_leds_hud()
	_serial_write("OFF")

	_tocar_apito_init()

	await get_tree().create_timer(0.18).timeout

	_sortear_novo_grupo_de_fileiras()

	# incentivo da torcida sempre que o player começa (forçado pra garantir)
	_tocar_som_da_lista(SONS_TURNO_BOM, "inicio_turno", 1.0, true)

	_atualizar_hud()


func _avaliar_motivacao() -> void:
	if not partida_ativa:
		return
	if sfx_reativo == null or sfx_reativo.playing:
		return   # canal ocupado: não atropela a torcida

	if player_atual < 0 or player_atual >= total_players:
		return

	var agora := float(Time.get_ticks_msec())
	if agora - _ultimo_motivacional_ms < MOTIVACIONAL_INTERVALO_MS:
		return

	# tempo já jogado neste turno
	var decorrido: float = TEMPO_POR_PLAYER - tempos[player_atual]
	if decorrido < 5.0:
		return   # espera uns segundos antes de avaliar

	# ritmo de gols por segundo
	var ritmo: float = float(scores[player_atual]) / max(decorrido, 1.0)

	if ritmo >= MOTIVACIONAL_RITMO_BOM:
		_ultimo_motivacional_ms = agora
		_tocar_som_da_lista(SONS_TURNO_BOM, "motivacao", 1.0)



func _sortear_novo_grupo_de_fileiras() -> void:
	leds_ativos.clear()
	cores_leds_ativos.clear()

	qtd_leds_alvo_atual = randi_range(LEDS_ATIVOS_MIN, LEDS_ATIVOS_MAX)
	qtd_leds_alvo_atual = clamp(qtd_leds_alvo_atual, 1, LEDS_TOTAL)

	while leds_ativos.size() < qtd_leds_alvo_atual:
		var novo: int = _sortear_led_disponivel()

		if novo < 0:
			break

		if not leds_ativos.has(novo):
			leds_ativos.append(novo)
			cores_leds_ativos[novo] = _rgb_aleatorio_alvo()

	print("================================")
	print("NOVO GRUPO SORTEADO PARA O PLAYER ", player_atual + 1)
	print("QUANTIDADE: ", leds_ativos.size())
	print("SENSORES/FILEIRAS ATIVAS: ", _texto_fileiras_ativas())
	print("CORES RGB DOS ALVOS: ", cores_leds_ativos)
	print("================================")

	_atualizar_leds_hud()
	_enviar_leds_para_arduino()


func _mostrar_overlay() -> void:
	overlay_layer.visible = true

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(overlay_fundo, "color", Color(0, 0, 0, 0.62), 0.22)
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
	style.border_color = cor
	style.shadow_color = Color(cor.r, cor.g, cor.b, 0.72)


func _animar_painel_atual() -> void:
	if player_atual < 0 or player_atual >= player_panels.size():
		return

	var panel := player_panels[player_atual]
	panel.scale = Vector2(1.025, 1.025)

	var t := create_tween()
	t.tween_property(panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _atualizar_hud() -> void:
	if total_players <= 0:
		return

	if player_panels.size() < total_players:
		return
	if score_labels.size() < total_players:
		return
	if tempo_labels.size() < total_players:
		return
	if status_labels.size() < total_players:
		return
	if rodada_labels.size() < total_players:
		return
	if scores.size() < total_players:
		return
	if tempos.size() < total_players:
		return
	if terminou_player.size() < total_players:
		return


	for i in range(total_players):
		if not is_instance_valid(player_panels[i]):
			continue
		if not is_instance_valid(score_labels[i]):
			continue
		if not is_instance_valid(tempo_labels[i]):
			continue
		if not is_instance_valid(status_labels[i]):
			continue
		if not is_instance_valid(rodada_labels[i]):
			continue

		score_labels[i].text = str(scores[i])
		tempo_labels[i].text = str(int(ceil(tempos[i])))
		rodada_labels[i].text = ""

		var style := player_panels[i].get_theme_stylebox("panel") as StyleBoxFlat
		if style == null:
			continue

		var cor := cores_players[i]

		if terminou_player[i]:
			status_labels[i].text = "FINALIZADO"
			status_labels[i].add_theme_color_override("font_color", Color(0.55, 0.58, 0.62))

			style.bg_color = Color(0.018, 0.018, 0.020, 0.96)
			style.border_color = Color(0.25, 0.25, 0.25)
			style.shadow_color = Color(0, 0, 0, 0.4)
			style.shadow_size = 6

			player_panels[i].modulate = Color(0.72, 0.72, 0.72, 1.0)

		elif i == player_atual:
			if partida_ativa:
				status_labels[i].text = "JOGANDO AGORA"
			elif aguardando_start_turno:
				status_labels[i].text = "APERTE START"
			else:
				status_labels[i].text = "PREPARANDO"

			status_labels[i].add_theme_color_override("font_color", cor)

			# pulso de "respiração" no brilho do card ativo
			var pulso := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 340.0)

			style.bg_color = Color(cor.r * 0.065, cor.g * 0.065, cor.b * 0.065, 0.98)
			style.border_color = Color(cor.r, cor.g, cor.b, 0.65 + pulso * 0.35)
			style.shadow_color = Color(cor.r, cor.g, cor.b, 0.55 + pulso * 0.35)
			style.shadow_size = int(26.0 + pulso * 20.0)

			player_panels[i].modulate = Color(1, 1, 1, 1)

		else:
			status_labels[i].text = "AGUARDANDO"
			status_labels[i].add_theme_color_override("font_color", Color(0.45, 0.48, 0.52))

			style.bg_color = Color(cor.r * 0.025, cor.g * 0.025, cor.b * 0.025, 0.94)
			style.border_color = Color(cor.r, cor.g, cor.b, 0.30)
			style.shadow_color = Color(cor.r, cor.g, cor.b, 0.18)
			style.shadow_size = 8

			player_panels[i].modulate = Color(0.58, 0.58, 0.58, 1.0)
	
	_atualizar_medalhas_lider()


func _explosao_gol(index: int) -> void:
	if index < 0 or index >= player_panels.size():
		return

	var panel: Panel = player_panels[index]
	var cor: Color = cores_players[index]

	var W: float = float(panel.size.x)
	var H: float = float(panel.size.y)
	var centro: Vector2 = Vector2(W, H) * 0.5
	var ref: float = min(W, H)

	# --- burst central (clarão) ---
	var burst: Panel = Panel.new()
	var burst_tam: float = ref * 0.18

	burst.size = Vector2(burst_tam, burst_tam)
	burst.position = centro - burst.size * 0.5
	burst.pivot_offset = burst.size * 0.5
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.z_index = 78

	var bs: StyleBoxFlat = StyleBoxFlat.new()
	bs.bg_color = Color(1, 1, 1, 0.85)
	bs.set_corner_radius_all(int(burst_tam * 0.5))
	bs.shadow_color = Color(cor.r, cor.g, cor.b, 0.9)
	bs.shadow_size = int(ref * 0.06)
	burst.add_theme_stylebox_override("panel", bs)
	panel.add_child(burst)

	var tb: Tween = create_tween()
	tb.set_parallel(true)
	tb.tween_property(burst, "scale", Vector2(2.2, 2.2), 0.28) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tb.tween_property(burst, "modulate", Color(1, 1, 1, 0), 0.30) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tb.chain().tween_callback(burst.queue_free)

	# --- ondas de choque ---
	for k: int in range(3):
		var ring: Panel = Panel.new()
		var tam0: float = ref * 0.14

		ring.size = Vector2(tam0, tam0)
		ring.position = centro - ring.size * 0.5
		ring.pivot_offset = ring.size * 0.5
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.z_index = 80

		var rs: StyleBoxFlat = StyleBoxFlat.new()
		rs.bg_color = Color(0, 0, 0, 0)
		rs.border_color = Color(cor.r, cor.g, cor.b, 0.95)
		rs.set_border_width_all(max(int(ref * 0.012), 3))
		rs.set_corner_radius_all(int(tam0 * 0.5))
		ring.add_theme_stylebox_override("panel", rs)
		panel.add_child(ring)

		var diam_final: float = ref * (0.85 + float(k) * 0.18)
		var escala_final: float = diam_final / tam0
		var dur: float = 0.55 + float(k) * 0.12
		var delay_k: float = float(k) * 0.07

		@warning_ignore("shadowed_variable_base_class")
		var tr: Tween = create_tween()
		tr.set_parallel(true)
		tr.tween_property(ring, "scale", Vector2(escala_final, escala_final), dur) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay_k)
		tr.tween_property(ring, "modulate", Color(1, 1, 1, 0), dur) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay_k)
		tr.chain().tween_callback(ring.queue_free)

	# --- faíscas / confetes ---
	var paleta: Array[Color] = [
		Color(1.0, 0.85, 0.08),
		Color(1.0, 0.35, 0.25),
		cor,
		Color.WHITE,
		Color(0.2, 0.9, 1.0),
	]

	for i: int in range(24):
		var faisca: ColorRect = ColorRect.new()

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

		var tmov: Tween = create_tween()
		tmov.tween_property(faisca, "position", destino, dur_faisca * 0.4) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tmov.tween_property(faisca, "position", queda, dur_faisca * 0.6) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tmov.tween_callback(faisca.queue_free)

		var tvis: Tween = create_tween()
		tvis.set_parallel(true)
		tvis.tween_property(
			faisca,
			"rotation",
			faisca.rotation + randf_range(-6.0, 6.0),
			dur_faisca
		)
		tvis.tween_property(
			faisca,
			"modulate",
			Color(1, 1, 1, 0),
			dur_faisca * 0.6
		).set_delay(dur_faisca * 0.4)



func _finalizar_turno_player() -> void:
	if player_atual < 0 or player_atual >= total_players:
		return

	partida_ativa = false
	leds_ativos.clear()
	cores_leds_ativos.clear()
	_atualizar_leds_hud()
	_enviar_leds_para_arduino()

	_tocar_apito_fim()

	terminou_player[player_atual] = true
	_atualizar_hud()

	_tocar_som_fim_turno_reativo(player_atual)

	var player_finalizado := player_atual
	var proximo := -1

	for i in range(total_players):
		if not terminou_player[i]:
			proximo = i
			break

	if proximo == -1:
		await _mostrar_aviso_turno(
			"TEMPO ESGOTADO",
			"PLAYER %d FINALIZOU COM %d GOLS" % [player_finalizado + 1, scores[player_finalizado]],
			cores_players[player_finalizado]
		)

		_finalizar_partida()
	else:
		await _mostrar_aviso_turno(
			"TEMPO ESGOTADO",
			"PLAYER %d FEZ %d GOLS  •  PRÓXIMO: PLAYER %d" % [
				player_finalizado + 1,
				scores[player_finalizado],
				proximo + 1
			],
			cores_players[player_finalizado]
		)

		_tocar_apito_troca()

		player_atual = proximo
		_reconstruir_paineis()
		await get_tree().create_timer(0.25).timeout
		_mostrar_preparacao_player()



func _mostrar_aviso_turno(titulo_texto: String, subtitulo_texto: String, cor: Color) -> void:
	turno_layer = CanvasLayer.new()
	add_child(turno_layer)

	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0, 0, 0, 0.0)
	turno_layer.add_child(fundo)

	turno_panel = Panel.new()
	turno_panel.size = Vector2(860, 250)
	turno_panel.position = Vector2(
		(get_viewport().get_visible_rect().size.x - turno_panel.size.x) / 2.0,
		(get_viewport().get_visible_rect().size.y - turno_panel.size.y) / 2.0
	)
	turno_panel.scale = Vector2(0.92, 0.92)
	turno_panel.modulate = Color(1, 1, 1, 0)
	turno_layer.add_child(turno_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.010, 0.014, 0.020, 0.97)
	style.border_color = cor
	style.set_border_width_all(4)
	style.set_corner_radius_all(36)
	style.shadow_color = Color(cor.r, cor.g, cor.b, 0.78)
	style.shadow_size = 40
	style.shadow_offset = Vector2.ZERO
	turno_panel.add_theme_stylebox_override("panel", style)

	turno_titulo = Label.new()
	turno_titulo.text = titulo_texto
	turno_titulo.position = Vector2(0, 42)
	turno_titulo.size = Vector2(860, 70)
	turno_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turno_titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if fonte_orbitron:
		turno_titulo.add_theme_font_override("font", fonte_orbitron)

	turno_titulo.add_theme_font_size_override("font_size", 44)
	turno_titulo.add_theme_color_override("font_color", Color.WHITE)
	turno_titulo.add_theme_color_override("font_shadow_color", cor)
	turno_titulo.add_theme_constant_override("shadow_offset_x", 0)
	turno_titulo.add_theme_constant_override("shadow_offset_y", 0)
	turno_panel.add_child(turno_titulo)

	turno_subtitulo = Label.new()
	turno_subtitulo.text = subtitulo_texto
	turno_subtitulo.position = Vector2(40, 130)
	turno_subtitulo.size = Vector2(780, 70)
	turno_subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turno_subtitulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turno_subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if fonte_orbitron:
		turno_subtitulo.add_theme_font_override("font", fonte_orbitron)

	turno_subtitulo.add_theme_font_size_override("font_size", 24)
	turno_subtitulo.add_theme_color_override("font_color", Color(0.78, 0.90, 0.95))
	turno_panel.add_child(turno_subtitulo)

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(fundo, "color", Color(0, 0, 0, 0.68), 0.22)
	t.tween_property(turno_panel, "modulate", Color.WHITE, 0.22)
	t.tween_property(turno_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await t.finished
	await get_tree().create_timer(1.45).timeout

	var out := create_tween()
	out.set_parallel(true)
	out.tween_property(fundo, "color", Color(0, 0, 0, 0.0), 0.20)
	out.tween_property(turno_panel, "modulate", Color(1, 1, 1, 0), 0.20)
	out.tween_property(turno_panel, "scale", Vector2(0.94, 0.94), 0.20)

	await out.finished

	if turno_layer:
		turno_layer.queue_free()

	turno_layer = null
	turno_panel = null



func registrar_ponto(valor: int = 1) -> void:
	if not partida_ativa:
		return

	if player_atual < 0 or player_atual >= total_players:
		return

	var score_antes: int = scores[player_atual]
	scores[player_atual] += valor

	# som do gol
	if sfx_ponto and sfx_ponto.stream:
		sfx_ponto.stop()
		sfx_ponto.play()

	# SUPERAR AO VIVO: ao passar um adversário, SEMPRE toca o som bom (forçado).
	var superou_agora := false
	for j in range(total_players):
		if j == player_atual:
			continue
		if not terminou_player[j]:
			continue
		if scores[j] <= 0:
			continue
		if _superou_adversario[player_atual][j]:
			continue
		if score_antes <= scores[j] and scores[player_atual] > scores[j]:
			_superou_adversario[player_atual][j] = true
			_tocar_som_da_lista(SONS_SUPEROU_LIVE, "superou_live", 1.5, true)
			superou_agora = true
			break

	# A cada 10 pontos a torcida canta automaticamente.
	_acertos_torcida += valor
	if _acertos_torcida >= PONTOS_PARA_TORCIDA:
		_acertos_torcida = 0
		if not superou_agora:
			_tocar_som_da_lista(SONS_TURNO_BOM, "torcida_10", 1.5)

	# Se for o último a jogar e cravar o título, solta o grito de campeão.
	_verificar_vitoria_antecipada()

	# efeitos visuais
	_animar_score(player_atual)
	_efeito_gol_card(player_atual)
	_explosao_gol(player_atual)
	_mostrar_popup_ponto(player_atual, valor)
	_atualizar_hud()


func _tocar_campeao_agora() -> void:
	if sfx_campeao == null:
		return

	if sfx_campeao.stream == null:
		return

	_reativo_bloqueado_por_campeao = true
	_campeao_pendente = false

	if sfx_reativo and sfx_reativo.playing:
		sfx_reativo.stop()

	if sfx_campeao.stream is AudioStreamMP3:
		sfx_campeao.stream.loop = false

	sfx_campeao.stop()
	sfx_campeao.play()

	print("SOM DE CAMPEÃO TOCANDO AGORA")



func _verificar_vitoria_antecipada() -> void:
	if _vitoria_antecipada_tocada:
		return
	if total_players < 2:
		return
	if player_atual < 0 or player_atual >= total_players:
		return

	# Só vale se este é o ÚLTIMO a jogar:
	# todos os outros já terminaram.
	for j in range(total_players):
		if j == player_atual:
			continue
		if not terminou_player[j]:
			return

	# Ultrapassou a pontuação de TODOS?
	for j in range(total_players):
		if j == player_atual:
			continue
		if scores[player_atual] <= scores[j]:
			return

	_vitoria_antecipada_tocada = true

	# Se está tocando um canto de superação, espera terminar.
	if sfx_reativo and sfx_reativo.playing:
		_campeao_pendente = true
		_reativo_bloqueado_por_campeao = true
		print("CAMPEÃO ANTECIPADO PENDENTE: aguardando som reativo terminar.")
		return

	_tocar_campeao_agora()

	print("VITÓRIA ANTECIPADA: PLAYER ", player_atual + 1, " já garantiu o título!")


func _mostrar_popup_ponto(index: int, valor: int) -> void:
	if index < 0 or index >= player_panels.size():
		return

	var panel := player_panels[index]
	var cor := cores_players[index]
	var W := panel.size.x
	var H := panel.size.y

	var fs_gol := int(clampf(min(H * 0.16, W * 0.28), 32.0, 76.0))
	var fs_sub := int(float(fs_gol) * 0.62)

	var c_inicio := H * 0.44
	var subida := H * 0.22

	var popup := Label.new()
	popup.text = "GOOOL!"
	popup.size = Vector2(W, fs_gol + 16)
	popup.position = Vector2(0, c_inicio - popup.size.y * 0.5)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.z_index = 95
	popup.pivot_offset = popup.size * 0.5

	if fonte_orbitron:
		popup.add_theme_font_override("font", fonte_orbitron)

	popup.add_theme_font_size_override("font_size", fs_gol)
	popup.add_theme_color_override("font_color", Color.WHITE)
	popup.add_theme_color_override("font_shadow_color", cor)
	popup.add_theme_constant_override("shadow_offset_x", 0)
	popup.add_theme_constant_override("shadow_offset_y", 0)
	panel.add_child(popup)

	var sub := Label.new()
	sub.text = "+%d" % valor
	sub.size = Vector2(W, fs_sub + 10)
	sub.position = Vector2(0, c_inicio + popup.size.y * 0.5)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub.z_index = 95
	sub.pivot_offset = sub.size * 0.5

	if fonte_orbitron:
		sub.add_theme_font_override("font", fonte_orbitron)

	sub.add_theme_font_size_override("font_size", fs_sub)
	sub.add_theme_color_override("font_color", cor)
	sub.add_theme_color_override("font_shadow_color", cor)
	sub.add_theme_constant_override("shadow_offset_x", 0)
	sub.add_theme_constant_override("shadow_offset_y", 0)
	panel.add_child(sub)

	popup.scale = Vector2(0.5, 0.5)
	popup.rotation = deg_to_rad(randf_range(-7.0, 7.0))
	sub.scale = Vector2(0.6, 0.6)

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(popup, "scale", Vector2(1.35, 1.35), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(popup, "rotation", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(sub, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(popup, "position:y", popup.position.y - subida, 0.72).set_delay(0.12)
	t.tween_property(sub, "position:y", sub.position.y - subida, 0.72).set_delay(0.12)
	t.tween_property(popup, "modulate", Color(1, 1, 1, 0), 0.42).set_delay(0.42)
	t.tween_property(sub, "modulate", Color(1, 1, 1, 0), 0.42).set_delay(0.42)

	await t.finished

	if is_instance_valid(popup):
		popup.queue_free()

	if is_instance_valid(sub):
		sub.queue_free()



func registrar_erro(penalidade: int = 0) -> void:
	if not partida_ativa:
		return

	if penalidade > 0:
		scores[player_atual] -= penalidade
		if scores[player_atual] < 0:
			scores[player_atual] = 0

	_atualizar_hud()


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



func _efeito_gol_card(index: int) -> void:
	if index < 0 or index >= player_panels.size():
		return

	var panel := player_panels[index]
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


func _finalizar_partida() -> void:
	partida_finalizada = true
	partida_ativa = false
	_atualizar_hud()

	await get_tree().create_timer(0.25).timeout
	_mostrar_modal_final()



func _montar_ranking() -> Array[Dictionary]:
	var ranking: Array[Dictionary] = []

	for i in range(total_players):
		ranking.append({
			"player": i + 1,
			"score": scores[i],
			"cor": cores_players[i],
			"posicao": 1,
			"empatado": false
		})

	ranking.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["score"]) == int(b["score"]):
			return int(a["player"]) < int(b["player"])

		return int(a["score"]) > int(b["score"])
	)

	var posicao_atual := 1
	var ultimo_score := -999999

	for i in range(ranking.size()):
		var score_atual := int(ranking[i]["score"])

		if i == 0:
			posicao_atual = 1
		elif score_atual < ultimo_score:
			posicao_atual = i + 1

		ranking[i]["posicao"] = posicao_atual
		ultimo_score = score_atual

	for i in range(ranking.size()):
		var score_i := int(ranking[i]["score"])
		var qtd_mesmo_score := 0

		for j in range(ranking.size()):
			if int(ranking[j]["score"]) == score_i:
				qtd_mesmo_score += 1

		ranking[i]["empatado"] = qtd_mesmo_score > 1

	return ranking



func _mostrar_modal_final() -> void:
	_tocar_campeao_loop_modal()

	var ranking := _montar_ranking()

	if ranking.is_empty():
		return

	var maior_score := int(ranking[0]["score"])
	var vencedores: Array[int] = []

	for item in ranking:
		if int(item["score"]) == maior_score:
			vencedores.append(int(item["player"]))

	var empate_geral := (vencedores.size() == total_players and total_players > 1)

	var cor_vencedor: Color = ranking[0]["cor"]
	if empate_geral:
		cor_vencedor = Color(1.0, 0.85, 0.08)

	final_layer = CanvasLayer.new()
	add_child(final_layer)

	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0, 0, 0, 0.0)
	final_layer.add_child(fundo)

	var panel := Panel.new()
	panel.size = Vector2(820, 620)
	panel.clip_contents = false
	panel.position = Vector2(
		(get_viewport().get_visible_rect().size.x - panel.size.x) / 2.0,
		(get_viewport().get_visible_rect().size.y - panel.size.y) / 2.0
	)
	panel.scale = Vector2(0.94, 0.94)
	panel.modulate = Color(1, 1, 1, 0)
	final_layer.add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.010, 0.014, 0.020, 0.97)
	style.border_color = cor_vencedor
	style.set_border_width_all(4)
	style.set_corner_radius_all(36)
	style.shadow_color = Color(cor_vencedor.r, cor_vencedor.g, cor_vencedor.b, 0.75)
	style.shadow_size = 44
	style.shadow_offset = Vector2.ZERO
	panel.add_theme_stylebox_override("panel", style)

	var titulo := Label.new()
	titulo.text = "RESULTADO FINAL"
	titulo.position = Vector2(0, 30)
	titulo.size = Vector2(820, 58)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 42)
	titulo.add_theme_color_override("font_color", Color.WHITE)
	titulo.add_theme_color_override("font_shadow_color", cor_vencedor)
	titulo.add_theme_constant_override("shadow_offset_x", 0)
	titulo.add_theme_constant_override("shadow_offset_y", 0)

	if fonte_orbitron:
		titulo.add_theme_font_override("font", fonte_orbitron)

	panel.add_child(titulo)

	var y := 118.0
	var altura_linha := 74.0
	var passo := 88.0

	for i in range(ranking.size()):
		var item := ranking[i]
		var cor: Color = item["cor"]
		var posicao_item := int(item["posicao"])
		var score_item := int(item["score"])
		var player_num := int(item["player"])
		var eh_campeao := posicao_item == 1 and not empate_geral

		var linha := Panel.new()
		linha.position = Vector2(118, y)
		linha.size = Vector2(600, altura_linha)
		linha.pivot_offset = linha.size * 0.5
		linha.clip_contents = false
		panel.add_child(linha)

		var linha_style := StyleBoxFlat.new()

		if eh_campeao:
			linha_style.bg_color = Color(cor.r * 0.16, cor.g * 0.16, cor.b * 0.16, 0.96)
			linha_style.border_color = cor
			linha_style.set_border_width_all(3)
			linha_style.shadow_color = Color(cor.r, cor.g, cor.b, 0.85)
			linha_style.shadow_size = 26
		else:
			linha_style.bg_color = Color(cor.r * 0.06, cor.g * 0.06, cor.b * 0.06, 0.92)
			linha_style.border_color = Color(cor.r, cor.g, cor.b, 0.7)
			linha_style.set_border_width_all(2)
			linha_style.shadow_color = Color(cor.r, cor.g, cor.b, 0.35)
			linha_style.shadow_size = 12

		linha_style.set_corner_radius_all(22)
		linha.add_theme_stylebox_override("panel", linha_style)

		# Medalha somente para 1º, 2º e 3º lugar.
		# 1º = ouro, 2º = prata, 3º = bronze.
		# 4º lugar não recebe medalha.
		if posicao_item >= 1 and posicao_item <= 3:
			var medalha_linha := _criar_medalha_ranking(linha, cor, posicao_item, 0.50)
			medalha_linha.position = Vector2(-62, -6)
			medalha_linha.z_index = 150
			linha.add_child(medalha_linha)

		var texto := Label.new()
		var txt_empate := ""

		if bool(item["empatado"]):
			txt_empate = "  •  EMPATE"

		if eh_campeao:
			texto.text = "CAMPEÃO  •  PLAYER %d  •  %d GOLS" % [
				player_num,
				score_item
			]
		else:
			if posicao_item == 4:
				texto.text = "4º LUGAR  •  PLAYER %d  •  %d GOLS%s" % [
					player_num,
					score_item,
					txt_empate
				]
			else:
				texto.text = "%dº  •  PLAYER %d  •  %d GOLS%s" % [
					posicao_item,
					player_num,
					score_item,
					txt_empate
				]

		# Texto ocupa quase o card inteiro.
		# A medalha fica fora, então não tampa as letras.
		texto.position = Vector2(14, 0)
		texto.size = Vector2(linha.size.x - 28.0, linha.size.y)
		texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		texto.clip_text = true
		texto.autowrap_mode = TextServer.AUTOWRAP_OFF

		var tamanho_texto := 27 if eh_campeao else 24

		if texto.text.length() > 32:
			tamanho_texto -= 2
		if texto.text.length() > 42:
			tamanho_texto -= 2
		if texto.text.length() > 52:
			tamanho_texto -= 2
		if texto.text.length() > 62:
			tamanho_texto -= 2

		texto.add_theme_font_size_override("font_size", max(tamanho_texto, 17))
		texto.add_theme_color_override("font_color", Color.WHITE if eh_campeao else Color(0.85, 0.88, 0.92))
		texto.add_theme_color_override("font_shadow_color", cor)
		texto.add_theme_constant_override("shadow_offset_x", 0)
		texto.add_theme_constant_override("shadow_offset_y", 0)

		if fonte_orbitron:
			texto.add_theme_font_override("font", fonte_orbitron)

		linha.add_child(texto)

		if eh_campeao:
			var pulse := linha.create_tween()
			pulse.set_loops()
			pulse.tween_property(linha, "modulate", Color(1.18, 1.18, 1.18, 1.0), 0.6).set_trans(Tween.TRANS_SINE)
			pulse.tween_property(linha, "modulate", Color(1, 1, 1, 1), 0.6).set_trans(Tween.TRANS_SINE)

		y += passo

	var destaque := Label.new()

	if empate_geral:
		destaque.text = "EMPATE GERAL"
	elif vencedores.size() > 1:
		destaque.text = "EMPATE ENTRE PLAYERS " + ", ".join(vencedores.map(func(v): return str(v)))
	else:
		destaque.text = "VENCEDOR: PLAYER %d" % vencedores[0]

	destaque.position = Vector2(20, 500)
	destaque.size = Vector2(780, 44)
	destaque.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	destaque.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	destaque.clip_text = true
	destaque.add_theme_font_size_override("font_size", 28)
	destaque.add_theme_color_override("font_color", cor_vencedor)
	destaque.add_theme_color_override("font_shadow_color", cor_vencedor)
	destaque.add_theme_constant_override("shadow_offset_x", 0)
	destaque.add_theme_constant_override("shadow_offset_y", 0)

	if fonte_orbitron:
		destaque.add_theme_font_override("font", fonte_orbitron)

	panel.add_child(destaque)

	var dica := Label.new()
	dica.text = "APERTE START PARA JOGAR NOVAMENTE"
	dica.position = Vector2(0, 556)
	dica.size = Vector2(820, 34)
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dica.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dica.add_theme_font_size_override("font_size", 18)
	dica.add_theme_color_override("font_color", Color(0.7, 0.78, 0.85))

	if fonte_orbitron:
		dica.add_theme_font_override("font", fonte_orbitron)

	panel.add_child(dica)

	var t_dica := dica.create_tween()
	t_dica.set_loops()
	t_dica.tween_property(dica, "modulate", Color(1, 1, 1, 0.25), 0.7).set_trans(Tween.TRANS_SINE)
	t_dica.tween_property(dica, "modulate", Color(1, 1, 1, 1.0), 0.7).set_trans(Tween.TRANS_SINE)

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(fundo, "color", Color(0, 0, 0, 0.80), 0.25)
	t.tween_property(panel, "modulate", Color.WHITE, 0.25)
	t.tween_property(panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var confete_root := Control.new()
	confete_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	confete_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	confete_root.z_index = 10
	final_layer.add_child(confete_root)
	_iniciar_chuva_confetes(confete_root, cor_vencedor)

	pode_reiniciar = true
	var meu_token := _final_token
	var restante := int(TEMPO_REINICIO_AUTO)

	while restante > 0:
		dica.text = "APERTE START PARA JOGAR  •  VOLTA AO INÍCIO EM %d" % restante
		await get_tree().create_timer(1.0).timeout

		if not partida_finalizada or meu_token != _final_token:
			return

		restante -= 1

	if partida_finalizada and meu_token == _final_token:
		_voltar_ao_opening()



@warning_ignore("shadowed_variable")
func _iniciar_chuva_confetes(root: Control, cor: Color) -> void:
	var meu_token := _final_token

	while is_instance_valid(root) and partida_finalizada and meu_token == _final_token:
		_spawn_lote_confetes(root, cor)
		await get_tree().create_timer(0.35).timeout


@warning_ignore("shadowed_variable")
func _spawn_lote_confetes(root: Control, cor: Color) -> void:
	if not is_instance_valid(root):
		return

	var tela := get_viewport().get_visible_rect().size
	var clara := cor.lerp(Color.WHITE, 0.45)
	var escura := cor.lerp(Color.BLACK, 0.25)
	var paleta: Array[Color] = [cor, Color.WHITE, clara, escura]

	for i in range(16):
		var c := ColorRect.new()
		var s := randf_range(8.0, 18.0)
		c.size = Vector2(s, s * randf_range(0.5, 1.1))
		c.position = Vector2(randf_range(0.0, tela.x), randf_range(-90.0, -10.0))
		c.color = paleta[int(randi() % paleta.size())]
		c.pivot_offset = c.size * 0.5
		c.rotation = randf_range(0.0, TAU)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.z_index = 60
		root.add_child(c)

		var fim_y := tela.y + randf_range(20.0, 90.0)
		var dur := randf_range(2.0, 3.6)

		var t := c.create_tween()
		t.set_parallel(true)
		t.tween_property(c, "position:y", fim_y, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_property(c, "position:x", c.position.x + randf_range(-60.0, 60.0), dur)
		t.tween_property(c, "rotation", c.rotation + randf_range(-12.0, 12.0), dur)
		t.tween_property(c, "modulate", Color(1, 1, 1, 0), 0.6).set_delay(dur - 0.6)
		t.chain().tween_callback(c.queue_free)



func _voltar_ao_opening() -> void:
	_campeao_pendente = false
	_reativo_bloqueado_por_campeao = false
	_parar_tudo_exceto_musica()
	_parar_campeao()

	_serial_write("OFF")

	if ResourceLoader.exists(CENA_OPENING):
		get_tree().change_scene_to_file(CENA_OPENING)
	else:
		push_warning("Cena opening não encontrada: " + CENA_OPENING)



func _confetes_vencedor(panel: Panel, cor: Color) -> void:
	var W := panel.size.x
	var H := panel.size.y
	var clara := cor.lerp(Color.WHITE, 0.45)
	var paleta: Array[Color] = [cor, Color.WHITE, clara]

	for i in range(70):
		var c := ColorRect.new()
		var s := randf_range(8.0, 16.0)
		c.size = Vector2(s, s * randf_range(0.5, 1.1))
		c.position = Vector2(randf_range(0.0, W), randf_range(-60.0, -10.0))
		c.color = paleta[int(randi() % paleta.size())]
		c.pivot_offset = c.size * 0.5
		c.rotation = randf_range(0.0, TAU)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.z_index = 60
		panel.add_child(c)

		var fim_y := H + randf_range(20.0, 90.0)
		var dur := randf_range(1.6, 2.8)
		var atraso := randf_range(0.0, 1.6)

		var t := c.create_tween()
		t.set_parallel(true)
		t.tween_property(c, "position:y", fim_y, dur).set_delay(atraso).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_property(c, "position:x", c.position.x + randf_range(-50.0, 50.0), dur).set_delay(atraso)
		t.tween_property(c, "rotation", c.rotation + randf_range(-10.0, 10.0), dur).set_delay(atraso)
		t.tween_property(c, "modulate", Color(1, 1, 1, 0), 0.5).set_delay(atraso + dur - 0.5)
		t.chain().tween_callback(c.queue_free)



func _reiniciar_partida() -> void:
	# Em modo crédito, cada nova partida exige outro crédito no menu.
	if ArcadeData.modo_operacao == "credito":
		_voltar_ao_opening()
		return

	# No modo livre, o replay também conta como uma nova utilização.
	ArcadeData.registrar_partida("arcade")
	_final_token += 1
	pode_reiniciar = false

	_campeao_pendente = false
	_reativo_bloqueado_por_campeao = false
	_parar_tudo_exceto_musica()
	_parar_campeao()

	_serial_write("OFF")

	if is_instance_valid(final_layer):
		final_layer.queue_free()
	final_layer = null

	_inicializar_dados()
	_sortear_musicas_players()
	_reconstruir_paineis()

	await get_tree().process_frame

	_mostrar_preparacao_player()



func _exit_tree() -> void:
	_serial_write("OFF")

	if USAR_PONTE_POWERSHELL and caminho_fila_arduino != "":
		var nome_arquivo := "%020d_EXIT.cmd" % Time.get_ticks_msec()
		var caminho_final := caminho_fila_arduino.path_join(nome_arquivo)

		var f := FileAccess.open(caminho_final, FileAccess.WRITE)
		if f:
			f.store_string("__EXIT__")
			f.close()

	if audio_fundo:
		audio_fundo.stop()



func _sortear_musicas_players() -> void:
	musicas_por_player.clear()

	# carrega só as músicas que existem de verdade
	var disponiveis: Array[AudioStream] = []
	for caminho in MUSICAS_PLAYERS:
		if ResourceLoader.exists(caminho):
			var s: AudioStream = load(caminho)
			if s is AudioStreamMP3:
				s.loop = true
			disponiveis.append(s)
		else:
			push_warning("Música não encontrada: " + caminho)

	# embaralha e distribui uma distinta por player (sobra pelo menos uma de fora)
	disponiveis.shuffle()

	for i in range(total_players):
		if i < disponiveis.size():
			musicas_por_player.append(disponiveis[i])
		else:
			musicas_por_player.append(null)  # fallback se faltar arquivo

	print("MÚSICAS SORTEADAS: ", musicas_por_player.size(), " de ", disponiveis.size(), " disponíveis")



func _tocar_musica_do_player(index: int) -> void:
	if not audio_fundo:
		return
	if index < 0 or index >= musicas_por_player.size():
		return

	var stream: AudioStream = musicas_por_player[index]
	if stream == null:
		return

	audio_fundo.stop()
	audio_fundo.stream = stream
	audio_fundo.volume_db = -7.0
	audio_fundo.play()


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
	var tam: float = 64.0
	var gap: float = 14.0
	var largura_total: float = (tam * float(LEDS_TOTAL)) + (gap * float(LEDS_TOTAL - 1))
	var start_x: float = (tela.x - largura_total) * 0.5
	var y: float = tela.y - tam - 18.0

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


func _atualizar_leds_hud() -> void:
	if leds_hud_layer:
		leds_hud_layer.visible = MOSTRAR_TECLAS_LED_HUD

	if leds_botoes.is_empty():
		return

	for i in range(LEDS_TOTAL):
		var btn := leds_botoes[i]
		var lbl := leds_labels[i]
		var aceso: bool = leds_ativos.has(i)

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


func _sortear_led_disponivel() -> int:
	var disponiveis: Array[int] = []
	for i in range(LEDS_TOTAL):
		if not leds_ativos.has(i):
			disponiveis.append(i)

	if disponiveis.is_empty():
		return -1

	return disponiveis[randi() % disponiveis.size()]



func _completar_leds_ativos() -> void:
	qtd_leds_alvo_atual = clamp(qtd_leds_alvo_atual, LEDS_ATIVOS_MIN, LEDS_ATIVOS_MAX)

	while leds_ativos.size() < qtd_leds_alvo_atual:
		var novo: int = _sortear_led_disponivel()

		if novo < 0:
			break

		if not leds_ativos.has(novo):
			leds_ativos.append(novo)
			cores_leds_ativos[novo] = _rgb_aleatorio_alvo()

	print("================================")
	print("GRUPO COMPLETADO")
	print("SENSORES/FILEIRAS ATIVAS: ", _texto_fileiras_ativas())
	print("CORES RGB DOS ALVOS: ", cores_leds_ativos)
	print("================================")

	_atualizar_leds_hud()
	_enviar_leds_para_arduino()



func _flash_led(index_led: int, sucesso: bool) -> void:
	if index_led < 0 or index_led >= leds_botoes.size():
		return

	var btn := leds_botoes[index_led]
	btn.pivot_offset = btn.size * 0.5
	btn.scale = Vector2(1.30, 1.30)

	var t := create_tween()
	t.tween_property(btn, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if not sucesso:
		btn.modulate = Color(1.5, 0.45, 0.45, 1.0)
		var t2 := create_tween()
		t2.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.35)



func _processar_input_led(index_led: int) -> void:
	if not partida_ativa:
		return

	if index_led < 0 or index_led >= LEDS_TOTAL:
		return

	var letra_sensor := LEDS_LETRAS[index_led]

	print("================================")
	print("SENSOR ATIVADO: ", letra_sensor)
	print("FILEIRAS VÁLIDAS NO MOMENTO: ", _texto_fileiras_ativas())
	print("================================")

	if leds_ativos.has(index_led):
		print("ACERTOU: ", letra_sensor, " / MARCOU 1 GOL")

		_ultimo_acerto_ms = float(Time.get_ticks_msec())   # zera o timeout de 15s

		_flash_led(index_led, true)

		leds_ativos.erase(index_led)
		cores_leds_ativos.erase(index_led)

		registrar_ponto(1)

		_atualizar_leds_hud()
		_enviar_leds_para_arduino()

		await get_tree().create_timer(0.08).timeout

		_completar_leds_ativos()

	else:
		print("ERROU: ", letra_sensor, " NÃO ESTAVA ACESO")

		_flash_led(index_led, false)
		registrar_erro(0)

		_enviar_leds_para_arduino()



func _abrir_serial_arduino() -> void:
	if not USAR_ARDUINO:
		print("Arduino desativado por USAR_ARDUINO = false")
		return

	if USAR_PONTE_POWERSHELL:
		_matar_pontes_powershell_antigas()

		await get_tree().create_timer(0.4).timeout

		_iniciar_ponte_powershell()

		await get_tree().create_timer(3.0).timeout

		_serial_write("OFF")

		await get_tree().create_timer(0.20).timeout

		print("================================")
		print("ARDUINO PRONTO PARA A LÓGICA ÚNICA DO JOGO")
		print("A=D2 | B=D3 | C=D4 | D=D5 | E=D6 | F=D7 | G=D8")
		print("================================")
		return

	push_warning("SerialPort do Godot desativado. Usando somente ponte PowerShell.")



func _matar_pontes_powershell_antigas() -> void:
	var output: Array = []

	var comando := """
Get-CimInstance Win32_Process -Filter "name = 'powershell.exe'" |
Where-Object { $_.CommandLine -like '*arduino_bridge.ps1*' } |
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

	print("PONTES POWERSHELL ANTIGAS FINALIZADAS")



func _iniciar_ponte_powershell() -> void:
	caminho_cmd_arduino = ProjectSettings.globalize_path("user://arduino_cmd.txt")
	caminho_log_arduino = ProjectSettings.globalize_path("user://arduino_log.txt")
	caminho_script_arduino = ProjectSettings.globalize_path("user://arduino_bridge.ps1")
	caminho_fila_arduino = ProjectSettings.globalize_path("user://arduino_queue")

	DirAccess.make_dir_recursive_absolute(caminho_fila_arduino)

	# Limpa fila antiga.
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
		flog.store_string("INICIANDO LOG DA PONTE ARDUINO\n")
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

	print("================================")
	print("PONTE POWERSHELL INICIADA")
	print("PID: ", ponte_ps_pid)
	print("QUEUE: ", caminho_fila_arduino)
	print("LOG FILE: ", caminho_log_arduino)
	print("================================")


func _serial_write(texto: String) -> void:
	if not USAR_ARDUINO:
		return

	var cmd := texto.strip_edges()

	if cmd == "":
		return

	print("================================")
	print("SERIAL/PONTE WRITE -> ", cmd)
	print("FILA: ", caminho_fila_arduino)
	print("================================")

	if USAR_PONTE_POWERSHELL:
		if caminho_fila_arduino == "":
			push_warning("Ponte PowerShell ainda não iniciou. Comando ignorado: " + cmd)
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
			push_warning("Não consegui criar comando temporário Arduino: " + caminho_temp)
			return

		f.store_string(cmd)
		f.close()

		var err := DirAccess.rename_absolute(caminho_temp, caminho_final)

		if err != OK:
			push_warning("Não consegui mover comando para fila Arduino. Erro: " + str(err))
			return

		return

	push_warning("Nenhum modo serial ativo para enviar: " + cmd)



func _processar_linha_arduino(linha: String) -> void:
	linha = linha.strip_edges().to_upper()

	print("ARDUINO:", linha)

	if linha.begins_with("HIT:"):
		var letra := linha.substr(4, 1)

		var index_led := LEDS_LETRAS.find(letra)

		if index_led >= 0:
			_processar_input_led(index_led)

	elif linha == "READY":
		print("ARDUINO PRONTO")

	elif linha.begins_with("OK:"):
		pass

	elif linha.begins_with("ERR:"):
		push_warning("Arduino retornou erro: " + linha)


func _cor_para_rgb255(c: Color) -> Array:
	return [
		int(round(clampf(c.r, 0.0, 1.0) * 255.0)),
		int(round(clampf(c.g, 0.0, 1.0) * 255.0)),
		int(round(clampf(c.b, 0.0, 1.0) * 255.0)),
	]


func _enviar_leds_para_arduino() -> void:
	if not USAR_ARDUINO:
		return

	if leds_ativos.is_empty():
		_serial_write("OFF")
		print("ENVIOU PARA ARDUINO: OFF")
		return

	var partes: Array[String] = []

	for index_led in leds_ativos:
		if index_led < 0 or index_led >= LEDS_LETRAS.size():
			continue

		var letra: String = LEDS_LETRAS[index_led]
		var rgb: Array[int] = _rgb_led_por_index(index_led)

		var r: int = int(clamp(rgb[0], 0, 255))
		var g: int = int(clamp(rgb[1], 0, 255))
		var b: int = int(clamp(rgb[2], 0, 255))

		partes.append("%s=%d,%d,%d" % [
			letra,
			r,
			g,
			b
		])

	if partes.is_empty():
		_serial_write("OFF")
		return

	var comando: String = "SET:" + ";".join(partes)

	_serial_write(comando)

	print("================================")
	print("COMANDO FINAL PARA O NANO:")
	print(comando)
	print("PLAYER ATUAL: ", player_atual + 1)
	print("FILEIRAS ACESAS: ", _texto_fileiras_ativas())
	print("RGB SALVOS: ", cores_leds_ativos)
	print("================================")



func _texto_fileiras_ativas() -> String:
	var partes: Array[String] = []

	for index_led in leds_ativos:
		if index_led >= 0 and index_led < LEDS_LETRAS.size():
			partes.append(LEDS_LETRAS[index_led])

	return ", ".join(partes)



func _teste_arduino_colunas() -> void:
	print("TESTE ARDUINO: acendendo A / D2 azul")
	_serial_write("SET:A=0,0,255")
	await get_tree().create_timer(1.0).timeout

	print("TESTE ARDUINO: acendendo B / D3 verde")
	_serial_write("SET:B=0,255,0")
	await get_tree().create_timer(1.0).timeout

	print("TESTE ARDUINO: acendendo C / D4 vermelho")
	_serial_write("SET:C=255,0,0")
	await get_tree().create_timer(1.0).timeout

	print("TESTE ARDUINO: acendendo G / D8 amarelo")
	_serial_write("SET:G=255,255,0")
	await get_tree().create_timer(1.0).timeout

	print("TESTE ARDUINO: apagando")
	_serial_write("OFF")


func _rgb_led_do_player_atual() -> Array[int]:
	match player_atual:
		0:
			return [0, 0, 255]       # Player 1 azul
		1:
			return [0, 255, 0]       # Player 2 verde
		2:
			return [255, 0, 0]       # Player 3 vermelho
		3:
			return [255, 255, 0]     # Player 4 amarelo

	return [255, 255, 255]


func _mostrar_loading_play() -> void:
	loading_layer = CanvasLayer.new()
	loading_layer.layer = 200
	add_child(loading_layer)

	loading_fundo = ColorRect.new()
	loading_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_fundo.color = Color(0.006, 0.008, 0.012, 1.0)
	loading_layer.add_child(loading_fundo)

	loading_panel = Panel.new()
	loading_panel.size = Vector2(720, 260)
	loading_panel.position = Vector2(
		(get_viewport().get_visible_rect().size.x - loading_panel.size.x) / 2.0,
		(get_viewport().get_visible_rect().size.y - loading_panel.size.y) / 2.0
	)
	loading_panel.scale = Vector2(0.94, 0.94)
	loading_panel.modulate = Color(1, 1, 1, 0)
	loading_layer.add_child(loading_panel)

	var cor := cores_players[0]

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.010, 0.014, 0.020, 0.97)
	style.border_color = cor
	style.set_border_width_all(4)
	style.set_corner_radius_all(36)
	style.shadow_color = Color(cor.r, cor.g, cor.b, 0.78)
	style.shadow_size = 42
	style.shadow_offset = Vector2.ZERO
	loading_panel.add_theme_stylebox_override("panel", style)

	loading_label = Label.new()
	loading_label.text = "MONTANDO PARTIDA"
	loading_label.position = Vector2(0, 48)
	loading_label.size = Vector2(720, 58)
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_label.add_theme_font_size_override("font_size", 40)
	loading_label.add_theme_color_override("font_color", Color.WHITE)
	loading_label.add_theme_color_override("font_shadow_color", cor)
	loading_label.add_theme_constant_override("shadow_offset_x", 0)
	loading_label.add_theme_constant_override("shadow_offset_y", 0)

	if fonte_orbitron:
		loading_label.add_theme_font_override("font", fonte_orbitron)

	loading_panel.add_child(loading_label)

	loading_sub_label = Label.new()
	loading_sub_label.text = "%d PLAYER%s  •  PREPARE-SE" % [
		total_players,
		"" if total_players == 1 else "S"
	]
	loading_sub_label.position = Vector2(0, 130)
	loading_sub_label.size = Vector2(720, 44)
	loading_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_sub_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_sub_label.add_theme_font_size_override("font_size", 24)
	loading_sub_label.add_theme_color_override("font_color", cor)

	if fonte_orbitron:
		loading_sub_label.add_theme_font_override("font", fonte_orbitron)

	loading_panel.add_child(loading_sub_label)

	var dots := Label.new()
	dots.text = "●  ●  ●"
	dots.position = Vector2(0, 185)
	dots.size = Vector2(720, 38)
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dots.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dots.add_theme_font_size_override("font_size", 22)
	dots.add_theme_color_override("font_color", Color(0.75, 0.85, 0.92))

	if fonte_orbitron:
		dots.add_theme_font_override("font", fonte_orbitron)

	loading_panel.add_child(dots)

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(loading_panel, "modulate", Color.WHITE, 0.24)
	t.tween_property(loading_panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _remover_loading_play() -> void:
	if loading_layer == null:
		return

	var t := create_tween()
	t.set_parallel(true)

	if loading_panel:
		t.tween_property(loading_panel, "modulate", Color(1, 1, 1, 0), 0.22)
		t.tween_property(loading_panel, "scale", Vector2(0.94, 0.94), 0.22)

	if loading_fundo:
		t.tween_property(loading_fundo, "color", Color(0.006, 0.008, 0.012, 0.0), 0.22)

	await t.finished

	if loading_layer:
		loading_layer.queue_free()

	loading_layer = null
	loading_fundo = null
	loading_panel = null
	loading_label = null
	loading_sub_label = null

func _rgb_aleatorio_alvo() -> Array[int]:
	if CORES_ALVOS_RGB.is_empty():
		return [255, 255, 255]

	var index: int = int(randi() % CORES_ALVOS_RGB.size())
	var rgb: Array = CORES_ALVOS_RGB[index]

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

	var novo_rgb: Array[int] = _rgb_aleatorio_alvo()
	cores_leds_ativos[index_led] = novo_rgb
	return novo_rgb


func _cor_led_ativo(index_led: int) -> Color:
	var rgb: Array[int] = _rgb_led_por_index(index_led)

	return Color(
		float(rgb[0]) / 255.0,
		float(rgb[1]) / 255.0,
		float(rgb[2]) / 255.0,
		1.0
	)


func _novo_label_card(texto: String, largura: float, centro_y: float, fonte_size: int, cor: Color) -> Label:
	var lbl := Label.new()
	lbl.text = texto
	var altura := float(fonte_size) + 12.0
	lbl.position = Vector2(0, centro_y - altura * 0.5)
	lbl.size = Vector2(largura, altura)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", fonte_size)
	lbl.add_theme_color_override("font_color", cor)
	lbl.add_theme_constant_override("shadow_offset_x", 0)
	lbl.add_theme_constant_override("shadow_offset_y", 0)

	if fonte_orbitron:
		lbl.add_theme_font_override("font", fonte_orbitron)

	return lbl

func _parar_musica_partida() -> void:
	if audio_fundo and audio_fundo.playing:
		audio_fundo.stop()


func _parar_campeao() -> void:
	if sfx_campeao and sfx_campeao.playing:
		sfx_campeao.stop()

	if sfx_campeao and sfx_campeao.stream and sfx_campeao.stream is AudioStreamMP3:
		sfx_campeao.stream.loop = false


func _tocar_campeao_loop_modal() -> void:
	# Modal final: corta música da partida e todos os efeitos.
	_parar_musica_partida()
	_parar_tudo_exceto_musica()

	if sfx_campeao == null:
		return
	if sfx_campeao.stream == null:
		return

	if sfx_campeao.stream is AudioStreamMP3:
		sfx_campeao.stream.loop = true

	sfx_campeao.stop()
	sfx_campeao.play()
