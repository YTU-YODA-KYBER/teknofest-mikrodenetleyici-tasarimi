`timescale 1ns / 1ps

module Timer_testbench;

    // clock ve reset sinyalleri
    reg clk = 0;
    reg rst_n = 0;

    // WRITE ADDRESS kanalı (Master'dan Slave'e)
    reg [31:0] awaddr = 0;
    reg awvalid = 0;

    // WRITE DATA kanalı (Master'dan Slave'e)
    reg [31:0] wdata = 0;
    reg wvalid = 0;

    // WRITE RESPONSE kanalı (Master'dan Slave'e)
    reg bready = 0;

    // READ ADDRESS kanalı (Master'dan Slave'e)
    reg [31:0] araddr = 0;
    reg arvalid = 0;


    wire awready;
    wire wready;
    wire [1:0] bresp;
    wire bvalid;
    wire arready;
    wire [31:0] rdata;
    wire [1:0] rresp;
    wire rvalid;
    wire rready;
    
    //  MODULU CAGIRMA
    Timer_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .awaddr(awaddr),
        .awvalid(awvalid),
        .awready(awready),
        .wdata(wdata),
        .wvalid(wvalid),
        .wready(wready),
        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready),
        .araddr(araddr),
        .arvalid(arvalid),
        .arready(arready),
        .rdata(rdata),
        .rresp(rresp),
        .rvalid(rvalid),
        .rready(rready)
    );
    
    // --- CLOCK ÜRETİMİ ---
    always begin
        #5 clk = ~clk; // DENEME AMACLI 100MHZ CLK
    end
    
    // --- TEST --- 
    initial begin 
        // 1. Sistemi Resetle
        rst_n = 0;
        #20;
        rst_n = 1; // 20ns sonra reset'i kaldır
        #30;       // Toplam 50ns beklemiş olduk
        
        // 2. AXI Write İşlemi Başlat
        awaddr = 32'h0000_0000;
        wdata  = 32'h0000_000A;
        
        awvalid = 1;
        wvalid = 1;
        bready = 1;
        
        #20; 
        
        
        
        awaddr = 32'h0000_0004;
        wdata  = 32'h0000_05AD;
        
        awvalid = 1;
        wvalid = 1;
        bready = 1;
        
        #20; 
        
        
        
        awaddr = 32'h0000_0008;
        wdata  = 32'h0000_0000;
        
        awvalid = 1;
        wvalid = 1;
        bready = 1;
        
        #20;
        
        
        awaddr = 32'h0000_0010;
        wdata  = 32'h0000_0001;
        
        awvalid = 1;
        wvalid = 1;
        bready = 1;
        
        #20; 
        
        
        
        awaddr = 32'h0000_001C;
        wdata  = 32'h0000_0000;
        
        awvalid = 1;
        wvalid = 1;
        bready = 1;
        
        #20;         
        
        
        
        awaddr = 32'h0000_000C;
        wdata  = 32'h0000_0001;
        
        awvalid = 1;
        wvalid = 1;
        bready = 1;
        
        #20; 
        
        
        // Sinyalleri geri indir
        awvalid = 0;
        wvalid = 0;
        
        // 4. Simülasyonu hemen bitirme, sonuçları görmek için bekle
        #1000; 
        
        $display("Simülasyon başarıyla tamamlandı!");
        $finish;
    end

endmodule