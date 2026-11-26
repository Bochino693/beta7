extends SceneTree
## Teste da CENTRAL DA MÁQUINA, das janelas, do cursor e dos dados,
## com a tela de verdade (mouse, controle e teclas simulados):
##   godot --path . -s tools/testes/central/teste_central.gd
##   (no Linux sem monitor: xvfb-run -a -s "-screen 0 1920x1080x24" godot ...)
## Fotos de cada passo: defina SAIDA=/uma/pasta.
## (mexe no modo, nos créditos e apaga os cadastros: não rode na máquina do evento)
var falhas := 0
func confere(nome: String, certo: bool) -> void:
	if not certo:
		falhas += 1
	print(("  ok   " if certo else "  FALHOU ") + nome)
func foto(nome: String) -> void:
	await process_frame
	await process_frame
	if OS.get_environment("SAIDA") == "":
		return
	root.get_texture().get_image().save_png(OS.get_environment("SAIDA").path_join(nome + ".png"))
func espera(s: float) -> void:
	await create_timer(s).timeout
func achar(texto: String, n: Node = null) -> Control:
	if n == null:
		n = root
	# (de trás para a frente: o que está na janela de cima é achado primeiro)
	var filhos := n.get_children()
	filhos.reverse()
	for f in filhos:
		if (f is Button or f is LineEdit) and (f as Control).is_visible_in_tree() and not (f is Button and (f as Button).disabled):
			var t: String = f.text if f is Button else str(f.get_meta("titulo", ""))
			if t.contains(texto):
				return f
		var r := achar(texto, f)
		if r != null:
			return r
	return null
func centro(c: Control) -> Vector2:
	return root.get_final_transform() * (c.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, c.size)).get_center()
func clicar(pos: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = pos
	m.global_position = pos
	m.relative = Vector2(5, 5)
	Input.parse_input_event(m)
	await process_frame
	for p in [true, false]:
		var b := InputEventMouseButton.new()
		b.button_index = MOUSE_BUTTON_LEFT
		b.pressed = p
		b.position = pos
		b.global_position = pos
		Input.parse_input_event(b)
		await process_frame
		await process_frame
func clicar_em(texto: String) -> bool:
	var c := achar(texto)
	if c == null:
		print("   (não achei o botão: ", texto, ")")
		return false
	await clicar(centro(c))
	return true
func tecla(codigo: Key, letra: String = "") -> void:
	for p in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = codigo
		ev.physical_keycode = codigo
		ev.pressed = p
		if p and letra != "":
			ev.unicode = letra.unicode_at(0)
		Input.parse_input_event(ev)
		await process_frame
		await process_frame
func escrever(texto: String) -> void:
	for i in range(texto.length()):
		await tecla(KEY_A, texto[i])
func acao(nome: String) -> void:
	for p in [true, false]:
		var ev := InputEventAction.new()
		ev.action = nome
		ev.pressed = p
		Input.parse_input_event(ev)
		await process_frame
		await process_frame
		await process_frame

func _initialize() -> void:
	await process_frame
	var L := root.get_node("Leads")
	var A := root.get_node("ArcadeData")
	var T := root.get_node("ControleTv")
	L.apagar_tudo()
	L.definir_evento("")
	L._apagados.clear()
	L.ligar(true)
	A.definir_modo("free")
	A.zerar_creditos()
	A.zerar_estatisticas()

	print("CENTRAL DA MÁQUINA: mouse, janelas e controle")
	change_scene_to_file("res://scenes/config.tscn")
	await espera(1.5)
	var C := current_scene
	await clicar_em("CRÉDITO\n")
	confere("clique no CRÉDITO troca o modo", A.modo_atual() == "credito")
	confere("cursor do jogo aparece com o mouse", T.mouse_na_tela() and T._cursor.visible)
	confere("a seta do sistema fica escondida", Input.mouse_mode == Input.MOUSE_MODE_HIDDEN)
	await foto("e1_cursor")
	# janela por cima: o que está atrás não recebe nada
	await clicar_em("AJUSTES AVANÇADOS")
	await espera(0.2)
	confere("abriu a janela dos ajustes", C._modais.size() == 1)
	var atras := centro(C.botoes_modo["livre"])
	await clicar(atras)
	confere("clique no botão de trás não troca o modo", A.modo_atual() == "credito")
	await tecla(KEY_ENTER)
	await tecla(KEY_SPACE)
	confere("ENTER / ESPAÇO não apertam nada atrás", A.modo_atual() == "credito")
	while not C._modais.is_empty():
		C._fechar_modal()
	await espera(0.1)
	# controle remoto: OK num botão abre a janela; o 2o OK não aperta o de trás
	T.marcar(achar("AJUSTES AVANÇADOS"))
	await tecla(KEY_ENTER)
	await espera(0.2)
	confere("OK do controle abre a janela", C._modais.size() == 1)
	confere("a marca passou para dentro da janela (FECHAR)", T._alvo != null and (T._alvo as Button).text.begins_with("FECHAR"))
	# (força a marca no botão de trás, como ficava antes)
	for n in C.get_child(0).get_child(0).find_children("*", "Button", true, false):
		if (n as Button).text.begins_with("AJUSTES"):
			T._alvo = n
	await tecla(KEY_ENTER)
	await espera(0.2)
	confere("OK com a marca atrás NÃO abre outra janela", C._modais.size() == 1)
	confere("a marca saiu do botão de trás", T._alvo == null or not (T._alvo as Button).text.begins_with("AJUSTES"))
	# a opção EVENTO do menu: liga / desliga nos ajustes
	await clicar_em("EVENTO NO MENU")
	confere("EVENTO NO MENU: NÃO", not L.ligado)
	await clicar_em("EVENTO NO MENU")
	confere("EVENTO NO MENU: SIM", L.ligado)
	await tecla(KEY_ESCAPE)
	await espera(0.2)
	confere("ESC fecha os ajustes, não sai da Central", C._modais.is_empty() and current_scene == C and not C.voltando)

	print("CONTADORES: zerar um por um (eventos, leads e pendrive ficam no jogo)")
	for i in range(3):
		A.registrar_partida("arcade")
	A.registrar_partida("copa")
	confere("a Central não tem mais eventos nem pendrive", achar("EVENTOS E DADOS") == null and achar("DESCARREGAR") == null and achar("NOVO EVENTO") == null)
	await clicar_em("ZERAR CONTADORES")
	await espera(0.3)
	confere("abriu a janela dos contadores", C._modais.size() == 1 and C._dados_aberto)
	await clicar_em("ZERAR")
	await espera(0.2)
	confere("zerar pede confirmação", C._modais.size() == 2 and A.partidas_copa == 1)
	await foto("e2_confirmar")
	await tecla(KEY_ESCAPE)
	await espera(0.2)
	confere("ESC fecha só a de cima e não zera", C._modais.size() == 1 and A.partidas_copa == 1)
	await clicar_em("ZERAR")
	await espera(0.2)
	await clicar_em("SIM, ZERAR")
	await espera(0.4)
	# (o ZERAR achado é o da COPA: o último com partidas)
	confere("SIM zera só a COPA e volta para os contadores", C._modais.size() == 1 and A.partidas_copa == 0 and A.partidas_arcade == 3 and A.partidas_total == 3)
	await foto("e3_contadores")
	await clicar_em("FECHAR")
	await espera(0.3)
	# a data dos cadastros fica nos ajustes avançados
	await clicar_em("AJUSTES AVANÇADOS")
	await espera(0.2)
	await clicar_em("DATA E HORA")
	await espera(0.3)
	confere("DATA E HORA abre por cima dos ajustes", C._modais.size() == 2)
	var antes_data: String = L.data_na_tela()
	await clicar_em("+")
	await espera(0.2)
	confere("o + acerta a data dos cadastros", L.data_na_tela() != antes_data)
	L.ajuste_relogio = 0
	L._guardar_cfg()
	while not C._modais.is_empty():
		C._fechar_modal()
	await espera(0.3)
	await acao("input_credit")
	confere("ficha (L3) soma crédito", A.creditos == 1)
	await clicar_em("VOLTAR AO JOGO")

	print("MENU: ARCADE, COPA E EVENTO")
	await espera(6.0)
	var O := current_scene
	confere("voltou para o menu", O != null and O.scene_file_path.ends_with("opening.tscn"))
	confere("3 opções: ARCADE, COPA e EVENTO", O.modos_jogo.size() == 3 and str(O.modos_jogo[2]["acao"]) == "evento")
	await foto("e4_menu")
	await acao("input_start")
	await espera(1.2)
	confere("ARCADE com 1 crédito abre e gasta o crédito", O.escolhendo_players and A.creditos == 0 and O.max_players == 4)
	L.apagar_tudo()
	L._apagados.clear()
	L.definir_evento("")
	A.definir_modo("free")
	A.zerar_creditos()
	A.zerar_estatisticas()
	print("RESULTADO: ", "TUDO CERTO" if falhas == 0 else "%d FALHA(S)" % falhas)
	quit(1 if falhas > 0 else 0)
