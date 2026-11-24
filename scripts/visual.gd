extends Node

## VISUAL MODERNO E LISO, PARA O JOGO INTEIRO (sem reescrever cada tela):
##
## 1. PAINÉIS LIMPOS: todo painel / botão do jogo usa StyleBoxFlat com um
##    "neon" de sombra grande. Aqui cada um é afinado quando entra na tela:
##    brilho mais curto e suave, borda fina, cantos lisos (antisserrilhado).
##    Fica mais limpo e mais leve para a placa de vídeo da TV Box (sombra
##    grande é o que mais custa para desenhar).
## 2. MODAIS ANIMADOS: todo painel que aparece DEPOIS de a tela estar montada
##    (modal, aviso, pop-up, resultado) entra com um "pulo" curto: cresce de
##    92% para 100% com um leve passa-e-volta e surge do transparente. O fundo
##    escuro de um modal surge em fade. Um painel que a própria tela já anima
##    (escala ou transparência mexidas por ela) não é tocado.
## 3. SEM ENGASGOS: as imagens, sons, fontes e telas são carregados em
##    segundo plano logo que o jogo abre e ficam na memória; trocar de tela ou
##    tocar um som pela primeira vez não para mais o jogo para ler o arquivo.
##
## Para desligar: LIGADO = false.

const LIGADO := true
const BRILHO_MAX := 10            # tamanho máximo da sombra/neon (antes: até 40+)
const BRILHO_ALFA := 0.62         # o neon fica mais discreto
const BORDA_MAX := 2
const MONTANDO_MS := 450          # a tela nova ainda está se montando: não anima
const ENTRADA_S := 0.26
const PASTAS_CACHE := ["res://fonts", "res://images", "res://fundos", "res://songs", "res://scenes", "res://branding"]
const NOMES_ESTILO := ["panel", "normal", "hover", "pressed", "focus", "disabled", "fill", "background"]

var _cena: Node
var _partida := false
const TELAS_DE_PARTIDA := ["play", "cup_play", "torment_play", "pendings_play"]
var _cena_desde := 0
var _animando := {}               # nó -> true (só neste quadro: o pai anima, o filho não)
var _cache := {}                  # caminho -> recurso (fica na memória)
var _fila: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_carregar_nivel()
	_aplicar_resolucao()
	if not LIGADO:
		set_process(false)
		return
	get_tree().node_added.connect(_no_novo)
	_montar_fila()


# ------------------------------------------------------------------ quadro
func _process(_delta: float) -> void:
	var cena := get_tree().current_scene
	if cena != _cena:
		_trocou_de_tela(cena)
	if not _animando.is_empty():
		_animando.clear()
	_carregar_um()
	_medir()


func _trocou_de_tela(cena: Node) -> void:
	_cena = cena
	_cena_desde = Time.get_ticks_msec()
	_partida = cena != null and cena.scene_file_path.get_file().get_basename() in TELAS_DE_PARTIDA
	_enquadrar(cena)
	if _trocar_pendente:
		_trocar_pendente = false
		_aplicar_resolucao()


# ------------------------------------------------------- enquadramento
## CADA TELA NO TAMANHO EM QUE FOI DESENHADA. O menu foi desenhado para uma
## tela de 1080 linhas; os lobbies, as partidas e os resultados foram
## desenhados (modais, cartões e letras em pontos fixos) para uma tela de
## 720 linhas - numa de 1080 ficavam pequenos, com a letra miúda e muito
## fundo escuro sobrando. Aqui cada tela recebe a "régua" certa ANTES de se
## montar: o conteúdo ocupa a tela inteira, em qualquer TV. É só a régua do
## desenho; a nitidez continua a da TV (as letras são redesenhadas no
## tamanho final, não esticadas).
const LINHAS_DA_TELA := {"opening": 1080, "cup_setup_36": 1080, "champions_wall": 900, "champions_ranking": 900,
	"cup_lobby": 900, "lobby": 864}
const LINHAS_PADRAO := 720


func _enquadrar(cena: Node) -> void:
	if cena == null:
		return
	var nome := cena.scene_file_path.get_file().get_basename()
	var linhas: int = int(LINHAS_DA_TELA.get(nome, LINHAS_PADRAO))
	var teste := OS.get_environment("OLHO_LINHAS")
	if teste != "" and nome != "opening":
		linhas = int(teste)
	var regua := Vector2i(int(round(linhas * 16.0 / 9.0)), linhas)
	var janela := get_tree().root
	if janela.content_scale_size != regua:
		janela.content_scale_size = regua


# ------------------------------------------------- desempenho automático
## O JOGO É SEMPRE DESENHADO COMO UMA TELA DE 1920 x 1080 (project.godot:
## window/stretch). As posições, os tamanhos e as letras são os mesmos em
## qualquer TV, TV Box ou monitor - nada se desmonta.
##
## O que se ajusta sozinho à placa de vídeo da TV Box é só a QUANTIDADE DE
## PONTOS que ela pinta por quadro (a própria TV estica a imagem, de graça).
## O jogo mede os quadros por segundo de verdade e, se a caixa não dá conta,
## desce um degrau (e guarda, para já abrir certo da próxima vez):
##   nível 0  tudo: neon nos painéis e luzes de fundo               (PC)
##   nível 1  sem o neon (sombra) dos painéis; 1080 linhas          (a TV Box começa aqui)
##   nível 2  900 linhas
##   nível 3  720 linhas
##   nível 4  540 linhas
##   nível 5  540 linhas, travado em 30 quadros por segundo (constante é melhor que oscilando)
## Para recomeçar a medição: apague user://visual.cfg (ou reinstale o jogo).
const ARQUIVO := "user://visual.cfg"
const ALTURAS := [1080, 1080, 900, 720, 540, 540]
const NIVEL_MAX := 5
const JANELA_MS := 5000
const QPS_MINIMO := 41.0
var nivel := 0
var qps := 0.0
var placa := ""
var tv := ""                      # os pontos da TV ("1920x1080"), dito pelo Android
var _med_quadros := 0
var _med_desde := 0
var _ruins := 0
var _altura := 0


## Placas de vídeo fracas (as das TV Box baratas): já começam pintando 720
## linhas - o desenho continua o de 1080p, só a nitidez é menor - para o jogo
## rodar liso desde o primeiro segundo, sem precisar "descobrir" devagar.
const PLACAS_FRACAS := ["mali-g31", "mali-g51", "mali-t7", "mali-t8", "mali-4", "ge8", "sgx", "adreno (tm) 3", "adreno (tm) 4", "adreno (tm) 50", "videocore", "vivante"]
var _trocar_pendente := false


func _nivel_inicial() -> int:
	var p := placa.to_lower()
	for fraca in PLACAS_FRACAS:
		if p.contains(fraca):
			return 3
	return 1


func _carregar_nivel() -> void:
	placa = RenderingServer.get_video_adapter_name()
	if OS.get_name() != "Android":
		nivel = 0
		return
	var cfg := ConfigFile.new()
	cfg.load(ARQUIVO)
	# ("nivel_1080b": as medições das versões antigas não valem mais)
	nivel = clampi(int(cfg.get_value("visual", "nivel_1080b", _nivel_inicial())), 0, NIVEL_MAX)
	# Trava de segurança: se da última vez o jogo fechou / travou logo depois
	# de mudar os pontos da tela, esta caixa não aceita: nunca mais muda.
	# (3 vezes seguidas: uma queda de luz logo depois de abrir não conta)
	_sem_pontos = bool(cfg.get_value("visual", "sem_pontos", false))
	_tentativas = int(cfg.get_value("visual", "tentativas", 0))
	if _tentativas >= 3:
		_sem_pontos = true
		_tentativas = 0
		_guardar_nivel()


func _guardar_nivel() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("visual", "nivel_1080b", nivel)
	cfg.set_value("visual", "placa", placa)
	cfg.set_value("visual", "sem_pontos", _sem_pontos)
	cfg.set_value("visual", "tentativas", _tentativas)
	cfg.save(ARQUIVO)


var _sem_pontos := false
var _tentativas := 0
var _trocou_em := 0


## Quantos pontos a TV Box pinta (o desenho do jogo NÃO muda: é só a
## nitidez). Quem estica até o tamanho da TV é o próprio Android. Só é
## chamado ao abrir o jogo e nas trocas de tela - nunca no meio de uma tela.
func _aplicar_resolucao() -> void:
	if OS.get_name() != "Android":
		return
	Engine.max_fps = 30 if nivel >= NIVEL_MAX else 0
	var alt: int = 1080 if _sem_pontos else ALTURAS[nivel]
	if alt == _altura:
		return
	_altura = alt
	if Engine.has_singleton("StrikeSerial"):
		var p := Engine.get_singleton("StrikeSerial")
		if p.has_method("pontos_da_tela"):
			if alt < 1080:
				_tentativas += 1       # (se travar agora, a próxima abertura sabe)
				_guardar_nivel()
				_trocou_em = Time.get_ticks_msec()
			tv = str(p.call("pontos_da_tela", alt))


func _medir() -> void:
	var agora := Time.get_ticks_msec()
	# os pontos da tela mudaram e o jogo continuou vivo por 8 s: a caixa aceita
	if _trocou_em > 0 and agora - _trocou_em > 8000:
		_trocou_em = 0
		_tentativas = 0
		_guardar_nivel()
	# não mede montando a tela, em transição nem com o jogo parado num aviso
	if agora - _cena_desde < 4000 or get_tree().paused:
		_med_quadros = 0
		_med_desde = agora
		return
	_med_quadros += 1
	if agora - _med_desde < JANELA_MS:
		return
	qps = _med_quadros * 1000.0 / float(agora - _med_desde)
	_med_quadros = 0
	_med_desde = agora
	if OS.get_name() != "Android" or nivel >= NIVEL_MAX:
		return
	if qps >= QPS_MINIMO:
		_ruins = 0
		return
	_ruins += 1
	if _ruins < 2:
		return
	_ruins = 0
	nivel += 1
	_guardar_nivel()
	print("VISUAL: ", snappedf(qps, 0.1), " quadros/s: descendo para o nível ", nivel)
	# (os pontos da tela só mudam na próxima troca de tela, atrás da transição)
	_trocar_pendente = true


## Para o canto da tela e a Central da Máquina.
func texto() -> String:
	return "%s  •  %d q/s  •  nível %d  •  %dp%s" % [placa if placa != "" else "?", int(round(qps)), nivel, 1080 if _sem_pontos else ALTURAS[nivel], ("  •  TV " + tv) if tv != "" else ""]


# ----------------------------------------------------------- painéis limpos
func _no_novo(n: Node) -> void:
	# (chamado para CADA nó que entra na árvore: tem que ser quase de graça)
	# (a tela nova monta os nós dela antes do nosso _process ver a troca)
	var atual := get_tree().current_scene
	if atual != _cena:
		_trocou_de_tela(atual)
	if not (n is Panel or n is PanelContainer or n is BaseButton or n is ColorRect or n is LineEdit):
		return
	if _partida:
		# telas de partida: cores, neon dos LEDs e tempos são os do jogo; aqui
		# só os cantos e os "hovers" quadrados são acertados (uma vez)
		if not (n is ColorRect):
			_afinar.call_deferred(n)
		return
	var depois: bool = Time.get_ticks_msec() - _cena_desde >= MONTANDO_MS
	if n is ColorRect:
		if depois:
			_talvez_animar.call_deferred(n)
		return
	# o estilo chega logo depois de o nó entrar: afina no fim do quadro, e de
	# novo quando a tela troca o estilo do painel (botão marcado, card ativo...)
	_afinar.call_deferred(n)
	if not (n as Control).theme_changed.is_connected(_estilo_mudou):
		(n as Control).theme_changed.connect(_estilo_mudou.bind(n))
	if depois and not (n is LineEdit):
		_talvez_animar.call_deferred(n)


func _estilo_mudou(c: Control) -> void:
	if not is_instance_valid(c) or c.has_meta("v_fila"):
		return
	c.set_meta("v_fila", true)
	_afinar.call_deferred(c)


func _e_do_sistema(c: Node) -> bool:
	# os avisos e o teclado do próprio sistema (ControleTv, Efeitos, ArduinoBridge)
	var p := c
	while p != null:
		if p == self or p.name in ["ControleTv", "Efeitos", "ArduinoBridge", "Leads", "Harness"] and p.get_parent() == get_tree().root:
			return true
		p = p.get_parent()
	return false


## O NEON (sombra colorida) DOS CARDS FICA: só é encurtado conforme o fôlego
## da placa de vídeo (sombra grande é o desenho mais caro que existe aqui).
const NEON_POR_NIVEL := [14, 10, 10, 8, 6, 0]


func _maior_raio(sb: StyleBoxFlat) -> int:
	return maxi(maxi(sb.corner_radius_top_left, sb.corner_radius_top_right), maxi(sb.corner_radius_bottom_left, sb.corner_radius_bottom_right))


func _afinar(c: Control) -> void:
	if not is_instance_valid(c):
		return
	if c.has_meta("v_fila"):
		c.remove_meta("v_fila")
	if _e_do_sistema(c):
		return
	var menor := minf(c.size.x, c.size.y)
	if menor <= 0.0 and not c.has_meta("v_2a"):
		# (ainda sem tamanho: olha de novo daqui a pouco, uma vez)
		c.set_meta("v_2a", true)
		get_tree().create_timer(0.08, true, false, true).timeout.connect(_afinar.bind(c))
		return
	var tela := get_viewport().get_visible_rect().size
	for nome in NOMES_ESTILO:
		if not c.has_theme_stylebox_override(nome):
			continue
		var sb := c.get_theme_stylebox(nome)
		if sb is StyleBoxFlat and not sb.has_meta("visual"):
			_afinar_estilo(sb as StyleBoxFlat, c, menor, tela)
	if c is BaseButton:
		_afinar_botao(c as BaseButton)
	elif c is LineEdit:
		_afinar_campo(c as LineEdit)


func _afinar_estilo(sb: StyleBoxFlat, c: Control, menor: float, tela: Vector2) -> void:
	sb.set_meta("visual", true)
	# NEON mais curto (fora das partidas: lá o neon é o do jogo)
	if not _partida:
		var maximo: int = NEON_POR_NIVEL[clampi(nivel, 0, NEON_POR_NIVEL.size() - 1)]
		if sb.shadow_size > maximo:
			sb.shadow_size = maximo
			var cor := sb.shadow_color
			sb.shadow_color = Color(cor.r, cor.g, cor.b, cor.a * BRILHO_ALFA)
	# SEM CANTO PONTUDO: painel / botão quadrado ganha canto redondo. Ficam de
	# fora as faixas de lado a lado da tela, as barras fininhas e o que a
	# tela arredondou só de um lado de propósito.
	if menor >= 26.0 and c.size.x < tela.x * 0.94 and c.size.y < tela.y * 0.94 and _maior_raio(sb) < 6 \
			and (sb.bg_color.a > 0.03 or sb.border_color.a > 0.03):
		sb.set_corner_radius_all(clampi(int(menor * 0.22), 6, 14))


## BOTÃO REDONDO COM "HOVER" QUADRADO: o botão que só recebeu o estilo normal
## mostrava o hover / apertado / foco cinza e quadrado do tema padrão. Eles
## passam a ser o próprio estilo do botão, mais claro, com o mesmo canto.
func _afinar_botao(b: BaseButton) -> void:
	if not b.has_theme_stylebox_override("normal"):
		return
	var normal := b.get_theme_stylebox("normal") as StyleBoxFlat
	if normal == null:
		return
	var raio := _maior_raio(normal)
	for nome in ["hover", "pressed", "disabled"]:
		if b.has_theme_stylebox_override(nome):
			var sb := b.get_theme_stylebox(nome) as StyleBoxFlat
			if sb != null and _maior_raio(sb) + 2 < raio:
				sb.corner_radius_top_left = normal.corner_radius_top_left
				sb.corner_radius_top_right = normal.corner_radius_top_right
				sb.corner_radius_bottom_left = normal.corner_radius_bottom_left
				sb.corner_radius_bottom_right = normal.corner_radius_bottom_right
			continue
		var novo := normal.duplicate() as StyleBoxFlat
		novo.set_meta("visual", true)
		if nome == "hover":
			novo.bg_color = normal.bg_color.lightened(0.10)
			novo.border_color = normal.border_color.lightened(0.25)
		elif nome == "pressed":
			novo.bg_color = normal.bg_color.lightened(0.20)
			novo.border_color = normal.border_color.lightened(0.35)
		b.add_theme_stylebox_override(nome, novo)
	if not b.has_theme_stylebox_override("focus"):
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _afinar_campo(c: LineEdit) -> void:
	if not c.has_theme_stylebox_override("normal") or c.has_theme_stylebox_override("focus"):
		return
	var normal := c.get_theme_stylebox("normal") as StyleBoxFlat
	if normal == null:
		return
	var foco := normal.duplicate() as StyleBoxFlat
	foco.set_meta("visual", true)
	foco.border_color = normal.border_color.lightened(0.35)
	foco.bg_color = Color(0, 0, 0, 0)
	c.add_theme_stylebox_override("focus", foco)


# ----------------------------------------------------------- modais animados
func _talvez_animar(c: Control) -> void:
	if not is_instance_valid(c) or not c.is_inside_tree() or not c.is_visible_in_tree():
		return
	if _e_do_sistema(c):
		return
	# o pai já está entrando animado: o filho vai junto
	var p := c.get_parent()
	while p != null:
		if _animando.has(p):
			return
		p = p.get_parent()
	# a própria tela já mexe neste painel (escala, giro ou transparência): fica com ela
	if not c.scale.is_equal_approx(Vector2.ONE) or c.modulate.a < 0.99 or c.self_modulate.a < 0.99 or c.rotation != 0.0:
		return
	var tela := get_viewport().get_visible_rect().size
	if c is ColorRect:
		# fundo escuro de modal (cobre a tela): surge em fade
		var cr := c as ColorRect
		if cr.size.x >= tela.x * 0.9 and cr.size.y >= tela.y * 0.9 and cr.color.a > 0.2 and cr.color.a < 1.0 and cr.color.get_luminance() < 0.2:
			_animando[c] = true
			# nada de tela quase preta: o jogo continua aparecendo atrás do modal
			if cr.color.a > 0.60:
				cr.color.a = 0.60
			cr.modulate.a = 0.0
			var tf := c.create_tween()
			tf.tween_property(cr, "modulate:a", 1.0, 0.20)
		return
	if not (c is Panel or c is PanelContainer):
		return
	if c.size.x < 240.0 or c.size.y < 110.0:
		return
	# tela inteira (fundo de tela, não modal) não pula
	if c.size.x >= tela.x * 0.97 and c.size.y >= tela.y * 0.97:
		return
	_animando[c] = true
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2(0.92, 0.92)
	c.modulate.a = 0.0
	var tw := c.create_tween()
	tw.set_parallel(true)
	tw.tween_property(c, "scale", Vector2.ONE, ENTRADA_S).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "modulate:a", 1.0, ENTRADA_S * 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# ----------------------------------------------------------- sem engasgos
## Tudo que o jogo abre mais tarde (imagens, sons, fontes, telas) é lido em
## segundo plano, um arquivo por vez, e guardado: o "load()" das telas acha
## pronto na memória em vez de ir ao armazenamento da TV Box no meio do jogo.
func _montar_fila() -> void:
	for pasta in PASTAS_CACHE:
		var d := DirAccess.open(str(pasta))
		if d == null:
			continue
		for nome in d.get_files():
			# no jogo exportado os arquivos aparecem como "x.png.import" / "x.gd.remap"
			var limpo := nome.trim_suffix(".import").trim_suffix(".remap")
			var ext := limpo.get_extension().to_lower()
			if not (ext in ["png", "jpg", "jpeg", "mp3", "ogg", "wav", "ttf", "otf", "tscn"]):
				continue
			var caminho: String = str(pasta).path_join(limpo)
			if ext == "tscn":
				# as telas trazem o script junto: script só pode ser carregado
				# na linha principal (em segundo plano dá erro de leitura)
				if not _telas.has(caminho) and ResourceLoader.exists(caminho):
					_telas.append(caminho)
				continue
			if not _fila.has(caminho) and ResourceLoader.exists(caminho):
				_fila.append(caminho)


## As telas (e os scripts delas): na linha principal. Na abertura, uma por
## quadro enquanto a barra de carregamento anda (carregar_tudo); fora dela,
## uma a cada TELA_A_CADA_MS.
const TELA_A_CADA_MS := 220
const JUNTOS := 3                 # arquivos lidos ao mesmo tempo em segundo plano
var _telas: Array[String] = []
var _ultima_tela := 0
var _em_curso: Array[String] = []
var _depressa := false


## A ABERTURA CHAMA E ESPERA (com a tela de carregamento na frente): tudo
## que o jogo usa vai para a memória de uma vez e a barra anda de verdade
## (avisar recebe de 0 a 1). Depois disso nenhuma tela para o jogo para ler
## arquivo: trocar de tela, abrir um modal ou tocar um som é imediato.
func carregar_tudo(avisar: Callable) -> void:
	if not LIGADO:
		return
	var total := maxi(_fila.size() + _telas.size() + _em_curso.size(), 1)
	var comecou := Time.get_ticks_msec()
	_depressa = true
	while not (_fila.is_empty() and _telas.is_empty() and _em_curso.is_empty()):
		if Time.get_ticks_msec() - comecou > 45000:
			break   # (nunca prende a abertura: o resto entra aos poucos)
		await get_tree().process_frame
		var falta := _fila.size() + _telas.size() + _em_curso.size()
		if avisar.is_valid():
			avisar.call(1.0 - float(falta) / float(total))
	_depressa = false


func falta_carregar() -> int:
	return _fila.size() + _telas.size() + _em_curso.size()


func _carregar_tela() -> void:
	if _telas.is_empty():
		return
	var agora := Time.get_ticks_msec()
	if _depressa:
		# (as imagens e sons delas primeiro: aí a tela só junta o que já está pronto)
		if not _fila.is_empty() or not _em_curso.is_empty():
			return
	elif agora - _ultima_tela < TELA_A_CADA_MS:
		return
	_ultima_tela = agora
	var caminho: String = _telas.pop_front()
	var atual := get_tree().current_scene
	if atual != null and atual.scene_file_path == caminho:
		return
	_cache[caminho] = load(caminho)


func _carregar_um() -> void:
	_carregar_tela()
	for i in range(_em_curso.size() - 1, -1, -1):
		var caminho: String = _em_curso[i]
		var estado := ResourceLoader.load_threaded_get_status(caminho)
		if estado == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		if estado == ResourceLoader.THREAD_LOAD_LOADED:
			_cache[caminho] = ResourceLoader.load_threaded_get(caminho)
		_em_curso.remove_at(i)
	if _fila.is_empty():
		if _em_curso.is_empty() and _telas.is_empty() and _cache.size() > 0 and not has_meta("avisou"):
			set_meta("avisou", true)
			print("VISUAL: ", _cache.size(), " arquivos na memória (sem engasgo ao trocar de tela)")
		return
	var juntos: int = JUNTOS if _depressa else 1
	while _em_curso.size() < juntos and not _fila.is_empty():
		var proximo: String = _fila.pop_front()
		if ResourceLoader.has_cached(proximo):
			_cache[proximo] = load(proximo)
			continue
		if ResourceLoader.load_threaded_request(proximo) == OK:
			_em_curso.append(proximo)
