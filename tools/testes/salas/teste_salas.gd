extends SceneTree
## Teste das SALAS DOS CAMPEOES (Mural e Ranking): botoes da maquina, ESC,
## janela de limpar e volta sozinha ao menu.
##   godot --path . -s tools/testes/salas/teste_salas.gd   (fotos: SAIDA=/uma/pasta)
var falhas := 0
func confere(nome: String, certo: bool) -> void:
	if not certo:
		falhas += 1
	print(("  ok   " if certo else "  FALHOU ") + nome)
func espera(s: float) -> void:
	await create_timer(s).timeout
func foto(nome: String) -> void:
	await process_frame
	await process_frame
	if OS.get_environment("SAIDA") != "":
		root.get_texture().get_image().save_png(OS.get_environment("SAIDA").path_join(nome + ".png"))
func segurar(nome: String, p: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = nome
	ev.pressed = p
	Input.parse_input_event(ev)
	await process_frame
	await process_frame
func acao(nome: String) -> void:
	await segurar(nome, true)
	await segurar(nome, false)
	await process_frame
func tecla(codigo: Key) -> void:
	for p in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = codigo
		ev.physical_keycode = codigo
		ev.pressed = p
		Input.parse_input_event(ev)
		await process_frame
		await process_frame
func cena() -> String:
	return current_scene.scene_file_path.get_file() if current_scene != null else ""
func _initialize() -> void:
	await process_frame
	root.get_node("Leads").ligar(false)
	root.get_node("ArcadeData").definir_modo("free")
	var D := root.get_node("ChampionsDb")
	if D.total_copas() == 0:
		D.registrar_copa({"tipo": "COPA", "titulo": "COPA TESTE", "top3": [{"posicao": 1, "nome": "RAFA", "pontos": 9}, {"posicao": 2, "nome": "BIA", "pontos": 6}, {"posicao": 3, "nome": "CAIO", "pontos": 3}]})
	print("MURAL")
	# chega segurando START + SELECT (como na máquina)
	await segurar("input_start", true)
	await segurar("input_cup", true)
	change_scene_to_file("res://scenes/champions_wall.tscn")
	await espera(1.5)
	confere("segurando os botões ao chegar: não sai", cena() == "champions_wall.tscn")
	await segurar("input_start", false)
	await segurar("input_cup", false)
	await espera(0.3)
	var W := current_scene
	await foto("s1_mural")
	await acao("input_cup")
	await espera(0.3)
	confere("SELECT troca o filtro (TODOS -> COPA)", W.filtro_tipo == "COPA")
	await tecla(KEY_F9)
	await espera(0.3)
	confere("F9 abre a janela de limpar", W._janela_aberta())
	await acao("input_start")
	await espera(0.3)
	confere("START com a janela aberta não sai nem apaga", cena() == "champions_wall.tscn" and W._janela_aberta() and D.total_copas() > 0)
	await tecla(KEY_ESCAPE)
	await espera(0.3)
	confere("ESC fecha só a janela", cena() == "champions_wall.tscn" and not W._janela_aberta())
	W._abrir_ranking()
	await espera(2.0)
	print("RANKING")
	confere("abriu o ranking", cena() == "champions_ranking.tscn")
	var R := current_scene
	await foto("s2_ranking")
	await acao("input_cup")
	await espera(0.3)
	confere("SELECT troca a aba", R.modo_atual == "GOLS")
	await tecla(KEY_ESCAPE)
	await espera(2.0)
	confere("ESC / VOLTAR volta ao mural", cena() == "champions_wall.tscn")
	current_scene._abrir_ranking()
	await espera(2.0)
	await acao("input_start")
	await espera(2.0)
	confere("START volta ao mural", cena() == "champions_wall.tscn")
	current_scene._sem_uso = 89.5
	await espera(2.5)
	confere("parado 90 s: volta sozinho para o menu", cena() == "opening.tscn")
	await espera(2.0)
	change_scene_to_file("res://scenes/champions_wall.tscn")
	await espera(1.5)
	await acao("input_start")
	await espera(2.5)
	confere("START no mural volta ao menu", cena() == "opening.tscn")
	confere("seta do sistema escondida (cursor do jogo)", Input.mouse_mode == Input.MOUSE_MODE_HIDDEN)
	print("RESULTADO: ", "TUDO CERTO" if falhas == 0 else "%d FALHA(S)" % falhas)
	quit(1 if falhas > 0 else 0)
