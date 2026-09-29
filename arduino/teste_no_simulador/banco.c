// Banco de testes do firmware do Nano no simavr (ATmega328P 16 MHz).
// Serial de verdade (UART0), pinos de entrada acionados como sensores/botoes
// e o sinal WS2812 dos pinos dos LEDs decodificado bit a bit.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <simavr/sim_avr.h>
#include <simavr/sim_elf.h>
#include <simavr/sim_time.h>
#include <simavr/avr_uart.h>
#include <simavr/avr_ioport.h>

static avr_t *avr;
static char saida[65536];
static int nsaida = 0;

// ---- serial: o que o Nano escreve
static void uart_saida(struct avr_irq_t *irq, uint32_t valor, void *p) {
    if (nsaida < (int)sizeof(saida) - 1) saida[nsaida++] = (char)valor;
    saida[nsaida] = 0;
}

// ---- serial: o que a TV Box manda (um byte a cada ~87 us = 115200 baud)
static char fila[4096];
static int fila_ini = 0, fila_fim = 0;
static avr_irq_t *uart_entrada;
static avr_cycle_count_t enviar_byte(avr_t *a, avr_cycle_count_t quando, void *p) {
    if (fila_ini < fila_fim) {
        avr_raise_irq(uart_entrada, (uint8_t)fila[fila_ini++]);
    }
    return quando + 1389;  // 16e6 / 11520 bytes/s
}
static void mandar(const char *s) {
    int n = strlen(s);
    memcpy(fila + fila_fim, s, n);
    fila_fim += n;
}

// ---- WS2812: guarda as mudancas de cada pino de LED
typedef struct { avr_cycle_count_t t; int nivel; } Borda;
#define MAXB 200000
typedef struct { Borda b[MAXB]; int n; } Pino;
static Pino pinos[7];
static void mudou_pino(struct avr_irq_t *irq, uint32_t valor, void *p) {
    Pino *pn = (Pino *)p;
    if (pn->n < MAXB) { pn->b[pn->n].t = avr->cycle; pn->b[pn->n].nivel = valor; pn->n++; }
}
// Decodifica o ULTIMO quadro enviado no pino: pulsos altos longos = 1.
static int ultimo_quadro(int alvo, uint8_t *bytes, int max) {
    Pino *pn = &pinos[alvo];
    // acha o comeco do ultimo quadro: um intervalo baixo > 50 us antes dele
    int fim = pn->n;
    int ini = -1;
    for (int i = fim - 1; i > 0; i--) {
        if (pn->b[i].nivel == 1 && pn->b[i - 1].nivel == 0 &&
            pn->b[i].t - pn->b[i - 1].t > 800) { ini = i; break; }
    }
    if (ini < 0) {
        for (int i = 0; i < fim; i++) if (pn->b[i].nivel == 1) { ini = i; break; }
    }
    if (ini < 0) return 0;
    int nbits = 0;
    for (int i = ini; i + 1 < fim; i++) {
        if (pn->b[i].nivel == 1 && pn->b[i + 1].nivel == 0) {
            avr_cycle_count_t alto = pn->b[i + 1].t - pn->b[i].t;  // ciclos
            int bit = alto > 10;  // 0: ~0,4 us (6 ciclos); 1: ~0,8 us (13 ciclos)
            if (nbits / 8 >= max) break;
            if (nbits % 8 == 0) bytes[nbits / 8] = 0;
            bytes[nbits / 8] = (bytes[nbits / 8] << 1) | bit;
            nbits++;
        }
    }
    return nbits / 8;
}

static void rodar_ms(double ms) {
    avr_cycle_count_t alvo = avr->cycle + (avr_cycle_count_t)(ms * 16000.0);
    while (avr->cycle < alvo) {
        int st = avr_run(avr);
        if (st == cpu_Done || st == cpu_Crashed) { printf("CPU PAROU (%d)\n", st); exit(2); }
    }
}

static avr_irq_t *pino_entrada(char porta, int bit) {
    return avr_io_getirq(avr, AVR_IOCTL_IOPORT_GETIRQ(porta), bit);
}

static int falhas = 0;
static void confere(int ok, const char *o_que) {
    printf("%s  %s\n", ok ? "OK   " : "FALHA", o_que);
    if (!ok) falhas++;
}
static int saida_tem(const char *s) { return strstr(saida, s) != NULL; }
static int conta(const char *s) {
    int n = 0; const char *p = saida;
    while ((p = strstr(p, s))) { n++; p += strlen(s); }
    return n;
}
static void limpa_saida(void) { nsaida = 0; saida[0] = 0; }

static void confere_cor(int alvo, int r, int g, int b, int pixels, const char *nome) {
    uint8_t bytes[600];
    int n = ultimo_quadro(alvo, bytes, sizeof(bytes));
    int ok = n >= pixels * 3;
    for (int i = 0; ok && i < pixels; i++) {
        // NeoPixel: ordem G, R, B
        if (bytes[i * 3] != g || bytes[i * 3 + 1] != r || bytes[i * 3 + 2] != b) ok = 0;
    }
    char msg[200];
    snprintf(msg, sizeof msg, "%s: alvo %c = (%d,%d,%d) em %d LEDs [lidos %d bytes, 1o LED G=%d R=%d B=%d]",
             nome, 'A' + alvo, r, g, b, pixels, n, n ? bytes[0] : -1, n > 1 ? bytes[1] : -1, n > 2 ? bytes[2] : -1);
    confere(ok, msg);
}

int main(int argc, char **argv) {
    elf_firmware_t fw = {0};
    if (elf_read_firmware(argv[1], &fw) != 0) { printf("sem firmware\n"); return 1; }
    avr = avr_make_mcu_by_name("atmega328p");
    avr_init(avr);
    avr->frequency = 16000000;
    avr_load_firmware(avr, &fw);

    uint32_t f = 0;
    avr_ioctl(avr, AVR_IOCTL_UART_GET_FLAGS('0'), &f);
    f &= ~AVR_UART_FLAG_STDIO;
    avr_ioctl(avr, AVR_IOCTL_UART_SET_FLAGS('0'), &f);
    avr_irq_register_notify(avr_io_getirq(avr, AVR_IOCTL_UART_GETIRQ('0'), UART_IRQ_OUTPUT), uart_saida, NULL);
    uart_entrada = avr_io_getirq(avr, AVR_IOCTL_UART_GETIRQ('0'), UART_IRQ_INPUT);
    avr_cycle_timer_register(avr, 1389, enviar_byte, NULL);

    // LEDs: D2..D7 = PD2..PD7, D8 = PB0
    for (int i = 0; i < 6; i++)
        avr_irq_register_notify(pino_entrada('D', 2 + i), mudou_pino, &pinos[i]);
    avr_irq_register_notify(pino_entrada('B', 0), mudou_pino, &pinos[6]);

    // Entradas soltas (nivel alto) antes de ligar.
    int sensorPorta[7] = {'B', 'B', 'B', 'B', 'C', 'C', 'C'};
    int sensorBit[7] = {1, 2, 3, 4, 0, 1, 2};
    for (int i = 0; i < 7; i++) avr_raise_irq(pino_entrada(sensorPorta[i], sensorBit[i]), 1);
    for (int b = 3; b <= 5; b++) avr_raise_irq(pino_entrada('C', b), 1);

    rodar_ms(1500);
    confere(saida_tem("READY:GOL_FLASH:1"), "ao ligar manda READY:GOL_FLASH:1");
    confere_cor(0, 0, 0, 0, 16, "depois da animacao de ligar");

    limpa_saida();
    mandar("PING\n");
    rodar_ms(20);
    confere(saida_tem("PONG:GOL_FLASH:1"), "PING -> PONG:GOL_FLASH:1");

    limpa_saida();
    mandar("SET:A=255,0,0;C=0,0,255;G=255,255,0\n");
    rodar_ms(30);
    confere(saida_tem("OK:SET"), "SET responde OK:SET");
    confere_cor(0, 255, 0, 0, 16, "SET");
    confere_cor(2, 0, 0, 255, 16, "SET");
    confere_cor(6, 255, 255, 0, 16, "SET");

    limpa_saida();
    mandar("SET:B=0,255,0\n");
    rodar_ms(30);
    confere_cor(1, 0, 255, 0, 16, "SET so com B");
    confere_cor(0, 0, 0, 0, 16, "SET so com B apaga o A");
    confere_cor(2, 0, 0, 0, 16, "SET so com B apaga o C");

    // minusculas e espacos (o jogo manda sempre maiusculo, mas nao custa)
    limpa_saida();
    mandar("set:d=10,20,30\r\n");
    rodar_ms(30);
    confere(saida_tem("OK:SET"), "set minusculo com \\r\\n aceito");
    confere_cor(3, 10, 20, 30, 16, "set minusculo");

    // sensores
    for (int i = 0; i < 7; i++) {
        limpa_saida();
        avr_raise_irq(pino_entrada(sensorPorta[i], sensorBit[i]), 0);
        rodar_ms(8);
        avr_raise_irq(pino_entrada(sensorPorta[i], sensorBit[i]), 1);
        rodar_ms(250);
        char esperado[16];
        snprintf(esperado, sizeof esperado, "HIT:%c", 'A' + i);
        char msg[80];
        snprintf(msg, sizeof msg, "sensor %c (pino %c%d) -> %s uma vez", 'A' + i, sensorPorta[i], sensorBit[i], esperado);
        confere(conta(esperado) == 1 && conta("HIT:") == 1, msg);
    }

    // pulso bem curto (3 ms) conta
    limpa_saida();
    avr_raise_irq(pino_entrada('B', 1), 0); rodar_ms(3); avr_raise_irq(pino_entrada('B', 1), 1);
    rodar_ms(250);
    confere(conta("HIT:A") == 1, "pulso de 3 ms no sensor A conta");

    // repique: tres batidas em 60 ms contam uma vez so
    limpa_saida();
    for (int k = 0; k < 3; k++) {
        avr_raise_irq(pino_entrada('B', 2), 0); rodar_ms(5); avr_raise_irq(pino_entrada('B', 2), 1); rodar_ms(15);
    }
    rodar_ms(250);
    confere(conta("HIT:B") == 1, "repique (3 batidas em 60 ms) conta uma vez");

    // ruido de 1 ms nao conta
    limpa_saida();
    avr_raise_irq(pino_entrada('B', 3), 0); rodar_ms(1); avr_raise_irq(pino_entrada('B', 3), 1);
    rodar_ms(250);
    confere(conta("HIT:") == 0, "pico de ruido de 1 ms nao conta");

    // botoes
    const char *nomes[3] = {"START", "SELECT", "CREDIT"};
    for (int b = 0; b < 3; b++) {
        limpa_saida();
        avr_raise_irq(pino_entrada('C', 3 + b), 0);
        rodar_ms(100);
        char aperta[32], solta[32], msg[200];
        snprintf(aperta, sizeof aperta, "BTN:%s:1", nomes[b]);
        snprintf(solta, sizeof solta, "BTN:%s:0", nomes[b]);
        int apertou = conta(aperta) == 1;
        avr_raise_irq(pino_entrada('C', 3 + b), 1);
        rodar_ms(100);
        snprintf(msg, sizeof msg, "%s (pino C%d): %s ao apertar e %s ao soltar", nomes[b], 3 + b, aperta, solta);
        confere(apertou && conta(solta) == 1, msg);
    }

    // START + SELECT juntos (combo do Mural)
    limpa_saida();
    avr_raise_irq(pino_entrada('C', 3), 0);
    rodar_ms(40);
    avr_raise_irq(pino_entrada('C', 4), 0);
    rodar_ms(3000);
    confere(saida_tem("BTN:START:1") && saida_tem("BTN:SELECT:1") && !saida_tem(":0"),
            "START + SELECT segurados juntos 3 s: os dois apertados, nenhum solto");
    avr_raise_irq(pino_entrada('C', 3), 1);
    avr_raise_irq(pino_entrada('C', 4), 1);
    rodar_ms(100);

    // sensor durante um SET longo (LEDs desenhando)
    limpa_saida();
    mandar("SET:A=1,2,3;B=4,5,6;C=7,8,9;D=10,11,12;E=13,14,15;F=16,17,18;G=19,20,21\n");
    rodar_ms(30);
    confere(saida_tem("OK:SET"), "SET com os 7 alvos");
    confere_cor(4, 13, 14, 15, 16, "SET 7 alvos");
    confere_cor(6, 19, 20, 21, 16, "SET 7 alvos");

    // comando compacto C: (o que a TV Box usa)
    limpa_saida();
    mandar("C:F00000F00F00000000FFF\n");
    rodar_ms(30);
    confere(saida_tem("OK:C"), "C: responde OK:C");
    confere_cor(0, 255, 0, 0, 16, "C:");
    confere_cor(1, 0, 0, 0, 16, "C:");
    confere_cor(2, 255, 0, 0, 16, "C:");
    confere_cor(3, 255, 0, 0, 16, "C:");
    confere_cor(6, 255, 255, 255, 16, "C:");
    limpa_saida();
    mandar("c:0000000000000000000000\n");
    rodar_ms(30);
    confere(saida_tem("ERR:C"), "C: com 22 digitos -> ERR:C");
    confere_cor(6, 255, 255, 255, 16, "C: errado nao mexe");
    limpa_saida();
    mandar("c:08f000000000000000000\n");
    rodar_ms(30);
    confere(saida_tem("OK:C"), "c: minusculo aceito");
    confere_cor(0, 0, 136, 255, 16, "c: meio-tom (8 -> 136)");
    confere_cor(6, 0, 0, 0, 16, "c: apaga G");

    limpa_saida();
    mandar("XYZ\n");
    rodar_ms(20);
    confere(saida_tem("ERR:COMANDO:XYZ"), "comando desconhecido -> ERR:COMANDO:XYZ");

    limpa_saida();
    mandar("SET:A=1,2\n");
    rodar_ms(20);
    confere(saida_tem("ERR:SET"), "SET mal formado -> ERR:SET");
    confere_cor(0, 0, 136, 255, 16, "SET mal formado nao mexe nos LEDs");

    limpa_saida();
    mandar("OFF\n");
    rodar_ms(30);
    confere(saida_tem("OK:OFF"), "OFF responde OK:OFF");
    int apagou = 1;
    for (int i = 0; i < 7; i++) {
        uint8_t bytes[64];
        int n = ultimo_quadro(i, bytes, 48);
        for (int k = 0; k < n; k++) if (bytes[k]) apagou = 0;
    }
    confere(apagou, "OFF apaga os 7 alvos");

    // silencio: 10 s sem mensagem apaga
    mandar("SET:E=255,255,255\n");
    rodar_ms(30);
    confere_cor(4, 255, 255, 255, 16, "antes do silencio");
    rodar_ms(9000);
    confere_cor(4, 255, 255, 255, 16, "9 s sem mensagem: ainda aceso");
    rodar_ms(1500);
    confere_cor(4, 0, 0, 0, 16, "10,5 s sem mensagem: apagou sozinho");

    printf("\n%s: %d falha(s)\n", falhas ? "RESULTADO COM FALHAS" : "TUDO CERTO", falhas);
    return falhas ? 1 : 0;
}
