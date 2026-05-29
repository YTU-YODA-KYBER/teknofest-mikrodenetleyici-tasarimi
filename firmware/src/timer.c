#include "timer.h"

void timer_init(uint32_t prescaler, uint32_t reload, uint32_t mode) {
    TIMER->ENA   = 0;          /* Önce devre dışı bırak */
    TIMER->PRE_m = prescaler;
    TIMER->ARE   = reload;
    TIMER->MOD   = mode;
    TIMER->CLR   = 1;          /* CNT=0, TIM_PRE=TIM_PRE_m yükle */
    TIMER->EVC   = 1;          /* Event sayacını sıfırla */
}

void timer_enable(void) {
    TIMER->ENA = 1;
}

void timer_disable(void) {
    TIMER->ENA = 0;
}

void timer_clear(void) {
    TIMER->CLR = 1;
}

void timer_clear_events(void) {
    TIMER->EVC = 1;
}

uint32_t timer_get_count(void) {
    return TIMER->CNT;
}

uint32_t timer_get_events(void) {
    return TIMER->EVN;
}

void timer_delay_ms(uint32_t ms) {
    if (ms == 0) return;

    /* 48MHz / prescaler(48) = 1µs tick, ARE=999 → 1ms/event */
    timer_init(TIMER_PRE_1US, TIMER_ARE_1MS, TIMER_MOD_UP);
    timer_enable();

    /* TIM_EVN ms adet event birikene kadar bekle */
    while (TIMER->EVN < ms);

    timer_disable();
}

void timer_delay_us(uint32_t us) {
    if (us == 0) return;

    /* Prescaler=0 → her clock'ta bir tick (48 tick/µs @ 48MHz).
     * ARE = 48*us - 1 → us adet mikrosaniye sonra tek event. */
    timer_init(0, (uint32_t)(48UL * us - 1UL), TIMER_MOD_UP);
    timer_enable();

    while (TIMER->EVN < 1);

    timer_disable();
}
