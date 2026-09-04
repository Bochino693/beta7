extends Node

const CAMINHO_CONFIG: String = "user://configuracoes.cfg"

# Ajuste aqui se seu ranking usa outro arquivo
const CAMINHOS_RANKING: Array[String] = [
	"user://ranking.save",
	"user://ranking.cfg",
	"user://ranking.json",
	"user://ranking.dat"
]

var canvas: CanvasLayer
var root: Control

var painel: Panel
var titulo: Label

var tempo_label: Label
var tempo_spin: SpinBox

var modo_label: Label
var modo_option: OptionButton

var botao_salvar: Button
var botao_resetar_ranking: Button
var botao_voltar: Button

var tempo_partida: int = 60
var modo_jogo: String = "todos"


func _ready() -> void:
	_carregar_configuracoes()
	_criar_interface()


func _process(delta: float) -> void:
	pass


func _criar_interface() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)

	root = Control.new()
	root.name = "TelaConfiguracoes"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)

	var fundo := ColorRect.new()
	fundo.color = Color(0.02, 0.02, 0.04, 1.0)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(fundo)

	painel = Panel.new()
	painel.custom_minimum_size = Vector2(620, 560)
	painel.position = Vector2(0, 0)
	root.add_child(painel)

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.05, 0.06, 0.10, 0.96)
	estilo.border_color = Color(0.0, 0.85, 1.0, 1.0)
	estilo.set_border_width_all(3)
	estilo.corner_radius_top_left = 22
	estilo.corner_radius_top_right = 22
	estilo.corner_radius_bottom_left = 22
	estilo.corner_radius_bottom_right = 22
	painel.add_theme_stylebox_override("panel", estilo)

	titulo = Label.new()
	titulo.text = "CONFIGURAÇÕES"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 42)
	titulo.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	painel.add_child(titulo)

	tempo_label = Label.new()
	tempo_label.text = "Tempo de partida"
	tempo_label.add_theme_font_size_override("font_size", 26)
	tempo_label.add_theme_color_override("font_color", Color.WHITE)
	painel.add_child(tempo_label)

	tempo_spin = SpinBox.new()
	tempo_spin.min_value = 10
	tempo_spin.max_value = 600
	tempo_spin.step = 5
	tempo_spin.value = tempo_partida
	tempo_spin.add_theme_font_size_override("font_size", 24)
	painel.add_child(tempo_spin)

	modo_label = Label.new()
	modo_label.text = "Modo de jogo"
	modo_label.add_theme_font_size_override("font_size", 26)
	modo_label.add_theme_color_override("font_color", Color.WHITE)
	painel.add_child(modo_label)

	modo_option = OptionButton.new()
	modo_option.add_item("Todos", 0)
	modo_option.add_item("Somente Arcade", 1)
	modo_option.add_item("Somente Copa", 2)
	modo_option.add_theme_font_size_override("font_size", 24)
	painel.add_child(modo_option)

	if modo_jogo == "arcade":
		modo_option.select(1)
	elif modo_jogo == "copa":
		modo_option.select(2)
	else:
		modo_option.select(0)

	botao_salvar = Button.new()
	botao_salvar.text = "SALVAR CONFIGURAÇÕES"
	botao_salvar.add_theme_font_size_override("font_size", 24)
	botao_salvar.pressed.connect(_salvar_configuracoes)
	painel.add_child(botao_salvar)

	botao_resetar_ranking = Button.new()
	botao_resetar_ranking.text = "RESETAR RANKING"
	botao_resetar_ranking.add_theme_font_size_override("font_size", 24)
	botao_resetar_ranking.pressed.connect(_resetar_ranking)
	painel.add_child(botao_resetar_ranking)

	botao_voltar = Button.new()
	botao_voltar.text = "VOLTAR"
	botao_voltar.add_theme_font_size_override("font_size", 24)
	botao_voltar.pressed.connect(_voltar)
	painel.add_child(botao_voltar)

	_aplicar_estilo_botao(botao_salvar, Color(0.0, 0.65, 1.0))
	_aplicar_estilo_botao(botao_resetar_ranking, Color(1.0, 0.15, 0.15))
	_aplicar_estilo_botao(botao_voltar, Color(0.2, 1.0, 0.35))

	_ajustar_layout()


func _ajustar_layout() -> void:
	var tela := get_viewport().get_visible_rect().size

	painel.size = Vector2(620, 560)
	painel.position = (tela - painel.size) / 2.0

	titulo.position = Vector2(30, 35)
	titulo.size = Vector2(painel.size.x - 60, 60)

	tempo_label.position = Vector2(70, 130)
	tempo_label.size = Vector2(480, 40)

	tempo_spin.position = Vector2(70, 175)
	tempo_spin.size = Vector2(480, 55)

	modo_label.position = Vector2(70, 255)
	modo_label.size = Vector2(480, 40)

	modo_option.position = Vector2(70, 300)
	modo_option.size = Vector2(480, 55)

	botao_salvar.position = Vector2(70, 385)
	botao_salvar.size = Vector2(480, 55)

	botao_resetar_ranking.position = Vector2(70, 450)
	botao_resetar_ranking.size = Vector2(480, 55)

	botao_voltar.position = Vector2(70, 515)
	botao_voltar.size = Vector2(480, 45)


func _aplicar_estilo_botao(botao: Button, cor: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.04, 0.04, 0.06, 1.0)
	normal.border_color = cor
	normal.set_border_width_all(3)
	normal.corner_radius_top_left = 14
	normal.corner_radius_top_right = 14
	normal.corner_radius_bottom_left = 14
	normal.corner_radius_bottom_right = 14

	var hover := StyleBoxFlat.new()
	hover.bg_color = cor.darkened(0.35)
	hover.border_color = cor
	hover.set_border_width_all(4)
	hover.corner_radius_top_left = 14
	hover.corner_radius_top_right = 14
	hover.corner_radius_bottom_left = 14
	hover.corner_radius_bottom_right = 14

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = cor.darkened(0.15)
	pressed.border_color = Color.WHITE
	pressed.set_border_width_all(4)
	pressed.corner_radius_top_left = 14
	pressed.corner_radius_top_right = 14
	pressed.corner_radius_bottom_left = 14
	pressed.corner_radius_bottom_right = 14

	botao.add_theme_stylebox_override("normal", normal)
	botao.add_theme_stylebox_override("hover", hover)
	botao.add_theme_stylebox_override("pressed", pressed)
	botao.add_theme_color_override("font_color", Color.WHITE)
	botao.add_theme_color_override("font_hover_color", Color.WHITE)
	botao.add_theme_color_override("font_pressed_color", Color.WHITE)


func _salvar_configuracoes() -> void:
	tempo_partida = int(tempo_spin.value)

	var id_modo := modo_option.get_selected_id()

	if id_modo == 1:
		modo_jogo = "arcade"
	elif id_modo == 2:
		modo_jogo = "copa"
	else:
		modo_jogo = "todos"

	var config := ConfigFile.new()
	config.set_value("jogo", "tempo_partida", tempo_partida)
	config.set_value("jogo", "modo", modo_jogo)

	var erro := config.save(CAMINHO_CONFIG)

	if erro == OK:
		_mostrar_mensagem("Configurações salvas!")
	else:
		_mostrar_mensagem("Erro ao salvar configurações!")


func _carregar_configuracoes() -> void:
	var config := ConfigFile.new()
	var erro := config.load(CAMINHO_CONFIG)

	if erro != OK:
		tempo_partida = 60
		modo_jogo = "todos"
		return

	tempo_partida = int(config.get_value("jogo", "tempo_partida", 60))
	modo_jogo = str(config.get_value("jogo", "modo", "todos"))


func _resetar_ranking() -> void:
	for caminho in CAMINHOS_RANKING:
		if FileAccess.file_exists(caminho):
			DirAccess.remove_absolute(caminho)

	_mostrar_mensagem("Ranking resetado!")


func _voltar() -> void:
	# Coloque aqui a cena do menu, se quiser voltar direto:
	# get_tree().change_scene_to_file("res://scenes/main.tscn")

	queue_free()


func _mostrar_mensagem(texto: String) -> void:
	var msg := Label.new()
	msg.text = texto
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 24)
	msg.add_theme_color_override("font_color", Color(1.0, 1.0, 0.2))
	msg.position = Vector2(70, 85)
	msg.size = Vector2(480, 40)
	painel.add_child(msg)

	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = 1.4
	add_child(timer)

	timer.timeout.connect(func():
		if is_instance_valid(msg):
			msg.queue_free()
		timer.queue_free()
	)

	timer.start()
