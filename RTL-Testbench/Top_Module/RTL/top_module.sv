module top_module #(
    parameter DATA_WIDTH_boot = 32,
    parameter ADDR_WIDTH_boot = 10,                 // 2^10 = 1024 kelime, yani 4KB boot ROM
    parameter INIT_FILE_boot = "firmware.hex",
    parameter DATA_WIDTH_instr = 32,
    parameter ADDR_WIDTH_instr = 11,                // 2^11 = 2048 kelime, yani 8KB instruction RAM
    parameter DATA_WIDTH_data = 32,
    parameter ADDR_WIDTH_data = 11,                 // 2^11 = 2048 kelime, yani 8KB data RAM


    parameter logic [31:0] boot_addr         = 32'h0000_0000,   //BASLANGIC ADRESI
    parameter logic [31:0] mtvec_addr        = 32'h1F00_0000,   //INTERRUPT GELDIGINDE ISLEMCININ ATLAYACAGI ADRES
    parameter logic [31:0] dm_halt_addr      = 32'h2F0_0000,    //JTAG KULLANILMAK ISTENDIGINDE ISLEMCISNIN ATLAYACAGI ADRES
    parameter logic [31:0] hart_id           = 32'h0000_0000,   //CEKIRDEGIN NUMARASI(TEK CEKIRDEK OLDUGU ICIN DIREKT 0 YAZDIK)
    parameter logic [31:0] dm_exception_addr = 32'h3F00_0000    //JTAG KULLANILIRKEN HATA OLUSULURSA ISLEMCININ ATLAYACAGI ADRES
)(

    input logic clk_i,
    input logic rst_ni,

    input  logic rx,
    output logic tx,

    input  logic [31:0] interrupt_i,
    output logic [ 4:0] interrupt_id,
    output logic        interrupt_ack,

    input  logic [31:0] GPIO_IDR,
    output logic [31:0] GPIO_ODR,

    output logic I2C_SCL,
    inout  logic I2C_SDA,

    output logic QSPI_SCLK,
    output logic QSPI_CS,
    inout  logic QSPI_IO0,
    inout  logic QSPI_IO1,
    inout  logic QSPI_IO2,
    inout  logic QSPI_IO3


);
    
    //  INSTRUCTION AR PORTLARI
    logic [31:0] cpu_instr_araddr;
    logic        cpu_instr_arvalid;
    logic        cpu_instr_arready;
    //  INSTRUCTION R PORTLARI
    logic        cpu_instr_rready;
    logic [31:0] cpu_instr_rdata;
    logic [ 1:0] cpu_instr_rresp;
    logic        cpu_instr_rvalid;
    //  INSTRUCTION AW PORTLARI
    logic [31:0] cpu_instr_awaddr;
    logic        cpu_instr_awvalid;
    logic        cpu_instr_awready;
    //  INSTRUCTION W PORTLARI
    logic [31:0] cpu_instr_wdata;
    logic        cpu_instr_wvalid;
    logic        cpu_instr_wready;
    //  INSTRUCTION B PORTLARI
    logic        cpu_instr_bready;
    logic [ 1:0] cpu_instr_bresp;
    logic        cpu_instr_bvalid;


    //  DATA AR PORTLARI
    logic [31:0] cpu_data_araddr;
    logic        cpu_data_arvalid;
    logic        cpu_data_arready;
    //  DATA R PORTLARI
    logic        cpu_data_rready;
    logic [31:0] cpu_data_rdata;
    logic [ 1:0] cpu_data_rresp;
    logic        cpu_data_rvalid;
    //  DATA AW PORTLARI
    logic [31:0] cpu_data_awaddr;
    logic        cpu_data_awvalid;
    logic        cpu_data_awready;
    //  DATA W PORTLARI
    logic [31:0] cpu_data_wdata;
    logic        cpu_data_wvalid;
    logic        cpu_data_wready;
    //  DATA B PORTLARI
    logic        cpu_data_bready;
    logic [ 1:0] cpu_data_bresp;
    logic        cpu_data_bvalid;




    // AW Portları
    logic [31:0] TIMER_awaddr;
    logic        TIMER_awvalid;
    logic        TIMER_awready;
    // W Portları
    logic [31:0] TIMER_wdata;
    logic        TIMER_wvalid;
    logic        TIMER_wready;
    // B Portları
    logic [ 1:0] TIMER_bresp;
    logic        TIMER_bvalid;
    logic        TIMER_bready;
    // AR Portları
    logic [31:0] TIMER_araddr;
    logic        TIMER_arvalid;
    logic        TIMER_arready;
    // R Portları
    logic        TIMER_rready;
    logic [31:0] TIMER_rdata;
    logic [ 1:0] TIMER_rresp;
    logic        TIMER_rvalid;

    // AW Portları
    logic [31:0] UART_awaddr;
    logic        UART_awvalid;
    logic        UART_awready;
    // W Portları
    logic [31:0] UART_wdata;
    logic        UART_wvalid;
    logic        UART_wready;
    // B Portları
    logic [ 1:0] UART_bresp;
    logic        UART_bvalid;
    logic        UART_bready;
    // AR Portları
    logic [31:0] UART_araddr;
    logic        UART_arvalid;
    logic        UART_arready;
    // R Portları
    logic        UART_rready;
    logic [31:0] UART_rdata;
    logic [ 1:0] UART_rresp;
    logic        UART_rvalid;



    // WRITE ADDRESS kanalları
    logic [31:0] QSPI_awaddr;
    logic        QSPI_awvalid;
    logic        QSPI_awready;
    // WRITE DATA kanalları
    logic [31:0] QSPI_wdata;
    logic        QSPI_wvalid;
    logic        QSPI_wready;
    // WRITE RESPONSE kanalları
    logic [ 1:0] QSPI_bresp;
    logic        QSPI_bvalid;
    logic        QSPI_bready;
    // READ ADDRESS kanalları
    logic [31:0] QSPI_araddr;
    logic        QSPI_arvalid;
    logic        QSPI_arready;
    // READ DATA kanalları
    logic        QSPI_rready;
    logic [31:0] QSPI_rdata;
    logic [ 1:0] QSPI_rresp;
    logic        QSPI_rvalid;


    // AW Portları
    logic [31:0] I2C_awaddr;
    logic        I2C_awvalid;
    logic        I2C_awready;
    // W Portları
    logic [31:0] I2C_wdata;
    logic        I2C_wvalid;
    logic        I2C_wready;
    // B Portları
    logic [ 1:0] I2C_bresp;
    logic        I2C_bvalid;
    logic        I2C_bready;
    // AR Portları
    logic [31:0] I2C_araddr;
    logic        I2C_arvalid;
    logic        I2C_arready;
    // R Portları
    logic        I2C_rready;
    logic [31:0] I2C_rdata;
    logic [ 1:0] I2C_rresp;
    logic        I2C_rvalid;

    // AW Portları
    logic [31:0] GPIO_awaddr;
    logic        GPIO_awvalid;
    logic        GPIO_awready;
    // W Portları
    logic [31:0] GPIO_wdata;
    logic        GPIO_wvalid;
    logic        GPIO_wready;
    // B Portları
    logic [ 1:0] GPIO_bresp;
    logic        GPIO_bvalid;
    logic        GPIO_bready;
    // AR Portları
    logic [31:0] GPIO_araddr;
    logic        GPIO_arvalid;
    logic        GPIO_arready;
    // R Portları
    logic        GPIO_rready;
    logic [31:0] GPIO_rdata;
    logic [ 1:0] GPIO_rresp;
    logic        GPIO_rvalid;


    logic [31:0] axi_boot_rom_araddr;
    logic        axi_boot_rom_arvalid;
    logic        axi_boot_rom_arready;
    logic [31:0] axi_boot_rom_rdata;
    logic [ 1:0] axi_boot_rom_rresp;
    logic        axi_boot_rom_rvalid;
    logic        axi_boot_rom_rready;

    logic [31:0] axi_boot_rom_interconnect_araddr;
    logic        axi_boot_rom_interconnect_arvalid;
    logic        axi_boot_rom_interconnect_arready;
    logic [31:0] axi_boot_rom_interconnect_rdata;
    logic [ 1:0] axi_boot_rom_interconnect_rresp;
    logic        axi_boot_rom_interconnect_rvalid;
    logic        axi_boot_rom_interconnect_rready;

    logic [31:0] axi_instr_bram_araddr;
    logic        axi_instr_bram_arvalid;
    logic        axi_instr_bram_arready;
    logic [31:0] axi_instr_bram_rdata;
    logic [ 1:0] axi_instr_bram_rresp;
    logic        axi_instr_bram_rvalid;
    logic        axi_instr_bram_rready;
    logic [31:0] axi_instr_bram_awaddr;
    logic        axi_instr_bram_awvalid;
    logic        axi_instr_bram_awready;
    logic [31:0] axi_instr_bram_wdata;
    logic        axi_instr_bram_wvalid;
    logic        axi_instr_bram_wready;
    logic [ 1:0] axi_instr_bram_bresp;
    logic        axi_instr_bram_bvalid;
    logic        axi_instr_bram_bready;


    logic [31:0] axi_data_bram_awaddr;
    logic        axi_data_bram_awvalid;
    logic        axi_data_bram_awready;
    logic [31:0] axi_data_bram_wdata;
    logic        axi_data_bram_wvalid;
    logic        axi_data_bram_wready;
    logic [ 1:0] axi_data_bram_bresp;
    logic        axi_data_bram_bvalid;
    logic        axi_data_bram_bready;
    logic [31:0] axi_data_bram_araddr;
    logic        axi_data_bram_arvalid;
    logic        axi_data_bram_arready;
    logic [31:0] axi_data_bram_rdata;
    logic [ 1:0] axi_data_bram_rresp;
    logic        axi_data_bram_rvalid;
    logic        axi_data_bram_rready;



boot_rom_axi_ctrl #(
    .DATA_WIDTH(DATA_WIDTH_boot),
    .ADDR_WIDTH(ADDR_WIDTH_boot),
    .INIT_FILE(INIT_FILE_boot)
) boot_rom_ctrl_inst(
    .clk_i(clk_i),
    .rst_n(rst_ni),

    .axi_boot_rom_araddr (axi_boot_rom_araddr),
    .axi_boot_rom_arvalid(axi_boot_rom_arvalid),
    .axi_boot_rom_arready(axi_boot_rom_arready),

    .axi_boot_rom_rdata (axi_boot_rom_rdata),
    .axi_boot_rom_rresp (axi_boot_rom_rresp),
    .axi_boot_rom_rvalid(axi_boot_rom_rvalid),
    .axi_boot_rom_rready(axi_boot_rom_rready),

    .axi_boot_rom_interconnect_araddr (axi_boot_rom_interconnect_araddr),
    .axi_boot_rom_interconnect_arvalid(axi_boot_rom_interconnect_arvalid), 
    .axi_boot_rom_interconnect_arready(axi_boot_rom_interconnect_arready),
    .axi_boot_rom_interconnect_rdata  (axi_boot_rom_interconnect_rdata),
    .axi_boot_rom_interconnect_rresp  (axi_boot_rom_interconnect_rresp),
    .axi_boot_rom_interconnect_rvalid (axi_boot_rom_interconnect_rvalid),
    .axi_boot_rom_interconnect_rready (axi_boot_rom_interconnect_rready)
);

instr_bram_axi_ctrl #(
    .DATA_WIDTH(DATA_WIDTH_instr),
    .ADDR_WIDTH(ADDR_WIDTH_instr)
) instr_bram_ctrl_inst(
    .clk_i(clk_i),
    .rst_n(rst_ni),

    .axi_instr_bram_araddr (axi_instr_bram_araddr),
    .axi_instr_bram_arvalid(axi_instr_bram_arvalid),
    .axi_instr_bram_arready(axi_instr_bram_arready),

    .axi_instr_bram_rdata  (axi_instr_bram_rdata),
    .axi_instr_bram_rresp  (axi_instr_bram_rresp),
    .axi_instr_bram_rvalid (axi_instr_bram_rvalid),
    .axi_instr_bram_rready (axi_instr_bram_rready),

    .axi_instr_bram_awaddr (axi_instr_bram_awaddr),
    .axi_instr_bram_awvalid(axi_instr_bram_awvalid),
    .axi_instr_bram_awready(axi_instr_bram_awready),

    .axi_instr_bram_wdata  (axi_instr_bram_wdata),
    .axi_instr_bram_wvalid (axi_instr_bram_wvalid),
    .axi_instr_bram_wready (axi_instr_bram_wready),

    .axi_instr_bram_bresp  (axi_instr_bram_bresp),
    .axi_instr_bram_bvalid (axi_instr_bram_bvalid),
    .axi_instr_bram_bready (axi_instr_bram_bready)
);

data_bram_axi_ctrl #(
    .DATA_WIDTH(DATA_WIDTH_data),
    .ADDR_WIDTH(ADDR_WIDTH_data)
) data_bram_ctrl_inst(
    .clk_i (clk_i),
    .rst_n(rst_ni),

    .axi_data_bram_araddr (axi_data_bram_araddr),
    .axi_data_bram_arvalid(axi_data_bram_arvalid),
    .axi_data_bram_arready(axi_data_bram_arready),

    .axi_data_bram_rdata  (axi_data_bram_rdata),
    .axi_data_bram_rresp  (axi_data_bram_rresp),
    .axi_data_bram_rvalid (axi_data_bram_rvalid),
    .axi_data_bram_rready (axi_data_bram_rready),

    .axi_data_bram_awaddr (axi_data_bram_awaddr),
    .axi_data_bram_awvalid(axi_data_bram_awvalid),
    .axi_data_bram_awready(axi_data_bram_awready),

    .axi_data_bram_wdata  (axi_data_bram_wdata),
    .axi_data_bram_wvalid (axi_data_bram_wvalid),
    .axi_data_bram_wready (axi_data_bram_wready),

    .axi_data_bram_bresp  (axi_data_bram_bresp),
    .axi_data_bram_bvalid (axi_data_bram_bvalid),
    .axi_data_bram_bready (axi_data_bram_bready)
);

cv32e40p_obi_to_axi_wrapper #(
    .boot_addr        (boot_addr),
    .mtvec_addr       (mtvec_addr),
    .dm_halt_addr     (dm_halt_addr),
    .hart_id          (hart_id),
    .dm_exception_addr(dm_exception_addr)

)cpu(

    .clk_i (clk_i),
    .rst_ni(rst_ni),

    // INTERRUPT PORTLARI
    .interrupt_i  (interrupt_i),
    .interrupt_ack(interrupt_ack),
    .interrupt_id (interrupt_id),

    //  INSTRUCTION AW PORTLARI
    .axi_instr_awaddr (cpu_instr_awaddr),
    .axi_instr_awvalid(cpu_instr_awvalid),
    .axi_instr_awready(cpu_instr_awready),
    //  INSTRUCTION W PORTLARI
    .axi_instr_wdata  (cpu_instr_wdata),
    .axi_instr_wvalid (cpu_instr_wvalid),
    .axi_instr_wready (cpu_instr_wready),
    //  INSTRUCTION B PORTLARI
    .axi_instr_bresp  (cpu_instr_bresp),
    .axi_instr_bvalid (cpu_instr_bvalid),
    .axi_instr_bready (cpu_instr_bready),
    //  INSTRUCTION AR PORTLARI
    .axi_instr_araddr (cpu_instr_araddr),
    .axi_instr_arvalid(cpu_instr_arvalid),
    .axi_instr_arready(cpu_instr_arready),
    //  INSTRUCTION R PORTLARI
    .axi_instr_rready (cpu_instr_rready),
    .axi_instr_rdata  (cpu_instr_rdata),
    .axi_instr_rresp  (cpu_instr_rresp),
    .axi_instr_rvalid (cpu_instr_rvalid),

    //  DATA AW PORTLARI
    .axi_data_awaddr  (cpu_data_awaddr),
    .axi_data_awvalid (cpu_data_awvalid),
    .axi_data_awready (cpu_data_awready),
    //  DATA W PORTLARI
    .axi_data_wdata   (cpu_data_wdata),
    .axi_data_wvalid  (cpu_data_wvalid),
    .axi_data_wready  (cpu_data_wready),
    //  DATA B PORTLARI
    .axi_data_bresp   (cpu_data_bresp),
    .axi_data_bvalid  (cpu_data_bvalid),
    .axi_data_bready  (cpu_data_bready),
    //  DATA AR PORTLARI
    .axi_data_araddr  (cpu_data_araddr),
    .axi_data_arvalid (cpu_data_arvalid),
    .axi_data_arready (cpu_data_arready),
    //  DATA R PORTLARI
    .axi_data_rready  (cpu_data_rready),
    .axi_data_rdata   (cpu_data_rdata),
    .axi_data_rresp   (cpu_data_rresp),
    .axi_data_rvalid  (cpu_data_rvalid)

);
AXI4_Interconnect connect(

    .clk_i(clk_i),
    .rst_ni(rst_ni),

    // ==============================================================
    // SLAVE 0: CPU DATA PORTLARI (AXI4)
    // ==============================================================
    .axi_s0_awaddr (cpu_data_awaddr),
    .axi_s0_awvalid(cpu_data_awvalid),
    .axi_s0_awready(cpu_data_awready),
    .axi_s0_wdata  (cpu_data_wdata),
    .axi_s0_wvalid (cpu_data_wvalid),
    .axi_s0_wready (cpu_data_wready),
    .axi_s0_bresp  (cpu_data_bresp),
    .axi_s0_bvalid (cpu_data_bvalid),
    .axi_s0_bready (cpu_data_bready),
    .axi_s0_araddr (cpu_data_araddr),
    .axi_s0_arvalid(cpu_data_arvalid),
    .axi_s0_arready(cpu_data_arready),
    .axi_s0_rdata  (cpu_data_rdata),
    .axi_s0_rresp  (cpu_data_rresp),
    .axi_s0_rvalid (cpu_data_rvalid),
    .axi_s0_rready (cpu_data_rready),

    // ==============================================================
    // MASTER 0: TIMER PORTLARI (AXI4-Lite) - Base: 0x4000_0000
    // ==============================================================
    .axi_m0_awaddr (TIMER_awaddr),
    .axi_m0_awvalid(TIMER_awvalid),
    .axi_m0_awready(TIMER_awready),
    .axi_m0_wdata  (TIMER_wdata),
    .axi_m0_wvalid (TIMER_wvalid),
    .axi_m0_wready (TIMER_wready),
    .axi_m0_bresp  (TIMER_bresp),
    .axi_m0_bvalid (TIMER_bvalid),
    .axi_m0_bready (TIMER_bready),
    .axi_m0_araddr (TIMER_araddr),
    .axi_m0_arvalid(TIMER_arvalid),
    .axi_m0_arready(TIMER_arready),
    .axi_m0_rdata  (TIMER_rdata),
    .axi_m0_rresp  (TIMER_rresp),
    .axi_m0_rvalid (TIMER_rvalid),
    .axi_m0_rready (TIMER_rready),

    // ==============================================================
    // MASTER 1: GPIO PORTLARI (AXI4-Lite) - Base: 0x4001_0000
    // ==============================================================
    .axi_m1_awaddr (GPIO_awaddr),
    .axi_m1_awvalid(GPIO_awvalid),
    .axi_m1_awready(GPIO_awready),
    .axi_m1_wdata  (GPIO_wdata),
    .axi_m1_wvalid (GPIO_wvalid),
    .axi_m1_wready (GPIO_wready),
    .axi_m1_bresp  (GPIO_bresp),
    .axi_m1_bvalid (GPIO_bvalid),
    .axi_m1_bready (GPIO_bready),
    .axi_m1_araddr (GPIO_araddr),
    .axi_m1_arvalid(GPIO_arvalid),
    .axi_m1_arready(GPIO_arready),
    .axi_m1_rdata  (GPIO_rdata),
    .axi_m1_rresp  (GPIO_rresp),
    .axi_m1_rvalid (GPIO_rvalid),
    .axi_m1_rready (GPIO_rready),

    // ==============================================================
    // MASTER 2: I2C PORTLARI (AXI4-Lite) - Base: 0x4002_0000
    // ==============================================================
    .axi_m2_awaddr (I2C_awaddr),
    .axi_m2_awvalid(I2C_awvalid),
    .axi_m2_awready(I2C_awready),
    .axi_m2_wdata  (I2C_wdata),
    .axi_m2_wvalid (I2C_wvalid),
    .axi_m2_wready (I2C_wready),
    .axi_m2_bresp  (I2C_bresp),
    .axi_m2_bvalid (I2C_bvalid),
    .axi_m2_bready (I2C_bready),
    .axi_m2_araddr (I2C_araddr),
    .axi_m2_arvalid(I2C_arvalid),
    .axi_m2_arready(I2C_arready),
    .axi_m2_rdata  (I2C_rdata),
    .axi_m2_rresp  (I2C_rresp),
    .axi_m2_rvalid (I2C_rvalid),
    .axi_m2_rready (I2C_rready),

    // ==============================================================
    // MASTER 3: QSPI PORTLARI (AXI4-Lite) - Base: 0x4003_0000
    // ==============================================================
    .axi_m3_awaddr (QSPI_awaddr),
    .axi_m3_awvalid(QSPI_awvalid),
    .axi_m3_awready(QSPI_awready),
    .axi_m3_wdata  (QSPI_wdata),
    .axi_m3_wvalid (QSPI_wvalid),
    .axi_m3_wready (QSPI_wready),
    .axi_m3_bresp  (QSPI_bresp),
    .axi_m3_bvalid (QSPI_bvalid),
    .axi_m3_bready (QSPI_bready),
    .axi_m3_araddr (QSPI_araddr),
    .axi_m3_arvalid(QSPI_arvalid),
    .axi_m3_arready(QSPI_arready),
    .axi_m3_rdata  (QSPI_rdata),
    .axi_m3_rresp  (QSPI_rresp),
    .axi_m3_rvalid (QSPI_rvalid),
    .axi_m3_rready (QSPI_rready),

    // ==============================================================
    // MASTER 4: UART PORTLARI (AXI4-Lite) - Base: 0x4004_0000
    // ==============================================================
    .axi_m4_awaddr (UART_awaddr),
    .axi_m4_awvalid(UART_awvalid),
    .axi_m4_awready(UART_awready),
    .axi_m4_wdata  (UART_wdata),
    .axi_m4_wvalid (UART_wvalid),
    .axi_m4_wready (UART_wready),
    .axi_m4_bresp  (UART_bresp),
    .axi_m4_bvalid (UART_bvalid),
    .axi_m4_bready (UART_bready),
    .axi_m4_araddr (UART_araddr),
    .axi_m4_arvalid(UART_arvalid),
    .axi_m4_arready(UART_arready),
    .axi_m4_rdata  (UART_rdata),
    .axi_m4_rresp  (UART_rresp),
    .axi_m4_rvalid (UART_rvalid),
    .axi_m4_rready (UART_rready),

    // ==============================================================
    // MASTER 5: DATA RAM PORTLARI (AXI4-Lite) - Base: 0x2000_0000
    // ==============================================================
    .axi_m5_awaddr (axi_data_bram_awaddr),
    .axi_m5_awvalid(axi_data_bram_awvalid),
    .axi_m5_awready(axi_data_bram_awready),
    .axi_m5_wdata  (axi_data_bram_wdata),
    .axi_m5_wvalid (axi_data_bram_wvalid),
    .axi_m5_wready (axi_data_bram_wready),
    .axi_m5_bresp  (axi_data_bram_bresp),
    .axi_m5_bvalid (axi_data_bram_bvalid),
    .axi_m5_bready (axi_data_bram_bready),
    .axi_m5_araddr (axi_data_bram_araddr),
    .axi_m5_arvalid(axi_data_bram_arvalid),
    .axi_m5_arready(axi_data_bram_arready),
    .axi_m5_rdata  (axi_data_bram_rdata),
    .axi_m5_rresp  (axi_data_bram_rresp),
    .axi_m5_rvalid (axi_data_bram_rvalid),
    .axi_m5_rready (axi_data_bram_rready),

    // ==============================================================
    // MASTER 6: INSTRUCTION RAM PORTLARI (AXI4-Lite) - Base: 0x0000_0000
    // ==============================================================
    .axi_m6_awaddr (axi_instr_bram_awaddr),
    .axi_m6_awvalid(axi_instr_bram_awvalid),
    .axi_m6_awready(axi_instr_bram_awready),
    .axi_m6_wdata  (axi_instr_bram_wdata),
    .axi_m6_wvalid (axi_instr_bram_wvalid),
    .axi_m6_wready (axi_instr_bram_wready),
    .axi_m6_bresp  (axi_instr_bram_bresp),
    .axi_m6_bvalid (axi_instr_bram_bvalid),
    .axi_m6_bready (axi_instr_bram_bready),

    // ==============================================================
    // MASTER 7: BOOT RAM PORTLARI (AXI4-Lite) - Base: 0x0000_0000
    // ==============================================================
    .axi_m7_araddr (axi_boot_rom_interconnect_araddr),
    .axi_m7_arvalid(axi_boot_rom_interconnect_arvalid),
    .axi_m7_arready(axi_boot_rom_interconnect_arready),
    .axi_m7_rdata  (axi_boot_rom_interconnect_rdata),
    .axi_m7_rresp  (axi_boot_rom_interconnect_rresp),
    .axi_m7_rvalid (axi_boot_rom_interconnect_rvalid),
    .axi_m7_rready (axi_boot_rom_interconnect_rready)

);

Timer_module timer_inst(

    .clk_i(clk_i),
    .rst_n(rst_ni),

    .awaddr (TIMER_awaddr),
    .awvalid(TIMER_awvalid),
    .awready(TIMER_awready),
    .wdata  (TIMER_wdata),
    .wvalid (TIMER_wvalid),
    .wready (TIMER_wready),
    .bresp  (TIMER_bresp),
    .bvalid (TIMER_bvalid),
    .bready (TIMER_bready),
    .araddr (TIMER_araddr),
    .arvalid(TIMER_arvalid),
    .arready(TIMER_arready),
    .rready (TIMER_rready),
    .rdata  (TIMER_rdata),
    .rresp  (TIMER_rresp),
    .rvalid (TIMER_rvalid)
);

Uart_TX uart_inst(
    .clk(clk_i),
    .rst_n(rst_ni),

    .awaddr (UART_awaddr),
    .awvalid(UART_awvalid),
    .awready(UART_awready),
    .wdata  (UART_wdata),
    .wvalid (UART_wvalid),
    .wready (UART_wready),
    .bresp  (UART_bresp),
    .bvalid (UART_bvalid),
    .bready (UART_bready),
    .araddr (UART_araddr),
    .arvalid(UART_arvalid),
    .arready(UART_arready),
    .rready (UART_rready),
    .rdata  (UART_rdata),
    .rresp  (UART_rresp),
    .rvalid (UART_rvalid),

    // UART Portları
    .rx(rx),
    .tx(tx)
);



I2C_Master_AXI4_Lite i2c_master(
    .clk_i(clk_i),
    .rst_n(rst_ni),

    .awaddr (I2C_awaddr),
    .awvalid(I2C_awvalid),
    .awready(I2C_awready),
    .wdata  (I2C_wdata),
    .wvalid (I2C_wvalid),
    .wready (I2C_wready),
    .bresp  (I2C_bresp),
    .bvalid (I2C_bvalid),
    .bready (I2C_bready),
    .araddr (I2C_araddr),
    .arvalid(I2C_arvalid),
    .arready(I2C_arready),
    .rready (I2C_rready),
    .rdata  (I2C_rdata),
    .rresp  (I2C_rresp),
    .rvalid (I2C_rvalid),

    // I/O Portları
    .I2C_SCL(I2C_SCL),
    .I2C_SDA(I2C_SDA)
);


GPIO_AXI4_Lite gpio(
    .clk_i(clk_i),
    .rst_n(rst_ni),

    .awaddr (GPIO_awaddr),
    .awvalid(GPIO_awvalid),
    .awready(GPIO_awready),
    .wdata  (GPIO_wdata),
    .wvalid (GPIO_wvalid),
    .wready (GPIO_wready),
    .bresp  (GPIO_bresp),
    .bvalid (GPIO_bvalid),
    .bready (GPIO_bready),
    .araddr (GPIO_araddr),
    .arvalid(GPIO_arvalid),
    .arready(GPIO_arready),
    .rready (GPIO_rready),
    .rdata  (GPIO_rdata),
    .rresp  (GPIO_rresp),
    .rvalid (GPIO_rvalid),

    // I/O Portları
    .GPIO_IDR(GPIO_IDR),
    .GPIO_ODR(GPIO_ODR)
);

QSPI_Master_AXI4_Lite qspi_master(
    .clk_i(clk_i),
    .rst_n(rst_ni),

    .awaddr (QSPI_awaddr),
    .awvalid(QSPI_awvalid),
    .awready(QSPI_awready),
    .wdata  (QSPI_wdata),
    .wvalid (QSPI_wvalid),
    .wready (QSPI_wready),
    .bresp  (QSPI_bresp),
    .bvalid (QSPI_bvalid),
    .bready (QSPI_bready),
    .araddr (QSPI_araddr),
    .arvalid(QSPI_arvalid),
    .arready(QSPI_arready),
    .rready (QSPI_rready),
    .rdata  (QSPI_rdata),
    .rresp  (QSPI_rresp),
    .rvalid (QSPI_rvalid),

    // QSPI Portları
    .QSPI_SCLK(QSPI_SCLK),
    .QSPI_CS  (QSPI_CS),
    .QSPI_IO0 (QSPI_IO0),
    .QSPI_IO1 (QSPI_IO1),
    .QSPI_IO2 (QSPI_IO2),
    .QSPI_IO3 (QSPI_IO3)
);


Instr_Splitter instr_splitter(
    // ==========================
    //  GİRİŞ PORTLARI
    // ==========================
    .axi_araddr (cpu_instr_araddr),
    .axi_arvalid(cpu_instr_arvalid),
    .axi_arready(cpu_instr_arready),
    .axi_rready (cpu_instr_rready),
    .axi_rdata  (cpu_instr_rdata),
    .axi_rresp  (cpu_instr_rresp),
    .axi_rvalid (cpu_instr_rvalid),

    // =========================
    // INSTRUCTION RAM PORTLARI
    // =========================
    .i_araddr (axi_instr_bram_araddr),
    .i_arvalid(axi_instr_bram_arvalid),
    .i_arready(axi_instr_bram_arready),
    .i_rready (axi_instr_bram_rready),
    .i_rdata  (axi_instr_bram_rdata),
    .i_rresp  (axi_instr_bram_rresp),
    .i_rvalid (axi_instr_bram_rvalid),

    // =========================
    // BOOT RAM PORTLARI
    // =========================
    .b_araddr (axi_boot_rom_araddr),
    .b_arvalid(axi_boot_rom_arvalid),
    .b_arready(axi_boot_rom_arready),
    .b_rready (axi_boot_rom_rready),
    .b_rdata  (axi_boot_rom_rdata),
    .b_rresp  (axi_boot_rom_rresp),
    .b_rvalid (axi_boot_rom_rvalid)
);


endmodule
