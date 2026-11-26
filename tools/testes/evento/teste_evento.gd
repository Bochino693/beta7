extends SceneTree
## Teste do MODO EVENTO DE PONTA A PONTA, com a tela de verdade e um pendrive
## de mentira (uma pasta):
##   OLHO_PENDRIVE=/tmp/pen godot --path . -s tools/testes/evento/teste_evento.gd
##   (no Linux sem monitor: xvfb-run -a -s "-screen 0 1920x1080x24" godot ...)
## Escolhe EVENTO no menu: abre a tela dos EVENTOS (o nome vem antes de tudo),
## cria o evento e joga 2 partidas: a 1a com 8 jogadores (o pendrive ainda
## fora da máquina), a 2a com um jogador que volta e um novo. Cada ficha pede
## e-mail, nome, idade, cidade (lista país > estado > cidade) e telefone.
## Confere a partida (8 cartões, nomes do cadastro), que ARCADE continua
## pedindo ficha, a conferência do pendrive (nada repetido), os leads e o
## apagar - tudo na tela dos EVENTOS.
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
	while not (root.get_node("Leads")._ficha != null) and Time.get_ticks_msec() - t0 < 30000:
		await espera(0.25)
	await espera(0.8)

func esperar_lobby() -> void:
	var t0 := Time.get_ticks_msec()
	while not root.get_node("Leads").lobby_aberto() and Time.get_ticks_msec() - t0 < 8000:
		await espera(0.1)
	await espera(0.9)

## cidade = os passos na lista: o texto de um botão, "OK" (aperta o que já
## está marcado) ou "ESCREVER:nome" (a cidade que não está na lista)
func preencher(email: String, nome: String = "", idade: String = "", cidade: Array = [], tel: String = "") -> void:
	await escrever(email)
	await clicar_em("PRONTO")
	await espera(0.3)
	if nome == "":
		return
	await escrever(nome)
	await clicar_em("PRONTO")
	await espera(0.3)
	await escrever(idade)
	await clicar_em("PRONTO")
	await espera(0.5)
	for passo in cidade:
		if str(passo) == "OK":
			await tecla(KEY_ENTER)
		elif str(passo).begins_with("ESCREVER:"):
			await clicar_em("NOME DA CIDADE")
			await espera(0.4)
			await escrever(str(passo).trim_prefix("ESCREVER:"))
			await clicar_em("PRONTO")
		else:
			await clicar_em(str(passo))
		await espera(0.4)
	await espera(0.3)
	await escrever(tel)
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

func linhas_de(caminho: String) -> PackedStringArray:
	return FileAccess.get_file_as_string(caminho).trim_prefix("﻿").split("\r\n", false)


func _initialize() -> void:
	await process_frame
	var L := root.get_node("Leads")
	var A := root.get_node("ArcadeData")
	var T := root.get_node("ControleTv")
	var raiz_pen := OS.get_environment("OLHO_PENDRIVE")
	var pen := raiz_pen.path_join("OlhoNoLance_Leads")
	L.ligar(false)
	L.apagar_tudo()
	L.definir_evento("")
	L._apagados.clear()
	L.ultimo_lugar = ["Brasil", "", ""]
	L.ligar(true)
	# o pendrive começa FORA da máquina (a pasta do teste não existe ainda)
	OS.execute("rm", ["-rf", raiz_pen, raiz_pen + "_fora"])
	L._destinos.clear()
	A.definir_modo("credito")
	A.zerar_creditos()
	A.zerar_estatisticas()
	root.get_node("ChampionsDb").limpar_tudo()

	print("1. O MENU: ARCADE, COPA E EVENTO")
	root.set_meta("pular_patrocinadores_opening_uma_vez", true)
	change_scene_to_file("res://scenes/opening.tscn")
	await esperar_cena("opening.tscn", 15000)
	await espera(6.0)
	var O := current_scene
	confere("3 opções no menu, a 3a é EVENTO", O.modos_jogo.size() == 3 and str(O.modos_jogo[2]["acao"]) == "evento")
	await acao("input_start")
	await espera(1.2)
	confere("ARCADE sem ficha: não abre (modo crédito)", not O.escolhendo_players)
	await escolher_evento_no_menu()
	confere("SELECT chega na opção EVENTO", str(O.modos_jogo[O.modo_focado]["acao"]) == "evento")
	await foto("v1_menu_evento")

	print("2. A TELA DOS EVENTOS: o nome vem antes de tudo")
	await acao("input_start")
	await esperar_lobby()
	confere("EVENTO abre a tela dos eventos (nenhuma partida contada ainda)", L.lobby_aberto() and not O.escolhendo_players and A.partidas_evento == 0)
	confere("sem evento: o teclado já abre pedindo o NOME DO NOVO EVENTO", T.teclado_aberto() and str(T._campo.get_meta("titulo", "")) == "NOME DO NOVO EVENTO")
	await foto("v2_lobby_vazio_teclado")
	await acao("input_start")
	await espera(0.5)
	confere("START sem evento escolhido não começa partida", L.lobby_aberto() and not O.escolhendo_players)
	if not T.teclado_aberto():
		await clicar_em("NOME DO NOVO EVENTO")
		await espera(0.4)
	await escrever("feira teste")
	await clicar_em("PRONTO")
	await espera(0.6)
	confere("evento criado e escolhido: FEIRA TESTE", L.evento == "FEIRA TESTE" and L.eventos_resumo().size() == 1 and L._lobby._escolhido == "FEIRA TESTE")
	confere("a marca do controle foi para JOGAR NESTE EVENTO", T._alvo == L._lobby._bt_jogar)
	confere("sem pendrive: a tela avisa", not L.tem_pendrive() and L._lobby._pen.text.begins_with("SEM PENDRIVE"))
	await foto("v3_lobby_evento_criado")
	# um 2o evento, e a volta para o primeiro pela lista
	await clicar_em("NOME DO NOVO EVENTO")
	await espera(0.4)
	await escrever("copa da escola")
	await clicar_em("PRONTO")
	await espera(0.6)
	confere("2 eventos salvos; o novo ficou escolhido", L._lobby._eventos.size() == 2 and L._lobby._escolhido == "COPA DA ESCOLA")
	for b in L._lobby._lista.get_children():
		if str(b.get_meta("evento", "")) == "FEIRA TESTE":
			await clicar(centro(b))
	await espera(0.4)
	confere("clicar na lista escolhe o evento", L._lobby._escolhido == "FEIRA TESTE")
	await acao("input_cup")
	await espera(0.4)
	confere("SELECT passa para o próximo evento", L._lobby._escolhido == "COPA DA ESCOLA")
	await acao("input_cup")
	await espera(0.4)
	await foto("v4_lobby_dois_eventos")
	# VOLTAR sai para o menu sem contar partida
	await tecla(KEY_ESCAPE)
	await espera(0.8)
	confere("ESC volta para o menu: nada contado, nada gasto", not L.lobby_aberto() and not O.escolhendo_players and A.partidas_evento == 0 and A.creditos == 0)

	print("3. PARTIDA 1 DO EVENTO: 8 jogadores novos (sem ficha, pendrive fora)")
	await acao("input_start")
	await esperar_lobby()
	confere("a tela volta com o evento escolhido e a marca no JOGAR", L._lobby._escolhido == "FEIRA TESTE" and T._alvo == L._lobby._bt_jogar)
	await tecla(KEY_ENTER)
	await espera(1.5)
	confere("OK no JOGAR abre a escolha de jogadores SEM ficha, até 8", not L.lobby_aberto() and O.escolhendo_players and O.max_players == 8 and A.creditos == 0 and L.evento == "FEIRA TESTE")
	for n in range(7):
		await acao("input_start")
		await espera(0.45)
	confere("8 jogadores escolhidos", O.total_players == 8)
	await esperar_ficha()
	confere("ficha do jogador 1 de 8", L._ficha != null and L._indice == 0 and L._fila.size() == 8)
	# [e-mail, nome, idade, os passos da cidade, telefone]
	var gente := [
		["ana@gmail.com", "ana lima", "9", ["SP   São Paulo", "Campinas"], "19987654321"],
		["beto@uol.com.br", "beto souza", "34", ["OK"], "1933334444"],
		["caio@hotmail.com", "caio", "12", ["MUDAR O ESTADO", "RJ   Rio de Janeiro", "Niterói"], "21999990000"],
		["duda@gmail.com", "duda reis", "15", ["OK"], "21988887777"],
		["edu@gmail.com", "eduardo", "41", ["ESCREVER:paraty"], "24977776666"],
		["fabi@gmail.com", "fabiana", "27", ["MUDAR O ESTADO", "MUDAR O PAÍS", "Argentina", "Córdoba", "Córdoba"], "3514567890"],
		["gui@gmail.com", "guilherme alves", "8", ["MUDAR O ESTADO", "MUDAR O PAÍS", "Brasil", "SP   São Paulo", "São Paulo"], "11912345678"],
		["helo@gmail.com", "heloisa", "52", ["OK"], "11955554444"]]
	for i in range(8):
		if i == 0:
			await escrever(gente[i][0])
			await clicar_em("PRONTO")
			await espera(0.3)
			await escrever(gente[i][1])
			await clicar_em("PRONTO")
			await espera(0.3)
			await escrever(gente[i][2])
			await clicar_em("PRONTO")
			await espera(0.6)
			confere("depois da idade a lista de lugares abre sozinha (ESTADO, no Brasil)", L._seletor != null and L._sel_fase == 1 and L._sel_pais == "Brasil")
			await foto("v5_escolher_estado")
			await clicar_em("SP   São Paulo")
			await espera(0.5)
			await foto("v6_escolher_cidade")
			await clicar_em("Campinas")
			await espera(0.6)
			confere("escolheu a cidade: o teclado do TELEFONE abre sozinho", L._seletor == null and L._lugar == ["Brasil", "SP", "Campinas"] and T.teclado_aberto() and str(T._campo.get_meta("titulo", "")).begins_with("TELEFONE"))
			await foto("v7_teclado_telefone")
			await escrever("199876")
			await clicar_em("PRONTO")
			await espera(0.4)
			confere("telefone pela metade não passa", not L._tudo_certo() and L._recado.text.begins_with("Confira o TELEFONE"))
			await escrever("54321")
			await clicar_em("PRONTO")
			await espera(0.4)
			confere("tudo certo: os 5 passos verdes e a marca no CONFIRMAR", L._tudo_certo() and T._alvo == L._bt_confirmar)
			await foto("v8_ficha_completa")
		else:
			await preencher(gente[i][0], gente[i][1], gente[i][2], gente[i][3], gente[i][4])
			if i == 1:
				confere("o 2o jogador: a lista já abre na cidade do anterior, um OK basta", L._lugar == ["Brasil", "SP", "Campinas"])
		await clicar_em("CONFIRMAR")
		await espera(0.8)
	await esperar_cena("play.tscn", 25000)
	confere("a partida do evento começou", current_scene.scene_file_path.ends_with("play.tscn"))
	var P := current_scene
	await espera(2.5)
	confere("8 jogadores na partida, com os nomes do cadastro", P.total_players == 8 and P.partida_evento and P.player_panels.size() == 8 and P._nome_player(0) == "ANA" and P._nome_player(6) == "GUILHERME")
	await foto("v9_partida_8")
	confere("8 jogadores e 8 cadastros guardados NA MÁQUINA, esperando o pendrive", L.total() == 8 and L.visitas() == 8 and L.pendente and FileAccess.file_exists(L._pasta.path_join("leads.json")))
	var fabi: Dictionary = L.procurar("fabi@gmail.com")
	var edu: Dictionary = L.procurar("edu@gmail.com")
	confere("telefone e lugar guardados (Brasil, cidade escrita, Argentina)", str(L.procurar("ana@gmail.com")["telefone"]) == "55 19 98765-4321" and str(L.procurar("beto@uol.com.br")["telefone"]) == "55 19 3333-4444"
		and str(edu["cidade"]) == "Paraty" and str(edu["estado"]) == "RJ" and str(fabi["pais"]) == "Argentina" and str(fabi["cidade"]) == "Córdoba" and str(fabi["telefone"]) == "54 3514567890")
	var t0 := Time.get_ticks_msec()
	while not P.partida_ativa and Time.get_ticks_msec() - t0 < 30000:
		if P.aguardando_start_turno:
			await acao("input_start")
		await espera(0.25)
	for g in range(5):
		P.registrar_ponto(1)
		await espera(0.25)
	confere("alvos acesos durante a partida: de 2 a 4", P.leds_ativos.size() >= 2 and P.leds_ativos.size() <= 4)
	P.scores.assign([5, 3, 9, 2, 7, 4, 6, 1])
	P._finalizar_partida()
	await espera(4.0)
	confere("resultado com os 8", P.partida_finalizada)
	var D := root.get_node("ChampionsDb")
	var torneios: Array = D.listar_por_tipo("TORNEIO")
	confere("a partida do evento entrou no Mural como TORNEIO, com o pódio", torneios.size() == 1 and str(torneios[0]["titulo"]) == "FEIRA TESTE" and str(torneios[0]["top3"][0]["nome"]) == "CAIO" and str(torneios[0]["top3"][1]["nome"]) == "EDUARDO" and str(torneios[0]["top3"][2]["nome"]) == "GUILHERME")

	print("4. O OPERADOR ESPETA O PENDRIVE; PARTIDA 2: a Ana volta e o Ivo é novo")
	root.set_meta("pular_patrocinadores_opening_uma_vez", true)
	change_scene_to_file("res://scenes/opening.tscn")
	await espera(3.0)
	var c0: Dictionary = L.conferir_pendrive()
	confere("conferência sem pendrive: 8 na máquina, 8 faltando", not bool(c0["tem"]) and int(c0["na_maquina"]) == 8 and int(c0["faltam"]) == 8)
	DirAccess.make_dir_recursive_absolute(raiz_pen)
	await espera(8.0)
	confere("espetou o pendrive: os cadastros desceram sozinhos", not L.pendente and FileAccess.file_exists(pen.path_join("leads.csv")) and FileAccess.get_file_as_string(pen.path_join("leads.csv")).contains("helo@gmail.com"))
	O = current_scene
	await escolher_evento_no_menu()
	await acao("input_start")
	await esperar_lobby()
	confere("a tela dos eventos mostra: PENDRIVE EM DIA", L._lobby._pen.text.begins_with("PENDRIVE EM DIA") and bool(L.conferir_pendrive()["em_dia"]))
	await foto("v10_lobby_pendrive_em_dia")
	await acao("input_start")
	await espera(2.0)
	confere("START na tela dos eventos = JOGAR", not L.lobby_aberto() and O.escolhendo_players)
	await acao("input_start")
	await espera(0.6)
	await esperar_ficha()
	await preencher("ana@gmail.com")
	await espera(0.5)
	confere("reconheceu: nome, idade, cidade e telefone voltaram sozinhos", L._campo_nome.text == "Ana Lima" and L._campo_idade.text == "9" and L._lugar == ["Brasil", "SP", "Campinas"]
		and L._campo_tel.text == "19987654321" and L._recado.text.begins_with("BEM-VINDO DE VOLTA, ANA") and T._alvo == L._bt_confirmar)
	await foto("v11_bem_vindo_de_volta")
	await clicar_em("CONFIRMAR")
	await espera(0.8)
	await preencher("ivo@hotmail.com", "ivo", "12", ["OK"], "11944443333")
	await clicar_em("CONFIRMAR")
	await esperar_cena("play.tscn", 25000)
	confere("a partida 2 começou com 2 jogadores", current_scene.scene_file_path.ends_with("play.tscn") and current_scene.total_players == 2)
	confere("9 jogadores, 10 cadastros; a Ana com 2 visitas (não duplicou)", L.total() == 9 and L.visitas() == 10 and int(L.procurar("ana@gmail.com")["visitas"]) == 2)
	confere("com o pendrive espetado: gravado antes de a partida começar", not L.pendente)
	var ev_feira: Dictionary = {}
	for ev in L.eventos_resumo():
		if str(ev["nome"]) == "FEIRA TESTE":
			ev_feira = ev
	confere("contadores: 2 partidas de evento (as 2 no FEIRA TESTE), 0 de arcade", A.partidas_evento == 2 and A.partidas_arcade == 0 and int(ev_feira["partidas"]) == 2 and int(ev_feira["jogadores"]) == 9 and int(ev_feira["cadastros"]) == 10)

	print("5. O QUE FICOU NO PENDRIVE")
	for nome in ["leads.csv", "leads_excel.csv", "leads.json", "visitas.csv", "eventos.csv", "partidas.csv", "resumo.txt", "LEIA-ME.txt"]:
		confere("existe " + nome, FileAccess.file_exists(pen.path_join(nome)))
	var csv := linhas_de(pen.path_join("leads.csv"))
	confere("leads.csv: 9 jogadores, sem repetir", csv.size() == 10)
	confere("leads.csv tem as colunas telefone, cidade, estado e pais", csv[0] == "id,nome,email,telefone,idade,cidade,estado,pais,primeira_visita,ultima_visita,visitas,evento,modo,autorizou_contato,maquina")
	var ana := ""
	for l in csv:
		if l.contains("ana@gmail.com"):
			ana = l
	confere("linha da Ana: telefone, cidade, 2 visitas, evento FEIRA TESTE", ana.contains(",ana@gmail.com,55 19 98765-4321,9,Campinas,SP,Brasil,") and ana.contains(",2,FEIRA TESTE,EVENTO,"))
	confere("visitas.csv: 10 linhas (uma por cadastro), com telefone e cidade", linhas_de(pen.path_join("visitas.csv")).size() == 11 and linhas_de(pen.path_join("visitas.csv"))[1].ends_with(",55 19 98765-4321,Campinas,SP,Brasil"))
	var resumo := FileAccess.get_file_as_string(pen.path_join("resumo.txt"))
	confere("resumo.txt com as contas certas", resumo.contains("jogadores diferentes ........ 9") and resumo.contains("cadastros (um por partida) .. 10") and resumo.contains("jogaram mais de uma vez ..... 1")
		and resumo.contains("EVENTO: FEIRA TESTE") and resumo.contains("com telefone ................ 9") and resumo.contains("Campinas - SP (Brasil)"))
	print("----- resumo.txt -----")
	print(resumo)
	confere("partidas.csv e eventos.csv com os números", FileAccess.get_file_as_string(pen.path_join("partidas.csv")).contains("EVENTO,2") and FileAccess.get_file_as_string(pen.path_join("eventos.csv")).contains("FEIRA TESTE,") and FileAccess.get_file_as_string(pen.path_join("eventos.csv")).contains(",2,9,10,"))
	confere("nenhum crédito pedido nem gasto", A.creditos == 0)

	print("6. PENDRIVE: O QUE JÁ ESTÁ NELE NÃO SE REPETE")
	var antes_json := FileAccess.get_file_as_string(pen.path_join("leads.json"))
	confere("descarregar de novo sem nada novo: os arquivos ficam iguais", L.gravar_no_pendrive() and L.gravar_no_pendrive() and FileAccess.get_file_as_string(pen.path_join("leads.json")) == antes_json
		and linhas_de(pen.path_join("visitas.csv")).size() == 11 and linhas_de(pen.path_join("leads.csv")).size() == 10)
	# tira o pendrive, cadastra mais um, e põe nele (de outra máquina) um cadastro que esta não tem
	DirAccess.rename_absolute(raiz_pen, raiz_pen + "_fora")
	L._destinos.clear()
	L.registrar("Joana Dias", "joana@gmail.com", 22, "EVENTO", "55 11 97777-1111", "Santos", "SP", "Brasil")
	L.fechar_cadastros()
	var f := FileAccess.open((raiz_pen + "_fora").path_join("OlhoNoLance_Leads/visitas.csv"), FileAccess.READ_WRITE)
	f.seek_end()
	f.store_string("2026-11-20,10:00:00,LOUTRA,Zeca Outro,zeca@gmail.com,30,EVENTO,FEIRA TESTE,M-OUTRA,55 11 96666-2222,Osasco,SP,Brasil\r\n")
	f.close()
	confere("sem pendrive: nada a conferir, os dados esperam na máquina", not bool(L.conferir_pendrive()["tem"]) and L.pendente)
	DirAccess.rename_absolute(raiz_pen + "_fora", raiz_pen)
	L._destinos.clear()
	L._tinha_pen = true      # (segura a gravação automática: o teste quer ver a conta antes)
	L._erro_pen = "teste"
	var c1: Dictionary = L.conferir_pendrive()
	confere("conferência: 10 já estão, 1 novo para gravar, 1 só no pendrive", bool(c1["tem"]) and int(c1["ja_estao"]) == 10 and int(c1["faltam"]) == 1 and int(c1["so_no_pen"]) == 1 and not bool(c1["em_dia"]))
	L._erro_pen = ""
	print("   ", L.texto_conferencia())
	root.set_meta("pular_patrocinadores_opening_uma_vez", true)
	change_scene_to_file("res://scenes/opening.tscn")
	await esperar_cena("opening.tscn", 15000)
	await espera(7.0)
	O = current_scene
	await escolher_evento_no_menu()
	await acao("input_start")
	await esperar_lobby()
	await clicar_em("DESCARREGAR NO PENDRIVE")
	await espera(0.8)
	var c2: Dictionary = L.conferir_pendrive()
	confere("descarregou: pendrive em dia, 12 cadastros nos dois, nenhum repetido", bool(c2["em_dia"]) and int(c2["na_maquina"]) == 12 and int(c2["faltam"]) == 0 and int(c2["so_no_pen"]) == 0
		and linhas_de(pen.path_join("visitas.csv")).size() == 13 and linhas_de(pen.path_join("leads.csv")).size() == 12 and L.total() == 11)
	confere("o jogador que só estava no pendrive entrou na máquina, com telefone e cidade", str(L.procurar("zeca@gmail.com").get("telefone", "")) == "55 11 96666-2222" and str(L.procurar("zeca@gmail.com").get("cidade", "")) == "Osasco")
	await foto("v12_lobby_descarregado")

	print("7. VER LEADS E APAGAR O EVENTO, NA TELA DOS EVENTOS")
	await clicar_em("VER LEADS")
	await espera(0.5)
	confere("VER LEADS abre a lista do evento (11 jogadores, 2 páginas)", L._lobby._leads_painel != null and L.leads_do_evento("FEIRA TESTE").size() == 11)
	await foto("v13_leads")
	await clicar_em("PRÓXIMOS")
	await espera(0.4)
	confere("PRÓXIMOS vai para a página 2", L._lobby._leads_pagina == 1)
	await tecla(KEY_ESCAPE)
	await espera(0.5)
	confere("ESC fecha os leads e continua na tela dos eventos", L._lobby != null and L._lobby._leads_painel == null)
	await clicar_em("APAGAR EVENTO")
	await espera(0.4)
	confere("apagar pede o 2o aperto", L.total() == 11 and L._lobby._bt_apagar.text.begins_with("APAGAR MESMO"))
	await foto("v14_apagar_mesmo")
	await clicar_em("APAGAR MESMO")
	await espera(0.6)
	confere("evento apagado da máquina: 0 jogadores, 0 cadastros; sobrou COPA DA ESCOLA", L.total() == 0 and L.visitas() == 0 and L.eventos_resumo().size() == 1 and L._lobby._escolhido == "COPA DA ESCOLA")
	var c3: Dictionary = L.conferir_pendrive()
	confere("conferência: os 12 do pendrive são de evento apagado e saem dele", int(c3["saem"]) == 12 and int(c3["so_no_pen"]) == 0)
	await clicar_em("DESCARREGAR NO PENDRIVE")
	await espera(0.8)
	confere("depois da descarga o pendrive também ficou sem eles", linhas_de(pen.path_join("leads.csv")).size() == 1 and linhas_de(pen.path_join("visitas.csv")).size() == 1)
	confere("o que estava no pendrive não voltou para a máquina", L.total() == 0)
	confere("a versão anterior ficou na cópia de segurança do pendrive", FileAccess.get_file_as_string(pen.path_join("copia_de_seguranca/leads.csv")).contains("ana@gmail.com"))
	await clicar_em("VOLTAR AO MENU")
	await espera(0.8)
	confere("VOLTAR AO MENU fecha a tela", not L.lobby_aberto())
	L._apagados.clear()
	L.ligar(false)
	L.apagar_tudo()
	L.definir_evento("")
	L.ultimo_lugar = ["Brasil", "", ""]
	L.ligar(true)
	A.definir_modo("free")
	A.zerar_estatisticas()
	print("RESULTADO: ", "TUDO CERTO" if falhas == 0 else "%d FALHA(S)" % falhas)
	quit(1 if falhas > 0 else 0)
