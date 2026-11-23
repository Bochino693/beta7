// ============================================================================
//  OLHO NO LANCE - ARDUINO DA MAQUINA (Uno ou Nano)
//  arquivo unico: arduino/olho_no_lance/olho_no_lance.ino   firmware OLHO_NO_LANCE:2
//  Lazer & Sport Games
// ============================================================================
//  O QUE ELE FAZ
//   1. Acende os LEDs dos 7 ALVOS (A..G) na cor que o jogo manda.
//   2. Le os 7 SENSORES dos alvos, os botoes START e SELECT e o MOEDEIRO e
//      avisa o jogo pelo mesmo cabo USB. Na TV Box / TV Android isso dispensa
//      a placa Zero Delay: so o cabo USB do Arduino vai na TV.
//
//  LIGACAO (desenho completo: arduino/ligacao_olho_no_lance.pdf)
//    ALVO    fita de LED (DIN)    sensor (contato para o GND)
//     A            D2                    D9
//     B            D3                    D10
//     C            D4                    D11
//     D            D5                    D12
//     E            D6                    A0
//     F            D7                    A1
//     G            D8                    A2
//    START  -> A3     SELECT (COPA) -> A4     MOEDEIRO / NOTEIRO -> A5
//    (botoes, sensores e moedeiro: um fio no pino, o outro no GND)
//
//  CONVERSA COM O JOGO (texto, 9600, uma linha por comando)
//    jogo -> Arduino   PING                    responde PONG:OLHO_NO_LANCE:2
//                      OFF                     apaga tudo
//                      SET:A=255,0,0;C=0,0,255 acende A e C (r,g,b de 0 a
//                                              255) e APAGA os outros alvos
//    Arduino -> jogo   OLA:OLHO_NO_LANCE:2     ao ligar
//                      S:A ... S:G             a bola bateu no alvo
//                      B:START:1 / B:START:0   START apertado / solto
//                      B:SELECT:1 / B:SELECT:0 SELECT apertado / solto
//                      FICHA                   entrou 1 credito
//                      ORDEM:0..5              ordem das cores da fita (guarda)
//                      CFG?                    responde CFG:ORDEM=n;LEDS=m
//  AO LIGAR FICA TUDO APAGADO: so o jogo acende.
//  E o mesmo "SET / OFF" que o jogo sempre usou: funciona igual no PC (COM5)
//  e na TV Box (USB).
//
//  BIBLIOTECA: Adafruit NeoPixel (IDE do Arduino: Ferramentas > Gerenciar
//  bibliotecas > "Adafruit NeoPixel" > Instalar). Placa: Arduino Uno (ou Nano).
// ============================================================================
#include <Adafruit_NeoPixel.h>
#include <EEPROM.h>

// ------------------------------------------------------------------ AJUSTES
#define FIRMWARE "OLHO_NO_LANCE:2"

// Quantos LEDs o Arduino acende em CADA alvo. Ele sempre manda a cor para
// todos esses: com um anel/fita MENOR (8, 16, 24, 60 LEDs) acende inteiro do
// mesmo jeito, sem precisar contar. So aumente se o alvo tiver MAIS de 64
// LEDs e o fim do anel ficar apagado (maximo 150). Nao ponha a mais sem
// precisar: enquanto a fita recebe a cor o Arduino nao escuta o jogo, e com
// 64 LEDs isso dura 2 milesimos de segundo (seguro); com 150, quase 5.
#define LEDS_POR_ALVO 64

// A ORDEM DAS CORES da fita nao precisa mais mexer aqui: se pedir vermelho e
// acender outra cor, entre no jogo em MENU > Central da Maquina e aperte
// "ORDEM DAS CORES DOS LEDS" ate o anel ficar VERMELHO. Fica guardado no
// Arduino. (Comando: ORDEM:0 a ORDEM:5.)  Fita RGBW (4 cores) nao serve.
#define ORDEM_PADRAO 0   // 0 = GRB (WS2812B, a mais comum)

// Brilho (0 a 255). 255 = cor cheia, como o jogo manda.
#define BRILHO_MAX 255

// Sensores, botoes e moedeiro: 0 = contato que FECHA para o GND ao acionar
// (o comum: microchave / sensor NA). 1 = contato que ABRE ao acionar (NF).
#define SENSOR_NF 0
#define BOTAO_NF 0
#define FICHA_NF 0

// Filtros (em milissegundos)
#define SENSOR_FILTRO_MS 2      // o sensor tem que ficar acionado este tempo
#define SENSOR_PAUSA_MS 250     // depois de um gol, o mesmo alvo espera isto
#define BOTAO_FILTRO_MS 25
#define FICHA_FILTRO_MS 15
#define FICHA_PAUSA_MS 120

// 1 = ao ligar, cada alvo pisca vermelho, verde e azul (teste de bancada)
#define TESTE_AO_LIGAR 0

// ------------------------------------------------------------------- PINOS
#define ALVOS 7
const uint8_t PINO_LED[ALVOS]    = {2, 3, 4, 5, 6, 7, 8};        // A..G
const uint8_t PINO_SENSOR[ALVOS] = {9, 10, 11, 12, A0, A1, A2};  // A..G
#define PINO_START A3
#define PINO_SELECT A4
#define PINO_FICHA A5

// ------------------------------------------------------------------- TIPOS
// (fica aqui em cima, antes de qualquer funcao: a IDE do Arduino cria os
// prototipos das funcoes no topo do arquivo e precisa ja conhecer o tipo)
// Entrada com filtro: "acionada" so depois de ficar um tempo firme.
struct Entrada {
  uint8_t pino;
  bool nf;
  bool firme;            // estado aceito
  bool bruto;            // ultima leitura
  unsigned long desde;   // quando a leitura mudou
};

// -------------------------------------------------------------------- LEDS
// Uma fita so na memoria: todos os LEDs de um alvo tem a mesma cor, entao o
// mesmo desenho e mandado para o pino de cada alvo (gasta pouca memoria).
// A fita e criada como "RGB puro" e a ordem das cores e trocada aqui (ordem).
Adafruit_NeoPixel fita(LEDS_POR_ALVO, PINO_LED[0], NEO_RGB + NEO_KHZ800);
uint8_t corAtual[ALVOS][3];   // o que esta aceso
uint8_t corNova[ALVOS][3];    // o que o jogo pediu
uint8_t ordem = ORDEM_PADRAO; // 0 GRB, 1 RGB, 2 BRG, 3 RBG, 4 GBR, 5 BGR
uint8_t proximoReforco = 0;
unsigned long ultimoReforco = 0;
#define EEPROM_MARCA 0x4C     // "L": a ordem foi guardada
#define REFORCO_MS 400        // de tempo em tempo um alvo e reenviado (ver loop)

// r, g, b do jogo -> a ordem de fios desta fita
uint32_t corDaFita(uint8_t r, uint8_t g, uint8_t b) {
  switch (ordem) {
    case 1: return fita.Color(r, g, b);
    case 2: return fita.Color(b, r, g);
    case 3: return fita.Color(r, b, g);
    case 4: return fita.Color(g, b, r);
    case 5: return fita.Color(b, g, r);
    default: return fita.Color(g, r, b);
  }
}

void mostrarAlvo(uint8_t i) {
  uint32_t c = corDaFita(corNova[i][0], corNova[i][1], corNova[i][2]);
  for (uint16_t p = 0; p < LEDS_POR_ALVO; p++) fita.setPixelColor(p, c);
  fita.setPin(PINO_LED[i]);
  fita.show();
  corAtual[i][0] = corNova[i][0];
  corAtual[i][1] = corNova[i][1];
  corAtual[i][2] = corNova[i][2];
}

// So redesenha o alvo que mudou (enquanto a fita recebe, o Arduino nao
// escuta o USB: quanto menos, melhor).
void aplicarLeds() {
  for (uint8_t i = 0; i < ALVOS; i++) {
    if (corAtual[i][0] != corNova[i][0] || corAtual[i][1] != corNova[i][1] || corAtual[i][2] != corNova[i][2]) {
      mostrarAlvo(i);
    }
  }
}

void apagarTudo() {
  for (uint8_t i = 0; i < ALVOS; i++) {
    corNova[i][0] = 0; corNova[i][1] = 0; corNova[i][2] = 0;
  }
}

// Manda de novo a cor de TODOS os alvos (ao ligar e ao trocar a ordem).
void reenviarTudo() {
  for (uint8_t i = 0; i < ALVOS; i++) mostrarAlvo(i);
}

// SO O JOGO ACENDE: a fita de LED liga sozinha com cores soltas quando recebe
// energia (e a fonte dela pode ligar depois do Arduino). Por isso, alem de
// apagar tudo ao ligar, o Arduino reenvia um alvo a cada REFORCO_MS com a
// cor que o jogo pediu por ultimo (apagado, se o jogo nao pediu nada).
void reforcar() {
  unsigned long agora = millis();
  if (agora - ultimoReforco < REFORCO_MS) return;
  ultimoReforco = agora;
  mostrarAlvo(proximoReforco);
  proximoReforco = (proximoReforco + 1) % ALVOS;
}

// ---------------------------------------------------------------- COMANDOS
#define TAM_LINHA 128
char linha[TAM_LINHA];
uint8_t tamLinha = 0;
bool linhaGrande = false;

// "A=255,0,0;B=0,255,0": os alvos da lista acendem, os outros apagam
void comandoSet(const char *p) {
  apagarTudo();
  while (*p) {
    char letra = *p;
    if (letra >= 'a' && letra <= 'g') letra -= 32;
    if (letra < 'A' || letra > 'G' || p[1] != '=') {
      // pedaco que nao entendi: pula ate o proximo ';'
      while (*p && *p != ';') p++;
      if (*p == ';') p++;
      continue;
    }
    p += 2;
    uint8_t alvo = letra - 'A';
    for (uint8_t k = 0; k < 3; k++) {
      uint16_t v = 0;
      while (*p >= '0' && *p <= '9') { v = v * 10 + (*p - '0'); if (v > 255) v = 255; p++; }
      corNova[alvo][k] = (uint8_t)v;
      if (*p == ',') p++;
    }
    while (*p && *p != ';') p++;
    if (*p == ';') p++;
  }
}

void responderCfg() {
  Serial.print(F("CFG:ORDEM="));
  Serial.print((int)ordem);
  Serial.print(F(";LEDS="));
  Serial.println((int)LEDS_POR_ALVO);
}

bool igual(const char *a, const char *b) {
  while (*a && *b) {
    char c = *a;
    if (c >= 'a' && c <= 'z') c -= 32;
    if (c != *b) return false;
    a++; b++;
  }
  return *a == 0 && *b == 0;
}

void executar() {
  if (igual(linha, "PING")) {
    Serial.println(F("PONG:" FIRMWARE));
  } else if (igual(linha, "OFF")) {
    apagarTudo();
    aplicarLeds();
  } else if (igual(linha, "CFG?")) {
    responderCfg();
  } else if ((linha[0] == 'O' || linha[0] == 'o') && linha[5] == ':' && linha[6] >= '0' && linha[6] <= '5' && linha[7] == 0) {
    // ORDEM:n - a ordem das cores desta fita (guardada no Arduino)
    ordem = linha[6] - '0';
    EEPROM.update(0, EEPROM_MARCA);
    EEPROM.update(1, ordem);
    reenviarTudo();
    responderCfg();
  } else if ((linha[0] == 'S' || linha[0] == 's') && (linha[1] == 'E' || linha[1] == 'e') && (linha[2] == 'T' || linha[2] == 't') && linha[3] == ':') {
    comandoSet(linha + 4);
    aplicarLeds();
  }
}

void lerUsb() {
  while (Serial.available() > 0) {
    char c = (char)Serial.read();
    if (c == '\n' || c == '\r') {
      if (tamLinha > 0 && !linhaGrande) {
        linha[tamLinha] = 0;
        executar();
      }
      tamLinha = 0;
      linhaGrande = false;
    } else if (tamLinha < TAM_LINHA - 1) {
      linha[tamLinha++] = c;
    } else {
      linhaGrande = true;   // linha maior que a memoria: joga fora
    }
  }
}

// ----------------------------------------------------------------- ENTRADAS
bool lerAcionada(const Entrada &e) {
  bool fechado = digitalRead(e.pino) == LOW;   // contato no GND
  return e.nf ? !fechado : fechado;
}

// devolve 1 (acionou), -1 (soltou) ou 0 (nada mudou)
int8_t atualizar(Entrada &e, unsigned long agora, unsigned int filtro) {
  bool a = lerAcionada(e);
  if (a != e.bruto) {
    e.bruto = a;
    e.desde = agora;
  }
  if (e.bruto != e.firme && agora - e.desde >= filtro) {
    e.firme = e.bruto;
    return e.firme ? 1 : -1;
  }
  return 0;
}

Entrada sensores[ALVOS];
unsigned long sensorPausa[ALVOS];
bool sensorJaBateu[ALVOS];
Entrada botaoStart = {PINO_START, BOTAO_NF != 0, false, false, 0};
Entrada botaoSelect = {PINO_SELECT, BOTAO_NF != 0, false, false, 0};
Entrada ficha = {PINO_FICHA, FICHA_NF != 0, false, false, 0};
unsigned long fichaPausa = 0;
bool fichaJaEntrou = false;

void lerEntradas() {
  unsigned long agora = millis();
  for (uint8_t i = 0; i < ALVOS; i++) {
    if (atualizar(sensores[i], agora, SENSOR_FILTRO_MS) == 1 && (!sensorJaBateu[i] || agora - sensorPausa[i] >= SENSOR_PAUSA_MS)) {
      sensorJaBateu[i] = true;
      sensorPausa[i] = agora;
      Serial.print(F("S:"));
      Serial.println((char)('A' + i));
    }
  }
  int8_t m = atualizar(botaoStart, agora, BOTAO_FILTRO_MS);
  if (m == 1) Serial.println(F("B:START:1"));
  if (m == -1) Serial.println(F("B:START:0"));
  m = atualizar(botaoSelect, agora, BOTAO_FILTRO_MS);
  if (m == 1) Serial.println(F("B:SELECT:1"));
  if (m == -1) Serial.println(F("B:SELECT:0"));
  if (atualizar(ficha, agora, FICHA_FILTRO_MS) == 1 && (!fichaJaEntrou || agora - fichaPausa >= FICHA_PAUSA_MS)) {
    fichaJaEntrou = true;
    fichaPausa = agora;
    Serial.println(F("FICHA"));
  }
}

// ------------------------------------------------------------------- INICIO
void setup() {
  Serial.begin(9600);
  for (uint8_t i = 0; i < ALVOS; i++) {
    pinMode(PINO_SENSOR[i], INPUT_PULLUP);
    sensores[i].pino = PINO_SENSOR[i];
    sensores[i].nf = SENSOR_NF != 0;
    sensores[i].desde = 0;
    // comeca no estado em que esta: ligar com um sensor acionado nao marca gol
    sensores[i].bruto = lerAcionada(sensores[i]);
    sensores[i].firme = sensores[i].bruto;
    sensorPausa[i] = 0;
    sensorJaBateu[i] = false;
    pinMode(PINO_LED[i], OUTPUT);
    digitalWrite(PINO_LED[i], LOW);
  }
  pinMode(PINO_START, INPUT_PULLUP);
  pinMode(PINO_SELECT, INPUT_PULLUP);
  pinMode(PINO_FICHA, INPUT_PULLUP);
  botaoStart.bruto = botaoStart.firme = lerAcionada(botaoStart);
  botaoSelect.bruto = botaoSelect.firme = lerAcionada(botaoSelect);
  ficha.bruto = ficha.firme = lerAcionada(ficha);

  if (EEPROM.read(0) == EEPROM_MARCA && EEPROM.read(1) <= 5) ordem = EEPROM.read(1);
  fita.begin();
  fita.setBrightness(BRILHO_MAX);
  // AO LIGAR, TUDO APAGADO: duas passadas (a fita pode estar acordando)
  apagarTudo();
  reenviarTudo();
  delay(30);
  reenviarTudo();
#if TESTE_AO_LIGAR
  for (uint8_t k = 0; k < 3; k++) {
    for (uint8_t i = 0; i < ALVOS; i++) {
      apagarTudo();
      corNova[i][k] = 255;
      aplicarLeds();
      delay(120);
    }
  }
  apagarTudo();
  aplicarLeds();
#endif
  Serial.println(F("OLA:" FIRMWARE));
}

void loop() {
  lerUsb();
  lerEntradas();
  // (so reforca com o USB quieto: nunca no meio de um comando chegando)
  if (tamLinha == 0 && Serial.available() == 0) reforcar();
}
