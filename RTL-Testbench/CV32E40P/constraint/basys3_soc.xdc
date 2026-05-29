## ============================================================
##  Basys 3 - TEKNOFEST 2026 Çip Tasarım Yarışması
##  CV32E40P SoC Constraint File
##  FPGA: Xilinx Artix-7 XC7A35T-1CPG236C
##  Sistem saati: 48 MHz (clk_wiz 100MHz → 48MHz)
## ============================================================

## ============================================================
##  Sistem Saati - Kart üzerindeki 100 MHz osilatör (W5)
##  NOT: create_clock komutunu YAZMA! clk_wiz_0 IP'si bunu
##       otomatik olarak kendi XDC'sinde tanımlıyor (clk_in1_0 adıyla).
##       Burada sadece pin ataması ve IO standardı yeterli.
## ============================================================
set_property PACKAGE_PIN W5 [get_ports clk_in1_0]
    set_property IOSTANDARD LVCMOS33 [get_ports clk_in1_0]

## ============================================================
##  Reset - SW15 slide switch (active-low rst_n)
##    Switch YUKARI = 1 = Çalış
##    Switch AŞAĞI  = 0 = Reset asserted
## ============================================================
set_property PACKAGE_PIN R2 [get_ports rst_n]
    set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

## ============================================================
##  UART - USB-UART köprüsü üzerinden bilgisayara
##    PC'de "USB Serial Port" olarak görünür
##    Baud: 115200, 8N1
## ============================================================
## FPGA TX çıkışı → USB-RXD (veri bilgisayara gider)
set_property PACKAGE_PIN A18 [get_ports tx_0]
    set_property IOSTANDARD LVCMOS33 [get_ports tx_0]

## FPGA RX girişi ← USB-TXD (veri bilgisayardan gelir)
set_property PACKAGE_PIN B18 [get_ports rx_0]
    set_property IOSTANDARD LVCMOS33 [get_ports rx_0]

## ============================================================
##  GPIO_ODR - Kart üzerindeki 16 LED'i sürer (LED0..LED15)
##    Üst 16 bit ([31:16]) kullanılmıyor (RTL zaten 0 yazıyor)
## ============================================================
set_property PACKAGE_PIN U16 [get_ports {GPIO_ODR_0[0]}]    ;## LED0
set_property PACKAGE_PIN E19 [get_ports {GPIO_ODR_0[1]}]    ;## LED1
set_property PACKAGE_PIN U19 [get_ports {GPIO_ODR_0[2]}]    ;## LED2
set_property PACKAGE_PIN V19 [get_ports {GPIO_ODR_0[3]}]    ;## LED3
set_property PACKAGE_PIN W18 [get_ports {GPIO_ODR_0[4]}]    ;## LED4
set_property PACKAGE_PIN U15 [get_ports {GPIO_ODR_0[5]}]    ;## LED5
set_property PACKAGE_PIN U14 [get_ports {GPIO_ODR_0[6]}]    ;## LED6
set_property PACKAGE_PIN V14 [get_ports {GPIO_ODR_0[7]}]    ;## LED7
set_property PACKAGE_PIN V13 [get_ports {GPIO_ODR_0[8]}]    ;## LED8
set_property PACKAGE_PIN V3  [get_ports {GPIO_ODR_0[9]}]    ;## LED9
set_property PACKAGE_PIN W3  [get_ports {GPIO_ODR_0[10]}]   ;## LED10
set_property PACKAGE_PIN U3  [get_ports {GPIO_ODR_0[11]}]   ;## LED11
set_property PACKAGE_PIN P3  [get_ports {GPIO_ODR_0[12]}]   ;## LED12
set_property PACKAGE_PIN N3  [get_ports {GPIO_ODR_0[13]}]   ;## LED13
set_property PACKAGE_PIN P1  [get_ports {GPIO_ODR_0[14]}]   ;## LED14
set_property PACKAGE_PIN L1  [get_ports {GPIO_ODR_0[15]}]   ;## LED15
set_property IOSTANDARD LVCMOS33 [get_ports {GPIO_ODR_0[*]}]

## ============================================================
##  GPIO_IDR - Kart üzerindeki 15 switch + center button
##    SW15 reset'e ayrıldı, [15] yerine btnC kullanıldı
##    Üst 16 bit ([31:16]) kullanılmıyor — xlconstant ile 0'a
##    bağla veya Vivado validate uyarısını görmezden gel
## ============================================================
set_property PACKAGE_PIN V17 [get_ports {GPIO_IDR_0[0]}]    ;## SW0
set_property PACKAGE_PIN V16 [get_ports {GPIO_IDR_0[1]}]    ;## SW1
set_property PACKAGE_PIN W16 [get_ports {GPIO_IDR_0[2]}]    ;## SW2
set_property PACKAGE_PIN W17 [get_ports {GPIO_IDR_0[3]}]    ;## SW3
set_property PACKAGE_PIN W15 [get_ports {GPIO_IDR_0[4]}]    ;## SW4
set_property PACKAGE_PIN V15 [get_ports {GPIO_IDR_0[5]}]    ;## SW5
set_property PACKAGE_PIN W14 [get_ports {GPIO_IDR_0[6]}]    ;## SW6
set_property PACKAGE_PIN W13 [get_ports {GPIO_IDR_0[7]}]    ;## SW7
set_property PACKAGE_PIN V2  [get_ports {GPIO_IDR_0[8]}]    ;## SW8
set_property PACKAGE_PIN T3  [get_ports {GPIO_IDR_0[9]}]    ;## SW9
set_property PACKAGE_PIN T2  [get_ports {GPIO_IDR_0[10]}]   ;## SW10
set_property PACKAGE_PIN R3  [get_ports {GPIO_IDR_0[11]}]   ;## SW11
set_property PACKAGE_PIN W2  [get_ports {GPIO_IDR_0[12]}]   ;## SW12
set_property PACKAGE_PIN U1  [get_ports {GPIO_IDR_0[13]}]   ;## SW13
set_property PACKAGE_PIN T1  [get_ports {GPIO_IDR_0[14]}]   ;## SW14
set_property PACKAGE_PIN U18 [get_ports {GPIO_IDR_0[15]}]   ;## btnC (SW15 reset'te)
set_property IOSTANDARD LVCMOS33 [get_ports {GPIO_IDR_0[*]}]

## ============================================================
##  I2C Master - Pmod JB üzerinden harici slave'e
##    JB1 (A14) - SCL
##    JB2 (A16) - SDA
##    ÖNEMLİ: Harici 4.7k pull-up dirençleri SCL ve SDA hatlarına
##    eklenmeli! Açık-drain protokol açık-kollektörü andırır,
##    pull-up olmadan veriyolu hep '0' kalır.
## ============================================================
set_property PACKAGE_PIN A14 [get_ports I2C_SCL_0]
set_property PACKAGE_PIN A16 [get_ports I2C_SDA_0]
set_property IOSTANDARD LVCMOS33 [get_ports I2C_SCL_0]
set_property IOSTANDARD LVCMOS33 [get_ports I2C_SDA_0]
## FPGA dahili pull-up'lar zayıf (~50k), harici 4.7k tercih edilir.
## Yine de yedek olarak dahili pull-up'ı aktif et:
set_property PULLUP true [get_ports I2C_SCL_0]
set_property PULLUP true [get_ports I2C_SDA_0]

## ============================================================
##  QSPI Master - Pmod JA üzerinden harici NOR Flash
##    Önerilen bağlantı (W25Q32/W25Q64/MT25QL serisi):
##      JA1 (J1) - QSPI_CS    → Flash CS#
##      JA2 (L2) - QSPI_IO0   → Flash IO0/DI
##      JA3 (J2) - QSPI_IO1   → Flash IO1/DO
##      JA4 (G2) - QSPI_IO2   → Flash IO2/WP#
##      JA7 (H1) - QSPI_IO3   → Flash IO3/HOLD#
##      JA8 (K2) - QSPI_SCLK  → Flash CLK
##    Flash VCC ve GND'yi Pmod'un VCC (pin 6) ve GND (pin 5)
##    pinlerinden besle. 3.3V flash olmasına dikkat (5V YAKAR).
## ============================================================
set_property PACKAGE_PIN J1 [get_ports QSPI_CS_0]
set_property PACKAGE_PIN L2 [get_ports QSPI_IO0_0]
set_property PACKAGE_PIN J2 [get_ports QSPI_IO1_0]
set_property PACKAGE_PIN G2 [get_ports QSPI_IO2_0]
set_property PACKAGE_PIN H1 [get_ports QSPI_IO3_0]
set_property PACKAGE_PIN K2 [get_ports QSPI_SCLK_0]
set_property IOSTANDARD LVCMOS33 [get_ports {QSPI_CS_0 QSPI_SCLK_0 QSPI_IO0_0 QSPI_IO1_0 QSPI_IO2_0 QSPI_IO3_0}]

## QSPI IO2 ve IO3 — x1/x2 modlarda RTL bunları high-Z'ye çekiyor.
## Flash chip'inde WP# ve HOLD# olarak çalışırlar ve aktif-low'durlar.
## Floating kalırsa flash davranışı tanımsız! Dahili pull-up etkin et:
set_property PULLUP true [get_ports QSPI_IO2_0]
set_property PULLUP true [get_ports QSPI_IO3_0]
## NOT: Dahili pull-up Artix-7'de yaklaşık 50kΩ — yavaş. Daha güvenilir
## davranış için breadboard'da 10kΩ harici pull-up tak.

## ============================================================
##  Bitstream / Konfigürasyon ayarları
## ============================================================
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
## Kullanılmayan pinleri yüksek empedansta tut (boşta kalsın):
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]
