#ifndef I2C_H
#define I2C_H

#include "soc.h"

/* =========================================================
 *  I2C Register Map  (base: 0x4002_0000)
 *  RTL kaynak: i2c_axi4_lite.sv (I2C_Master_AXI4_Lite)
 *
 *  Offset  | İsim       | R/W | Açıklama
 *  --------+------------+-----+---------------------------------
 *  0x00    | I2C_NBY    | R/W | Byte sayısı (1-4, HW 4'e kırpar)
 *  0x04    | I2C_ADR    | R/W | Slave adresi [6:0]
 *  0x08    | I2C_RDR    | R   | Alınan veri (4 byte paket)
 *  0x0C    | I2C_TDR    | W   | Gönderilecek veri (4 byte paket)
 *  0x10    | I2C_CFG    | R/W | Config / Status
 *  0x14    | I2C_CFG_CLR| W   | Flag temizleme
 *
 *  I2C_CFG bit tanımları:
 *    [0] = TX_START  : 1 yazınca YAZMA işlemi başlar
 *                      → I2C_NBY kadar byte I2C_TDR'dan gönderilir
 *                      → İşlem bitince HW [0]=0, [1]=1 yapar
 *    [1] = TX_DONE   : YAZMA işlemi tamamlandı (HW set eder, ro)
 *    [2] = RX_START  : 1 yazınca OKUMA işlemi başlar
 *                      → Önce I2C_TDR[7:0] register adresi gönderilir
 *                      → Sonra RESTART + I2C_NBY kadar byte okunur
 *                      → İşlem bitince HW [2]=0, [3]=1 yapar
 *    [3] = RX_DONE   : OKUMA işlemi tamamlandı (HW set eder, ro)
 *
 *  I2C_CFG_CLR bit tanımları:
 *    [0] = 1 → I2C_CFG[1] (TX_DONE) temizle
 *    [1] = 1 → I2C_CFG[3] (RX_DONE) temizle
 *
 *  I2C_TDR / I2C_RDR byte düzeni (RTL'den):
 *    byte_cnt==1 → [7:0],  byte_cnt==2 → [15:8],
 *    byte_cnt==3 → [23:16], byte_cnt==4 → [31:24]
 *    Yani: byte0 = TDR[7:0], byte1 = TDR[15:8], ...
 *
 *  Frekans: CLK_FREQ_HZ=48MHz, I2C_FREQ_HZ=400KHz (Fast-mode)
 * ========================================================= */

typedef struct {
    volatile uint32_t NBY;     /* 0x00 - Byte sayısı          */
    volatile uint32_t ADR;     /* 0x04 - Slave adresi [6:0]   */
    volatile uint32_t RDR;     /* 0x08 - Alınan veri          */
    volatile uint32_t TDR;     /* 0x0C - Gönderilecek veri    */
    volatile uint32_t CFG;     /* 0x10 - Config / Status      */
    volatile uint32_t CFG_CLR; /* 0x14 - Flag temizleme       */
} I2C_TypeDef;

#define I2C  ((I2C_TypeDef *) I2C_BASE)

/* CFG register bit maskeleri */
#define I2C_CFG_TX_START   BIT(0)
#define I2C_CFG_TX_DONE    BIT(1)
#define I2C_CFG_RX_START   BIT(2)
#define I2C_CFG_RX_DONE    BIT(3)

/* CFG_CLR bit maskeleri */
#define I2C_CLR_TX_DONE    BIT(0)
#define I2C_CLR_RX_DONE    BIT(1)

/* Maksimum tek seferde yazılabilir/okunabilir byte sayısı (RTL sınırı) */
#define I2C_MAX_BYTES  4

/* Timeout sabiti (döngü sayısı cinsinden) */
#define I2C_TIMEOUT    100000UL

/* Return kodları */
#define I2C_OK         0
#define I2C_ERR_NACK  -1
#define I2C_ERR_TIMEOUT -2

/* =========================================================
 *  Fonksiyon prototipleri
 * ========================================================= */

/**
 * @brief I2C slave'e 1-4 byte yazar.
 * @param slave_addr  7-bit slave adresi
 * @param data        Yazılacak veriler (max 4 byte, little-endian)
 * @param len         Byte sayısı (1-4)
 * @return I2C_OK veya hata kodu
 */
int i2c_write(uint8_t slave_addr, const uint8_t *data, uint8_t len);

/**
 * @brief I2C slave'den register okuma (write-then-restart-read).
 *        RTL'de I2C_CFG[2] (RX_START) akışı:
 *          1. Slave adresini write modda gönderir
 *          2. Register adresini gönderir (TDR[7:0])
 *          3. RESTART
 *          4. Slave adresini read modda gönderir
 *          5. len kadar byte okur → RDR'a yazar
 * @param slave_addr  7-bit slave adresi
 * @param reg_addr    Okunacak register adresi
 * @param buf         Okunan veriyi tutacak buffer (max 4 byte)
 * @param len         Okunacak byte sayısı (1-4)
 * @return I2C_OK veya hata kodu
 */
int i2c_read_reg(uint8_t slave_addr, uint8_t reg_addr,
                 uint8_t *buf, uint8_t len);

/**
 * @brief TX_DONE ve RX_DONE flag'lerini temizler.
 */
void i2c_clear_flags(void);

#endif /* I2C_H */
