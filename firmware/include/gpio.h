#ifndef GPIO_H
#define GPIO_H

#include "soc.h"

/* =========================================================
 *  GPIO Register Map  (base: 0x4001_0000)
 *  RTL kaynak: gpio.sv (GPIO_AXI4_Lite modülü)
 *
 *  Offset  | İsim      | R/W | Açıklama
 *  --------+-----------+-----+----------------------------------
 *  0x00    | GPIO_IDR  | R   | Input Data Register  [31:0]
 *  0x04    | GPIO_ODR  | R/W | Output Data Register [15:0]
 *
 *  NOT: ODR yazımında RTL sadece wdata[15:0]'ı alır:
 *       GPIO_ODR <= {16'h0000, wdata[15:0]}
 *       IDR tüm 32 biti döner.
 * ========================================================= */

typedef struct {
    volatile uint32_t IDR;   /* 0x00 - Input Data Register  */
    volatile uint32_t ODR;   /* 0x04 - Output Data Register */
} GPIO_TypeDef;

#define GPIO  ((GPIO_TypeDef *) GPIO_BASE)

/* =========================================================
 *  Fonksiyon prototipleri
 * ========================================================= */

/** @brief Tüm output pinlerini yazar (sadece [15:0] etkili). */
void gpio_write(uint16_t val);

/** @brief Belirli bir output pinini set eder (0-15). */
void gpio_set_pin(uint8_t pin);

/** @brief Belirli bir output pinini temizler (0-15). */
void gpio_clear_pin(uint8_t pin);

/** @brief Tüm input pinlerini okur [31:0]. */
uint32_t gpio_read(void);

/** @brief Belirli bir input pinini okur. */
uint8_t gpio_read_pin(uint8_t pin);

#endif /* GPIO_H */
