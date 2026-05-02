module AXI4_Interconnect(

    // GLOBAL CLOCK VE RESET
    input logic clk_i,
    input logic rst_ni,

    
    axi4_if.slave s0_bus,  // CPU(DATA) => Interconnect portları
    axi4_if.slave s1_bus,  // CPU(INSTRUCTION) => Interconnect portları

    axi4lite_if.master m0_bus, // Interconnect => Timer portları
    axi4lite_if.master m1_bus, // Interconnect => GPIO portları
    axi4lite_if.master m2_bus, // Interconnect => I2C portları
    axi4lite_if.master m3_bus  // Interconnect => QSPI portları
    );

    // ==============================================================
    // 1. ADRES ÇÖZÜCÜ (Address Decoder) - Sadece seçim sinyalleri
    // ==============================================================
    logic sel_timer_aw, sel_timer_ar; 
    logic sel_gpio_aw, sel_gpio_ar;
    logic sel_i2c_aw, sel_i2c_ar;
    logic sel_qspi_aw, sel_qspi_ar;
    
    // AW Kanalı Seçimleri
    assign sel_timer_aw = (s0_bus.axi_awaddr >= 32'h4000_0000) && (s0_bus.axi_awaddr < 32'h4001_0000);
    assign sel_gpio_aw  = (s0_bus.axi_awaddr >= 32'h4001_0000) && (s0_bus.axi_awaddr < 32'h4002_0000);
    assign sel_i2c_aw   = (s0_bus.axi_awaddr >= 32'h4002_0000) && (s0_bus.axi_awaddr < 32'h4003_0000);
    assign sel_qspi_aw  = (s0_bus.axi_awaddr >= 32'h4003_0000) && (s0_bus.axi_awaddr < 32'h4004_0000);

    // AR Kanalı Seçimleri
    assign sel_timer_ar = (s0_bus.axi_araddr >= 32'h4000_0000) && (s0_bus.axi_araddr < 32'h4001_0000);
    assign sel_gpio_ar  = (s0_bus.axi_araddr >= 32'h4001_0000) && (s0_bus.axi_araddr < 32'h4002_0000);
    assign sel_i2c_ar   = (s0_bus.axi_araddr >= 32'h4002_0000) && (s0_bus.axi_araddr < 32'h4003_0000);
    assign sel_qspi_ar  = (s0_bus.axi_araddr >= 32'h4003_0000) && (s0_bus.axi_araddr < 32'h4004_0000);


    // ==============================================================
    // 2. BROADCAST (Ortak Bağlananlar: Adresler, Veriler ve Ready'ler)
    // ==============================================================
    assign m0_bus.axi_awaddr = s0_bus.axi_awaddr;
    assign m1_bus.axi_awaddr = s0_bus.axi_awaddr;
    assign m2_bus.axi_awaddr = s0_bus.axi_awaddr;
    assign m3_bus.axi_awaddr = s0_bus.axi_awaddr;

    assign m0_bus.axi_wdata  = s0_bus.axi_wdata;
    assign m1_bus.axi_wdata  = s0_bus.axi_wdata;
    assign m2_bus.axi_wdata  = s0_bus.axi_wdata;
    assign m3_bus.axi_wdata  = s0_bus.axi_wdata;

    assign m0_bus.axi_araddr = s0_bus.axi_araddr;
    assign m1_bus.axi_araddr = s0_bus.axi_araddr;
    assign m2_bus.axi_araddr = s0_bus.axi_araddr;
    assign m3_bus.axi_araddr = s0_bus.axi_araddr;

    assign m0_bus.axi_bready = s0_bus.axi_bready;
    assign m1_bus.axi_bready = s0_bus.axi_bready;
    assign m2_bus.axi_bready = s0_bus.axi_bready;
    assign m3_bus.axi_bready = s0_bus.axi_bready;

    assign m0_bus.axi_rready = s0_bus.axi_rready;
    assign m1_bus.axi_rready = s0_bus.axi_rready;
    assign m2_bus.axi_rready = s0_bus.axi_rready;
    assign m3_bus.axi_rready = s0_bus.axi_rready;


    // ==============================================================
    // 3. DEMULTIPLEXER (Maskelenerek Gidenler: Valid Sinyalleri)
    // ==============================================================
    // Eğer o modül seçilmediyse, VALID sinyali zorla 0 yapılır (Latch oluşmaz)
    assign m0_bus.axi_awvalid = s0_bus.axi_awvalid & sel_timer_aw;
    assign m1_bus.axi_awvalid = s0_bus.axi_awvalid & sel_gpio_aw;
    assign m2_bus.axi_awvalid = s0_bus.axi_awvalid & sel_i2c_aw;
    assign m3_bus.axi_awvalid = s0_bus.axi_awvalid & sel_qspi_aw;

    assign m0_bus.axi_wvalid  = s0_bus.axi_wvalid & sel_timer_aw;
    assign m1_bus.axi_wvalid  = s0_bus.axi_wvalid & sel_gpio_aw;
    assign m2_bus.axi_wvalid  = s0_bus.axi_wvalid & sel_i2c_aw;
    assign m3_bus.axi_wvalid  = s0_bus.axi_wvalid & sel_qspi_aw;

    assign m0_bus.axi_arvalid = s0_bus.axi_arvalid & sel_timer_ar;
    assign m1_bus.axi_arvalid = s0_bus.axi_arvalid & sel_gpio_ar;
    assign m2_bus.axi_arvalid = s0_bus.axi_arvalid & sel_i2c_ar;
    assign m3_bus.axi_arvalid = s0_bus.axi_arvalid & sel_qspi_ar;


    // ==============================================================
    // 4. MULTIPLEXER (Toplanarak İşlemciye Dönenler)
    // ==============================================================
    
    // AWREADY MUX
    assign s0_bus.axi_awready = sel_timer_aw ? m0_bus.axi_awready :
                                sel_gpio_aw  ? m1_bus.axi_awready :
                                sel_i2c_aw   ? m2_bus.axi_awready :
                                sel_qspi_aw  ? m3_bus.axi_awready : 1'b0;

    // WREADY MUX
    assign s0_bus.axi_wready  = sel_timer_aw ? m0_bus.axi_wready :
                                sel_gpio_aw  ? m1_bus.axi_wready :
                                sel_i2c_aw   ? m2_bus.axi_wready :
                                sel_qspi_aw  ? m3_bus.axi_wready : 1'b0;

    // BVALID & BRESP MUX
    assign s0_bus.axi_bvalid  = sel_timer_aw ? m0_bus.axi_bvalid :
                                sel_gpio_aw  ? m1_bus.axi_bvalid :
                                sel_i2c_aw   ? m2_bus.axi_bvalid :
                                sel_qspi_aw  ? m3_bus.axi_bvalid : 1'b0;

    assign s0_bus.axi_bresp   = sel_timer_aw ? m0_bus.axi_bresp :
                                sel_gpio_aw  ? m1_bus.axi_bresp :
                                sel_i2c_aw   ? m2_bus.axi_bresp :
                                sel_qspi_aw  ? m3_bus.axi_bresp : 2'b00;

    // ARREADY MUX
    assign s0_bus.axi_arready = sel_timer_ar ? m0_bus.axi_arready :
                                sel_gpio_ar  ? m1_bus.axi_arready :
                                sel_i2c_ar   ? m2_bus.axi_arready :
                                sel_qspi_ar  ? m3_bus.axi_arready : 1'b0;

    // RVALID, RDATA & RRESP MUX
    assign s0_bus.axi_rvalid  = sel_timer_ar ? m0_bus.axi_rvalid :
                                sel_gpio_ar  ? m1_bus.axi_rvalid :
                                sel_i2c_ar   ? m2_bus.axi_rvalid :
                                sel_qspi_ar  ? m3_bus.axi_rvalid : 1'b0;

    assign s0_bus.axi_rdata   = sel_timer_ar ? m0_bus.axi_rdata :
                                sel_gpio_ar  ? m1_bus.axi_rdata :
                                sel_i2c_ar   ? m2_bus.axi_rdata :
                                sel_qspi_ar  ? m3_bus.axi_rdata : 32'h0;

    assign s0_bus.axi_rresp   = sel_timer_ar ? m0_bus.axi_rresp :
                                sel_gpio_ar  ? m1_bus.axi_rresp :
                                sel_i2c_ar   ? m2_bus.axi_rresp :
                                sel_qspi_ar  ? m3_bus.axi_rresp : 2'b00;

endmodule