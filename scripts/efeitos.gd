extends CanvasLayer

## VIDA NAS TELAS (vale para o jogo inteiro, sem mexer na lógica das telas):
##   * transição: cada tela entra com um clarão que se abre (não "pula");
##   * ambiente: luzes de estádio varrendo e partículas de luz subindo,
##     na cor da tela (menu verde/dourado, partida azul, copa dourada);
##   * GOL: clarão na cor do jogador, onda de choque e chuva de confete
##     (as telas de partida chamam Efeitos.gol(jogador));
##   * ERRO: a borda da tela pisca vermelha (Efeitos.erro()).
## Tudo leve (GL Compatibility, TV Box): poucas partículas, sem shader.
## Para desligar tudo: LIGADO = false.

const LIGADO := true
const CORES_JOGADOR: Array[Color] = [
	Color(0.15, 0.55, 1.0),   # player 1 azul
	Color(0.20, 0.95, 0.35),  # player 2 verde
	Color(1.0, 0.22, 0.22),   # player 3 vermelho
	Color(1.0, 0.85, 0.10),   # player 4 amarelo
]
const COR_PADRAO := Color(0.20, 0.75, 1.0)
const COR_COPA := Color(1.0, 0.80, 0.15)
const COR_MENU := Color(0.35, 1.0, 0.45)

var _cena: Node
var _ambiente: Control
var _luzes: CPUParticles2D
var _feixes: Array[TextureRect] = []
var _cortina: ColorRect
var _clarao: ColorRect
var _borda: Control
var _ondas: Control
var _lista_ondas: Array = []       # [nascimento_ms, cor]
var _borda_alfa := 0.0
var _tex_luz: Texture2D
var _tex_feixe: Texture2D
var _cor_ambiente := COR_PADRAO
var _leve := false


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not LIGADO:
		set_process(false)
		return
	_leve = OS.get_name() == "Android"
	_tex_luz = _textura_luz()
	_tex_feixe = _textura_feixe()

	_ambiente = _cheio(Control.new())
	add_child(_ambiente)
	for i in range(2):
		var f := TextureRect.new()
		f.texture = _tex_feixe
		f.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		f.stretch_mode = TextureRect.STRETCH_SCALE
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f.material = _aditivo()
		_ambiente.add_child(f)
		_feixes.append(f)
	_luzes = CPUParticles2D.new()
	_luzes.texture = _tex_luz
	_luzes.material = _aditivo()
	_luzes.amount = 14 if _leve else 34
	_luzes.lifetime = 9.0
	_luzes.preprocess = 9.0
	_luzes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_luzes.direction = Vector2(0.15, -1.0)
	_luzes.spread = 25.0
	_luzes.gravity = Vector2.ZERO
	_luzes.initial_velocity_min = 12.0
	_luzes.initial_velocity_max = 46.0
	_luzes.scale_amount_min = 0.25
	_luzes.scale_amount_max = 1.1
	var some := Gradient.new()
	some.set_color(0, Color(1, 1, 1, 0.0))
	some.add_point(0.25, Color(1, 1, 1, 1.0))
	some.add_point(0.75, Color(1, 1, 1, 1.0))
	some.set_color(some.get_point_count() - 1, Color(1, 1, 1, 0.0))
	_luzes.color_ramp = some
	_ambiente.add_child(_luzes)

	_ondas = _cheio(Control.new())
	_ondas.draw.connect(_desenhar_ondas)
	add_child(_ondas)
	_borda = _cheio(Control.new())
	_borda.draw.connect(_desenhar_borda)
	add_child(_borda)
	_clarao = _cheio(ColorRect.new())
	_clarao.color = Color(1, 1, 1, 0)
	_clarao.material = _aditivo()
	add_child(_clarao)
	_cortina = _cheio(ColorRect.new())
	_cortina.color = Color(0, 0, 0, 0)
	add_child(_cortina)
	get_viewport().size_changed.connect(_ajustar)
	_ajustar()
	# AQUECE os efeitos do gol fora da tela: a placa de vídeo prepara os
	# desenhos agora, e o primeiro gol da partida não dá engasgo
	_aquecer.call_deferred()


func _aquecer() -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.amount = 4
	p.lifetime = 0.3
	p.position = Vector2(-400, -400)
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.0, true, false, true).timeout.connect(p.queue_free)
	_lista_ondas.append([Time.get_ticks_msec() - 640, Color(0, 0, 0, 0)])
	_ondas.queue_redraw()


func _cheio(c: Control) -> Control:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _aditivo() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


func _textura_luz() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.9))
	g.add_point(0.35, Color(1, 1, 1, 0.28))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0.0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 96
	t.height = 96
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


func _textura_feixe() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.0))
	g.add_point(0.5, Color(1, 1, 1, 1.0))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0.0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 128
	t.height = 4
	return t


func _tela() -> Vector2:
	return get_viewport().get_visible_rect().size


func _ajustar() -> void:
	if _luzes == null:
		return
	var t := _tela()
	_luzes.position = t * 0.5
	_luzes.emission_rect_extents = t * 0.55
	for f in _feixes:
		f.size = Vector2(t.x * 0.34, t.y * 2.2)
		f.pivot_offset = f.size * 0.5
		f.rotation = deg_to_rad(24.0)


# ------------------------------------------------------------------ quadro
func _process(delta: float) -> void:
	var cena := get_tree().current_scene
	if cena != _cena:
		_cena = cena
		_entrou_tela()
	# feixes de luz de estádio varrendo devagar
	var t := _tela()
	var agora := Time.get_ticks_msec() / 1000.0
	for i in range(_feixes.size()):
		var f := _feixes[i]
		var fase := fmod(agora * (0.045 + 0.02 * i) + 0.5 * i, 1.0)
		f.position = Vector2(lerpf(-t.x * 0.5, t.x * 1.15, fase), -t.y * 0.6)
		var brilho := sin(fase * PI)
		f.modulate = Color(_cor_ambiente.r, _cor_ambiente.g, _cor_ambiente.b, 0.085 * brilho)
	if not _lista_ondas.is_empty():
		_ondas.queue_redraw()
	if _borda_alfa > 0.0:
		_borda_alfa = maxf(0.0, _borda_alfa - delta * 2.2)
		_borda.queue_redraw()


func _entrou_tela() -> void:
	var nome := ""
	if _cena != null:
		nome = _cena.scene_file_path.get_file().get_basename()
	var visivel := true
	match nome:
		"opening":
			_cor_ambiente = COR_MENU
			# na TV Box o vídeo da abertura já é o movimento da tela: o
			# processador fica todo para ele
			visivel = not _leve
		"play", "torment_play":
			_cor_ambiente = COR_PADRAO
		"cup_play", "cup_lobby", "lobby", "cup_setup_36", "champions_wall", "champions_ranking":
			_cor_ambiente = COR_COPA
		"config", "teste_serial":
			visivel = false
		_:
			_cor_ambiente = COR_PADRAO
	_ambiente.visible = visivel
	_luzes.color = Color(_cor_ambiente.r, _cor_ambiente.g, _cor_ambiente.b, 0.16)
	_lista_ondas.clear()
	_borda_alfa = 0.0
	# a tela nova abre do escuro, com um clarão curto na cor dela
	_cortina.color = Color(0, 0, 0, 1)
	var tw := create_tween()
	tw.tween_property(_cortina, "color:a", 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_piscar(_cor_ambiente, 0.16, 0.6)


func _piscar(cor: Color, forca: float, tempo: float) -> void:
	_clarao.color = Color(cor.r, cor.g, cor.b, forca)
	var tw := create_tween()
	tw.tween_property(_clarao, "color:a", 0.0, tempo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# -------------------------------------------------------------------- gol
## As telas de partida chamam a cada gol (jogador 0..3 dá a cor).
func gol(jogador: int = 0) -> void:
	if not LIGADO:
		return
	var cor: Color = CORES_JOGADOR[posmod(jogador, CORES_JOGADOR.size())]
	_piscar(cor, 0.30, 0.45)
	_lista_ondas.append([Time.get_ticks_msec(), cor])
	_ondas.queue_redraw()
	_confete(cor)


## Bola em alvo apagado.
func erro() -> void:
	if not LIGADO:
		return
	_borda_alfa = 0.55
	_borda.queue_redraw()


func _confete(cor: Color) -> void:
	var t := _tela()
	var escala := t.x / 1280.0
	for lado in [-1.0, 1.0]:
		var p := CPUParticles2D.new()
		p.one_shot = true
		p.emitting = false
		p.amount = 22 if _leve else 40
		p.lifetime = 1.7
		p.explosiveness = 0.92
		p.position = Vector2(t.x * (0.5 - 0.42 * lado), t.y * 1.02)
		p.direction = Vector2(0.55 * lado, -1.0)
		p.spread = 26.0
		p.initial_velocity_min = 620.0 * escala
		p.initial_velocity_max = 1150.0 * escala
		p.gravity = Vector2(0, 1250.0 * escala)
		p.angle_min = 0.0
		p.angle_max = 360.0
		p.angular_velocity_min = -520.0
		p.angular_velocity_max = 520.0
		p.scale_amount_min = 7.0 * escala
		p.scale_amount_max = 15.0 * escala
		var g := Gradient.new()
		g.set_color(0, cor)
		g.add_point(0.35, Color.WHITE)
		g.add_point(0.65, cor.lightened(0.35))
		g.set_color(g.get_point_count() - 1, Color(1.0, 0.85, 0.2))
		p.color_initial_ramp = g
		var some := Gradient.new()
		some.set_color(0, Color(1, 1, 1, 1))
		some.add_point(0.75, Color(1, 1, 1, 1))
		some.set_color(some.get_point_count() - 1, Color(1, 1, 1, 0))
		p.color_ramp = some
		add_child(p)
		move_child(p, _ondas.get_index())
		p.emitting = true
		get_tree().create_timer(p.lifetime + 0.4, true, false, true).timeout.connect(p.queue_free)


func _desenhar_ondas() -> void:
	var agora := Time.get_ticks_msec()
	var t := _tela()
	var centro := t * 0.5
	var vivas: Array = []
	for o in _lista_ondas:
		var k := float(agora - int(o[0])) / 650.0
		if k >= 1.0:
			continue
		vivas.append(o)
		var cor: Color = o[1]
		var raio := lerpf(t.y * 0.12, t.x * 0.62, 1.0 - pow(1.0 - k, 3.0))
		var alfa := (1.0 - k) * 0.75
		_ondas.draw_arc(centro, raio, 0.0, TAU, 72, Color(cor.r, cor.g, cor.b, alfa), 14.0 * (1.0 - k) + 3.0, true)
		_ondas.draw_arc(centro, raio * 0.82, 0.0, TAU, 72, Color(1, 1, 1, alfa * 0.45), 4.0, true)
	_lista_ondas = vivas


func _desenhar_borda() -> void:
	if _borda_alfa <= 0.0:
		return
	var t := _tela()
	var g := t.y * 0.045
	var cor := Color(1.0, 0.12, 0.12, _borda_alfa)
	_borda.draw_rect(Rect2(0, 0, t.x, g), cor)
	_borda.draw_rect(Rect2(0, t.y - g, t.x, g), cor)
	_borda.draw_rect(Rect2(0, g, g, t.y - 2.0 * g), cor)
	_borda.draw_rect(Rect2(t.x - g, g, g, t.y - 2.0 * g), cor)
