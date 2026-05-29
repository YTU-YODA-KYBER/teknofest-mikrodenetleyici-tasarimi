#include "uart.h"

/* UART Register Tanımlamaları (soc.h'taki UART_BASE'e göre) */
#define UART_CPB REG32(UART_BASE + 0x00)
#define UART_STP REG32(UART_BASE + 0x04)
#define UART_RDR REG32(UART_BASE + 0x08)
#define UART_TDR REG32(UART_BASE + 0x0C)
#define UART_CFG REG32(UART_BASE + 0x10)

/* İstenilen Baud Rate */
#define BAUD_RATE 9600

void uart_init(void) {
    /* 1. Baud Rate Ayarı: (Sistem Saati / Baud Rate) -> 48000000 / 9600 = 5000 */
    UART_CPB = SYS_CLK_HZ / BAUD_RATE;

    /* 2. Stop Bit Ayarı: "00" (1 Stop Bit) */
    UART_STP = 0x00;

    /* 3. Konfigürasyon bayraklarını sıfırla (Başlangıç durumu güvenliği için) */
    UART_CFG &= ~(0x07);
}

void uart_send_char(char c) {
    /* 1. Gönderilecek karakteri Transmit Data Register'a yaz */
    UART_TDR = (uint32_t)c;

    /* 2. Gönderimi başlat (UART_CFG[0] = 1)
     * Şartnameye göre donanım işlem bitince bu biti kendisi '0' yapacak. */
    UART_CFG |= (1 << 0);

    /* 3. Donanımın UART_CFG[2] (Transmit Completed) bitini '1' yapmasını bekle */
    while (!(UART_CFG & (1 << 2))) {
        /* Polling - işlem bitene kadar donanımı dinle */
    }

    /* 4. İşlem bitti, şartname gereği Transmit Completed bayrağını yazılımla temizle */
    UART_CFG &= ~(1 << 2);
}

void uart_send_string(const char *str) {
    /* String'in sonu (NULL terminator) gelene kadar karakterleri tek tek gönder */
    while (*str) {
        uart_send_char(*str++);
    }
}
