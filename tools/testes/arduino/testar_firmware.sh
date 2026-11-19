#!/bin/bash
# TESTE DO FIRMWARE DO ARDUINO NO PC (sem placa): compila o
# arduino/gol_flash_arena com um Arduino de mentira (mock/) e simula os
# comandos de LED do jogo, os 7 sensores, START, SELECT e o moedeiro.
#     bash tools/testes/arduino/testar_firmware.sh
# Precisa so do g++.
set -e
AQUI="$(cd "$(dirname "$0")" && pwd)"
INO="$AQUI/../../../arduino/gol_flash_arena/gol_flash_arena.ino"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
falhou=0
variante() {  # nome, sed
  sed "$2" "$INO" > "$TMP/fw.ino"
  g++ -std=gnu++17 -Wall -Wextra -Wno-unused-parameter -I"$AQUI/mock" -I"$TMP" \
    -DARQUIVO_FW='"fw.ino"' "$AQUI/teste_firmware.cpp" -o "$TMP/t_$1"
  printf '%-12s ' "$1"; "$TMP/t_$1" || falhou=1
}
variante padrao 's/x/x/'
variante sensor_nf 's/^#define SENSOR_NF 0/#define SENSOR_NF 1/'
variante ficha_nf 's/^#define FICHA_NF 0/#define FICHA_NF 1/'
variante teste 's/^#define TESTE_AO_LIGAR 0/#define TESTE_AO_LIGAR 1/'
[ $falhou = 0 ] || exit 1
