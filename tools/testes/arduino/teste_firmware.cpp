// Simula o firmware do Olho no Lance no PC (testar_firmware.sh)
#include "Arduino.h"
unsigned long t_ms = 0;
int pinLevel[32], pinOut[32], pinModeV[32], pinPwm[32];
volatile uint8_t TCCR1A, TCCR1B;
volatile uint16_t ICR1, OCR1A;
SerialMock Serial;
#include "EEPROM.h"
EEPROMMock EEPROM;
uint32_t fitaCor[32];
int fitaShows = 0;
#include ARQUIVO_FW

static int falhas = 0;
#define CONFERE(c, msg) do { if (!(c)) { printf("  FALHOU (t=%lu): %s\n", t_ms, msg); falhas++; } } while (0)
std::string saida;
void rodar(unsigned long ms) { for (unsigned long i = 0; i < ms; i++) { loop(); t_ms++; } saida += Serial.out; Serial.out.clear(); }
void manda(const char *c) { for (const char *p = c; *p; p++) Serial.in.push_back(*p); Serial.in.push_back('\n'); }
int conta(const std::string &s) { int n = 0; size_t p = 0; while ((p = saida.find(s, p)) != std::string::npos) { n++; p += s.size(); } return n; }
// o que chegou nos fios da fita, de volta para r,g,b do jogo (ordem 0 = GRB)
uint32_t fios(char alvo) { return fitaCor[PINO_LED[alvo - 'A']]; }
uint32_t cor(char alvo) { uint32_t f = fios(alvo); return ((f >> 8 & 255) << 16) | ((f >> 16 & 255) << 8) | (f & 255); }

int main() {
  for (int i = 0; i < 32; i++) pinLevel[i] = HIGH;
  // em repouso: contato NA aberto (HIGH pelo pull-up); NF fechado no GND (LOW)
  for (int i = 0; i < ALVOS; i++) pinLevel[PINO_SENSOR[i]] = SENSOR_NF ? LOW : HIGH;
  pinLevel[PINO_FICHA] = FICHA_NF ? LOW : HIGH;
  pinLevel[PINO_SENSOR[2]] = SENSOR_NF ? HIGH : LOW;   // liga com o sensor C acionado
  setup(); rodar(50);
  CONFERE(conta("OLA:GOL_FLASH:2") == 1, "OLA ao ligar");
  CONFERE(conta("S:") == 0, "sensor acionado ao ligar nao marca gol");
  pinLevel[PINO_SENSOR[2]] = SENSOR_NF ? LOW : HIGH; rodar(50);
  for (int i = 0; i < ALVOS; i++) CONFERE(pinModeV[PINO_SENSOR[i]] == INPUT_PULLUP, "sensor com pull-up");

  for (char a = 'A'; a <= 'G'; a++) CONFERE(fios(a) == 0, "ao ligar, tudo apagado");
  CONFERE(fitaShows >= 14, "ao ligar, cada alvo recebe apagado duas vezes");
  // a fita "acordou" com cores soltas (a fonte ligou depois): o reforco apaga sozinho
  for (int i = 0; i < ALVOS; i++) fitaCor[PINO_LED[i]] = 0x123456;
  rodar(REFORCO_MS * ALVOS + 50);
  for (char a = 'A'; a <= 'G'; a++) CONFERE(fios(a) == 0, "fita que acende sozinha e apagada pelo reforco");
  manda("SET:A=10,20,30"); rodar(5);
  fitaCor[PINO_LED[0]] = 0; rodar(REFORCO_MS * ALVOS + 50);
  CONFERE(cor('A') == 0x0A141E, "o reforco reenvia a cor que o jogo pediu");
  manda("OFF"); rodar(5);

  manda("PING"); rodar(5);
  CONFERE(conta("PONG:GOL_FLASH:2") == 1, "PONG");

  manda("SET:A=0,0,255"); rodar(5);
  CONFERE(cor('A') == 0x0000FF, "A azul");
  manda("SET:B=255,0,0"); rodar(5);
  CONFERE(cor('B') == 0xFF0000 && cor('A') == 0, "B vermelho e A apagou");
  int antes = fitaShows;
  manda("SET:B=255,0,0"); rodar(5);
  CONFERE(fitaShows - antes <= 1, "mesmo comando nao redesenha (so o reforco)");
  // ordem das cores: vermelho do jogo tem que sair no fio certo de cada tipo de fita
  manda("CFG?"); rodar(5);
  CONFERE(conta("CFG:ORDEM=0;LEDS=64") == 1, "CFG? responde a ordem e os LEDs");
  manda("ORDEM:1"); rodar(5);
  CONFERE(fios('B') == 0xFF0000 && conta("CFG:ORDEM=1") == 1, "ORDEM:1 (RGB): vermelho no 1o fio, na hora");
  manda("ORDEM:5"); rodar(5);
  CONFERE(fios('B') == 0x0000FF, "ORDEM:5 (BGR): vermelho no 3o fio");
  CONFERE(EEPROM.read(0) == EEPROM_MARCA && EEPROM.read(1) == 5, "a ordem fica guardada no Arduino");
  manda("ORDEM:0"); rodar(5);
  CONFERE(fios('B') == 0x00FF00, "ORDEM:0 (GRB): vermelho no 2o fio");
  manda("SET:A=255,255,255;B=255,255,255;C=255,255,255;D=255,255,255;E=255,255,255;F=255,255,255;G=255,255,255"); rodar(5);
  for (char a = 'A'; a <= 'G'; a++) CONFERE(cor(a) == 0xFFFFFF, "todos brancos (comando mais comprido do jogo)");
  manda("set:c=0,255,0;x=1,2,3;g=300,5,5"); rodar(5);
  CONFERE(cor('C') == 0x00FF00 && cor('G') == 0xFF0505 && cor('A') == 0, "minusculas, lixo no meio e valor acima de 255");
  manda("OFF"); rodar(5);
  for (char a = 'A'; a <= 'G'; a++) CONFERE(cor(a) == 0, "OFF apaga tudo");
  std::string grande(300, 'Z'); manda(grande.c_str()); manda("SET:D=1,2,3"); rodar(5);
  CONFERE(cor('D') == 0x010203, "linha gigante e descartada e a seguinte vale");
  saida.clear();

  // sensores: cada um manda a letra certa, uma vez
  for (int i = 0; i < ALVOS; i++) {
    pinLevel[PINO_SENSOR[i]] = SENSOR_NF ? HIGH : LOW; rodar(40);
    pinLevel[PINO_SENSOR[i]] = SENSOR_NF ? LOW : HIGH; rodar(400);
    std::string e = std::string("S:") + (char)('A' + i) + "\n";
    CONFERE(conta(e) == 1 && conta("S:") == 1, "sensor manda a letra dele uma vez");
    saida.clear();
  }
  // ruido de 1 ms nao e gol; repique logo depois do gol nao conta dobrado
  pinLevel[PINO_SENSOR[0]] = SENSOR_NF ? HIGH : LOW; rodar(1);
  pinLevel[PINO_SENSOR[0]] = SENSOR_NF ? LOW : HIGH; rodar(50);
  CONFERE(conta("S:") == 0, "ruido curto nao e gol");
  for (int k = 0; k < 4; k++) {
    pinLevel[PINO_SENSOR[0]] = SENSOR_NF ? HIGH : LOW; rodar(10);
    pinLevel[PINO_SENSOR[0]] = SENSOR_NF ? LOW : HIGH; rodar(10);
  }
  CONFERE(conta("S:A") == 1, "repique conta um gol so");
  rodar(400); saida.clear();

  // botoes: aperta e solta (segurar = um aviso so)
  pinLevel[PINO_START] = LOW; rodar(1000);
  CONFERE(conta("B:START:1") == 1 && conta("B:START:0") == 0, "START apertado");
  pinLevel[PINO_SELECT] = LOW; rodar(100);
  CONFERE(conta("B:SELECT:1") == 1, "SELECT junto com o START");
  pinLevel[PINO_START] = HIGH; pinLevel[PINO_SELECT] = HIGH; rodar(100);
  CONFERE(conta("B:START:0") == 1 && conta("B:SELECT:0") == 1, "soltou os dois");
  saida.clear();

  // moedeiro: 3 pulsos de 50 ms = 3 creditos
  for (int k = 0; k < 3; k++) {
    pinLevel[PINO_FICHA] = FICHA_NF ? HIGH : LOW; rodar(50);
    pinLevel[PINO_FICHA] = FICHA_NF ? LOW : HIGH; rodar(150);
  }
  CONFERE(conta("FICHA") == 3, "3 pulsos = 3 fichas");

  printf(falhas ? "FIRMWARE COM ERRO (%d)\n" : "FIRMWARE OK\n", falhas);
  return falhas ? 1 : 0;
}
