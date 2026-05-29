#include "qspi.h"

/* =========================================================
 *  Dahili: son gönderilen instruction byte'ı takip eder.
 *  RTL tetikleyici mekanizması: instruction byte değişmeden
 *  tekrar yazılırsa yeni transfer başlamaz.
 * ========================================================= */
static uint8_t qspi_last_instr = 0x00;  /* reset sonrası instr_shadow=0 */

/* =========================================================
 *  Dahili: meşgul bekle
 * ========================================================= */
static void qspi_wait_idle(void) {
    while (QSPI->STA & QSPI_STA_BUSY);
}

/* =========================================================
 *  Dahili: aynı instruction tekrar kullanılacaksa
 *  araya 0xFF (NOP) koy ve bekle.
 *  Not: 0xFF birçok flash'ta tanımsız komuttur ve ignored olur.
 *       CS aktifleşip 0xFF gönderilir, CS pasifleşir — zararsız.
 * ========================================================= */
static void qspi_break_shadow(void) {
    /* Adres fazı olmadan, veri fazı olmadan sadece 0xFF gönder */
    QSPI->ADDR_FLAG = 0;
    QSPI->CCR = QSPI_CCR_PRESC(QSPI_DEFAULT_PRESC) | FLASH_CMD_NOP;
    qspi_wait_idle();
    qspi_last_instr = FLASH_CMD_NOP;
}

/* =========================================================
 *  Dahili: tek komut gönder (instruction only, no addr/data)
 * ========================================================= */
static void qspi_send_instr_only(uint8_t instr) {
    if (instr == qspi_last_instr) qspi_break_shadow();

    QSPI->ADDR_FLAG = 0;
    QSPI->CCR = QSPI_CCR_PRESC(QSPI_DEFAULT_PRESC) |
                QSPI_CCR_INSTR(instr);

    qspi_wait_idle();
    qspi_last_instr = instr;
}

/* =========================================================
 *  Dahili: adresli okuma (instruction + address + read data)
 * ========================================================= */
static void qspi_read_with_addr(uint8_t instr, uint32_t addr,
                                 uint8_t len_bytes) {
    if (instr == qspi_last_instr) qspi_break_shadow();

    /* RX FIFO'yu temizle */
    QSPI->FCR = QSPI_FCR_RX_CLR;

    QSPI->ADR      = addr;
    QSPI->ADDR_FLAG = 1;

    QSPI->CCR = QSPI_CCR_PRESC(QSPI_DEFAULT_PRESC) |
                QSPI_CCR_DSIZE(len_bytes)           |
                QSPI_CCR_DMODE_x1                   |
                QSPI_CCR_DIR_READ                   |
                QSPI_CCR_INSTR(instr);

    qspi_wait_idle();
    qspi_last_instr = instr;
}

/* =========================================================
 *  Dahili: adresli yazma (instruction + address + write data)
 * ========================================================= */
static void qspi_write_with_addr(uint8_t instr, uint32_t addr,
                                  const uint8_t *data, uint8_t len_bytes) {
    if (instr == qspi_last_instr) qspi_break_shadow();

    /* TX FIFO'yu temizle, veri yükle */
    QSPI->FCR = QSPI_FCR_TX_CLR;

    /* RTL byte sırası: flash'tan gelen veride byte swap var (LOAD state'inde
     * {[7:0],[15:8],[23:16],[31:24]} şeklinde swap yapılıyor).
     * Yazma için de aynı swap uygulanıyor, yani driver'da swap yok. */
    uint32_t word = 0;
    for (int i = 0; i < len_bytes; i++) {
        word |= ((uint32_t)data[i] << (i * 8));
    }
    QSPI->DR = word;  /* TX FIFO'ya push */

    QSPI->ADR       = addr;
    QSPI->ADDR_FLAG = 1;

    QSPI->CCR = QSPI_CCR_PRESC(QSPI_DEFAULT_PRESC) |
                QSPI_CCR_DSIZE(len_bytes)           |
                QSPI_CCR_DMODE_x1                   |
                QSPI_CCR_DIR_WRITE                  |
                QSPI_CCR_INSTR(instr);

    qspi_wait_idle();
    qspi_last_instr = instr;
}

/* =========================================================
 *  Public API
 * ========================================================= */

void qspi_init(void) {
    /* FIFO'ları ve status'u temizle */
    QSPI->FCR = QSPI_FCR_RX_CLR | QSPI_FCR_TX_CLR;
    QSPI->CCR = QSPI_CCR_STA_CLR;

    /* CCR'ı sıfırla (instr_shadow'ı RTL'de 0'a başlatır, biz de 0'da bırakıyoruz) */
    QSPI->CCR      = 0;
    QSPI->ADDR_FLAG = 0;
    qspi_last_instr = 0x00;
}

uint32_t qspi_read_id(void) {
    /* RDID (0x9F): 3 byte döner — manufacturer + device type + capacity */
    qspi_read_with_addr(FLASH_CMD_RDID, 0, 3);

    /* RX FIFO'dan oku */
    uint32_t raw = QSPI->DR;

    /* RTL LOAD state'inde byte swap yapılıyor:
     * FIFO'dan {[7:0],[15:8],[23:16],[31:24]} sırasıyla geliyor.
     * Yani DR[7:0]=manufacturer, DR[15:8]=device_type, DR[23:16]=capacity */
    return raw & 0x00FFFFFFUL;
}

uint8_t qspi_read_status(void) {
    /* RDSR1 (0x05): 1 byte status register */
    qspi_read_with_addr(FLASH_CMD_RDSR1, 0, 1);
    return (uint8_t)(QSPI->DR & 0xFF);
}

void qspi_wait_busy(void) {
    /* Flash WIP (Write In Progress) biti temizlenene kadar bekle */
    while (qspi_read_status() & FLASH_SR_WIP);
}

void qspi_write_enable(void) {
    qspi_send_instr_only(FLASH_CMD_WREN);
}

void qspi_read(uint32_t addr, uint8_t *buf, uint8_t len) {
    if (!buf || len == 0 || len > 4) return;  /* 4 byte max (1 FIFO word) */

    qspi_read_with_addr(FLASH_CMD_READ, addr, len);

    uint32_t raw = QSPI->DR;
    for (int i = 0; i < len; i++) {
        buf[i] = (uint8_t)((raw >> (i * 8)) & 0xFF);
    }
}

void qspi_page_program(uint32_t addr, const uint8_t *data, uint8_t len) {
    if (!data || len == 0 || len > 4) return;

    qspi_write_enable();

    qspi_write_with_addr(FLASH_CMD_PP, addr, data, len);

    qspi_wait_busy();
}

void qspi_sector_erase(uint32_t addr) {
    qspi_write_enable();

    if (FLASH_CMD_SE4K == qspi_last_instr) qspi_break_shadow();

    QSPI->ADR       = addr;
    QSPI->ADDR_FLAG = 1;

    QSPI->CCR = QSPI_CCR_PRESC(QSPI_DEFAULT_PRESC) |
                QSPI_CCR_INSTR(FLASH_CMD_SE4K);

    qspi_wait_idle();
    qspi_last_instr = FLASH_CMD_SE4K;

    qspi_wait_busy();
}
