extends Node

var total_players_futebol: int = 1
var cores_players_futebol: Array = [
	Color(0.1, 0.75, 1.0),
	Color(0.2, 1.0, 0.3),
	Color(1.0, 0.15, 0.15),
	Color(1.0, 0.85, 0.05)
]

func configurar_players_futebol(qtd: int, cores: Array) -> void:
	total_players_futebol = clamp(qtd, 1, 4)

	cores_players_futebol.clear()

	for i in range(total_players_futebol):
		if i < cores.size():
			cores_players_futebol.append(cores[i])
		else:
			cores_players_futebol.append(Color.white)

	print("PLAYERS GLOBAL CONFIGURADO: ", total_players_futebol)
