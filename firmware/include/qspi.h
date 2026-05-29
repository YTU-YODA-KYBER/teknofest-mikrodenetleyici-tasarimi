#ifndef QSPI_H
#define QSPI_H

#include "soc.h"

/* =========================================================
 *  QSPI Register Map  (base: 0x4003_0000)
 *  RTL kaynak: qspi_master_axi4_lite.sv (QSPI_Master_AXI4_Lite)
 *
 *  Offset  | İsim      | R/W | Açıklama
 *  --------+-----------+-----+----------------------------------
 *  0x00    | QSPI_CCR  | R/W | Command & Config Register
 *  0x04    | QSPI_ADR  | R/W | Flash adresi
 *  0x08    | QSPI_DR   | R/W | Data Register (TX FIFO yazar / RX FIFO okur)
 *  0x0C    | QSPI_STA  | R   | Status Register
 *  0x10    | QSPI_FCR  | W   | FIFO Control Register
 *  0x14    | ADDR_FLAG | W   | 1: adres fazı ekle, 0: ekleme
 *
 * ----- QSPI_CCR bit tanımları -----
 *  [7:0]   instruction  : Flash komutu (opcode).
 *                         ÖNEMLİ: bu alan önceki değerden FARKLI
 *                         olduğunda yeni transfer başlar.
 *  [9:8]   data_mode    : Veri fazı modu
 *                         00 = veri fazı yok
 *                         01 = x1 (tek hat)
 *                         10 = x2 (dual)
 *                         11 = x4 (quad)
 *  [10]    direction    : 0 = okuma (flash→CPU), 1 = yazma (CPU→flash)
 *  [15:11] dummy_cycles : Dummy clock sayısı (0 = dummy yok)
 *  [23:16] data_size_m1 : Veri boyutu - 1 (ör. 3 byte için = 2)
 *  [30:25] prescaler    : SCLK = sys_clk / (2 * prescaler)
 *  [31]    sta_clr      : 1 yazınca QSPI_STA sıfırlanır
 *
 * ----- QSPI_STA bit tanımları -----
 *  [1]     busy         : Transfer devam ediyor
 *  [4]     rx_full      : RX FIFO dolu
 *  [5]     rx_empty     : RX FIFO boş
 *  [6]     tx_full      : TX FIFO dolu
 *  [7]     tx_empty     : TX FIFO boş
 *  [11:8]  error        : 0001=RX underrun, 0010=TX overrun
 *
 * ----- QSPI_FCR bit tanımları -----
 *  [0]     rx_clr       : 1 yazınca RX FIFO sıfırlanır
 *  [1]     tx_clr       : 1 yazınca TX FIFO sıfırlanır
 *
 * ----- Transfer Tetikleme Mekanizması -----
 *  RTL, instruction byte'ının ÖNCEKİ değerden farklı olduğunu gördüğünde
 *  transfer başlatır. Aynı komutu arka arkaya göndermek için araya
 *  farklı bir instruction byte'ı geçirilmesi gerekir.
 *  Bu driver'da: qspi_exec_cmd() içinde önceki instruction takip edilir;
 *  eğer aynıysa önce 0xFF (Flash'ta NOP olarak yorumlanır) gönderilir.
 * ========================================================= */

typedef struct {
    volatile uint32_t CCR;       /* 0x00 - Command & Config      */
    volatile uint32_t ADR;       /* 0x04 - Flash adresi          */
    volatile uint32_t DR;        /* 0x08 - Data register         */
    volatile uint32_t STA;       /* 0x0C - Status                */
    volatile uint32_t FCR;       /* 0x10 - FIFO control          */
    volatile uint32_t ADDR_FLAG; /* 0x14 - Adres fazı aktif flag */
} QSPI_TypeDef;

#define QSPI  ((QSPI_TypeDef *) QSPI_BASE)

/* CCR alan sabitleri */
#define QSPI_CCR_INSTR(x)      ((uint32_t)((x) & 0xFF))
#define QSPI_CCR_DMODE_NONE    (0UL  << 8)
#define QSPI_CCR_DMODE_x1      (1UL  << 8)
#define QSPI_CCR_DMODE_x2      (2UL  << 8)
#define QSPI_CCR_DMODE_x4      (3UL  << 8)
#define QSPI_CCR_DIR_READ      (0UL  << 10)
#define QSPI_CCR_DIR_WRITE     (1UL  << 10)
#define QSPI_CCR_DUMMY(n)      (((uint32_t)(n) & 0x1F) << 11)
#define QSPI_CCR_DSIZE(n)      (((uint32_t)((n)-1) & 0xFF) << 16)  /* n byte */
#define QSPI_CCR_PRESC(n)      (((uint32_t)(n) & 0x3F) << 25)
#define QSPI_CCR_STA_CLR       BIT(31)

/* STA register bit maskeleri */
#define QSPI_STA_BUSY          BIT(1)
#define QSPI_STA_RX_FULL       BIT(4)
#define QSPI_STA_RX_EMPTY      BIT(5)
#define QSPI_STA_TX_FULL       BIT(6)
#define QSPI_STA_TX_EMPTY      BIT(7)

/* FCR bit maskeleri */
#define QSPI_FCR_RX_CLR        BIT(0)
#define QSPI_FCR_TX_CLR        BIT(1)

/* Varsayılan SCLK prescaler (48MHz → SCLK = 48/(2*4) = 6MHz) */
#define QSPI_DEFAULT_PRESC     4UL

/* Bilinen Flash komutları */
#define FLASH_CMD_WREN     0x06   /* Write Enable                  */
#define FLASH_CMD_WRDI     0x04   /* Write Disable                 */
#define FLASH_CMD_RDSR1    0x05   /* Read Status Reg-1             */
#define FLASH_CMD_RDID     0x9F   /* Read JEDEC ID                 */
#define FLASH_CMD_READ     0x03   /* Standard Read (x1)            */
#define FLASH_CMD_PP       0x02   /* Page Program (x1 write)       */
#define FLASH_CMD_SE4K     0x20   /* Sector Erase 4KB              */
#define FLASH_CMD_SE64K    0xD8   /* Sector Erase 64KB             */
#define FLASH_CMD_RESET_EN 0x66   /* Reset Enable                  */
#define FLASH_CMD_RESET    0x99   /* Reset Memory                  */
#define FLASH_CMD_NOP      0xFF   /* Driver-dahili dummy komut     */

/* Flash Status Register-1 bit maskeleri */
#define FLASH_SR_WIP       BIT(0)  /* Write In Progress */
#define FLASH_SR_WEL       BIT(1)  /* Write Enable Latch */

/* =========================================================
 *  Fonksiyon prototipleri
 * ========================================================= */

/** @brief QSPI'ı başlatır, FIFO'ları temizler, STA sıfırlar. */
void qspi_init(void);

/** @brief JEDEC ID okur (3 byte: manufacturer, device type, capacity). */
uint32_t qspi_read_id(void);

/** @brief Flash Status Register-1'i okur. */
uint8_t qspi_read_status(void);

/** @brief Flash WIP biti temizlenene kadar bekler (write/erase bitmesini bekler). */
void qspi_wait_busy(void);

/** @brief Write Enable komutu gönderir. */
void qspi_write_enable(void);

/**
 * @brief Flash'tan standart x1 okuma (READ 0x03).
 * @param addr   24-bit flash adresi
 * @param buf    Veriyi yazacak buffer
 * @param len    Okunacak byte sayısı (1-4, RTL FIFO sınırı: 64 word)
 */
void qspi_read(uint32_t addr, uint8_t *buf, uint8_t len);

/**
 * @brief Flash'a sayfa programlama (PP 0x02).
 * @param addr   24-bit flash adresi (sayfa hizalı olmalı: 256 byte sınır)
 * @param data   Yazılacak veri
 * @param len    Byte sayısı (1-4)
 */
void qspi_page_program(uint32_t addr, const uint8_t *data, uint8_t len);

/**
 * @brief 4KB sektör silme (SE 0x20).
 * @param addr   Silinecek sektörün başlangıç adresi
 */
void qspi_sector_erase(uint32_t addr);

#endif /* QSPI_H */
