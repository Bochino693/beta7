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
var _clarao: ColorRect
var _tw_clarao: Tween
var _borda: Control
var _ondas: Control
var _lista_ondas: Array = []       # [nascimento_ms, cor]
var _borda_alfa := 0.0
var _tex_luz: Texture2D
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

	_ambiente = _cheio(Control.new())
	add_child(_ambiente)
	_luzes = CPUParticles2D.new()
	_luzes.texture = _tex_luz
	_luzes.material = _aditivo()
	_luzes.amount = 10 if _leve else 22
	_luzes.lifetime = 9.0
	_luzes.preprocess = 9.0
	_luzes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_luzes.direction = Vector2(0.15, -1.0)
	_luzes.spread = 25.0
	_luzes.gravity = Vector2.ZERO
	_luzes.initial_velocity_min = 12.0
	_luzes.initial_velocity_max = 46.0
	_luzes.scale_amount_min = 0.5
	_luzes.scale_amount_max = 1.8
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
	_clarao.visible = false          # um retângulo de tela inteira, mesmo transparente, custa: só existe enquanto pisca
	add_child(_clarao)
	get_viewport().size_changed.connect(_ajustar)
	_ajustar()
	# AQUECE os efeitos do gol fora da tela: a placa de vídeo prepara os
	# desenhos agora, e o primeiro gol da partida não dá engasgo
	_aquecer.call_deferred()


func _aquecer() -> void:
	_criar_canhoes()
	for p in _canhoes:
		p.position = Vector2(-600, -600)
		p.restart()
		p.emitting = true


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
	t.width = 40
	t.height = 40
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


# ------------------------------------------------------------------ quadro
func _process(delta: float) -> void:
	var cena := get_tree().current_scene
	if cena != _cena:
		_cena = cena
		_entrou_tela()
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
	# as luzes de fundo só no nível 0 (placa folgada): numa placa fraca cada
	# camada transparente a mais custa quadros
	_ambiente.visible = visivel and Visual.nivel == 0
	_luzes.emitting = _ambiente.visible
	_luzes.color = Color(_cor_ambiente.r, _cor_ambiente.g, _cor_ambiente.b, 0.16)
	_lista_ondas.clear()
	_borda_alfa = 0.0
	_transicao()


## TRANSIÇÃO DE TELA, como vinheta de transmissão esportiva: a tela nova
## nasce coberta por faixas inclinadas (escuras, com fio na cor da tela) e o
## nome do jogo no meio; as faixas saem correndo para o lado, uma depois da
## outra, e um clarão curto fecha. Meio segundo. De quebra, cobre o instante
## em que a tela nova ainda está se montando.
const FAIXAS := 6
const CORES_FAIXA: Array[Color] = [Color(0.10, 0.66, 0.24), Color(1.0, 0.80, 0.10), Color(0.07, 0.42, 0.90)]
var _faixas: Node2D
var _camada_transicao: CanvasLayer
var _marca: Label


func _transicao() -> void:
	var t := _tela()
	if _faixas != null and is_instance_valid(_faixas):
		_faixas.queue_free()
	# numa camada por cima de TUDO (as telas de carregamento do jogo usam a 900)
	if _camada_transicao == null:
		_camada_transicao = CanvasLayer.new()
		_camada_transicao.layer = 1000
		add_child(_camada_transicao)
	_faixas = Node2D.new()
	_camada_transicao.add_child(_faixas)
	var larg := t.x / FAIXAS
	var tomba := t.y * 0.32            # inclinação das faixas
	for i in range(FAIXAS):
		var f := Polygon2D.new()
		var x0 := i * larg - tomba
		f.polygon = PackedVector2Array([Vector2(x0 + tomba, -4), Vector2(x0 + tomba + larg + 3, -4), Vector2(x0 + larg + 3, t.y + 4), Vector2(x0, t.y + 4)])
		# faixas nas cores do jogo (verde, amarelo, azul), não escuras
		f.color = CORES_FAIXA[i % CORES_FAIXA.size()]
		_faixas.add_child(f)
		var fio := Polygon2D.new()
		fio.polygon = PackedVector2Array([Vector2(x0 + tomba + larg - 3, -4), Vector2(x0 + tomba + larg + 3, -4), Vector2(x0 + larg + 3, t.y + 4), Vector2(x0 + larg - 3, t.y + 4)])
		fio.color = Color(1, 1, 1, 0.9)
		f.add_child(fio)
		var tw := f.create_tween()
		tw.tween_interval(0.16 + 0.035 * (FAIXAS - 1 - i))
		tw.tween_property(f, "position:x", t.x + tomba + larg, 0.40).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# a primeira faixa cobre também a sobra da esquerda
	var canto := Polygon2D.new()
	canto.polygon = PackedVector2Array([Vector2(-4, -4), Vector2(tomba, -4), Vector2(-tomba, t.y + 4), Vector2(-4 - tomba, t.y + 4)])
	canto.color = CORES_FAIXA[0]
	_faixas.get_child(0).add_child(canto)
	# o nome do jogo, no meio, some junto
	if _marca == null:
		_marca = Label.new()
		_marca.text = "OLHO NO LANCE"
		_marca.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_marca.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ResourceLoader.exists("res://fonts/Bungee-Regular.ttf"):
			_marca.add_theme_font_override("font", load("res://fonts/Bungee-Regular.ttf"))
		_marca.add_theme_color_override("font_outline_color", Color(0.02, 0.10, 0.05))
		_camada_transicao.add_child(_marca)
	_camada_transicao.move_child(_marca, -1)
	_marca.add_theme_font_size_override("font_size", int(t.y * 0.085))
	_marca.add_theme_constant_override("outline_size", int(t.y * 0.014))
	_marca.size = Vector2(t.x, t.y * 0.2)
	_marca.position = Vector2(0, t.y * 0.40)
	_marca.pivot_offset = _marca.size * 0.5
	_marca.rotation = deg_to_rad(-4.0)
	_marca.modulate = Color(1, 1, 1, 1)
	_marca.scale = Vector2(0.94, 0.94)
	_marca.visible = true
	var tm := _marca.create_tween()
	tm.set_parallel(true)
	tm.tween_property(_marca, "scale", Vector2(1.04, 1.04), 0.40)
	tm.tween_property(_marca, "modulate:a", 0.0, 0.20).set_delay(0.20)
	var fim := create_tween()
	fim.tween_interval(0.85)
	fim.tween_callback(func() -> void:
		if _faixas != null and is_instance_valid(_faixas):
			_faixas.queue_free()
		_faixas = null
		if _marca != null:
			_marca.visible = false)
	# o clarão na cor da tela, quando as faixas estão saindo
	get_tree().create_timer(0.30, true, false, true).timeout.connect(_piscar.bind(_cor_ambiente, 0.20, 0.55))


func _piscar(cor: Color, forca: float, tempo: float) -> void:
	_clarao.color = Color(cor.r, cor.g, cor.b, forca)
	_clarao.visible = true
	if _tw_clarao != null and _tw_clarao.is_valid():
		_tw_clarao.kill()
	_tw_clarao = create_tween()
	_tw_clarao.tween_property(_clarao, "color:a", 0.0, tempo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tw_clarao.tween_callback(func() -> void: _clarao.visible = false)


# -------------------------------------------------------------------- gol
## O GOL, NA COR DE QUEM MARCOU (as telas de partida chamam a cada gol e
## passam a cor do jogador; sem a cor, vale a do número do jogador):
##   - a moldura da tela acende na cor do jogador e apaga suave (luz de
##     estádio) - sem clarão cobrindo a tela inteira;
##   - duas chuvas de papel picado sobem dos cantos de baixo: cor do
##     jogador, branco e a cor mais clara.
## Nada é criado na hora do gol: os dois "canhões" de papel já existem e só
## disparam de novo (sem engasgo), e a moldura são 8 retângulos.
var _canhoes: Array[CPUParticles2D] = []
var _rampas: Array[Gradient] = []
var _borda_cor := Color(1.0, 0.12, 0.12)


func gol(jogador: int = 0, cor_do_jogador: Variant = null) -> void:
	if not LIGADO:
		return
	var cor: Color = CORES_JOGADOR[posmod(jogador, CORES_JOGADOR.size())]
	if cor_do_jogador is Color:
		cor = cor_do_jogador
	# (uma cor viva, mesmo que a do jogador seja escura)
	if cor.v < 0.75:
		cor.v = 0.75
	_borda_cor = cor
	_borda_alfa = 0.85
	_borda.queue_redraw()
	_confete(cor)


## Bola em alvo apagado.
func erro() -> void:
	if not LIGADO:
		return
	_borda_cor = Color(1.0, 0.12, 0.12)
	_borda_alfa = 0.55
	_borda.queue_redraw()


func _criar_canhoes() -> void:
	for lado in [-1.0, 1.0]:
		var p := CPUParticles2D.new()
		p.one_shot = true
		p.emitting = false
		p.amount = 20 if _leve else 36
		p.lifetime = 1.6
		p.explosiveness = 0.92
		p.direction = Vector2(0.55 * lado, -1.0)
		p.spread = 26.0
		p.angle_min = 0.0
		p.angle_max = 360.0
		p.angular_velocity_min = -520.0
		p.angular_velocity_max = 520.0
		var g := Gradient.new()
		g.set_color(0, Color.WHITE)
		g.add_point(0.4, Color.WHITE)
		g.set_color(g.get_point_count() - 1, Color.WHITE)
		p.color_initial_ramp = g
		var some := Gradient.new()
		some.set_color(0, Color(1, 1, 1, 1))
		some.add_point(0.75, Color(1, 1, 1, 1))
		some.set_color(some.get_point_count() - 1, Color(1, 1, 1, 0))
		p.color_ramp = some
		add_child(p)
		move_child(p, _ondas.get_index())
		_canhoes.append(p)
		_rampas.append(g)


func _confete(cor: Color) -> void:
	if _canhoes.is_empty():
		_criar_canhoes()
	var t := _tela()
	var escala := t.x / 1280.0
	for i in range(_canhoes.size()):
		var lado: float = -1.0 if i == 0 else 1.0
		var p := _canhoes[i]
		p.position = Vector2(t.x * (0.5 - 0.42 * lado), t.y * 1.02)
		p.initial_velocity_min = 620.0 * escala
		p.initial_velocity_max = 1150.0 * escala
		p.gravity = Vector2(0, 1250.0 * escala)
		p.scale_amount_min = 7.0 * escala
		p.scale_amount_max = 15.0 * escala
		var g := _rampas[i]
		g.set_color(0, cor)
		g.set_color(1, Color.WHITE)
		g.set_color(2, cor.lightened(0.45))
		p.restart()
		p.emitting = true


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
	# duas molduras, a de fora forte e a de dentro fraca: parece luz, não tarja
	for passo in range(2):
		var g: float = t.y * (0.022 if passo == 0 else 0.05)
		var cor := Color(_borda_cor.r, _borda_cor.g, _borda_cor.b, _borda_alfa * (0.75 if passo == 0 else 0.30))
		_borda.draw_rect(Rect2(0, 0, t.x, g), cor)
		_borda.draw_rect(Rect2(0, t.y - g, t.x, g), cor)
		_borda.draw_rect(Rect2(0, g, g, t.y - 2.0 * g), cor)
		_borda.draw_rect(Rect2(t.x - g, g, g, t.y - 2.0 * g), cor)


# ------------------------------------------------------- resultado final
## A APRESENTAÇÃO DO RESULTADO, como nos jogos de futebol de console: as
## telas de partida montam o modal do resultado do jeito delas e chamam
## Efeitos.apresentar(painel, cor_do_vencedor). Aqui ele ganha a entrada:
##   - o fundo deixa de ser preto: escurece na COR do vencedor e um halo de
##     luz acende atrás do painel;
##   - o painel sobe do rodapé e assenta;
##   - cada linha (título, colocados, vencedor, dica) entra na sua vez,
##     alternando da esquerda e da direita;
##   - um reflexo de luz atravessa o painel uma vez.
## Tudo com 1 textura pequena e poucos "tweens": nada pesa na TV Box.
var _tex_halo: Texture2D


func apresentar(painel: Control, cor: Color = COR_PADRAO) -> void:
	if not LIGADO or painel == null or not is_instance_valid(painel) or not painel.is_inside_tree():
		return
	var pai := painel.get_parent()
	var tela := _tela()
	if cor.v < 0.7:
		cor.v = 0.7

	# 1. o fundo escuro vira "noite" na cor do vencedor
	if pai != null:
		for irmao in pai.get_children():
			if irmao is ColorRect and irmao != painel:
				var cr := irmao as ColorRect
				if cr.size.x >= tela.x * 0.9 and cr.size.y >= tela.y * 0.9 and cr.color.get_luminance() < 0.1:
					var tf := cr.create_tween()
					tf.tween_interval(0.30)
					tf.tween_property(cr, "color", Color(cor.r * 0.16, cor.g * 0.16, cor.b * 0.16 + 0.03, 0.78), 0.6)
					break

	# 2. o halo de luz atrás do painel
	if pai != null:
		if _tex_halo == null:
			_tex_halo = _textura_luz()
		var halo := TextureRect.new()
		halo.texture = _tex_halo
		halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		halo.stretch_mode = TextureRect.STRETCH_SCALE
		halo.size = painel.size * Vector2(1.9, 2.1)
		halo.position = painel.position + painel.size * 0.5 - halo.size * 0.5
		halo.pivot_offset = halo.size * 0.5
		halo.modulate = Color(cor.r, cor.g, cor.b, 0.0)
		halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pai.add_child(halo)
		pai.move_child(halo, painel.get_index())
		var th := halo.create_tween()
		th.tween_property(halo, "modulate:a", 0.55, 0.5)
		var respira := halo.create_tween()
		respira.set_loops()
		respira.tween_property(halo, "scale", Vector2(1.08, 1.08), 1.8).set_trans(Tween.TRANS_SINE)
		respira.tween_property(halo, "scale", Vector2.ONE, 1.8).set_trans(Tween.TRANS_SINE)

	# 3. o painel sobe e assenta
	var destino := painel.position
	painel.position = destino + Vector2(0, tela.y * 0.10)
	var tp := painel.create_tween()
	tp.tween_property(painel, "position", destino, 0.55).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	# 4. cada linha na sua vez, alternando os lados
	var ordem := 0
	for filho in painel.get_children():
		if not (filho is Control) or not (filho as Control).visible:
			continue
		var c := filho as Control
		if c.size.x >= painel.size.x * 0.9 and c.size.y >= painel.size.y * 0.9:
			continue   # (imagem / escurecimento de fundo do painel)
		if c.size.y < 6.0 or c.modulate.a < 0.99:
			continue   # (fios separadores e o que a tela já anima)
		var lado: float = -1.0 if ordem % 2 == 0 else 1.0
		var fim := c.position
		c.position = fim + Vector2(46.0 * lado, 0)
		c.modulate.a = 0.0
		var espera: float = 0.22 + 0.07 * mini(ordem, 12)
		var tl := c.create_tween()
		tl.set_parallel(true)
		tl.tween_property(c, "position", fim, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(espera)
		tl.tween_property(c, "modulate:a", 1.0, 0.24).set_delay(espera)
		ordem += 1

	# 5. o reflexo que atravessa o painel
	var mascara := Control.new()
	mascara.position = Vector2(8, 8)
	mascara.size = painel.size - Vector2(16, 16)
	mascara.clip_contents = true
	mascara.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(mascara)
	var reflexo := TextureRect.new()
	reflexo.texture = _textura_feixe()
	reflexo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reflexo.stretch_mode = TextureRect.STRETCH_SCALE
	reflexo.size = Vector2(painel.size.x * 0.22, painel.size.y * 1.8)
	reflexo.rotation = 0.35
	reflexo.material = _aditivo()
	reflexo.modulate = Color(1, 1, 1, 0.16)
	reflexo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reflexo.position = Vector2(-painel.size.x * 0.4, -painel.size.y * 0.4)
	mascara.add_child(reflexo)
	var tr := reflexo.create_tween()
	tr.tween_interval(0.75)
	tr.tween_property(reflexo, "position:x", painel.size.x * 1.25, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tr.tween_callback(mascara.queue_free)
