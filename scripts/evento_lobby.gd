extends Control
## A TELA "EVENTOS" - abre quando se escolhe EVENTO no menu do jogo.
## (quem cria e mostra é Leads.abrir_lobby(); fica na frente do menu)
##
## TUDO DO MODO EVENTO ESTÁ AQUI, NA MÃO:
##   - os eventos salvos (o nome vem ANTES de tudo: sem evento não há partida)
##   - + NOVO EVENTO: escreve o nome e ele já fica escolhido
##   - JOGAR NESTE EVENTO: segue para os jogadores e as fichas de cadastro
##   - VER LEADS: quem se cadastrou no evento
##   - APAGAR EVENTO (pede para apertar duas vezes)
##   - o PENDRIVE: o que já está nele, o que falta, e DESCARREGAR
##
## CONTROLE: setas + OK.  START = jogar no evento escolhido.  SELECT = próximo
## evento.  VOLTAR / ESC = fecha a lista de leads ou volta para o menu.

signal terminou(jogar: bool)

const VERDE := Color(0.30, 1.0, 0.50)
const AMARELO := Color(1.0, 0.84, 0.10)
const VERMELHO := Color(1.0, 0.36, 0.30)
const AZUL := Color(0.25, 0.70, 1.0)
const CINZA := Color(0.75, 0.80, 0.88)
const SEM_TOQUE_S := 150.0
const LEADS_POR_PAGINA := 8

var parado := 0.0                  # (Leads.tocou() zera)
var _cartao: Panel
var _campo_novo: LineEdit
var _lista: VBoxContainer
var _rolo: ScrollContainer
var _conta_eventos: Label
var _detalhe: Control
var _recado: Label
var _pen: Label
var _bt_jogar: Button
var _bt_apagar: Button
var _bt_pen: Button
var _eventos: Array = []
var _escolhido := ""               # o nome do evento escolhido ("" = nenhum)
var _tem_escolhido := false
var _apagar_em := 0
var _pasta_em := 0
var _aberto_em := 0
var _olhar_pen := 0.0
var _leads_painel: Panel
var _leads_pagina := 0
var _fim := false


func _ready() -> void:
	var tela := get_viewport().get_visible_rect().size
	# a tela inteira, com tamanho de verdade: é isto que deixa o menu "atrás"
	# (nem o mouse nem as setas do controle chegam aos botões dele)
	# (as âncoras de tela cheia já vêm postas por Leads.abrir_lobby, antes de
	# entrar na árvore: postas aqui, o tamanho ficava zero)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_aberto_em = Time.get_ticks_msec()
	var k: float = minf(tela.x / 1280.0, tela.y / 720.0)
	var fundo := ColorRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.color = Color(0.01, 0.04, 0.10, 0.94)      # (o menu atrás quase não aparece)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	var palco := Control.new()
	palco.size = Vector2(1280, 720)
	palco.scale = Vector2(k, k)
	palco.position = (tela - Vector2(1280, 720) * k) * 0.5
	palco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(palco)

	_cartao = Panel.new()
	_cartao.position = Vector2(40, 12)
	_cartao.size = Vector2(1200, 696)
	_cartao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cartao.add_theme_stylebox_override("panel", Leads._caixa(Color(0.035, 0.065, 0.12, 1.0), AZUL, 28, 3))
	palco.add_child(_cartao)

	# ---- cabeçalho
	var selo := Panel.new()
	selo.position = Vector2(30, 14)
	selo.size = Vector2(190, 28)
	selo.add_theme_stylebox_override("panel", Leads._caixa(Color(AMARELO.r, AMARELO.g, AMARELO.b, 0.14), Color(AMARELO.r, AMARELO.g, AMARELO.b, 0.7), 14))
	_cartao.add_child(selo)
	_rot(selo, "MODO EVENTO", 16, AMARELO, Vector2.ZERO, selo.size, Leads.FONTE_FORTE, HORIZONTAL_ALIGNMENT_CENTER)
	_rot(_cartao, "EVENTOS", 46, Color.WHITE, Vector2(30, 40), Vector2(400, 52), Leads.FONTE_TITULO)
	var sub := _rot(_cartao, "Escolha o evento desta partida ou crie um novo.\nOs jogadores são cadastrados dentro dele.", 18, Color(0.72, 0.80, 0.92),
		Vector2(250, 44), Vector2(640, 52))
	sub.clip_text = false
	var data := _rot(_cartao, "HOJE:  " + Leads.data_na_tela(), 20, Color(0.60, 0.70, 0.82), Vector2(900, 14), Vector2(270, 30), "", HORIZONTAL_ALIGNMENT_RIGHT)
	if Leads.relogio_suspeito():
		data.text = "⚠ DATA ERRADA:  " + Leads.data_na_tela()
		data.add_theme_color_override("font_color", AMARELO)

	# ---- à esquerda: novo evento + os salvos
	_campo_novo = LineEdit.new()
	_campo_novo.position = Vector2(30, 108)
	_campo_novo.size = Vector2(520, 56)
	_campo_novo.max_length = 40
	_campo_novo.placeholder_text = "+  NOVO EVENTO   (escreva o nome)"
	_campo_novo.context_menu_enabled = false
	_campo_novo.virtual_keyboard_enabled = false
	_campo_novo.focus_mode = Control.FOCUS_NONE     # quem escreve é o teclado da tela
	_campo_novo.set_meta("titulo", "NOME DO NOVO EVENTO")
	_campo_novo.add_theme_font_size_override("font_size", 24)
	_campo_novo.add_theme_color_override("font_color", Color.WHITE)
	_campo_novo.add_theme_color_override("font_placeholder_color", VERDE)
	_campo_novo.add_theme_stylebox_override("normal", Leads._caixa(Color(VERDE.r, VERDE.g, VERDE.b, 0.10), VERDE, 14))
	_campo_novo.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_cartao.add_child(_campo_novo)
	_conta_eventos = _rot(_cartao, "", 17, AZUL.lightened(0.35), Vector2(30, 170), Vector2(520, 26), Leads.FONTE_FORTE)
	_rolo = ScrollContainer.new()
	_rolo.position = Vector2(30, 198)
	_rolo.size = Vector2(520, 332)
	_rolo.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_cartao.add_child(_rolo)
	_lista = VBoxContainer.new()
	_lista.custom_minimum_size.x = 506
	_lista.add_theme_constant_override("separation", 8)
	_rolo.add_child(_lista)

	# ---- à direita: o evento escolhido
	var quadro := Panel.new()
	quadro.position = Vector2(570, 108)
	quadro.size = Vector2(600, 430)
	quadro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quadro.add_theme_stylebox_override("panel", Leads._caixa(Color(1, 1, 1, 0.035), Color(1, 1, 1, 0.14), 20, 1))
	_cartao.add_child(quadro)
	_detalhe = Control.new()
	_detalhe.size = quadro.size
	_detalhe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quadro.add_child(_detalhe)
	_bt_jogar = Leads._botao(quadro, "▶  JOGAR NESTE EVENTO", Vector2(20, 266), Vector2(560, 78), VERDE, true)
	_bt_jogar.add_theme_font_size_override("font_size", 34)
	_bt_jogar.pressed.connect(_jogar)
	var ver := Leads._botao(quadro, "VER LEADS", Vector2(20, 356), Vector2(272, 58), AZUL, false)
	ver.pressed.connect(_abrir_leads)
	ver.name = "VerLeads"
	_bt_apagar = Leads._botao(quadro, "APAGAR EVENTO", Vector2(308, 356), Vector2(272, 58), VERMELHO, false)
	_bt_apagar.pressed.connect(_apagar)

	# ---- embaixo: o recado, o pendrive, e os dois botões na mesma linha
	_recado = _rot(_cartao, "", 20, Color(0.80, 0.88, 0.98), Vector2(30, 544), Vector2(1140, 30), Leads.FONTE_FORTE)
	_recado.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_pen = _rot(_cartao, "", 17, Color.WHITE, Vector2(30, 576), Vector2(1140, 44), Leads.FONTE_FORTE)
	_pen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pen.clip_text = false
	var voltar_bt := Leads._botao(_cartao, "✕  VOLTAR AO MENU", Vector2(30, 628), Vector2(280, 54), CINZA, false)
	voltar_bt.pressed.connect(func() -> void: _fechar(false))
	_bt_pen = Leads._botao(_cartao, "DESCARREGAR NO PENDRIVE", Vector2(820, 628), Vector2(350, 54), AZUL, true)
	_bt_pen.add_theme_font_size_override("font_size", 24)
	_bt_pen.pressed.connect(_descarregar)

	ControleTv.teclado_fechou.connect(_teclado_fechou)
	Leads.mudou.connect(_dados_mudaram)
	_escolhido = Leads.evento
	_refazer()
	# entrada
	_cartao.pivot_offset = _cartao.size * 0.5
	_cartao.scale = Vector2(0.94, 0.94)
	modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	tw.tween_property(_cartao, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_marcar_inicio.call_deferred()


func _rot(pai: Control, texto: String, tam: int, cor: Color, pos: Vector2, tamanho: Vector2, fonte := "", alinhar := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	return Leads._rotulo(pai, texto, tam, cor, pos, tamanho, fonte, alinhar)


func _marcar_inicio() -> void:
	if _fim:
		return
	if _tem_escolhido:
		ControleTv.marcar(_bt_jogar)
	else:
		# nenhum evento ainda: o nome vem antes de tudo
		ControleTv.abrir_teclado(_campo_novo)


func _dizer(texto: String, cor: Color) -> void:
	_recado.text = texto
	_recado.add_theme_color_override("font_color", cor)


func _data_curta(t: String) -> String:
	if t.length() < 16:
		return t if t != "" else "-"
	return "%s/%s/%s %s" % [t.substr(8, 2), t.substr(5, 2), t.substr(0, 4), t.substr(11, 5)]


func _evento_escolhido() -> Dictionary:
	for ev in _eventos:
		if str(ev["nome"]) == _escolhido:
			return ev
	return {}


# ------------------------------------------------------------------ a tela
## Monta de novo a lista, o evento escolhido e a linha do pendrive.
func _refazer() -> void:
	_eventos = []
	for ev in Leads.eventos_resumo():
		if str(ev["nome"]) != "":       # (evento sem nome não entra: o nome vem antes)
			_eventos.append(ev)
	_tem_escolhido = not _evento_escolhido().is_empty()
	if not _tem_escolhido and not _eventos.is_empty():
		_escolhido = str(_eventos[0]["nome"])
		_tem_escolhido = true
	_conta_eventos.text = "EVENTOS SALVOS  (%d)" % _eventos.size()
	for f in _lista.get_children():
		_lista.remove_child(f)
		f.queue_free()
	if _eventos.is_empty():
		var vazio := _rot(_lista, "Nenhum evento ainda.\nEscreva o nome do primeiro em  + NOVO EVENTO.", 20, Color(0.66, 0.75, 0.86), Vector2.ZERO, Vector2(506, 150), "", HORIZONTAL_ALIGNMENT_CENTER)
		vazio.custom_minimum_size = Vector2(506, 150)
		vazio.clip_text = false
	for ev in _eventos:
		_lista.add_child(_linha(ev))
	_mostrar_detalhe()
	_atualizar_pen()


func _linha(ev: Dictionary) -> Button:
	var nome := str(ev["nome"])
	var este := nome == _escolhido
	var b := Button.new()
	b.custom_minimum_size = Vector2(506, 64)
	b.focus_mode = Control.FOCUS_NONE
	b.set_meta("evento", nome)
	var cor := AMARELO if este else Color(0.30, 0.48, 0.72)
	b.add_theme_stylebox_override("normal", Leads._caixa(Color(AMARELO.r, AMARELO.g, AMARELO.b, 0.13) if este else Color(0.08, 0.13, 0.22), cor, 14, 2 if este else 1))
	var aceso := Leads._caixa(Color(0.12, 0.22, 0.38), Color(0.62, 0.84, 1.0), 14, 2)
	aceso.shadow_color = Color(0.30, 0.65, 1.0, 0.50)
	aceso.shadow_size = 12
	b.add_theme_stylebox_override("hover", aceso)
	b.add_theme_stylebox_override("pressed", aceso)
	b.pressed.connect(_escolher.bind(nome, true))
	var t := _rot(b, ("●  " if este else "") + nome, 25, AMARELO if este else Color.WHITE, Vector2(16, 4), Vector2(474, 32), Leads.FONTE_TITULO)
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_rot(b, "%d partida%s   •   %d jogador%s   •   criado em %s" % [int(ev["partidas"]), "" if int(ev["partidas"]) == 1 else "s",
		int(ev["jogadores"]), "" if int(ev["jogadores"]) == 1 else "es", _data_curta(str(ev["criado"])).substr(0, 10)],
		15, Color(0.66, 0.75, 0.86), Vector2(16, 36), Vector2(474, 22))
	return b


func _mostrar_detalhe() -> void:
	for f in _detalhe.get_children():
		_detalhe.remove_child(f)
		f.queue_free()
	var ev := _evento_escolhido()
	var tem := not ev.is_empty()
	_bt_jogar.disabled = not tem
	_bt_jogar.modulate.a = 1.0 if tem else 0.30
	_bt_apagar.disabled = not tem
	_bt_apagar.modulate.a = 1.0 if tem else 0.30
	_bt_apagar.text = "APAGAR EVENTO"
	_apagar_em = 0
	var ver := _bt_apagar.get_parent().get_node("VerLeads") as Button
	ver.disabled = not tem or int(ev.get("jogadores", 0)) == 0
	ver.modulate.a = 0.30 if ver.disabled else 1.0
	ver.text = "VER LEADS  (%d)" % int(ev.get("jogadores", 0)) if tem else "VER LEADS"
	if not tem:
		_rot(_detalhe, "NENHUM EVENTO ESCOLHIDO", 34, Color.WHITE, Vector2(20, 40), Vector2(560, 44), Leads.FONTE_TITULO, HORIZONTAL_ALIGNMENT_CENTER)
		var dica := _rot(_detalhe, "O nome do evento vem antes de tudo.\nEscreva em  + NOVO EVENTO  (à esquerda) e ele já fica pronto para jogar.", 21, Color(0.72, 0.80, 0.92),
			Vector2(30, 100), Vector2(540, 120), "", HORIZONTAL_ALIGNMENT_CENTER)
		dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dica.clip_text = false
		return
	_rot(_detalhe, "EVENTO ESCOLHIDO", 15, AMARELO, Vector2(20, 12), Vector2(300, 22), Leads.FONTE_FORTE)
	var nome := _rot(_detalhe, str(ev["nome"]), 40, Color.WHITE, Vector2(20, 32), Vector2(560, 50), Leads.FONTE_TITULO)
	nome.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var linha2 := "criado em %s" % _data_curta(str(ev["criado"]))
	if str(ev["ultimo"]) != "":
		linha2 += "      •      último cadastro: %s" % _data_curta(str(ev["ultimo"]))
	_rot(_detalhe, linha2, 16, Color(0.62, 0.72, 0.84), Vector2(20, 82), Vector2(560, 24))
	var numeros := [["PARTIDAS", int(ev["partidas"]), VERDE], ["JOGADORES", int(ev["jogadores"]), AZUL], ["CADASTROS", int(ev["cadastros"]), Color(0.80, 0.55, 1.0)]]
	for i in range(3):
		var cor: Color = numeros[i][2]
		var tile := Panel.new()
		tile.position = Vector2(20 + i * 190, 116)
		tile.size = Vector2(180, 132)
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_theme_stylebox_override("panel", Leads._caixa(Color(cor.r * 0.08, cor.g * 0.08, cor.b * 0.08, 0.9), Color(cor.r, cor.g, cor.b, 0.7), 16, 1))
		_detalhe.add_child(tile)
		_rot(tile, str(numeros[i][1]), 58, Color.WHITE, Vector2(0, 14), Vector2(180, 70), Leads.FONTE_TITULO, HORIZONTAL_ALIGNMENT_CENTER)
		_rot(tile, str(numeros[i][0]), 16, cor.lightened(0.35), Vector2(0, 92), Vector2(180, 26), Leads.FONTE_FORTE, HORIZONTAL_ALIGNMENT_CENTER)


func _atualizar_pen() -> void:
	var t := Leads.texto_conferencia()
	_pen.text = t
	var cor := Color.WHITE
	if t.begins_with("PENDRIVE EM DIA"):
		cor = VERDE
	elif t.begins_with("SEM") or t.contains("NOVOS"):
		cor = AMARELO
	elif t.contains("ERRO"):
		cor = VERMELHO
	_pen.add_theme_color_override("font_color", cor)


func _dados_mudaram() -> void:
	if _fim or _leads_painel != null:
		return
	var marcado_em := _evento_marcado()
	_refazer()
	_remarcar(marcado_em)


## A lista foi montada de novo: a marca do controle volta para o mesmo evento.
func _evento_marcado() -> String:
	var alvo: Variant = ControleTv.get("_alvo")
	if alvo is Button and (alvo as Button).has_meta("evento"):
		return str((alvo as Button).get_meta("evento"))
	return ""


func _remarcar(nome: String) -> void:
	if nome == "":
		return
	for b in _lista.get_children():
		if b is Button and str(b.get_meta("evento", "")) == nome:
			ControleTv.marcar.call_deferred(b)


# ------------------------------------------------------------------ ações
func _escolher(nome: String, ir_para_jogar: bool) -> void:
	parado = 0.0
	_escolhido = nome
	Leads.definir_evento(nome)      # fica guardado: é o evento das próximas partidas
	_refazer()
	_dizer("EVENTO ESCOLHIDO: %s" % nome, AMARELO)
	if ir_para_jogar:
		ControleTv.marcar.call_deferred(_bt_jogar)


func _jogar() -> void:
	if _fim or not _tem_escolhido:
		_dizer("ESCREVA O NOME DO EVENTO em  + NOVO EVENTO", AMARELO)
		ControleTv.marcar(_campo_novo)
		return
	Leads.criar_evento(_escolhido)      # passa a ser o evento atual
	_fechar(true)


func _fechar(jogar: bool) -> void:
	if _fim:
		return
	_fim = true
	terminou.emit(jogar)


## NOVO EVENTO: o teclado da tela fechou com PRONTO.
func _teclado_fechou(campo: LineEdit, pronto: bool) -> void:
	if _fim or campo != _campo_novo:
		return
	parado = 0.0
	var nome := Leads._uma_linha(_campo_novo.text).strip_edges().to_upper().substr(0, 40)
	if not pronto:
		_campo_novo.text = ""
		return
	if nome.length() < 2:
		_campo_novo.text = ""
		_dizer("ESCREVA O NOME DO EVENTO  (pelo menos 2 letras)", VERMELHO)
		return
	_campo_novo.text = ""
	var ja_tinha := false
	for ev in _eventos:
		if str(ev["nome"]) == nome:
			ja_tinha = true
	_escolhido = Leads.criar_evento(nome)        # (Leads.mudou monta a tela de novo)
	_refazer()
	_dizer(("ESTE EVENTO JÁ EXISTIA: %s" if ja_tinha else "EVENTO CRIADO: %s   •   aperte JOGAR") % _escolhido, VERDE)
	ControleTv.marcar.call_deferred(_bt_jogar)


## APAGAR: aperte duas vezes (a 2a em até 5 segundos).
func _apagar() -> void:
	parado = 0.0
	var ev := _evento_escolhido()
	if ev.is_empty():
		return
	var agora := Time.get_ticks_msec()
	if _apagar_em == 0 or agora - _apagar_em > 5000:
		_apagar_em = agora
		_bt_apagar.text = "APAGAR MESMO?  OK"
		_dizer("APAGAR \"%s\" e os %d cadastros dele?  Aperte APAGAR de novo." % [str(ev["nome"]), int(ev["cadastros"])], VERMELHO)
		return
	_apagar_em = 0
	var nome := str(ev["nome"])
	var n := Leads.apagar_eventos([nome])
	_escolhido = Leads.evento
	_refazer()
	_dizer("EVENTO APAGADO: %s  (%d cadastros)" % [nome, n], AMARELO)
	if _tem_escolhido:
		ControleTv.marcar.call_deferred(_bt_jogar)
	else:
		ControleTv.marcar.call_deferred(_campo_novo)


func _descarregar() -> void:
	parado = 0.0
	if not Leads.tem_pendrive():
		var agora := Time.get_ticks_msec()
		if OS.get_name() == "Android" and _pasta_em > 0 and agora - _pasta_em < 8000 and Leads.escolher_pendrive():
			_pasta_em = 0
			_dizer("Na tela do Android: entre no PENDRIVE e aperte \"USAR ESTA PASTA\"", AMARELO)
			return
		_pasta_em = agora
		_dizer("NÃO ACHEI PENDRIVE: espete um na USB e aperte de novo" + ("  (2 vezes = escolher a pasta)" if OS.get_name() == "Android" else ""), AMARELO)
		_atualizar_pen()
		return
	var antes := Leads.conferir_pendrive()
	if Leads.gravar_no_pendrive():
		var novos := int(antes["faltam"])
		_dizer("GRAVADO E CONFERIDO: %s  •  PODE TIRAR O PENDRIVE" % (("%d cadastros novos" % novos) if novos > 0 else "nada repetido, tudo em dia"), VERDE)
	else:
		_dizer("O PENDRIVE NÃO ACEITOU: tente outro (formatado em FAT32 ou exFAT)", VERMELHO)
	_refazer()


# ------------------------------------------------------------ os leads
## Quem se cadastrou no evento escolhido, 8 por página. Na tela os contatos
## aparecem pela metade; os completos vão para o pendrive (leads.csv).
func _abrir_leads() -> void:
	parado = 0.0
	if _leads_painel != null or _evento_escolhido().is_empty():
		return
	_leads_pagina = 0
	_montar_leads()


func _montar_leads() -> void:
	if _leads_painel != null and is_instance_valid(_leads_painel):
		_leads_painel.queue_free()
	var leads: Array = Leads.leads_do_evento(_escolhido)
	var paginas: int = maxi(1, int(ceil(leads.size() / float(LEADS_POR_PAGINA))))
	_leads_pagina = clampi(_leads_pagina, 0, paginas - 1)
	_leads_painel = Panel.new()
	_leads_painel.size = _cartao.size
	_leads_painel.mouse_filter = Control.MOUSE_FILTER_STOP     # os botões da tela ficam atrás
	_leads_painel.add_theme_stylebox_override("panel", Leads._caixa(Color(0.035, 0.065, 0.12, 1.0), AZUL, 28, 3))
	_cartao.add_child(_leads_painel)
	var titulo := _rot(_leads_painel, "LEADS  •  %s" % _escolhido, 40, Color.WHITE, Vector2(30, 14), Vector2(860, 50), Leads.FONTE_TITULO)
	titulo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_rot(_leads_painel, "%d jogador%s   •   página %d de %d" % [leads.size(), "" if leads.size() == 1 else "es", _leads_pagina + 1, paginas], 20,
		AMARELO, Vector2(840, 22), Vector2(330, 34), Leads.FONTE_FORTE, HORIZONTAL_ALIGNMENT_RIGHT)
	var colunas := [["NOME", 30, 290], ["IDADE", 326, 60], ["CIDADE", 392, 240], ["TELEFONE", 638, 190], ["E-MAIL", 834, 250], ["JOGOU", 1090, 80]]
	for c in colunas:
		_rot(_leads_painel, str(c[0]), 15, AZUL.lightened(0.35), Vector2(float(c[1]), 74), Vector2(float(c[2]), 24), Leads.FONTE_FORTE)
	var y := 102.0
	for i in range(_leads_pagina * LEADS_POR_PAGINA, mini(leads.size(), (_leads_pagina + 1) * LEADS_POR_PAGINA)):
		var d: Dictionary = leads[i]
		var faixa := Panel.new()
		faixa.position = Vector2(20, y)
		faixa.size = Vector2(1160, 54)
		faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		faixa.add_theme_stylebox_override("panel", Leads._caixa(Color(1, 1, 1, 0.05 if i % 2 == 0 else 0.02), Color(1, 1, 1, 0.08), 10, 1))
		_leads_painel.add_child(faixa)
		var tel := str(d.get("telefone", ""))
		var valores := [str(d.get("nome", "")), str(int(d.get("idade", 0))), Leads.lugar_texto(str(d.get("cidade", "")), str(d.get("estado", "")), ""),
			Leads.esconder_telefone(tel) if tel != "" else "-", Leads.esconder_email(str(d.get("email", ""))), "%dx" % int(d.get("partidas", 1))]
		for j in range(colunas.size()):
			var l := _rot(_leads_painel, str(valores[j]) if str(valores[j]) != "" else "-", 20 if j == 0 else 18, Color.WHITE if j == 0 else Color(0.80, 0.86, 0.94),
				Vector2(float(colunas[j][1]), y), Vector2(float(colunas[j][2]), 54))
			l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		y += 58.0
	if leads.is_empty():
		_rot(_leads_painel, "Ninguém se cadastrou neste evento ainda.", 24, Color(0.66, 0.75, 0.86), Vector2(30, 240), Vector2(1140, 60), "", HORIZONTAL_ALIGNMENT_CENTER)
	var aviso := _rot(_leads_painel, "Os contatos completos (telefone e e-mail inteiros) vão para o pendrive: leads.csv / leads_excel.csv.", 16,
		Color(0.56, 0.66, 0.78), Vector2(30, 574), Vector2(1140, 26), "", HORIZONTAL_ALIGNMENT_CENTER)
	aviso.clip_text = false
	var fechar := Leads._botao(_leads_painel, "◀  VOLTAR AOS EVENTOS", Vector2(30, 612), Vector2(330, 60), CINZA, false)
	fechar.pressed.connect(_fechar_leads)
	var ant := Leads._botao(_leads_painel, "◀  ANTERIORES", Vector2(650, 612), Vector2(250, 60), AZUL, false)
	ant.disabled = _leads_pagina <= 0
	ant.modulate.a = 0.30 if ant.disabled else 1.0
	ant.pressed.connect(func() -> void:
		_leads_pagina -= 1
		_montar_leads())
	var prox := Leads._botao(_leads_painel, "PRÓXIMOS  ▶", Vector2(920, 612), Vector2(250, 60), AZUL, true)
	prox.disabled = _leads_pagina >= paginas - 1
	prox.modulate.a = 0.30 if prox.disabled else 1.0
	prox.pressed.connect(func() -> void:
		_leads_pagina += 1
		_montar_leads())
	ControleTv.marcar.call_deferred(fechar if prox.disabled else prox)


func _fechar_leads() -> void:
	if _leads_painel != null and is_instance_valid(_leads_painel):
		_leads_painel.queue_free()
	_leads_painel = null
	_refazer()
	ControleTv.marcar.call_deferred(_bt_jogar)


# ------------------------------------------------------- controle e tempo
## VOLTAR / ESC (ControleTv chama por Leads.voltar()).
func voltar() -> void:
	parado = 0.0
	if _leads_painel != null:
		_fechar_leads()
		return
	_fechar(false)


func _process(delta: float) -> void:
	if _fim:
		return
	parado += delta
	if parado >= SEM_TOQUE_S:
		_fechar(false)      # ninguém na máquina: o menu volta
		return
	# o pendrive: espetou / tirou / acabou de gravar - a conta aparece sozinha
	_olhar_pen += delta
	if _olhar_pen >= 3.0 and _leads_painel == null:
		_olhar_pen = 0.0
		_atualizar_pen()
	if _bt_apagar.text != "APAGAR EVENTO" and Time.get_ticks_msec() - _apagar_em > 5000:
		_bt_apagar.text = "APAGAR EVENTO"
		_apagar_em = 0
	if Time.get_ticks_msec() - _aberto_em < 600 or ControleTv.teclado_aberto() or _leads_painel != null:
		return
	# os botões da máquina: START joga, SELECT passa para o próximo evento
	if Input.is_action_just_pressed("input_start"):
		parado = 0.0
		_jogar()
	elif InputMap.has_action("input_cup") and Input.is_action_just_pressed("input_cup") and _eventos.size() > 1:
		var i := 0
		for j in range(_eventos.size()):
			if str(_eventos[j]["nome"]) == _escolhido:
				i = j
		_escolher(str(_eventos[(i + 1) % _eventos.size()]["nome"]), true)
