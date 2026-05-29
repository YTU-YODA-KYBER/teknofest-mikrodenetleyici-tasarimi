#ifndef TIMER_H
#define TIMER_H

#include "soc.h"

/* =========================================================
 *  Timer Register Map  (base: 0x4000_0000)
 *  RTL kaynak: timer_axi4lite.sv (Timer_module)
 *
 *  Offset  | İsim      | R/W | Açıklama
 *  --------+-----------+-----+----------------------------------
 *  0x00    | TIM_PRE_m | R/W | Prescaler yükleme değeri
 *  0x04    | TIM_ARE   | R/W | Auto-Reload (karşılaştırma) değeri
 *  0x08    | TIM_CLR   | W   | [0]=1: sayacı sıfırla, TIM_PRE'ye TIM_PRE_m yükle
 *  0x0C    | TIM_ENA   | R/W | [0]=1: timer etkin
 *  0x10    | TIM_MOD   | R/W | [0]: 0=aşağı sayar, 1=yukarı sayar
 *  0x14    | TIM_CNT   | R   | Güncel sayaç değeri
 *  0x18    | TIM_EVN   | R   | Olay sayacı (her CNT==ARE'de artar)
 *  0x1C    | TIM_EVC   | W   | [0]=1: TIM_EVN'yi sıfırla
 *
 *  Çalışma prensibi:
 *    - Her clock'ta TIM_PRE 1 azalır.
 *    - TIM_PRE == 0 olduğunda TIM_PRE = TIM_PRE_m yüklenir ve bir "tick" üretilir.
 *    - Her tick'te:
 *        Yukarı mod (MOD[0]=1): CNT artar; CNT >= ARE → event, CNT=0
 *        Aşağı mod (MOD[0]=0): CNT azalır; CNT == 0  → event, CNT=ARE
 *    - Her event'te TIM_EVN 1 artar.
 *
 *  1ms gecikme için (48MHz):
 *    TIM_PRE_m = 47    → prescaler = 48 → 1µs/tick
 *    TIM_ARE   = 999   → 1000 tick/event → 1ms/event
 *    TIM_MOD   = 1     (yukarı sayar)
 * ========================================================= */

typedef struct {
    volatile uint32_t PRE_m;  /* 0x00 - Prescaler yükleme değeri  */
    volatile uint32_t ARE;    /* 0x04 - Auto-reload değeri         */
    volatile uint32_t CLR;    /* 0x08 - Sayaç sıfırlama           */
    volatile uint32_t ENA;    /* 0x0C - Enable                     */
    volatile uint32_t MOD;    /* 0x10 - Mod seçimi                 */
    volatile uint32_t CNT;    /* 0x14 - Güncel sayaç (ro)          */
    volatile uint32_t EVN;    /* 0x18 - Event sayacı (ro)          */
    volatile uint32_t EVC;    /* 0x1C - Event temizle              */
} TIMER_TypeDef;

#define TIMER  ((TIMER_TypeDef *) TIMER_BASE)

/* MOD register sabitleri */
#define TIMER_MOD_DOWN  0UL   /* Aşağı sayar */
#define TIMER_MOD_UP    1UL   /* Yukarı sayar */

/* 48MHz için önceden hesaplanmış değerler */
#define TIMER_PRE_1US   47UL    /* 1µs/tick  için prescaler-1 */
#define TIMER_ARE_1MS   999UL   /* 1ms/event için ARE         */

/* =========================================================
 *  Fonksiyon prototipleri
 * ========================================================= */

/**
 * @brief Timer'ı yapılandırır ve sıfırlar (henüz başlatmaz).
 * @param prescaler  TIM_PRE_m değeri (frekans bölücü - 1)
 * @param reload     TIM_ARE değeri
 * @param mode       TIMER_MOD_UP veya TIMER_MOD_DOWN
 */
void timer_init(uint32_t prescaler, uint32_t reload, uint32_t mode);

/** @brief Timer'ı etkinleştirir. */
void timer_enable(void);

/** @brief Timer'ı devre dışı bırakır. */
void timer_disable(void);

/** @brief Sayacı ve prescaler'ı sıfırlar. */
void timer_clear(void);

/** @brief Event sayacını sıfırlar. */
void timer_clear_events(void);

/** @brief Güncel sayaç değerini döner. */
uint32_t timer_get_count(void);

/** @brief Güncel event sayısını döner. */
uint32_t timer_get_events(void);

/**
 * @brief Blocking ms gecikme.
 *        Dahili olarak 1µs tick, 1ms/event yapılandırması kullanır.
 *        (48MHz sistem saati varsayılır — soc.h'daki SYS_CLK_HZ'e bağlı değil,
 *         prescaler değerleri sabit kodlanmıştır.)
 */
void timer_delay_ms(uint32_t ms);

/**
 * @brief Blocking µs gecikme (yaklaşık, prescaler=0 ile).
 */
void timer_delay_us(uint32_t us);

#endif /* TIMER_H */
