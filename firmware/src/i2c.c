#include "i2c.h"

/* =========================================================
 *  Yardımcı: TDR register'ına byte dizisini paketle
 *  (RTL byte düzeni: byte0=[7:0], byte1=[15:8], byte2=[23:16], byte3=[31:24])
 * ========================================================= */
static uint32_t pack_bytes(const uint8_t *data, uint8_t len) {
    uint32_t packed = 0;
    for (uint8_t i = 0; i < len && i < 4; i++) {
        packed |= ((uint32_t)data[i] << (i * 8));
    }
    return packed;
}

/* =========================================================
 *  Yardımcı: RDR register'ından byte dizisini aç
 * ========================================================= */
static void unpack_bytes(uint32_t rdr, uint8_t *buf, uint8_t len) {
    for (uint8_t i = 0; i < len && i < 4; i++) {
        buf[i] = (uint8_t)((rdr >> (i * 8)) & 0xFF);
    }
}

void i2c_clear_flags(void) {
    I2C->CFG_CLR = I2C_CLR_TX_DONE | I2C_CLR_RX_DONE;
}

int i2c_write(uint8_t slave_addr, const uint8_t *data, uint8_t len) {
    if (len == 0 || len > I2C_MAX_BYTES) return I2C_ERR_TIMEOUT;

    /* Önceki flag'leri temizle */
    i2c_clear_flags();

    /* Register'ları yükle */
    I2C->NBY = (uint32_t)len;
    I2C->ADR = (uint32_t)(slave_addr & 0x7F);
    I2C->TDR = pack_bytes(data, len);

    /* TX_START bit'ini yaz → I2C işlemi başlar.
     * RTL: awready/wready bu noktadan sonra 0 olur,
     *       işlem bitince stop_and_clear state'inde 1'e döner. */
    I2C->CFG = I2C_CFG_TX_START;

    /* TX_DONE bekle (timeout ile) */
    volatile uint32_t timeout = I2C_TIMEOUT;
    while (!(I2C->CFG & I2C_CFG_TX_DONE)) {
        if (--timeout == 0) return I2C_ERR_TIMEOUT;
    }

    /* Flag'i temizle */
    I2C->CFG_CLR = I2C_CLR_TX_DONE;

    return I2C_OK;
}

int i2c_read_reg(uint8_t slave_addr, uint8_t reg_addr,
                 uint8_t *buf, uint8_t len) {
    if (len == 0 || len > I2C_MAX_BYTES) return I2C_ERR_TIMEOUT;

    /* Önceki flag'leri temizle */
    i2c_clear_flags();

    /* Register'ları yükle.
     * TDR[7:0] = register adresi (RTL CFG[2] akışında 1 byte write yapar).
     * NBY = okunacak byte sayısı (restart sonrası read fazında kullanılır). */
    I2C->NBY = (uint32_t)len;
    I2C->ADR = (uint32_t)(slave_addr & 0x7F);
    I2C->TDR = (uint32_t)reg_addr;  /* [7:0]'a register adresi */

    /* RX_START bit'ini yaz → write-restart-read akışı başlar */
    I2C->CFG = I2C_CFG_RX_START;

    /* RX_DONE bekle */
    volatile uint32_t timeout = I2C_TIMEOUT;
    while (!(I2C->CFG & I2C_CFG_RX_DONE)) {
        if (--timeout == 0) return I2C_ERR_TIMEOUT;
    }

    /* RDR'dan veriyi oku */
    unpack_bytes(I2C->RDR, buf, len);

    /* Flag'i temizle */
    I2C->CFG_CLR = I2C_CLR_RX_DONE;

    return I2C_OK;
}
