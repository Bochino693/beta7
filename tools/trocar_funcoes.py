"""Troca o CORPO de funções inteiras de um script GDScript.

    python tools/trocar_funcoes.py arquivo.gd especificacao.py

`especificacao.py` define TROCAS = {"_nome_da_funcao": "corpo novo"}: a
linha `func ...` fica como está e o corpo (até a próxima declaração no
começo da linha) vira o texto dado. Usado para trocar as pontes
PowerShell/COM5 da versão do PC pelo Arduino da TV Box.
"""
import re
import sys

TOPO = re.compile(r"^(func|static func|var|const|signal|onready|export|class|enum|remote|puppet|master)\b")


def trocar(texto, trocas):
    linhas = texto.split("\n")
    saida = []
    i = 0
    feitas = set()
    while i < len(linhas):
        l = linhas[i]
        m = re.match(r"^(?:static\s+)?func\s+(\w+)\s*\(", l)
        if m and m.group(1) in trocas:
            nome = m.group(1)
            saida.append(l)
            i += 1
            while i < len(linhas) and not TOPO.match(linhas[i]):
                i += 1
            corpo = trocas[nome].strip("\n")
            saida += corpo.split("\n")
            saida += ["", ""]
            feitas.add(nome)
            continue
        saida.append(l)
        i += 1
    faltam = set(trocas) - feitas
    if faltam:
        raise SystemExit("funções não encontradas: %s" % ", ".join(sorted(faltam)))
    return "\n".join(saida)


if __name__ == "__main__":
    arq, spec = sys.argv[1], sys.argv[2]
    ns = {}
    exec(open(spec, encoding="utf-8").read(), ns)
    t = open(arq, encoding="utf-8").read()
    open(arq, "w", encoding="utf-8").write(trocar(t, ns["TROCAS"]))
    print(arq, "->", ", ".join(ns["TROCAS"]))
