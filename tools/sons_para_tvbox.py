"""Troca res://songs/X.mp3 nos scripts pelo X.wav ou X.ogg que existir.

    python tools/sons_para_tvbox.py

Na TV Box os efeitos curtos são WAV (tocar não custa CPU) e as músicas
OGG; os MP3 da versão do PC saíram da pasta songs/.
"""
import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]


def trocar(m):
    nome = m.group(1)
    for ext in ("wav", "ogg"):
        if (RAIZ / "songs" / (nome + "." + ext)).exists():
            return "res://songs/%s.%s" % (nome, ext)
    return m.group(0)


for arq in sorted((RAIZ / "scripts").glob("*.gd")):
    t = arq.read_text(encoding="utf-8")
    n = re.sub(r"res://songs/([A-Za-z0-9_\-]+)\.mp3", trocar, t)
    if n != t:
        arq.write_text(n, encoding="utf-8")
        print("sons:", arq.name)
