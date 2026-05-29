# =========================================================================
# 1. TEMEL SAAT TANIMI
# =========================================================================
# 48 MHz için 20.833 ns periyot tanımlanır.
create_clock -period 20.833 -name clk_i -waveform {0.000 10.416} [get_ports clk_i]

# =========================================================================
# 2. CLOCK JITTER VE BELİRSİZLİK (0.5 ns)
# =========================================================================
# Dışarıdan gelen saat sinyalinin peak-to-peak jitter değerini araca bildiririz.
# Bu, aracın Setup/Hold analizlerinde kullanabileceği zamanı 0.5 ns daraltır.
set_input_jitter [get_clocks clk_i] 0.500

# Alternatif/Ek olarak tüm saat ağına genel bir belirsizlik eklenebilir:
# set_clock_uncertainty 0.500 [get_clocks clk_i]

# =========================================================================
# 3. GİRİŞ VE ÇIKIŞ PORTLARI İÇİN GÜVENLİK MARJLARI (1.0 ns)
# =========================================================================
# set_input_delay: Dış çipten çıkıp FPGA pinine gelene kadar geçen süre (Board delay + dış çipin Tco'su).
# set_output_delay: FPGA pininden çıkıp dış çipe gidene kadar geçen süre (Board delay + dış çipin Setup time'ı).

# Sadece "Giriş" (Input) olan portlar için (clk_i ve rst_ni hariç tutulmalı)
set_input_delay -clock [get_clocks clk_i] 1.000 [get_ports -filter {DIRECTION == IN && NAME != clk_i && NAME != rst_n>

# Sadece "Çıkış" (Output) olan portlar için (TX, I2C_SCL, vb.)
set_output_delay -clock [get_clocks clk_i] 1.000 [get_ports -filter {DIRECTION == OUT}]

# Çift Yönlü (Inout) Portlar İçin (QSPI_IOx, I2C_SDA)
# Bunlar hem okuma hem yazma yaptığı için her iki kısıtlamayı da almalıdır.
set_input_delay -clock [get_clocks clk_i] 1.000 [get_ports -filter {DIRECTION == INOUT}]
set_output_delay -clock [get_clocks clk_i] 1.000 [get_ports -filter {DIRECTION == INOUT}]

# =========================================================================
# 4. FALSE PATH (ASENKRON SİNYALLER)
# =========================================================================
# Reset sinyalinin zamanlaması analiz edilmesin.
set_false_path -from [get_ports rst_ni]

