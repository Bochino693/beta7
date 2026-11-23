extends CanvasLayer

## O JOGO INTEIRO PELO CONTROLE REMOTO DA TV BOX / TV ANDROID
## (e pelas setas + ENTER do teclado, no PC).
##
##   OK (centro)      = botão START da máquina; com um botão/campo marcado
##                      na tela (moldura amarela), aperta o que está marcado
##   ◀ ▶              = botão SELECT da máquina (troca ARCADE / COPA)
##   ▲ ▼              = marcam os botões da tela; com um botão marcado as
##                      4 setas andam por eles (VOLTAR desmarca)
##   tela de nomes    = as 4 setas andam pelos campos e botões
##   OK num campo     = abre o TECLADO NA TELA para escrever o nome
##   VOLTAR           = fecha o teclado / volta (o ESC do teclado)
##   MENU             = Central da Máquina (o F9); sem tecla MENU no
##                      controle: VOLTAR 5 vezes seguidas no menu principal
##
## Não depende de mouse, teclado USB nem do teclado do Android: os botões
## são achados na própria tela (qualquer Button visível e os campos de
## nome), então vale para todas as telas, inclusive as novas.

const COR_MARCA := Color(1.0, 0.86, 0.10)
const LINHAS_TECLADO := ["1234567890", "QWERTYUIOP", "ASDFGHJKLÇ", "ZXCVBNM-.&"]
const VOLTAR_PARA_MENU := 5
const VOLTAR_JANELA_MS := 3000

var _alvo: Control                 # botão/campo marcado
var _moldura: Control
var _teclado: Control              # teclado na tela (null = fechado)
var _teclas: Array[Button] = []
var _campo: LineEdit               # campo que o teclado está escrevendo
var _visor: Label
var _start_pelo_ok := false
var _select_pela_seta := false
var _voltar_vezes := 0
var _voltar_desde := 0
var _cena_vista: Node
var _tinha_alvo := false


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_moldura = Control.new()
	_moldura.set_anchors_preset(Control.PRESET_FULL_RECT)
	_moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moldura.draw.connect(_desenhar_moldura)
	add_child(_moldura)
	get_tree().node_added.connect(_no_novo)


func _process(_delta: float) -> void:
	# sempre o último filho da raiz: recebe as teclas antes das telas
	var raiz := get_parent()
	if raiz != null and raiz.get_child(raiz.get_child_count() - 1) != self:
		raiz.move_child(self, -1)
	var cena := get_tree().current_scene
	if cena != _cena_vista:
		_cena_vista = cena
		_alvo = null
		_fechar_teclado()
		_soltar_tudo()
	if _alvo != null and not _vale(_alvo):
		_alvo = null
	# (só redesenha com algo marcado: parado, não gasta nada)
	if _alvo != null or _tinha_alvo:
		_tinha_alvo = _alvo != null
		_moldura.queue_redraw()


# ------------------------------------------------------------------ teclas
func _input(event: InputEvent) -> void:
	var tecla := ""
	var apertou := false
	var eco := false
	if event is InputEventKey:
		apertou = event.pressed
		eco = event.echo
		match event.keycode:
			KEY_UP: tecla = "cima"
			KEY_DOWN: tecla = "baixo"
			KEY_LEFT: tecla = "esq"
			KEY_RIGHT: tecla = "dir"
			KEY_ENTER, KEY_KP_ENTER: tecla = "ok"
			KEY_BACK: tecla = "voltar"
			KEY_MENU: tecla = "menu"
		if tecla == "" and _teclado != null and apertou:
			_tecla_fisica(event)
			return
	elif event is InputEventJoypadButton and OS.get_name() == "Android":
		# controle que o Android entrega como "direcional de joystick"
		apertou = event.pressed
		match event.button_index:
			JOY_BUTTON_DPAD_UP: tecla = "cima"
			JOY_BUTTON_DPAD_DOWN: tecla = "baixo"
			JOY_BUTTON_DPAD_LEFT: tecla = "esq"
			JOY_BUTTON_DPAD_RIGHT: tecla = "dir"
	# aviso do jogo na tela (permissão de abrir ao ligar): OK segue, o resto espera
	if ArduinoBridge.aviso_aberto:
		_consumir()
		if tecla == "ok" and apertou and not eco:
			ArduinoBridge.confirmar_aviso()
		return
	if tecla == "":
		return

	# quem está escrevendo num campo com teclado USB continua como sempre
	if _teclado == null and _escrevendo_no_campo() and tecla in ["esq", "dir", "ok"]:
		return

	match tecla:
		"ok":
			if eco:
				_consumir()
				return
			if not apertou:
				if _start_pelo_ok:
					_start_pelo_ok = false
					_acao("input_start", false)
				return
			if _alvo != null and _vale(_alvo):
				_consumir()
				_apertar(_alvo)
				return
			var lista := _candidatos()
			if _tem_campo(lista):
				# tela de cadastro: o primeiro OK marca o primeiro campo
				_consumir()
				_marcar(lista[0])
				return
			# sem nada marcado: OK = START (a tecla segue para a tela também)
			_start_pelo_ok = true
			_acao("input_start", true)
		"cima", "baixo", "esq", "dir":
			if not apertou:
				if _select_pela_seta and tecla in ["esq", "dir"]:
					_select_pela_seta = false
					_acao("input_cup", false)
				return
			var lista := _candidatos()
			# nada marcado: ◀ ▶ = SELECT (troca ARCADE / COPA); ▲ ▼ começam
			# a andar pelos botões. Em tela de cadastro as 4 setas andam.
			var sem_marca := _alvo == null and _teclado == null and not _tem_campo(lista)
			if lista.is_empty() or (sem_marca and tecla in ["esq", "dir"]):
				if tecla in ["esq", "dir"] and not eco and not _select_pela_seta:
					_select_pela_seta = true
					_acao("input_cup", true)
				return
			_consumir()
			_andar(tecla, lista)
		"voltar":
			if not apertou or eco:
				_consumir()
				return
			_consumir()
			if _teclado != null:
				_fechar_teclado()
				return
			if _alvo != null:
				_alvo = null
			_contar_voltar()
			_tecla_falsa(KEY_ESCAPE)
		"menu":
			_consumir()
			if apertou and not eco:
				_fechar_teclado()
				_tecla_falsa(KEY_F9)


func _consumir() -> void:
	var vp := get_viewport()
	if vp != null:
		vp.set_input_as_handled()


func _acao(acao: String, apertou: bool) -> void:
	if not InputMap.has_action(acao):
		return
	var ev := InputEventAction.new()
	ev.action = acao
	ev.pressed = apertou
	Input.parse_input_event(ev)


func _soltar_tudo() -> void:
	if _start_pelo_ok:
		_start_pelo_ok = false
		_acao("input_start", false)
	if _select_pela_seta:
		_select_pela_seta = false
		_acao("input_cup", false)


func _tecla_falsa(codigo: Key) -> void:
	for p in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = codigo
		ev.physical_keycode = codigo
		ev.pressed = p
		Input.parse_input_event(ev)


## VOLTAR 5 vezes em 3 s = Central da Máquina (controle sem tecla MENU).
func _contar_voltar() -> void:
	var agora := Time.get_ticks_msec()
	if agora - _voltar_desde > VOLTAR_JANELA_MS:
		_voltar_desde = agora
		_voltar_vezes = 0
	_voltar_vezes += 1
	if _voltar_vezes >= VOLTAR_PARA_MENU:
		_voltar_vezes = 0
		_tecla_falsa(KEY_F9)


func _escrevendo_no_campo() -> bool:
	var vp := get_viewport()
	var foco := vp.gui_get_focus_owner() if vp != null else null
	return foco is LineEdit and (foco as LineEdit).is_editing()


# ------------------------------------------------------- botões da tela
func _vale(c: Control) -> bool:
	if c == null or not is_instance_valid(c) or not c.is_inside_tree() or not c.is_visible_in_tree():
		return false
	if c is BaseButton:
		return not (c as BaseButton).disabled
	if c is LineEdit:
		return (c as LineEdit).editable
	return false


func _retangulo(c: Control) -> Rect2:
	return c.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, c.size)


func _camada_de(n: Node) -> int:
	var p := n
	while p != null:
		if p is CanvasLayer:
			return (p as CanvasLayer).layer
		p = p.get_parent()
	return 0


## Todos os botões e campos que dá para apertar agora (visíveis, dentro da
## tela e sem um painel por cima).
func _candidatos() -> Array[Control]:
	var saida: Array[Control] = []
	if _teclado != null:
		for t in _teclas:
			saida.append(t)
		return saida
	var todos: Array[Control] = []
	_juntar(get_tree().root, todos)
	var tela := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	for i in range(todos.size()):
		var c := todos[i]
		if not _vale(c) or c.modulate.a < 0.05:
			continue
		var r := _retangulo(c)
		if r.size.x < 6.0 or r.size.y < 6.0 or not tela.has_point(r.get_center()):
			continue
		if _coberto(c, i, todos):
			continue
		saida.append(c)
	saida.sort_custom(func(a: Control, b: Control) -> bool:
		var pa := _retangulo(a).position
		var pb := _retangulo(b).position
		if absf(pa.y - pb.y) > 12.0:
			return pa.y < pb.y
		return pa.x < pb.x)
	return saida


func _juntar(n: Node, lista: Array[Control]) -> void:
	if n == self:
		return
	if n is Control and (n as Control).is_visible_in_tree():
		lista.append(n)
	for f in n.get_children():
		_juntar(f, lista)


## Tem um painel que barra o mouse por cima do centro deste botão?
func _coberto(c: Control, indice: int, todos: Array[Control]) -> bool:
	var centro := _retangulo(c).get_center()
	var camada := _camada_de(c)
	for j in range(todos.size()):
		var x := todos[j]
		if x == c or x.mouse_filter != Control.MOUSE_FILTER_STOP:
			continue
		var cx := _camada_de(x)
		if cx < camada or (cx == camada and j < indice):
			continue
		if x.is_ancestor_of(c) or c.is_ancestor_of(x):
			continue
		if x is BaseButton or x is LineEdit:
			continue
		if x.modulate.a < 0.05:
			continue
		if _retangulo(x).has_point(centro):
			return true
	return false


func _tem_campo(lista: Array[Control]) -> bool:
	for c in lista:
		if c is LineEdit:
			return true
	return false


func _marcar(c: Control) -> void:
	_alvo = c
	_moldura.queue_redraw()


func _andar(tecla: String, lista: Array[Control]) -> void:
	if _alvo == null or not lista.has(_alvo):
		_marcar(lista[0])
		return
	var d := Vector2.ZERO
	match tecla:
		"cima": d = Vector2.UP
		"baixo": d = Vector2.DOWN
		"esq": d = Vector2.LEFT
		"dir": d = Vector2.RIGHT
	var de := _retangulo(_alvo)
	var melhor: Control = null
	var menor := INF
	for c in lista:
		if c == _alvo:
			continue
		var r := _retangulo(c)
		var o := r.get_center() - de.get_center()
		var frente := o.dot(d)
		if frente < 4.0:
			continue
		var lado := absf(o.dot(Vector2(-d.y, d.x)))
		# quem está na mesma linha/coluna ganha de quem está na diagonal
		var alinhado := (r.position.y < de.end.y and r.end.y > de.position.y) if d.x != 0.0 \
			else (r.position.x < de.end.x and r.end.x > de.position.x)
		var nota := frente + lado * (1.0 if alinhado else 3.0)
		if nota < menor:
			menor = nota
			melhor = c
	if melhor != null:
		_marcar(melhor)


func _apertar(c: Control) -> void:
	if c is LineEdit:
		_abrir_teclado(c)
	elif c is OptionButton:
		var o := c as OptionButton
		if o.item_count > 0:
			var novo := (o.selected + 1) % o.item_count
			o.select(novo)
			o.item_selected.emit(novo)
	elif c is BaseButton:
		var b := c as BaseButton
		if b.toggle_mode:
			b.button_pressed = not b.button_pressed
		b.pressed.emit()


func _desenhar_moldura() -> void:
	if _alvo == null or not _vale(_alvo):
		return
	var r := _retangulo(_alvo).grow(5.0)
	var pulso := 0.75 + 0.25 * sin(Time.get_ticks_msec() / 160.0)
	_moldura.draw_rect(r.grow(3.0), Color(0, 0, 0, 0.55), false, 3.0)
	_moldura.draw_rect(r, Color(COR_MARCA, pulso), false, 4.0)


# -------------------------------------------------------- teclado na tela
## Na TV os campos não chamam o teclado do Android: usam o teclado do jogo.
func _no_novo(n: Node) -> void:
	if n is LineEdit and OS.get_name() == "Android":
		var campo := n as LineEdit
		campo.virtual_keyboard_enabled = false
		campo.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.pressed and _teclado == null and _vale(campo):
				_marcar(campo)
				_abrir_teclado(campo))


func _abrir_teclado(campo: LineEdit) -> void:
	_fechar_teclado()
	_campo = campo
	var tela := get_viewport().get_visible_rect().size
	var escala := clampf(tela.x / 1280.0, 0.8, 2.0)
	var lado := 62.0 * escala
	var vao := 8.0 * escala
	var larg := lado * 10.0 + vao * 9.0 + 40.0 * escala
	var alt := lado * 5.0 + vao * 4.0 + 120.0 * escala

	_teclado = Control.new()
	_teclado.set_anchors_preset(Control.PRESET_FULL_RECT)
	_teclado.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_teclado)
	move_child(_teclado, 0)

	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0, 0, 0, 0.55)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_teclado.add_child(fundo)

	# em cima ou embaixo: nunca por cima do campo que está sendo escrito
	var rc := _retangulo(campo)
	var y := tela.y - alt - 14.0 * escala
	if rc.get_center().y > tela.y * 0.5:
		y = 14.0 * escala
	var painel := Panel.new()
	painel.position = Vector2((tela.x - larg) * 0.5, y)
	painel.size = Vector2(larg, alt)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.03, 0.05, 0.09, 0.98)
	st.border_color = COR_MARCA
	st.set_border_width_all(2)
	st.set_corner_radius_all(int(18 * escala))
	painel.add_theme_stylebox_override("panel", st)
	_teclado.add_child(painel)

	_visor = Label.new()
	_visor.position = Vector2(20.0 * escala, 12.0 * escala)
	_visor.size = Vector2(larg - 40.0 * escala, 56.0 * escala)
	_visor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_visor.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_visor.add_theme_font_size_override("font_size", int(30 * escala))
	painel.add_child(_visor)

	var dica := Label.new()
	dica.text = "SETAS: escolher   •   OK: digitar   •   VOLTAR: fechar"
	dica.position = Vector2(20.0 * escala, alt - 34.0 * escala)
	dica.size = Vector2(larg - 40.0 * escala, 26.0 * escala)
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dica.add_theme_font_size_override("font_size", int(15 * escala))
	dica.add_theme_color_override("font_color", Color(0.6, 0.68, 0.78))
	painel.add_child(dica)

	_teclas.clear()
	var x0 := 20.0 * escala
	var y0 := 76.0 * escala
	for li in range(LINHAS_TECLADO.size()):
		var linha: String = LINHAS_TECLADO[li]
		for ci in range(linha.length()):
			var letra := linha[ci]
			var b := _tecla(letra, Vector2(lado, lado), escala)
			b.position = Vector2(x0 + ci * (lado + vao), y0 + li * (lado + vao))
			b.pressed.connect(_digitar.bind(letra))
			painel.add_child(b)
	var yb := y0 + 4.0 * (lado + vao)
	var especiais := [["ESPAÇO", 3.0, _digitar.bind(" ")], ["⌫ APAGAR", 2.5, _apagar], ["LIMPAR", 2.0, _limpar], ["✔ PRONTO", 2.5, _fechar_teclado]]
	var xb := x0
	for e in especiais:
		var w: float = lado * float(e[1]) + vao * (float(e[1]) - 1.0)
		var b := _tecla(str(e[0]), Vector2(w, lado), escala)
		b.position = Vector2(xb, yb)
		b.pressed.connect(e[2])
		painel.add_child(b)
		xb += w + vao
	_atualizar_visor()
	_marcar(_teclas[10])   # começa no Q


func _tecla(texto: String, tam: Vector2, escala: float) -> Button:
	var b := Button.new()
	b.text = texto
	b.size = tam
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", int((26 if texto.length() == 1 else 17) * escala))
	for estado in ["normal", "hover", "pressed"]:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.10, 0.14, 0.22) if estado == "normal" else Color(0.18, 0.30, 0.48)
		st.border_color = Color(0.25, 0.55, 0.95, 0.8)
		st.set_border_width_all(1)
		st.set_corner_radius_all(int(10 * escala))
		b.add_theme_stylebox_override(estado, st)
	_teclas.append(b)
	return b


func _fechar_teclado() -> void:
	if _teclado == null:
		return
	_teclado.queue_free()
	_teclado = null
	_teclas.clear()
	_visor = null
	_alvo = _campo if _vale(_campo) else null
	_campo = null


func _texto_do_campo(novo: String) -> void:
	if _campo == null or not is_instance_valid(_campo):
		_fechar_teclado()
		return
	if _campo.max_length > 0 and novo.length() > _campo.max_length:
		novo = novo.substr(0, _campo.max_length)
	_campo.text = novo
	_campo.text_changed.emit(novo)
	_campo.caret_column = _campo.text.length()
	_atualizar_visor()


func _digitar(letra: String) -> void:
	if _campo != null and is_instance_valid(_campo):
		_texto_do_campo(_campo.text + letra)


func _apagar() -> void:
	if _campo != null and is_instance_valid(_campo) and _campo.text.length() > 0:
		_texto_do_campo(_campo.text.substr(0, _campo.text.length() - 1))


func _limpar() -> void:
	_texto_do_campo("")


func _atualizar_visor() -> void:
	if _visor == null or _campo == null:
		return
	if _campo.text == "":
		_visor.text = _campo.placeholder_text
		_visor.add_theme_color_override("font_color", Color(0.45, 0.52, 0.62))
	else:
		_visor.text = _campo.text + "▏"
		_visor.add_theme_color_override("font_color", Color.WHITE)


## Com o teclado da tela aberto, um teclado USB também escreve.
func _tecla_fisica(ev: InputEventKey) -> void:
	if ev.keycode == KEY_BACKSPACE:
		_consumir()
		_apagar()
	elif ev.keycode == KEY_ESCAPE:
		_consumir()
		_fechar_teclado()
	elif ev.unicode >= 32:
		_consumir()
		_digitar(String.chr(ev.unicode).to_upper())
