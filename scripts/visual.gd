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
const BRILHO_MAX := 14            # tamanho máximo da sombra/neon (antes: até 40+)
const BRILHO_ALFA := 0.62         # o neon fica mais discreto
const BORDA_MAX := 2
const MONTANDO_MS := 450          # a tela nova ainda está se montando: não anima
const ENTRADA_S := 0.26
const PASTAS_CACHE := ["res://fonts", "res://images", "res://fundos", "res://songs", "res://scenes", "res://branding"]
const NOMES_ESTILO := ["panel", "normal", "hover", "pressed", "focus", "disabled", "fill", "background"]

var _cena: Node
var _cena_desde := 0
var _animando := {}               # nó -> true (só neste quadro: o pai anima, o filho não)
var _cache := {}                  # caminho -> recurso (fica na memória)
var _fila: Array[String] = []
var _carregando := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not LIGADO:
		set_process(false)
		return
	get_tree().node_added.connect(_no_novo)
	_montar_fila()


# ------------------------------------------------------------------ quadro
func _process(_delta: float) -> void:
	var cena := get_tree().current_scene
	if cena != _cena:
		_cena = cena
		_cena_desde = Time.get_ticks_msec()
	if not _animando.is_empty():
		_animando.clear()
	_carregar_um()


# ----------------------------------------------------------- painéis limpos
func _no_novo(n: Node) -> void:
	if not (n is Control):
		return
	var c := n as Control
	if _e_do_sistema(c):
		return
	if c is Panel or c is PanelContainer or c is BaseButton or c is ProgressBar or c is LineEdit:
		# o estilo chega logo depois de o nó entrar: afina no fim do quadro e
		# de novo sempre que a tela trocar o estilo (seleção, destaque...)
		_afinar.call_deferred(c)
		if not c.theme_changed.is_connected(_afinar.bind(c)):
			c.theme_changed.connect(_afinar.bind(c))
	if Time.get_ticks_msec() - _cena_desde >= MONTANDO_MS:
		_talvez_animar.call_deferred(c)


func _e_do_sistema(c: Node) -> bool:
	# os avisos e o teclado do próprio sistema (ControleTv, Efeitos, ArduinoBridge)
	var p := c
	while p != null:
		if p == self or p.name in ["ControleTv", "Efeitos", "ArduinoBridge", "Harness"] and p.get_parent() == get_tree().root:
			return true
		p = p.get_parent()
	return false


func _afinar(c: Control) -> void:
	if not is_instance_valid(c):
		return
	for nome in NOMES_ESTILO:
		if not c.has_theme_stylebox_override(nome):
			continue
		var sb := c.get_theme_stylebox(nome)
		if sb is StyleBoxFlat and not sb.has_meta("visual"):
			_afinar_estilo(sb as StyleBoxFlat)


func _afinar_estilo(sb: StyleBoxFlat) -> void:
	sb.set_meta("visual", true)
	sb.anti_aliasing = true
	sb.anti_aliasing_size = 1.0
	sb.corner_detail = 8
	if sb.shadow_size > BRILHO_MAX:
		sb.shadow_size = BRILHO_MAX
		var cor := sb.shadow_color
		sb.shadow_color = Color(cor.r, cor.g, cor.b, cor.a * BRILHO_ALFA)
	for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		if sb.get_border_width(lado) > BORDA_MAX:
			sb.set_border_width(lado, BORDA_MAX)


# ----------------------------------------------------------- modais animados
func _talvez_animar(c: Control) -> void:
	if not is_instance_valid(c) or not c.is_inside_tree() or not c.is_visible_in_tree():
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
			if not _fila.has(caminho) and ResourceLoader.exists(caminho):
				_fila.append(caminho)


func _carregar_um() -> void:
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
