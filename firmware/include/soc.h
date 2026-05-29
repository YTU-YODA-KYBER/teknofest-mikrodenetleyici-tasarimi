#ifndef SOC_H
#define SOC_H

#include <stdint.h>
#include <stddef.h>

/* =========================================================
 *  volatile 32-bit register erisim makrosu
 * ========================================================= */
#define REG32(addr)  (*((volatile uint32_t *)(addr)))

/* =========================================================
 *  Sistem saati
 * ========================================================= */
#define SYS_CLK_HZ   48000000UL

/* =========================================================
 *  Peripheral base adresleri (interconnect adres map'i)
 * ========================================================= */
#define TIMER_BASE   0x40000000UL
#define GPIO_BASE    0x40010000UL
#define I2C_BASE     0x40020000UL
#define QSPI_BASE    0x40030000UL
#define UART_BASE    0x40040000UL

#define BOOTROM_BASE 0x00000000UL
#define DATARAM_BASE 0x20000000UL

/* =========================================================
 *  UART register haritasi (sartname EK-2)
 * ========================================================= */
#define UART_CPB  REG32(UART_BASE + 0x00)  /* clock-per-bit (baud bolen)  */
#define UART_STP  REG32(UART_BASE + 0x04)  /* stop bit sayisi             */
#define UART_RDR  REG32(UART_BASE + 0x08)  /* RX veri register (oku)      */
#define UART_TDR  REG32(UART_BASE + 0x0C)  /* TX veri register (yaz)      */
#define UART_CFG  REG32(UART_BASE + 0x10)  /* config / durum              */

#define UART_CFG_TX_START  (1U << 0)  /* yaz: TX baslat (self-clearing)  */
#define UART_CFG_RX_READY  (1U << 1)  /* oku: veri alindi                */
#define UART_CFG_TX_DONE   (1U << 2)  /* oku: TX tamamlandi               */

/* UART baud boleni: 48 MHz / 115200 ~= 416 */
#define UART_BAUD          115200UL
#define UART_CPB_VALUE     (SYS_CLK_HZ / UART_BAUD)

/* =========================================================
 *  Yardimci bit makrolari
 * ========================================================= */
#define BIT(n)       (1UL << (n))
#define SET_BIT(r,n) ((r) |=  BIT(n))
#define CLR_BIT(r,n) ((r) &= ~BIT(n))
#define TST_BIT(r,n) (((r) >> (n)) & 1UL)

#endif /* SOC_H */
