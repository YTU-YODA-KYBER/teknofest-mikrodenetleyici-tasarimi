#include "gpio.h"

/* Shadow register: ODR doğrudan read-modify-write'a izin veriyor
 * ama RTL'de ODR AXI okuma ile doğru dönüyor, doğrudan kullanabiliriz. */

void gpio_write(uint16_t val) {
    /* RTL: GPIO_ODR <= {16'h0000, wdata[15:0]} */
    GPIO->ODR = (uint32_t)val;
}

void gpio_set_pin(uint8_t pin) {
    if (pin > 15) return;
    /* Güncel ODR değerini oku (RTL bunu doğru döndürüyor: araddr[3:0] == 4'h4) */
    uint32_t current = GPIO->ODR;
    GPIO->ODR = current | BIT(pin);
}

void gpio_clear_pin(uint8_t pin) {
    if (pin > 15) return;
    uint32_t current = GPIO->ODR;
    GPIO->ODR = current & ~BIT(pin);
}

uint32_t gpio_read(void) {
    return GPIO->IDR;
}

uint8_t gpio_read_pin(uint8_t pin) {
    if (pin > 31) return 0;
    return (uint8_t)((GPIO->IDR >> pin) & 1UL);
}
