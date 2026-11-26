extends SceneTree
## Teste do MODO EVENTO DE PONTA A PONTA, com a tela de verdade e um pendrive
## de mentira (uma pasta):
##   OLHO_PENDRIVE=/tmp/pen godot --path . -s tools/testes/evento/teste_evento.gd
##   (no Linux sem monitor: xvfb-run -a -s "-screen 0 1920x1080x24" godot ...)
## Liga o evento na Central, joga 2 partidas (a 2a com um jogador que volta e
## um novo) e confere os arquivos do pendrive. Fotos: SAIDA=/uma/pasta.
## (apaga os cadastros: não rode na máquina do evento)

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


func esperar_ficha() -> void:
	var t0 := Time.get_ticks_msec()
	while not root.get_node("Leads").ficha_aberta() and Time.get_ticks_msec() - t0 < 30000:
		await espera(0.25)
	await espera(0.8)

func preencher(email: String, nome: String, idade: String) -> void:
	await escrever(email)
	await clicar_em("PRONTO")
	await espera(0.3)
	if nome != "":
		await escrever(nome)
		await clicar_em("PRONTO")
		await espera(0.3)
		await escrever(idade)
		await clicar_em("PRONTO")
		await espera(0.3)

func esperar_cena(nome: String, ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while (current_scene == null or not current_scene.scene_file_path.ends_with(nome)) and Time.get_ticks_msec() - t0 < ms:
		await espera(0.25)

func _initialize() -> void:
	await process_frame
	var L := root.get_node("Leads")
	var A := root.get_node("ArcadeData")
	var T := root.get_node("ControleTv")
	var pen := OS.get_environment("OLHO_PENDRIVE").path_join("OlhoNoLance_Leads")
	L.ligar(false)
	L.apagar_tudo()
	L.definir_evento("")
	# o pendrive começa FORA da máquina (a pasta do teste não existe ainda)
	var raiz_pen := OS.get_environment("OLHO_PENDRIVE")
	OS.execute("rm", ["-rf", raiz_pen])
	L._destinos.clear()
	A.definir_modo("credito")
	A.zerar_creditos()
	A.zerar_estatisticas()

	print("1. CRIAR O EVENTO NA CENTRAL")
	change_scene_to_file("res://scenes/config.tscn")
	await espera(1.5)
	var C := current_scene
	await clicar_em("EVENTO\n")
	confere("EVENTO ligado", A.modo_atual() == "evento")
	await clicar(centro(C.evento_campo))
	await espera(0.3)
	await escrever("feira teste")
	await clicar_em("PRONTO")
	await espera(0.3)
	confere("nome do evento: FEIRA TESTE", L.evento == "FEIRA TESTE")
	await espera(2.5)
	confere("liga SEM pendrive e a Central avisa", not L.tem_pendrive() and C.evento_pen.text.begins_with("SEM PENDRIVE"))
	await foto("v1_central_evento")
	await clicar_em("VOLTAR AO JOGO")
	await esperar_cena("opening.tscn", 15000)
	await espera(5.0)

	print("2. PARTIDA 1: dois jogadores novos")
	var O := current_scene
	confere("menu só com ARCADE e sem pedir ficha", O.modos_jogo.size() == 1 and A.pode_jogar() and A.creditos == 0)
	await acao("input_start")
	await espera(2.0)
	await acao("input_start")
	await espera(0.6)
	confere("2 jogadores escolhidos", O.total_players == 2)
	await esperar_ficha()
	confere("ficha do jogador 1 aberta", L.ficha_aberta() and L._indice == 0)
	await preencher("ana@gmail.com", "ana lima", "9")
	await clicar_em("CONFIRMAR")
	await espera(0.8)
	await preencher("beto@uol.com.br", "beto souza", "34")
	await clicar_em("CONFIRMAR")
	await esperar_cena("play.tscn", 25000)
	confere("a partida 1 começou", current_scene.scene_file_path.ends_with("play.tscn"))
	confere("2 jogadores e 2 cadastros guardados", L.total() == 2 and L.visitas() == 2)
	confere("sem pendrive: guardado NA MÁQUINA, esperando o pendrive", L.pendente and FileAccess.file_exists(L._pasta.path_join("leads.json")) and FileAccess.file_exists(L._pasta.path_join("visitas.csv")))
	await espera(2.0)
	print("   (o operador espeta o pendrive com o menu na tela)")

	print("3. PARTIDA 2: a Ana volta (reconhecida) e o Caio é novo")
	root.set_meta("pular_patrocinadores_opening_uma_vez", true)
	change_scene_to_file("res://scenes/opening.tscn")
	await espera(3.0)
	DirAccess.make_dir_recursive_absolute(raiz_pen)
	await espera(8.0)
	confere("espetou o pendrive: os cadastros desceram sozinhos", not L.pendente and FileAccess.file_exists(pen.path_join("leads.csv")) and FileAccess.get_file_as_string(pen.path_join("leads.csv")).contains("beto@uol.com.br"))
	O = current_scene
	await acao("input_start")
	await espera(2.0)
	await acao("input_start")
	await espera(0.6)
	await esperar_ficha()
	await preencher("ana@gmail.com", "", "")
	await espera(0.4)
	confere("reconheceu: nome e idade voltaram sozinhos", L._campo_nome.text == "Ana Lima" and L._campo_idade.text == "9" and L._recado.text.begins_with("BEM-VINDO DE VOLTA, ANA"))
	await foto("v2_bem_vindo_de_volta")
	await clicar_em("CONFIRMAR")
	await espera(0.8)
	await preencher("caio@hotmail.com", "caio", "12")
	await clicar_em("CONFIRMAR")
	await esperar_cena("play.tscn", 25000)
	confere("a partida 2 começou", current_scene.scene_file_path.ends_with("play.tscn"))
	confere("3 jogadores, 4 cadastros; a Ana com 2 visitas (não duplicou)", L.total() == 3 and L.visitas() == 4 and int(L.procurar("ana@gmail.com")["visitas"]) == 2)
	confere("com o pendrive espetado: gravado antes de a partida começar", not L.pendente)

	print("4. O QUE FICOU NO PENDRIVE")
	for nome in ["leads.csv", "leads_excel.csv", "leads.json", "visitas.csv", "resumo.txt", "LEIA-ME.txt"]:
		confere("existe " + nome, FileAccess.file_exists(pen.path_join(nome)))
	var csv := FileAccess.get_file_as_string(pen.path_join("leads.csv")).split("\r\n", false)
	confere("leads.csv: 3 jogadores, sem repetir", csv.size() == 4)
	var ana := ""
	for l in csv:
		if l.contains("ana@gmail.com"):
			ana = l
	confere("linha da Ana: 2 visitas, evento FEIRA TESTE, ARCADE", ana.contains(",2,FEIRA TESTE,ARCADE,"))
	confere("visitas.csv: 4 linhas (uma por cadastro)", FileAccess.get_file_as_string(pen.path_join("visitas.csv")).split("\r\n", false).size() == 5)
	var resumo := FileAccess.get_file_as_string(pen.path_join("resumo.txt"))
	confere("resumo.txt com as contas certas", resumo.contains("jogadores diferentes ........ 3") and resumo.contains("cadastros (um por partida) .. 4") and resumo.contains("jogaram mais de uma vez ..... 1") and resumo.contains("EVENTO: FEIRA TESTE"))
	print("----- resumo.txt -----")
	print(resumo)
	print("----- leads.csv -----")
	print("\n".join(csv))
	confere("nenhum crédito pedido nem gasto", A.creditos == 0)
	L.ligar(false)
	L.apagar_tudo()
	L.definir_evento("")
	A.definir_modo("free")
	A.zerar_estatisticas()
	print("RESULTADO: ", "TUDO CERTO" if falhas == 0 else "%d FALHA(S)" % falhas)
	quit(1 if falhas > 0 else 0)
