module boot_rom #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10,
    parameter INIT_FILE  = "boot_code.mem" // Makine kodlarının olduğu dosya
)(
    input  logic                  clk,
    
    // Port A: Instruction (Komut) Hattı İçin
    input  logic [ADDR_WIDTH-1:0] raddr_a,
    output logic [DATA_WIDTH-1:0] rdata_a,
    
    // Port B: Data (Veri) Hattı İçin
    input  logic [ADDR_WIDTH-1:0] raddr_b,
    output logic [DATA_WIDTH-1:0] rdata_b
);

    // Bellek dizisi
    logic [DATA_WIDTH-1:0] rom [0:(2**ADDR_WIDTH)-1];

    initial begin
        $readmemh(INIT_FILE, rom); 
    end

    // Çift Portlu Asenkron Okuma
    assign rdata_a = rom[raddr_a];
    assign rdata_b = rom[raddr_b];

endmodule