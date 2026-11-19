// Fita de LED de mentira: guarda a cor que cada pino recebeu no ultimo show()
#pragma once
#define NEO_GRB 0x52
#define NEO_RGB 0x06
#define NEO_BRG 0x58
#define NEO_KHZ800 0x0000
extern uint32_t fitaCor[32];
extern int fitaShows;
struct Adafruit_NeoPixel {
  int pino; uint32_t cor = 0;
  Adafruit_NeoPixel(uint16_t, int16_t p, int) : pino(p) {}
  void begin() {}
  void show() { fitaCor[pino] = cor; fitaShows++; }
  void clear() { cor = 0; }
  void setPin(int16_t p) { pino = p; }
  void setBrightness(uint8_t) {}
  void setPixelColor(uint16_t, uint32_t c) { cor = c; }
  static uint32_t Color(uint8_t r, uint8_t g, uint8_t b) { return ((uint32_t)r << 16) | ((uint32_t)g << 8) | b; }
};
