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
##                      controle: VOLTAR 5 vezes seguidas no menu principal.
##                      No teclado: F9 ou F1 (sempre com o menu principal na tela)
##
## MOUSE (para quem quiser mexer com ele): o jogo tem o SEU cursor, igual em
## todas as telas, no PC e na TV Box. Ele aparece quando o mouse mexe e some
## sozinho depois de uns segundos parado (na partida não fica seta na tela).
## Clicar num campo de cadastro abre o teclado da tela.
##
## Não depende de mouse, teclado USB nem do teclado do Android: os botões
## são achados na própria tela (qualquer Button visível e os campos de
## nome), então vale para todas as telas, inclusive as novas.

const COR_MARCA := Color(1.0, 0.86, 0.10)
const LINHAS_TECLADO := ["1234567890", "QWERTYUIOP", "ASDFGHJKLÇ", "ZXCVBNM-.&"]
# Teclados próprios para o campo (campo.set_meta("teclado", "email" / "numero")):
const LINHAS_EMAIL := ["1234567890", "qwertyuiop", "asdfghjkl@", "zxcvbnm._-"]
const ATALHOS_EMAIL := ["@gmail.com", "@hotmail.com", "@outlook.com", "@yahoo.com.br"]
const LINHAS_NUMERO := ["1234567890"]

## O teclado da tela fechou: pronto = true pelo botão PRONTO (ou ENTER / TAB
## de um teclado USB); false pelo VOLTAR. Quem monta um formulário usa isto
## para pular sozinho para o próximo campo.
signal teclado_fechou(campo: LineEdit, pronto: bool)
const VOLTAR_PARA_MENU := 5
const VOLTAR_JANELA_MS := 3000

var _alvo: Control                 # botão/campo marcado
var _moldura: Control
var _teclado: Control              # teclado na tela (null = fechado)
var _teclas: Array[Button] = []
var _campo: LineEdit               # campo que o teclado está escrevendo
var _modo_teclado := ""            # "" (nomes), "email" ou "numero"
var _fisico := false               # a última letra veio de um teclado USB
var _visor: Label
var _start_pelo_ok := false
var _select_pela_seta := false
var _voltar_vezes := 0
var _voltar_desde := 0
var _cena_vista: Node
var _tinha_alvo := false
var _conferir_alvo := 0.0

# o cursor do jogo
const MOUSE_SOME_MS := 6000
var _cursor: Control
var _mouse_pos := Vector2.ZERO
var _mouse_visto_ms := -100000
var _mouse_apertado := false


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_moldura = Control.new()
	_moldura.set_anchors_preset(Control.PRESET_FULL_RECT)
	_moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moldura.draw.connect(_desenhar_moldura)
	add_child(_moldura)
	_cursor = Control.new()
	_cursor.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor.z_index = 100
	_cursor.visible = false
	_cursor.draw.connect(_desenhar_cursor)
	add_child(_cursor)
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
	# abriu um painel por cima do botão marcado: a marca sai (o OK nunca
	# aperta um botão que ficou atrás)
	if _alvo != null:
		_conferir_alvo -= _delta
		if _conferir_alvo <= 0.0:
			_conferir_alvo = 0.2
			if not _candidatos().has(_alvo):
				_alvo = null
	_quadro_do_cursor()
	# (só redesenha com algo marcado: parado, não gasta nada)
	if _alvo != null or _tinha_alvo:
		_tinha_alvo = _alvo != null
		_moldura.queue_redraw()


# ------------------------------------------------------------------ teclas
func _input(event: InputEvent) -> void:
	var tecla := ""
	var apertou := false
	var eco := false
	if event is InputEventMouse:
		_mouse_mexeu(event)
		return
	# a ficha do Modo Feira está na tela: VOLTAR / ESC é dela (com o teclado
	# fechado) e qualquer tecla conta como "tem gente aqui"
	if Leads.ficha_aberta() and (event is InputEventKey or event is InputEventJoypadButton):
		Leads.tocou()
		if _teclado == null and event is InputEventKey and event.keycode in [KEY_BACK, KEY_ESCAPE]:
			_consumir()
			if event.pressed and not event.echo:
				Leads.voltar()
			return
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
			KEY_MENU, KEY_F1: tecla = "menu"   # (F1 = o mesmo que o F9, para tecladinhos)
		if _teclado != null and apertou and event.keycode == KEY_TAB:
			# teclado USB: TAB = pronto, próximo campo
			_consumir()
			if not eco:
				_fechar_teclado(true)
			return
		if tecla == "" and _teclado != null and apertou:
			_tecla_fisica(event)
			return
	elif event is InputEventJoypadButton and OS.get_name() == "Android" and not ArduinoBridge.tem_mapa and not ArduinoBridge.ensinando:
		# controle que o Android entrega como "direcional de joystick"
		apertou = event.pressed
		match event.button_index:
			JOY_BUTTON_DPAD_UP: tecla = "cima"
			JOY_BUTTON_DPAD_DOWN: tecla = "baixo"
			JOY_BUTTON_DPAD_LEFT: tecla = "esq"
			JOY_BUTTON_DPAD_RIGHT: tecla = "dir"
	# a Central da Máquina está "ensinando" as entradas: ela recebe tudo
	if ArduinoBridge.ensinando:
		return
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
			if _teclado != null and _fisico:
				# quem está escrevendo num teclado USB: ENTER = pronto
				_consumir()
				_fechar_teclado(true)
				return
			var lista := _candidatos()
			var atras := _alvo != null and not lista.has(_alvo)
			if atras:
				# um painel abriu por cima do botão marcado: ele não é apertado
				_alvo = null
			if _alvo != null and _vale(_alvo):
				_consumir()
				_apertar(_alvo)
				return
			if atras and not lista.is_empty():
				_consumir()
				_marcar(lista[0])
				return
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
			_fisico = false
			_andar(tecla, lista)
		"voltar":
			if not apertou or eco:
				_consumir()
				return
			_consumir()
			_voltar_tecla_ms = Time.get_ticks_msec()
			_voltar()
		"menu":
			_consumir()
			if apertou and not eco:
				_fechar_teclado()
				_tecla_falsa(KEY_F9)


var _voltar_tecla_ms := -100000


func _voltar() -> void:
	if _teclado != null:
		_fechar_teclado()
		return
	if Leads.ficha_aberta():
		Leads.voltar()
		return
	if _alvo != null:
		_alvo = null
	_contar_voltar()
	_tecla_falsa(KEY_ESCAPE)


## Alguns controles / versões do Android entregam o VOLTAR só como "pedido de
## voltar" (sem a tecla): vale igual (sem contar duas vezes).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and Time.get_ticks_msec() - _voltar_tecla_ms > 250:
		_voltar_tecla_ms = Time.get_ticks_msec()
		_voltar()


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
		if _coberto(c, i, todos) or _escondido_no_rolo(c):
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


## ANDAR PELOS BOTÕES, DO JEITO QUE A PESSOA ESPERA:
##   ▲ ▼  vão para a FILEIRA mais próxima acima / abaixo e, nela, para o
##        botão mais alinhado com o que está marcado;
##   ◀ ▶  andam DENTRO da fileira (o vizinho do lado); só se não houver
##        vizinho na fileira é que valem os botões em diagonal.
## Nunca pula para um botão que não está do lado de lá da borda do marcado
## (era o que fazia a marca "fugir" para a linha de cima ou de baixo).
func _andar(tecla: String, lista: Array[Control]) -> void:
	if _alvo == null or not lista.has(_alvo):
		_marcar(lista[0])
		return
	# dentro de uma lista que rola (os eventos da Central): ▲ ▼ andam pelas
	# linhas dela, inclusive as que ainda estão escondidas - a lista rola junto
	var rolo := _rolo_de(_alvo)
	if rolo != null and tecla in ["cima", "baixo"]:
		var da_lista: Array[Control] = []
		_juntar_apertaveis(rolo, da_lista)
		var na_lista := _escolher(tecla, da_lista)
		if na_lista != null:
			rolo.ensure_control_visible(na_lista)
			_marcar(na_lista)
			return
	var melhor := _escolher(tecla, lista)
	if melhor != null:
		_marcar(melhor)


func _rolo_de(c: Control) -> ScrollContainer:
	var p := c.get_parent()
	while p != null:
		if p is ScrollContainer:
			return p
		p = p.get_parent()
	return null


func _juntar_apertaveis(n: Node, lista: Array[Control]) -> void:
	for f in n.get_children():
		if f is Control and _vale(f):
			lista.append(f)
		_juntar_apertaveis(f, lista)


## Está numa lista que rola e ficou para fora da parte que aparece?
func _escondido_no_rolo(c: Control) -> bool:
	var rolo := _rolo_de(c)
	return rolo != null and not _retangulo(rolo).has_point(_retangulo(c).get_center())


## O botão para onde a seta leva, saindo do marcado (null = não tem).
func _escolher(tecla: String, lista: Array[Control]) -> Control:
	var de := _retangulo(_alvo)
	var horizontal := tecla in ["esq", "dir"]
	var achados: Array = []      # [botão, além da borda, ao lado (centros), sobrepõe]
	for c in lista:
		if c == _alvo:
			continue
		var r := _retangulo(c)
		var alem := 0.0
		match tecla:
			"dir": alem = r.position.x - de.end.x
			"esq": alem = de.position.x - r.end.x
			"baixo": alem = r.position.y - de.end.y
			"cima": alem = de.position.y - r.end.y
		if alem < -8.0:
			continue
		var o := r.get_center() - de.get_center()
		var lado := absf(o.y) if horizontal else absf(o.x)
		var sobrepoe: bool = (minf(r.end.y, de.end.y) - maxf(r.position.y, de.position.y) > 4.0) if horizontal \
			else (minf(r.end.x, de.end.x) - maxf(r.position.x, de.position.x) > 4.0)
		achados.append([c, maxf(alem, 0.0), lado, sobrepoe])
	if achados.is_empty():
		return null
	var melhor: Control = null
	var menor := INF
	if horizontal:
		# o vizinho da mesma fileira (sem vizinho, a marca fica onde está:
		# para trocar de fileira use ▲ ▼)
		for a in achados:
			if a[3] and float(a[1]) + float(a[2]) * 0.01 < menor:
				menor = float(a[1]) + float(a[2]) * 0.01
				melhor = a[0]
	else:
		# a fileira mais próxima; nela, quem está embaixo / em cima do marcado
		var perto := INF
		for a in achados:
			perto = minf(perto, float(a[1]))
		for a in achados:
			if float(a[1]) > perto + 26.0:
				continue
			var nota: float = float(a[2]) - (100000.0 if a[3] else 0.0)
			if nota < menor:
				menor = nota
				melhor = a[0]
	return melhor


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
## No PC vale para os campos de cadastro (os que dizem qual teclado querem):
## um clique do mouse abre o teclado da tela, e o teclado USB também escreve.
func _no_novo(n: Node) -> void:
	if n is LineEdit:
		var campo := n as LineEdit
		var na_tv := OS.get_name() == "Android"
		if na_tv:
			campo.virtual_keyboard_enabled = false
		campo.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and _teclado == null and _vale(campo) \
					and (na_tv or campo.has_meta("teclado") or campo.has_meta("titulo")):
				_marcar(campo)
				_abrir_teclado(campo))


## Para quem monta um formulário (a ficha do Modo Feira): abrir o teclado
## num campo e marcar um botão sem esperar as setas.
func abrir_teclado(campo: LineEdit) -> void:
	if _vale(campo):
		_abrir_teclado(campo)


func marcar(c: Control) -> void:
	if _teclado == null and _vale(c):
		_marcar(c)


func teclado_aberto() -> bool:
	return _teclado != null


func fechar_teclado() -> void:
	_fechar_teclado()


func _abrir_teclado(campo: LineEdit) -> void:
	_fechar_teclado()
	_campo = campo
	_fisico = false
	_modo_teclado = str(campo.get_meta("teclado", ""))
	var titulo := str(campo.get_meta("titulo", ""))
	var linhas: Array = LINHAS_TECLADO
	var atalhos: Array = []
	var especiais: Array = [["ESPAÇO", 3.0, _digitar.bind(" ")], ["⌫ APAGAR", 2.5, _apagar], ["LIMPAR", 2.0, _limpar], ["✔ PRONTO", 2.5, _fechar_teclado.bind(true)]]
	var tela := get_viewport().get_visible_rect().size
	var escala := clampf(tela.x / 1280.0, 0.8, 2.0)
	var lado := 62.0 * escala
	match _modo_teclado:
		"email":
			linhas = LINHAS_EMAIL
			atalhos = ATALHOS_EMAIL
			lado = 56.0 * escala
			especiais = [[".com", 1.5, _digitar.bind(".com")], [".com.br", 2.0, _digitar.bind(".com.br")], ["⌫ APAGAR", 2.5, _apagar], ["LIMPAR", 1.5, _limpar], ["✔ PRONTO", 2.5, _fechar_teclado.bind(true)]]
		"numero":
			linhas = LINHAS_NUMERO
			especiais = [["⌫ APAGAR", 3.5, _apagar], ["LIMPAR", 3.0, _limpar], ["✔ PRONTO", 3.5, _fechar_teclado.bind(true)]]
	var vao := 8.0 * escala
	var topo := (76.0 + (30.0 if titulo != "" else 0.0)) * escala
	var fileiras := linhas.size() + (1 if not atalhos.is_empty() else 0) + 1
	var larg := lado * 10.0 + vao * 9.0 + 40.0 * escala
	var alt := topo + fileiras * (lado + vao) + 36.0 * escala

	_teclado = Control.new()
	_teclado.set_anchors_preset(Control.PRESET_FULL_RECT)
	_teclado.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_teclado)
	move_child(_teclado, 0)

	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0, 0, 0, 0.55 if titulo == "" else 0.25)
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
	st.bg_color = Color(0.03, 0.05, 0.09, 1.0)
	st.border_color = COR_MARCA
	st.set_border_width_all(2)
	st.set_corner_radius_all(int(18 * escala))
	painel.add_theme_stylebox_override("panel", st)
	_teclado.add_child(painel)

	if titulo != "":
		# o que está sendo pedido (o campo pode estar atrás do teclado)
		var lt := Label.new()
		lt.text = titulo
		lt.position = Vector2(20.0 * escala, 10.0 * escala)
		lt.size = Vector2(larg - 40.0 * escala, 28.0 * escala)
		lt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lt.add_theme_font_size_override("font_size", int(19 * escala))
		lt.add_theme_color_override("font_color", COR_MARCA)
		painel.add_child(lt)

	_visor = Label.new()
	_visor.position = Vector2(20.0 * escala, topo - 64.0 * escala)
	_visor.size = Vector2(larg - 40.0 * escala, 56.0 * escala)
	_visor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_visor.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_visor.clip_text = true
	_visor.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
	var y0 := topo
	for li in range(linhas.size()):
		var linha: String = linhas[li]
		for ci in range(linha.length()):
			var letra := linha[ci]
			var b := _tecla(letra, Vector2(lado, lado), escala)
			b.position = Vector2(x0 + ci * (lado + vao), y0 + li * (lado + vao))
			b.pressed.connect(_digitar.bind(letra))
			painel.add_child(b)
	var yb := y0 + linhas.size() * (lado + vao)
	if not atalhos.is_empty():
		# os finais de e-mail mais comuns, de uma vez
		var wa: float = (lado * 10.0 + vao * 9.0 - vao * (atalhos.size() - 1)) / float(atalhos.size())
		for ai in range(atalhos.size()):
			var b := _tecla(str(atalhos[ai]), Vector2(wa, lado), escala)
			b.position = Vector2(x0 + ai * (wa + vao), yb)
			b.pressed.connect(_digitar.bind(str(atalhos[ai])))
			painel.add_child(b)
		yb += lado + vao
	var xb := x0
	for e in especiais:
		var w: float = lado * float(e[1]) + vao * (float(e[1]) - 1.0)
		var b := _tecla(str(e[0]), Vector2(w, lado), escala)
		b.position = Vector2(xb, yb)
		b.pressed.connect(e[2])
		painel.add_child(b)
		xb += w + vao
	_atualizar_visor()
	_marcar(_teclas[10] if _teclas.size() > 20 else _teclas[0])   # começa no Q (números: no 1)


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


func _fechar_teclado(pronto: bool = false) -> void:
	if _teclado == null:
		return
	_teclado.queue_free()
	_teclado = null
	_teclas.clear()
	_visor = null
	var era := _campo
	_alvo = _campo if _vale(_campo) else null
	_campo = null
	_fisico = false
	if era != null and is_instance_valid(era):
		teclado_fechou.emit(era, pronto)


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
	if _campo == null or not is_instance_valid(_campo):
		return
	match _modo_teclado:
		"email":
			letra = letra.to_lower().replace(" ", "")
		"numero":
			if not letra.is_valid_int():
				return
	if letra != "":
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
		_fisico = true
		var letra := String.chr(ev.unicode)
		_digitar(letra if _modo_teclado == "email" else letra.to_upper())


# ------------------------------------------------------------ cursor do jogo
## O mouse está em uso (o cursor do jogo está na tela)?
func mouse_na_tela() -> bool:
	return Time.get_ticks_msec() - _mouse_visto_ms < MOUSE_SOME_MS


func _mouse_mexeu(event: InputEventMouse) -> void:
	# (toque na tela não é mouse)
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventMouseMotion:
		if (event as InputEventMouseMotion).relative.length_squared() < 0.5:
			return
	elif event is InputEventMouseButton:
		var b := event as InputEventMouseButton
		if b.button_index == MOUSE_BUTTON_LEFT:
			_mouse_apertado = b.pressed
			# quem está com o mouse não usa a marca do controle
			if b.pressed and _teclado == null:
				_alvo = null
		if Leads.ficha_aberta():
			Leads.tocou()
	_mouse_pos = event.position
	_mouse_visto_ms = Time.get_ticks_msec()


func _quadro_do_cursor() -> void:
	# a seta do sistema nunca aparece: quem desenha é o jogo
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var mostra := mouse_na_tela()
	if not mostra and not _cursor.visible:
		return
	_cursor.visible = mostra
	if get_child(get_child_count() - 1) != _cursor:
		move_child(_cursor, -1)
	_cursor.queue_redraw()


## Uma seta grande, amarela com contorno escuro: dá para ver de longe em
## qualquer fundo. Encolhe um pouco no clique.
func _desenhar_cursor() -> void:
	var tela := get_viewport().get_visible_rect().size
	var k := clampf(tela.y / 1080.0, 0.6, 2.0) * (0.86 if _mouse_apertado else 1.0)
	var falta := MOUSE_SOME_MS - (Time.get_ticks_msec() - _mouse_visto_ms)
	var a := clampf(falta / 400.0, 0.0, 1.0)
	var forma := PackedVector2Array([Vector2(0, 0), Vector2(0, 40), Vector2(10, 31), Vector2(17, 47), Vector2(24, 44), Vector2(17, 28), Vector2(30, 28)])
	var pts := PackedVector2Array()
	var sombra := PackedVector2Array()
	for p in forma:
		pts.append(_mouse_pos + p * k)
		sombra.append(_mouse_pos + p * k + Vector2(3, 4) * k)
	_cursor.draw_colored_polygon(sombra, Color(0, 0, 0, 0.35 * a))
	_cursor.draw_colored_polygon(pts, Color(COR_MARCA, a))
	var borda := pts.duplicate()
	borda.append(pts[0])
	_cursor.draw_polyline(borda, Color(0.02, 0.04, 0.08, a), 3.0 * k, true)
	_cursor.draw_polyline(borda, Color(1, 1, 1, 0.9 * a), 1.0 * k, true)
