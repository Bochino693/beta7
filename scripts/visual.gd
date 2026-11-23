extends Node

## VISUAL MODERNO E LISO, PARA O JOGO INTEIRO (sem reescrever cada tela):
##
## 1. PAINÉIS LIMPOS: todo painel / botão do jogo usa StyleBoxFlat com um
##    "neon" de sombra grande. Aqui cada um é afinado quando entra na tela:
##    brilho mais curto e suave, borda fina, cantos lisos (antisserrilhado).
##    Fica mais limpo e mais leve para a placa de vídeo da TV Box (sombra
##    grande é o que mais custa para desenhar).
## 2. MODAIS ANIMADOS: todo painel que aparece DEPOIS de a tela estar montada
##    (modal, aviso, pop-up, resultado) entra com um "pulo" curto: cresce de
##    92% para 100% com um leve passa-e-volta e surge do transparente. O fundo
##    escuro de um modal surge em fade. Um painel que a própria tela já anima
##    (escala ou transparência mexidas por ela) não é tocado.
## 3. SEM ENGASGOS: as imagens, sons, fontes e telas são carregados em
##    segundo plano logo que o jogo abre e ficam na memória; trocar de tela ou
##    tocar um som pela primeira vez não para mais o jogo para ler o arquivo.
##
## Para desligar: LIGADO = false.

const LIGADO := true
const BRILHO_MAX := 10            # tamanho máximo da sombra/neon (antes: até 40+)
const BRILHO_ALFA := 0.62         # o neon fica mais discreto
const BORDA_MAX := 2
const MONTANDO_MS := 450          # a tela nova ainda está se montando: não anima
const ENTRADA_S := 0.26
const PASTAS_CACHE := ["res://fonts", "res://images", "res://fundos", "res://songs", "res://scenes", "res://branding"]
const NOMES_ESTILO := ["panel", "normal", "hover", "pressed", "focus", "disabled", "fill", "background"]

var _cena: Node
var _partida := false
const TELAS_DE_PARTIDA := ["play", "cup_play", "torment_play", "pendings_play"]
var _cena_desde := 0
var _animando := {}               # nó -> true (só neste quadro: o pai anima, o filho não)
var _cache := {}                  # caminho -> recurso (fica na memória)
var _fila: Array[String] = []
var _carregando := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_carregar_nivel()
	_aplicar_resolucao()
	if not LIGADO:
		set_process(false)
		return
	get_tree().node_added.connect(_no_novo)
	_montar_fila()


# ------------------------------------------------------------------ quadro
func _process(_delta: float) -> void:
	var cena := get_tree().current_scene
	if cena != _cena:
		_trocou_de_tela(cena)
	if not _animando.is_empty():
		_animando.clear()
	_carregar_um()
	_medir()


func _trocou_de_tela(cena: Node) -> void:
	_cena = cena
	_cena_desde = Time.get_ticks_msec()
	_partida = cena != null and cena.scene_file_path.get_file().get_basename() in TELAS_DE_PARTIDA
	if OS.get_name() == "Android" and cena != null and ALTURAS[nivel] != _altura and cena.scene_file_path.get_file() == "opening.tscn":
		_trocar_resolucao()


# ------------------------------------------------- desempenho automático
## O JOGO SE AJUSTA À PLACA DE VÍDEO DA TV BOX. Ele mede os quadros por
## segundo de verdade e, se a caixa não dá conta, desce um degrau (e guarda,
## para já abrir certo da próxima vez):
##   nível 0  tudo: neon nos painéis, luzes de fundo, 720 linhas   (PC)
##   nível 1  sem o neon (sombra) dos painéis e sem luzes de fundo (a TV Box começa aqui)
##   nível 2  + imagem em 540 linhas (a TV Box estica)
##   nível 3  + imagem em 480 linhas
##   nível 4  + travado em 30 quadros por segundo (constante é melhor que oscilando)
## Para recomeçar a medição: apague user://visual.cfg (ou reinstale o jogo).
const ARQUIVO := "user://visual.cfg"
const ALTURAS := [720, 720, 540, 480, 480]
const JANELA_MS := 5000
const QPS_MINIMO := 41.0
var nivel := 0
var qps := 0.0
var placa := ""
var _med_quadros := 0
var _med_desde := 0
var _ruins := 0
var _altura := 0


func _carregar_nivel() -> void:
	placa = RenderingServer.get_video_adapter_name()
	if OS.get_name() != "Android":
		nivel = 0
		return
	var cfg := ConfigFile.new()
	cfg.load(ARQUIVO)
	nivel = clampi(int(cfg.get_value("visual", "nivel", 1)), 0, 4)


func _guardar_nivel() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("visual", "nivel", nivel)
	cfg.set_value("visual", "placa", placa)
	cfg.save(ARQUIVO)


## A imagem do jogo em poucas linhas, esticada pela TV (uma caixa ligada em
## 1080p ou 4K desenharia muito mais pontos por quadro).
func _aplicar_resolucao() -> void:
	if OS.get_name() != "Android":
		return
	var alt: int = ALTURAS[nivel]
	if alt == _altura:
		return
	_altura = alt
	var janela := get_tree().root
	janela.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	janela.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	janela.content_scale_size = Vector2i(int(round(alt * 16.0 / 9.0)), alt)
	Engine.max_fps = 30 if nivel >= 4 else 0


func _medir() -> void:
	var agora := Time.get_ticks_msec()
	# não mede montando a tela, em transição nem com o jogo parado num aviso
	if agora - _cena_desde < 4000 or get_tree().paused:
		_med_quadros = 0
		_med_desde = agora
		return
	_med_quadros += 1
	if agora - _med_desde < JANELA_MS:
		return
	qps = _med_quadros * 1000.0 / float(agora - _med_desde)
	_med_quadros = 0
	_med_desde = agora
	if OS.get_name() != "Android" or nivel >= 4:
		return
	if qps >= QPS_MINIMO:
		_ruins = 0
		return
	_ruins += 1
	if _ruins < 2:
		return
	_ruins = 0
	nivel += 1
	_guardar_nivel()
	print("VISUAL: ", snappedf(qps, 0.1), " quadros/s: descendo para o nível ", nivel)
	if ALTURAS[nivel] != _altura or nivel >= 4:
		_trocar_resolucao()


## A resolução só troca com a tela do menu (ela é remontada no tamanho novo).
func _trocar_resolucao() -> void:
	var cena := get_tree().current_scene
	if cena == null or cena.scene_file_path.get_file() != "opening.tscn":
		return   # fica para a próxima vez que o menu abrir (_process)
	_aplicar_resolucao()
	get_tree().reload_current_scene.call_deferred()


## Para o canto da tela e a Central da Máquina.
func texto() -> String:
	return "%s  •  %d q/s  •  nível %d  •  %dp" % [placa if placa != "" else "?", int(round(qps)), nivel, ALTURAS[nivel]]


# ----------------------------------------------------------- painéis limpos
func _no_novo(n: Node) -> void:
	# (chamado para CADA nó que entra na árvore: tem que ser quase de graça)
	# (a tela nova monta os nós dela antes do nosso _process ver a troca)
	var atual := get_tree().current_scene
	if atual != _cena:
		_trocou_de_tela(atual)
	if _partida:
		return   # telas de partida: nada é tocado (cores, neon dos LEDs e tempos são os do jogo)
	if not (n is Panel or n is PanelContainer or n is BaseButton or n is ColorRect):
		return
	var depois: bool = Time.get_ticks_msec() - _cena_desde >= MONTANDO_MS
	if n is ColorRect:
		if depois:
			_talvez_animar.call_deferred(n)
		return
	# o estilo chega logo depois de o nó entrar: afina UMA vez, no fim do quadro
	_afinar.call_deferred(n)
	if depois:
		_talvez_animar.call_deferred(n)


func _e_do_sistema(c: Node) -> bool:
	# os avisos e o teclado do próprio sistema (ControleTv, Efeitos, ArduinoBridge)
	var p := c
	while p != null:
		if p == self or p.name in ["ControleTv", "Efeitos", "ArduinoBridge", "Harness"] and p.get_parent() == get_tree().root:
			return true
		p = p.get_parent()
	return false


func _afinar(c: Control) -> void:
	if not is_instance_valid(c) or _e_do_sistema(c):
		return
	for nome in NOMES_ESTILO:
		if not c.has_theme_stylebox_override(nome):
			continue
		var sb := c.get_theme_stylebox(nome)
		if sb is StyleBoxFlat and not sb.has_meta("visual"):
			_afinar_estilo(sb as StyleBoxFlat)


func _afinar_estilo(sb: StyleBoxFlat) -> void:
	sb.set_meta("visual", true)
	# só o que deixa MAIS LEVE: sombra (neon) curta. Sem antisserrilhado e sem
	# cantos mais detalhados - isso é desenho a mais para a placa de vídeo.
	var maximo: int = BRILHO_MAX if nivel == 0 else 0
	if sb.shadow_size > maximo:
		sb.shadow_size = maximo
		var cor := sb.shadow_color
		sb.shadow_color = Color(cor.r, cor.g, cor.b, cor.a * BRILHO_ALFA)


# ----------------------------------------------------------- modais animados
func _talvez_animar(c: Control) -> void:
	if not is_instance_valid(c) or not c.is_inside_tree() or not c.is_visible_in_tree():
		return
	if _e_do_sistema(c):
		return
	# o pai já está entrando animado: o filho vai junto
	var p := c.get_parent()
	while p != null:
		if _animando.has(p):
			return
		p = p.get_parent()
	# a própria tela já mexe neste painel (escala, giro ou transparência): fica com ela
	if not c.scale.is_equal_approx(Vector2.ONE) or c.modulate.a < 0.99 or c.self_modulate.a < 0.99 or c.rotation != 0.0:
		return
	var tela := get_viewport().get_visible_rect().size
	if c is ColorRect:
		# fundo escuro de modal (cobre a tela): surge em fade
		var cr := c as ColorRect
		if cr.size.x >= tela.x * 0.9 and cr.size.y >= tela.y * 0.9 and cr.color.a > 0.2 and cr.color.a < 1.0 and cr.color.get_luminance() < 0.2:
			_animando[c] = true
			# nada de tela quase preta: o jogo continua aparecendo atrás do modal
			if cr.color.a > 0.60:
				cr.color.a = 0.60
			cr.modulate.a = 0.0
			var tf := c.create_tween()
			tf.tween_property(cr, "modulate:a", 1.0, 0.20)
		return
	if not (c is Panel or c is PanelContainer):
		return
	if c.size.x < 240.0 or c.size.y < 110.0:
		return
	# tela inteira (fundo de tela, não modal) não pula
	if c.size.x >= tela.x * 0.97 and c.size.y >= tela.y * 0.97:
		return
	_animando[c] = true
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2(0.92, 0.92)
	c.modulate.a = 0.0
	var tw := c.create_tween()
	tw.set_parallel(true)
	tw.tween_property(c, "scale", Vector2.ONE, ENTRADA_S).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "modulate:a", 1.0, ENTRADA_S * 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# ----------------------------------------------------------- sem engasgos
## Tudo que o jogo abre mais tarde (imagens, sons, fontes, telas) é lido em
## segundo plano, um arquivo por vez, e guardado: o "load()" das telas acha
## pronto na memória em vez de ir ao armazenamento da TV Box no meio do jogo.
func _montar_fila() -> void:
	for pasta in PASTAS_CACHE:
		var d := DirAccess.open(str(pasta))
		if d == null:
			continue
		for nome in d.get_files():
			# no jogo exportado os arquivos aparecem como "x.png.import" / "x.gd.remap"
			var limpo := nome.trim_suffix(".import").trim_suffix(".remap")
			var ext := limpo.get_extension().to_lower()
			if not (ext in ["png", "jpg", "jpeg", "mp3", "ogg", "wav", "ttf", "otf", "tscn"]):
				continue
			var caminho: String = str(pasta).path_join(limpo)
			if ext == "tscn":
				# as telas trazem o script junto: script só pode ser carregado
				# na linha principal (em segundo plano dá erro de leitura)
				if not _telas.has(caminho) and ResourceLoader.exists(caminho):
					_telas.append(caminho)
				continue
			if not _fila.has(caminho) and ResourceLoader.exists(caminho):
				_fila.append(caminho)


## As telas (e os scripts delas): uma a cada TELA_A_CADA_MS, na linha
## principal, logo no começo - enquanto a abertura mostra "carregando".
const TELA_A_CADA_MS := 220
var _telas: Array[String] = []
var _ultima_tela := 0


func _carregar_tela() -> void:
	if _telas.is_empty():
		return
	var agora := Time.get_ticks_msec()
	if agora - _ultima_tela < TELA_A_CADA_MS:
		return
	_ultima_tela = agora
	var caminho: String = _telas.pop_front()
	var atual := get_tree().current_scene
	if atual != null and atual.scene_file_path == caminho:
		return
	_cache[caminho] = load(caminho)


func _carregar_um() -> void:
	_carregar_tela()
	if _carregando != "":
		var estado := ResourceLoader.load_threaded_get_status(_carregando)
		if estado == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return
		if estado == ResourceLoader.THREAD_LOAD_LOADED:
			_cache[_carregando] = ResourceLoader.load_threaded_get(_carregando)
		_carregando = ""
	if _fila.is_empty():
		if _cache.size() > 0 and not has_meta("avisou"):
			set_meta("avisou", true)
			print("VISUAL: ", _cache.size(), " arquivos na memória (sem engasgo ao trocar de tela)")
		return
	var proximo: String = _fila.pop_front()
	if ResourceLoader.has_cached(proximo):
		_cache[proximo] = load(proximo)
		return
	if ResourceLoader.load_threaded_request(proximo) == OK:
		_carregando = proximo
