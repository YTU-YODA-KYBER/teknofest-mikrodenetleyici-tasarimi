module Instr_Splitter
(
    // ==========================
    //  GİRİŞ PORTLARI
    // ==========================
    input  logic [31:0] axi_araddr,
    input  logic        axi_arvalid,
    output logic        axi_arready,

    input  logic        axi_rready,
    output logic [31:0] axi_rdata,
    output logic [ 1:0] axi_rresp,
    output logic        axi_rvalid,


    // =========================
    // INSTRUCTION RAM PORTLARI
    // =========================
    output logic [31:0] i_araddr,
    output logic        i_arvalid,
    input  logic        i_arready,

    output logic        i_rready,
    input  logic [31:0] i_rdata,
    input  logic [ 1:0] i_rresp,
    input  logic        i_rvalid,

    // =========================
    // BOOT RAM PORTLARI
    // =========================
    output logic [31:0] b_araddr,
    output logic        b_arvalid,
    input  logic        b_arready,

    output logic        b_rready,
    input  logic [31:0] b_rdata,
    input  logic [ 1:0] b_rresp,
    input  logic        b_rvalid
);

    logic boot_ram_read;
    logic instruction_ram_read;

    // Simülasyon için
    assign boot_ram_read        = (axi_araddr >= 32'h0000_0000) && (axi_araddr < 32'h0001_0000);
    assign instruction_ram_read = (axi_araddr >= 32'h1000_0000) && (axi_araddr < 32'h1001_0000);

    // Normali
    //assign boot_ram_read        = (axi_araddr >= 32'h1000_0000) && (axi_araddr < 32'h1001_0000);
    //assign instruction_ram_read = (axi_araddr >= 32'h0000_0000) && (axi_araddr < 32'h0001_0000);

    assign b_araddr  = axi_araddr; 
    assign i_araddr  = axi_araddr;

    assign b_arvalid = boot_ram_read ? axi_arvalid : 1'b0;
    assign i_arvalid = instruction_ram_read ? axi_arvalid : 1'b0;

    assign axi_arready   = boot_ram_read        ? b_arready : 
                       instruction_ram_read ? i_arready : 1'b0;

    assign axi_rvalid = b_rvalid | i_rvalid;

    assign axi_rdata  = boot_ram_read        ? b_rdata  : 
                       instruction_ram_read ? i_rdata  : 32'b0;
    assign axi_rresp  = b_rvalid ? b_rresp  : (i_rvalid ? i_rresp  : 2'b00);

    assign b_rready = axi_rready;
    assign i_rready = axi_rready;

endmodule
