"""Tira as funções anônimas mais comuns (Godot 4) do GDScript do Godot 3.

    python tools/lambdas_g3.py arquivo.gd

  X.sort_custom(func(a, b) -> bool:      ->  X.sort_custom(self, "_ordem_N")
      corpo                                  + func _ordem_N(a, b) -> bool:
  )                                              corpo   (no fim do arquivo)
  t.tween_callback(func(): f(1, 2))      ->  t.tween_callback(self, "f", [1, 2])
  b.pressed.connect(func(): f(x))        ->  b.connect("pressed", self, "f", [x])

As que usam variáveis do lugar em várias linhas ficam para a mão.
"""
import re
import sys

arq = sys.argv[1]
linhas = open(arq, encoding="utf-8").read().split("\n")
saida = []
metodos = []
n = 0
i = 0


def indent(l):
    return len(l) - len(l.lstrip("\t"))


while i < len(linhas):
    l = linhas[i]
    m = re.match(r"^(\s*)(.*?)\.sort_custom\(func\((\w+)(?:\s*:\s*\w+)?\s*,\s*(\w+)(?:\s*:\s*\w+)?\)\s*(?:->\s*bool)?\s*:\s*(#.*)?$", l)
    if m:
        base = indent(l)
        corpo = []
        j = i + 1
        while j < len(linhas) and (linhas[j].strip() == "" or indent(linhas[j]) > base):
            corpo.append(linhas[j])
            j += 1
        if j < len(linhas) and linhas[j].strip() == ")":
            n += 1
            nome = "_ordem_%d" % n
            saida.append("%s%s.sort_custom(self, \"%s\")" % (m.group(1), m.group(2), nome))
            desloc = indent(corpo[0]) - 1 if corpo else 0
            metodos.append("\n\nfunc %s(%s, %s) -> bool:" % (nome, m.group(3), m.group(4)))
            for c in corpo:
                metodos.append(c[desloc:] if c.strip() else "")
            i = j + 1
            continue
    m = re.match(r"^(\s*)(.*?)\.tween_callback\(func\(\):\s*(\w+)\((.*)\)\)\s*(#.*)?$", l)
    if m:
        args = m.group(4).strip()
        saida.append("%s%s.tween_callback(self, \"%s\"%s)" % (m.group(1), m.group(2), m.group(3), (", [%s]" % args) if args else ""))
        i += 1
        continue
    m = re.match(r"^(\s*)(.*?)\.(\w+)\.connect\(func\(\):\s*(\w+)\((.*)\)\)\s*(#.*)?$", l)
    if m:
        args = m.group(5).strip()
        saida.append("%s%s.connect(\"%s\", self, \"%s\"%s)" % (m.group(1), m.group(2), m.group(3), m.group(4), (", [%s]" % args) if args else ""))
        i += 1
        continue
    saida.append(l)
    i += 1

texto = "\n".join(saida).rstrip("\n") + "\n" + "\n".join(metodos) + "\n"
open(arq, "w", encoding="utf-8").write(texto)
print(arq, ": %d comparadores, restam %d func(" % (n, texto.count("func(")))
