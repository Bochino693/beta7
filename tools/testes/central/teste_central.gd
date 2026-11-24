extends SceneTree
## Teste da CENTRAL DA MÁQUINA, das janelas, do cursor e do MODO EVENTO,
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
	for f in n.get_children():
		if (f is Button or f is LineEdit) and (f as Control).is_visible_in_tree():
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
	L.ligar(false)
	L.apagar_tudo()
	L.definir_evento("")
	A.definir_modo("credito")
	A.creditos = 0
	A.zerar_estatisticas()

	print("CENTRAL DA MÁQUINA: mouse, janelas e controle")
	change_scene_to_file("res://scenes/config.tscn")
	await espera(1.5)
	var C := current_scene
	confere("começa no modo crédito", A.modo_atual() == "credito")
	await clicar_em("EVENTO\n")
	confere("clique no EVENTO liga (sem pendrive)", A.modo_atual() == "evento" and L.ligado)
	confere("cursor do jogo aparece com o mouse", T.mouse_na_tela() and T._cursor.visible)
	confere("a seta do sistema fica escondida", Input.mouse_mode == Input.MOUSE_MODE_HIDDEN)
	await foto("e1_cursor")
	# janela por cima: o que está atrás não recebe nada
	await clicar_em("AJUSTES AVANÇADOS")
	await espera(0.2)
	confere("abriu a janela dos ajustes", C._modais.size() == 1)
	var atras := centro(achar("LIVRE\n"))
	confere("o botão LIVRE está atrás da janela", atras.x < root.size.x * 0.35)
	await clicar(atras)
	confere("clique no botão de trás não troca o modo", A.modo_atual() == "evento")
	await tecla(KEY_ENTER)
	await tecla(KEY_SPACE)
	confere("ENTER / ESPAÇO não apertam nada atrás", A.modo_atual() == "evento")
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
	# confirmar: zerar contador
	A.registrar_partida("arcade")
	await clicar_em("ZERAR CONTADOR")
	await espera(0.2)
	confere("pede confirmação", C._modais.size() == 2 and A.partidas_total == 1)
	await foto("e2_confirmar")
	await tecla(KEY_ESCAPE)
	await espera(0.2)
	confere("ESC fecha só a de cima e não zera", C._modais.size() == 1 and A.partidas_total == 1)
	await clicar_em("ZERAR CONTADOR")
	await espera(0.2)
	await clicar_em("SIM, ZERAR")
	await espera(0.2)
	confere("SIM zera e volta para os ajustes", C._modais.size() == 1 and A.partidas_total == 0)
	await tecla(KEY_ESCAPE)
	await espera(0.2)
	confere("ESC fecha os ajustes, não sai da Central", C._modais.is_empty() and current_scene == C and not C.voltando)
	# nome do evento: clique abre o teclado da tela
	await clicar(centro(C.evento_campo))
	await espera(0.2)
	confere("clique no NOME DO EVENTO abre o teclado da tela", T.teclado_aberto())
	await escrever("feira 26")
	await foto("e3_teclado")
	await clicar_em("PRONTO")
	await espera(0.2)
	confere("nome do evento guardado", L.evento == "FEIRA 26" and not T.teclado_aberto())
	# sensor batido com janela aberta não mexe atrás; ficha conta fora da janela
	await acao("input_credit")
	confere("ficha (L3) soma crédito", A.creditos == 1)
	await clicar_em("VOLTAR AO JOGO")

	print("MENU EM MODO EVENTO")
	await espera(6.0)
	var O := current_scene
	confere("voltou para o menu", O != null and O.scene_file_path.ends_with("opening.tscn"))
	confere("só o ARCADE no menu", O.modos_jogo.size() == 1 and str(O.modos_jogo[0]["acao"]) == "arcade")
	await foto("e4_menu_evento")
	await acao("input_cup")
	await espera(0.5)
	confere("SELECT não troca de modo", O.modo_focado == 0)
	var creditos_antes: int = A.creditos
	A.creditos = 0
	await acao("input_start")
	await espera(1.0)
	confere("START abre a escolha de jogadores SEM ficha", O.escolhendo_players)
	await espera(1.0)
	await acao("input_start")
	await espera(0.6)
	confere("2 jogadores", O.total_players == 2)
	await foto("e5_players")
	var t0 := Time.get_ticks_msec()
	while not L.ficha_aberta() and Time.get_ticks_msec() - t0 < 30000:
		await espera(0.25)
	confere("a ficha de cadastro abriu", L.ficha_aberta())
	await espera(0.8)
	confere("teclado no e-mail", T.teclado_aberto())
	await escrever("ana@gmail.com")
	await foto("e6_ficha_email")
	await clicar_em("PRONTO")
	await espera(0.3)
	await escrever("ana lima")
	await clicar_em("PRONTO")
	await espera(0.3)
	await escrever("9")
	await clicar_em("PRONTO")
	await espera(0.3)
	await foto("e7_ficha_cheia")
	# com a ficha na tela, START / sensores não mexem no menu
	await acao("input_start")
	confere("START com a ficha aberta não faz nada atrás", L.ficha_aberta() and O.iniciando_jogo)
	await clicar_em("CONFIRMAR")
	await espera(0.8)
	confere("passou para o jogador 2", L.ficha_aberta() and L._indice == 1)
	# jogador 2 pelo mouse: clica no campo, fecha, clica de novo
	await escrever("beto@uol.com.br")
	await tecla(KEY_ENTER)
	await espera(0.3)
	await escrever("beto")
	await tecla(KEY_ENTER)
	await espera(0.3)
	await escrever("34")
	await tecla(KEY_ENTER)
	await espera(0.3)
	confere("campos do jogador 2 certos", L._tudo_certo())
	await clicar_em("CONFIRMAR")
	await espera(0.5)
	confere("ficha fechou", not L.ficha_aberta())
	confere("2 cadastros guardados (ARCADE, evento)", L.total() == 2 and str(L.procurar("ana@gmail.com").get("evento", "")) == "FEIRA 26" and int(L.procurar("beto@uol.com.br").get("idade", 0)) == 34)
	confere("nenhum crédito gasto", A.creditos == 0)
	t0 = Time.get_ticks_msec()
	while current_scene == O and Time.get_ticks_msec() - t0 < 25000:
		await espera(0.25)
	await espera(1.0)
	confere("a partida começou (play)", current_scene != null and current_scene.scene_file_path.ends_with("play.tscn"))
	await foto("e8_partida")
	A.creditos = creditos_antes
	L.ligar(false)
	L.apagar_tudo()
	L.definir_evento("")
	A.definir_modo("free")
	A.zerar_creditos()
	A.zerar_estatisticas()
	print("RESULTADO: ", "TUDO CERTO" if falhas == 0 else "%d FALHA(S)" % falhas)
	quit(1 if falhas > 0 else 0)
