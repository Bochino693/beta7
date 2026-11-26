extends Node

signal dados_atualizados

const CAMINHO: String = "user://arcade_data.cfg"

var modo_operacao: String = "free"
var creditos: int = 0
var partidas_total: int = 0
var partidas_arcade: int = 0
var partidas_copa: int = 0
var partidas_evento: int = 0


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
	creditos = maxi(0, int(cfg.get_value("maquina", "creditos", 0)))
	partidas_total = maxi(0, int(cfg.get_value("estatisticas", "partidas_total", 0)))
	partidas_arcade = maxi(0, int(cfg.get_value("estatisticas", "partidas_arcade", 0)))
	partidas_copa = maxi(0, int(cfg.get_value("estatisticas", "partidas_copa", 0)))
	partidas_evento = maxi(0, int(cfg.get_value("estatisticas", "partidas_evento", 0)))


func salvar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("maquina", "modo_operacao", modo_operacao)
	cfg.set_value("maquina", "creditos", creditos)
	cfg.set_value("estatisticas", "partidas_total", partidas_total)
	cfg.set_value("estatisticas", "partidas_arcade", partidas_arcade)
	cfg.set_value("estatisticas", "partidas_copa", partidas_copa)
	cfg.set_value("estatisticas", "partidas_evento", partidas_evento)
	cfg.save(CAMINHO)


func definir_modo(novo_modo: String) -> void:
	modo_operacao = "credito" if novo_modo == "credito" else "free"
	salvar()
	dados_atualizados.emit()


func adicionar_credito(quantidade: int = 1) -> void:
	creditos = maxi(0, creditos + quantidade)
	salvar()
	dados_atualizados.emit()


## A opção EVENTO está no menu do jogo, ao lado de ARCADE e COPA (vem ligada;
## dá para esconder em AJUSTES AVANÇADOS). A partida do EVENTO é um arcade de até 8 jogadores,
## SEM FICHA, com o cadastro (e-mail, nome, idade) de cada um antes de
## começar. ARCADE e COPA continuam como estão (livre ou crédito).
func evento() -> bool:
	return Leads.ligado


## "livre" | "credito" - como ARCADE e COPA são liberados.
func modo_atual() -> String:
	return "credito" if modo_operacao == "credito" else "livre"


## ARCADE e COPA não pedem ficha.
func livre() -> bool:
	return modo_operacao == "free"


func zerar_creditos() -> void:
	creditos = 0
	salvar()
	dados_atualizados.emit()


func pode_jogar() -> bool:
	return livre() or creditos > 0


func consumir_credito() -> bool:
	if livre():
		return true
	if creditos <= 0:
		return false
	creditos -= 1
	salvar()
	dados_atualizados.emit()
	return true


func registrar_partida(tipo: String) -> void:
	partidas_total += 1
	if tipo.to_lower() == "copa":
		partidas_copa += 1
	elif tipo.to_lower() == "evento":
		partidas_evento += 1
	else:
		partidas_arcade += 1
	salvar()
	dados_atualizados.emit()


## A partida foi liberada mas não começou (o cadastro do Modo Feira foi
## abandonado): o crédito volta e a partida sai da conta.
func devolver_partida(tipo: String) -> void:
	# (a partida do evento não gastou ficha: não há o que devolver)
	if tipo.to_lower() != "evento" and not livre():
		creditos += 1
	partidas_total = maxi(partidas_total - 1, 0)
	if tipo.to_lower() == "copa":
		partidas_copa = maxi(partidas_copa - 1, 0)
	elif tipo.to_lower() == "evento":
		partidas_evento = maxi(partidas_evento - 1, 0)
	else:
		partidas_arcade = maxi(partidas_arcade - 1, 0)
	salvar()
	dados_atualizados.emit()


## Zera o contador de um tipo só: "arcade", "copa" ou "evento".
func zerar_partidas(tipo: String) -> void:
	match tipo.to_lower():
		"arcade": partidas_arcade = 0
		"copa": partidas_copa = 0
		"evento": partidas_evento = 0
	partidas_total = partidas_arcade + partidas_copa + partidas_evento
	salvar()
	dados_atualizados.emit()


func zerar_estatisticas() -> void:
	partidas_total = 0
	partidas_arcade = 0
	partidas_copa = 0
	partidas_evento = 0
	salvar()
	dados_atualizados.emit()
