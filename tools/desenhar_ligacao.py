"""Desenha a MONTAGEM DO ARDUINO do Gol Flash Arena (fundo branco), com os
mesmos pinos do firmware arduino/gol_flash_arena/gol_flash_arena.ino:
  7 fitas/aneis de LED dos alvos (D2..D8), 7 sensores (D9..D12, A0..A2),
  START (A3), SELECT (A4), moedeiro (A5), fonte 5 V dos LEDs e a TV Box.

    python3 -I tools/desenhar_ligacao.py [destino.svg]
    (padrao: arduino/ligacao_gol_flash_arena.svg)

O PNG e o PDF saem do SVG: tools/desenho_para_png_pdf.js (Chromium).
"""
import os
import sys

W, H = 3800, 2860
SANS = "DejaVu Sans, Verdana, Arial, sans-serif"
TXT = "#1b2a41"
CINZA = "#5d6d7e"
LETRAS = "ABCDEFG"
# cor do fio de cada pino
COR_LED = ["#1565c0", "#2e7d32", "#c62828", "#f9a825", "#8e24aa", "#00838f", "#ef6c00"]
COR_SENSOR = ["#5c6bc0", "#43a047", "#e53935", "#c0a000", "#ab47bc", "#00acc1", "#fb8c00"]
PINO_LED = ["D2", "D3", "D4", "D5", "D6", "D7", "D8"]
PINO_SENSOR = ["D9", "D10", "D11", "D12", "A0", "A1", "A2"]
COR_START, COR_SELECT, COR_FICHA = "#2e7d32", "#f9a825", "#6d4c41"

out = []


def add(s):
    out.append(s)


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def rect(x, y, w, h, fill, stroke="none", sw=0, rx=0, dash=None, op=None):
    e = ' stroke-dasharray="%s"' % dash if dash else ""
    e += ' opacity="%s"' % op if op else ""
    add('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" rx="%s" fill="%s" stroke="%s" stroke-width="%s"%s/>' % (x, y, w, h, rx, fill, stroke, sw, e))


def circ(x, y, r, fill, stroke="none", sw=0, op=None):
    e = ' opacity="%s"' % op if op else ""
    add('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" stroke="%s" stroke-width="%s"%s/>' % (x, y, r, fill, stroke, sw, e))


def texto(x, y, s, tam=24, cor=TXT, peso="normal", ancora="start"):
    """**negrito** dentro do texto vira <tspan> em negrito."""
    partes = s.split("**")
    corpo = ""
    for i, p in enumerate(partes):
        corpo += ('<tspan font-weight="bold">%s</tspan>' % esc(p)) if i % 2 else esc(p)
    add('<text x="%.1f" y="%.1f" font-family="%s" font-size="%s" fill="%s" font-weight="%s" text-anchor="%s">%s</text>' % (x, y, SANS, tam, cor, peso, ancora, corpo))


def bloco(x, y, linhas, tam=25, entre=1.45, cor=TXT):
    for i, l in enumerate(linhas):
        if l:
            texto(x, y + i * tam * entre, l, tam, cor)


def fio(pontos, cor, sw=9, dash=None):
    """Fio com cantos arredondados, contorno escuro e brilho."""
    r = 16
    d = "M%.1f %.1f" % pontos[0]
    for i in range(1, len(pontos) - 1):
        x0, y0 = pontos[i - 1]
        x1, y1 = pontos[i]
        x2, y2 = pontos[i + 1]

        def perto(ax, ay, bx, by):
            dx, dy = bx - ax, by - ay
            n = max(1e-6, (dx * dx + dy * dy) ** 0.5)
            k = min(r, n / 2) / n
            return ax + dx * k, ay + dy * k

        ex, ey = perto(x1, y1, x0, y0)
        sx, sy = perto(x1, y1, x2, y2)
        d += " L%.1f %.1f Q%.1f %.1f %.1f %.1f" % (ex, ey, x1, y1, sx, sy)
    d += " L%.1f %.1f" % pontos[-1]
    e = ' stroke-dasharray="%s"' % dash if dash else ""
    add('<path d="%s" fill="none" stroke="#10151c" stroke-width="%s" stroke-linejoin="round" stroke-linecap="round" opacity="0.55"%s/>' % (d, sw + 4, e))
    add('<path d="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linejoin="round" stroke-linecap="round"%s/>' % (d, cor, sw, e))
    add('<path d="%s" fill="none" stroke="white" stroke-width="%s" stroke-linejoin="round" stroke-linecap="round" opacity="0.28"%s/>' % (d, max(1.5, sw * 0.25), e))


def etiqueta(x, y, s, fundo="#212121", cor="white", tam=22, ancora="middle"):
    w = len(s) * tam * 0.63 + 22
    x0 = x - w / 2 if ancora == "middle" else (x if ancora == "start" else x - w)
    rect(x0, y - tam * 0.78, w, tam * 1.32, fundo, "#00000055", 1.5, rx=8)
    texto(x0 + w / 2, y + tam * 0.20, s, tam, cor, "bold", "middle")


def caixa(x, y, w, h, titulo, cor, tam=28):
    rect(x + 4, y + 6, w, h, "#000000", rx=18, op=0.10)
    rect(x, y, w, h, "white", cor, 4, rx=18)
    add('<path d="M%.1f %.1f h%.1f a18 18 0 0 1 18 18 v%.1f h-%.1f v-%.1f a18 18 0 0 1 18 -18 z" fill="%s"/>' % (x + 18, y, w - 36, 38, w, 38, cor))
    texto(x + 26, y + 39, titulo, tam, "white", "bold")


def resistor(x, y, cor):
    """Resistor de 330 ohm em pe no fio (x, y = centro)."""
    rect(x - 13, y - 30, 26, 60, "#d9c08a", "#7a6a45", 2, rx=10)
    for i, c in enumerate(["#e65100", "#e65100", "#6d4c41", "#c9a227"]):
        rect(x - 13, y - 22 + i * 12, 26, 6, c)


# ============================================================ medidas da placa
NX, NY, NW, NH = 1180, 1010, 1440, 330
PASSO = 88
TOPO = ["TX1", "RX0", "RST", "GND", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9", "D10", "D11", "D12"]
BASE = ["VIN", "GND", "RST", "5V", "A7", "A6", "A5", "A4", "A3", "A2", "A1", "A0", "AREF", "3V3", "D13"]


def px(nome, cima=True):
    lista = TOPO if cima else BASE
    return NX + 104 + lista.index(nome) * PASSO


COR_PINO = {}
for _i in range(7):
    COR_PINO[PINO_LED[_i]] = COR_LED[_i]
    COR_PINO[PINO_SENSOR[_i]] = COR_SENSOR[_i]
COR_PINO.update({"A3": COR_START, "A4": COR_SELECT, "A5": COR_FICHA, "GND": "#262626"})


def nano():
    rect(NX + 6, NY + 10, NW, NH, "#000", rx=22, op=0.22)
    rect(NX, NY, NW, NH, "#1b4f9c", "#0d2f63", 5, rx=22)
    # trilhas
    for i in range(14):
        add('<path d="M%.1f %.1f v60 h40" fill="none" stroke="#2a66bd" stroke-width="3" opacity="0.7"/>' % (NX + 150 + i * PASSO, NY + 70))
    # chip, cristal, botao
    rect(NX + 640, NY + 118, 110, 96, "#1c1c1c", "#000", 2, rx=6)
    texto(NX + 695, NY + 162, "ATMEGA", 17, "#cfd8dc", "bold", "middle")
    texto(NX + 695, NY + 184, "328P", 17, "#cfd8dc", "bold", "middle")
    rect(NX + 500, NY + 142, 90, 46, "#cfd8dc", "#78909c", 2, rx=22)
    texto(NX + 545, NY + 172, "16.000", 15, "#37474f", "bold", "middle")
    rect(NX + 330, NY + 126, 70, 70, "#eceff1", "#90a4ae", 3, rx=8)
    circ(NX + 365, NY + 161, 21, "#263238")
    texto(NX + 365, NY + 218, "RESET", 14, "#dfe9f5", "bold", "middle")
    texto(NX + 1040, NY + 158, "ARDUINO NANO", 34, "white", "bold", "middle")
    texto(NX + 1040, NY + 192, "5 V · 16 MHz · no Uno: mesmos nomes de pinos", 19, "#cfe0f5", "normal", "middle")
    # conector USB
    rect(NX + NW - 6, NY + 104, 96, 122, "#cfd8dc", "#78909c", 3, rx=8)
    rect(NX + NW + 22, NY + 138, 56, 54, "#263238", rx=6)
    # pinos
    for lista, yy, cima in ((TOPO, NY + 42, True), (BASE, NY + NH - 42, False)):
        for i, nome in enumerate(lista):
            x = NX + 104 + i * PASSO
            usado = nome in COR_PINO
            if usado:
                circ(x, yy, 27, "none", COR_PINO[nome], 6)
            circ(x, yy, 19, "#d4a829", "#8a6a12", 2.5)
            circ(x, yy, 8, "#3b2f0a")
            texto(x, yy + (58 if cima else -40), nome, 24 if usado else 21, "white" if usado else "#9db7dd", "bold" if usado else "normal", "middle")
    for cx, cy in ((NX + 30, NY + 30), (NX + NW - 30, NY + 30), (NX + 30, NY + NH - 30), (NX + NW - 30, NY + NH - 30)):
        circ(cx, cy, 15, "#e8eef5", "#8fa1b5", 3)


# ================================================================== cabecalho
def cabecalho():
    rect(0, 0, W, H, "white")
    texto(60, 100, "GOL FLASH ARENA · MONTAGEM DO ARDUINO", 78, "#16407a", "bold")
    texto(62, 150, "Arduino **Nano** ou **Uno** visto de cima · firmware **arduino/gol_flash_arena** (GOL_FLASH:1) · o mesmo cabo USB serve no **PC** e na **TV Box / TV Android**", 27, CINZA)
    # legenda
    rect(2720, 34, 1040, 124, "white", "#b0bec5", 3, rx=16)
    fio([(2750, 74), (2860, 74)], "#455a64", 9)
    texto(2880, 83, "fio: ligar", 24)
    etiqueta(3110, 82, "GND", "#262626")
    texto(3160, 83, "= no GND comum (todos juntos)", 24)
    etiqueta(2805, 132, "+5V", "#d32f2f")
    texto(2880, 133, "= no + da FONTE 5 V dos LEDs (não no Arduino)", 24)
    cores = COR_LED
    for i, c in enumerate(cores):
        rect(i * W / 7.0, 178, W / 7.0 + 1, 10, c)


# ===================================================================== alvos
BX0, BW, BGAP = 50, 318, 20
BY, BH = 250, 372


def bx(i):
    return BX0 + i * (BW + BGAP)


def anel(cx, cy, cor):
    circ(cx, cy, 74, "#15191f", "#000", 3)
    circ(cx, cy, 44, "white", "#cfd8dc", 2)
    import math
    for k in range(12):
        a = k * math.tau / 12
        x, y = cx + 59 * math.cos(a), cy + 59 * math.sin(a)
        circ(x, y, 14, cor, op=0.30)
        circ(x, y, 9, cor, "white", 2)


def alvos():
    texto(BX0, 232, "OS 7 ALVOS — fita ou anel de LED endereçável (WS2812B): o fio **DIN** de cada alvo vai no pino dele, com um resistor de 330 Ω", 30, TXT, "bold")
    for i in range(7):
        x = bx(i)
        c = COR_LED[i]
        caixa(x, BY, BW, BH, "ALVO %s · LED" % LETRAS[i], c, 27)
        anel(x + BW / 2, BY + 148, c)
        texto(x + BW / 2, BY + 158, LETRAS[i], 44, c, "bold", "middle")
        texto(x + BW / 2, BY + 262, "DIN → %s" % PINO_LED[i], 30, c, "bold", "middle")
        # borne: +5V  DIN  GND
        rect(x + 24, BY + BH - 62, BW - 48, 40, "#2e7d32", "#1b5e20", 2, rx=6)
        for k, nome in enumerate(["+5V", "DIN", "GND"]):
            xx = x + 62 + k * (BW - 124) / 2.0
            circ(xx, BY + BH - 42, 11, "#cfd8dc", "#607d8b", 2)
            texto(xx, BY + BH - 72, nome, 19, TXT, "bold", "middle")
        etiqueta(x + 62, BY + BH + 44, "+5V", "#d32f2f")
        fio([(x + 62, BY + BH - 42), (x + 62, BY + BH + 20)], "#d32f2f", 8)
        etiqueta(x + BW - 62, BY + BH + 44, "GND", "#262626")
        fio([(x + BW - 62, BY + BH - 42), (x + BW - 62, BY + BH + 20)], "#262626", 8)


def sensores_de_cima():
    x0 = bx(7) + 30
    texto(x0, 232, "SENSORES A, B, C, D  (E, F, G: embaixo)", 30, TXT, "bold")
    for k in range(4):
        x = x0 + k * (BW - 4)
        w = BW - 24
        c = COR_SENSOR[k]
        caixa(x, BY, w, BH, "SENSOR %s" % LETRAS[k], c, 27)
        sensor(x + w / 2, BY + 150, c)
        texto(x + w / 2, BY + 262, "sinal → %s" % PINO_SENSOR[k], 30, c, "bold", "middle")
        borne2(x, BY + BH - 62, w)
        etiqueta(x + w - 70, BY + BH + 44, "GND", "#262626")
        fio([(x + w - 70, BY + BH - 42), (x + w - 70, BY + BH + 20)], "#262626", 8)


def sensor(cx, cy, cor):
    """Microchave / sensor de impacto atras do alvo."""
    rect(cx - 86, cy - 44, 172, 88, "#1c1f24", "#000", 3, rx=10)
    rect(cx - 70, cy - 66, 150, 16, "#b0bec5", "#607d8b", 2, rx=6)
    circ(cx + 70, cy - 60, 13, "#eceff1", "#607d8b", 3)
    texto(cx, cy + 4, "contato", 21, "#cfd8dc", "bold", "middle")
    texto(cx, cy + 28, "do alvo", 19, "#90a4ae", "normal", "middle")
    circ(cx - 60, cy - 20, 8, cor)


def borne2(x, y, w):
    rect(x + 24, y, w - 48, 40, "#2e7d32", "#1b5e20", 2, rx=6)
    for xx, nome in ((x + 70, "sinal"), (x + w - 70, "GND")):
        circ(xx, y + 20, 11, "#cfd8dc", "#607d8b", 2)
        texto(xx, y - 10, nome, 19, TXT, "bold", "middle")


def fios_de_cima():
    """Fios dos blocos de cima ate a fileira de cima do Nano, sem cruzar."""
    saidas = []   # (x do bloco, y de saida, pino, cor, resistor?)
    for i in range(7):
        saidas.append((bx(i) + BW / 2, BY + BH - 42, PINO_LED[i], COR_LED[i], True))
    x0 = bx(7) + 30
    for k in range(4):
        saidas.append((x0 + k * (BW - 4) + 70, BY + BH - 42, PINO_SENSOR[k], COR_SENSOR[k], False))
    base = NY + 42
    esq = [s for s in saidas if s[0] < px(s[2])]
    dir_ = [s for s in saidas if s[0] >= px(s[2])]
    # da esquerda: o bloco mais a esquerda leva a faixa mais baixa
    faixa = {}
    y_baixo = NY - 60
    for n, s in enumerate(esq):
        faixa[s[2]] = y_baixo - n * 34
    for n, s in enumerate(reversed(dir_)):
        faixa[s[2]] = y_baixo - n * 34
    for s in saidas:
        xb, yb, pino, cor, res = s
        xp = px(pino)
        fio([(xb, yb), (xb, faixa[pino]), (xp, faixa[pino]), (xp, base)], cor, 9)
        if res:
            resistor(xb, BY + BH + 46, cor)
            texto(xb + 22, BY + BH + 86, "330 Ω", 19, CINZA, "bold")


# ============================================================ blocos de baixo
YB = 1640
BAIXO = [  # nome, pino, cor, tipo
    ("MOEDEIRO", "A5", COR_FICHA, "ficha"),
    ("BOTÃO SELECT", "A4", COR_SELECT, "botao"),
    ("BOTÃO START", "A3", COR_START, "botao"),
    ("SENSOR G", "A2", COR_SENSOR[6], "sensor"),
    ("SENSOR F", "A1", COR_SENSOR[5], "sensor"),
    ("SENSOR E", "A0", COR_SENSOR[4], "sensor"),
]
BBW, BBH = 356, 372
BBX0 = 760


def bbx(i):
    return BBX0 + i * (BBW + 24)


def botao(cx, cy, cor):
    circ(cx, cy, 70, "#263238", "#000", 3)
    circ(cx, cy, 56, cor, "#00000066", 3)
    circ(cx - 16, cy - 18, 20, "white", op=0.35)


def moedeiro(cx, cy):
    rect(cx - 74, cy - 78, 148, 156, "#cfd8dc", "#78909c", 3, rx=10)
    rect(cx - 30, cy - 62, 60, 12, "#263238", rx=5)
    circ(cx, cy - 6, 30, "#f9a825", "#b47d00", 3)
    texto(cx, cy + 3, "R$", 22, "#6d4c00", "bold", "middle")
    circ(cx, cy + 50, 12, "#e53935", "#8e0000", 2)


def blocos_de_baixo():
    for i, (nome, pino, cor, tipo) in enumerate(BAIXO):
        x = bbx(i)
        caixa(x, YB, BBW, BBH, "", cor, 25)
        texto(x + BBW / 2, YB + 38, nome, 25, "white", "bold", "middle")
        cx = x + BBW / 2
        if tipo == "botao":
            botao(cx, YB + 200, cor)
        elif tipo == "ficha":
            moedeiro(cx, YB + 200)
        else:
            sensor(cx, YB + 206, cor)
        ys = YB + 72
        rect(x + 24, ys, BBW - 48, 40, "#2e7d32", "#1b5e20", 2, rx=6)
        rot = "COIN" if tipo == "ficha" else "sinal"
        for xx, n in ((x + 46, rot), (x + BBW - 46, "GND")):
            circ(xx, ys + 20, 11, "#cfd8dc", "#607d8b", 2)
            texto(xx + (48 if n == rot else -48), ys + 28, n, 19, "white", "bold", "middle")
        etiqueta(x + BBW - 46, YB - 26, "GND", "#262626")
        fio([(x + BBW - 46, ys + 20), (x + BBW - 46, YB - 6)], "#262626", 8)
        texto(cx, YB + 312, "%s → %s" % (rot, pino), 30, cor, "bold", "middle")
        nota = {"botao": "um fio no %s, o outro no GND" % pino,
                "sensor": "um fio no %s, o outro no GND" % pino,
                "ficha": "12 V e GND do moedeiro: fonte dele"}[tipo]
        texto(cx, YB + 346, nota, 19, CINZA, "normal", "middle")
    # fios: fileira de baixo do Nano
    base = NY + NH - 42
    pontos = [(bbx(i) + 46, YB + 92, BAIXO[i][1], BAIXO[i][2]) for i in range(len(BAIXO))]
    esq = [p for p in pontos if p[0] < px(p[2], False)]
    dir_ = [p for p in pontos if p[0] >= px(p[2], False)]
    y_alto = NY + NH + 80
    faixa = {}
    for n, p in enumerate(esq):
        faixa[p[2]] = y_alto + n * 34
    for n, p in enumerate(reversed(dir_)):
        faixa[p[2]] = y_alto + n * 34
    for xb, yb, pino, cor in pontos:
        xp = px(pino, False)
        fio([(xb, yb), (xb, faixa[pino]), (xp, faixa[pino]), (xp, base)], cor, 9)


# ======================================================== fonte, TV e tabela
def fonte():
    x, y, w, h = 60, 1000, 620, 420
    caixa(x, y, w, h, "FONTE 5 V DOS LEDS", "#b71c1c", 27)
    rect(x + 40, y + 76, 300, 190, "#cfd8dc", "#78909c", 3, rx=8)
    for r in range(5):
        for c in range(11):
            circ(x + 62 + c * 26, y + 100 + r * 26, 5, "#607d8b")
    rect(x + 60, y + 196, 260, 56, "#1b4f9c", rx=6)
    texto(x + 190, y + 234, "5 V · 10 A", 30, "white", "bold", "middle")
    rect(x + 360, y + 96, 220, 60, "#2e7d32", "#1b5e20", 2, rx=6)
    circ(x + 410, y + 126, 14, "#cfd8dc", "#607d8b", 2)
    circ(x + 530, y + 126, 14, "#cfd8dc", "#607d8b", 2)
    texto(x + 410, y + 88, "+V", 21, TXT, "bold", "middle")
    texto(x + 530, y + 88, "−V", 21, TXT, "bold", "middle")
    etiqueta(x + 410, y + 216, "+5V", "#d32f2f", tam=24)
    fio([(x + 410, y + 126), (x + 410, y + 190)], "#d32f2f", 9)
    etiqueta(x + 530, y + 216, "GND", "#262626", tam=24)
    fio([(x + 530, y + 126), (x + 530, y + 190)], "#262626", 9)
    bloco(x + 30, y + 300, [
        "**+5V** e **GND** de CADA fita saem daqui",
        "(fio 1,5 mm²), nunca do pino 5V do Arduino.",
        "Capacitor **1000 µF 16 V** entre +V e −V.",
    ], 22)
    # GND da fonte no GND do Nano (obrigatorio)
    xg = px("GND", False)
    yl = NY + NH + 34
    fio([(x + 590, y + 208), (x + w + 60, y + 208), (x + w + 60, yl), (xg, yl), (xg, NY + NH - 42)], "#262626", 10)
    etiqueta((x + w + 60 + xg) / 2, yl + 8, "GND da fonte → GND do Arduino (obrigatório)", "#262626", tam=20)


def tv_box():
    x, y, w, h = 2840, 1000, 900, 330
    rect(x + 6, y + 10, w, h, "#000", rx=24, op=0.2)
    rect(x, y, w, h, "#0f141b", "#000", 4, rx=24)
    rect(x + 30, y + 30, w - 60, 150, "#17202b", "#263545", 3, rx=14)
    texto(x + w / 2, y + 96, "TV BOX ou TV ANDROID", 44, "#ffd54f", "bold", "middle")
    texto(x + w / 2, y + 146, "o jogo Gol Flash Arena (APK)   ·   no PC: a mesma porta USB (COM5)", 23, "white", "normal", "middle")
    texto(x + w / 2, y + 226, "USB: dados + alimenta o Arduino", 28, "white", "bold", "middle")
    texto(x + w / 2, y + 268, "1ª vez: na janela do Android marque “Usar por padrão” e OK", 23, "#b0bec5", "normal", "middle")
    texto(x + w / 2, y + 302, "HDMI na TV · controle remoto opera o jogo", 21, "#78909c", "normal", "middle")
    # cabo USB
    yu = NY + 165
    fio([(NX + NW + 90, yu), (x, yu)], "#8a9399", 16)
    etiqueta((NX + NW + 90 + x) / 2, yu - 34, "CABO USB", "#455a64", tam=24)


def tabela():
    x, y, w, h = 60, 1640, 640, 650
    caixa(x, y, w, h, "TABELA DE PINOS", "#37474f", 27)
    linhas = []
    for i in range(7):
        linhas.append((COR_LED[i], PINO_LED[i], "LED do alvo %s (DIN, 330 Ω)" % LETRAS[i]))
    for i in range(7):
        linhas.append((COR_SENSOR[i], PINO_SENSOR[i], "sensor do alvo %s" % LETRAS[i]))
    linhas += [(COR_START, "A3", "botão START"), (COR_SELECT, "A4", "botão SELECT (COPA)"),
               (COR_FICHA, "A5", "moedeiro / noteiro (COIN)"),
               ("#262626", "GND", "GND de tudo (todos juntos)"),
               ("#9e9e9e", "D13, A6, A7", "livres")]
    for n, (cor, pino, oque) in enumerate(linhas):
        yy = y + 84 + n * 29.5
        if n % 2:
            rect(x + 12, yy - 22, w - 24, 29.5, "#f1f4f7")
        circ(x + 36, yy - 8, 9, cor, "#00000055", 1.5)
        texto(x + 58, yy, pino, 22, TXT, "bold")
        texto(x + 215, yy, oque, 22, TXT)


def textos():
    y, h = 2330, 480
    w = 900
    cx = [60, 990, 1920, 2850]
    ws = [900, 900, 900, 890]
    caixa(cx[0], y, ws[0], h, "A FONTE E AS FITAS", "#b71c1c")
    bloco(cx[0] + 30, y + 92, [
        "**Conta da fonte:** 0,05 A por LED aceso em branco.",
        "7 alvos × 30 LEDs = 210 LEDs → **fonte 5 V 10 A**.",
        "Menos LEDs? 7 alvos × 12 LEDs → 5 V 5 A basta.",
        "",
        "No .ino: **LEDS_POR_ALVO** = quantos LEDs tem CADA",
        "alvo (pode sobrar). **BRILHO_MAX** baixa o consumo.",
        "Cor trocada (pede vermelho, acende verde): troque",
        "**TIPO_FITA** para NEO_RGB ou NEO_BRG.",
        "Fita WS2811 de **12 V**: +12 V na fita (fonte 12 V),",
        "DIN e GND iguais ao desenho.",
    ], 24)
    caixa(cx[1], y, ws[1], h, "PRIMEIRA VEZ (passo a passo)", "#1565c0")
    bloco(cx[1] + 30, y + 92, [
        "**1.** IDE do Arduino: instale a biblioteca **Adafruit**",
        "**NeoPixel** e grave **gol_flash_arena.ino** (placa Nano:",
        "processador “ATmega328P (Old Bootloader)” se falhar).",
        "**2.** Monitor Serial a **9600**: aparece OLA:GOL_FLASH:1.",
        "Digite SET:A=255,0,0 (alvo A vermelho) e OFF.",
        "**3.** Bata em cada alvo: aparece S:A ... S:G.",
        "START mostra B:START:1 e a ficha mostra FICHA.",
        "**4.** USB na TV Box, abra o jogo, aceite a janela",
        "do USB com **“Usar por padrão”**.",
        "**5.** No jogo: MENU do controle → Central da Máquina",
        "→ teste os 7 LEDs e os 7 sensores.",
    ], 24)
    caixa(cx[2], y, ws[2], h, "SENSORES, START, SELECT E MOEDEIRO", "#2e7d32")
    bloco(cx[2] + 30, y + 92, [
        "**Contato simples** (microchave, sensor de impacto,",
        "botão): um fio no pino, o outro no **GND**. Não precisa",
        "de resistor: o Arduino já puxa o pino para 5 V.",
        "**Sensor de 3 fios (NPN, 5 V):** marrom no pino **5V**",
        "do Arduino, azul no GND, preto (sinal) no pino. **Nunca PNP.**",
        "Contato que ABRE ao acionar: **SENSOR_NF 1** no .ino.",
        "**Moedeiro:** só o fio COIN no A5 e o GND junto;",
        "o 12 V dele vem da fonte dele. Se ele mandar 12 V",
        "no COIN, use um optoacoplador.",
        "**No PC** a placa Zero Delay continua valendo: os",
        "sensores podem ficar nela (use um OU outro).",
    ], 24)
    caixa(cx[3], y, ws[3], h, "CUIDADOS", "#c62828")
    bloco(cx[3] + 30, y + 92, [
        "**Todos os GND juntos:** Arduino, fonte 5 V, fitas,",
        "sensores, botões e moedeiro.",
        "**Nunca 12 V num pino** do Arduino: meça cada fio",
        "de sinal antes de ligar.",
        "**Fitas pela fonte**, não pelo Arduino (o pino 5V",
        "aguenta só o Arduino).",
        "**Resistor de 330 Ω** em cada DIN, perto da fita;",
        "fio do DIN curto (até ~2 m; mais que isso use",
        "cabo blindado ou um conversor de nível 74HCT245).",
        "Ligue a **fonte 5 V antes** (ou junto) do USB.",
        "Desligue tudo da tomada para mexer nos fios.",
    ], 24)


def observacoes():
    x, y = 2840, 1380
    rect(x, y, 900, 200, "#fff8e1", "#f9a825", 3, rx=16)
    bloco(x + 26, y + 46, [
        "**Na TV Box / TV Android tudo passa pelo Arduino:** LEDs,",
        "sensores, START, SELECT e ficha — um cabo USB só.",
        "**No PC (Windows)** o jogo fala com ele pela COM5, como",
        "sempre; a placa Zero Delay continua funcionando lá.",
    ], 23)


def main():
    destino = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "arduino", "ligacao_gol_flash_arena.svg")
    add('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">' % (W, H, W, H))
    cabecalho()
    alvos()
    sensores_de_cima()
    fonte()
    fios_de_cima()
    blocos_de_baixo()
    tv_box()
    observacoes()
    nano()
    tabela()
    textos()
    add("</svg>")
    with open(destino, "w", encoding="utf-8") as f:
        f.write("\n".join(out))
    print("ok:", os.path.normpath(destino))


main()
