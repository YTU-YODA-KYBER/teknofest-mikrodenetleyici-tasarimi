module boot_rom_axi_ctrl #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10, // 2^10 = 1024 derinlik, 1024x32 bit = 4KB BRAM
    parameter INIT_FILE  = "boot_code.mem"
)(

    // BOOT RAM PORTLARI

    input logic clk_i,
    input logic rst_n,

    // AR PORTLARI
    input  logic [31:0]           axi_boot_rom_araddr,
    input  logic                  axi_boot_rom_arvalid,
    output logic                  axi_boot_rom_arready,

    // R PORTLARI
    output logic [DATA_WIDTH-1:0] axi_boot_rom_rdata,
    output logic [1:0]            axi_boot_rom_rresp,
    output logic                  axi_boot_rom_rvalid,
    input  logic                  axi_boot_rom_rready,

    // AR PORTLARI
    input  logic [31:0]           axi_boot_rom_interconnect_araddr,
    input  logic                  axi_boot_rom_interconnect_arvalid,
    output logic                  axi_boot_rom_interconnect_arready,

    // R PORTLARI
    output logic [DATA_WIDTH-1:0] axi_boot_rom_interconnect_rdata,
    output logic [1:0]            axi_boot_rom_interconnect_rresp,
    output logic                  axi_boot_rom_interconnect_rvalid,
    input  logic                  axi_boot_rom_interconnect_rready
);

    logic [ADDR_WIDTH-1:0] raddr_a;
    logic [DATA_WIDTH-1:0] rdata_a;
    logic [DATA_WIDTH-1:0] rdata_latch_a; // sonradan eklendi

    logic [ADDR_WIDTH-1:0] raddr_b;
    logic [DATA_WIDTH-1:0] rdata_b;
    logic [DATA_WIDTH-1:0] rdata_latch_b; // sonradan eklendi

boot_rom #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .INIT_FILE(INIT_FILE)
)
boot_rom(
    .clk(clk_i),
    .raddr_a(raddr_a),
    .rdata_a(rdata_a),
    .raddr_b(raddr_b),
    .rdata_b(rdata_b)
);


assign raddr_a = axi_boot_rom_araddr[ADDR_WIDTH+1:2]; 
assign axi_boot_rom_rdata = rdata_latch_a; // rdata yerine rdata_latch kullanıldı

always_ff @(posedge clk_i or negedge rst_n) begin
    if(rst_n == 0) begin
        rdata_latch_a <= 0;
        axi_boot_rom_rvalid <= 0;
        axi_boot_rom_arready <= 1;
        axi_boot_rom_rresp <= 0;
    end
    else if(axi_boot_rom_arvalid && axi_boot_rom_arready)begin
        rdata_latch_a <= rdata_a;
        axi_boot_rom_rvalid <= 1;
        axi_boot_rom_arready <= 0;
    end
    else if (axi_boot_rom_rvalid && axi_boot_rom_rready)begin
        axi_boot_rom_rvalid <= 0;
        axi_boot_rom_arready <= 1;
    end
end


assign raddr_b = axi_boot_rom_interconnect_araddr[ADDR_WIDTH+1:2]; 
assign axi_boot_rom_interconnect_rdata = rdata_latch_b; // rdata yerine rdata_latch kullanıldı

always_ff @(posedge clk_i or negedge rst_n) begin
    if(rst_n == 0) begin
        rdata_latch_b <= 0;
        axi_boot_rom_interconnect_rvalid <= 0;
        axi_boot_rom_interconnect_arready <= 1;
        axi_boot_rom_interconnect_rresp <= 0;
    end
    else if(axi_boot_rom_interconnect_arvalid && axi_boot_rom_interconnect_arready)begin
        rdata_latch_b <= rdata_b;
        axi_boot_rom_interconnect_rvalid <= 1;
        axi_boot_rom_interconnect_arready <= 0;
    end
    else if (axi_boot_rom_interconnect_rvalid && axi_boot_rom_interconnect_rready)begin
        axi_boot_rom_interconnect_rvalid <= 0;
        axi_boot_rom_interconnect_arready <= 1;
    end
end
endmodule