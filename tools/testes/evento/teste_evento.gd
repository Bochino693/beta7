extends SceneTree
## Teste do MODO EVENTO DE PONTA A PONTA, com a tela de verdade e um pendrive
## de mentira (uma pasta):
##   OLHO_PENDRIVE=/tmp/pen godot --path . -s tools/testes/evento/teste_evento.gd
##   (no Linux sem monitor: xvfb-run -a -s "-screen 0 1920x1080x24" godot ...)
## Cria o evento na Central (EVENTOS E DADOS), escolhe a opção EVENTO no menu e joga 2
## partidas: a 1a com 8 jogadores (o pendrive ainda fora da máquina), a 2a
## com um jogador que volta e um novo. Confere a partida (8 cartões, nomes do
## cadastro), que ARCADE continua pedindo ficha e os arquivos do pendrive.
## Fotos de cada passo: SAIDA=/uma/pasta.
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

func escolher_evento_no_menu() -> void:
	var O := current_scene
	var t0 := Time.get_ticks_msec()
	while str(O.modos_jogo[O.modo_focado]["acao"]) != "evento" and Time.get_ticks_msec() - t0 < 12000:
		await acao("input_cup")
		await espera(0.9)


func _initialize() -> void:
	await process_frame
	var L := root.get_node("Leads")
	var A := root.get_node("ArcadeData")
	var raiz_pen := OS.get_environment("OLHO_PENDRIVE")
	var pen := raiz_pen.path_join("OlhoNoLance_Leads")
	L.ligar(false)
	L.apagar_tudo()
	L.definir_evento("")
	L._apagados.clear()
	L.ligar(true)
	# o pendrive começa FORA da máquina (a pasta do teste não existe ainda)
	OS.execute("rm", ["-rf", raiz_pen])
	L._destinos.clear()
	A.definir_modo("credito")
	A.zerar_creditos()
	A.zerar_estatisticas()

	print("1. CRIAR O EVENTO NA CENTRAL (EVENTOS E DADOS)")
	change_scene_to_file("res://scenes/config.tscn")
	await espera(1.5)
	var C := current_scene
	confere("a Central não tem mais a chave do evento (ARCADE e COPA no CRÉDITO)", achar("LIGAR O MODO EVENTO") == null and A.modo_atual() == "credito")
	await clicar_em("EVENTOS E DADOS")
	await espera(0.4)
	await clicar_em("NOVO EVENTO")
	await espera(0.9)
	await escrever("feira teste")
	await clicar_em("PRONTO")
	await espera(0.3)
	await clicar_em("CRIAR E USAR")
	await espera(0.5)
	confere("evento criado e em uso: FEIRA TESTE", L.evento == "FEIRA TESTE" and L.eventos_resumo().size() == 1 and bool(L.eventos_resumo()[0]["atual"]))
	await foto("v1_eventos_e_dados")
	await clicar_em("FECHAR")
	await espera(2.5)
	confere("sem pendrive: a Central avisa", not L.tem_pendrive() and C.evento_pen.text.contains("SEM PENDRIVE"))
	await clicar_em("VOLTAR AO JOGO")
	await esperar_cena("opening.tscn", 15000)
	await espera(5.0)

	print("2. O MENU: ARCADE, COPA E EVENTO")
	var O := current_scene
	confere("3 opções no menu, a 3a é EVENTO", O.modos_jogo.size() == 3 and str(O.modos_jogo[2]["acao"]) == "evento")
	await acao("input_start")
	await espera(1.2)
	confere("ARCADE sem ficha: não abre (modo crédito)", not O.escolhendo_players)
	await escolher_evento_no_menu()
	confere("SELECT chega na opção EVENTO", str(O.modos_jogo[O.modo_focado]["acao"]) == "evento")
	await foto("v2_menu_evento")

	print("3. PARTIDA 1 DO EVENTO: 8 jogadores novos (sem ficha, pendrive fora)")
	await acao("input_start")
	await espera(1.5)
	confere("EVENTO abre a escolha de jogadores SEM ficha, até 8", O.escolhendo_players and O.max_players == 8 and A.creditos == 0)
	for n in range(7):
		await acao("input_start")
		await espera(0.45)
		if n == 4:
			await foto("v3_escolha_6_de_8")
	confere("8 jogadores escolhidos", O.total_players == 8)
	await esperar_ficha()
	confere("ficha do jogador 1 de 8", L.ficha_aberta() and L._indice == 0 and L._fila.size() == 8)
	var gente := [["ana@gmail.com", "ana lima", "9"], ["beto@uol.com.br", "beto souza", "34"], ["caio@hotmail.com", "caio", "12"], ["duda@gmail.com", "duda reis", "15"],
		["edu@gmail.com", "eduardo", "41"], ["fabi@gmail.com", "fabiana", "27"], ["gui@gmail.com", "guilherme alves", "8"], ["helo@gmail.com", "heloisa", "52"]]
	for i in range(8):
		await preencher(gente[i][0], gente[i][1], gente[i][2])
		if i == 0:
			await foto("v4_ficha")
		await clicar_em("CONFIRMAR")
		await espera(0.8)
	await esperar_cena("play.tscn", 25000)
	confere("a partida do evento começou", current_scene.scene_file_path.ends_with("play.tscn"))
	var P := current_scene
	await espera(2.5)
	confere("8 jogadores na partida, com os nomes do cadastro", P.total_players == 8 and P.partida_evento and P.player_panels.size() == 8 and P._nome_player(0) == "ANA" and P._nome_player(6) == "GUILHERME")
	await foto("v5_partida_8")
	confere("8 jogadores e 8 cadastros guardados NA MÁQUINA, esperando o pendrive", L.total() == 8 and L.visitas() == 8 and L.pendente and FileAccess.file_exists(L._pasta.path_join("leads.json")))
	var t0 := Time.get_ticks_msec()
	while not P.partida_ativa and Time.get_ticks_msec() - t0 < 30000:
		if P.aguardando_start_turno:
			await acao("input_start")
		await espera(0.25)
	for g in range(5):
		P.registrar_ponto(1)
		await espera(0.25)
	await foto("v6_partida_gol")
	P.scores.assign([5, 3, 9, 2, 7, 4, 6, 1])
	P._finalizar_partida()
	await espera(4.0)
	await foto("v7_resultado_8")
	confere("resultado com os 8", P.partida_finalizada)

	print("4. O OPERADOR ESPETA O PENDRIVE; PARTIDA 2: a Ana volta e o Ivo é novo")
	root.set_meta("pular_patrocinadores_opening_uma_vez", true)
	change_scene_to_file("res://scenes/opening.tscn")
	await espera(3.0)
	DirAccess.make_dir_recursive_absolute(raiz_pen)
	await espera(8.0)
	confere("espetou o pendrive: os cadastros desceram sozinhos", not L.pendente and FileAccess.file_exists(pen.path_join("leads.csv")) and FileAccess.get_file_as_string(pen.path_join("leads.csv")).contains("helo@gmail.com"))
	O = current_scene
	await escolher_evento_no_menu()
	await acao("input_start")
	await espera(2.0)
	await acao("input_start")
	await espera(0.6)
	await esperar_ficha()
	await preencher("ana@gmail.com", "", "")
	await espera(0.4)
	confere("reconheceu: nome e idade voltaram sozinhos", L._campo_nome.text == "Ana Lima" and L._campo_idade.text == "9" and L._recado.text.begins_with("BEM-VINDO DE VOLTA, ANA"))
	await foto("v8_bem_vindo_de_volta")
	await clicar_em("CONFIRMAR")
	await espera(0.8)
	await preencher("ivo@hotmail.com", "ivo", "12")
	await clicar_em("CONFIRMAR")
	await esperar_cena("play.tscn", 25000)
	confere("a partida 2 começou com 2 jogadores", current_scene.scene_file_path.ends_with("play.tscn") and current_scene.total_players == 2)
	confere("9 jogadores, 10 cadastros; a Ana com 2 visitas (não duplicou)", L.total() == 9 and L.visitas() == 10 and int(L.procurar("ana@gmail.com")["visitas"]) == 2)
	confere("com o pendrive espetado: gravado antes de a partida começar", not L.pendente)

	confere("contadores: 2 partidas de evento (e 2 no evento FEIRA TESTE), 0 de arcade", A.partidas_evento == 2 and A.partidas_arcade == 0 and int(L.eventos_resumo()[0]["partidas"]) == 2)

	print("5. O QUE FICOU NO PENDRIVE")
	for nome in ["leads.csv", "leads_excel.csv", "leads.json", "visitas.csv", "eventos.csv", "partidas.csv", "resumo.txt", "LEIA-ME.txt"]:
		confere("existe " + nome, FileAccess.file_exists(pen.path_join(nome)))
	var csv := FileAccess.get_file_as_string(pen.path_join("leads.csv")).split("\r\n", false)
	confere("leads.csv: 9 jogadores, sem repetir", csv.size() == 10)
	var ana := ""
	for l in csv:
		if l.contains("ana@gmail.com"):
			ana = l
	confere("linha da Ana: 2 visitas, evento FEIRA TESTE, modo EVENTO", ana.contains(",2,FEIRA TESTE,EVENTO,"))
	confere("visitas.csv: 10 linhas (uma por cadastro)", FileAccess.get_file_as_string(pen.path_join("visitas.csv")).split("\r\n", false).size() == 11)
	var resumo := FileAccess.get_file_as_string(pen.path_join("resumo.txt"))
	confere("resumo.txt com as contas certas", resumo.contains("jogadores diferentes ........ 9") and resumo.contains("cadastros (um por partida) .. 10") and resumo.contains("jogaram mais de uma vez ..... 1") and resumo.contains("EVENTO: FEIRA TESTE"))
	print("----- resumo.txt -----")
	print(resumo)
	confere("partidas.csv e eventos.csv com os números", FileAccess.get_file_as_string(pen.path_join("partidas.csv")).contains("EVENTO,2") and FileAccess.get_file_as_string(pen.path_join("eventos.csv")).contains("FEIRA TESTE,") and FileAccess.get_file_as_string(pen.path_join("eventos.csv")).contains(",2,9,10,"))
	confere("nenhum crédito pedido nem gasto", A.creditos == 0)

	print("6. APAGAR O EVENTO PELA CENTRAL (some da máquina e, na descarga, do pendrive)")
	change_scene_to_file("res://scenes/config.tscn")
	await espera(1.5)
	C = current_scene
	await clicar_em("EVENTOS E DADOS")
	await espera(0.4)
	await foto("v9_dados_com_evento")
	await clicar_em("APAGAR")
	await espera(0.4)
	confere("pede confirmação antes de apagar", C._modais.size() == 2 and L.total() == 9)
	await clicar_em("SIM, APAGAR")
	await espera(0.6)
	confere("evento apagado da máquina: 0 jogadores, 0 cadastros, nenhum evento", L.total() == 0 and L.visitas() == 0 and L.eventos_resumo().is_empty())
	await clicar_em("DESCARREGAR NO PENDRIVE")
	await espera(0.6)
	var csv2 := FileAccess.get_file_as_string(pen.path_join("leads.csv")).split("\r\n", false)
	confere("depois da descarga o pendrive também ficou sem eles", csv2.size() == 1 and FileAccess.get_file_as_string(pen.path_join("visitas.csv")).split("\r\n", false).size() == 1)
	confere("o que estava no pendrive não voltou para a máquina", L.total() == 0)
	confere("a versão anterior ficou na cópia de segurança do pendrive", FileAccess.get_file_as_string(pen.path_join("copia_de_seguranca/leads.csv")).contains("ana@gmail.com"))
	L._apagados.clear()
	L.ligar(false)
	L.apagar_tudo()
	L.definir_evento("")
	A.definir_modo("free")
	A.zerar_estatisticas()
	print("RESULTADO: ", "TUDO CERTO" if falhas == 0 else "%d FALHA(S)" % falhas)
	quit(1 if falhas > 0 else 0)
