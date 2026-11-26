#!/usr/bin/env python3
"""ARTE DO CARTÃO DO JOGADOR (fundos/card_estadio.png) - feita para o Olho no Lance.

    python3 tools/arte/gerar_card.py

Desenha, do zero, o fundo dos cartões da partida: os holofotes do estádio com
os fachos de luz, as luzes da arquibancada, a rede do gol nas laterais, os
riscos de velocidade e o gramado em perspectiva com a grande área e o círculo.
O ALVO DE LED atrás do placar NÃO está aqui: quem desenha é o shader do cartão
(scripts/play.gd), no lugar exato do placar e com as luzes correndo.

A imagem NÃO tem cor: o jogo pinta na cor de cada jogador.
    canal vermelho = a luz que recebe a cor do jogador
    canal verde    = o que fica branco (o miolo dos holofotes, das linhas e das faíscas)
    canal azul     = a segunda cor (um tom vizinho), para a arte não ficar de uma cor só
"""
import os
import numpy as np
from PIL import Image, ImageFilter

N = 1024
rng = np.random.default_rng(7)
v, u = np.mgrid[0:N, 0:N].astype(np.float32) / (N - 1)


def borrar(a, raio):
    im = Image.fromarray(np.clip(a * 255.0, 0, 255).astype(np.uint8))
    return np.asarray(im.filter(ImageFilter.GaussianBlur(raio)), dtype=np.float32) / 255.0


def linha(d, largura):
    """Uma linha de luz: d = distância até ela (em fração da imagem)."""
    return np.exp(-(d / largura) ** 2)


cor = np.zeros((N, N), np.float32)      # recebe a cor do jogador
branco = np.zeros((N, N), np.float32)   # fica branco
segunda = np.zeros((N, N), np.float32)  # segunda cor

HORIZONTE = 0.60

# 1. o céu do estádio: mais claro perto do horizonte
cor += 0.10 + 0.20 * np.exp(-((v - HORIZONTE) / 0.30) ** 2)

# 2. os holofotes (dois cantos de cima) e os fachos de luz
for lado in (-1.0, 1.0):
    fx, fy = 0.5 + lado * 0.43, 0.035
    dx, dy = u - fx, v - fy
    dist = np.sqrt(dx * dx + dy * dy)
    ang = np.arctan2(dy, dx * -lado)          # 0 = para o meio, pi/2 = para baixo
    for alvo, forca, abre in ((0.62, 0.50, 0.060), (0.95, 0.34, 0.045), (0.34, 0.26, 0.040)):
        facho = np.exp(-((ang - alvo) / abre) ** 2) * np.exp(-dist / 0.85) * (dist > 0.03)
        cor += facho * forca
        segunda += facho * forca * 0.5
    cor += np.exp(-(dist / 0.16) ** 2) * 0.55          # o clarão em volta
    # as lâmpadas (3 x 3)
    for i in range(3):
        for j in range(3):
            lx = fx - lado * (0.012 + i * 0.030)
            ly = fy + 0.004 + j * 0.026
            d = np.sqrt((u - lx) ** 2 + (v - ly) ** 2)
            branco += np.exp(-(d / 0.0085) ** 2) * 0.95
            cor += np.exp(-(d / 0.022) ** 2) * 0.45

# 3. a arquibancada: uma faixa de luzinhas logo acima do horizonte
luzes = np.zeros((N, N), np.float32)
for _ in range(1500):
    x = rng.random()
    y = HORIZONTE - 0.012 - rng.random() ** 1.6 * 0.20
    yy, xx = int(y * N), int(x * N)
    luzes[yy:yy + 2, xx:xx + 2] = rng.random() * 0.9 + 0.1
arquibancada = borrar(luzes, 1.2) * 1.4 + borrar(luzes, 5) * 2.2
faixa = np.exp(-((v - (HORIZONTE - 0.09)) / 0.11) ** 2)
cor += arquibancada * 0.55 + faixa * 0.10
segunda += arquibancada * 0.35
branco += borrar(luzes, 0.8) * 0.35
# a linha do muro
cor += linha(v - HORIZONTE, 0.004) * 0.55

# 4. o gramado em perspectiva (abaixo do horizonte)
chao = (v > HORIZONTE).astype(np.float32)
prof = np.clip((v - HORIZONTE) / (1.0 - HORIZONTE), 1e-4, 1.0)   # 0 = longe, 1 = perto
mundo_x = (u - 0.5) / (0.18 + prof * 0.95)                       # abre para perto
mundo_z = 1.0 / (0.12 + prof)                                    # longe = grande
# faixas do corte da grama
grama = 0.5 + 0.5 * np.sign(np.sin(mundo_z * 5.2))
cor += chao * (0.10 + 0.07 * grama) * (0.55 + 0.45 * prof)
# linhas: as laterais, a grande área e o meio
linhas = np.zeros((N, N), np.float32)
esp = 0.010 / (0.30 + prof)                                      # mais finas ao longe
for x0 in (-0.92, 0.92):
    linhas += linha(mundo_x - x0, 0.018)
for x0 in (-0.42, 0.42):
    linhas += linha(mundo_x - x0, 0.016) * (mundo_z > 1.55)
linhas += linha(mundo_z - 1.55, 0.05) * (np.abs(mundo_x) < 0.43)
linhas += linha(mundo_z - 3.3, 0.10) * (np.abs(mundo_x) < 0.93)
# o círculo de perto (meia-lua)
raio_c = np.sqrt(mundo_x ** 2 + ((mundo_z - 0.86) * 0.9) ** 2)
linhas += linha(raio_c - 0.36, 0.022) * (prof > 0.45)
linhas *= chao
cor += borrar(linhas, 6) * 0.9 + linhas * 0.55
branco += linhas * 0.42
segunda += borrar(linhas, 14) * 0.6
# o reflexo dos holofotes no gramado
cor += chao * np.exp(-((u - 0.5) / 0.30) ** 2) * np.exp(-((prof - 0.25) / 0.35) ** 2) * 0.16

# 5. a rede do gol nas duas laterais (losangos), sumindo para o meio
borda = np.clip((np.abs(u - 0.5) - 0.30) / 0.20, 0.0, 1.0) ** 1.5
malha = np.maximum(linha(np.abs(np.sin((u + v * 0.9) * 62.0)), 0.085),
                   linha(np.abs(np.sin((u - v * 0.9) * 62.0)), 0.085))
rede = malha * borda * (v < HORIZONTE + 0.02) * (v > 0.10)
cor += rede * 0.30
segunda += rede * 0.22
branco += rede * 0.06

# 6. os riscos de velocidade, na diagonal
riscos = np.zeros((N, N), np.float32)
for _ in range(11):
    c0 = rng.random() * 1.5 - 0.25
    larg = 0.0014 + rng.random() * 0.0030
    comeco, tam = rng.random(), 0.10 + rng.random() * 0.20
    ao_longo = (u * 0.80 + (1.0 - v) * 0.60) / 1.4
    janela = np.exp(-((ao_longo - comeco) / tam) ** 2)
    riscos += linha((v + u * 0.55) - c0, larg) * janela * (0.25 + rng.random() * 0.55)
riscos *= (v < HORIZONTE + 0.10)
cor += borrar(riscos, 3) * 0.40 + riscos * 0.20
segunda += borrar(riscos, 8) * 0.55
branco += riscos * 0.08

# 7. faíscas
fa = np.zeros((N, N), np.float32)
for _ in range(210):
    x, y = rng.random(), rng.random() ** 0.8
    fa[int(y * (N - 2)), int(x * (N - 2))] = rng.random() * 0.8 + 0.2
branco += borrar(fa, 1.0) * 2.4
cor += borrar(fa, 4.5) * 3.2

# 8. as bordas mais escuras (a moldura do cartão acende por cima)
vinheta = 1.0 - 0.55 * np.clip((np.maximum(np.abs(u - 0.5), np.abs(v - 0.5)) - 0.30) / 0.20, 0, 1) ** 2
cor *= vinheta
segunda *= vinheta

img = np.stack([np.clip(cor, 0, 1), np.clip(branco, 0, 1), np.clip(segunda, 0, 1)], axis=-1)
saida = os.path.join(os.path.dirname(__file__), "..", "..", "fundos", "card_estadio.png")
Image.fromarray((img * 255.0 + 0.5).astype(np.uint8), "RGB").save(saida, optimize=True)
print("ok:", os.path.normpath(saida), os.path.getsize(saida) // 1024, "KB")

# prévia pintada (para conferir sem abrir o jogo)
if os.environ.get("PREVIA"):
    for nome, t in (("azul", (0.10, 0.75, 1.0)), ("vermelho", (1.0, 0.15, 0.15)), ("amarelo", (1.0, 0.85, 0.05)), ("roxo", (0.72, 0.38, 1.0))):
        t = np.array(t, np.float32)
        t2 = np.array([t[2], t[0], t[1]], np.float32) * 0.5 + t * 0.5
        p = img[..., 0:1] * t * 1.15 + img[..., 2:3] * t2 * 0.55 + img[..., 1:2]
        Image.fromarray((np.clip(p, 0, 1) * 255).astype(np.uint8), "RGB").save(os.path.join(os.environ["PREVIA"], "previa_card_%s.png" % nome))
