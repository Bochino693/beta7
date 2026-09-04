extends Node

var total_jogadores_copa: int = 0
var grupos_copa: Array = []
var partidas_copa: Array = []
var partida_atual_copa_index: int = 0
var partida_copa_atual: Dictionary = {}
var resultado_copa_pendente: Dictionary = {}


func configurar_copa_grupos(total: int, grupos: Array) -> void:
	total_jogadores_copa = total
	grupos_copa = grupos.duplicate(true)
	partidas_copa.clear()
	partida_atual_copa_index = 0
	partida_copa_atual.clear()
	resultado_copa_pendente.clear()

	print("CUP GLOBAL CONFIGURADO: ", total_jogadores_copa, " jogadores")


func salvar_estado_copa(grupos: Array, partidas: Array, partida_index: int = 0) -> void:
	grupos_copa = grupos.duplicate(true)
	partidas_copa = partidas.duplicate(true)
	partida_atual_copa_index = partida_index


func configurar_partida_atual(dados_partida: Dictionary, index: int, grupos: Array, partidas: Array) -> void:
	partida_copa_atual = dados_partida.duplicate(true)
	partida_atual_copa_index = index
	grupos_copa = grupos.duplicate(true)
	partidas_copa = partidas.duplicate(true)


func salvar_resultado_pendente(partida_index: int, ranking: Array) -> void:
	resultado_copa_pendente = {
		"partida_index": partida_index,
		"ranking": ranking.duplicate(true)
	}


func consumir_resultado_pendente() -> Dictionary:
	var r := resultado_copa_pendente.duplicate(true)
	resultado_copa_pendente.clear()
	return r


func limpar_copa() -> void:
	total_jogadores_copa = 0
	grupos_copa.clear()
	partidas_copa.clear()
	partida_atual_copa_index = 0
	partida_copa_atual.clear()
	resultado_copa_pendente.clear()
