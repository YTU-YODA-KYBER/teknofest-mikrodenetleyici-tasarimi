`timescale 1ns / 1ps
// =====================================================================
//  tb_soc.sv — SoC Firmware Doğrulama Testbench'i
//  ---------------------------------------------------
//  Amaç: firmware.hex'in boot ROM'a yüklenip CV32E40P üzerinde
//        doğru koştuğunu simülasyonda doğrulamak.
//
//  Özellikler:
//    - 48 MHz clock üretir (clk_wiz'i bypass eder)
//    - Reset sekansı uygular
//    - UART TX hattını decode edip karakterleri konsola yazar
//    - GPIO_ODR değişimlerini loglar
//
//  NOT: DUT modül adını ('top_module') ve port isimlerini kendi
//       SoC top modülünle eşleştir. Aşağıdaki isimler block design'daki
//       SoC_Design portlarına göre yazıldı.
//
//  ÖNEMLİ — Simülasyon Hızı:
//    main.c'deki timer_delay_ms(1000) çağrıları simülasyonda
//    48 milyon clock = sonsuza kadar sürer. Simülasyon için
//    -DSIMULATION flag'iyle kısa gecikmeli bir build kullan
//    (aşağıdaki açıklamaya bak) veya minimal bir sim firmware'i yaz.
// =====================================================================

module tb_soc;

    // -----------------------------------------------------------------
    //  Parametreler
    // -----------------------------------------------------------------
    localparam real CLK_PERIOD = 20.833;          // 48 MHz → 20.833 ns
    localparam real BAUD_RATE  = 115200.0;
    localparam real BIT_TIME   = 1.0e9 / BAUD_RATE; // ns/bit ≈ 8680.5

    // -----------------------------------------------------------------
    //  DUT sinyalleri
    // -----------------------------------------------------------------
    logic        clk_i;
    logic        rst_ni;
    logic        rx;
    logic        tx;
    logic [31:0] interrupt_i;
    logic [31:0] GPIO_IDR;
    logic [31:0] GPIO_ODR;
    logic [4:0]  interrupt_id;
    logic        interrupt_ack;

    // Bidirectional hatlar — tri1: undriven iken '1'e çekilir
    // (harici pull-up dirençlerini modeller)
    tri1         I2C_SCL;
    tri1         I2C_SDA;
    tri1         QSPI_SCLK;
    tri1         QSPI_CS;
    tri1         QSPI_IO0;
    tri1         QSPI_IO1;
    tri1         QSPI_IO2;
    tri1         QSPI_IO3;

    // UART decode için
    logic [7:0]  uart_rx_byte;

    // -----------------------------------------------------------------
    //  DUT — kendi top modülünle isim/port eşleştir
    // -----------------------------------------------------------------
    top_module dut (
        .clk_i         (clk_i),
        .rst_ni        (rst_ni),
        .rx            (rx),
        .tx            (tx),
        .interrupt_i   (interrupt_i),
        .GPIO_IDR      (GPIO_IDR),
        .GPIO_ODR      (GPIO_ODR),
        .interrupt_id  (interrupt_id),
        .interrupt_ack (interrupt_ack),
        .I2C_SCL       (I2C_SCL),
        .I2C_SDA       (I2C_SDA),
        .QSPI_SCLK     (QSPI_SCLK),
        .QSPI_CS       (QSPI_CS),
        .QSPI_IO0      (QSPI_IO0),
        .QSPI_IO1      (QSPI_IO1),
        .QSPI_IO2      (QSPI_IO2),
        .QSPI_IO3      (QSPI_IO3)
    );

    // -----------------------------------------------------------------
    //  48 MHz clock üretimi
    // -----------------------------------------------------------------
    initial clk_i = 1'b0;
    always #(CLK_PERIOD / 2.0) clk_i = ~clk_i;

    // -----------------------------------------------------------------
    //  Reset + başlangıç stimulusu
    // -----------------------------------------------------------------
    initial begin
        rst_ni      = 1'b0;
        rx          = 1'b1;            // UART idle hattı yüksek
        interrupt_i = 32'h0000_0000;
        GPIO_IDR    = 32'h0000_00A5;   // test pattern (switch'leri taklit)

        // 20 clock boyunca reset tut
        repeat (20) @(posedge clk_i);
        rst_ni = 1'b1;
        $display("[TB] %0t ns : Reset deassert edildi, CPU boot ediyor...", $time);
    end

    // -----------------------------------------------------------------
    //  UART RX Monitor — tx hattını decode edip konsola yazar
    //  8N1 format: 1 start (low) + 8 data (LSB first) + 1 stop (high)
    // -----------------------------------------------------------------
    initial begin
        forever begin
            // Start bit bekle (idle '1' → start '0' geçişi)
            @(negedge tx);

            // 1.5 bit süresi bekle: start bit'i geç + bit0'ın ortasına gel
            #(BIT_TIME * 1.5);

            // 8 data bitini örnekle (LSB first)
            for (int i = 0; i < 8; i++) begin
                uart_rx_byte[i] = tx;
                #(BIT_TIME);
            end
            // stop bit'i atla — bir sonraki negedge zaten yakalar

            // Karakteri yazdır
            if (uart_rx_byte >= 8'h20 && uart_rx_byte < 8'h7F)
                $write("%c", uart_rx_byte);          // yazdırılabilir ASCII
            else if (uart_rx_byte == 8'h0A)
                $write("\n");                         // \n
            else if (uart_rx_byte == 8'h0D)
                ;                                     // \r — yok say
            else
                $write("[%02h]", uart_rx_byte);       // diğer → hex göster
        end
    end

    // -----------------------------------------------------------------
    //  GPIO_ODR Monitor — her değişimde logla
    // -----------------------------------------------------------------
    initial begin
        @(posedge rst_ni);  // reset bitene kadar bekle
        forever begin
            @(GPIO_ODR);
            $display("[TB] %0t ns : GPIO_ODR = 0x%08h", $time, GPIO_ODR);
        end
    end

    // -----------------------------------------------------------------
    //  Simülasyon süre limiti
    //  NOT: firmware'deki gecikmelere göre ayarla. -DSIMULATION ile
    //  kısa gecikmeli build kullanıyorsan 5-10 ms yeterli.
    // -----------------------------------------------------------------
    initial begin
        #10_000_000;   // 10 ms simülasyon zamanı
        $display("\n[TB] %0t ns : Simülasyon zaman limiti — bitiriliyor.", $time);
        $finish;
    end

    // -----------------------------------------------------------------
    //  Waveform dump (XSim otomatik yapar ama explicit de eklenebilir)
    // -----------------------------------------------------------------
    initial begin
        $dumpfile("tb_soc.vcd");
        $dumpvars(0, tb_soc);
    end

endmodule
