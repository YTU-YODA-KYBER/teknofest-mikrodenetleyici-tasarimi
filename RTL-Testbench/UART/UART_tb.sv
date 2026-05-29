`timescale 1ns / 1ps

module UART_testbench;

    // clock ve reset sinyalleri
    logic clk_i = 0;
    logic rst_n = 0;

    // AW Portları
    logic [31:0] awaddr  = 0;
    logic        awvalid = 0;
    logic        awready;

    // W Portları
    logic [31:0] wdata   = 0;
    logic        wvalid  = 0;
    logic        wready;

    // AW Portları
    logic        bready  = 0;
    logic [ 1:0] bresp;
    logic        bvalid;
    // AR Portları
    logic [31:0] araddr  = 0;
    logic        arvalid = 0;
    logic        arready;

    // R Portları
    logic        rready;
    logic [31:0] rdata;
    logic [1 :0] rresp;
    logic        rvalid; 
                    
    logic  rx_val;
    logic  tx_val;
        
    logic rx;
    logic tx;

    logic [7:0] read_data;

    integer i = 0;

    assign rx = rx_val;
    assign tx_val = tx;

    // MODÜLÜ ÇAĞIRMA
    Uart_module dut(
        .clk(clk_i),
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
         
        .rx(rx),
        .tx(tx)
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
    
    // UART okuma testi
    task uart_read(input [7:0] data);
        begin
            rx_val = 0; // Start bit
            i = 0;
            wait(dut.sixteen_cnt_rx == 15);

            repeat(8)begin
                wait(dut.sixteen_cnt_rx == 0);
                rx_val = data[i];
                i = i + 1;
                wait(dut.sixteen_cnt_rx == 15);
            end
            wait(dut.sixteen_cnt_rx == 15);
            rx_val = 1;
        end

    endtask



    initial begin

        //===========================================================
        //                        TEST 1
        // Yazma ve okuma işlemlerini aynı anda ve yüksek baudrate
        // ile başlatacağız.
        //===========================================================
        rx_val = 1; // Idle durumda RX hattı yüksek
        $display("\n-----------------------------------------------------");
        $display("--- TEST 1: Ayni anda yazma ve okuma islemi testi ---");
        $display("-----------------------------------------------------\n");
        reset();    // Active low reset

        $display("--- Register'lar konfigure ediliyor... ---");
        //Yazma işlemi için konfigürasyon
        axi_write(32'h0000_0000, 32'd375);                  //UART_CPB => 48Mhz / (375 + 1) = 128000 baudrate
        axi_write(32'h0000_0004, 32'd2);                    //UART_STP => 1.5 stop biti
        axi_write(32'h0000_000C, 32'b0110_1101);            //UART_TDR => 0110_1101 => 0x6D => 109 decimal
        axi_write(32'h0000_0010, 32'b1);                    //UART_CFG => Yazmaya başla
        $display("--- Konfigurasyon tamamlandi. ---\n");

        uart_read(8'b1010_1101);
        $display("--- Yazma ve okuma islemi baslatildi. ---\n");

        wait(dut.UART_CFG[1] == 1); // Okuma işlemi tamamlanana kadar bekliyoruz
        axi_read(32'h0000_0008, read_data); // UART_RDR'den okuma yapıyoruz
        if(read_data[7:0] == 8'b1010_1101) $display("--- Okuma islemi basarili, okunan veri: %b ---\n", read_data[7:0]);
        else $display("--- Okuma islemi basarisiz, okunan veri: %b ---\n", read_data[7:0]);
        dut.UART_CFG[1] <= 0; // Data received bitini temizliyoruz ki sonraki okuma işlemlerinde de görebilelim
    
        wait(dut.UART_CFG[2] == 1); // Yazma işlemi tamamlanana kadar bekliyoruz
        $display("--- Yazma islemi basarili ---\n\n");
        dut.UART_CFG[2] <= 0; // Data sent bitini temizliyoruz ki sonraki yazma işlemlerinde de görebilelim
        // Biraz bekle
        #10000; 



        //===========================================================
        //                        TEST 2
        // Yazma işleminin ortalarında iken okuma işlemini başlatacağız.
        // Baud rate sayaçlarının birbirinden bağımsız çalıştığını göstermek için.
        //===========================================================
        $display("------------------------------------------------------------");
        $display("--- TEST 2: Yazma ve okuma islemlerini asenkron baslatma ---");
        $display("------------------------------------------------------------\n");
        $display("--- Register'lar konfigure ediliyor... ---");
        //Yazma işlemi için konfigürasyon
        axi_write(32'h0000_0000, 32'd417);                  //UART_CPB => 48Mhz / (417 + 1) = 115200 baudrate
        axi_write(32'h0000_0004, 32'd3);                    //UART_STP => 2 stop biti
        axi_write(32'h0000_000C, 32'b1000_1011);            //UART_TDR => 1000_1011 => 0x8B => 139 decimal
        axi_write(32'h0000_0010, 32'b1);                    //UART_CFG => Yazmaya başla
        $display("--- Konfigurasyon tamamlandi. ---\n");
        $display("--- Yazma islemi baslatildi. ---");

        wait(dut.tx_shift_cnt == 4); // Yazma işlemi ortasına gelindiğinde okuma işlemini başlatıyoruz
        uart_read(8'b1101_0110);
        $display("--- Okuma islemi baslatildi. ---\n");

        wait(dut.UART_CFG[1] == 1); // Okuma işlemi tamamlanana kadar bekliyoruz
        axi_read(32'h0000_0008, read_data); // UART_RDR'den okuma yapıyoruz
        if(read_data[7:0] == 8'b1101_0110) $display("--- Okuma islemi basarili, okunan veri: %b ---\n", read_data[7:0]);
        else $display("--- Okuma islemi basarisiz, okunan veri: %b ---\n", read_data[7:0]);        
        dut.UART_CFG[1] <= 0; // Data received bitini temizliyoruz ki sonraki okuma işlemlerinde de görebilelim

        wait(dut.UART_CFG[2] == 1); // Yazma işlemi tamamlanana kadar bekliyoruz
        $display("--- Yazma islemi basarili ---\n\n");
        dut.UART_CFG[2] <= 0; // Data sent bitini temizliyoruz ki sonraki yazma işlemlerinde de görebilelim
        // Biraz bekle
        #10000; 



        //===========================================================
        //                        TEST 3
        // Yüksek baudrate ile art arda yazma işlemi yapacağız. Sürekli yazma 
        // koşulunda hatasız veri iletimi sağlanabildiğini göstermek için.
        //===========================================================     
        $display("-------------------------------------");
        $display("--- TEST 3: Art arda yazma islemi ---");
        $display("-------------------------------------\n");
        $display("--- Register'lar konfigure ediliyor... ---");
        //Yazma işlemi için konfigürasyon
        axi_write(32'h0000_0000, 32'd500);                  //UART_CPB => 48Mhz / (500 + 1) = 96000 baudrate
        axi_write(32'h0000_0004, 32'd0);                    //UART_STP => 1 stop biti

        //============================================================
        //                      1. Yazma işlemi
        //============================================================
        axi_write(32'h0000_000C, 32'b1000_1011);            //UART_TDR => 1000_1011 => 0x8B => 139 decimal
        axi_write(32'h0000_0010, 32'b1);                    //UART_CFG => Yazmaya başla
        $display("--- Konfigurasyon tamamlandi. ---\n");
        $display("--- 1. Yazma islemi baslatildi. ---");
        wait(dut.UART_CFG[2] == 1); // Yazma işlemi tamamlanana kadar bekliyoruz
        $display("--- Yazma islemi basarili ---\n");
        dut.UART_CFG[2] <= 0; // Data sent bitini temizliyoruz ki sonraki yazma işlemlerinde de görebilelim

        //============================================================
        //                      2. Yazma işlemi
        //============================================================
        axi_write(32'h0000_000C, 32'b0110_1101);            //UART_TDR => 0110_1101 => 0x6D => 109 decimal
        axi_write(32'h0000_0010, 32'b1);                    //UART_CFG => Yazmaya başla
        $display("--- 2. Yazma islemi baslatildi. ---");
        wait(dut.UART_CFG[2] == 1); // Yazma işlemi tamamlanana kadar bekliyoruz
        $display("--- Yazma islemi basarili ---\n");
        dut.UART_CFG[2] <= 0; // Data sent bitini temizliyoruz ki sonraki yazma işlemlerinde de görebilelim

        //============================================================
        //                      3. Yazma işlemi
        //============================================================
        axi_write(32'h0000_000C, 32'b1111_0000);            //UART_TDR => 1111_0000 => 0xF0 => 240 decimal
        axi_write(32'h0000_0010, 32'b1);                    //UART_CFG => Yazmaya başla
        $display("--- 3. Yazma islemi baslatildi. ---");
        wait(dut.UART_CFG[2] == 1); // Yazma işlemi tamamlanana kadar bekliyoruz
        $display("--- Yazma islemi basarili ---\n");
        dut.UART_CFG[2] <= 0;
        $display("--- Yazma islemleri tamamlandi. ---\n\n");

        // Biraz bekle
        #10000; 



        //===========================================================
        //                        TEST 4
        // Yüksek baudrate ile art arda okuma işlemi yapacağız. Sürekli okuma 
        // koşulunda hatasız veri iletimi sağlanabildiğini göstermek için.
        //===========================================================
        $display("-------------------------------------");    
        $display("--- TEST 4: Art arda okuma islemi ---");
        $display("-------------------------------------\n");
        $display("--- Register'lar konfigure ediliyor... ---");
        //Yazma işlemi için konfigürasyon
        axi_write(32'h0000_0000, 32'd1000);                  //UART_CPB => 48Mhz / (1000 + 1) = 48000 baudrate
        $display("--- Konfigurasyon tamamlandi. ---\n");

        //============================================================
        //                      1. Okuma işlemi
        //============================================================
        uart_read(8'b1101_0110);
        $display("--- 1. Okuma islemi baslatildi. ---");
        wait(dut.UART_CFG[1] == 1); // İlk okuma işlemi tamamlanana kadar bekliyoruz
        $display("--- Data received bit 1 oldu. ---");
        dut.UART_CFG[1] <= 0; // Data received bitini temizliyoruz ki sonraki okuma işlemlerinde de görebilelim

        axi_read(32'h0000_0008, read_data); // UART_RDR'den okuma yapıyoruz
        if(read_data[7:0] == 8'b1101_0110) $display("--- 1. Okuma islemi basarili, okunan veri: %b ---\n", read_data[7:0]);
        else $display("--- 1. Okuma islemi basarisiz, okunan veri: %b ---\n", read_data[7:0]);

        //============================================================
        //                      2. Okuma işlemi
        //============================================================
        uart_read(8'b1010_1101);
        $display("--- 2. Okuma islemi baslatildi. ---");
        wait(dut.UART_CFG[1] == 1); // İlk okuma işlemi tamamlanana kadar bekliyoruz
        $display("--- Data received bit 1 oldu. ---");
        dut.UART_CFG[1] <= 0; // Data received bitini temizliyoruz ki sonraki okuma işlemlerinde de görebilelim

        axi_read(32'h0000_0008, read_data); // UART_RDR'den okuma yapıyoruz
        if(read_data[7:0] == 8'b1010_1101) $display("--- 2. Okuma islemi basarili, okunan veri: %b ---\n", read_data[7:0]);
        else $display("--- 2. Okuma islemi basarisiz, okunan veri: %b ---\n", read_data[7:0]);

        //============================================================
        //                      3. Okuma işlemi
        //============================================================
        uart_read(8'b1111_0000);
        $display("--- 3. Okuma islemi baslatildi. ---");
        wait(dut.UART_CFG[1] == 1); // İlk okuma işlemi tamamlanana kadar bekliyoruz
        $display("--- Data received bit 1 oldu. ---");
        dut.UART_CFG[1] <= 0;

        axi_read(32'h0000_0008, read_data); // UART_RDR'den okuma yapıyoruz
        if(read_data[7:0] == 8'b1111_0000) $display("--- 3. Okuma islemi basarili, okunan veri: %b ---\n", read_data[7:0]);
        else $display("--- 3. Okuma islemi basarisiz, okunan veri: %b ---\n", read_data[7:0]);

        $display("--- Okuma islemleri tamamlandi. ---");

        // Biraz bekle
        #10000; 

        $finish;
    end

endmodule