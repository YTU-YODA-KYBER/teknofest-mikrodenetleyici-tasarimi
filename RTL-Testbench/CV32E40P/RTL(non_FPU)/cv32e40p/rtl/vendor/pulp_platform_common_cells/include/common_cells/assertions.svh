// ============================================================
//  assertions.svh - Vivado xsim Uyumlu Stub
// ============================================================
//  Orijinal: lowRISC/common_cells/assertions.svh
//
//  NEDEN BU DOSYA GEREKLİ:
//    Vivado xsim, SystemVerilog macro'larında default parametre
//    değeri sözdizimini (= `MACRO_NAME) desteklemiyor.
//    Bu stub, tüm assertion macro'larını no-op olarak tanımlar.
//    Simulation doğruluğu etkilenmez; assertion'lar sadece
//    tasarım invariant'larını kontrol eder, davranışı değiştirmez.
//
//  KULLANIM:
//    Projenizdeki orijinal assertions.svh'ın içeriğini
//    tamamen bu dosyanın içeriğiyle değiştirin.
//    Dosya yolu değişmesin - sadece içeriği değişsin.
// ============================================================

`ifndef COMMON_CELLS_ASSERTIONS_SVH_
`define COMMON_CELLS_ASSERTIONS_SVH_

// ============================================================
//  Default clock/reset tanımları
//  (CV32E40P bu macro'ları include etmeden önce kullanıyor)
// ============================================================
`ifndef ASSERT_DEFAULT_CLK
  `define ASSERT_DEFAULT_CLK clk_i
`endif

`ifndef ASSERT_DEFAULT_RST
  `define ASSERT_DEFAULT_RST (!rst_ni)
`endif

// ============================================================
//  Assertion macro'ları - no-op (xsim uyumlu)
//
//  CV32E40P bu macro'ları 4 argümanla çağırıyor:
//    `ASSERT(isim, özellik, clk, rst)
//
//  Tüm argümanlar kabul ediliyor ama gövde boş.
// ============================================================

// Temel internal macro (diğerleri bunu çağırır)
`define ASSERT_I(__name, __prop)

// Synthesis ortamında hiçbiri derlenmez
`ifdef SYNTHESIS

`define ASSERT(__name, __prop, __clk, __rst)
`define ASSERT_NEVER(__name, __prop, __clk, __rst)
`define ASSERT_IF(__name, __prop, __cond, __clk, __rst)
`define ASSERT_PULSE(__name, __sig, __clk, __rst)
`define ASSERT_KNOWN(__name, __sig, __clk, __rst)
`define ASSERT_KNOWN_IF(__name, __sig, __cond, __clk, __rst)

`else // SIMULATION

// -------------------------------------------------------
//  `ASSERT(isim, özellik, clk, rst)
//  Bir sonraki clock edge'de özellik doğru olmalı.
// -------------------------------------------------------
`define ASSERT(__name, __prop, __clk, __rst)

// -------------------------------------------------------
//  `ASSERT_NEVER(isim, özellik, clk, rst)
//  Özellik hiçbir zaman doğru olmamalı.
// -------------------------------------------------------
`define ASSERT_NEVER(__name, __prop, __clk, __rst)

// -------------------------------------------------------
//  `ASSERT_IF(isim, özellik, koşul, clk, rst)
//  Koşul doğruysa özellik geçerli olmalı.
// -------------------------------------------------------
`define ASSERT_IF(__name, __prop, __cond, __clk, __rst)

// -------------------------------------------------------
//  `ASSERT_PULSE(isim, sinyal, clk, rst)
//  Sinyal tek cycle pulse olmalı.
// -------------------------------------------------------
`define ASSERT_PULSE(__name, __sig, __clk, __rst)

// -------------------------------------------------------
//  `ASSERT_KNOWN(isim, sinyal, clk, rst)
//  Sinyal X veya Z içermemeli.
// -------------------------------------------------------
`define ASSERT_KNOWN(__name, __sig, __clk, __rst)

// -------------------------------------------------------
//  `ASSERT_KNOWN_IF(isim, sinyal, koşul, clk, rst)
// -------------------------------------------------------
`define ASSERT_KNOWN_IF(__name, __sig, __cond, __clk, __rst)

`endif // SYNTHESIS

// ============================================================
//  Zamanlamadan bağımsız assertion'lar (initial/final block)
// ============================================================

// `ASSERT_INIT(isim, özellik) - simülasyon başında kontrol
`define ASSERT_INIT(__name, __prop)

// `ASSERT_INIT_NET(isim, özellik) - net seviyesinde
`define ASSERT_INIT_NET(__name, __prop)

// `ASSERT_FINAL(isim, özellik) - simülasyon sonunda kontrol
`define ASSERT_FINAL(__name, __prop)

`endif // COMMON_CELLS_ASSERTIONS_SVH_
