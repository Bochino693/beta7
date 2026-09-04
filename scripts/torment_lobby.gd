extends Node2D

# ============================================================
# TORMENT LOBBY — 36 PLAYERS
# Chaveamento afunilado:
# - A/F lado esquerdo
# - G/L lado direito
# - Fase inicial: Primeira Fase (IDA/VOLTA), Segunda Fase, Oitavas
# - Playoffs: Quartas, Semifinal, Final, Pódio
#
# NOVA REGRA DA PRIMEIRA FASE:
# - Cada grupo de 3 jogadores (3X3) joga IDA e VOLTA.
# - O ranking do grupo soma os gols das duas pernas.
# - Os 2 melhores de cada grupo se classificam (24 no total).
# - Dos 24, os 4 melhores de CADA LADO (A-F / G-L) = 8 no total
#   pegam BYE direto para as OITAVAS.
# - Os outros 16 (8 por lado) jogam a SEGUNDA FASE (mata-mata
#   ida/volta, dentro do próprio lado) e os 8 vencedores
#   completam as Oitavas junto com os 8 do bye.
# ============================================================

var _torneio_salvo_mural: bool = false

const CENA_PLAY: String = "res://scenes/torment_play.tscn"
const CENA_OPENING: String = "res://scenes/opening.tscn"
const FONTE_ORBITRON: String = "res://fonts/orbitron-bold.ttf"

const SFX_START_TORMENT: String = "res://songs/start_game.mp3"
const SFX_START_TORMENT_FALLBACK: String = "res://songs/game_start.mp3"
const VOLUME_SFX_START_TORMENT_DB: float = 2.0
const DELAY_TROCA_CENA_START: float = 0.65

const COR_CARD_ATIVO_MODERNO: Color = Color(0.00, 0.86, 1.00)
const COR_CARD_FUNDO_ATIVO: Color = Color(0.006, 0.030, 0.070, 0.98)
const COR_CARD_FUNDO_MATA: Color = Color(0.010, 0.014, 0.034, 0.96)
const COR_CARD_FUNDO_FINALIZADO: Color = Color(0.008, 0.016, 0.034, 0.97)
const COR_CARD_FUNDO_FINAL: Color = Color(0.014, 0.012, 0.044, 0.98)


const FASE_3LUGAR: String = "DISPUTA 3 LUGAR"

const META_ESTADO: String = "torment_lobby_estado"
const META_PARTIDA: String = "partida_torneio_atual"
const META_PARTIDA_INDEX: String = "torneio_partida_atual_index"
const META_PARTIDA_FASE: String = "torneio_partida_atual_fase"
const META_PARTIDA_ETAPA: String = "torneio_partida_atual_etapa"
const META_RESULTADO: String = "resultado_torneio_pendente"

const FASE_GRUPOS: String = "PRIMEIRA FASE"
const FASE_PLAYIN: String = "SEGUNDA FASE"
const FASE_OITAVAS: String = "OITAVAS"
const FASE_QUARTAS: String = "QUARTAS"
const FASE_SEMIS: String = "SEMIFINAL"
const FASE_FINAL: String = "FINAL"
const FASE_PODIO: String = "PODIO"

const META_PARTIDA_ID: String = "torneio_partida_atual_id"

const IMAGEM_LOADING_TORMENT: String = "res://images/loading.png"
const SFX_LOADING_RESULTADO: String = "res://songs/game_start.mp3"

const USAR_LEDS_LOADING_LOBBY: bool = true
const ARDUINO_QUEUE_TORMENT: String = "user://arduino_queue_torment"


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

const FASES_ORDEM: Array[String] = [
	FASE_GRUPOS,
	FASE_PLAYIN,
	FASE_OITAVAS,
	FASE_QUARTAS,
	FASE_SEMIS,
	FASE_3LUGAR,
	FASE_FINAL,
	FASE_PODIO
]


const MUSICA_LOBBY_TORMENT: String = "res://songs/intro_game.mp3"
const VOLUME_MUSICA_LOBBY_DB: float = -6.0


const SFX_PODIO_GOOD_PLAYER: String = "res://songs/good_player.mp3"
const VOLUME_PODIO_GOOD_PLAYER_DB: float = -4.0

const START_HOLD_RETORNAR_PODIO: float = 1.65

const CONFETE_INTERVALO_PODIO: float = 0.035
const CONFETES_INICIAIS_PODIO: int = 95

const FILTRO_INICIAL: String = "FASE INICIAL"
const FILTRO_PLAYOFFS: String = "PLAYOFFS"


const NOMES_GRUPOS: Array[String] = [
	"A", "B", "C", "D", "E", "F",
	"G", "H", "I", "J", "K", "L"
]

const CORES_PADRAO: Array[Color] = [
	Color(1.00, 0.12, 0.10),
	Color(0.10, 0.85, 0.28),
	Color(0.10, 0.48, 1.00),
	Color(1.00, 0.86, 0.08),
	Color(0.78, 0.20, 1.00),
	Color(0.08, 0.90, 0.95)
]

const COR_NEON: Color = Color(0.10, 0.75, 1.00)
const COR_FUNDO: Color = Color(0.006, 0.011, 0.022, 1.0)
const IMAGEM_BACK_TORMENT: String = "res://fundos/back_torment.png"

const COR_TORMENT: Color = Color(0.95, 0.00, 1.00) # roxo/magenta do torneio
const COR_TORMENT_DARK: Color = Color(0.20, 0.02, 0.34)
const COR_TORMENT_2: Color = Color(0.58, 0.10, 1.00)

const COR_OK: Color = Color(0.22, 0.95, 0.58)
const COR_ALERTA: Color = Color(1.00, 0.78, 0.18)
const COR_ERRO: Color = Color(1.00, 0.22, 0.22)
const COR_PRATA: Color = Color(0.80, 0.84, 0.92)
const COR_BRONZE: Color = Color(0.86, 0.55, 0.28)
const COR_TEXTO_SUAVE: Color = Color(0.72, 0.82, 0.96)
const COR_BOOT: Color = Color(0.48, 0.52, 0.62)


const AUTO_RESOLVER_BOTS: bool = true

# Quantos de cada lado (A-F / G-L) recebem BYE direto para as Oitavas.
const BYE_POR_LADO: int = 4

# --- Instruções do torneio (segurar input_cup) ---
const CUP_HOLD_ABRIR: float = 0.55
var _cup_hold_tempo: float = 0.0
var _instrucoes_abertas: bool = false
var _instrucoes_overlay: Control = null

var canvas: CanvasLayer
var root: Control
var fonte_principal: Font

var musica_lobby_torment: AudioStreamPlayer = null

var bye_oitavas: Dictionary = {
	"esquerdo": [],
	"direito": []
}

var audio_podio_good_player: AudioStreamPlayer = null

var _start_hold_retorno_podio_tempo: float = 0.0

var _podio_confete_root: Control = null
var _podio_confete_ativo: bool = false
var _podio_confete_timer: float = 0.0

var filtro_tela: String = FILTRO_INICIAL
var fase_atual: String = FASE_GRUPOS

var jogadores: Array = []
var grupos: Array = []
var partidas: Dictionary = {}
var stats: Dictionary = {}

var _podio_hold_tempo: float = 0.0
var _podio_barra_fill: ColorRect = null
var _podio_barra_max_w: float = 0.0
var _podio_voltando: bool = false
const PODIO_HOLD_RETORNO: float = 1.5

var ranking_grupos: Array = []
var semi_perdedores: Array = []
var top3_final: Array = []

var aviso_pendente: Dictionary = {}
var viewport_cache: Vector2 = Vector2.ZERO

# --- LEDs idle do lobby (cores dos próximos players) ---
var _leds_idle_ativo: bool = false
var _leds_idle_tempo: float = 0.0
var _leds_idle_index: int = 0
var assinatura_setup_atual: String = ""
const LEDS_IDLE_INTERVALO: float = 0.14
const LEDS_LETRAS_LOBBY: Array[String] = ["A", "B", "C", "D", "E", "F", "G"]


var audio_start_torment: AudioStreamPlayer = null
var _abrindo_partida_com_sfx: bool = false
var _retornando_inicio_podio: bool = false

var _podio_hold_fill: ColorRect = null
var _podio_hold_label: Label = null
var _podio_hold_fill_max_w: float = 0.0

var _processando_resultado_retorno: bool = false
var loading_result_layer: CanvasLayer = null
var loading_result_root: Control = null
var sfx_loading_resultado: AudioStreamPlayer = null
var caminho_fila_arduino_lobby: String = ""


func _ready() -> void:
	randomize()

	_travar_torment_fullscreen()
	get_tree().auto_accept_quit = false

	caminho_fila_arduino_lobby = ProjectSettings.globalize_path(ARDUINO_QUEUE_TORMENT)

	if ResourceLoader.exists(FONTE_ORBITRON):
		var fonte_res: Resource = load(FONTE_ORBITRON)
		if fonte_res is Font:
			fonte_principal = fonte_res

	_criar_audio_loading_lobby()
	_criar_musica_lobby_torment()
	_criar_audio_start_torment()
	_criar_audio_podio_good_player()
	_tocar_musica_lobby_torment()
	
	# Recuperação anti-queda: se não há estado em memória, tenta o disco.
	if not get_tree().has_meta(META_ESTADO):
		var es := get_node_or_null("/root/EstadoComp")
		if es and es.tem("torneio36"):
			get_tree().set_meta(META_ESTADO, es.carregar("torneio36"))

	# NÃO apaga mais META_ESTADO nem META_RESULTADO aqui.
	# Isso fazia o torneio reiniciar do zero toda vez que um player
	# real voltava de uma partida (placar zerado + loop infinito).
	# Agora o reset só ocorre quando o SETUP muda (assinatura diferente).
	_carregar_ou_criar_estado()

	var tem_resultado_pendente: bool = get_tree().has_meta(META_RESULTADO)

	_criar_interface()
	_salvar_estado()
	_renderizar()

	if tem_resultado_pendente:
		call_deferred("_consumir_resultado_pendente_com_loading")
	else:
		_resolver_automaticos_ate_proxima_real()
		_salvar_estado()
		_renderizar()
		_iniciar_leds_idle_lobby()



func _process(delta: float) -> void:
	if not _instrucoes_abertas:
		if get_tree().has_meta(META_RESULTADO) and not _processando_resultado_retorno:
			call_deferred("_consumir_resultado_pendente_com_loading")
			_atualizar_hold_podio(delta)

		var s: Vector2 = get_viewport_rect().size
		if s != viewport_cache:
			viewport_cache = s
			_renderizar()

		_atualizar_leds_idle_lobby(delta)

		if fase_atual == FASE_PODIO:
			_atualizar_hold_start_retorno_podio(delta)
			_atualizar_confetes_podio(delta)
		else:
			_start_hold_retorno_podio_tempo = 0.0

	_atualizar_hold_cup(delta)



func _unhandled_input(event: InputEvent) -> void:
	var vp := get_viewport()

	if _instrucoes_abertas:
		var fechar: bool = false

		if _acao_existe("input_start") and event.is_action_pressed("input_start"):
			fechar = true
		elif _acao_existe("input_cup") and event.is_action_pressed("input_cup"):
			fechar = true
		elif event is InputEventKey and event.pressed:
			if event.keycode == KEY_ESCAPE:
				fechar = true

		if fechar:
			if vp:
				vp.set_input_as_handled()
			_fechar_instrucoes_torneio()

		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB and event.ctrl_pressed:
		_fechar_ponte_leds_lobby()
		get_tree().quit()
		return

	var iniciar: bool = false

	if _acao_existe("input_start") and event.is_action_pressed("input_start"):
		if fase_atual == FASE_PODIO:
			if vp:
				vp.set_input_as_handled()
			return
		else:
			iniciar = true

	if iniciar:
		if vp:
			vp.set_input_as_handled()
		_jogar_proxima_partida()
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if vp:
			vp.set_input_as_handled()

		# No pódio, ESC não volta mais.
		# O retorno agora é SOMENTE segurando START.
		if fase_atual == FASE_PODIO:
			return

		if ResourceLoader.exists(CENA_OPENING):
			_parar_leds_idle_lobby()
			_parar_good_player_podio()
			get_tree().change_scene_to_file(CENA_OPENING)



# ============================================================
# ESTADO
# ============================================================
func _carregar_ou_criar_estado() -> void:
	var tem_resultado: bool = get_tree().has_meta(META_RESULTADO)
	var assinatura_atual: String = _assinatura_setup_atual()

	if not get_tree().has_meta(META_ESTADO):
		assinatura_setup_atual = assinatura_atual
		_criar_novo_torneio()
		return

	var e: Dictionary = _as_dict(get_tree().get_meta(META_ESTADO))

	fase_atual = str(e.get("fase_atual", FASE_GRUPOS))
	filtro_tela = str(e.get("filtro_tela", FILTRO_INICIAL))

	jogadores = _as_array(e.get("jogadores", []))
	grupos = _as_array(e.get("grupos", []))
	partidas = _as_dict(e.get("partidas", {}))
	stats = _as_dict(e.get("stats", {}))
	ranking_grupos = _as_array(e.get("ranking_grupos", []))
	semi_perdedores = _as_array(e.get("semi_perdedores", []))
	top3_final = _as_array(e.get("top3_final", []))
	bye_oitavas = _as_dict(e.get("bye_oitavas", {}))

	var assinatura_salva: String = str(e.get("assinatura_setup", ""))
	assinatura_setup_atual = assinatura_salva

	# Só reseta se NÃO estiver voltando de uma partida (sem resultado
	# pendente) E o setup atual for de um torneio diferente.
	if not tem_resultado:
		if not assinatura_atual.is_empty() and not assinatura_salva.is_empty() and assinatura_atual != assinatura_salva:
			assinatura_setup_atual = assinatura_atual
			_criar_novo_torneio()
			return

	if bye_oitavas.is_empty() and get_tree().has_meta("torment_bye_oitavas"):
		bye_oitavas = _as_dict(get_tree().get_meta("torment_bye_oitavas"))

	_normalizar_bye_oitavas_dict()
	get_tree().set_meta("torment_bye_oitavas", bye_oitavas)

	if not FASES_ORDEM.has(fase_atual):
		assinatura_setup_atual = assinatura_atual
		_criar_novo_torneio()
		return

	if fase_atual != FASE_PODIO and not partidas.has(fase_atual):
		assinatura_setup_atual = assinatura_atual
		_criar_novo_torneio()
		return

	if _indice_fase(fase_atual) >= _indice_fase(FASE_PLAYIN):
		_garantir_bye_oitavas()



func _salvar_estado() -> void:
	var estado: Dictionary = {
		"fase_atual": fase_atual,
		"filtro_tela": filtro_tela,
		"jogadores": jogadores,
		"grupos": grupos,
		"partidas": partidas,
		"stats": stats,
		"ranking_grupos": ranking_grupos,
		"semi_perdedores": semi_perdedores,
		"top3_final": top3_final,
		"bye_oitavas": bye_oitavas,
		"assinatura_setup": assinatura_setup_atual
	}

	get_tree().set_meta(META_ESTADO, estado)
	get_tree().set_meta("torment_bye_oitavas", bye_oitavas)

	_persistir_estado_disco(estado)


func _persistir_estado_disco(estado: Dictionary) -> void:
	# Torneio terminado não precisa retomar.
	if fase_atual == FASE_PODIO:
		return
	var es := get_node_or_null("/root/EstadoComp")
	if es:
		es.salvar("torneio36", estado)



func _criar_novo_torneio() -> void:
	jogadores.clear()
	grupos.clear()
	partidas.clear()
	stats.clear()
	ranking_grupos.clear()
	semi_perdedores.clear()
	top3_final.clear()

	bye_oitavas = {
		"esquerdo": [],
		"direito": []
	}
	_limpar_metas_partida_torment()

	assinatura_setup_atual = _assinatura_setup_atual()

	var grupos_setup: Array = _ler_grupos_do_setup()

	if not grupos_setup.is_empty():
		_montar_grupos_do_setup(grupos_setup)
	else:
		_montar_grupos_fallback()

	partidas[FASE_GRUPOS] = _criar_partidas_grupos()
	fase_atual = FASE_GRUPOS
	filtro_tela = FILTRO_INICIAL
	_salvar_estado()


func _ler_grupos_do_setup() -> Array:
	for chave in ["torneio_grupos_fase1", "copa_grupos", "copa_chaves_36", "copa_chaves_fase1"]:
		if get_tree().has_meta(chave):
			var g: Array = _as_array(get_tree().get_meta(chave))
			if not g.is_empty():
				return g
	return []


func _assinatura_setup_atual() -> String:
	var grupos_setup: Array = _ler_grupos_do_setup()
	if grupos_setup.is_empty():
		return ""

	var partes: Array[String] = []

	for item_grupo in grupos_setup:
		var lista_raw: Array = []

		if item_grupo is Dictionary:
			var gd: Dictionary = _as_dict(item_grupo)
			lista_raw = _as_array(gd.get("jogadores", gd.get("players", gd.get("lista", []))))
		elif item_grupo is Array:
			lista_raw = _as_array(item_grupo)

		for j in lista_raw:
			if j is Dictionary:
				var jd: Dictionary = _as_dict(j)
				partes.append(str(jd.get("nome", jd.get("name", ""))))
			else:
				partes.append(str(j))

	return "|".join(partes)



func _montar_grupos_do_setup(grupos_setup: Array) -> void:
	jogadores.clear()
	grupos.clear()

	var seed_counter: int = 1

	for gi in range(12):
		var grupo: Array = []

		if gi < grupos_setup.size():
			var item_grupo: Variant = grupos_setup[gi]
			var lista_raw: Array = []

			if item_grupo is Dictionary:
				var gdata: Dictionary = _as_dict(item_grupo)
				lista_raw = _as_array(gdata.get("jogadores", gdata.get("players", gdata.get("lista", []))))
			elif item_grupo is Array:
				lista_raw = _as_array(item_grupo)

			for item in lista_raw:
				if grupo.size() >= 3:
					break

				var j: Dictionary = _normalizar_jogador(item, seed_counter - 1)
				j["seed"] = seed_counter
				j["id"] = seed_counter
				seed_counter += 1

				grupo.append(j)
				jogadores.append(j)

		while grupo.size() < 3:
			var boot: Dictionary = {
				"nome": "Boot %02d" % seed_counter,
				"bot": true,
				"boot": true,
				"seed": seed_counter,
				"id": seed_counter
			}

			var jb: Dictionary = _normalizar_jogador(boot, seed_counter - 1)
			seed_counter += 1

			grupo.append(jb)
			jogadores.append(jb)

		grupos.append(grupo)



func _montar_grupos_fallback() -> void:
	var origem: Array = []
	if get_tree().has_meta("torneio_36_jogadores"):
		origem = _as_array(get_tree().get_meta("torneio_36_jogadores"))
	elif get_tree().has_meta("torment_jogadores"):
		origem = _as_array(get_tree().get_meta("torment_jogadores"))
	if origem.is_empty():
		origem = _gerar_jogadores_teste()

	for i in range(origem.size()):
		jogadores.append(_normalizar_jogador(origem[i], i))
	while jogadores.size() < 36:
		var boot: Dictionary = {"nome": "Boot %02d" % [jogadores.size() + 1], "bot": true}
		jogadores.append(_normalizar_jogador(boot, jogadores.size()))

	for g in range(12):
		grupos.append([])
	for i in range(jogadores.size()):
		var gi: int = i % 12
		var grupo: Array = _as_array(grupos[gi])
		grupo.append(_as_dict(jogadores[i]))
		grupos[gi] = grupo



func _gerar_jogadores_teste() -> Array:
	var arr: Array = []

	for i in range(36):
		arr.append({
			"nome": "Jogador %02d" % [i + 1],
			"bot": i >= 24
		})

	return arr


func _normalizar_jogador(valor: Variant, idx: int) -> Dictionary:
	var j: Dictionary = {}
	if valor is Dictionary:
		j = _as_dict(valor).duplicate(true)
	else:
		j = {"nome": str(valor)}

	var nome: String = str(j.get("nome", j.get("name", "Jogador %02d" % [idx + 1]))).strip_edges()
	if nome.is_empty():
		nome = "Jogador %02d" % [idx + 1]

	var bot: bool = bool(j.get("bot", j.get("eh_bot", j.get("boot", false))))
	var nome_lower: String = nome.to_lower()
	if nome_lower.begins_with("bot") or nome_lower.begins_with("boot"):
		bot = true

	var cor: Color = CORES_PADRAO[idx % CORES_PADRAO.size()]
	var cor_v: Variant = j.get("cor", j.get("color", null))
	if cor_v is Color:
		cor = cor_v

	return {
		"id": int(j.get("id", idx + 1)),
		"seed": int(j.get("seed", idx + 1)),
		"nome": nome,
		"bot": bot,
		"boot": bot,
		"cor": cor,
		"cor_nome": str(j.get("cor_nome", "")),
		"cor_index": int(j.get("cor_index", -1))
	}



func _criar_grupos() -> void:
	grupos.clear()

	for g in range(12):
		grupos.append([])

	for i in range(jogadores.size()):
		var grupo_index: int = i % 12
		var grupo: Array = _as_array(grupos[grupo_index])
		grupo.append(_as_dict(jogadores[i]))
		grupos[grupo_index] = grupo



func _criar_partidas_grupos() -> Array:
	var arr: Array = []
	for gi in range(grupos.size()):
		var grupo: Array = _as_array(grupos[gi])
		arr.append(_nova_partida_grupo_ida_volta(gi, grupo))
	return arr



func _nova_partida_grupo_ida_volta(grupo_index: int, jogadores_grupo: Array) -> Dictionary:
	return {
		"id": "G_%02d_%d" % [grupo_index, Time.get_ticks_msec() % 100000],
		"tipo": "grupo",
		"fase": FASE_GRUPOS,
		"grupo_index": grupo_index,
		"grupo_nome": NOMES_GRUPOS[grupo_index],
		"jogadores": jogadores_grupo.duplicate(true),

		# Ida e volta do grupo (3x3 cada perna).
		"ida": {
			"ranking": [],
			"finalizada": false
		},
		"volta": {
			"ranking": [],
			"finalizada": false
		},

		"ranking": [],
		"finalizada": false,
		"vencedor": {}
	}



func _nova_partida_mata(fase: String, a: Dictionary, b: Dictionary, numero: int) -> Dictionary:
	return {
		"id": "%s_%02d_%d" % [fase, numero, Time.get_ticks_msec() % 100000],
		"tipo": "mata",
		"fase": fase,
		"numero": numero,
		"a": a,
		"b": b,
		"ida": {
			"a": -1,
			"b": -1,
			"finalizada": false
		},
		"volta": {
			"a": -1,
			"b": -1,
			"finalizada": false
		},
		"penaltis": {
			"a": 0,
			"b": 0,
			"finalizada": false
		},
		"agregado_a": 0,
		"agregado_b": 0,
		"aguardando_penaltis": false,
		"finalizada": false,
		"vencedor_lado": "",
		"vencedor": {},
		"perdedor": {},
		"motivo": "",
		"lado_chave": "",
		"origem_chave": "",
		"cruzamento": ""
	}


# ============================================================
# RESULTADO DO PLAY
# ============================================================

func _consumir_resultado_pendente() -> void:
	if _processando_resultado_retorno:
		return

	call_deferred("_consumir_resultado_pendente_com_loading")

func _consumir_resultado_pendente_com_loading() -> void:
	if _processando_resultado_retorno:
		return

	if not get_tree().has_meta(META_RESULTADO):
		return

	_processando_resultado_retorno = true
	_leds_idle_ativo = false

	var r: Dictionary = _as_dict(get_tree().get_meta(META_RESULTADO))
	get_tree().remove_meta(META_RESULTADO)

	await _mostrar_loading_resultados_torment(
		"CARREGANDO RESULTADOS",
		"PROCESSANDO PARTIDA  •  ATUALIZANDO CHAVEAMENTO  •  LIGANDO LEDS"
	)

	_registrar_resultado(r)
	_limpar_metas_partida_atual_sem_resultado()

	_avancar_fase_se_preciso()
	_resolver_automaticos_ate_proxima_real()

	_salvar_estado()
	_renderizar()

	await _remover_loading_resultados_torment()

	_processando_resultado_retorno = false

	# Volta a rodar as cores dos próximos players no lobby.
	_iniciar_leds_idle_lobby()



func _registrar_resultado(r: Dictionary) -> void:
	var fase_raw: String = str(r.get("fase", get_tree().get_meta(META_PARTIDA_FASE, fase_atual)))
	var fase: String = _normalizar_fase_lobby(fase_raw)

	var index: int = int(r.get("partida_index", get_tree().get_meta(META_PARTIDA_INDEX, -1)))
	var etapa: String = str(r.get("etapa", get_tree().get_meta(META_PARTIDA_ETAPA, "ida")))
	var partida_id_recebido: String = str(r.get("partida_id", ""))

	if etapa != "ida" and etapa != "volta" and etapa != "penaltis":
		etapa = "ida"

	if not partidas.has(fase):
		push_warning("TORMENT: resultado recebido para fase inexistente: " + fase_raw + " / normalizada: " + fase)
		return

	var arr: Array = _as_array(partidas[fase])

	var achou_por_id: bool = false

	if not partida_id_recebido.is_empty():
		for i in range(arr.size()):
			var cand: Dictionary = _as_dict(arr[i])
			if str(cand.get("id", "")) == partida_id_recebido:
				index = i
				achou_por_id = true
				break

	if index < 0 or index >= arr.size():
		push_warning("TORMENT: resultado com index inválido. Fase=%s Index=%d ID=%s" % [
			fase,
			index,
			partida_id_recebido
		])
		return

	var p: Dictionary = _as_dict(arr[index])
	var partida_id_real: String = str(p.get("id", ""))

	# Agora não rejeita mais resultado por ID diferente.
	# Se o index está correto, salva por index.
	if not partida_id_recebido.is_empty() and partida_id_real != partida_id_recebido and not achou_por_id:
		push_warning("TORMENT: ID diferente, mas aceitando por index. Esperado=%s Recebido=%s Index=%d" % [
			partida_id_real,
			partida_id_recebido,
			index
		])

	if str(p.get("tipo", "")) == "grupo":
		var ranking_recebido: Array = _as_array(r.get("ranking", []))
		_aplicar_resultado_grupo_ida_volta(p, etapa, ranking_recebido)
	else:
		var gols_a: int = _pegar_int(r, ["gols_a", "score_a", "pontos_a", "a"], 0)
		var gols_b: int = _pegar_int(r, ["gols_b", "score_b", "pontos_b", "b"], 0)
		var pen_a: int = _pegar_int(r, ["pen_a", "penaltis_a", "penalti_a"], 0)
		var pen_b: int = _pegar_int(r, ["pen_b", "penaltis_b", "penalti_b"], 0)

		_aplicar_resultado_mata(p, etapa, gols_a, gols_b, pen_a, pen_b)

	arr[index] = p
	partidas[fase] = arr

	print("TORMENT RESULTADO SALVO => FASE:", fase, " INDEX:", index, " ETAPA:", etapa, " DADOS:", r)


func _normalizar_fase_lobby(fase: String) -> String:
	match fase:
		"FASE_1":
			return FASE_GRUPOS
		"PRIMEIRA":
			return FASE_GRUPOS
		"PRIMEIRA FASE":
			return FASE_GRUPOS
		"PLAYIN_24_PARA_16":
			return FASE_PLAYIN
		"SEGUNDA_FASE":
			return FASE_PLAYIN
		"SEGUNDA FASE":
			return FASE_PLAYIN
		"OITAVAS":
			return FASE_OITAVAS
		"QUARTAS":
			return FASE_QUARTAS
		"SEMIFINAL":
			return FASE_SEMIS
		"SEMI":
			return FASE_SEMIS
		"FINAL":
			return FASE_FINAL
		"PODIO":
			return FASE_PODIO

	return fase



func _pegar_int(d: Dictionary, keys: Array, padrao: int = 0) -> int:
	for key_var in keys:
		var k: String = str(key_var)
		if d.has(k):
			return int(d[k])
	return padrao


func _aplicar_resultado_mata(p: Dictionary, etapa: String, gols_a: int, gols_b: int, pen_a: int, pen_b: int) -> void:
	if etapa == "penaltis":
		var pen: Dictionary = _as_dict(p.get("penaltis", {}))
		if bool(pen.get("finalizada", false)):
			return

		pen["a"] = pen_a if pen_a > 0 or pen_b > 0 else gols_a
		pen["b"] = pen_b if pen_a > 0 or pen_b > 0 else gols_b
		pen["finalizada"] = true
		p["penaltis"] = pen

		_avaliar_partida_mata(p)
		return

	var chave: String = "ida"
	if etapa == "volta":
		chave = "volta"

	var leg: Dictionary = _as_dict(p.get(chave, {}))
	if bool(leg.get("finalizada", false)):
		return

	leg["a"] = gols_a
	leg["b"] = gols_b
	leg["finalizada"] = true
	p[chave] = leg

	_registrar_stats_jogo(
		_as_dict(p.get("a", {})),
		_as_dict(p.get("b", {})),
		gols_a,
		gols_b,
		{},
		false
	)

	print("TORMENT MATA SALVO:", str(p.get("fase", "")), " Nº", int(p.get("numero", 0)), " ", etapa, " ", gols_a, "x", gols_b)

	_avaliar_partida_mata(p)


func _avaliar_partida_mata(p: Dictionary) -> void:
	if bool(p.get("finalizada", false)):
		return

	var ida: Dictionary = _as_dict(p.get("ida", {}))
	var volta: Dictionary = _as_dict(p.get("volta", {}))

	# CORREÇÃO DO BUG: nunca decide o confronto sem a IDA *e* a VOLTA
	# estarem finalizadas. Antes disso, não há vencedor possível.
	if not bool(ida.get("finalizada", false)):
		return

	if not bool(volta.get("finalizada", false)):
		return

	var agregado_a: int = int(ida.get("a", 0)) + int(volta.get("a", 0))
	var agregado_b: int = int(ida.get("b", 0)) + int(volta.get("b", 0))

	p["agregado_a"] = agregado_a
	p["agregado_b"] = agregado_b

	if agregado_a > agregado_b:
		_finalizar_mata(p, "a", "agregado")
		return

	if agregado_b > agregado_a:
		_finalizar_mata(p, "b", "agregado")
		return

	var a: Dictionary = _as_dict(p.get("a", {}))
	var b: Dictionary = _as_dict(p.get("b", {}))

	var a_bot: bool = _eh_bot(a)
	var b_bot: bool = _eh_bot(b)

	if a_bot or b_bot:
		if a_bot and not b_bot:
			_finalizar_mata(p, "b", "empate_agregado_real_vence_bot")
			return

		if b_bot and not a_bot:
			_finalizar_mata(p, "a", "empate_agregado_real_vence_bot")
			return

		if _seed(a) <= _seed(b):
			_finalizar_mata(p, "a", "empate_bots_seed")
		else:
			_finalizar_mata(p, "b", "empate_bots_seed")
		return

	var pen: Dictionary = _as_dict(p.get("penaltis", {}))

	if not bool(pen.get("finalizada", false)):
		p["aguardando_penaltis"] = true
		p["motivo"] = "aguardando_penaltis"
		return

	var pen_a: int = int(pen.get("a", 0))
	var pen_b: int = int(pen.get("b", 0))

	if pen_a > pen_b:
		_finalizar_mata(p, "a", "penaltis")
	elif pen_b > pen_a:
		_finalizar_mata(p, "b", "penaltis")
	else:
		p["aguardando_penaltis"] = true
		p["motivo"] = "penaltis_empatados"


func _finalizar_mata(p: Dictionary, lado: String, motivo: String) -> void:
	p["finalizada"] = true
	p["aguardando_penaltis"] = false
	p["vencedor_lado"] = lado
	p["motivo"] = motivo

	if lado == "a":
		p["vencedor"] = _as_dict(p.get("a", {}))
		p["perdedor"] = _as_dict(p.get("b", {}))
	else:
		p["vencedor"] = _as_dict(p.get("b", {}))
		p["perdedor"] = _as_dict(p.get("a", {}))

	_adicionar_vitoria(_as_dict(p.get("vencedor", {})))

	var pen: Dictionary = _as_dict(p.get("penaltis", {}))
	if bool(pen.get("finalizada", false)):
		_adicionar_penaltis(_as_dict(p.get("a", {})), int(pen.get("a", 0)))
		_adicionar_penaltis(_as_dict(p.get("b", {})), int(pen.get("b", 0)))

	if str(p.get("fase", "")) == FASE_SEMIS:
		aviso_pendente = {
			"vencedor": _as_dict(p.get("vencedor", {})),
			"perdedor": _as_dict(p.get("perdedor", {})),
			"fase": FASE_SEMIS
		}


# ============================================================
# STATS
# ============================================================

func _id_key(j: Dictionary) -> String:
	return str(j.get("id", j.get("seed", j.get("nome", "0"))))


func _garantir_stats(j: Dictionary) -> Dictionary:
	var k: String = _id_key(j)

	if not stats.has(k):
		stats[k] = {
			"jogos": 0,
			"gols": 0,
			"vitorias": 0,
			"penaltis": 0,
			"pontos_grupo": 0,
			"gols_contra": 0
		}

	return _as_dict(stats[k])


func _registrar_stats_jogo(a: Dictionary, b: Dictionary, gols_a: int, gols_b: int, vencedor: Dictionary, conta_vitoria: bool) -> void:
	var sa: Dictionary = _garantir_stats(a)
	var sb: Dictionary = _garantir_stats(b)

	sa["jogos"] = int(sa.get("jogos", 0)) + 1
	sb["jogos"] = int(sb.get("jogos", 0)) + 1

	sa["gols"] = int(sa.get("gols", 0)) + gols_a
	sb["gols"] = int(sb.get("gols", 0)) + gols_b

	sa["gols_contra"] = int(sa.get("gols_contra", 0)) + gols_b
	sb["gols_contra"] = int(sb.get("gols_contra", 0)) + gols_a

	if conta_vitoria and not vencedor.is_empty():
		var vencedor_key: String = _id_key(vencedor)

		if vencedor_key == _id_key(a):
			sa["vitorias"] = int(sa.get("vitorias", 0)) + 1
			sa["pontos_grupo"] = int(sa.get("pontos_grupo", 0)) + 3
		else:
			sb["vitorias"] = int(sb.get("vitorias", 0)) + 1
			sb["pontos_grupo"] = int(sb.get("pontos_grupo", 0)) + 3

	stats[_id_key(a)] = sa
	stats[_id_key(b)] = sb


func _adicionar_vitoria(j: Dictionary) -> void:
	var s: Dictionary = _garantir_stats(j)
	s["vitorias"] = int(s.get("vitorias", 0)) + 1
	stats[_id_key(j)] = s


func _adicionar_penaltis(j: Dictionary, qtd: int) -> void:
	var s: Dictionary = _garantir_stats(j)
	s["penaltis"] = int(s.get("penaltis", 0)) + qtd
	stats[_id_key(j)] = s


func _jogador_com_stats(j: Dictionary) -> Dictionary:
	var r: Dictionary = j.duplicate(true)
	var s: Dictionary = _garantir_stats(j)

	var gols_salvos: int = int(r.get("gols_total", r.get("gols_grupo", r.get("gols", r.get("score", 0)))))
	var pens_salvos: int = int(r.get("penaltis_total", r.get("penaltis_grupo", r.get("penaltis", 0))))
	var pontos_salvos: int = int(r.get("pontos_grupo", 0))

	var gols_stats: int = int(s.get("gols", 0))
	var pens_stats: int = int(s.get("penaltis", 0))
	var pontos_stats: int = int(s.get("pontos_grupo", 0))

	r["jogos_total"] = int(s.get("jogos", 0))
	r["gols_total"] = maxi(gols_salvos, gols_stats)
	r["vitorias_total"] = int(s.get("vitorias", 0))
	r["penaltis_total"] = maxi(pens_salvos, pens_stats)
	r["pontos_grupo"] = maxi(pontos_salvos, pontos_stats)

	return r


# ============================================================
# AVANÇO DE FASE
# ============================================================
func _avancar_fase_se_preciso() -> bool:
	if fase_atual == FASE_PODIO:
		return false

	if not _fase_concluida(fase_atual):
		return false

	if fase_atual == FASE_GRUPOS:
		_calcular_ranking_grupos()

		var classificados: Array = _classificados_24()
		if classificados.size() < 24:
			push_warning("TORMENT: Primeira Fase concluída, mas classificados insuficientes: %d/24." % classificados.size())
			return false

		_criar_segunda_fase_com_bye()

		if not partidas.has(FASE_PLAYIN):
			return false

		var playin: Array = _as_array(partidas.get(FASE_PLAYIN, []))
		if playin.size() < 8:
			push_warning("TORMENT: Segunda Fase inválida. Jogos=%d. Não avançou." % playin.size())
			return false

		fase_atual = FASE_PLAYIN
		filtro_tela = FILTRO_INICIAL
		return true

	if fase_atual == FASE_PLAYIN:
		var vencedores_playin: Array = _vencedores_fase(FASE_PLAYIN)
		if vencedores_playin.size() < 8:
			push_warning("TORMENT: Segunda Fase concluída, mas vencedores insuficientes: %d/8." % vencedores_playin.size())
			return false

		_criar_oitavas_com_bye_e_vencedores()

		var oitavas: Array = _as_array(partidas.get(FASE_OITAVAS, []))
		if oitavas.size() < 8:
			push_warning("TORMENT: Oitavas inválidas. Jogos=%d. Não avançou." % oitavas.size())
			return false

		fase_atual = FASE_OITAVAS
		filtro_tela = FILTRO_INICIAL
		return true

	if fase_atual == FASE_OITAVAS:
		var vencedores_oitavas: Array = _vencedores_fase(FASE_OITAVAS)
		if vencedores_oitavas.size() < 8:
			push_warning("TORMENT: Oitavas concluídas, mas vencedores insuficientes: %d/8." % vencedores_oitavas.size())
			return false

		_criar_quartas_cruzadas()

		var quartas: Array = _as_array(partidas.get(FASE_QUARTAS, []))
		if quartas.size() < 4:
			push_warning("TORMENT: Quartas inválidas. Jogos=%d. Não avançou." % quartas.size())
			return false

		fase_atual = FASE_QUARTAS
		filtro_tela = FILTRO_PLAYOFFS
		return true

	if fase_atual == FASE_QUARTAS:
		var vencedores_quartas: Array = _vencedores_fase(FASE_QUARTAS)
		if vencedores_quartas.size() < 4:
			push_warning("TORMENT: Quartas concluídas, mas vencedores insuficientes: %d/4." % vencedores_quartas.size())
			return false

		_criar_semis_cruzadas()

		var semis: Array = _as_array(partidas.get(FASE_SEMIS, []))
		if semis.size() < 2:
			push_warning("TORMENT: Semifinal inválida. Jogos=%d. Não avançou." % semis.size())
			return false

		fase_atual = FASE_SEMIS
		filtro_tela = FILTRO_PLAYOFFS
		return true

	if fase_atual == FASE_SEMIS:
		var vencedores_semis: Array = _vencedores_fase(FASE_SEMIS)
		if vencedores_semis.size() < 2:
			push_warning("TORMENT: Semifinal concluída, mas vencedores insuficientes: %d/2." % vencedores_semis.size())
			return false

		semi_perdedores = _perdedores_fase(FASE_SEMIS)
		_criar_disputa_terceiro(semi_perdedores)

		# Se não deu pra montar o 3º lugar (faltou perdedor), pula direto à final.
		if not partidas.has(FASE_3LUGAR) or _as_array(partidas.get(FASE_3LUGAR, [])).is_empty():
			_criar_fase_mata_normal(FASE_FINAL, vencedores_semis)
			fase_atual = FASE_FINAL
			filtro_tela = FILTRO_PLAYOFFS
			return true

		fase_atual = FASE_3LUGAR
		filtro_tela = FILTRO_PLAYOFFS
		return true

	if fase_atual == FASE_3LUGAR:
		var venc_semis: Array = _vencedores_fase(FASE_SEMIS)
		if venc_semis.size() < 2:
			push_warning("TORMENT: 3º lugar concluído, mas vencedores da semi insuficientes.")
			return false

		_criar_fase_mata_normal(FASE_FINAL, venc_semis)

		var final_arr: Array = _as_array(partidas.get(FASE_FINAL, []))
		if final_arr.size() < 1:
			push_warning("TORMENT: Final inválida. Jogos=%d. Não avançou." % final_arr.size())
			return false

		fase_atual = FASE_FINAL
		filtro_tela = FILTRO_PLAYOFFS
		return true

	if fase_atual == FASE_FINAL:
		var campeao: Array = _vencedores_fase(FASE_FINAL)
		var vice: Array = _perdedores_fase(FASE_FINAL)

		if campeao.size() < 1 or vice.size() < 1:
			push_warning("TORMENT: Final concluída, mas campeão/vice não formados.")
			return false

		_montar_top3_final()

		if top3_final.size() < 3:
			push_warning("TORMENT: Top 3 incompleto. Não abriu pódio.")
			return false

		fase_atual = FASE_PODIO
		filtro_tela = FILTRO_PLAYOFFS
		return true

	return false



func _fase_concluida(fase: String) -> bool:
	if not partidas.has(fase):
		return false

	var arr: Array = _as_array(partidas[fase])
	if arr.is_empty():
		return false

	for item in arr:
		var p: Dictionary = _as_dict(item)
		if not bool(p.get("finalizada", false)):
			return false

	return true


func _vencedores_fase(fase: String) -> Array:
	var arr: Array = []

	if not partidas.has(fase):
		return arr

	var lista: Array = _as_array(partidas[fase])

	for item in lista:
		var p: Dictionary = _as_dict(item)
		if bool(p.get("finalizada", false)):
			arr.append(_jogador_com_stats(_as_dict(p.get("vencedor", {}))))

	return arr


func _perdedores_fase(fase: String) -> Array:
	var arr: Array = []

	if not partidas.has(fase):
		return arr

	var lista: Array = _as_array(partidas[fase])

	for item in lista:
		var p: Dictionary = _as_dict(item)
		if bool(p.get("finalizada", false)):
			arr.append(_jogador_com_stats(_as_dict(p.get("perdedor", {}))))

	return arr


func _calcular_ranking_grupos() -> void:
	ranking_grupos.clear()
	var classificados_24: Array = []
	var lista: Array = _as_array(partidas.get(FASE_GRUPOS, []))

	for item in lista:
		var p: Dictionary = _as_dict(item)
		var gi: int = int(p.get("grupo_index", -1))
		var grupo_nome: String = str(p.get("grupo_nome", "?"))
		var tabela: Array = []

		for jitem in _as_array(p.get("ranking", [])):
			var j: Dictionary = _jogador_com_stats(_as_dict(jitem))
			j["grupo_nome"] = grupo_nome
			tabela.append(j)

		ranking_grupos.append({"grupo": grupo_nome, "tabela": tabela})

		if tabela.size() >= 2:
			classificados_24.append(_as_dict(tabela[0]))
			classificados_24.append(_as_dict(tabela[1]))
		elif tabela.size() == 1:
			classificados_24.append(_as_dict(tabela[0]))

	classificados_24.sort_custom(func(a: Variant, b: Variant) -> bool:
		return _comparar_classificacao(_as_dict(a), _as_dict(b))
	)

	for i in range(classificados_24.size()):
		var c: Dictionary = _as_dict(classificados_24[i])
		c["ranking_geral"] = i + 1
		classificados_24[i] = c

	ranking_grupos.append({"geral_24": classificados_24})



func _comparar_classificacao(a: Dictionary, b: Dictionary) -> bool:
	var pa: int = int(a.get("pontos_grupo", 0))
	var pb: int = int(b.get("pontos_grupo", 0))
	if pa != pb:
		return pa > pb

	var va: int = int(a.get("vitorias_total", 0))
	var vb: int = int(b.get("vitorias_total", 0))
	if va != vb:
		return va > vb

	var sa: int = int(a.get("saldo_grupo", 0))
	var sb: int = int(b.get("saldo_grupo", 0))
	if sa != sb:
		return sa > sb

	var ga: int = int(a.get("gols_total", 0))
	var gb: int = int(b.get("gols_total", 0))
	if ga != gb:
		return ga > gb

	return _seed(a) < _seed(b)


func _classificados_24() -> Array:
	if ranking_grupos.is_empty():
		return []

	var ultimo: Dictionary = _as_dict(ranking_grupos[ranking_grupos.size() - 1])
	return _as_array(ultimo.get("geral_24", []))


func _lado_grupo(grupo_nome: String) -> String:
	var idx: int = NOMES_GRUPOS.find(grupo_nome)
	if idx <= 5:
		return "ESQUERDO"
	return "DIREITO"


func _normalizar_bye_oitavas_dict() -> void:
	if bye_oitavas.is_empty():
		bye_oitavas = {
			"esquerdo": [],
			"direito": []
		}

	if not bye_oitavas.has("esquerdo"):
		bye_oitavas["esquerdo"] = []

	if not bye_oitavas.has("direito"):
		bye_oitavas["direito"] = []

	bye_oitavas["esquerdo"] = _as_array(bye_oitavas.get("esquerdo", []))
	bye_oitavas["direito"] = _as_array(bye_oitavas.get("direito", []))


func _bye_oitavas_vazio() -> bool:
	_normalizar_bye_oitavas_dict()

	var esq: Array = _as_array(bye_oitavas.get("esquerdo", []))
	var dir: Array = _as_array(bye_oitavas.get("direito", []))

	return esq.is_empty() and dir.is_empty()


func _ordenar_classificados(lista: Array) -> void:
	lista.sort_custom(func(a: Variant, b: Variant) -> bool:
		return _comparar_classificacao(_as_dict(a), _as_dict(b))
	)


func _adicionar_unico_classificado(destino: Array, jogador: Dictionary) -> void:
	if jogador.is_empty():
		return

	var k: String = _id_key(jogador)

	for item in destino:
		var ja: Dictionary = _as_dict(item)
		if _id_key(ja) == k:
			return

	destino.append(_jogador_com_stats(jogador))


func _garantir_bye_oitavas() -> void:
	if not _bye_oitavas_vazio():
		get_tree().set_meta("torment_bye_oitavas", bye_oitavas)
		return

	if _classificados_24().is_empty() and _fase_concluida(FASE_GRUPOS):
		_calcular_ranking_grupos()

	var geral: Array = _classificados_24().duplicate(true)

	var lado_esquerdo: Array = []
	var lado_direito: Array = []

	for item in geral:
		var j: Dictionary = _as_dict(item)
		var grupo_nome: String = str(j.get("grupo_nome", j.get("grupo", "")))

		if _lado_grupo(grupo_nome) == "ESQUERDO":
			lado_esquerdo.append(j)
		else:
			lado_direito.append(j)

	_ordenar_classificados(lado_esquerdo)
	_ordenar_classificados(lado_direito)

	var bye_esq: Array = []
	var bye_dir: Array = []

	for i in range(mini(BYE_POR_LADO, lado_esquerdo.size())):
		var j_esq: Dictionary = _as_dict(lado_esquerdo[i]).duplicate(true)
		j_esq["bye_oitavas"] = true
		j_esq["lado_chave"] = "ESQUERDO"
		bye_esq.append(j_esq)

	for i in range(mini(BYE_POR_LADO, lado_direito.size())):
		var j_dir: Dictionary = _as_dict(lado_direito[i]).duplicate(true)
		j_dir["bye_oitavas"] = true
		j_dir["lado_chave"] = "DIREITO"
		bye_dir.append(j_dir)

	bye_oitavas = {
		"esquerdo": bye_esq,
		"direito": bye_dir
	}

	get_tree().set_meta("torment_bye_oitavas", bye_oitavas)


func _montar_lado_oitavas_seguro(lado: String, byes: Array, vencedores: Array) -> Array:
	var finalistas_lado: Array = []

	for item in byes:
		var j_bye: Dictionary = _as_dict(item)
		_adicionar_unico_classificado(finalistas_lado, j_bye)

	for item in vencedores:
		var j_venc: Dictionary = _as_dict(item)
		_adicionar_unico_classificado(finalistas_lado, j_venc)

	# Segurança: se por algum motivo o BYE não voltou do play,
	# recompõe pelos melhores da primeira fase daquele lado.
	if finalistas_lado.size() < 8:
		var geral: Array = _classificados_24().duplicate(true)
		_ordenar_classificados(geral)

		for item in geral:
			var j: Dictionary = _as_dict(item)
			var grupo_nome: String = str(j.get("grupo_nome", j.get("grupo", "")))

			if _lado_grupo(grupo_nome) != lado:
				continue

			_adicionar_unico_classificado(finalistas_lado, j)

			if finalistas_lado.size() >= 8:
				break

	_ordenar_classificados(finalistas_lado)

	while finalistas_lado.size() > 8:
		finalistas_lado.pop_back()

	return finalistas_lado



# ------------------------------------------------------------
# NOVA SEGUNDA FASE: 8 BYE (4 por lado) + 16 jogam mata-mata
# ida/volta dentro do próprio lado (4 confrontos por lado).
# ------------------------------------------------------------
func _criar_segunda_fase_com_bye() -> void:
	var geral: Array = _classificados_24().duplicate(true)

	if geral.size() < 24:
		push_warning("TORMENT: não criou Segunda Fase porque só existem %d classificados. Esperado: 24." % geral.size())
		return

	var lado_esquerdo: Array = []
	var lado_direito: Array = []

	for item in geral:
		var j: Dictionary = _as_dict(item)
		var grupo_nome: String = str(j.get("grupo_nome", j.get("grupo", "")))

		if _lado_grupo(grupo_nome) == "ESQUERDO":
			lado_esquerdo.append(j)
		else:
			lado_direito.append(j)

	_ordenar_classificados(lado_esquerdo)
	_ordenar_classificados(lado_direito)

	if lado_esquerdo.size() < 12 or lado_direito.size() < 12:
		push_warning("TORMENT: lados incompletos. Esquerdo=%d Direito=%d" % [
			lado_esquerdo.size(),
			lado_direito.size()
		])
		return

	var bye_esq: Array = []
	var bye_dir: Array = []
	var resto_esq: Array = []
	var resto_dir: Array = []

	for i in range(lado_esquerdo.size()):
		var j_esq: Dictionary = _as_dict(lado_esquerdo[i]).duplicate(true)
		j_esq["lado_chave"] = "ESQUERDO"

		if i < BYE_POR_LADO:
			j_esq["bye_oitavas"] = true
			bye_esq.append(j_esq)
		else:
			j_esq["bye_oitavas"] = false
			resto_esq.append(j_esq)

	for i in range(lado_direito.size()):
		var j_dir: Dictionary = _as_dict(lado_direito[i]).duplicate(true)
		j_dir["lado_chave"] = "DIREITO"

		if i < BYE_POR_LADO:
			j_dir["bye_oitavas"] = true
			bye_dir.append(j_dir)
		else:
			j_dir["bye_oitavas"] = false
			resto_dir.append(j_dir)

	bye_oitavas = {
		"esquerdo": bye_esq,
		"direito": bye_dir
	}

	get_tree().set_meta("torment_bye_oitavas", bye_oitavas)

	var arr: Array = []
	var numero: int = 1

	var jogos_esq: Array = _criar_confrontos_segunda_fase(resto_esq, "ESQUERDO", numero)
	arr.append_array(jogos_esq)

	numero = arr.size() + 1

	var jogos_dir: Array = _criar_confrontos_segunda_fase(resto_dir, "DIREITO", numero)
	arr.append_array(jogos_dir)

	if arr.size() != 8:
		push_warning("TORMENT: Segunda Fase criada com quantidade errada: %d. Esperado: 8." % arr.size())

	partidas[FASE_PLAYIN] = arr

	print("TORMENT SEGUNDA FASE CRIADA. BYE ESQ:", bye_esq.size(), " BYE DIR:", bye_dir.size(), " JOGOS:", arr.size())

	_salvar_estado()



func _criar_confrontos_segunda_fase(lista: Array, lado: String, numero_inicio: int) -> Array:
	var participantes: Array = lista.duplicate(true)

	participantes.sort_custom(func(a: Variant, b: Variant) -> bool:
		return _comparar_classificacao(_as_dict(a), _as_dict(b))
	)

	var arr: Array = []
	var total: int = participantes.size()
	var total_confrontos: int = int(total / 2)
	var numero: int = numero_inicio

	# Confronto de potes opostos dentro do mesmo lado: melhor x pior.
	for i in range(total_confrontos):
		var a: Dictionary = _as_dict(participantes[i])
		var b: Dictionary = _as_dict(participantes[total - 1 - i])
		var p: Dictionary = _nova_partida_mata(FASE_PLAYIN, a, b, numero)
		p["lado_chave"] = lado
		arr.append(p)
		numero += 1

	return arr


# ------------------------------------------------------------
# NOVAS OITAVAS: 8 do bye + 8 vencedores da Segunda Fase = 16.
# ------------------------------------------------------------
func _criar_oitavas_com_bye_e_vencedores() -> void:
	_garantir_bye_oitavas()
	_normalizar_bye_oitavas_dict()

	var bye_esq: Array = _as_array(bye_oitavas.get("esquerdo", [])).duplicate(true)
	var bye_dir: Array = _as_array(bye_oitavas.get("direito", [])).duplicate(true)

	var vencedores_esq: Array = []
	var vencedores_dir: Array = []

	var lista: Array = _as_array(partidas.get(FASE_PLAYIN, []))

	for item in lista:
		var p: Dictionary = _as_dict(item)

		if not bool(p.get("finalizada", false)):
			continue

		var lado: String = str(p.get("lado_chave", ""))
		var vencedor: Dictionary = _jogador_com_stats(_as_dict(p.get("vencedor", {})))

		if lado == "ESQUERDO":
			vencedores_esq.append(vencedor)
		elif lado == "DIREITO":
			vencedores_dir.append(vencedor)
		else:
			var grupo_nome: String = str(vencedor.get("grupo_nome", vencedor.get("grupo", "")))

			if _lado_grupo(grupo_nome) == "ESQUERDO":
				vencedores_esq.append(vencedor)
			else:
				vencedores_dir.append(vencedor)

	var classificados_esq: Array = _montar_lado_oitavas_seguro("ESQUERDO", bye_esq, vencedores_esq)
	var classificados_dir: Array = _montar_lado_oitavas_seguro("DIREITO", bye_dir, vencedores_dir)

	if classificados_esq.size() < 8:
		push_warning("TORMENT: Oitavas lado esquerdo incompletas: " + str(classificados_esq.size()))

	if classificados_dir.size() < 8:
		push_warning("TORMENT: Oitavas lado direito incompletas: " + str(classificados_dir.size()))

	var arr: Array = []

	arr.append_array(_criar_partidas_lado(FASE_OITAVAS, classificados_esq, "ESQUERDO", 1))
	arr.append_array(_criar_partidas_lado(FASE_OITAVAS, classificados_dir, "DIREITO", arr.size() + 1))

	partidas[FASE_OITAVAS] = arr

	_salvar_estado()



func _criar_partidas_lado(fase: String, lista: Array, lado: String, numero_inicio: int) -> Array:
	var participantes: Array = lista.duplicate(true)

	participantes.sort_custom(func(a: Variant, b: Variant) -> bool:
		return _comparar_classificacao(_as_dict(a), _as_dict(b))
	)

	var arr: Array = []
	var total: int = participantes.size()
	var total_confrontos: int = int(total / 2)
	var numero: int = numero_inicio

	for i in range(total_confrontos):
		var a: Dictionary = _as_dict(participantes[i])
		var b: Dictionary = _as_dict(participantes[total - 1 - i])
		var p: Dictionary = _nova_partida_mata(fase, a, b, numero)
		p["lado_chave"] = lado
		arr.append(p)
		numero += 1

	return arr


func _criar_quartas_cruzadas() -> void:
	var classificados: Array = _vencedores_fase(FASE_OITAVAS)

	classificados.sort_custom(func(a: Variant, b: Variant) -> bool:
		return _comparar_classificacao(_as_dict(a), _as_dict(b))
	)

	var lado_esquerdo: Array = []
	var lado_direito: Array = []

	for item in classificados:
		var j: Dictionary = _as_dict(item)
		var grupo_nome: String = str(j.get("grupo_nome", ""))

		if _lado_grupo(grupo_nome) == "ESQUERDO":
			lado_esquerdo.append(j)
		else:
			lado_direito.append(j)

	if lado_esquerdo.size() != 4 or lado_direito.size() != 4:
		_criar_fase_mata_normal(FASE_QUARTAS, classificados)
		return

	var arr: Array = []

	for i in range(4):
		var a: Dictionary = _as_dict(lado_esquerdo[i])
		var b: Dictionary = _as_dict(lado_direito[3 - i])
		var p: Dictionary = _nova_partida_mata(FASE_QUARTAS, a, b, i + 1)
		p["cruzamento"] = "ESQUERDA x DIREITA"
		arr.append(p)

	partidas[FASE_QUARTAS] = arr


func _criar_fase_mata_normal(fase: String, lista: Array) -> void:
	var participantes: Array = lista.duplicate(true)

	participantes.sort_custom(func(a: Variant, b: Variant) -> bool:
		return _comparar_classificacao(_as_dict(a), _as_dict(b))
	)

	var arr: Array = []
	var total: int = participantes.size()
	var total_confrontos: int = int(total / 2)

	for i in range(total_confrontos):
		var a: Dictionary = _as_dict(participantes[i])
		var b: Dictionary = _as_dict(participantes[total - 1 - i])
		var p: Dictionary = _nova_partida_mata(fase, a, b, i + 1)
		arr.append(p)

	partidas[fase] = arr


func _montar_top3_final() -> void:
	top3_final.clear()

	var finalistas: Array = _vencedores_fase(FASE_FINAL)
	var vices: Array = _perdedores_fase(FASE_FINAL)

	if finalistas.size() > 0:
		top3_final.append(_jogador_com_stats(_as_dict(finalistas[0])))

	if vices.size() > 0:
		top3_final.append(_jogador_com_stats(_as_dict(vices[0])))

	# 3º lugar: vencedor da disputa de 3º. Se não houve, cai pro melhor perdedor de semi.
	var terceiro: Array = _vencedores_fase(FASE_3LUGAR)

	if terceiro.size() > 0:
		top3_final.append(_jogador_com_stats(_as_dict(terceiro[0])))
	else:
		semi_perdedores.sort_custom(func(a: Variant, b: Variant) -> bool:
			return _comparar_classificacao(_as_dict(a), _as_dict(b))
		)
		if semi_perdedores.size() > 0:
			top3_final.append(_jogador_com_stats(_as_dict(semi_perdedores[0])))



# ============================================================
# JOGAR / AUTO BOT
# ============================================================
func _jogar_proxima_partida() -> void:
	if _processando_resultado_retorno:
		return

	# IDA: quem mostra o loading (com patrocinadores) é o PLAY.
	# O lobby não abre mais loading próprio aqui (fim do loading duplo).
	_parar_leds_idle_lobby()

	# Resolve somente partidas 100% Boots.
	_resolver_automaticos_ate_proxima_real()
	_salvar_estado()
	_renderizar()

	if fase_atual == FASE_PODIO:
		_iniciar_leds_idle_lobby()
		return

	var info: Dictionary = _proxima_partida_pendente()

	if info.is_empty():
		if _fase_concluida(fase_atual):
			_avancar_fase_se_preciso()
			_resolver_automaticos_ate_proxima_real()
			_salvar_estado()
			_renderizar()

		_iniciar_leds_idle_lobby()
		return

	var index: int = int(info.get("index", -1))
	var etapa: String = str(info.get("etapa", "ida"))
	var arr: Array = _as_array(partidas.get(fase_atual, []))

	if index < 0 or index >= arr.size():
		_iniciar_leds_idle_lobby()
		return

	var p: Dictionary = _as_dict(arr[index])

	if _deve_auto_resolver(p):
		_auto_resolver(index, etapa)
		_resolver_automaticos_ate_proxima_real()
		_salvar_estado()
		_renderizar()
		_iniciar_leds_idle_lobby()
		return

	# Abre a partida real. O play cuida do carregamento na ida.
		# Abre a partida real somente depois do som de START.
	if _abrindo_partida_com_sfx:
		return

	_abrindo_partida_com_sfx = true
	await _tocar_start_game_e_aguardar()
	_abrindo_partida_com_sfx = false

	_abrir_partida(index, etapa)




func _resolver_automaticos_ate_proxima_real() -> bool:
	var mudou: bool = false
	var seguranca: int = 0

	while seguranca < 1200:
		seguranca += 1

		if fase_atual == FASE_PODIO:
			break

		# Primeiro resolve TODOS os jogos 100% Boot da fase atual.
		# Isso faz as chaves só de boot andarem sozinhas no início.
		var resolveu_um: bool = _resolver_um_automatico_da_fase_atual()

		if resolveu_um:
			mudou = true
			continue

		# Depois de resolver os boots, se a fase inteira terminou,
		# avança uma fase e continua resolvendo boots da nova fase.
		if _fase_concluida(fase_atual):
			if _avancar_fase_se_preciso():
				mudou = true
				continue

		# Se não tem mais boot automático e ainda existe partida real,
		# para aqui e deixa o START abrir o jogo certo.
		break

	if seguranca >= 1200:
		push_warning("TORMENT: segurança atingida ao resolver automáticos.")

	return mudou



func _resolver_um_automatico_da_fase_atual() -> bool:
	if not partidas.has(fase_atual):
		return false

	var arr: Array = _as_array(partidas.get(fase_atual, []))

	for i in range(arr.size()):
		var p: Dictionary = _as_dict(arr[i])

		if bool(p.get("finalizada", false)):
			continue

		if not _deve_auto_resolver(p):
			continue

		var etapa: String = _etapa_pendente_da_partida(p)

		if etapa.is_empty():
			continue

		_auto_resolver(i, etapa)
		return true

	return false


func _etapa_pendente_da_partida(p: Dictionary) -> String:
	if p.is_empty():
		return ""

	if bool(p.get("finalizada", false)):
		return ""

	if str(p.get("tipo", "")) == "grupo":
		var ida: Dictionary = _as_dict(p.get("ida", {}))
		var volta: Dictionary = _as_dict(p.get("volta", {}))

		if not bool(ida.get("finalizada", false)):
			return "ida"

		if not bool(volta.get("finalizada", false)):
			return "volta"

		return ""

	var ida_m: Dictionary = _as_dict(p.get("ida", {}))
	var volta_m: Dictionary = _as_dict(p.get("volta", {}))

	if not bool(ida_m.get("finalizada", false)):
		return "ida"

	if not bool(volta_m.get("finalizada", false)):
		return "volta"

	if bool(p.get("aguardando_penaltis", false)):
		return "penaltis"

	return ""


func _limpar_metas_partida_atual_sem_resultado() -> void:
	var metas: Array[String] = [
		META_PARTIDA,
		META_PARTIDA_INDEX,
		META_PARTIDA_FASE,
		META_PARTIDA_ETAPA,
		META_PARTIDA_ID
	]

	for m in metas:
		if get_tree().has_meta(m):
			get_tree().remove_meta(m)



func _proxima_partida_pendente() -> Dictionary:
	if not partidas.has(fase_atual):
		return {}

	var arr: Array = _as_array(partidas[fase_atual])

	for i in range(arr.size()):
		var p: Dictionary = _as_dict(arr[i])

		if bool(p.get("finalizada", false)):
			continue

		if _deve_auto_resolver(p):
			continue

		if str(p.get("tipo", "")) == "grupo":
			var ida: Dictionary = _as_dict(p.get("ida", {}))
			var volta: Dictionary = _as_dict(p.get("volta", {}))

			if not bool(ida.get("finalizada", false)):
				return {
					"index": i,
					"etapa": "ida"
				}

			if not bool(volta.get("finalizada", false)):
				return {
					"index": i,
					"etapa": "volta"
				}
		else:
			var ida_m: Dictionary = _as_dict(p.get("ida", {}))
			var volta_m: Dictionary = _as_dict(p.get("volta", {}))

			if not bool(ida_m.get("finalizada", false)):
				return {
					"index": i,
					"etapa": "ida"
				}

			if not bool(volta_m.get("finalizada", false)):
				return {
					"index": i,
					"etapa": "volta"
				}

			if bool(p.get("aguardando_penaltis", false)):
				return {
					"index": i,
					"etapa": "penaltis"
				}

	return {}



func _deve_auto_resolver(p: Dictionary) -> bool:
	if not AUTO_RESOLVER_BOTS:
		return false

	if p.is_empty():
		return false

	if bool(p.get("finalizada", false)):
		return false

	var tipo: String = str(p.get("tipo", ""))

	# PRIMEIRA FASE 3X3:
	# Só resolve automático se TODOS forem Boots.
	# Se tiver pelo menos 1 player real, abre a partida com os bots junto.
	if tipo == "grupo":
		var lista: Array = _as_array(p.get("jogadores", []))

		if lista.is_empty():
			return false

		for item in lista:
			var j: Dictionary = _as_dict(item)

			if not _eh_bot(j):
				return false

		return true

	# MATA-MATA 1X1:
	# Correção principal:
	# Real x Boot NÃO é automático.
	# Boot x Real NÃO é automático.
	# Só Boot x Boot é automático.
	var a: Dictionary = _as_dict(p.get("a", {}))
	var b: Dictionary = _as_dict(p.get("b", {}))

	if a.is_empty() or b.is_empty():
		return false

	var a_bot: bool = _eh_bot(a)
	var b_bot: bool = _eh_bot(b)

	return a_bot and b_bot


func _auto_resolver(index: int, etapa: String) -> void:
	var arr: Array = _as_array(partidas.get(fase_atual, []))
	if index < 0 or index >= arr.size():
		return

	var p: Dictionary = _as_dict(arr[index])
	var pid: String = str(p.get("id", ""))

	if str(p.get("tipo", "")) == "grupo":
		_registrar_resultado({
			"fase": fase_atual,
			"partida_index": index,
			"partida_id": pid,
			"tipo": "grupo",
			"etapa": etapa,
			"ranking": _ranking_auto_grupo(p),
			"auto": true
		})
		return

	var placar: Vector2i = _placar_auto(p)

	_registrar_resultado({
		"fase": fase_atual,
		"partida_index": index,
		"partida_id": pid,
		"etapa": etapa,
		"gols_a": int(placar.x),
		"gols_b": int(placar.y),
		"auto": true
	})


func _placar_auto(p: Dictionary) -> Vector2i:
	var a: Dictionary = _as_dict(p.get("a", {}))
	var b: Dictionary = _as_dict(p.get("b", {}))

	var a_bot: bool = _eh_bot(a)
	var b_bot: bool = _eh_bot(b)

	# Segurança:
	# Real x Boot não deveria mais cair aqui.
	if not (a_bot and b_bot):
		return Vector2i(0, 0)

	var ida: Dictionary = _as_dict(p.get("ida", {}))
	var etapa_volta: bool = bool(ida.get("finalizada", false))

	var ga: int = randi_range(0, 5)
	var gb: int = randi_range(0, 5)

	if etapa_volta:
		var ida_a: int = int(ida.get("a", 0))
		var ida_b: int = int(ida.get("b", 0))

		if ida_a + ga == ida_b + gb:
			if randf() < 0.5:
				ga += 1
			else:
				gb += 1
	else:
		if ga == gb:
			if randf() < 0.5:
				ga += 1
			else:
				gb += 1

	return Vector2i(ga, gb)


func _abrir_partida(index: int, etapa: String) -> void:
	if not ResourceLoader.exists(CENA_PLAY):
		return

	var arr: Array = _as_array(partidas.get(fase_atual, []))
	if index < 0 or index >= arr.size():
		return

	var p: Dictionary = _as_dict(arr[index]).duplicate(true)
	var eh_chave: bool = str(p.get("tipo", "")) == "grupo"

	p["fase_lobby"] = fase_atual
	p["fase"] = _fase_play(fase_atual)
	p["fase_nome"] = _fase_nome_play(fase_atual)
	p["partida_index"] = index
	p["partida_id"] = str(p.get("id", ""))
	p["etapa"] = etapa
	p["lobby_controla_torneio"] = true

	if eh_chave:
		var chave_nome_txt: String = str(p.get("grupo_nome", "-"))

		p["chave"] = chave_nome_txt
		p["nome"] = "CHAVE %s  •  %s" % [
			chave_nome_txt,
			etapa.to_upper()
		]
		p["modo"] = "3X3"
		p["ida_volta"] = false

		var lista_play: Array = []

		for item in _as_array(p.get("jogadores", [])):
			lista_play.append(_jogador_para_play(_as_dict(item)))

		p["jogadores"] = lista_play
	else:
		p["chave"] = "%s %02d" % [
			fase_atual,
			int(p.get("numero", index + 1))
		]

		p["nome"] = "%s  •  %s" % [
			fase_atual,
			etapa.to_upper()
		]

		p["modo"] = "1X1"
		p["ida_volta"] = false

		p["jogadores"] = [
			_jogador_para_play(_as_dict(p.get("a", {}))),
			_jogador_para_play(_as_dict(p.get("b", {})))
		]

	p["modo_penaltis"] = etapa == "penaltis"
	p["somente_penaltis"] = etapa == "penaltis"

	get_tree().set_meta(META_PARTIDA, p)
	get_tree().set_meta(META_PARTIDA_INDEX, index)
	get_tree().set_meta(META_PARTIDA_FASE, fase_atual)
	get_tree().set_meta(META_PARTIDA_ETAPA, etapa)
	get_tree().set_meta(META_PARTIDA_ID, str(p.get("id", "")))

	_salvar_estado()
	_parar_musica_lobby_torment()
	get_tree().change_scene_to_file(CENA_PLAY)



func _ranking_auto_grupo(p: Dictionary) -> Array:
	var jogadores_grupo: Array = _as_array(p.get("jogadores", []))
	var etapa_txt: String = "ida"

	var ida: Dictionary = _as_dict(p.get("ida", {}))
	if bool(ida.get("finalizada", false)):
		etapa_txt = "volta"

	var ranking: Array = []

	for i in range(jogadores_grupo.size()):
		var j: Dictionary = _as_dict(jogadores_grupo[i])
		var bot: bool = _eh_bot(j)

		var gols: int = 0

		if bot:
			gols = randi_range(1, 8)
		else:
			gols = randi_range(5, 14)

		# Varia a volta para não repetir placar da ida.
		if etapa_txt == "volta":
			gols += randi_range(0, 4)

		ranking.append({
			"player_index": i,
			"nome": _nome_jogador(j),
			"gols": gols,
			"penaltis": 0,
			"boot": bot,
			"posicao": i + 1
		})

	ranking.sort_custom(func(a: Variant, b: Variant) -> bool:
		var da: Dictionary = _as_dict(a)
		var db: Dictionary = _as_dict(b)

		var ga: int = int(da.get("gols", 0))
		var gb: int = int(db.get("gols", 0))

		if ga != gb:
			return ga > gb

		var ia: int = int(da.get("player_index", 0))
		var ib: int = int(db.get("player_index", 0))

		var ja: Dictionary = _as_dict(jogadores_grupo[ia])
		var jb: Dictionary = _as_dict(jogadores_grupo[ib])

		var ba: bool = _eh_bot(ja)
		var bb: bool = _eh_bot(jb)

		if ba != bb:
			return not ba

		return _seed(ja) < _seed(jb)
	)

	for pos in range(ranking.size()):
		var r: Dictionary = _as_dict(ranking[pos])
		r["posicao"] = pos + 1
		ranking[pos] = r

	return ranking


# ------------------------------------------------------------
# RESULTADO DA PRIMEIRA FASE (GRUPO) COM IDA E VOLTA
# Cada perna manda seu próprio ranking (por jogo). O ranking
# final do grupo soma os gols das duas pernas.
# ------------------------------------------------------------
func _aplicar_resultado_grupo_ida_volta(p: Dictionary, etapa: String, ranking_raw: Array) -> void:
	if bool(p.get("finalizada", false)):
		return

	var chave: String = "ida"
	if etapa == "volta":
		chave = "volta"

	var leg: Dictionary = _as_dict(p.get(chave, {}))
	if bool(leg.get("finalizada", false)):
		return

	var jogadores_grupo: Array = _as_array(p.get("jogadores", []))
	var ranking_perna: Array = _normalizar_ranking_grupo(jogadores_grupo, ranking_raw)

	leg["ranking"] = ranking_perna
	leg["finalizada"] = true
	p[chave] = leg

	# Só fecha o grupo (e contabiliza estatísticas/pontos) quando
	# IDA e VOLTA estiverem ambas finalizadas.
	var ida: Dictionary = _as_dict(p.get("ida", {}))
	var volta: Dictionary = _as_dict(p.get("volta", {}))

	if not (bool(ida.get("finalizada", false)) and bool(volta.get("finalizada", false))):
		return

	_finalizar_grupo_ida_volta(p, jogadores_grupo, _as_array(ida.get("ranking", [])), _as_array(volta.get("ranking", [])))


func _normalizar_ranking_grupo(jogadores_grupo: Array, ranking_raw: Array) -> Array:
	var ranking_final: Array = []
	var soma_gols: int = 0

	for item in ranking_raw:
		var r: Dictionary = _as_dict(item)
		var idx: int = int(r.get("player_index", -1))

		if idx < 0 or idx >= jogadores_grupo.size():
			continue

		var gols: int = int(r.get("gols", r.get("gols_total", r.get("score", r.get("gols_normais", 0)))))
		var pen: int = int(r.get("penaltis", r.get("penaltis_total", 0)))

		soma_gols += gols

		ranking_final.append({
			"player_index": idx,
			"gols": gols,
			"penaltis": pen
		})

	# Se veio tudo zerado/vazio, cria resultado de segurança.
	# Isso impede o torneio de morrer com placar 0.
	if ranking_final.is_empty() or soma_gols <= 0:
		ranking_final.clear()

		for i in range(jogadores_grupo.size()):
			var j: Dictionary = _as_dict(jogadores_grupo[i])
			var gols_auto: int = randi_range(1, 8)

			if not _eh_bot(j):
				gols_auto = randi_range(5, 14)

			ranking_final.append({
				"player_index": i,
				"gols": gols_auto,
				"penaltis": 0
			})

	ranking_final.sort_custom(func(a: Variant, b: Variant) -> bool:
		var da: Dictionary = _as_dict(a)
		var db: Dictionary = _as_dict(b)

		var ga: int = int(da.get("gols", 0))
		var gb: int = int(db.get("gols", 0))

		if ga != gb:
			return ga > gb

		var ia: int = int(da.get("player_index", 0))
		var ib: int = int(db.get("player_index", 0))

		var ja: Dictionary = _as_dict(jogadores_grupo[ia])
		var jb: Dictionary = _as_dict(jogadores_grupo[ib])

		var ba: bool = _eh_bot(ja)
		var bb: bool = _eh_bot(jb)

		if ba != bb:
			return not ba

		return _seed(ja) < _seed(jb)
	)

	return ranking_final


func _finalizar_grupo_ida_volta(p: Dictionary, jogadores_grupo: Array, ranking_ida: Array, ranking_volta: Array) -> void:
	var gols_por_index: Dictionary = {}
	var pens_por_index: Dictionary = {}

	for item in ranking_ida:
		var r: Dictionary = _as_dict(item)
		var idx: int = int(r.get("player_index", -1))
		if idx < 0:
			continue

		gols_por_index[idx] = int(gols_por_index.get(idx, 0)) + int(r.get("gols", 0))
		pens_por_index[idx] = int(pens_por_index.get(idx, 0)) + int(r.get("penaltis", 0))

	for item in ranking_volta:
		var r2: Dictionary = _as_dict(item)
		var idx2: int = int(r2.get("player_index", -1))
		if idx2 < 0:
			continue

		gols_por_index[idx2] = int(gols_por_index.get(idx2, 0)) + int(r2.get("gols", 0))
		pens_por_index[idx2] = int(pens_por_index.get(idx2, 0)) + int(r2.get("penaltis", 0))

	var ranking_final: Array = []

	for idx3 in range(jogadores_grupo.size()):
		var base: Dictionary = _as_dict(jogadores_grupo[idx3]).duplicate(true)
		var gols_final: int = int(gols_por_index.get(idx3, 0))
		var pens_final: int = int(pens_por_index.get(idx3, 0))

		base["player_index"] = idx3
		base["gols_grupo"] = gols_final
		base["gols_total"] = gols_final
		base["gols"] = gols_final
		base["score"] = gols_final
		base["penaltis_grupo"] = pens_final
		base["penaltis_total"] = pens_final

		ranking_final.append(base)

	ranking_final.sort_custom(func(a: Variant, b: Variant) -> bool:
		var ja: Dictionary = _as_dict(a)
		var jb: Dictionary = _as_dict(b)

		var ga: int = int(ja.get("gols_grupo", 0))
		var gb: int = int(jb.get("gols_grupo", 0))

		if ga != gb:
			return ga > gb

		var ba: bool = _eh_bot(ja)
		var bb: bool = _eh_bot(jb)

		if ba != bb:
			return not ba

		return _seed(ja) < _seed(jb)
	)

	for pos in range(ranking_final.size()):
		var jg: Dictionary = _as_dict(ranking_final[pos])
		var pontos: int = 0

		if pos == 0:
			pontos = 6
		elif pos == 1:
			pontos = 3
		else:
			pontos = 0

		jg["pos_grupo"] = pos + 1
		jg["posicao"] = pos + 1
		jg["classificado"] = pos < 2
		jg["pontos_grupo"] = pontos
		jg["grupo_nome"] = str(p.get("grupo_nome", ""))

		ranking_final[pos] = jg
		_registrar_stats_grupo_jogador(jg)

	p["ranking"] = ranking_final
	p["finalizada"] = true

	if ranking_final.size() > 0:
		p["vencedor"] = _as_dict(ranking_final[0])

	print("TORMENT GRUPO FINALIZADO:", str(p.get("grupo_nome", "")), " RANKING:", ranking_final)



func _registrar_stats_grupo_jogador(j: Dictionary) -> void:
	var s: Dictionary = _garantir_stats(j)

	# A chave fecha somente depois da IDA + VOLTA.
	s["jogos"] = int(s.get("jogos", 0)) + 2
	s["gols"] = int(s.get("gols", 0)) + int(j.get("gols_grupo", 0))
	s["pontos_grupo"] = int(s.get("pontos_grupo", 0)) + int(j.get("pontos_grupo", 0))
	s["penaltis"] = int(s.get("penaltis", 0)) + int(j.get("penaltis_grupo", 0))

	if int(j.get("pos_grupo", 99)) == 1:
		s["vitorias"] = int(s.get("vitorias", 0)) + 1

	stats[_id_key(j)] = s


func _jogador_para_play(j: Dictionary) -> Dictionary:
	var d: Dictionary = j.duplicate(true)
	d["boot"] = _eh_bot(j)
	d["nome"] = _nome_jogador(j)
	if not (d.get("cor") is Color):
		d["cor"] = _cor_jogador(j)
	return d


func _fase_play(fase: String) -> String:
	match fase:
		FASE_GRUPOS:
			return "FASE_1"
		FASE_PLAYIN:
			return "SEGUNDA_FASE"
		FASE_OITAVAS:
			return "OITAVAS"
		FASE_QUARTAS:
			return "QUARTAS"
		FASE_SEMIS:
			return "SEMIFINAL"
		FASE_3LUGAR:
			return "TERCEIRO"
		FASE_FINAL:
			return "FINAL"

	return "FASE_1"



func _fase_nome_play(fase: String) -> String:
	match fase:
		FASE_GRUPOS:
			return "PRIMEIRA FASE — CHAVE"
		FASE_PLAYIN:
			return "SEGUNDA FASE"
		FASE_OITAVAS:
			return "OITAVAS"
		FASE_QUARTAS:
			return "QUARTAS"
		FASE_SEMIS:
			return "SEMIFINAL"
		FASE_3LUGAR:
			return "DISPUTA DE 3º LUGAR"
		FASE_FINAL:
			return "GRANDE FINAL"

	return "TORNEIO"



# ============================================================
# UI PRINCIPAL — TORMENT LOBBY COMPACTO / ENQUADRADO
# Mantém 100% a lógica do torneio.
# Apenas remodela visual: cabeçalho menor, fundo neutro,
# containers bem presos, cards menores e tudo enquadrado.
# ============================================================

func _travar_torment_fullscreen() -> void:
	RenderingServer.set_default_clear_color(Color(0.006, 0.008, 0.016, 1.0))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _criar_interface() -> void:
	if is_instance_valid(canvas):
		canvas.queue_free()

	canvas = CanvasLayer.new()
	canvas.layer = 2
	add_child(canvas)

	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)


func _renderizar() -> void:
	if not is_instance_valid(root):
		return

	for child in root.get_children():
		child.queue_free()

	var tela: Vector2 = get_viewport_rect().size
	viewport_cache = tela
	root.size = tela

	_criar_back_torment(root, tela)
	_render_topbar_torment(root, tela)
	_render_fluxo_torment(root, tela)

	var margem_x: float = 22.0
	var top_y: float = 122.0
	var bottom_h: float = 54.0

	var area: Rect2 = Rect2(
		Vector2(margem_x, top_y),
		Vector2(tela.x - margem_x * 2.0, tela.y - top_y - bottom_h - 12.0)
	)

	if fase_atual == FASE_PODIO:
		_render_podio_final(root, area)
	elif filtro_tela == FILTRO_INICIAL:
		_render_chaveamento_afunilado_inicial(root, area)
	else:
		_render_chaveamento_afunilado_playoffs(root, area)

	_render_footer_torment(root, tela)

	if not aviso_pendente.is_empty():
		var aviso: Dictionary = aviso_pendente.duplicate(true)
		aviso_pendente.clear()

		call_deferred(
			"_mostrar_aviso_classificado",
			root,
			_as_dict(aviso.get("vencedor", {})),
			_as_dict(aviso.get("perdedor", {})),
			str(aviso.get("fase", ""))
		)


# ============================================================
# FUNDO / TOPO / FLUXO
# ============================================================

func _criar_back_torment(parent: Control, tela: Vector2) -> void:
	var base := ColorRect.new()
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.color = Color(0.006, 0.008, 0.016, 1.0)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(base)

	if ResourceLoader.exists(IMAGEM_BACK_TORMENT):
		var img := TextureRect.new()
		img.set_anchors_preset(Control.PRESET_FULL_RECT)
		img.texture = load(IMAGEM_BACK_TORMENT)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_SCALE
		img.modulate = Color(1, 1, 1, 0.28)
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(img)

	var escuro := ColorRect.new()
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	escuro.color = Color(0, 0, 0, 0.58)
	escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(escuro)

	var vinheta_top := ColorRect.new()
	vinheta_top.position = Vector2.ZERO
	vinheta_top.size = Vector2(tela.x, 122)
	vinheta_top.color = Color(0.025, 0.012, 0.035, 0.82)
	vinheta_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(vinheta_top)

	var vinheta_bottom := ColorRect.new()
	vinheta_bottom.position = Vector2(0, tela.y - 72)
	vinheta_bottom.size = Vector2(tela.x, 72)
	vinheta_bottom.color = Color(0.006, 0.008, 0.016, 0.86)
	vinheta_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(vinheta_bottom)


func _render_topbar_torment(parent: Control, tela: Vector2) -> void:
	var top := Panel.new()
	top.position = Vector2(18, 12)
	top.size = Vector2(tela.x - 36, 52)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_stylebox_override(
		"panel",
		_style_panel_torment(COR_TORMENT, Color(0.012, 0.014, 0.026, 0.92), 0.22, 16, 2)
	)
	parent.add_child(top)

	var titulo := _label("TORMENT ARENA 36", 25, Color.WHITE, COR_TORMENT)
	titulo.position = Vector2(18, 0)
	titulo.size = Vector2(top.size.x * 0.34, top.size.y)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top.add_child(titulo)

	var subtitulo := _label("12 GRUPOS  •  IDA/VOLTA  •  AGREGADO  •  PÊNALTIS REAL x REAL", 12, COR_TEXTO_SUAVE)
	subtitulo.position = Vector2(top.size.x * 0.35, 0)
	subtitulo.size = Vector2(top.size.x * 0.34, top.size.y)
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subtitulo.clip_text = true
	top.add_child(subtitulo)

	# Apenas os botões de filtro de tela. O botão de JOGAR fica
	# somente no rodapé (footer), evitando duplicidade.
	var btn_w: float = 122.0
	var btn_h: float = 34.0
	var gap: float = 8.0
	var x: float = top.size.x - btn_w * 2.0 - gap - 12.0
	var y: float = 9.0

	_criar_botao(
		top,
		Rect2(Vector2(x, y), Vector2(btn_w, btn_h)),
		"INICIAL",
		COR_TORMENT if filtro_tela == FILTRO_INICIAL else Color(0.25, 0.25, 0.32),
		func() -> void:
			filtro_tela = FILTRO_INICIAL
			_renderizar()
	)

	_criar_botao(
		top,
		Rect2(Vector2(x + btn_w + gap, y), Vector2(btn_w, btn_h)),
		"PLAYOFFS",
		COR_TORMENT if filtro_tela == FILTRO_PLAYOFFS else Color(0.25, 0.25, 0.32),
		func() -> void:
			filtro_tela = FILTRO_PLAYOFFS
			_renderizar()
	)


func _render_fluxo_torment(parent: Control, tela: Vector2) -> void:
	var fases: Array = [
		[FASE_GRUPOS, "1ª", "36→24"],
		[FASE_PLAYIN, "2ª", "16→8"],
		[FASE_OITAVAS, "OIT", "16→8"],
		[FASE_QUARTAS, "QUA", "8→4"],
		[FASE_SEMIS, "SEM", "4→2"],
		[FASE_FINAL, "FINAL", "2→1"],
		[FASE_PODIO, "PÓDIO", "TOP3"]
	]

	var x0: float = 22.0
	var y: float = 72.0
	var h: float = 38.0
	var gap: float = 8.0
	var w: float = (tela.x - x0 * 2.0 - gap * float(fases.size() - 1)) / float(fases.size())

	for i in range(fases.size()):
		var item: Array = _as_array(fases[i])
		var fase: String = str(item[0])
		var estado: String = _estado_visual_fase_torment(fase)

		var cor: Color = Color(0.20, 0.22, 0.30)
		var bg: Color = Color(0.010, 0.012, 0.020, 0.92)
		var brilho: float = 0.02

		if estado == "ATUAL":
			cor = COR_ALERTA
			bg = Color(0.052, 0.036, 0.010, 0.96)
			brilho = 0.32
		elif estado == "CONCLUIDA":
			cor = COR_OK
			bg = Color(0.010, 0.040, 0.025, 0.94)
			brilho = 0.16
		elif estado == "LIBERADA":
			cor = COR_TORMENT
			bg = Color(0.034, 0.010, 0.046, 0.94)
			brilho = 0.14

		var box := Panel.new()
		box.position = Vector2(x0 + float(i) * (w + gap), y)
		box.size = Vector2(w, h)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_theme_stylebox_override("panel", _style_panel_torment(cor, bg, brilho, 12, 2))
		parent.add_child(box)

		var t := _label("%s  %s" % [str(item[1]), str(item[2])], 12, Color.WHITE, cor)
		t.position = Vector2(4, 0)
		t.size = box.size - Vector2(8, 0)
		t.clip_text = true
		box.add_child(t)


func _estado_visual_fase_torment(fase: String) -> String:
	if fase == fase_atual:
		return "ATUAL"

	if _indice_fase(fase) < _indice_fase(fase_atual):
		return "CONCLUIDA"

	if partidas.has(fase):
		return "LIBERADA"

	return "BLOQUEADA"



func _render_footer_torment(parent: Control, tela: Vector2) -> void:
	var prox: Dictionary = _proxima_partida_pendente()

	var texto: String = "START  •  PRÓXIMA PARTIDA"
	var cor: Color = COR_OK

	if prox.is_empty():
		if fase_atual == FASE_PODIO:
			texto = "TORNEIO FINALIZADO  •  SEGURE START PARA VOLTAR AO INÍCIO"
			cor = COR_ALERTA
		else:
			texto = "AGUARDANDO PRÓXIMA FASE"
			cor = COR_ALERTA
	else:
		texto = _texto_proxima_partida_clara(prox)
		cor = COR_OK

	var footer_h: float = 38.0
	var btn_w: float = 150.0
	var gap: float = 10.0

	var reais: Array = _players_reais_proxima_partida()
	var chips_w: float = 0.0
	if not reais.is_empty():
		chips_w = clampf(float(reais.size()) * 168.0, 168.0, tela.x * 0.42)

	var box_w: float = tela.x - 44.0 - btn_w - gap - chips_w
	if chips_w > 0.0:
		box_w -= 8.0
	box_w = maxf(box_w, 260.0)

	var box := Panel.new()
	box.position = Vector2(22, tela.y - 50)
	box.size = Vector2(box_w, footer_h)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override(
		"panel",
		_style_panel_torment(cor, Color(0.010, 0.012, 0.020, 0.94), 0.18, 14, 2)
	)
	parent.add_child(box)

	var lbl := _label(texto, 15, Color.WHITE, cor)
	lbl.position = Vector2.ZERO
	lbl.size = box.size
	lbl.clip_text = true
	box.add_child(lbl)

	# Destaque dos players reais que vão jogar a próxima partida.
	if not reais.is_empty():
		var cx: float = box.position.x + box.size.x + 8.0
		var cw: float = (chips_w - 6.0 * float(reais.size() - 1)) / float(reais.size())

		for k in range(reais.size()):
			var j: Dictionary = _as_dict(reais[k])
			var cj: Color = _cor_jogador(j)

			var chip := Panel.new()
			chip.position = Vector2(cx + float(k) * (cw + 6.0), tela.y - 50)
			chip.size = Vector2(cw, footer_h)
			chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			chip.clip_contents = true
			chip.add_theme_stylebox_override(
				"panel",
				_style_panel_torment(cj, Color(cj.r * 0.12, cj.g * 0.12, cj.b * 0.12, 0.97), 0.34, 12, 2)
			)
			parent.add_child(chip)

			var risco := ColorRect.new()
			risco.position = Vector2(6.0, footer_h * 0.5 - 8.0)
			risco.size = Vector2(5.0, 16.0)
			risco.color = cj
			risco.mouse_filter = Control.MOUSE_FILTER_IGNORE
			chip.add_child(risco)

			var lbln := _label(_nome_jogador(j), 13, Color.WHITE, cj)
			lbln.position = Vector2(16.0, 0.0)
			lbln.size = Vector2(cw - 20.0, footer_h)
			lbln.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			lbln.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbln.clip_text = true
			chip.add_child(lbln)

	var jogar_txt: String = "START"
	var jogar_cor: Color = COR_OK

	if fase_atual == FASE_PODIO:
		jogar_txt = "SEGURE START"
		jogar_cor = COR_ALERTA

		_criar_botao(
		parent,
		Rect2(Vector2(tela.x - 22 - btn_w, tela.y - 50), Vector2(btn_w, footer_h)),
		jogar_txt,
		jogar_cor,
		func() -> void:
			if fase_atual != FASE_PODIO:
				_jogar_proxima_partida()
	)

	if fase_atual == FASE_PODIO:
		_render_barra_hold_start_podio(parent, tela)


func _texto_proxima_partida_clara(prox: Dictionary) -> String:
	var index: int = int(prox.get("index", -1))
	var etapa: String = str(prox.get("etapa", "ida")).to_upper()

	var arr: Array = _as_array(partidas.get(fase_atual, []))

	if index < 0 or index >= arr.size():
		return "%s  •  %s  •  START" % [fase_atual, etapa]

	var p: Dictionary = _as_dict(arr[index])

	if str(p.get("tipo", "")) == "grupo":
		var chave_nome: String = str(p.get("grupo_nome", "-"))
		return "PRÓXIMA: CHAVE %s  •  %s  •  START" % [
			chave_nome,
			etapa
		]

	var a: Dictionary = _as_dict(p.get("a", {}))
	var b: Dictionary = _as_dict(p.get("b", {}))
	var numero: int = int(p.get("numero", index + 1))

	return "PRÓXIMA: %s %02d  •  %s  •  %s x %s  •  START" % [
		fase_atual,
		numero,
		etapa,
		_nome_jogador(a),
		_nome_jogador(b)
	]



func _indice_fase(fase: String) -> int:
	for i in range(FASES_ORDEM.size()):
		if FASES_ORDEM[i] == fase:
			return i
	return 0


# ============================================================
# FASE INICIAL — ENQUADRADA
# ============================================================

func _render_chaveamento_afunilado_inicial(parent: Control, area: Rect2) -> void:
	var ax: float = area.position.x
	var ay: float = area.position.y
	var aw: float = area.size.x
	var ah: float = area.size.y

	var centro_w: float = 70.0
	var lado_w: float = (aw - centro_w) / 2.0
	var col_gap: float = 12.0
	var col_w: float = (lado_w - col_gap * 2.0) / 3.0

	var lx_grupos: float = ax
	var lx_play: float = ax + col_w + col_gap
	var lx_oit: float = ax + (col_w + col_gap) * 2.0

	var rx_oit: float = ax + lado_w + centro_w
	var rx_play: float = rx_oit + col_w + col_gap
	var rx_grupos: float = rx_oit + (col_w + col_gap) * 2.0

	var centro_x: float = ax + lado_w + centro_w * 0.5

	var header_h: float = 24.0
	var top0: float = ay + header_h
	var h0: float = ah - header_h

	var play_esq: Array = _partidas_por_lado_e_grupos(FASE_PLAYIN, ["A", "B", "C", "D", "E", "F"])
	var play_dir: Array = _partidas_por_lado_e_grupos(FASE_PLAYIN, ["G", "H", "I", "J", "K", "L"])
	var oit_esq: Array = _partidas_por_lado_e_grupos(FASE_OITAVAS, ["A", "B", "C", "D", "E", "F"])
	var oit_dir: Array = _partidas_por_lado_e_grupos(FASE_OITAVAS, ["G", "H", "I", "J", "K", "L"])

	var ge_rects: Array = _coluna_rects(lx_grupos, top0, col_w, h0, 6, 8.0)
	var gd_rects: Array = _coluna_rects(rx_grupos, top0, col_w, h0, 6, 8.0)
	var pe_rects: Array = _coluna_rects(lx_play, top0, col_w, h0, maxi(play_esq.size(), 3), 8.0)
	var pd_rects: Array = _coluna_rects(rx_play, top0, col_w, h0, maxi(play_dir.size(), 3), 8.0)
	var oe_rects: Array = _coluna_rects(lx_oit, top0, col_w, h0, maxi(oit_esq.size(), 2), 8.0)
	var od_rects: Array = _coluna_rects(rx_oit, top0, col_w, h0, maxi(oit_dir.size(), 2), 8.0)

	var centro_ponto: Vector2 = Vector2(centro_x, top0 + h0 * 0.5)

	_conectar_colunas(parent, _bordas_dir(ge_rects), _bordas_esq(pe_rects), _cor_conector_fase(FASE_GRUPOS))
	_conectar_colunas(parent, _bordas_dir(pe_rects), _bordas_esq(oe_rects), _cor_conector_fase(FASE_PLAYIN))
	_conectar_para_ponto(parent, _bordas_dir(oe_rects), centro_ponto, _cor_conector_fase(FASE_OITAVAS))
	_conectar_colunas(parent, _bordas_esq(gd_rects), _bordas_dir(pd_rects), _cor_conector_fase(FASE_GRUPOS))
	_conectar_colunas(parent, _bordas_esq(pd_rects), _bordas_dir(od_rects), _cor_conector_fase(FASE_PLAYIN))
	_conectar_para_ponto(parent, _bordas_esq(od_rects), centro_ponto, _cor_conector_fase(FASE_OITAVAS))

	for i in range(6):
		_render_grupo_box(parent, ge_rects[i], i)
		_render_grupo_box(parent, gd_rects[i], i + 6)
	_render_coluna_cards(parent, pe_rects, play_esq, "16AV")
	_render_coluna_cards(parent, pd_rects, play_dir, "16AV")
	_render_coluna_cards(parent, oe_rects, oit_esq, "OIT")
	_render_coluna_cards(parent, od_rects, oit_dir, "OIT")

	_header_coluna(parent, lx_grupos, ay, col_w, "CHAVES A-F")
	_header_coluna(parent, lx_play, ay, col_w, "16 AVOS")
	_header_coluna(parent, lx_oit, ay, col_w, "OITAVAS")
	_header_coluna(parent, rx_oit, ay, col_w, "OITAVAS")
	_header_coluna(parent, rx_play, ay, col_w, "16 AVOS")
	_header_coluna(parent, rx_grupos, ay, col_w, "CHAVES G-L")
	_spine_central(parent, centro_x, top0, h0)



func _render_lado_inicial_torment(parent: Control, rect: Rect2, titulo_txt: String, nomes: Array, esquerda: bool) -> void:
	var painel := Panel.new()
	painel.position = rect.position
	painel.size = rect.size
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.clip_contents = true
	painel.add_theme_stylebox_override(
		"panel",
		_style_panel_torment(COR_TORMENT, Color(0.010, 0.012, 0.022, 0.78), 0.10, 18, 2)
	)
	parent.add_child(painel)

	var titulo := _label(titulo_txt, 14, Color.WHITE, COR_TORMENT)
	titulo.position = Vector2(12, 6)
	titulo.size = Vector2(painel.size.x - 24, 24)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	painel.add_child(titulo)

	var padding: float = 10.0
	var top: float = 38.0
	var col_gap: float = 10.0
	var col_w: float = (painel.size.x - padding * 2.0 - col_gap * 2.0) / 3.0
	var col_h: float = painel.size.y - top - padding

	var x_grupo: float
	var x_play: float
	var x_oit: float

	if esquerda:
		x_grupo = padding
		x_play = padding + col_w + col_gap
		x_oit = padding + (col_w + col_gap) * 2.0
	else:
		x_oit = padding
		x_play = padding + col_w + col_gap
		x_grupo = padding + (col_w + col_gap) * 2.0

	_render_coluna_torment(painel, Rect2(Vector2(x_grupo, top), Vector2(col_w, col_h)), "PRIMEIRA", "grupos", nomes)
	_render_coluna_torment(painel, Rect2(Vector2(x_play, top), Vector2(col_w, col_h)), "SEGUNDA", FASE_PLAYIN, nomes)
	_render_coluna_torment(painel, Rect2(Vector2(x_oit, top), Vector2(col_w, col_h)), "OITAVAS", FASE_OITAVAS, nomes)


func _render_coluna_torment(parent: Control, rect: Rect2, titulo_txt: String, tipo: String, nomes: Array) -> void:
	var col := Panel.new()
	col.position = rect.position
	col.size = rect.size
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.clip_contents = true
	col.add_theme_stylebox_override(
		"panel",
		_style_panel_torment(Color(0.26, 0.28, 0.38), Color(0.006, 0.008, 0.016, 0.62), 0.02, 14, 1)
	)
	parent.add_child(col)

	var header := _label(titulo_txt, 11, COR_TEXTO_SUAVE, Color.BLACK)
	header.position = Vector2(5, 4)
	header.size = Vector2(col.size.x - 10, 20)
	header.clip_text = true
	col.add_child(header)

	var list_y: float = 28.0
	var list_h: float = col.size.y - list_y - 6.0

	if tipo == "grupos":
		var qtd: int = nomes.size()
		var gap: float = 5.0
		var card_h: float = (list_h - gap * float(qtd - 1)) / float(qtd)

		for i in range(qtd):
			var r := Rect2(Vector2(6, list_y + float(i) * (card_h + gap)), Vector2(col.size.x - 12, card_h))
			_render_card_grupo_compacto(col, r, str(nomes[i]))

		return

	var lista: Array = _partidas_por_lado_e_grupos(tipo, nomes)

	if lista.is_empty():
		var aguardando := _label("AGUARDANDO", 12, Color(0.54, 0.58, 0.66))
		aguardando.position = Vector2(6, list_y)
		aguardando.size = Vector2(col.size.x - 12, 42)
		col.add_child(aguardando)
		return

	var qtd_mata: int = lista.size()
	var gap_mata: float = 6.0
	var card_h_mata: float = clampf(
		(list_h - gap_mata * float(qtd_mata - 1)) / float(qtd_mata),
		48.0,
		78.0
	)

	for i in range(qtd_mata):
		var y: float = list_y + float(i) * (card_h_mata + gap_mata)
		var r_mata := Rect2(Vector2(6, y), Vector2(col.size.x - 12, card_h_mata))
		_render_card_mata_tv(col, r_mata, _as_dict(lista[i]), "%02d" % [i + 1])


# ============================================================
# PLAYOFFS — COMPACTO E CENTRALIZADO
# ============================================================
func _render_chaveamento_afunilado_playoffs(parent: Control, area: Rect2) -> void:
	var ax: float = area.position.x
	var ay: float = area.position.y
	var aw: float = area.size.x
	var ah: float = area.size.y

	var quartas: Array = _as_array(partidas.get(FASE_QUARTAS, []))
	var semis: Array = _as_array(partidas.get(FASE_SEMIS, []))
	var finais: Array = _as_array(partidas.get(FASE_FINAL, []))
	var terceiro: Array = _as_array(partidas.get(FASE_3LUGAR, []))

	var gap: float = clampf(aw * 0.012, 8.0, 16.0)
	var final_w: float = aw * 0.20
	var col_w: float = (aw - final_w - gap * 4.0) / 4.0

	if col_w < 120.0:
		final_w = aw * 0.18
		col_w = (aw - final_w - gap * 4.0) / 4.0

	var header_h: float = 26.0
	var top: float = ay + header_h
	var h: float = ah - header_h

	var lx_qf: float = ax
	var lx_sf: float = lx_qf + col_w + gap
	var x_final: float = lx_sf + col_w + gap
	var rx_sf: float = x_final + final_w + gap
	var rx_qf: float = rx_sf + col_w + gap

	var qf_h: float = (h - 18.0) / 2.0
	qf_h = clampf(qf_h, 105.0, 170.0)
	var qf_gap: float = h - qf_h * 2.0
	qf_gap = maxf(qf_gap, 10.0)

	var qf1: Rect2 = Rect2(Vector2(lx_qf, top), Vector2(col_w, qf_h))
	var qf2: Rect2 = Rect2(Vector2(lx_qf, top + qf_h + qf_gap), Vector2(col_w, qf_h))
	var qf3: Rect2 = Rect2(Vector2(rx_qf, top), Vector2(col_w, qf_h))
	var qf4: Rect2 = Rect2(Vector2(rx_qf, top + qf_h + qf_gap), Vector2(col_w, qf_h))

	var sf_h: float = clampf(h * 0.42, 125.0, 190.0)
	var sf1: Rect2 = Rect2(Vector2(lx_sf, top + (h - sf_h) * 0.5), Vector2(col_w, sf_h))
	var sf2: Rect2 = Rect2(Vector2(rx_sf, top + (h - sf_h) * 0.5), Vector2(col_w, sf_h))

	# Bloco central: FINAL em cima + 3º LUGAR logo abaixo.
	var f_h: float = clampf(h * 0.40, 150.0, 205.0)
	var r3_h: float = clampf(h * 0.24, 88.0, 134.0)
	var entre: float = 16.0
	var total_bloco: float = f_h + entre + r3_h
	var final_y: float = top + (h - total_bloco) * 0.5
	if final_y < top:
		final_y = top

	var rfinal: Rect2 = Rect2(Vector2(x_final, final_y), Vector2(final_w, f_h))
	var r3: Rect2 = Rect2(Vector2(x_final, final_y + f_h + entre), Vector2(final_w, r3_h))

	# Conectores das fases (roxo se ainda não foi; destaque se já foi).
	_neon_conector(parent, _ponto_dir(qf1), _ponto_esq(sf1), _cor_conector_fase(FASE_QUARTAS))
	_neon_conector(parent, _ponto_dir(qf2), _ponto_esq(sf1), _cor_conector_fase(FASE_QUARTAS))
	_neon_conector(parent, _ponto_dir(sf1), _ponto_esq(rfinal), _cor_conector_fase(FASE_SEMIS))

	_neon_conector(parent, _ponto_esq(qf3), _ponto_dir(sf2), _cor_conector_fase(FASE_QUARTAS))
	_neon_conector(parent, _ponto_esq(qf4), _ponto_dir(sf2), _cor_conector_fase(FASE_QUARTAS))
	_neon_conector(parent, _ponto_esq(sf2), _ponto_dir(rfinal), _cor_conector_fase(FASE_SEMIS))

	# Linhas ligando os PERDEDORES das semis ao card de 3º lugar.
	var cor_3l: Color = _cor_conector_fase(FASE_3LUGAR)
	_neon_conector(parent, Vector2(sf1.position.x + sf1.size.x, sf1.position.y + sf1.size.y - 8.0), _ponto_esq(r3), cor_3l)
	_neon_conector(parent, Vector2(sf2.position.x, sf2.position.y + sf2.size.y - 8.0), _ponto_dir(r3), cor_3l)

	_render_card_mata_tv(parent, qf1, _as_dict(quartas[0]) if quartas.size() > 0 else {}, "QUARTA 1")
	_render_card_mata_tv(parent, qf2, _as_dict(quartas[1]) if quartas.size() > 1 else {}, "QUARTA 2")
	_render_card_mata_tv(parent, qf3, _as_dict(quartas[2]) if quartas.size() > 2 else {}, "QUARTA 3")
	_render_card_mata_tv(parent, qf4, _as_dict(quartas[3]) if quartas.size() > 3 else {}, "QUARTA 4")

	_render_card_mata_tv(parent, sf1, _as_dict(semis[0]) if semis.size() > 0 else {}, "SEMI 1")
	_render_card_mata_tv(parent, sf2, _as_dict(semis[1]) if semis.size() > 1 else {}, "SEMI 2")

	_render_card_mata_tv(parent, rfinal, _as_dict(finais[0]) if finais.size() > 0 else {}, "GRANDE FINAL", true)
	_render_card_mata_tv(parent, r3, _as_dict(terceiro[0]) if terceiro.size() > 0 else {}, "DISPUTA 3º LUGAR")

	_header_coluna(parent, lx_qf, ay, col_w, "QUARTAS")
	_header_coluna(parent, lx_sf, ay, col_w, "SEMIFINAL")
	_header_coluna(parent, x_final, ay, final_w, "FINAL / 3º")
	_header_coluna(parent, rx_sf, ay, col_w, "SEMIFINAL")
	_header_coluna(parent, rx_qf, ay, col_w, "QUARTAS")



# ============================================================
# CARDS
# ============================================================
func _render_card_grupo_compacto(parent: Control, rect: Rect2, grupo_nome: String) -> void:
	var gi: int = NOMES_GRUPOS.find(grupo_nome)
	if gi < 0:
		return

	var card := Panel.new()
	card.position = rect.position
	card.size = rect.size
	card.clip_contents = true
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override(
		"panel",
		_style_panel_torment(COR_TORMENT, Color(0.014, 0.016, 0.028, 0.92), 0.08, 10, 1)
	)
	parent.add_child(card)

	var titulo := _label("CH %s" % grupo_nome, 10, Color.WHITE, COR_TORMENT)
	titulo.position = Vector2(4, 0)
	titulo.size = Vector2(card.size.x - 8, 17)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(titulo)

	var tabela: Array = _tabela_grupo(gi)

	var y: float = 17.0
	var row_h: float = maxf(13.0, (card.size.y - 18.0) / 3.0)

	for i in range(min(3, tabela.size())):
		var j: Dictionary = _as_dict(tabela[i])
		var classifica: bool = i < 2
		var cor_j: Color = _cor_jogador(j, COR_NEON)

		var nome_txt: String = "%dº %s" % [i + 1, _nome_jogador(j)]
		if _eh_bot(j):
			nome_txt += " B"

		var centro_y: float = y + row_h * 0.5

		var chip := ColorRect.new()
		chip.position = Vector2(3, centro_y - 3.0)
		chip.size = Vector2(3, 6)
		chip.color = cor_j
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(chip)

		var pts_w: float = 28.0
		var nome_x: float = 10.0
		var nome_w: float = maxf(card.size.x - nome_x - pts_w - 5.0, 24.0)

		var texto_h: float = row_h + 3.0
		var texto_y: float = centro_y - texto_h * 0.5 - 1.0

		var lbl := _label(nome_txt, 9, Color.WHITE if classifica else Color(0.62, 0.64, 0.70), Color.BLACK)
		lbl.position = Vector2(nome_x, texto_y)
		lbl.size = Vector2(nome_w, texto_h)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.clip_text = true
		lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		card.add_child(lbl)

		var gols_valor: int = int(j.get("gols_total", j.get("gols_grupo", j.get("pontos_grupo", 0))))

		var pts := _label(str(gols_valor), 9, COR_ALERTA if classifica else COR_TEXTO_SUAVE)
		pts.position = Vector2(card.size.x - pts_w - 4.0, texto_y)
		pts.size = Vector2(pts_w, texto_h)
		pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pts.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card.add_child(pts)

		y += row_h


func _render_card_mata_tv(parent: Control, rect: Rect2, p: Dictionary, titulo_txt: String = "", eh_final: bool = false) -> void:
	var vazia: bool = p.is_empty()
	var finalizada: bool = not vazia and bool(p.get("finalizada", false))
	var proxima: bool = not vazia and _eh_card_da_proxima_partida(p)

	var fase_card: String = str(p.get("fase", fase_atual))
	var tema_mata_moderno: bool = fase_card != FASE_GRUPOS

	var cor: Color = Color(0.30, 0.34, 0.46)
	var bg: Color = Color(0.010, 0.014, 0.030, 0.94)
	var brilho: float = 0.04

	if vazia:
		cor = Color(0.24, 0.27, 0.36)
		bg = Color(0.006, 0.010, 0.022, 0.88)
		brilho = 0.02

	elif proxima:
		if tema_mata_moderno:
			# De 16 avos em diante, o card ativo não usa mais amarelo/marrom.
			# Fica ciano/roxo para não confundir com player amarelo.
			cor = COR_CARD_ATIVO_MODERNO
			bg = COR_CARD_FUNDO_ATIVO
			brilho = 0.50
		else:
			cor = COR_ALERTA
			bg = Color(0.050, 0.038, 0.012, 0.96)
			brilho = 0.30

	elif finalizada:
		cor = _cor_caminho_partida(p)

		if tema_mata_moderno:
			# Fundo neutro sofisticado. A cor do vencedor fica só na borda/detalhe.
			bg = COR_CARD_FUNDO_FINALIZADO
			brilho = 0.24
		else:
			bg = Color(cor.r * 0.045, cor.g * 0.045, cor.b * 0.045, 0.96)
			brilho = 0.16

	else:
		if tema_mata_moderno:
			cor = COR_TORMENT_2
			bg = COR_CARD_FUNDO_MATA
			brilho = 0.18
		else:
			cor = COR_TORMENT
			bg = Color(0.026, 0.010, 0.040, 0.95)
			brilho = 0.14

	if eh_final:
		cor = _cor_caminho_partida(p) if finalizada else COR_CARD_ATIVO_MODERNO
		bg = COR_CARD_FUNDO_FINAL
		brilho = 0.46

	var card: Panel = Panel.new()
	card.position = rect.position
	card.size = rect.size
	card.clip_contents = true
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _style_card_mata_neon(cor, bg, brilho))
	parent.add_child(card)

	if tema_mata_moderno:
		_decorar_card_mata_moderno(card, cor, proxima, finalizada, eh_final)
	
	
	var W: float = card.size.x
	var H: float = card.size.y

	var titulo_h: float = clampf(H * 0.22, 22.0, 36.0)
	var fs_titulo: int = int(clampf(H * 0.115, 10.0, 17.0))

	var titulo_final: String = titulo_txt
	if proxima:
		var etapa_now: String = _etapa_card_proxima(p)
		titulo_final = "▶ %s • %s" % [titulo_txt, etapa_now]

	var titulo: Label = _label(titulo_final, fs_titulo, Color.WHITE, cor)
	titulo.position = Vector2(7.0, 2.0)
	titulo.size = Vector2(W - 14.0, titulo_h)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo.clip_text = true
	card.add_child(titulo)

	if vazia:
		var vazio: Label = _label("AGUARDANDO", int(clampf(H * 0.12, 10.0, 16.0)), Color(0.55, 0.58, 0.66))
		vazio.position = Vector2(6.0, H * 0.5 - 13.0)
		vazio.size = Vector2(W - 12.0, 26.0)
		vazio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vazio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card.add_child(vazio)
		return

	var a: Dictionary = _as_dict(p.get("a", {}))
	var b: Dictionary = _as_dict(p.get("b", {}))
	var cor_a: Color = _cor_jogador(a, COR_NEON)
	var cor_b: Color = _cor_jogador(b, COR_TORMENT)

	var ida: Dictionary = _as_dict(p.get("ida", {}))
	var volta: Dictionary = _as_dict(p.get("volta", {}))
	var pen: Dictionary = _as_dict(p.get("penaltis", {}))

	var ida_final: bool = bool(ida.get("finalizada", false))
	var volta_final: bool = bool(volta.get("finalizada", false))

	var ida_a: int = int(ida.get("a", -1))
	var ida_b: int = int(ida.get("b", -1))
	var volta_a: int = int(volta.get("a", -1))
	var volta_b: int = int(volta.get("b", -1))

	var agg_a: int = int(p.get("agregado_a", 0))
	var agg_b: int = int(p.get("agregado_b", 0))

	if ida_final and volta_final:
		agg_a = int(ida.get("a", 0)) + int(volta.get("a", 0))
		agg_b = int(ida.get("b", 0)) + int(volta.get("b", 0))

	var placar_y: float = titulo_h + 2.0
	var linha_h: float = 18.0

	_add_placar_mata_linha(
		card,
		placar_y,
		W,
		"IDA",
		_score_txt(ida_a),
		_score_txt(ida_b),
		cor_a,
		cor_b,
		proxima and _etapa_card_proxima(p) == "IDA"
	)

	_add_placar_mata_linha(
		card,
		placar_y + linha_h,
		W,
		"VOLTA",
		_score_txt(volta_a),
		_score_txt(volta_b),
		cor_a,
		cor_b,
		proxima and _etapa_card_proxima(p) == "VOLTA"
	)

	_add_placar_mata_linha(
		card,
		placar_y + linha_h * 2.0,
		W,
		"AGREGADO",
		str(agg_a) if ida_final and volta_final else "—",
		str(agg_b) if ida_final and volta_final else "—",
		cor_a,
		cor_b,
		false
	)

	var pen_y: float = placar_y + linha_h * 3.0
	var extra_txt: String = ""

	if bool(p.get("aguardando_penaltis", false)):
		extra_txt = "AGUARDANDO PÊNALTIS"

	if bool(pen.get("finalizada", false)):
		extra_txt = "PÊNALTIS %dx%d" % [
			int(pen.get("a", 0)),
			int(pen.get("b", 0))
		]

	if extra_txt != "":
		var extra: Label = _label_num(extra_txt, 9, COR_ALERTA, COR_ALERTA)
		extra.position = Vector2(6.0, pen_y)
		extra.size = Vector2(W - 12.0, 17.0)
		extra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		extra.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		extra.clip_text = true
		card.add_child(extra)
		pen_y += 17.0

	var players_y: float = pen_y + 3.0
	var bottom_pad: float = 9.0
	var linha_gap: float = 4.0
	var player_h: float = maxf(16.0, (H - players_y - bottom_pad - linha_gap) / 2.0)

	_adicionar_linha_jogador_mata(card, a, p, "a", Vector2(6.0, players_y), Vector2(W - 12.0, player_h), finalizada)
	_adicionar_linha_jogador_mata(card, b, p, "b", Vector2(6.0, players_y + player_h + linha_gap), Vector2(W - 12.0, player_h), finalizada)


func _adicionar_linha_jogador_mata(card: Panel, jogador: Dictionary, p: Dictionary, lado: String, pos: Vector2, tam: Vector2, finalizada: bool) -> void:
	var vencedor_lado: String = str(p.get("vencedor_lado", ""))
	var venceu: bool = finalizada and vencedor_lado == lado
	var perdeu: bool = finalizada and vencedor_lado != "" and vencedor_lado != lado
	var cor_j: Color = _cor_jogador(jogador, COR_NEON)

	var nome_txt: String = _nome_jogador(jogador)
	if _eh_bot(jogador):
		nome_txt += " BOT"

	var fs: int = int(clampf(tam.y * 0.42, 10.0, 17.0))

	if nome_txt.length() > 18:
		fs = int(maxi(fs - 1, 9))

	if nome_txt.length() > 24:
		fs = int(maxi(fs - 2, 8))

	var bg: ColorRect = ColorRect.new()
	bg.position = pos
	bg.size = tam
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.color = Color(cor_j.r, cor_j.g, cor_j.b, 0.16 if venceu else 0.055)

	if perdeu:
		bg.color = Color(0, 0, 0, 0.26)

	card.add_child(bg)

	var cor_nome: Color = Color.WHITE
	if perdeu:
		cor_nome = Color(0.48, 0.50, 0.56)
	elif _eh_bot(jogador):
		cor_nome = COR_BOOT

	var chip: ColorRect = ColorRect.new()
	chip.position = Vector2(pos.x + 5.0, pos.y + tam.y * 0.5 - 5.0)
	chip.size = Vector2(5.0, 10.0)
	chip.color = cor_j if not perdeu else Color(0.32, 0.34, 0.38)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(chip)

	var check_w: float = 22.0 if venceu else 4.0

	var lbl: Label = _label(nome_txt, fs, cor_nome, Color.BLACK)
	lbl.position = Vector2(pos.x + 15.0, pos.y)
	lbl.size = Vector2(tam.x - 19.0 - check_w, tam.y)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.clip_text = true
	card.add_child(lbl)

	if venceu:
		var ok: Label = _label("✓", fs + 2, COR_OK, COR_OK)
		ok.position = Vector2(pos.x + tam.x - 22.0, pos.y)
		ok.size = Vector2(18.0, tam.y)
		ok.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ok.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card.add_child(ok)


func _texto_partida_mata(p: Dictionary) -> String:
	var ida: Dictionary = _as_dict(p.get("ida", {}))
	var volta: Dictionary = _as_dict(p.get("volta", {}))
	var pen: Dictionary = _as_dict(p.get("penaltis", {}))

	if not bool(ida.get("finalizada", false)):
		return "AGUARDANDO IDA"

	if bool(ida.get("finalizada", false)) and not bool(volta.get("finalizada", false)):
		return "IDA %dx%d" % [
			int(ida.get("a", 0)),
			int(ida.get("b", 0))
		]

	var ida_a: int = int(ida.get("a", 0))
	var ida_b: int = int(ida.get("b", 0))
	var volta_a: int = int(volta.get("a", 0))
	var volta_b: int = int(volta.get("b", 0))
	var agg_a: int = int(p.get("agregado_a", ida_a + volta_a))
	var agg_b: int = int(p.get("agregado_b", ida_b + volta_b))

	var texto: String = "I %dx%d  V %dx%d  A %dx%d" % [
		ida_a,
		ida_b,
		volta_a,
		volta_b,
		agg_a,
		agg_b
	]

	if bool(p.get("aguardando_penaltis", false)):
		texto += "  PÊN"

	if bool(pen.get("finalizada", false)):
		texto += "  P %dx%d" % [
			int(pen.get("a", 0)),
			int(pen.get("b", 0))
		]

	return texto


func _partidas_por_lado_e_grupos(fase: String, nomes: Array) -> Array:
	var resultado: Array = []

	if not partidas.has(fase):
		return resultado

	var lado_alvo: String = ""
	if nomes.size() > 0:
		lado_alvo = _lado_grupo(str(nomes[0]))

	var lista: Array = _as_array(partidas[fase])

	for item in lista:
		var p: Dictionary = _as_dict(item)
		var lado_chave: String = str(p.get("lado_chave", ""))

		if not lado_chave.is_empty():
			if lado_chave == lado_alvo:
				resultado.append(p)
			continue

		var a: Dictionary = _as_dict(p.get("a", {}))
		var b: Dictionary = _as_dict(p.get("b", {}))

		var grupo_a: String = str(a.get("grupo_nome", ""))
		var grupo_b: String = str(b.get("grupo_nome", ""))

		if nomes.has(grupo_a) or nomes.has(grupo_b):
			resultado.append(p)

	return resultado


func _cor_caminho_partida(p: Dictionary) -> Color:
	if p.is_empty():
		return Color(0.30, 0.32, 0.42)

	if bool(p.get("finalizada", false)):
		return _cor_jogador(_as_dict(p.get("vencedor", {})), COR_OK)

	var a: Dictionary = _as_dict(p.get("a", {}))
	var b: Dictionary = _as_dict(p.get("b", {}))
	var ca: Color = _cor_jogador(a, COR_TORMENT)
	var cb: Color = _cor_jogador(b, COR_NEON)

	return Color(
		(ca.r + cb.r) * 0.5,
		(ca.g + cb.g) * 0.5,
		(ca.b + cb.b) * 0.5,
		1.0
	)


# ============================================================
# TABELA / PÓDIO
# ============================================================
func _tabela_grupo(grupo_index: int) -> Array:
	var lista: Array = _as_array(partidas.get(FASE_GRUPOS, []))

	for item in lista:
		var p: Dictionary = _as_dict(item)
		if int(p.get("grupo_index", -1)) != grupo_index:
			continue

		# 1) Grupo fechado (ida + volta): ranking agregado.
		var ranking: Array = _as_array(p.get("ranking", []))
		if not ranking.is_empty():
			var tabela: Array = []
			for jitem in ranking:
				var j: Dictionary = _jogador_com_stats(_as_dict(jitem))
				j["grupo_nome"] = NOMES_GRUPOS[grupo_index] if grupo_index >= 0 and grupo_index < NOMES_GRUPOS.size() else "?"
				tabela.append(j)
			return tabela

		# 2) Parcial: soma as pernas já finalizadas (ex.: só a ida).
		var parcial: Array = _tabela_grupo_parcial(p, grupo_index)
		if not parcial.is_empty():
			return parcial

		break

	# 3) Antes de qualquer perna: jogadores zerados.
	var tabela2: Array = []
	if grupo_index >= 0 and grupo_index < grupos.size():
		for item in _as_array(grupos[grupo_index]):
			tabela2.append(_jogador_com_stats(_as_dict(item)))
	return tabela2


func _tabela_grupo_parcial(p: Dictionary, grupo_index: int) -> Array:
	var jogadores_grupo: Array = _as_array(p.get("jogadores", []))
	if jogadores_grupo.is_empty():
		return []

	var ida: Dictionary = _as_dict(p.get("ida", {}))
	var volta: Dictionary = _as_dict(p.get("volta", {}))

	var ida_ok: bool = bool(ida.get("finalizada", false))
	var volta_ok: bool = bool(volta.get("finalizada", false))

	# Nenhuma perna finalizada: deixa cair no caso "zerado".
	if not ida_ok and not volta_ok:
		return []

	var gols_por_index: Dictionary = {}

	for item in _as_array(ida.get("ranking", [])):
		var r: Dictionary = _as_dict(item)
		var idx: int = int(r.get("player_index", -1))
		if idx < 0:
			continue
		gols_por_index[idx] = int(gols_por_index.get(idx, 0)) + int(r.get("gols", 0))

	for item in _as_array(volta.get("ranking", [])):
		var r2: Dictionary = _as_dict(item)
		var idx2: int = int(r2.get("player_index", -1))
		if idx2 < 0:
			continue
		gols_por_index[idx2] = int(gols_por_index.get(idx2, 0)) + int(r2.get("gols", 0))

	var grupo_nome: String = NOMES_GRUPOS[grupo_index] if grupo_index >= 0 and grupo_index < NOMES_GRUPOS.size() else "?"

	var tabela: Array = []

	for i in range(jogadores_grupo.size()):
		var base: Dictionary = _jogador_com_stats(_as_dict(jogadores_grupo[i]))
		var g: int = int(gols_por_index.get(i, 0))

		base["player_index"] = i
		base["gols_grupo"] = g
		base["gols_total"] = g
		base["gols"] = g
		base["score"] = g
		base["grupo_nome"] = grupo_nome
		base["parcial"] = true

		tabela.append(base)

	tabela.sort_custom(func(a: Variant, b: Variant) -> bool:
		var ja: Dictionary = _as_dict(a)
		var jb: Dictionary = _as_dict(b)

		var ga: int = int(ja.get("gols_grupo", 0))
		var gb: int = int(jb.get("gols_grupo", 0))

		if ga != gb:
			return ga > gb

		var ba: bool = _eh_bot(ja)
		var bb: bool = _eh_bot(jb)

		if ba != bb:
			return not ba

		return _seed(ja) < _seed(jb)
	)

	for pos in range(tabela.size()):
		var jg: Dictionary = _as_dict(tabela[pos])
		jg["posicao"] = pos + 1
		jg["pos_grupo"] = pos + 1
		jg["classificado"] = pos < 2
		tabela[pos] = jg

	return tabela



func _render_podio_final(parent: Control, area: Rect2) -> void:
	var painel := Panel.new()
	painel.position = area.position
	painel.size = area.size
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.clip_contents = true
	painel.add_theme_stylebox_override(
		"panel",
			_style_panel_torment(COR_TORMENT, Color(0.006, 0.010, 0.030, 0.94), 0.36, 20, 2)
	)
	parent.add_child(painel)
	
	_decorar_fundo_podio_torment(painel)
	
	_tocar_good_player_podio()
	_iniciar_confetes_podio(painel)

	var titulo := _label("PÓDIO TORMENT ARENA", 30, Color.WHITE, COR_TORMENT)
	titulo.position = Vector2(0, 18)
	titulo.size = Vector2(painel.size.x, 48)
	painel.add_child(titulo)

	if top3_final.size() < 3:
		var erro := _label("Top 3 ainda não foi formado.", 20, Color.WHITE)
		erro.position = Vector2(20, 90)
		erro.size = Vector2(painel.size.x - 40, 50)
		painel.add_child(erro)
		return
	
	_salvar_torneio_no_mural()

	var gap: float = 24.0
	var margem: float = 58.0
	var top: float = 100.0
	var w: float = (painel.size.x - margem * 2.0 - gap * 2.0) / 3.0
	var h_base: float = painel.size.y - top - 28.0

	_criar_pedestal_torment(painel, _as_dict(top3_final[1]), 2, Vector2(margem, top + 48), Vector2(w, h_base - 48), COR_PRATA, "VICE")
	_criar_pedestal_torment(painel, _as_dict(top3_final[0]), 1, Vector2(margem + w + gap, top), Vector2(w, h_base), COR_ALERTA, "CAMPEÃO")
	_criar_pedestal_torment(painel, _as_dict(top3_final[2]), 3, Vector2(margem + (w + gap) * 2.0, top + 78), Vector2(w, h_base - 78), COR_BRONZE, "3º LUGAR")
	
	
	var cor_campeao: Color = _cor_jogador(_as_dict(top3_final[0]), COR_ALERTA)
	_chuva_fitas_campeao(painel, cor_campeao)
	_render_barra_hold_podio(painel, cor_campeao)


func _criar_pedestal_torment(parent: Control, jogador: Dictionary, posicao: int, pos: Vector2, tam: Vector2, cor_metal: Color, titulo_txt: String) -> void:
	var cor_j: Color = _cor_jogador(jogador, cor_metal)
	
	var fundo_pedestal: Color = _fundo_pedestal_torment(posicao)

	var ped := Panel.new()
	ped.position = pos
	ped.size = tam
	ped.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ped.clip_contents = true
	ped.add_theme_stylebox_override(
		"panel",
				_style_panel_torment(cor_metal, fundo_pedestal, 0.38, 18, 2)
	)
	parent.add_child(ped)

	_decorar_pedestal_torment(ped, cor_metal, posicao)

	var num := _label("%dº" % posicao, 48, Color.WHITE, cor_metal)
	num.position = Vector2(0, 8)
	num.size = Vector2(tam.x, 58)
	ped.add_child(num)

	var titulo := _label(titulo_txt, 17, cor_metal, cor_metal)
	titulo.position = Vector2(12, 70)
	titulo.size = Vector2(tam.x - 24, 30)
	ped.add_child(titulo)

	var nome := _label(_nome_jogador(jogador), 24, Color.WHITE, cor_j)
	nome.position = Vector2(16, 112)
	nome.size = Vector2(tam.x - 32, 44)
	nome.clip_text = true
	ped.add_child(nome)

	var stats_txt := "GOLS %d\nJOGOS %d\nVITÓRIAS %d\nPÊNALTIS %d\nPONTOS %d" % [
		int(jogador.get("gols_total", 0)),
		int(jogador.get("jogos_total", 0)),
		int(jogador.get("vitorias_total", 0)),
		int(jogador.get("penaltis_total", 0)),
		int(jogador.get("pontos_grupo", 0))
	]

	var stats := _label(stats_txt, 15, COR_TEXTO_SUAVE)
	stats.position = Vector2(18, 164)
	stats.size = Vector2(tam.x - 36, tam.y - 174)
	ped.add_child(stats)


# ============================================================
# AVISO DE CLASSIFICADO
# ============================================================

func _acao_existe(nome: String) -> bool:
	return InputMap.has_action(nome)


func _atualizar_hold_cup(delta: float) -> void:
	if _instrucoes_abertas:
		return
	if not _acao_existe("input_cup"):
		return

	if Input.is_action_pressed("input_cup"):
		_cup_hold_tempo += delta
		if _cup_hold_tempo >= CUP_HOLD_ABRIR:
			_cup_hold_tempo = 0.0
			_abrir_instrucoes_torneio()
	else:
		_cup_hold_tempo = 0.0


func _fechar_instrucoes_torneio() -> void:
	_instrucoes_abertas = false
	_cup_hold_tempo = 0.0
	if is_instance_valid(_instrucoes_overlay):
		_instrucoes_overlay.queue_free()
	_instrucoes_overlay = null


func _abrir_instrucoes_torneio() -> void:
	if _instrucoes_abertas:
		return
	if not is_instance_valid(canvas):
		return

	_instrucoes_abertas = true

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(overlay)
	_instrucoes_overlay = overlay

	var tela: Vector2 = get_viewport_rect().size
	overlay.size = tela

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.004, 0.006, 0.012, 0.95)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(bg)

	var margem: float = 46.0
	var painel := Panel.new()
	painel.position = Vector2(margem, margem)
	painel.size = Vector2(tela.x - margem * 2.0, tela.y - margem * 2.0)
	painel.clip_contents = true
	painel.mouse_filter = Control.MOUSE_FILTER_STOP
	painel.add_theme_stylebox_override(
		"panel",
		_style_panel_torment(COR_TORMENT, Color(0.010, 0.012, 0.024, 0.98), 0.30, 22, 2)
	)
	overlay.add_child(painel)

	var W: float = painel.size.x
	var H: float = painel.size.y

	var titulo := _label("REGULAMENTO • TORMENT ARENA 36", 30, Color.WHITE, COR_TORMENT)
	titulo.position = Vector2(28, 18)
	titulo.size = Vector2(W - 56, 44)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	painel.add_child(titulo)

	var sub := _label("36 JOGADORES • FORMATO COPA DO BRASIL • OS MELHORES PEGAM BYE PARA AS OITAVAS", 14, COR_TEXTO_SUAVE)
	sub.position = Vector2(28, 60)
	sub.size = Vector2(W - 56, 24)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	painel.add_child(sub)

	var fases_info: Array = [
		["1ª FASE • GRUPOS", COR_TORMENT,
			"12 grupos de 3 jogadores.\nCada grupo joga IDA e VOLTA.\nSoma os gols das 2 pernas.\nOs 2 melhores avançam (24 no total)."],
		["CLASSIFICAÇÃO • BYE", COR_ALERTA,
			"Os 4 melhores de CADA LADO (A-F / G-L)\nvão DIRETO para as OITAVAS (bye).\n8 no total. Os outros 16 caem na 2ª fase."],
		["SEGUNDA FASE • 16→8", COR_NEON,
			"16 jogadores, dentro do próprio lado.\nIda e volta, gols agregados.\nEmpate no agregado vai para os pênaltis.\n8 vencedores sobem para as oitavas."],
		["OITAVAS", COR_TORMENT_2,
			"8 do bye + 8 vencedores = 16.\n8 confrontos, ida e volta + pênaltis.\nAfunila esquerda (A-F) x direita (G-L)."],
		["QUARTAS", COR_NEON,
			"8 → 4. Cruzamento esquerda x direita.\nIda e volta, agregado, pênaltis no empate."],
		["SEMIFINAL", COR_TORMENT,
			"4 → 2. Quem vence vai para a final.\nOs perdedores disputam o 3º lugar."],
		["FINAL", COR_ALERTA,
			"2 → 1. Ida e volta pelo título.\nO campeão fecha o pódio TORMENT."],
		["PÊNALTIS", COR_OK,
			"Só acontecem entre players reais.\nSe tiver pelo menos 1 player real,\na partida abre normalmente contra o boot."]
	]

	var cols: int = 2
	var col_gap: float = 16.0
	var row_gap: float = 12.0
	var top: float = 96.0
	var rodape: float = 52.0
	var grid_w: float = W - 56.0
	var grid_h: float = H - top - rodape
	var card_w: float = (grid_w - col_gap * float(cols - 1)) / float(cols)
	var linhas: int = int(ceil(float(fases_info.size()) / float(cols)))
	var card_h: float = (grid_h - row_gap * float(linhas - 1)) / float(linhas)

	for i in range(fases_info.size()):
		var info: Array = _as_array(fases_info[i])
		var col: int = i % cols
		var lin: int = int(i / cols)
		var x: float = 28.0 + float(col) * (card_w + col_gap)
		var y: float = top + float(lin) * (card_h + row_gap)
		_render_card_instrucao(painel, Rect2(Vector2(x, y), Vector2(card_w, card_h)), str(info[0]), info[1], str(info[2]))

	var rodape_lbl := _label("SEGURE O CUP PARA ABRIR  •  APERTE START PARA VOLTAR", 16, COR_ALERTA, COR_ALERTA)
	rodape_lbl.position = Vector2(28, H - rodape + 10.0)
	rodape_lbl.size = Vector2(W - 56, 30)
	painel.add_child(rodape_lbl)


func _render_card_instrucao(parent: Control, rect: Rect2, titulo_txt: String, cor: Color, corpo: String) -> void:
	var card := Panel.new()
	card.position = rect.position
	card.size = rect.size
	card.clip_contents = true
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override(
		"panel",
		_style_panel_torment(cor, Color(cor.r * 0.05, cor.g * 0.05, cor.b * 0.05, 0.96), 0.16, 14, 2)
	)
	parent.add_child(card)

	var faixa := ColorRect.new()
	faixa.position = Vector2.ZERO
	faixa.size = Vector2(6, rect.size.y)
	faixa.color = cor
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(faixa)

	var titulo := _label(titulo_txt, 17, Color.WHITE, cor)
	titulo.position = Vector2(16, 8)
	titulo.size = Vector2(rect.size.x - 24, 26)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.add_child(titulo)

	var corpo_lbl := _label(corpo, 14, COR_TEXTO_SUAVE)
	corpo_lbl.position = Vector2(16, 38)
	corpo_lbl.size = Vector2(rect.size.x - 28, rect.size.y - 46)
	corpo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	corpo_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	corpo_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	corpo_lbl.clip_text = true
	card.add_child(corpo_lbl)



func _mostrar_aviso_classificado(parent: Node, vencedor: Dictionary, perdedor: Dictionary, fase_nome: String) -> void:
	var tela: Vector2 = get_viewport_rect().size

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(overlay)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.70)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(bg)

	var cor: Color = _cor_jogador(vencedor, COR_TORMENT)

	var card := Panel.new()
	card.size = Vector2(minf(tela.x - 80, 720), 230)
	card.position = Vector2((tela.x - card.size.x) * 0.5, (tela.y - card.size.y) * 0.5)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override(
		"panel",
		_style_panel_torment(cor, Color(0.012, 0.014, 0.026, 0.98), 0.42, 22, 2)
	)
	overlay.add_child(card)

	var t1 := _label("CLASSIFICADO", 30, Color.WHITE, cor)
	t1.position = Vector2(20, 20)
	t1.size = Vector2(card.size.x - 40, 42)
	card.add_child(t1)

	var nome := _label(_nome_jogador(vencedor), 34, Color.WHITE, Color.BLACK)
	nome.position = Vector2(20, 72)
	nome.size = Vector2(card.size.x - 40, 52)
	nome.clip_text = true
	card.add_child(nome)

	var destino_txt: String = "PASSOU PARA A FINAL"
	if not fase_nome.to_lower().contains("semi"):
		destino_txt = "PASSOU DE FASE"

	var destino := _label(destino_txt, 22, COR_TEXTO_SUAVE)
	destino.position = Vector2(20, 132)
	destino.size = Vector2(card.size.x - 40, 34)
	card.add_child(destino)

	var eliminado := _label("%s ficou pelo caminho" % _nome_jogador(perdedor), 16, Color(0.86, 0.86, 0.90))
	eliminado.position = Vector2(20, 176)
	eliminado.size = Vector2(card.size.x - 40, 30)
	eliminado.clip_text = true
	card.add_child(eliminado)

	var timer: SceneTreeTimer = get_tree().create_timer(3.0)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(overlay):
			overlay.queue_free()
	)


# ============================================================
# COMPONENTES VISUAIS
# ============================================================

func _painel(parent: Node, rect: Rect2, cor: Color, alpha: float = 0.92, radius: int = 18) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.clip_contents = true
	parent.add_child(p)

	p.add_theme_stylebox_override(
		"panel",
		_style_panel_torment(
			cor,
			Color(cor.r * 0.06, cor.g * 0.06, cor.b * 0.06, alpha),
			0.10,
			radius,
			2
		)
	)

	return p


func _style_panel_torment(
	cor_borda: Color,
	cor_fundo: Color,
	brilho: float,
	radius: int = 14,
	border: int = 1
) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = cor_fundo
	s.border_color = Color(cor_borda.r, cor_borda.g, cor_borda.b, maxf(cor_borda.a, 0.22))
	s.set_border_width_all(border)
	s.set_corner_radius_all(radius)
	s.corner_detail = 10
	s.anti_aliasing = true
	s.anti_aliasing_size = 1.0
	s.shadow_color = Color(cor_borda.r, cor_borda.g, cor_borda.b, brilho)
	s.shadow_size = 10
	s.shadow_offset = Vector2.ZERO
	return s


func _label(txt: String, tamanho: int, cor: Color = Color.WHITE, outline: Color = Color.BLACK) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl.clip_text = true
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if fonte_principal != null:
		lbl.add_theme_font_override("font", fonte_principal)

	lbl.add_theme_font_size_override("font_size", tamanho)
	lbl.add_theme_color_override("font_color", cor)
	lbl.add_theme_color_override("font_outline_color", outline)
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.add_theme_constant_override("line_spacing", 1)

	return lbl

func _label_num(txt: String, tamanho: int, cor: Color = Color.WHITE, outline: Color = Color.BLACK) -> Label:
	# Igual ao _label, porém SEM a fonte Orbitron: usa a fonte padrão da
	# engine para os números de placar (fica mais limpo e legível).
	var lbl := Label.new()
	lbl.text = txt
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl.clip_text = true
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", tamanho)
	lbl.add_theme_color_override("font_color", cor)
	lbl.add_theme_color_override("font_outline_color", outline)
	lbl.add_theme_constant_override("outline_size", 3)
	return lbl



func _criar_botao(parent: Node, rect: Rect2, texto: String, cor: Color, callback: Callable) -> Button:
	var b := Button.new()
	b.position = rect.position
	b.size = rect.size
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(b)

	if fonte_principal != null:
		b.add_theme_font_override("font", fonte_principal)

	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)

	b.add_theme_stylebox_override("normal", _style_botao(cor, 0.12))
	b.add_theme_stylebox_override("hover", _style_botao(cor.lightened(0.12), 0.26))
	b.add_theme_stylebox_override("pressed", _style_botao(cor, 0.34))
	b.add_theme_stylebox_override("focus", _style_botao(cor, 0.18))

	b.pressed.connect(callback)
	return b


func _style_botao(cor: Color, brilho: float) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(cor.r * 0.16, cor.g * 0.16, cor.b * 0.16, 0.94)
	st.border_color = Color(cor.r, cor.g, cor.b, 0.84)
	st.set_border_width_all(1)
	st.set_corner_radius_all(11)
	st.corner_detail = 8
	st.shadow_color = Color(cor.r, cor.g, cor.b, brilho)
	st.shadow_size = 8
	st.shadow_offset = Vector2.ZERO
	return st


func _style_chip(cor: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = cor
	s.border_color = Color(1, 1, 1, 0.50)
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	s.shadow_color = Color(cor.r, cor.g, cor.b, 0.28)
	s.shadow_size = 5
	s.shadow_offset = Vector2.ZERO
	return s



func _criar_audio_loading_lobby() -> void:
	if is_instance_valid(sfx_loading_resultado):
		return

	sfx_loading_resultado = AudioStreamPlayer.new()
	sfx_loading_resultado.name = "SFXLoadingResultadoTorment"
	add_child(sfx_loading_resultado)

	if ResourceLoader.exists(SFX_LOADING_RESULTADO):
		var st: AudioStream = load(SFX_LOADING_RESULTADO)
		sfx_loading_resultado.stream = st
		sfx_loading_resultado.volume_db = 1.5



func _mostrar_loading_resultados_torment(titulo_txt: String, sub_txt: String) -> void:
	if is_instance_valid(loading_result_layer):
		return

	_criar_audio_loading_lobby()

	if sfx_loading_resultado != null and sfx_loading_resultado.stream != null:
		sfx_loading_resultado.stop()
		sfx_loading_resultado.play()

	_leds_loading_resultado_on()

	loading_result_layer = CanvasLayer.new()
	loading_result_layer.layer = 900
	add_child(loading_result_layer)

	loading_result_root = Control.new()
	loading_result_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_result_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_result_layer.add_child(loading_result_root)

	var tela: Vector2 = get_viewport_rect().size

	var fundo: ColorRect = ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.004, 0.006, 0.014, 1.0)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_result_root.add_child(fundo)

	if ResourceLoader.exists(IMAGEM_LOADING_TORMENT):
		var img: TextureRect = TextureRect.new()
		img.set_anchors_preset(Control.PRESET_FULL_RECT)
		img.texture = load(IMAGEM_LOADING_TORMENT)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.modulate = Color(1, 1, 1, 0.92)
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		loading_result_root.add_child(img)

	var escuro: ColorRect = ColorRect.new()
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	escuro.color = Color(0, 0, 0, 0.58)
	escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_result_root.add_child(escuro)

	# Rodapé de patrocinadores (igual ao play). Retorna o Y do topo
	# do rodapé para encaixar a barra/status logo acima.
	var rodape_top: float = _adicionar_rodape_patrocinadores_lobby(loading_result_root)
	var base_y: float = rodape_top if rodape_top > 0.0 else tela.y - 24.0

	var topo: ColorRect = ColorRect.new()
	topo.position = Vector2.ZERO
	topo.size = Vector2(tela.x, 150.0)
	topo.color = Color(0.020, 0.006, 0.035, 0.78)
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_result_root.add_child(topo)

	var titulo: Label = _label(titulo_txt, 46, Color.WHITE, COR_TORMENT)
	titulo.position = Vector2(40.0, tela.y * 0.30)
	titulo.size = Vector2(tela.x - 80.0, 64.0)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_result_root.add_child(titulo)

	var sub: Label = _label(sub_txt, 20, COR_TEXTO_SUAVE, Color.BLACK)
	sub.position = Vector2(60.0, tela.y * 0.30 + 70.0)
	sub.size = Vector2(tela.x - 120.0, 34.0)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub.clip_text = true
	loading_result_root.add_child(sub)

	var status: Label = _label("CARREGANDO...", 26, COR_ALERTA, COR_ALERTA)
	status.position = Vector2(0, base_y - 96.0)
	status.size = Vector2(tela.x, 38.0)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_result_root.add_child(status)

	var barra_bg: ColorRect = ColorRect.new()
	barra_bg.position = Vector2(tela.x * 0.22, base_y - 50.0)
	barra_bg.size = Vector2(tela.x * 0.56, 12.0)
	barra_bg.color = Color(1, 1, 1, 0.16)
	barra_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_result_root.add_child(barra_bg)

	var barra: ColorRect = ColorRect.new()
	barra.position = barra_bg.position
	barra.size = Vector2(8.0, 12.0)
	barra.color = COR_TORMENT
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_result_root.add_child(barra)

	var brilho: ColorRect = ColorRect.new()
	brilho.position = Vector2(barra_bg.position.x, barra_bg.position.y - 5.0)
	brilho.size = Vector2(8.0, 22.0)
	brilho.color = Color(COR_TORMENT.r, COR_TORMENT.g, COR_TORMENT.b, 0.25)
	brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loading_result_root.add_child(brilho)

	loading_result_root.modulate = Color(1, 1, 1, 0)

	var entrada: Tween = create_tween()
	entrada.set_parallel(true)
	entrada.tween_property(loading_result_root, "modulate", Color(1, 1, 1, 1), 0.18)
	entrada.tween_property(barra, "size:x", barra_bg.size.x, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	entrada.tween_property(brilho, "size:x", barra_bg.size.x, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(2.4).timeout



func _remover_loading_resultados_torment() -> void:
	_leds_loading_resultado_off()

	if not is_instance_valid(loading_result_layer):
		return

	if is_instance_valid(loading_result_root):
		var t: Tween = create_tween()
		t.tween_property(loading_result_root, "modulate", Color(1, 1, 1, 0), 0.22)
		await t.finished

	if is_instance_valid(loading_result_layer):
		loading_result_layer.queue_free()

	loading_result_layer = null
	loading_result_root = null


func _serial_write_lobby(texto: String) -> void:
	if not USAR_LEDS_LOADING_LOBBY:
		return

	var cmd: String = texto.strip_edges()
	if cmd.is_empty():
		return

	if caminho_fila_arduino_lobby.is_empty():
		caminho_fila_arduino_lobby = ProjectSettings.globalize_path(ARDUINO_QUEUE_TORMENT)

	DirAccess.make_dir_recursive_absolute(caminho_fila_arduino_lobby)

	var nome_arquivo: String = "%020d_%06d.cmd" % [
		Time.get_ticks_msec(),
		randi() % 1000000
	]

	var caminho_temp: String = caminho_fila_arduino_lobby.path_join(nome_arquivo + ".tmp")
	var caminho_final: String = caminho_fila_arduino_lobby.path_join(nome_arquivo)

	var f: FileAccess = FileAccess.open(caminho_temp, FileAccess.WRITE)

	if f == null:
		return

	f.store_string(cmd)
	f.close()

	DirAccess.rename_absolute(caminho_temp, caminho_final)

func _listar_imagens_patrocinadores_lobby() -> Array[String]:
	var imagens: Array[String] = []
	for caminho in PATROCINADORES_FIXOS:
		if ResourceLoader.exists(caminho):
			if not imagens.has(caminho):
				imagens.append(caminho)
		else:
			push_warning("Patrocinador não encontrado: " + caminho)
	return imagens


func _adicionar_rodape_patrocinadores_lobby(alvo: Control) -> float:
	if alvo == null:
		return 0.0

	var imagens := _listar_imagens_patrocinadores_lobby()
	if imagens.is_empty():
		return 0.0

	var tela := get_viewport_rect().size
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
	fundo_style.border_color = Color(COR_TORMENT.r, COR_TORMENT.g, COR_TORMENT.b, 0.50)
	fundo_style.set_border_width_all(2)
	fundo_style.set_corner_radius_all(0)
	fundo_style.shadow_color = Color(COR_TORMENT.r, COR_TORMENT.g, COR_TORMENT.b, 0.40)
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
			var card := _criar_card_patrocinador_lobby(caminho, Vector2(card_w, card_h))
			card.position = Vector2(x0 + float(i) * (card_w + gap), y0)
			fundo.add_child(card)

	return footer_y


func _criar_card_patrocinador_lobby(caminho: String, tamanho: Vector2) -> Panel:
	var card := Panel.new()
	card.size = tamanho
	card.custom_minimum_size = tamanho
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.clip_contents = true

	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.02, 0.04, 0.07, 0.92)
	st.border_color = Color(COR_TORMENT.r, COR_TORMENT.g, COR_TORMENT.b, 0.70)
	st.set_border_width_all(2)
	st.set_corner_radius_all(14)
	st.shadow_color = Color(COR_TORMENT.r, COR_TORMENT.g, COR_TORMENT.b, 0.30)
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


func _leds_loading_resultado_on() -> void:
	var letras: Array[String] = ["A", "B", "C", "D", "E", "F", "G", "H"]

	var paleta: Array = [
		[180, 0, 255],   # roxo forte
		[255, 0, 220],   # magenta neon
		[110, 0, 255],   # violeta
		[0, 160, 255]    # ciano/azul neon
	]

	var partes: Array[String] = []

	for i in range(letras.size()):
		var rgb: Array = paleta[i % paleta.size()]
		partes.append("%s=%d,%d,%d" % [
			letras[i],
			int(rgb[0]),
			int(rgb[1]),
			int(rgb[2])
		])

	_serial_write_lobby("SET:" + ";".join(partes))



func _leds_loading_resultado_off() -> void:
	_serial_write_lobby("OFF")


func _matar_pontes_powershell_lobby() -> void:
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


func _fechar_ponte_leds_lobby() -> void:
	if not USAR_LEDS_LOADING_LOBBY:
		return

	_leds_idle_ativo = false
	_serial_write_lobby("OFF")
	_serial_write_lobby("__EXIT__")
	_matar_pontes_powershell_lobby()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_fechar_ponte_leds_lobby()
		get_tree().quit()


func _iniciar_leds_idle_lobby() -> void:
	if not USAR_LEDS_LOADING_LOBBY:
		return
	if fase_atual == FASE_PODIO:
		_leds_idle_ativo = false
		_serial_write_lobby("OFF")
		return

	_leds_idle_ativo = true
	_leds_idle_tempo = LEDS_IDLE_INTERVALO  # envia já no primeiro frame
	_leds_idle_index = 0


func _parar_leds_idle_lobby() -> void:
	_leds_idle_ativo = false
	_serial_write_lobby("OFF")



func _atualizar_leds_idle_lobby(delta: float) -> void:
	if not _leds_idle_ativo:
		return
	if _processando_resultado_retorno:
		return
	if fase_atual == FASE_PODIO:
		return

	_leds_idle_tempo += delta
	if _leds_idle_tempo < LEDS_IDLE_INTERVALO:
		return
	_leds_idle_tempo = 0.0

	_leds_idle_index += 1

	var total: int = LEDS_LETRAS_LOBBY.size()
	if total <= 0:
		return

	var head: int = _leds_idle_index % total

	# Paleta neon viva (roxo/magenta/violeta) para um lobby chamativo.
	# O "cometa" anda pelos LEDs com um rastro que apaga, então SEMPRE
	# fica algo aceso (nunca manda OFF aqui).
	var paleta: Array = [
		[180, 0, 255],   # roxo forte
		[255, 0, 220],   # magenta neon
		[120, 0, 255],   # violeta
		[210, 0, 255]    # roxo claro vivo
	]

	var cor_base: Array = paleta[int(_leds_idle_index / total) % paleta.size()]

	var partes: Array[String] = []

	for i in range(total):
		var dist: int = absi(i - head)
		dist = mini(dist, total - dist)   # rastro circular

		var fator: float = 1.0 - float(dist) * 0.32
		fator = clampf(fator, 0.10, 1.0)

		var r: int = int(clamp(float(cor_base[0]) * fator, 0.0, 255.0))
		var g: int = int(clamp(float(cor_base[1]) * fator, 0.0, 255.0))
		var b: int = int(clamp(float(cor_base[2]) * fator, 0.0, 255.0))

		partes.append("%s=%d,%d,%d" % [LEDS_LETRAS_LOBBY[i], r, g, b])

	_serial_write_lobby("SET:" + ";".join(partes))


func _rgb_cor_para_led(cor: Color) -> Array:
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



func _cores_proximos_players_lobby() -> Array:
	var cores: Array = []

	var prox: Dictionary = _proxima_partida_pendente()
	if prox.is_empty():
		return cores

	var index: int = int(prox.get("index", -1))
	var arr: Array = _as_array(partidas.get(fase_atual, []))

	if index < 0 or index >= arr.size():
		return cores

	var p: Dictionary = _as_dict(arr[index])

	if str(p.get("tipo", "")) == "grupo":
		for item in _as_array(p.get("jogadores", [])):
			cores.append(_cor_jogador(_as_dict(item)))
	else:
		cores.append(_cor_jogador(_as_dict(p.get("a", {}))))
		cores.append(_cor_jogador(_as_dict(p.get("b", {}))))

	return cores


# ============================================================
# HELPERS
# ============================================================

func _as_dict(v: Variant) -> Dictionary:
	if v is Dictionary:
		return v
	return {}


func _as_array(v: Variant) -> Array:
	if v is Array:
		return v
	return []


func _nome_jogador(j: Dictionary) -> String:
	return str(j.get("nome", j.get("name", "---")))


func _cor_jogador(j: Dictionary, fallback: Color = COR_NEON) -> Color:
	var c: Variant = j.get("cor", j.get("color", fallback))
	if c is Color:
		return c
	return fallback


func _eh_bot(j: Dictionary) -> bool:
	if bool(j.get("bot", j.get("eh_bot", j.get("boot", false)))):
		return true

	var nome: String = _nome_jogador(j).strip_edges().to_lower()
	return nome.begins_with("bot") or nome.begins_with("boot")


func _seed(j: Dictionary) -> int:
	return int(j.get("seed", j.get("id", 999999)))



func _coluna_rects(x: float, top: float, w: float, total_h: float, n: int, gap: float) -> Array:
	var rects: Array = []
	n = maxi(n, 1)
	var alt: float = (total_h - gap * float(n - 1)) / float(n)
	for i in range(n):
		rects.append(Rect2(Vector2(x, top + float(i) * (alt + gap)), Vector2(w, alt)))
	return rects


func _bordas_dir(rects: Array) -> Array:
	var pts: Array = []
	for r in rects:
		var rr: Rect2 = r
		pts.append(Vector2(rr.position.x + rr.size.x, rr.position.y + rr.size.y * 0.5))
	return pts


func _bordas_esq(rects: Array) -> Array:
	var pts: Array = []
	for r in rects:
		var rr: Rect2 = r
		pts.append(Vector2(rr.position.x, rr.position.y + rr.size.y * 0.5))
	return pts


func _ponto_dir(r: Rect2) -> Vector2:
	return Vector2(r.position.x + r.size.x, r.position.y + r.size.y * 0.5)


func _ponto_esq(r: Rect2) -> Vector2:
	return Vector2(r.position.x, r.position.y + r.size.y * 0.5)


func _conectar_colunas(parent: Control, origens: Array, destinos: Array, cor: Color) -> void:
	if origens.is_empty() or destinos.is_empty():
		return
	for i in range(origens.size()):
		var d: int = int(floor(float(i) * float(destinos.size()) / float(origens.size())))
		d = clampi(d, 0, destinos.size() - 1)
		_neon_conector(parent, origens[i], destinos[d], cor)


func _conectar_para_ponto(parent: Control, origens: Array, ponto: Vector2, cor: Color) -> void:
	for o in origens:
		_neon_conector(parent, o, ponto, cor)


func _neon_seg(parent: Control, pos: Vector2, tam: Vector2, cor: Color, alpha: float) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = tam
	r.color = Color(cor.r, cor.g, cor.b, alpha)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)


func _neon_conector(parent: Control, de: Vector2, ate: Vector2, cor: Color) -> void:
	var mx: float = (de.x + ate.x) * 0.5
	var esp: float = 2.5
	var glow: float = 7.0

	var x1: float = minf(de.x, mx)
	var w1: float = absf(mx - de.x)
	_neon_seg(parent, Vector2(x1, de.y - glow * 0.5), Vector2(w1, glow), cor, 0.10)
	_neon_seg(parent, Vector2(x1, de.y - esp * 0.5), Vector2(w1, esp), cor, 0.85)

	var y2: float = minf(de.y, ate.y)
	var h2: float = absf(ate.y - de.y)
	_neon_seg(parent, Vector2(mx - glow * 0.5, y2), Vector2(glow, h2), cor, 0.10)
	_neon_seg(parent, Vector2(mx - esp * 0.5, y2), Vector2(esp, h2), cor, 0.85)

	var x3: float = minf(mx, ate.x)
	var w3: float = absf(ate.x - mx)
	_neon_seg(parent, Vector2(x3, ate.y - glow * 0.5), Vector2(w3, glow), cor, 0.10)
	_neon_seg(parent, Vector2(x3, ate.y - esp * 0.5), Vector2(w3, esp), cor, 0.85)


func _criar_musica_lobby_torment() -> void:
	if is_instance_valid(musica_lobby_torment):
		return

	musica_lobby_torment = AudioStreamPlayer.new()
	musica_lobby_torment.name = "MusicaLobbyTormentIntroGame"
	add_child(musica_lobby_torment)

	if ResourceLoader.exists(MUSICA_LOBBY_TORMENT):
		var st: AudioStream = load(MUSICA_LOBBY_TORMENT)

		if st is AudioStreamMP3:
			st.loop = true

		musica_lobby_torment.stream = st
		musica_lobby_torment.volume_db = VOLUME_MUSICA_LOBBY_DB
	else:
		push_warning("Música intro_game não encontrada: " + MUSICA_LOBBY_TORMENT)


func _tocar_musica_lobby_torment() -> void:
	if musica_lobby_torment == null:
		return

	if musica_lobby_torment.stream == null:
		return

	if not musica_lobby_torment.playing:
		musica_lobby_torment.play()


func _parar_musica_lobby_torment() -> void:
	if musica_lobby_torment != null and musica_lobby_torment.playing:
		musica_lobby_torment.stop()


func _header_coluna(parent: Control, x: float, top: float, w: float, txt: String) -> void:
	var box: Panel = Panel.new()
	box.position = Vector2(x, top)
	box.size = Vector2(w, 22)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override(
		"panel",
		_style_panel_torment(
			COR_TORMENT,
			Color(0.010, 0.012, 0.020, 0.78),
			0.08,
			10,
			1
		)
	)
	parent.add_child(box)

	var lbl: Label = _label(txt, 11, Color.WHITE, COR_TORMENT)
	lbl.position = Vector2.ZERO
	lbl.size = box.size
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.clip_text = true
	box.add_child(lbl)



func _spine_central(parent: Control, cx: float, top: float, h: float) -> void:
	_neon_seg(parent, Vector2(cx - 1.5, top + 18.0), Vector2(3.0, h - 36.0), COR_TORMENT, 0.55)



func _render_coluna_cards(parent: Control, rects: Array, lista: Array, prefixo: String) -> void:
	for i in range(rects.size()):
		var p: Dictionary = _as_dict(lista[i]) if i < lista.size() else {}
		_render_card_mata_tv(parent, rects[i], p, "%s %02d" % [prefixo, i + 1])



func _render_grupo_box(parent: Control, rect: Rect2, gi: int) -> void:
	if gi < 0 or gi >= NOMES_GRUPOS.size():
		return

	var chave_nome: String = NOMES_GRUPOS[gi]
	var tabela: Array = _tabela_grupo(gi)

	var prox: Dictionary = _proxima_partida_pendente()
	var eh_proxima_chave: bool = false
	var etapa_proxima: String = ""

	if fase_atual == FASE_GRUPOS and not prox.is_empty():
		var idx_prox: int = int(prox.get("index", -1))
		var arr_prox: Array = _as_array(partidas.get(FASE_GRUPOS, []))

		if idx_prox >= 0 and idx_prox < arr_prox.size():
			var p_prox: Dictionary = _as_dict(arr_prox[idx_prox])
			if int(p_prox.get("grupo_index", -999)) == gi:
				eh_proxima_chave = true
				etapa_proxima = str(prox.get("etapa", "ida")).to_upper()

	var borda_card: Color = COR_ALERTA if eh_proxima_chave else COR_TORMENT
	var fundo_card: Color = Color(0.052, 0.036, 0.010, 0.97) if eh_proxima_chave else Color(0.014, 0.014, 0.026, 0.96)
	var brilho_card: float = 0.32 if eh_proxima_chave else 0.13

	var card := Panel.new()
	card.position = rect.position
	card.size = rect.size
	card.clip_contents = true
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override(
		"panel",
		_style_panel_torment(borda_card, fundo_card, brilho_card, 12, 2)
	)
	parent.add_child(card)

	var W: float = rect.size.x
	var H: float = rect.size.y

	var fs_tit: int = int(clampf(H * 0.145, 11.0, 16.0))

	var header_card_h: float = clampf(H * 0.24, 22.0, 34.0)

	var titulo_txt: String = "CHAVE %s" % chave_nome
	if eh_proxima_chave:
		titulo_txt = "▶ CHAVE %s" % chave_nome

	var titulo: Label = _label(titulo_txt, fs_tit, Color.WHITE, borda_card)
	titulo.position = Vector2(6, 0)

	if eh_proxima_chave:
		titulo.size = Vector2(maxf(W - 70.0, 40.0), header_card_h)
		titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	else:
		titulo.size = Vector2(W - 12.0, header_card_h)
		titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo.clip_text = true
	card.add_child(titulo)

	if eh_proxima_chave:
		var etapa_chip: Panel = Panel.new()
		etapa_chip.position = Vector2(W - 62.0, 1.0)
		etapa_chip.size = Vector2(56.0, header_card_h - 5.0)
		etapa_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		etapa_chip.add_theme_stylebox_override(
			"panel",
			_style_panel_torment(COR_ALERTA, Color(0.12, 0.075, 0.010, 0.96), 0.18, 8, 1)
		)
		card.add_child(etapa_chip)

		var etapa_lbl: Label = _label(etapa_proxima, 10, Color.WHITE, COR_ALERTA)
		etapa_lbl.position = Vector2.ZERO
		etapa_lbl.size = etapa_chip.size
		etapa_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		etapa_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		etapa_chip.add_child(etapa_lbl)

	var list_y: float = header_card_h + 3.0
	var list_h: float = H - list_y - 4.0
	var rows: int = 3
	var gap: float = 3.0
	var row_h: float = (list_h - gap * float(rows - 1)) / float(rows)
	var fs: int = int(clampf(row_h * 0.46, 10.0, 15.0))

	for i in range(rows):
		var ry: float = list_y + float(i) * (row_h + gap)
		var classifica: bool = i < 2
		var cor_linha: Color = COR_OK if classifica else Color(0.30, 0.32, 0.40)

		var linha := Panel.new()
		linha.position = Vector2(6, ry)
		linha.size = Vector2(W - 12, row_h)
		linha.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var bg_linha: Color = Color(cor_linha.r * 0.11, cor_linha.g * 0.11, cor_linha.b * 0.11, 0.82)
		if not classifica:
			bg_linha = Color(0.018, 0.018, 0.026, 0.62)

		linha.add_theme_stylebox_override(
			"panel",
			_style_panel_torment(cor_linha, bg_linha, 0.04 if classifica else 0.0, 7, 1)
		)
		card.add_child(linha)

		if i < tabela.size():
			var j: Dictionary = _as_dict(tabela[i])
			var cor_j: Color = _cor_jogador(j, COR_NEON)

			var nome_txt: String = "%dº %s" % [
				i + 1,
				_nome_jogador(j)
			]

			if _eh_bot(j):
				nome_txt += " B"

			var centro_y: float = ry + row_h * 0.5

			var chip := ColorRect.new()
			chip.position = Vector2(11, centro_y - 4.0)
			chip.size = Vector2(4, 8)
			chip.color = cor_j
			chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(chip)

			var gols_w: float = 32.0
			var nome_x: float = 20.0
			var nome_w: float = maxf(W - nome_x - gols_w - 18.0, 30.0)

			var texto_h: float = row_h + 4.0
			var texto_y: float = centro_y - texto_h * 0.5 - 1.0

			var lbl := _label(nome_txt, fs, Color.WHITE if classifica else Color(0.62, 0.64, 0.72), Color.BLACK)
			lbl.position = Vector2(nome_x, texto_y)
			lbl.size = Vector2(nome_w, texto_h)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.clip_text = true
			lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			card.add_child(lbl)

			var gols_valor: int = int(j.get("gols_total", j.get("gols_grupo", 0)))

			var gols := _label(str(gols_valor), fs, COR_ALERTA if classifica else COR_TEXTO_SUAVE)
			gols.position = Vector2(W - gols_w - 10.0, texto_y)
			gols.size = Vector2(gols_w, texto_h)
			gols.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			gols.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			gols.clip_text = true
			card.add_child(gols)
		else:
			var vazio := _label("—", fs, Color(0.40, 0.42, 0.48))
			vazio.position = Vector2(18, ry - 1.0)
			vazio.size = Vector2(W - 28, row_h + 3.0)
			vazio.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			vazio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			card.add_child(vazio)



func _limpar_metas_partida_torment() -> void:
	var metas: Array[String] = [
		META_PARTIDA,
		META_PARTIDA_INDEX,
		META_PARTIDA_FASE,
		META_PARTIDA_ETAPA,
		META_PARTIDA_ID,
		META_RESULTADO,
		"torment_bye_oitavas"
	]

	for m in metas:
		if get_tree().has_meta(m):
			get_tree().remove_meta(m)



func _eh_card_da_proxima_partida(p: Dictionary) -> bool:
	if p.is_empty():
		return false

	var prox: Dictionary = _proxima_partida_pendente()
	if prox.is_empty():
		return false

	var index: int = int(prox.get("index", -1))
	var arr: Array = _as_array(partidas.get(fase_atual, []))

	if index < 0 or index >= arr.size():
		return false

	var atual: Dictionary = _as_dict(arr[index])
	return str(atual.get("id", "")) == str(p.get("id", ""))



func _etapa_card_proxima(p: Dictionary) -> String:
	if not _eh_card_da_proxima_partida(p):
		return ""

	var prox: Dictionary = _proxima_partida_pendente()
	return str(prox.get("etapa", "ida")).to_upper()



func _score_txt(v: int) -> String:
	if v < 0:
		return "—"
	return str(v)



func _add_placar_mata_linha(
	parent: Control,
	y: float,
	w: float,
	txt: String,
	a_txt: String,
	b_txt: String,
	cor_a: Color,
	cor_b: Color,
	ativo: bool
) -> void:
	var h: float = 18.0
	var label_w: float = clampf(w * 0.42, 62.0, 110.0)
	var score_w: float = clampf(w * 0.18, 26.0, 42.0)
	var x0: float = 6.0

	var bg: ColorRect = ColorRect.new()
	bg.position = Vector2(5.0, y + 1.0)
	bg.size = Vector2(w - 10.0, h - 2.0)
	bg.color = Color(1, 1, 1, 0.075 if ativo else 0.035)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)

	# Texto (IDA / VOLTA / AGREGADO) continua no Orbitron.
	var l: Label = _label(txt, 9, COR_TEXTO_SUAVE, Color.BLACK)
	l.position = Vector2(x0, y)
	l.size = Vector2(label_w, h)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.clip_text = true
	parent.add_child(l)

	# NÚMEROS: fonte padrão da engine (_label_num).
	var a: Label = _label_num(a_txt, 13, cor_a, Color.BLACK)
	a.position = Vector2(w - score_w * 2.0 - 22.0, y)
	a.size = Vector2(score_w, h)
	parent.add_child(a)

	var x: Label = _label_num("x", 10, Color.WHITE, Color.BLACK)
	x.position = Vector2(w - score_w - 22.0, y)
	x.size = Vector2(20.0, h)
	parent.add_child(x)

	var b: Label = _label_num(b_txt, 13, cor_b, Color.BLACK)
	b.position = Vector2(w - score_w - 2.0, y)
	b.size = Vector2(score_w, h)
	parent.add_child(b)


func _players_reais_proxima_partida() -> Array:
	var reais: Array = []

	var prox: Dictionary = _proxima_partida_pendente()
	if prox.is_empty():
		return reais

	var index: int = int(prox.get("index", -1))
	var arr: Array = _as_array(partidas.get(fase_atual, []))

	if index < 0 or index >= arr.size():
		return reais

	var p: Dictionary = _as_dict(arr[index])

	if str(p.get("tipo", "")) == "grupo":
		for item in _as_array(p.get("jogadores", [])):
			var j: Dictionary = _as_dict(item)
			if not _eh_bot(j):
				reais.append(j)
	else:
		for lado in ["a", "b"]:
			var j2: Dictionary = _as_dict(p.get(lado, {}))
			if not j2.is_empty() and not _eh_bot(j2):
				reais.append(j2)

	return reais



func _criar_semis_cruzadas() -> void:
	# Semifinais seguindo a posição do chaveamento (igual ao visual):
	# SEMI 1 = vencedor QUARTA 1 x vencedor QUARTA 2
	# SEMI 2 = vencedor QUARTA 3 x vencedor QUARTA 4
	var qf: Array = _as_array(partidas.get(FASE_QUARTAS, []))
	var vencedores: Array = []

	for item in qf:
		var p: Dictionary = _as_dict(item)
		if bool(p.get("finalizada", false)):
			vencedores.append(_jogador_com_stats(_as_dict(p.get("vencedor", {}))))

	var arr: Array = []
	var numero: int = 1
	var i: int = 0

	while i + 1 < vencedores.size():
		var a: Dictionary = _as_dict(vencedores[i])
		var b: Dictionary = _as_dict(vencedores[i + 1])
		var p2: Dictionary = _nova_partida_mata(FASE_SEMIS, a, b, numero)
		arr.append(p2)
		numero += 1
		i += 2

	partidas[FASE_SEMIS] = arr



func _cor_conector_fase(fase_origem: String) -> Color:
	# Roxo (COR_TORMENT) enquanto a fase ainda não aconteceu.
	# Verde forte (COR_OK) quando a fase já foi concluída e os
	# jogadores já foram direcionados para a próxima fase.
	if _fase_concluida(fase_origem):
		return COR_OK
	return COR_TORMENT



# ============================================================
# PÓDIO FINAL — CONFETES + GOOD_PLAYER + HOLD START
# ============================================================

func _criar_audio_podio_good_player() -> void:
	if is_instance_valid(audio_podio_good_player):
		return

	audio_podio_good_player = AudioStreamPlayer.new()
	audio_podio_good_player.name = "AudioPodioGoodPlayer"
	add_child(audio_podio_good_player)

	if ResourceLoader.exists(SFX_PODIO_GOOD_PLAYER):
		var st: AudioStream = load(SFX_PODIO_GOOD_PLAYER)

		if st is AudioStreamMP3:
			st.loop = true

		audio_podio_good_player.stream = st
		audio_podio_good_player.volume_db = VOLUME_PODIO_GOOD_PLAYER_DB
	else:
		push_warning("good_player.mp3 não encontrado: " + SFX_PODIO_GOOD_PLAYER)


func _tocar_good_player_podio() -> void:
	_criar_audio_podio_good_player()

	# Mantém a música do lobby tocando.
	_tocar_musica_lobby_torment()

	if audio_podio_good_player == null:
		return

	if audio_podio_good_player.stream == null:
		return

	if not audio_podio_good_player.playing:
		audio_podio_good_player.play()


func _parar_good_player_podio() -> void:
	if audio_podio_good_player != null and audio_podio_good_player.playing:
		audio_podio_good_player.stop()


func _atualizar_hold_start_retorno_podio(delta: float) -> void:
	if fase_atual != FASE_PODIO:
		_start_hold_retorno_podio_tempo = 0.0
		_atualizar_barra_hold_podio(0.0)
		return

	if _retornando_inicio_podio:
		_atualizar_barra_hold_podio(1.0)
		return

	if not _acao_existe("input_start"):
		return

	if Input.is_action_pressed("input_start"):
		_start_hold_retorno_podio_tempo += delta

		var progresso: float = _start_hold_retorno_podio_tempo / START_HOLD_RETORNAR_PODIO
		_atualizar_barra_hold_podio(progresso)

		if _start_hold_retorno_podio_tempo >= START_HOLD_RETORNAR_PODIO:
			_start_hold_retorno_podio_tempo = 0.0
			_retornar_inicio_podio()
	else:
		_start_hold_retorno_podio_tempo = 0.0
		_atualizar_barra_hold_podio(0.0)


func _retornar_inicio_podio() -> void:
	if _retornando_inicio_podio:
		return

	if not ResourceLoader.exists(CENA_OPENING):
		return

	_retornando_inicio_podio = true
	_podio_confete_ativo = false
	_atualizar_barra_hold_podio(1.0)

	_parar_leds_idle_lobby()

	await _tocar_start_game_e_aguardar()

	_parar_good_player_podio()

	get_tree().change_scene_to_file(CENA_OPENING)


func _iniciar_confetes_podio(parent: Control) -> void:
	if not is_instance_valid(parent):
		return

	_podio_confete_ativo = true
	_podio_confete_timer = 0.0

	var camada := Control.new()
	camada.name = "ConfetesPodioTorment"
	camada.position = Vector2.ZERO
	camada.size = parent.size
	camada.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.z_index = 80
	parent.add_child(camada)

	_podio_confete_root = camada

	for i in range(CONFETES_INICIAIS_PODIO):
		_emitir_confete_podio()


func _atualizar_confetes_podio(delta: float) -> void:
	if fase_atual != FASE_PODIO:
		_podio_confete_ativo = false
		return

	if not _podio_confete_ativo:
		return

	if not is_instance_valid(_podio_confete_root):
		return

	_podio_confete_timer += delta

	while _podio_confete_timer >= CONFETE_INTERVALO_PODIO:
		_podio_confete_timer -= CONFETE_INTERVALO_PODIO
		_emitir_confete_podio()


func _emitir_confete_podio() -> void:
	if not is_instance_valid(_podio_confete_root):
		return

	var tela: Vector2 = _podio_confete_root.size

	if tela.x <= 0.0 or tela.y <= 0.0:
		return

	var cores: Array = [
		COR_ALERTA,
		COR_TORMENT,
		COR_TORMENT_2,
		COR_NEON,
		COR_OK,
		COR_PRATA,
		COR_BRONZE,
		Color(1.0, 1.0, 1.0, 1.0)
	]

	var cor: Color = cores[randi() % cores.size()]

	var confete := ColorRect.new()
	confete.mouse_filter = Control.MOUSE_FILTER_IGNORE
	confete.color = cor

	var largura: float = randf_range(5.0, 12.0)
	var altura: float = randf_range(7.0, 19.0)

	confete.size = Vector2(largura, altura)

	var inicio_x: float = randf_range(-40.0, tela.x + 40.0)
	var inicio_y: float = randf_range(-120.0, -12.0)

	confete.position = Vector2(inicio_x, inicio_y)
	confete.modulate = Color(1, 1, 1, randf_range(0.72, 1.0))

	_podio_confete_root.add_child(confete)

	var queda_x: float = inicio_x + randf_range(-170.0, 170.0)
	var queda_y: float = tela.y + randf_range(30.0, 120.0)
	var duracao: float = randf_range(2.6, 5.4)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(confete, "position", Vector2(queda_x, queda_y), duracao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(confete, "size", Vector2(largura * randf_range(0.55, 1.45), altura * randf_range(0.55, 1.45)), duracao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func() -> void:
		if is_instance_valid(confete):
			confete.queue_free()
	)



func _decorar_card_mata_moderno(card: Panel, cor: Color, proxima: bool, finalizada: bool, eh_final: bool) -> void:
	if not is_instance_valid(card):
		return

	var W: float = card.size.x
	var H: float = card.size.y

	var faixa_top := ColorRect.new()
	faixa_top.position = Vector2(0, 0)
	faixa_top.size = Vector2(W, 3.0 if not eh_final else 4.0)
	faixa_top.color = Color(cor.r, cor.g, cor.b, 0.78 if proxima else 0.48)
	faixa_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(faixa_top)

	var faixa_lateral := ColorRect.new()
	faixa_lateral.position = Vector2(0, 0)
	faixa_lateral.size = Vector2(4.0, H)
	faixa_lateral.color = Color(cor.r, cor.g, cor.b, 0.72 if proxima else 0.42)
	faixa_lateral.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(faixa_lateral)

	var brilho_dir := ColorRect.new()
	brilho_dir.position = Vector2(W * 0.62, 0)
	brilho_dir.size = Vector2(W * 0.38, H)
	brilho_dir.color = Color(1, 1, 1, 0.045 if proxima else 0.022)
	brilho_dir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(brilho_dir)

	var neon_base := ColorRect.new()
	neon_base.position = Vector2(8.0, H - 5.0)
	neon_base.size = Vector2(W - 16.0, 2.0)
	neon_base.color = Color(cor.r, cor.g, cor.b, 0.55 if proxima else 0.25)
	neon_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(neon_base)

	if proxima:
		var pulse := ColorRect.new()
		pulse.position = Vector2(8.0, H - 9.0)
		pulse.size = Vector2(W - 16.0, 7.0)
		pulse.color = Color(cor.r, cor.g, cor.b, 0.12)
		pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(pulse)




func _decorar_fundo_podio_torment(painel: Panel) -> void:
	if not is_instance_valid(painel):
		return

	var W: float = painel.size.x
	var H: float = painel.size.y

	var glow_top := ColorRect.new()
	glow_top.position = Vector2(0, 0)
	glow_top.size = Vector2(W, 5.0)
	glow_top.color = Color(COR_TORMENT.r, COR_TORMENT.g, COR_TORMENT.b, 0.72)
	glow_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(glow_top)

	var glow_ciano := ColorRect.new()
	glow_ciano.position = Vector2(W * 0.18, 6.0)
	glow_ciano.size = Vector2(W * 0.64, 2.0)
	glow_ciano.color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 0.58)
	glow_ciano.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(glow_ciano)

	var aura_esq := ColorRect.new()
	aura_esq.position = Vector2(0, 0)
	aura_esq.size = Vector2(W * 0.26, H)
	aura_esq.color = Color(COR_TORMENT.r, COR_TORMENT.g, COR_TORMENT.b, 0.055)
	aura_esq.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(aura_esq)

	var aura_dir := ColorRect.new()
	aura_dir.position = Vector2(W * 0.74, 0)
	aura_dir.size = Vector2(W * 0.26, H)
	aura_dir.color = Color(COR_NEON.r, COR_NEON.g, COR_NEON.b, 0.040)
	aura_dir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(aura_dir)


func _fundo_pedestal_torment(posicao: int) -> Color:
	match posicao:
		1:
			return Color(0.020, 0.014, 0.052, 0.98) # campeão: roxo premium
		2:
			return Color(0.012, 0.022, 0.046, 0.98) # vice: azul/prata
		3:
			return Color(0.026, 0.014, 0.044, 0.98) # terceiro: violeta/bronze
	return Color(0.014, 0.018, 0.038, 0.98)


func _decorar_pedestal_torment(ped: Panel, cor: Color, posicao: int) -> void:
	if not is_instance_valid(ped):
		return

	var W: float = ped.size.x
	var H: float = ped.size.y

	var top_line := ColorRect.new()
	top_line.position = Vector2(0, 0)
	top_line.size = Vector2(W, 5.0)
	top_line.color = Color(cor.r, cor.g, cor.b, 0.84)
	top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ped.add_child(top_line)

	var side_line := ColorRect.new()
	side_line.position = Vector2(0, 0)
	side_line.size = Vector2(5.0, H)
	side_line.color = Color(cor.r, cor.g, cor.b, 0.60)
	side_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ped.add_child(side_line)

	var luz := ColorRect.new()
	luz.position = Vector2(W * 0.58, 0)
	luz.size = Vector2(W * 0.42, H)
	luz.color = Color(1, 1, 1, 0.030)
	luz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ped.add_child(luz)

	var base := ColorRect.new()
	base.position = Vector2(12.0, H - 8.0)
	base.size = Vector2(W - 24.0, 3.0)
	base.color = Color(cor.r, cor.g, cor.b, 0.50)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ped.add_child(base)


func _render_barra_hold_start_podio(parent: Control, tela: Vector2) -> void:
	var w: float = minf(tela.x - 90.0, 680.0)
	var h: float = 28.0
	var x: float = (tela.x - w) * 0.5
	var y: float = tela.y - 88.0

	var box := Panel.new()
	box.position = Vector2(x, y)
	box.size = Vector2(w, h)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override(
		"panel",
		_style_panel_torment(COR_NEON, Color(0.004, 0.014, 0.034, 0.94), 0.30, 12, 2)
	)
	parent.add_child(box)

	var bg := ColorRect.new()
	bg.position = Vector2(8.0, 9.0)
	bg.size = Vector2(w - 16.0, 10.0)
	bg.color = Color(1, 1, 1, 0.10)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(bg)

	var fill := ColorRect.new()
	fill.position = bg.position
	fill.size = Vector2(0.0, bg.size.y)
	fill.color = COR_NEON
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(fill)

	var brilho := ColorRect.new()
	brilho.position = Vector2(8.0, 7.0)
	brilho.size = Vector2(w - 16.0, 14.0)
	brilho.color = Color(COR_TORMENT.r, COR_TORMENT.g, COR_TORMENT.b, 0.08)
	brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(brilho)

	var lbl := _label("SEGURE START PARA VOLTAR", 12, Color.WHITE, COR_NEON)
	lbl.position = Vector2(0, 0)
	lbl.size = box.size
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(lbl)

	_podio_hold_fill = fill
	_podio_hold_label = lbl
	_podio_hold_fill_max_w = bg.size.x

	_atualizar_barra_hold_podio(0.0)


func _atualizar_barra_hold_podio(progresso: float) -> void:
	progresso = clampf(progresso, 0.0, 1.0)

	if is_instance_valid(_podio_hold_fill):
		_podio_hold_fill.size.x = _podio_hold_fill_max_w * progresso

	if is_instance_valid(_podio_hold_label):
		if progresso <= 0.01:
			_podio_hold_label.text = "SEGURE START PARA VOLTAR"
		elif progresso < 1.0:
			_podio_hold_label.text = "VOLTANDO... %d%%" % int(progresso * 100.0)
		else:
			_podio_hold_label.text = "ABRINDO TELA INICIAL..."
			


func _criar_audio_start_torment() -> void:
	if is_instance_valid(audio_start_torment):
		return

	audio_start_torment = AudioStreamPlayer.new()
	audio_start_torment.name = "AudioStartTorment"
	add_child(audio_start_torment)

	var caminho: String = SFX_START_TORMENT

	if not ResourceLoader.exists(caminho):
		caminho = SFX_START_TORMENT_FALLBACK

	if ResourceLoader.exists(caminho):
		audio_start_torment.stream = load(caminho)
		audio_start_torment.volume_db = VOLUME_SFX_START_TORMENT_DB
	else:
		push_warning("Som de START não encontrado: " + SFX_START_TORMENT + " nem " + SFX_START_TORMENT_FALLBACK)


func _tocar_start_game_e_aguardar() -> void:
	_criar_audio_start_torment()

	if audio_start_torment != null and audio_start_torment.stream != null:
		audio_start_torment.stop()
		audio_start_torment.play()

	await get_tree().create_timer(DELAY_TROCA_CENA_START).timeout




func _criar_disputa_terceiro(perdedores: Array) -> void:
	var lista: Array = perdedores.duplicate(true)
	if lista.size() < 2:
		return

	var a: Dictionary = _as_dict(lista[0])
	var b: Dictionary = _as_dict(lista[1])

	var p: Dictionary = _nova_partida_mata(FASE_3LUGAR, a, b, 1)
	p["disputa_terceiro"] = true

	partidas[FASE_3LUGAR] = [p]


func _style_card_mata_neon(cor_borda: Color, cor_fundo: Color, brilho: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = cor_fundo
	s.border_color = Color(cor_borda.r, cor_borda.g, cor_borda.b, maxf(cor_borda.a, 0.60))
	s.set_border_width_all(2)
	s.set_corner_radius_all(18)
	s.corner_detail = 16
	s.anti_aliasing = true
	s.anti_aliasing_size = 1.0
	s.shadow_color = Color(cor_borda.r, cor_borda.g, cor_borda.b, clampf(brilho + 0.16, 0.0, 0.95))
	s.shadow_size = 18
	s.shadow_offset = Vector2.ZERO
	return s



func _chuva_fitas_campeao(parent: Control, cor: Color) -> void:
	if not is_instance_valid(parent):
		return

	var qtd: int = 26

	for i in range(qtd):
		var fita := ColorRect.new()
		var w: float = randf_range(5.0, 11.0)
		var hf: float = randf_range(16.0, 32.0)
		fita.size = Vector2(w, hf)

		var x: float = randf_range(0.0, maxf(parent.size.x - w, 1.0))
		fita.position = Vector2(x, -hf)

		# SEMPRE variação da cor do campeão (nunca cor aleatória).
		var base: Color = cor.lightened(randf_range(0.05, 0.40)) if randf() < 0.5 else cor.darkened(randf_range(0.05, 0.30))
		fita.color = Color(base.r, base.g, base.b, randf_range(0.78, 1.0))

		fita.rotation = randf_range(-0.7, 0.7)
		fita.pivot_offset = fita.size * 0.5
		fita.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fita.z_index = 60
		parent.add_child(fita)

		var dur: float = randf_range(2.6, 4.8)
		var atraso: float = randf_range(0.0, 2.4)
		var queda: float = parent.size.y + 50.0
		var bal: float = randf_range(16.0, 44.0)

		var t := create_tween()
		t.set_loops()
		t.set_parallel(true)
		t.tween_property(fita, "position:y", queda, dur).from(-hf - 10.0).set_delay(atraso).set_trans(Tween.TRANS_LINEAR)
		t.tween_property(fita, "position:x", x + bal, dur).from(x - bal).set_delay(atraso).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)



func _render_barra_hold_podio(parent: Control, cor: Color) -> void:
	var W: float = parent.size.x
	var H: float = parent.size.y
	var bar_w: float = minf(W * 0.5, 520.0)
	var bx: float = (W - bar_w) * 0.5
	var by: float = H - 54.0

	var label := _label("SEGURE START PARA VOLTAR À TELA INICIAL", 15, Color.WHITE, cor)
	label.position = Vector2(bx, by - 26.0)
	label.size = Vector2(bar_w, 22.0)
	parent.add_child(label)

	var bg := Panel.new()
	bg.position = Vector2(bx, by)
	bg.size = Vector2(bar_w, 14.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_theme_stylebox_override(
		"panel",
		_style_panel_torment(cor, Color(0.02, 0.02, 0.03, 0.9), 0.16, 8, 1)
	)
	parent.add_child(bg)

	_podio_barra_max_w = bar_w - 4.0
	var frac: float = clampf(_podio_hold_tempo / PODIO_HOLD_RETORNO, 0.0, 1.0)

	_podio_barra_fill = ColorRect.new()
	_podio_barra_fill.position = Vector2(bx + 2.0, by + 2.0)
	_podio_barra_fill.size = Vector2(_podio_barra_max_w * frac, 10.0)
	_podio_barra_fill.color = cor
	_podio_barra_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_podio_barra_fill)


func _atualizar_hold_podio(delta: float) -> void:
	if fase_atual != FASE_PODIO:
		_podio_hold_tempo = 0.0
		return
	if _podio_voltando:
		return
	if not _acao_existe("input_start"):
		return

	if Input.is_action_pressed("input_start"):
		_podio_hold_tempo += delta
	else:
		_podio_hold_tempo = maxf(_podio_hold_tempo - delta * 2.0, 0.0)

	if is_instance_valid(_podio_barra_fill):
		var frac: float = clampf(_podio_hold_tempo / PODIO_HOLD_RETORNO, 0.0, 1.0)
		_podio_barra_fill.size.x = _podio_barra_max_w * frac

	if _podio_hold_tempo >= PODIO_HOLD_RETORNO:
		_podio_voltando = true
		if ResourceLoader.exists(CENA_OPENING):
			_parar_leds_idle_lobby()
			get_tree().change_scene_to_file(CENA_OPENING)


func _salvar_torneio_no_mural() -> void:
	if _torneio_salvo_mural:
		return
	if top3_final.size() < 3:
		return

	var db := get_node_or_null("/root/ChampionsDb")
	if db == null:
		push_warning("TORMENT: ChampionsDb (autoload) não encontrado. Torneio não salvo no mural.")
		return

	var top3_payload: Array = []
	for item in top3_final:
		var j: Dictionary = _jogador_com_stats(_as_dict(item))
		top3_payload.append({
			"nome": _nome_jogador(j),
			"gols_total": int(j.get("gols_total", 0)),
			"gols_normais": int(j.get("gols_total", 0)),
			"penaltis_total": int(j.get("penaltis_total", 0)),
			"jogos_total": int(j.get("jogos_total", 0)),
			"vitorias_total": int(j.get("vitorias_total", 0)),
			"pontos_grupo": int(j.get("pontos_grupo", 0)),
			"grupo": str(j.get("grupo_nome", j.get("grupo", "-"))),
			"fase_nome": "TORNEIO 36"
		})

	var reais: int = 0
	for jg in jogadores:
		if not _eh_bot(_as_dict(jg)):
			reais += 1

	var partidas_total: int = 0
	for fase in partidas.keys():
		partidas_total += _as_array(partidas[fase]).size()

	var payload: Dictionary = {
		"tipo": "TORNEIO",
		"titulo": "Torneio 36 Players",
		"top3": top3_payload,
		"resumo": {
			"fase_final": "Grande Final",
			"partidas_total": partidas_total,
			"grupos_total": 12,
			"jogadores_reais": reais
		}
	}

	db.registrar_copa(payload)
	_torneio_salvo_mural = true

	# Acabou: limpa o estado "em andamento".
	var es := get_node_or_null("/root/EstadoComp")
	if es:
		es.limpar("torneio36")
