"""Segunda passada da conversão: geometria de Control em variável SEM tipo.

    python tools/controles_por_inferencia.py ORIGINAL_GODOT4.gd CONVERTIDO_GODOT3.gd

No Godot 3 um Control não tem position/size/scale/pivot_offset (são
rect_position, rect_size...). O conversor troca quando a variável tem tipo
declarado; aqui vão as que não têm, descobertas pelo ORIGINAL do Godot 4,
que ainda guarda o que a conversão apaga:

  var botoes: Array[Button]          -> elemento é Control
  func _criar_card() -> Panel:       -> o retorno é Control
  var b = botoes[i]  /  for b in botoes  /  var p = _criar_card()
  var x = Panel.new()  /  y as Label  /  get_node("..") as Control

Cada função tem as suas locais (o mesmo nome pode ser Rect2 em outra); os
membros valem no arquivo todo. Só troca acesso a propriedade (não chamada).
"""
import re
import sys

CONTROLS = {
    "Control", "Label", "Panel", "ColorRect", "TextureRect", "Button",
    "NinePatchRect", "MarginContainer", "VBoxContainer", "HBoxContainer",
    "CenterContainer", "PanelContainer", "RichTextLabel", "ProgressBar",
    "TextureProgressBar", "TextureProgress", "LineEdit", "ReferenceRect",
    "GridContainer", "ScrollContainer", "TextureButton", "BaseButton",
    "Container", "VideoStreamPlayer", "VideoPlayer", "OptionButton", "SpinBox",
    "HSlider", "VSlider", "CheckBox", "CheckButton", "ItemList", "Tree",
    "TabContainer", "HSeparator", "VSeparator", "AspectRatioContainer",
    "FlowContainer", "HFlowContainer", "VFlowContainer", "SubViewportContainer",
    "ViewportContainer", "Range", "TextEdit", "MenuButton", "LinkButton",
}
PROPS = {
    "position": "rect_position", "size": "rect_size", "scale": "rect_scale",
    "pivot_offset": "rect_pivot_offset", "global_position": "rect_global_position",
    "custom_minimum_size": "rect_min_size", "rotation_degrees": "rect_rotation",
}
ID = r"[A-Za-z_]\w*"


def tipo_base(t):
    t = t.strip()
    m = re.match(r"Array\[(\w+)\]", t)
    return ("[]", m.group(1)) if m else ("", t)


def juntar_assinaturas(texto):
    """func f(\n a,\n b\n) -> Label:  vira uma linha só (mantém a contagem de linhas)."""
    linhas = texto.split("\n")
    i = 0
    while i < len(linhas):
        l = linhas[i]
        if re.match(r"^(?:static\s+)?func\s+\w+\s*\(", l) and not re.search(r"\)\s*(->\s*[\w\[\]]+)?\s*:\s*(#.*)?$", l):
            j = i + 1
            while j < len(linhas) and j - i < 12:
                l = l + " " + linhas[j].strip()
                linhas[j] = ""
                if re.search(r"\)\s*(->\s*[\w\[\]]+)?\s*:\s*(#.*)?$", l):
                    break
                j += 1
            linhas[i] = l
        i += 1
    return "\n".join(linhas)


def analisar(orig):
    """membros: nome -> 'C' (Control) ou '[C]' (array de Control); funções -> retorno."""
    orig = juntar_assinaturas(orig)
    membros, retornos = {}, {}
    funcoes = []  # (nome, linha_ini, linha_fim)
    linhas = orig.split("\n")
    atual = None
    for i, l in enumerate(linhas):
        m = re.match(r"^(?:static\s+)?func\s+(%s)\s*\((.*?)\)\s*(?:->\s*([\w\[\]]+))?\s*:" % ID, l)
        if m:
            if atual:
                funcoes.append((atual[0], atual[1], i))
            atual = (m.group(1), i)
            if m.group(3):
                arr, t = tipo_base(m.group(3))
                if t in CONTROLS:
                    retornos[m.group(1)] = "[C]" if arr else "C"
            continue
        m = re.match(r"^(?:@onready\s+|@export\s+)?var\s+(%s)\s*:\s*([\w\[\]]+)" % ID, l)
        if m and not l.startswith("\t"):
            arr, t = tipo_base(m.group(2))
            if t in CONTROLS:
                membros[m.group(1)] = "[C]" if arr else "C"
        m = re.match(r"^(?:@onready\s+)?var\s+(%s)\s*:?=\s*(%s)\.new\(\)" % (ID, ID), l)
        if m and not l.startswith("\t") and m.group(2) in CONTROLS:
            membros[m.group(1)] = "C"
    if atual:
        funcoes.append((atual[0], atual[1], len(linhas)))
    return membros, retornos, funcoes, linhas


def tipo_expr(expr, escopo, retornos):
    expr = expr.strip()
    expr = re.sub(r"\s*#.*$", "", expr)
    m = re.search(r"\bas\s+(\w+)\s*$", expr)
    if m:
        return "C" if m.group(1) in CONTROLS else None
    m = re.match(r"^(%s)\.new\(\)$" % ID, expr)
    if m:
        return "C" if m.group(1) in CONTROLS else None
    m = re.match(r"^(%s)\[.*\]$" % ID, expr)
    if m and escopo.get(m.group(1)) == "[C]":
        return "C"
    m = re.match(r"^(?:self\.)?(%s)\(" % ID, expr)
    if m and m.group(1) in retornos:
        return retornos[m.group(1)]
    m = re.match(r"^(%s)$" % ID, expr)
    if m and m.group(1) in escopo:
        return escopo[m.group(1)]
    return None


def locais_da_funcao(linhas, ini, fim, membros, retornos):
    escopo = dict(membros)
    cab = linhas[ini]
    m = re.match(r"^(?:static\s+)?func\s+%s\s*\((.*?)\)" % ID, cab)
    if m:
        for p in m.group(1).split(","):
            pm = re.match(r"\s*(%s)\s*:\s*([\w\[\]]+)" % ID, p)
            if pm:
                arr, t = tipo_base(pm.group(2))
                if t in CONTROLS:
                    escopo[pm.group(1)] = "[C]" if arr else "C"
                else:
                    escopo.pop(pm.group(1), None)
    for _ in range(3):  # propaga (b = a; c = b)
        for l in linhas[ini + 1:fim]:
            m = re.match(r"^\s*var\s+(%s)\s*:\s*([\w\[\]]+)" % ID, l)
            if m:
                arr, t = tipo_base(m.group(2))
                if t in CONTROLS:
                    escopo[m.group(1)] = "[C]" if arr else "C"
                else:
                    escopo.pop(m.group(1), None)
                continue
            m = re.match(r"^\s*var\s+(%s)\s*:?=\s*(.+)$" % ID, l)
            if m:
                t = tipo_expr(m.group(2), escopo, retornos)
                if t:
                    escopo[m.group(1)] = t
                continue
            m = re.match(r"^\s*for\s+(%s)(?:\s*:\s*\w+)?\s+in\s+(%s)\s*:" % (ID, ID), l)
            if m and escopo.get(m.group(2)) == "[C]":
                escopo[m.group(1)] = "C"
    return escopo


def trocar_linha(l, escopo):
    if l.lstrip().startswith("#"):
        return l
    def troca(m):
        nome, prop = m.group(1), m.group(2)
        if escopo.get(nome) != "C":
            return m.group(0)
        return "%s.%s" % (nome, PROPS[prop])
    padrao = r"\b(%s)\.(%s)\b(?!\s*\()" % (ID, "|".join(PROPS))
    return re.sub(padrao, troca, l)


def main():
    orig = open(sys.argv[1], encoding="utf-8").read()
    arq = sys.argv[2]
    conv = open(arq, encoding="utf-8").read().split("\n")
    membros, retornos, funcoes, linhas_orig = analisar(orig)
    # escopo de cada função do original, pelo nome
    escopos = {}
    for nome, ini, fim in funcoes:
        escopos[nome] = locais_da_funcao(linhas_orig, ini, fim, membros, retornos)
    atual = dict(membros)
    trocas = 0
    for i, l in enumerate(conv):
        m = re.match(r"^(?:static\s+)?func\s+(%s)\s*\(" % ID, l)
        if m:
            atual = escopos.get(m.group(1), dict(membros))
            continue
        n = trocar_linha(l, atual)
        if n != l:
            trocas += 1
            conv[i] = n
    open(arq, "w", encoding="utf-8").write("\n".join(conv))
    print("%s: %d linhas com geometria de Control corrigida" % (arq, trocas))


if __name__ == "__main__":
    main()
