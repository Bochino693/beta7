"""Imita o que a IDE do Arduino faz antes de compilar um .ino: copia o
prototipo de cada funcao para antes da PRIMEIRA funcao do arquivo.
Um tipo (struct) declarado depois disso da "does not name a type" na IDE,
mesmo compilando certo num compilador comum.

    python3 -I como_a_ide.py entrada.ino saida.ino
"""
import re
import sys

s = open(sys.argv[1]).read()
padrao = r'(?m)^([A-Za-z_][A-Za-z0-9_ ]*?[ \*&]+[A-Za-z_][A-Za-z0-9_]*\([^;{}]*\))\s*\{'
proibidas = ('if', 'while', 'for', 'switch', 'else', 'struct', 'return')
funcoes = [m for m in re.finditer(padrao, s) if m.group(1).split()[0] not in proibidas]
if not funcoes:
    sys.exit("nenhuma funcao encontrada em " + sys.argv[1])
prototipos = ''.join(m.group(1) + ';\n' for m in funcoes)
i = funcoes[0].start()
open(sys.argv[2], 'w').write(s[:i] + prototipos + s[i:])
print("%d prototipos antes de '%s'" % (len(funcoes), funcoes[0].group(1)))
