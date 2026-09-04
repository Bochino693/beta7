extends Node
# ============================================================
# EstadoComp — persistência GENÉRICA de competições em andamento.
# Salva qualquer Dictionary (inclusive com Color/Vector2) em
# user://estados_competicao.json, sob uma "chave" (ex: "torneio36", "copa").
# Serve pra retomar de onde parou em caso de queda/fechamento.
# user:// é o caminho correto também no executável exportado.
# ============================================================

const PATH: String = "user://estados_competicao.json"

var _cache: Dictionary = {}


func _ready() -> void:
	_carregar_arquivo()


func salvar(chave: String, dados: Dictionary) -> void:
	_cache[chave] = _serializar(dados)
	_gravar_arquivo()


func carregar(chave: String) -> Dictionary:
	if not _cache.has(chave):
		return {}
	var v: Variant = _desserializar(_cache[chave])
	return v if v is Dictionary else {}


func tem(chave: String) -> bool:
	if not _cache.has(chave):
		return false
	var v: Variant = _cache[chave]
	return v is Dictionary and not (v as Dictionary).is_empty()


func limpar(chave: String) -> void:
	if _cache.has(chave):
		_cache.erase(chave)
		_gravar_arquivo()


func limpar_tudo() -> void:
	_cache = {}
	_gravar_arquivo()


# --- arquivo ---
func _carregar_arquivo() -> void:
	_cache = {}
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	if txt.strip_edges() == "":
		return
	var parsed: Variant = JSON.parse_string(txt)
	if parsed is Dictionary:
		_cache = parsed


func _gravar_arquivo() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("EstadoComp: não consegui gravar " + PATH)
		return
	f.store_string(JSON.stringify(_cache, "\t"))
	f.close()


# --- serialização Color/Vector2-safe (recursiva) ---
func _serializar(v: Variant) -> Variant:
	if v is Color:
		return {"__color__": [v.r, v.g, v.b, v.a]}
	if v is Vector2:
		return {"__vec2__": [v.x, v.y]}
	if v is Dictionary:
		var d := {}
		for k in v.keys():
			d[str(k)] = _serializar(v[k])
		return d
	if v is Array:
		var a := []
		for it in v:
			a.append(_serializar(it))
		return a
	return v


func _desserializar(v: Variant) -> Variant:
	if v is Dictionary:
		if v.has("__color__") and v["__color__"] is Array and (v["__color__"] as Array).size() >= 3:
			var c: Array = v["__color__"]
			var a: float = float(c[3]) if c.size() > 3 else 1.0
			return Color(float(c[0]), float(c[1]), float(c[2]), a)
		if v.has("__vec2__") and v["__vec2__"] is Array and (v["__vec2__"] as Array).size() >= 2:
			var p: Array = v["__vec2__"]
			return Vector2(float(p[0]), float(p[1]))
		var d := {}
		for k in v.keys():
			d[k] = _desserializar(v[k])
		return d
	if v is Array:
		var arr := []
		for it in v:
			arr.append(_desserializar(it))
		return arr
	return v
