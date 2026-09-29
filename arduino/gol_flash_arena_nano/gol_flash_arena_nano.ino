/*
  GOL FLASH ARENA - ARDUINO NANO (TV Box Android 7.1)
  ====================================================

  O Nano faz TUDO da maquina: acende os 7 alvos (NeoPixel), le os 7
  sensores e os botoes START e SELECT. A Zero Delay nao e mais usada.
  A TV Box conversa com ele pelo cabo USB (115200 baud).

  PINOS (Arduino Nano ATmega328P)
  -------------------------------
    Alvo   LED (dado do NeoPixel)   Sensor (contato para o GND)
     A          D2                       D9
     B          D3                       D10
     C          D4                       D11
     D          D5                       D12
     E          D6                       A0
     F          D7                       A1
     G          D8                       A2

    START   A3  (botao para o GND)
    SELECT  A4  (botao para o GND)
    CREDITO A5  (opcional: moedeiro/botao para o GND; sem nada ligado, nao faz nada)

    Livres de proposito: D0/D1 (USB), D13 (LED da placa: atrapalha entrada),
    A6/A7 (so leitura analogica no Nano).

  Os LEDs de cada alvo continuam nos mesmos pinos da versao do PC (A = D2
  ate G = D8). Sensores e botoes usam o pull-up interno: e so ligar um
  lado no pino e o outro no GND (sem resistor). Sensor com saida propria
  (infravermelho, piezo com modulo) deve puxar o pino para o GND ao
  detectar.

  PROTOCOLO (uma linha por mensagem, termina em \n)
  -------------------------------------------------
  TV Box -> Nano
    SET:A=255,0,0;C=0,0,255   acende os alvos listados com a cor RGB e
                              APAGA os que nao estao na lista
    C:F00000F00FF0000000000FFF  os 7 alvos de uma vez: 3 digitos hexa por
                              alvo (R, G, B de 0 a F), de A ate G. E o que
                              a TV Box usa (cabe nos 32 caracteres que o
                              plugin USB do Android manda por linha)
    OFF                       apaga tudo
    PING                      responde PONG:GOL_FLASH:1
  Nano -> TV Box
    READY:GOL_FLASH:1         ao ligar
    PONG:GOL_FLASH:1          resposta ao PING
    HIT:A ... HIT:G           sensor do alvo acionado
    BTN:START:1 / BTN:START:0 START apertado / solto
    BTN:SELECT:1 / BTN:SELECT:0
    BTN:CREDIT:1 / BTN:CREDIT:0
    OK:SET / OK:C / OK:OFF    comando aplicado (ja desenhado nos LEDs)
    ERR:<motivo>              linha que nao entendeu

  CONTROLE DE FLUXO: enquanto desenha os LEDs o Nano nao consegue ler a
  serial (o NeoPixel desliga as interrupcoes). Por isso o OK so sai DEPOIS
  de desenhar, e a TV Box so manda o proximo comando de LED depois do OK
  (ou de 150 ms sem resposta). Nenhum byte se perde.

  SEGURANCA: sem nenhuma mensagem da TV Box por 10 s (jogo fechado, cabo
  solto), os LEDs apagam sozinhos.

  Biblioteca: Adafruit NeoPixel (Gerenciador de Bibliotecas da IDE).
*/

#include <Adafruit_NeoPixel.h>

// ---------------------------------------------------------------- ajustes
// LEDs em CADA alvo (fita/anel NeoPixel de cada pino). AJUSTE para o
// numero real: se o alvo tiver MAIS LEDs, os que passarem ficam apagados;
// se tiver menos, os que sobram na conta simplesmente nao existem. Quanto
// menor, mais rapido o desenho (16 LEDs = 0,5 ms por alvo).
#define PIXELS_POR_ALVO   16
#define BRILHO            255   // 0..255 (a cor ja vem certa do jogo)
#define BAUD              115200
#define DEBOUNCE_BOTAO_MS 25
#define DEBOUNCE_SENSOR_MS 2    // sensor e rapido: a bola bate e solta
#define REARME_SENSOR_MS  180   // o mesmo alvo so conta de novo depois disto
#define SILENCIO_APAGA_MS 10000

const uint8_t NUM_ALVOS = 7;
const char LETRAS[NUM_ALVOS] = {'A', 'B', 'C', 'D', 'E', 'F', 'G'};
const uint8_t PINO_LED[NUM_ALVOS]    = {2, 3, 4, 5, 6, 7, 8};
const uint8_t PINO_SENSOR[NUM_ALVOS] = {9, 10, 11, 12, A0, A1, A2};

#define PINO_START  A3
#define PINO_SELECT A4
#define PINO_CREDIT A5

// Um buffer so, reaproveitado para os 7 pinos (setPin): todos os LEDs de um
// alvo tem a mesma cor. 16 LEDs = 48 bytes de RAM.
Adafruit_NeoPixel fita(PIXELS_POR_ALVO, PINO_LED[0], NEO_GRB + NEO_KHZ800);

uint8_t corAlvo[NUM_ALVOS][3];      // cor atual de cada alvo
bool alvoMudou[NUM_ALVOS];           // precisa redesenhar

// --------------------------------------------------------------- entradas
struct Entrada {
  uint8_t pino;
  bool leituraAnterior;   // HIGH = solto (pull-up)
  bool estavel;
  unsigned long mudouEm;
  unsigned long ultimoDisparo;
};

Entrada sensores[NUM_ALVOS];
Entrada botaoStart, botaoSelect, botaoCredit;

// ------------------------------------------------------------------ serial
char linha[96];
uint8_t tamLinha = 0;
bool linhaEstourou = false;
unsigned long ultimaMensagem = 0;
bool apagadoPorSilencio = false;

// Prototipos (a IDE geraria sozinha; declarados aqui para compilar igual
// em qualquer versao da IDE).
void iniciarEntrada(Entrada &e, uint8_t pino);
void lerSensor(uint8_t i);
void lerBotao(Entrada &e, const char *nome);
void pintarAlvo(uint8_t i, uint8_t r, uint8_t g, uint8_t b);
void apagarTudo();
void desenharAlvos();
void animacaoDeLigar();
void lerSerial();
void executar(char *cmd);
bool aplicarSet(char *lista);
bool aplicarCompacto(const char *hexa);
int valorHexa(char c);

void iniciarEntrada(Entrada &e, uint8_t pino) {
  pinMode(pino, INPUT_PULLUP);
  e.pino = pino;
  e.leituraAnterior = digitalRead(pino);
  e.estavel = e.leituraAnterior;
  e.mudouEm = millis();
  e.ultimoDisparo = 0;
}

void setup() {
  for (uint8_t i = 0; i < NUM_ALVOS; i++) {
    pinMode(PINO_LED[i], OUTPUT);
    corAlvo[i][0] = corAlvo[i][1] = corAlvo[i][2] = 0;
    alvoMudou[i] = true;
    iniciarEntrada(sensores[i], PINO_SENSOR[i]);
  }
  iniciarEntrada(botaoStart, PINO_START);
  iniciarEntrada(botaoSelect, PINO_SELECT);
  iniciarEntrada(botaoCredit, PINO_CREDIT);

  fita.begin();
  fita.setBrightness(BRILHO);

  Serial.begin(BAUD);
  animacaoDeLigar();
  apagarTudo();
  desenharAlvos();
  ultimaMensagem = millis();
  Serial.println(F("READY:GOL_FLASH:1"));
}

void loop() {
  lerSerial();
  for (uint8_t i = 0; i < NUM_ALVOS; i++) {
    lerSensor(i);
  }
  lerBotao(botaoStart, "START");
  lerBotao(botaoSelect, "SELECT");
  lerBotao(botaoCredit, "CREDIT");

  if (!apagadoPorSilencio && millis() - ultimaMensagem > SILENCIO_APAGA_MS) {
    apagadoPorSilencio = true;
    apagarTudo();
  }
  desenharAlvos();
}

// --------------------------------------------------------------- sensores
// Um acionamento = o pino ficou no GND por DEBOUNCE_SENSOR_MS. Conta uma
// vez so (na borda) e o mesmo alvo so conta de novo depois de REARME.
void lerSensor(uint8_t i) {
  Entrada &e = sensores[i];
  bool leitura = digitalRead(e.pino);
  unsigned long agora = millis();
  if (leitura != e.leituraAnterior) {
    e.leituraAnterior = leitura;
    e.mudouEm = agora;
  }
  if (leitura != e.estavel && agora - e.mudouEm >= DEBOUNCE_SENSOR_MS) {
    e.estavel = leitura;
    if (e.estavel == LOW && agora - e.ultimoDisparo >= REARME_SENSOR_MS) {
      e.ultimoDisparo = agora;
      Serial.print(F("HIT:"));
      Serial.println(LETRAS[i]);
    }
  }
}

// ----------------------------------------------------------------- botoes
// O jogo precisa do apertado E do solto (segurar START + SELECT abre o
// Mural; segurar SELECT abre o Ranking).
void lerBotao(Entrada &e, const char *nome) {
  bool leitura = digitalRead(e.pino);
  unsigned long agora = millis();
  if (leitura != e.leituraAnterior) {
    e.leituraAnterior = leitura;
    e.mudouEm = agora;
  }
  if (leitura != e.estavel && agora - e.mudouEm >= DEBOUNCE_BOTAO_MS) {
    e.estavel = leitura;
    Serial.print(F("BTN:"));
    Serial.print(nome);
    Serial.println(e.estavel == LOW ? F(":1") : F(":0"));
  }
}

// ------------------------------------------------------------------- LEDs
void pintarAlvo(uint8_t i, uint8_t r, uint8_t g, uint8_t b) {
  if (corAlvo[i][0] != r || corAlvo[i][1] != g || corAlvo[i][2] != b) {
    corAlvo[i][0] = r;
    corAlvo[i][1] = g;
    corAlvo[i][2] = b;
    alvoMudou[i] = true;
  }
}

void apagarTudo() {
  for (uint8_t i = 0; i < NUM_ALVOS; i++) {
    pintarAlvo(i, 0, 0, 0);
  }
}

// So redesenha o alvo que mudou: cada fita leva 30 us por LED e,
// enquanto desenha, o Nano nao le a serial nem os sensores.
void desenharAlvos() {
  for (uint8_t i = 0; i < NUM_ALVOS; i++) {
    if (!alvoMudou[i]) continue;
    alvoMudou[i] = false;
    fita.setPin(PINO_LED[i]);
    fita.fill(fita.Color(corAlvo[i][0], corAlvo[i][1], corAlvo[i][2]));
    fita.show();
  }
}

void animacaoDeLigar() {
  for (uint8_t i = 0; i < NUM_ALVOS; i++) {
    pintarAlvo(i, 0, 90, 255);
    desenharAlvos();
    delay(70);
  }
  delay(250);
}

// ------------------------------------------------------------------ serial
void lerSerial() {
  while (Serial.available() > 0) {
    char c = (char)Serial.read();
    if (c == '\r') continue;
    if (c == '\n') {
      linha[tamLinha] = '\0';
      if (linhaEstourou) {
        Serial.println(F("ERR:LINHA_LONGA"));
      } else if (tamLinha > 0) {
        executar(linha);
      }
      tamLinha = 0;
      linhaEstourou = false;
      continue;
    }
    if (tamLinha < sizeof(linha) - 1) {
      linha[tamLinha++] = (char)toupper(c);
    } else {
      linhaEstourou = true;
    }
  }
}

void executar(char *cmd) {
  ultimaMensagem = millis();
  apagadoPorSilencio = false;

  if (strcmp(cmd, "PING") == 0) {
    Serial.println(F("PONG:GOL_FLASH:1"));
    return;
  }
  if (strcmp(cmd, "OFF") == 0) {
    apagarTudo();
    desenharAlvos();
    Serial.println(F("OK:OFF"));
    return;
  }
  if (strncmp(cmd, "C:", 2) == 0) {
    if (aplicarCompacto(cmd + 2)) {
      desenharAlvos();
      Serial.println(F("OK:C"));
    } else {
      Serial.println(F("ERR:C"));
    }
    return;
  }
  if (strncmp(cmd, "SET:", 4) == 0) {
    if (aplicarSet(cmd + 4)) {
      desenharAlvos();
      Serial.println(F("OK:SET"));
    } else {
      Serial.println(F("ERR:SET"));
    }
    return;
  }
  Serial.print(F("ERR:COMANDO:"));
  Serial.println(cmd);
}

// "A=255,0,0;C=0,0,255" -> A e C acesos, o resto apagado.
bool aplicarSet(char *lista) {
  uint8_t nova[NUM_ALVOS][3];
  for (uint8_t i = 0; i < NUM_ALVOS; i++) {
    nova[i][0] = nova[i][1] = nova[i][2] = 0;
  }
  char *item = strtok(lista, ";");
  while (item != NULL) {
    while (*item == ' ') item++;
    if (*item != '\0') {
      int idx = -1;
      for (uint8_t i = 0; i < NUM_ALVOS; i++) {
        if (item[0] == LETRAS[i]) idx = i;
      }
      int r, g, b;
      if (idx < 0 || item[1] != '=' || sscanf(item + 2, "%d,%d,%d", &r, &g, &b) != 3) {
        return false;
      }
      nova[idx][0] = (uint8_t)constrain(r, 0, 255);
      nova[idx][1] = (uint8_t)constrain(g, 0, 255);
      nova[idx][2] = (uint8_t)constrain(b, 0, 255);
    }
    item = strtok(NULL, ";");
  }
  for (uint8_t i = 0; i < NUM_ALVOS; i++) {
    pintarAlvo(i, nova[i][0], nova[i][1], nova[i][2]);
  }
  return true;
}

// "F00" "0F0" ... (21 digitos): cada canal 0..F vira 0..255 (x17).
int valorHexa(char c) {
  if (c >= '0' && c <= '9') return c - '0';
  if (c >= 'A' && c <= 'F') return c - 'A' + 10;
  return -1;
}

bool aplicarCompacto(const char *hexa) {
  if (strlen(hexa) != NUM_ALVOS * 3) return false;
  uint8_t nova[NUM_ALVOS * 3];
  for (uint8_t k = 0; k < NUM_ALVOS * 3; k++) {
    int v = valorHexa(hexa[k]);
    if (v < 0) return false;
    nova[k] = (uint8_t)(v * 17);
  }
  for (uint8_t i = 0; i < NUM_ALVOS; i++) {
    pintarAlvo(i, nova[i * 3], nova[i * 3 + 1], nova[i * 3 + 2]);
  }
  return true;
}
