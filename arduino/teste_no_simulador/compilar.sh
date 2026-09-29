#!/bin/bash
# Compila o sketch para o Arduino Nano (ATmega328P, 16 MHz) como a IDE faz.
set -e
S=$1
B=/tmp/claude-0/arduino/build
C=/tmp/claude-0/arduino/core
FLAGS="-mmcu=atmega328p -DF_CPU=16000000L -DARDUINO=10819 -DARDUINO_AVR_NANO -DARDUINO_ARCH_AVR -Os -ffunction-sections -fdata-sections -flto -fno-fat-lto-objects -I$C/cores/arduino -I$C/variants/eightanaloginputs -I$C/variants/standard -I/tmp/claude-0/arduino/neopixel"
CXX="avr-g++ $FLAGS -std=gnu++11 -fpermissive -fno-exceptions -fno-threadsafe-statics -Wall"
CC="avr-gcc $FLAGS -std=gnu11"
for f in $C/cores/arduino/*.c; do $CC -c $f -o $B/$(basename $f).o; done
for f in $C/cores/arduino/*.cpp; do $CXX -c $f -o $B/$(basename $f).o; done
avr-gcc $FLAGS -x assembler-with-cpp -c $C/cores/arduino/wiring_pulse.S -o $B/wiring_pulse.S.o
$CXX -c /tmp/claude-0/arduino/neopixel/Adafruit_NeoPixel.cpp -o $B/neo.o
$CC -c /tmp/claude-0/arduino/neopixel/esp.c -o $B/esp.o 2>/dev/null || true
# .ino -> .cpp (a IDE inclui Arduino.h e gera os prototipos)
{ echo '#include <Arduino.h>'; cat $S; } > $B/sketch.cpp
$CXX -fno-lto -c $B/sketch.cpp -o /dev/null -fsyntax-only 2>/dev/null || true
avr-g++ $FLAGS -std=gnu++11 -fpermissive -fno-exceptions -fno-threadsafe-statics -Wall -c $B/sketch.cpp -o $B/sketch.o
avr-gcc $FLAGS -Wl,--gc-sections -o $B/sketch.elf $B/sketch.o $B/neo.o $(ls $B/*.c.o $B/*.cpp.o $B/wiring_pulse.S.o) -lm
avr-size -C --mcu=atmega328p $B/sketch.elf
