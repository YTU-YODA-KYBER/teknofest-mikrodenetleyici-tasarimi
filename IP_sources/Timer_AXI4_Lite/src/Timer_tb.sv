`timescale 1ns / 1ps

module Timer_testbench;

    // clock ve reset sinyalleri
    reg clk_i = 0;
    reg rst_n = 0;

    // AW Portları
    reg  [31:0] awaddr  = 0;
    reg         awvalid = 0;
    wire        awready;

    // W Portları
    reg  [31:0] wdata   = 0;
    reg         wvalid  = 0;
    wire        wready;

    // AW Portları
    reg         bready  = 0;
    wire [ 1:0] bresp;
    wire        bvalid;
    // AR Portları
    reg  [31:0] araddr  = 0;
    reg         arvalid = 0;
    wire        arready;

    // R Portları
    reg         rready;
    wire [31:0] rdata;
    wire [1 :0] rresp;
    wire        rvalid;
    

    //  MODULU CAGIRMA
    Timer_module dut(
        .clk_i(clk_i),
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
        #5 clk_i = ~clk_i; // 100MHZ CLK
    end

    // Reset işlemi
    task reset;
        begin
            rst_n = 0;
            #20;
            rst_n = 1;
            #20;
        end
    endtask  


    // AXI yazma testi
    task axi_write(input [31:0] addr, input [31:0] data);
        begin
            wait(awready && wready);
            awaddr = addr;
            wdata  = data;
            awvalid = 1;
            wvalid = 1;
            bready = 1;
            
            wait(!(awready && wready));

            awvalid = 0;
            wvalid  = 0;       
        end
    endtask
    
    // AXI okuma testi
    task axi_read(input [31:0] addr, output [31:0] read);
        begin
            wait(arready);
            araddr = addr;
            arvalid = 1;

            wait(rvalid);
            read = rdata;
            rready = 1;
            arvalid = 0;

            wait(!rvalid);
            rready = 0;
        end
    endtask



    // --- TEST --- 
    initial begin 
        // Reset
        reset();

        // Yazma işlemi     
        axi_write(32'h0000_0000, 32'd4);                                       //TIM_PRE_m
        axi_write(32'h0000_0004, 32'd1453);                                     //TIM_ARE
        axi_write(32'h0000_0010, 32'd1);                                        //TIM_MOD
        axi_write(32'h0000_000C, 32'd1);                                        //TIM_ENA
        axi_write(32'h0000_0008, 32'h0000_0001);                              //TIM_CLR

        #2000000; 
        
        axi_write(32'h0000_001C, 32'h0000_0001);                              //TIM_EVC 
        #1000000;

        axi_write(32'h0000_0008, 32'h0000_0001);                              //TIM_CLR
        #3000000;

        $display("Simülasyon başarıyla tamamlandı!");
        $finish;
    end

endmodule