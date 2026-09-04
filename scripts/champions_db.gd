extends Node

# ============================================================
# CHAMPIONS DB
# Banco local do Mural de Campeões.
# Salva competições finalizadas em user://champions_wall.json
#
# NOVO NESTA VERSÃO:
# - Campo "tipo" da competição: COPA / TORNEIO / CAMPEONATO.
# - "tipo_nome" legível salvo junto.
# - Top 3 normalizado: garante nome e estatísticas mesmo
#   se o registro vier incompleto (nunca salva campeão sem nome).
# - Helpers: listar_por_tipo() e contar_por_tipo().
# ============================================================

const DB_PATH: String = "user://champions_wall.json"
const SCHEMA_VERSION: int = 2

# Tipos válidos de competição.
const TIPOS_VALIDOS: Array[String] = ["COPA", "TORNEIO", "CAMPEONATO"]

var dados: Dictionary = {
	"schema_version": SCHEMA_VERSION,
	"copas": []
}


signal banco_atualizado


func _ready() -> void:
	carregar()


func carregar() -> void:
	dados = {
		"schema_version": SCHEMA_VERSION,
		"copas": []
	}

	if not FileAccess.file_exists(DB_PATH):
		salvar()
		return

	var f := FileAccess.open(DB_PATH, FileAccess.READ)

	if f == null:
		push_warning("ChampionsDb: não consegui abrir o banco: " + DB_PATH)
		return

	var txt: String = f.get_as_text()
	f.close()

	if txt.strip_edges() == "":
		salvar()
		return

	var parsed: Variant = JSON.parse_string(txt)

	if parsed is Dictionary:
		dados = parsed
	else:
		push_warning("ChampionsDb: JSON inválido. Recriando banco.")
		dados = {
			"schema_version": SCHEMA_VERSION,
			"copas": []
		}
		salvar()
		return

	if not dados.has("schema_version"):
		dados["schema_version"] = SCHEMA_VERSION

	if not dados.has("copas") or not (dados["copas"] is Array):
		dados["copas"] = []

	_limpar_registros_invalidos()
	_ordenar_copas()


func salvar() -> void:
	var f := FileAccess.open(DB_PATH, FileAccess.WRITE)

	if f == null:
		push_warning("ChampionsDb: não consegui salvar banco: " + DB_PATH)
		return

	f.store_string(JSON.stringify(dados, "\t"))
	f.close()

	print("ChampionsDb: banco salvo (%d competições) em %s" % [
		dados.get("copas", []).size(),
		ProjectSettings.globalize_path(DB_PATH)
	])


func criar_id_copa() -> String:
	var d := Time.get_datetime_dict_from_system()
	var tick: int = int(Time.get_ticks_msec() % 1000000)

	return "CUP_%04d%02d%02d_%02d%02d%02d_%06d" % [
		int(d["year"]),
		int(d["month"]),
		int(d["day"]),
		int(d["hour"]),
		int(d["minute"]),
		int(d["second"]),
		tick
	]


func registrar_copa(copa: Dictionary) -> Dictionary:
	carregar()

	var obj: Dictionary = _normalizar_copa(copa)
	var id: String = str(obj.get("id", ""))

	if id == "":
		id = criar_id_copa()
		obj["id"] = id

	var copas: Array = dados.get("copas", [])
	var index_existente: int = _buscar_index_por_id(id)

	if index_existente >= 0:
		copas[index_existente] = obj
	else:
		copas.push_front(obj)

	dados["copas"] = copas

	_limpar_registros_invalidos()
	_ordenar_copas()
	salvar()

	banco_atualizado.emit()

	print("ChampionsDb: registrada %s [%s] • campeão: %s" % [
		str(obj.get("titulo", "")),
		str(obj.get("tipo", "COPA")),
		_nome_campeao(obj)
	])

	return obj


func listar_copas() -> Array:
	carregar()
	return dados.get("copas", []).duplicate(true)


func listar_por_tipo(tipo: String) -> Array:
	var alvo := tipo.strip_edges().to_upper()
	var todas := listar_copas()

	if alvo == "" or alvo == "TODOS":
		return todas

	var res: Array = []

	for c in todas:
		if c is Dictionary and str(c.get("tipo", "COPA")).to_upper() == alvo:
			res.append(c)

	return res


func contar_por_tipo() -> Dictionary:
	var todas := listar_copas()

	var cont := {
		"TODOS": todas.size(),
		"COPA": 0,
		"TORNEIO": 0,
		"CAMPEONATO": 0
	}

	for c in todas:
		if not (c is Dictionary):
			continue

		var t := str(c.get("tipo", "COPA")).to_upper()

		if cont.has(t):
			cont[t] = int(cont[t]) + 1

	return cont


func obter_copa(id: String) -> Dictionary:
	carregar()

	for c in dados.get("copas", []):
		if not (c is Dictionary):
			continue

		if str(c.get("id", "")) == id:
			return c.duplicate(true)

	return {}


func excluir_copa(id: String) -> bool:
	carregar()

	var copas: Array = dados.get("copas", [])
	var novo: Array = []
	var removeu: bool = false

	for c in copas:
		if not (c is Dictionary):
			continue

		if str(c.get("id", "")) == id:
			removeu = true
			continue

		novo.append(c)

	if removeu:
		dados["copas"] = novo
		salvar()
		banco_atualizado.emit()

	return removeu


func apagar_tudo() -> void:
	dados = {
		"schema_version": SCHEMA_VERSION,
		"copas": []
	}

	salvar()
	banco_atualizado.emit()


func total_copas() -> int:
	carregar()
	return int(dados.get("copas", []).size())


# ============================================================
# INTERNOS
# ============================================================
func _buscar_index_por_id(id: String) -> int:
	var copas: Array = dados.get("copas", [])

	for i in range(copas.size()):
		if not (copas[i] is Dictionary):
			continue

		if str(copas[i].get("id", "")) == id:
			return i

	return -1


func _limpar_registros_invalidos() -> void:
	var copas: Array = dados.get("copas", [])
	var limpas: Array = []

	for c in copas:
		if not (c is Dictionary):
			continue

		limpas.append(_normalizar_copa(c))

	dados["copas"] = limpas


func _ordenar_copas() -> void:
	var copas: Array = dados.get("copas", [])

	copas.sort_custom(func(a: Variant, b: Variant) -> bool:
		var da: Dictionary = a if a is Dictionary else {}
		var db: Dictionary = b if b is Dictionary else {}

		var ta: float = float(da.get("finished_at_unix", 0.0))
		var tb: float = float(db.get("finished_at_unix", 0.0))

		return ta > tb
	)

	dados["copas"] = copas


func _tipo_valido(tipo_raw: String) -> String:
	var t := tipo_raw.strip_edges().to_upper()

	if t in TIPOS_VALIDOS:
		return t

	return "COPA"


func _tipo_nome(tipo: String) -> String:
	match tipo:
		"TORNEIO":
			return "Torneio"
		"CAMPEONATO":
			return "Campeonato"
		_:
			return "Copa"


func _nome_campeao(obj: Dictionary) -> String:
	var t3: Variant = obj.get("top3", [])

	if t3 is Array and t3.size() > 0 and t3[0] is Dictionary:
		return str(t3[0].get("nome", "Campeão"))

	return "Sem campeão"



func _normalizar_top3(top3_var: Variant) -> Array:
	var res: Array = []

	if not (top3_var is Array):
		return res

	var posicao := 1

	for item in top3_var:
		if not (item is Dictionary):
			continue

		var d: Dictionary = item.duplicate(true)

		# Se as estatísticas vierem dentro de outro Dictionary, joga tudo para a raiz.
		for bloco_nome in ["estatisticas", "stats", "resumo", "dados"]:
			if d.has(bloco_nome) and d[bloco_nome] is Dictionary:
				var bloco: Dictionary = d[bloco_nome]
				for k in bloco.keys():
					if not d.has(k):
						d[k] = bloco[k]

		# Nome nunca vazio.
		d["nome"] = _coalesce_str(d, [
			"nome",
			"name",
			"jogador",
			"player_name",
			"player"
		], "---")

		var gols_normais := _coalesce_int(d, [
			"gols_normais",
			"gols_normal",
			"gols_tempo_normal",
			"normal_gols"
		])

		var gols_prorrogacao := _coalesce_int(d, [
			"gols_prorrogacao",
			"gols_prorro",
			"gols_extra",
			"prorrogacao_gols"
		])

		var penaltis_total := _coalesce_int(d, [
			"penaltis_total",
			"penaltis",
			"penaltis_marcados",
			"gols_penalti",
			"gols_penaltis"
		])

		var gols_total := _coalesce_int(d, [
			"gols_total",
			"gols",
			"score",
			"pontuacao"
		], -1)

		if gols_total < 0:
			gols_total = gols_normais + gols_prorrogacao + penaltis_total

		var jogos_total := _coalesce_int(d, [
			"jogos_total",
			"jogos",
			"partidas",
			"partidas_jogadas",
			"jogos_disputados",
			"matches"
		])

		var vitorias_total := _coalesce_int(d, [
			"vitorias_total",
			"vitorias",
			"wins",
			"partidas_vencidas"
		])

		var pontos_grupo := _coalesce_int(d, [
			"pontos_grupo",
			"pontos",
			"pontos_tabela",
			"pts"
		])

		d["posicao"] = _coalesce_int(d, [
			"posicao",
			"rank",
			"colocacao"
		], posicao)

		d["gols_total"] = gols_total
		d["gols_normais"] = gols_normais
		d["gols_prorrogacao"] = gols_prorrogacao
		d["penaltis_total"] = penaltis_total

		d["jogos_total"] = jogos_total
		d["vitorias_total"] = vitorias_total
		d["pontos_grupo"] = pontos_grupo

		d["grupo"] = _coalesce_str(d, ["grupo", "grupo_nome"], "-")
		d["fase_nome"] = _coalesce_str(d, ["fase_nome", "fase"], "-")

		print("TOP3 NORMALIZADO -> ", d["nome"], 
			" | gols=", d["gols_total"],
			" | jogos=", d["jogos_total"],
			" | vitórias=", d["vitorias_total"],
			" | pontos=", d["pontos_grupo"],
			" | pênaltis=", d["penaltis_total"]
		)

		res.append(d)

		posicao += 1

		if res.size() >= 3:
			break

	return res


func _normalizar_copa(copa: Dictionary) -> Dictionary:
	var d := Time.get_datetime_dict_from_system()
	var unix: float = Time.get_unix_time_from_system()

	var obj: Dictionary = copa.duplicate(true)

	if not obj.has("id"):
		obj["id"] = ""

	obj["schema_version"] = SCHEMA_VERSION

	# Tipo da competição: COPA / TORNEIO / CAMPEONATO.
	var tipo := _tipo_valido(str(obj.get("tipo", "COPA")))
	obj["tipo"] = tipo
	obj["tipo_nome"] = _tipo_nome(tipo)

	# Compatibilidade com registros antigos que usavam timestamp_unix.
	if not obj.has("finished_at_unix") and obj.has("timestamp_unix"):
		obj["finished_at_unix"] = float(obj.get("timestamp_unix", unix))

	# Compatibilidade com registros antigos que usavam data_hora_br.
	if not obj.has("finished_at_text") and obj.has("data_hora_br"):
		obj["finished_at_text"] = str(obj.get("data_hora_br", ""))

	if not obj.has("finished_at_unix"):
		obj["finished_at_unix"] = unix

	if not obj.has("finished_at_text") or str(obj.get("finished_at_text", "")).strip_edges() == "":
		obj["finished_at_text"] = "%02d/%02d/%04d às %02d:%02d" % [
			int(d["day"]),
			int(d["month"]),
			int(d["year"]),
			int(d["hour"]),
			int(d["minute"])
		]

	if not obj.has("titulo") or str(obj.get("titulo", "")).strip_edges() == "":
		obj["titulo"] = "%s %s" % [
			str(obj.get("tipo_nome", "Copa")),
			str(obj.get("finished_at_text", ""))
		]

	var top3_ok := _normalizar_top3(obj.get("top3", []))
	obj["top3"] = top3_ok

	var resumo_origem: Variant = obj.get("resumo", {})

	# Compatibilidade com registros antigos que salvaram "estatisticas" em vez de "resumo".
	if (not (resumo_origem is Dictionary) or (resumo_origem as Dictionary).is_empty()) and obj.has("estatisticas"):
		resumo_origem = obj.get("estatisticas", {})

	obj["resumo"] = _normalizar_resumo(resumo_origem, top3_ok)

	return obj


func _coalesce_int(d: Dictionary, chaves: Array, padrao: int = 0) -> int:
	for k in chaves:
		if d.has(k):
			var v: Variant = d[k]

			if typeof(v) == TYPE_INT:
				return int(v)

			if typeof(v) == TYPE_FLOAT:
				return int(v)

			if typeof(v) == TYPE_STRING:
				var s := str(v).strip_edges()

				if s.is_valid_int():
					return int(s)

				if s.is_valid_float():
					return int(float(s))

	return padrao


func _coalesce_str(d: Dictionary, chaves: Array, padrao: String = "-") -> String:
	for k in chaves:
		if d.has(k):
			var s := str(d[k]).strip_edges()
			if s != "":
				return s
	return padrao


func _normalizar_resumo(resumo_var: Variant, top3: Array) -> Dictionary:
	var r: Dictionary = {}

	if resumo_var is Dictionary:
		r = resumo_var.duplicate(true)

	if not r.has("fase_final") or str(r.get("fase_final", "")).strip_edges() == "":
		r["fase_final"] = "Competição encerrada"

	var gols_top3_salvo := _coalesce_int(r, ["gols_top3"], -1)

	if gols_top3_salvo < 0:
		var soma := 0

		for p in top3:
			if p is Dictionary:
				soma += int(p.get("gols_total", 0))

		r["gols_top3"] = soma

	if not r.has("partidas_total"):
		r["partidas_total"] = _coalesce_int(r, ["partidas", "jogos_total", "jogos"])

	if not r.has("grupos_total"):
		r["grupos_total"] = _coalesce_int(r, ["grupos", "qtd_grupos"])

	if not r.has("jogadores_reais"):
		r["jogadores_reais"] = _coalesce_int(r, ["players_reais", "jogadores", "total_jogadores"])

	return r
