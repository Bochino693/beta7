#!/bin/bash
# TESTE DO FIRMWARE DO ARDUINO NO PC (sem placa): compila o
# arduino/olho_no_lance com um Arduino de mentira (mock/) e simula os
# comandos de LED do jogo, os 7 sensores, START, SELECT e o moedeiro.
#     bash tools/testes/arduino/testar_firmware.sh
# Precisa so do g++.
set -e
AQUI="$(cd "$(dirname "$0")" && pwd)"
INO="$AQUI/../../../arduino/olho_no_lance/olho_no_lance.ino"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
falhou=0
variante() {  # nome, sed
  sed "$2" "$INO" > "$TMP/fw.ino"
  g++ -std=gnu++17 -Wall -Wextra -Wno-unused-parameter -I"$AQUI/mock" -I"$TMP" \
    -DARQUIVO_FW='"fw.ino"' "$AQUI/teste_firmware.cpp" -o "$TMP/t_$1"
  printf '%-12s ' "$1"; "$TMP/t_$1" || falhou=1
}
# COMO A IDE DO ARDUINO COMPILA (como_a_ide.py): os prototipos de todas as
# funcoes vao para antes da primeira funcao. Um struct declarado depois
# disso so da erro na IDE - este passo pega isso aqui.
python3 -I "$AQUI/como_a_ide.py" "$INO" "$TMP/fw.ino" > "$TMP/ide_info.txt"
if g++ -std=gnu++17 -Wno-unused-parameter -I"$AQUI/mock" -I"$TMP" -DARQUIVO_FW='"fw.ino"' \
    "$AQUI/teste_firmware.cpp" -o "$TMP/t_ide" 2> "$TMP/ide.txt"; then
  printf '%-12s ' "como_a_ide"; "$TMP/t_ide" || falhou=1
else
  echo "como_a_ide   FALHOU: a IDE do Arduino nao compilaria:"; grep -m4 "error" "$TMP/ide.txt"; falhou=1
fi
variante padrao 's/x/x/'
variante sensor_nf 's/^#define SENSOR_NF 0/#define SENSOR_NF 1/'
variante ficha_nf 's/^#define FICHA_NF 0/#define FICHA_NF 1/'
variante teste 's/^#define TESTE_AO_LIGAR 0/#define TESTE_AO_LIGAR 1/'
[ $falhou = 0 ] || exit 1
