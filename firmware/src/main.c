#include "soc.h"

/* ---------------------------------------------------------
 *  Kaba gecikme (busy-wait).
 *  1 byte @115200 ~= 417 cycle @48MHz. Bol pay icin 4000.
 * --------------------------------------------------------- */
static void delay_cycles(volatile uint32_t n)
{
    while (n--) { /* nop */ }
}

/* ---------------------------------------------------------
 *  UART baslat: baud boleni + stop bit
 * --------------------------------------------------------- */
static void uart_init(void)
{
    UART_CPB = UART_CPB_VALUE;   /* 48e6 / 115200 ~= 416 */
    UART_STP = 1;                /* 1 stop bit */
}

/* ---------------------------------------------------------
 *  ASAMA 1 - BLIND gonderim (TX_DONE bit'ine bagimli DEGIL)
 *  UART RTL'inin TX_DONE bit'i dogru calismasa bile TX
 *  hattini gozlemleyebilmek icin sabit gecikme kullanir.
 *  ILK TEST icin bunu kullan.
 * --------------------------------------------------------- */
static void uart_send_byte_blind(uint8_t c)
{
    UART_TDR = c;
    UART_CFG = UART_CFG_TX_START;
    delay_cycles(4000);          /* 1 byte iletimi rahatca biter */
}

/* ---------------------------------------------------------
 *  ASAMA 2 - POLLING gonderim (dogru/verimli yontem)
 *  Asama 1 calistiktan SONRA buna gec.
 * --------------------------------------------------------- */
static void uart_send_byte_poll(uint8_t c)
{
    UART_TDR = c;
    UART_CFG = UART_CFG_TX_START;
    while (!(UART_CFG & UART_CFG_TX_DONE)) { /* bekle */ }
}

/* Aktif gonderim fonksiyonu - ilk testte blind */
#define uart_send_byte  uart_send_byte_blind
/* Asama 2'ye gecince yukariyi yorum yapip sunu ac:        */
/* #define uart_send_byte  uart_send_byte_poll             */

static void uart_send_string(const char *s)
{
    while (*s) {
        uart_send_byte((uint8_t)*s++);
    }
}

int main(void)
{
    uart_init();

    uart_send_string("CV32E40P SoC - TEKNOFEST 2026\r\n");
    uart_send_string("UART calisiyor!\r\n");

    /* Decoder/osiloskop testi: surekli 'A' bas */
    while (1) {
        uart_send_byte('A');
    }

    return 0;
}
