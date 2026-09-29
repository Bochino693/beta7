extends Node

signal dados_atualizados

const CAMINHO: String = "user://arcade_data.cfg"

var modo_operacao: String = "free"
var creditos: int = 0
var partidas_total: int = 0
var partidas_arcade: int = 0
var partidas_copa: int = 0


func _ready() -> void:
	carregar()


func carregar() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CAMINHO) != OK:
		salvar()
		return
	modo_operacao = str(cfg.get_value("maquina", "modo_operacao", "free"))
	if modo_operacao != "credito":
		modo_operacao = "free"
	creditos = int(max(0, int(cfg.get_value("maquina", "creditos", 0))))
	partidas_total = int(max(0, int(cfg.get_value("estatisticas", "partidas_total", 0))))
	partidas_arcade = int(max(0, int(cfg.get_value("estatisticas", "partidas_arcade", 0))))
	partidas_copa = int(max(0, int(cfg.get_value("estatisticas", "partidas_copa", 0))))


func salvar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("maquina", "modo_operacao", modo_operacao)
	cfg.set_value("maquina", "creditos", creditos)
	cfg.set_value("estatisticas", "partidas_total", partidas_total)
	cfg.set_value("estatisticas", "partidas_arcade", partidas_arcade)
	cfg.set_value("estatisticas", "partidas_copa", partidas_copa)
	cfg.save(CAMINHO)


func definir_modo(novo_modo: String) -> void:
	modo_operacao = "credito" if novo_modo == "credito" else "free"
	salvar()
	emit_signal("dados_atualizados")


func adicionar_credito(quantidade: int = 1) -> void:
	creditos = int(max(0, creditos + quantidade))
	salvar()
	emit_signal("dados_atualizados")


func pode_jogar() -> bool:
	return modo_operacao == "free" or creditos > 0


func consumir_credito() -> bool:
	if modo_operacao == "free":
		return true
	if creditos <= 0:
		return false
	creditos -= 1
	salvar()
	emit_signal("dados_atualizados")
	return true


func registrar_partida(tipo: String) -> void:
	partidas_total += 1
	if tipo.to_lower() == "copa":
		partidas_copa += 1
	else:
		partidas_arcade += 1
	salvar()
	emit_signal("dados_atualizados")


func zerar_estatisticas() -> void:
	partidas_total = 0
	partidas_arcade = 0
	partidas_copa = 0
	salvar()
	emit_signal("dados_atualizados")
