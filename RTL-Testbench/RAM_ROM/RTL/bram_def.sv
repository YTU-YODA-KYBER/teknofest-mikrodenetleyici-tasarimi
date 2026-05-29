module bram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10 // 2^10 = 1024 derinlik, 1024x32 bit = 4KB BRAM
)(
    input  logic                  clk,
    
    // Yazma Portu (Write Port)
    input  logic                  we,      // Write Enable
    input  logic [ADDR_WIDTH-1:0] waddr,   // Write Address
    input  logic [DATA_WIDTH-1:0] wdata,   // Write Data
    
    // Okuma Portu (Read Port)
    input  logic [ADDR_WIDTH-1:0] raddr,   // Read Address
    output logic [DATA_WIDTH-1:0] rdata    // Read Data
);

    // Bellek dizisinin tanımlanması
    logic [DATA_WIDTH-1:0] ram [0:(2**ADDR_WIDTH)-1];

    // Yazma İşlemi
    always_ff @(posedge clk) begin
        if (we) begin
            ram[waddr] <= wdata;
        end
    end

    // Okuma İşlemi
    always_ff @(posedge clk) begin
        rdata <= ram[raddr];
    end

endmodule