"""Poe a arte gerada (node tools/arte/gerar.js <pasta>) dentro do projeto:
capa, tela de abertura, icones (PC, Android), banner da Android TV e os dois
videos da abertura (PC e TV Box). Precisa do ffmpeg e do Pillow.

    python3 -I tools/arte/montar.py <pasta>
"""
import os
import subprocess
import sys
from PIL import Image

pasta = sys.argv[1]
P = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))


def p(*a):
    return os.path.join(P, *a)


capa = Image.open(os.path.join(pasta, "capa.png")).convert("RGB")
# 16:9 (1920 x 1080): a capa e a tela de abertura enchem a TV sem esticar nem sobrar borda
capa.save(p("images", "fut_cap.jpeg"), quality=92)
capa.save(p("branding", "splash_gol_flash_arena.png"), optimize=True)
icone = Image.open(os.path.join(pasta, "icone.png")).convert("RGB")
icone.save(p("gol_flash_arena_oficial.png"), optimize=True)
icone.resize((1254, 1254), Image.LANCZOS).save(p("branding", "gol_flash_arena_icon.png"), optimize=True)
icone.resize((192, 192), Image.LANCZOS).save(p("branding", "android_icone_192.png"), optimize=True)
icone.save(p("branding", "gol_flash_arena.ico"), sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
banner = Image.open(os.path.join(pasta, "banner.png")).convert("RGB")
banner.resize((320, 180), Image.LANCZOS).save(p("tools", "android", "StrikeSerial", "res", "drawable-xhdpi", "gol_flash_banner.png"), optimize=True)

# CAMADAS DA ABERTURA ANIMADA (TV Box: sem vídeo, o jogo anima as peças):
# o fundo inteiro e o logo recortado (com a posição dele na tela, em fração)
fundo = Image.open(os.path.join(pasta, "capa_fundo.png")).convert("RGB")
fundo.resize((1280, 720), Image.LANCZOS).save(p("images", "capa_fundo.jpg"), quality=90)
logo = Image.open(os.path.join(pasta, "capa_logo.png")).convert("RGBA")
caixa = logo.split()[3].point(lambda a: 255 if a > 8 else 0).getbbox()
recorte = logo.crop(caixa)
recorte = recorte.resize((recorte.size[0] * 2 // 3, recorte.size[1] * 2 // 3), Image.LANCZOS)
recorte.save(p("images", "capa_logo.png"), optimize=True)
W, H = logo.size
ls = Image.open(p("tools", "arte", "lazer_sport_estrelas.png")).convert("RGBA")
ls.resize((440, int(440 * ls.size[1] / ls.size[0])), Image.LANCZOS).save(p("images", "capa_lazer_sport.png"), optimize=True)
with open(p("images", "capa_posicoes.txt"), "w") as f:
    # x, y, largura, altura do logo na tela (0..1); o Lazer & Sport fica como no arte.html
    f.write("%.5f %.5f %.5f %.5f\n" % (caixa[0] / W, caixa[1] / H, (caixa[2] - caixa[0]) / W, (caixa[3] - caixa[1]) / H))
    f.write("%.5f %.5f %.5f\n" % (1.0 - (64 + 330) / 1536.0, 34 / 864.0, 330 / 1536.0))
# as posições também como script (o .txt não vai dentro do APK)
with open(p("scripts", "capa_posicoes.gd"), "w") as f:
    f.write("extends RefCounted\n\n## Gerado por tools/arte/montar.py: onde ficam as peças da capa (fração da tela).\n")
    f.write("const LOGO := Rect2(%.5f, %.5f, %.5f, %.5f)\n" % (caixa[0] / W, caixa[1] / H, (caixa[2] - caixa[0]) / W, (caixa[3] - caixa[1]) / H))
    f.write("const LAZER_SPORT := Rect2(%.5f, %.5f, %.5f, %.5f)\n" % (1.0 - (64 + 330) / 1536.0, 34 / 864.0, 330 / 1536.0, 330 / 1536.0 * ls.size[1] / ls.size[0] * 16.0 / 9.0))
print("ok: camadas da abertura animada", caixa)

quadros = os.path.join(pasta, "quadros", "%04d.png")
for saida, filtro, taxa in ((p("medias", "init.ogv"), "scale=1280:720", "6000k"), (p("medias", "init_tv.ogv"), "scale=848:480:flags=lanczos", "1800k")):
    subprocess.check_call(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-framerate", "24", "-i", quadros,
                           "-vf", filtro, "-an", "-c:v", "libtheora", "-b:v", taxa, "-g", "48", saida])
    print("ok:", os.path.relpath(saida, P), "%.1f MB" % (os.path.getsize(saida) / 1048576.0))
print("ok: capa, abertura, icones e banner")
