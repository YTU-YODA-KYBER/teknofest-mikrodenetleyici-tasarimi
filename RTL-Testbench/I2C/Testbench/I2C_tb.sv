`timescale 1ns / 1ps

module I2C_Master_testbench;

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


    reg [31:0]  read_output;
    reg         sda = 1;
    
    integer     nby = 0;
    integer     i   = 1;     
                    
    wire I2C_SDA;
    wire I2C_SCL;

    assign I2C_SDA = sda ? 1'bz : 1'b0;
    
    pullup(I2C_SDA);
    pullup(I2C_SCL);
        
    // MODÜLÜ ÇAĞIRMA
    I2C_Master_AXI4_Lite dut(
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
        .rready(rready),
        
        .I2C_SCL(I2C_SCL),
        .I2C_SDA(I2C_SDA)    
        );
    
    // --- CLOCK ÜRETİMİ ---
    always begin
        #10.4166 clk_i = ~clk_i;
    end
    
    // Reset işlemi
    task reset;
        begin
            rst_n = 0;
            #40;
            rst_n = 1;
            #40;
        end
    endtask    
    
    
    // Yazma testi
    task write_and_ack;
        begin
            repeat(dut.I2C_NBY +1)begin
                repeat(8) @(posedge I2C_SCL);
                
                wait(I2C_SCL == 0);
                sda = 0;
                wait(I2C_SCL == 1);
                wait(I2C_SCL == 0);
                sda = 1;
            end
        end
    endtask
    
    
    // Okuma testi
    task read_and_ack(input [31:0]read_data);
        begin
            nby = dut.I2C_NBY;
            repeat(2)begin
                repeat(8) @(posedge I2C_SCL);
                
                wait(I2C_SCL == 0);
                sda = 0;
                wait(I2C_SCL == 1);
                wait(I2C_SCL == 0);
                sda = 1;
            end
                
                repeat(9) @(posedge I2C_SCL); //restart yüzünden fazladan 1 posedge bekle
                
                wait(I2C_SCL == 0);
                sda = 0;
                wait(I2C_SCL == 1);
                wait(I2C_SCL == 0);
                sda = 1;
            
                for (i = 7 ; i >= 0 ; i = i-1) begin
                        wait(I2C_SCL == 0);
                        sda = read_data[i];
                        @(negedge I2C_SCL);                    
                end 
                nby = nby -1;
                @(negedge I2C_SCL);
                if (nby) begin
                for (i = 15  ; i >= 8 ; i = i-1) begin
                        wait(I2C_SCL == 0);
                        sda = read_data[i];
                        @(negedge I2C_SCL);                     
                    end
                end
                nby = nby -1;
                @(negedge I2C_SCL);
                if (nby) begin
                for (i = 23 ; i >= 16 ; i = i-1) begin
                        wait(I2C_SCL == 0);
                        sda = read_data[i];
                        @(negedge I2C_SCL);                 
                    end
                end
                nby = nby -1;
                @(negedge I2C_SCL);
                if (nby) begin
                for (i = 31 ; i >= 24 ; i = i-1) begin
                        wait(I2C_SCL == 0);
                        sda = read_data[i];
                        @(negedge I2C_SCL);                     
                    end 
                end
                sda = 1;
            end
    endtask
    
    
    // NACK testi
    task nack_test_write(input [2:0]when_nack);
        begin
            repeat(when_nack -1)begin
                repeat(8) @(posedge I2C_SCL);
                
                wait(I2C_SCL == 0);
                sda = 0;
                wait(I2C_SCL == 1);
                wait(I2C_SCL == 0);
                sda = 1;
            end
            
            
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
                                // 4 bayt oku
        axi_write(32'h0000_0000, 32'h0000_0004);                                //I2C_NBY
        axi_write(32'h0000_0004, 32'b0110_0110);                                //I2C_ADR
        axi_write(32'h0000_000C, 32'b0101_1100_0111_1100_1010_1110_0110_0010);  //I2C_TDR
        axi_write(32'h0000_0010, 32'b0000_0000_0000_0000_0000_0000_0000_0100);  //I2C_CFG

        wait(dut.freq_div_en == 1);
        
        read_and_ack(32'b0101_1100_0111_1100_1010_1101_1110_0011);
        //write_and_ack();
        //nack_test_write(2);  
                
        wait(dut.freq_div_en == 0);

        axi_read(32'h0000_0008, read_output);

        // Biraz bekle
        #10000; 

        $finish;
    end

endmodule