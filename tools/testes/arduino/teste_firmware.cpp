// Simula o firmware do Gol Flash Arena no PC (testar_firmware.sh)
#include "Arduino.h"
unsigned long t_ms = 0;
int pinLevel[32], pinOut[32], pinModeV[32], pinPwm[32];
volatile uint8_t TCCR1A, TCCR1B;
volatile uint16_t ICR1, OCR1A;
SerialMock Serial;
uint32_t fitaCor[32];
int fitaShows = 0;
#include ARQUIVO_FW

static int falhas = 0;
#define CONFERE(c, msg) do { if (!(c)) { printf("  FALHOU (t=%lu): %s\n", t_ms, msg); falhas++; } } while (0)
std::string saida;
void rodar(unsigned long ms) { for (unsigned long i = 0; i < ms; i++) { loop(); t_ms++; } saida += Serial.out; Serial.out.clear(); }
void manda(const char *c) { for (const char *p = c; *p; p++) Serial.in.push_back(*p); Serial.in.push_back('\n'); }
int conta(const std::string &s) { int n = 0; size_t p = 0; while ((p = saida.find(s, p)) != std::string::npos) { n++; p += s.size(); } return n; }
uint32_t cor(char alvo) { return fitaCor[PINO_LED[alvo - 'A']]; }

int main() {
  for (int i = 0; i < 32; i++) pinLevel[i] = HIGH;
  // em repouso: contato NA aberto (HIGH pelo pull-up); NF fechado no GND (LOW)
  for (int i = 0; i < ALVOS; i++) pinLevel[PINO_SENSOR[i]] = SENSOR_NF ? LOW : HIGH;
  pinLevel[PINO_FICHA] = FICHA_NF ? LOW : HIGH;
  pinLevel[PINO_SENSOR[2]] = SENSOR_NF ? HIGH : LOW;   // liga com o sensor C acionado
  setup(); rodar(50);
  CONFERE(conta("OLA:GOL_FLASH:1") == 1, "OLA ao ligar");
  CONFERE(conta("S:") == 0, "sensor acionado ao ligar nao marca gol");
  pinLevel[PINO_SENSOR[2]] = SENSOR_NF ? LOW : HIGH; rodar(50);
  for (int i = 0; i < ALVOS; i++) CONFERE(pinModeV[PINO_SENSOR[i]] == INPUT_PULLUP, "sensor com pull-up");

  manda("PING"); rodar(5);
  CONFERE(conta("PONG:GOL_FLASH:1") == 1, "PONG");

  manda("SET:A=0,0,255"); rodar(5);
  CONFERE(cor('A') == 0x0000FF, "A azul");
  manda("SET:B=255,0,0"); rodar(5);
  CONFERE(cor('B') == 0xFF0000 && cor('A') == 0, "B vermelho e A apagou");
  int antes = fitaShows;
  manda("SET:B=255,0,0"); rodar(5);
  CONFERE(fitaShows == antes, "mesmo comando nao redesenha");
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
