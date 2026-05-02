`timescale 1ns / 1ps

module QSPI_Master_tb;

    // clock ve reset sinyalleri
    reg clk_i = 0;
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
        
    reg  rready;
    
                    
    wire QSPI_CS;
    wire QSPI_SCLK;

    wire QSPI_IO0;
    wire QSPI_IO1;
    wire QSPI_IO2;
    wire QSPI_IO3;

    wire awready;
    wire wready;
    wire [1:0] bresp;
    wire bvalid;
    wire arready;
    wire [31:0] rdata;
    wire [1:0] rresp;
    wire rvalid;
    
    reg io0_val = 1'bz;
    reg io1_val = 1'bz;;
    reg io2_val = 1'bz;;
    reg io3_val = 1'bz;;

    assign QSPI_IO0 = io0_val;
    assign QSPI_IO1 = io1_val;
    assign QSPI_IO2 = io2_val;
    assign QSPI_IO3 = io3_val;


    //  MODULU CAGIRMA
    QSPI_Master_AXI4_Lite dut(
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
        
        .QSPI_IO0(QSPI_IO0),
        .QSPI_IO1(QSPI_IO1),
        .QSPI_IO2(QSPI_IO2),
        .QSPI_IO3(QSPI_IO3),

        .QSPI_SCLK(QSPI_SCLK),
        .QSPI_CS(QSPI_CS)
                
        );
    
        // --- CLOCK ÜRETİMİ ---
    always begin
        #10.4166 clk_i = ~clk_i;
    end
    
    
    task reset;
        begin
            rst_n = 0;
            #40;
            rst_n = 1;
            #40;
        end
    endtask 


    task push_data (input [31:0]read_data, input [1:0]data_mode);
        begin
            repeat(32/data_mode)begin

                if(data_mode == 1)begin
                    io0_val = read_data[31];
                    read_data = read_data << 1;
                end
                if(data_mode == 2)begin
                    io0_val = read_data[30];
                    io1_val = read_data[31];
                    read_data = read_data << 2;

                end
                if(data_mode == 4)begin
                    io0_val = read_data[28];
                    io1_val = read_data[29];
                    io2_val = read_data[30];
                    io3_val = read_data[31];
                    read_data = read_data << 3;
                end
                @(negedge QSPI_SCLK);

            end

        end
    endtask
    

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
    
    //  WREN        = 0x06 = 00000110   // Yazma İzni Ver (Write Enable)
    //  WRDI        = 0x04 = 00000100   // Yazma İznini Kaldır (Write Disable)
    //  READ        = 0x03 = 00000011   // Standart Okuma (x1 Modu)
    //  DOR         = 0x3B = 00111011   // Dual Output Fast Read (x2 Modu)
    //  QOR         = 0x6B = 01101011   // Quad Output Fast Read (x4 Modu)
    //  PP          = 0x02 = 00000010   // Sayfa Programlama (Page Program - x1)
    //  QPP         = 0x32 = 00110010   // Dörtlü Sayfa Programlama (Quad Page Program - x4)
    //  SE(4KB)     = 0x20 = 00100000   // Subsektör Silme (Sector Erase - 4KB)
    //  SE(64KB)    = 0xD8 = 11011000   // Sektör silme (Subsector Erase - 64KB)
    //  RDID        = 0x9F = 10011111   // JEDEC Tanımlama Bilgisini Oku
    //  READ_ID     = 0x9E = 10011110   // Cihaz Kimliğini Oku (Read ID)
    //  RES         = 0xAB = 10101011   // Elektronik İmzayı Oku (Read Electronic Signature)
    //  RDSR1       = 0x05 = 00000101   // Durum Yazmacı-1'i Oku (Read Status logicister)
    //  RDSR2       = 0x70 = 01110000   // Flag Durum Yazmacını Oku (Read Flag Status logicister)
    //  RDCR        = 0xB5 = 10110101   // Konfigürasyon Yazmacını Oku (Read Nonvolatile Configuration)
    //  WRR         = 0x01 = 00000001   // Yazmaçları Güncelle (Write Status logicister)
    //  CLSR        = 0x50 = 01010000   // Flag Durum Yazmacını Temizle (Clear Flag Status logicister)
    //  RESET_en    = 0x66 = 01100110   // Reset Enable
    //  RESET_mem   = 0x99 = 10011001   // Reset Memory
    
    // --- TEST --- 
    initial begin 
        // Reset
        reset();
        rready = 0;

        axi_write(32'h0000_0014, 1'b0);                                         //address

        // Yazma işlemi
        axi_write(32'h0000_0008, 32'b0101_1100_0111_1100_1010_1110_0110_0010);  //QSPI_DR
        axi_write(32'h0000_0008, 32'b1101_0100_0110_0001_1011_1001_1101_0101);  //QSPI_DR

                                  //clr, prescaler, rzv, data_size, dummy, r_w, data_mode, instr_val
        axi_write(32'h0000_0000, 32'b0_____000001____0____00000000__00000___0______00_______00000110);    //Write Enable
        wait(dut.busy == 1);
        wait(dut.busy == 0);
        
        axi_write(32'h0000_0004, 32'b1001_1101_1110_1011_0110_0110);            //QSPI_ADR
        axi_write(32'h0000_0014, 1'b1);                                         //address
                                  //clr, prescaler, rzv, data_size, dummy, r_w, data_mode, instr_val
        axi_write(32'h0000_0000, 32'b0_____000001____0____00000000__00000___0______00_______11011000);    //Sector Erase
        wait(dut.busy == 1);
        wait(dut.busy == 0);

        axi_write(32'h0000_0014, 1'b0);                                         //address
                                  //clr, prescaler, rzv, data_size, dummy, r_w, data_mode, instr_val
        axi_write(32'h0000_0000, 32'b0_____000001____0____00000000__00000___0______00_______00000110);    //Write Enable
        wait(dut.busy == 1);
        wait(dut.busy == 0);

        axi_write(32'h0000_0004, 32'b1011_1101_1110_1011_0110_0110);            //QSPI_ADR
        axi_write(32'h0000_0014, 1'b1);                                         //address

                                    //clr, prescaler, rzv, data_size, dummy, r_w, data_mode, instr_val
        //axi_write(32'h0000_0000, 32'b0_____000001____0____00000111__00000___1______11_______00110010);    //Quad Page Program
        //wait(dut.busy == 1);
        //wait(dut.busy == 0);

                                  //clr, prescaler, rzv, data_size, dummy, r_w, data_mode, instr_val
        axi_write(32'h0000_0000, 32'b0_____000001____0____00000111__00111___0______10_______00111011);   //Dual Output Fast Read
        wait(dut.busy == 1);
        wait(dut.dummy_cycle == 8'b00111);
        wait(dut.dummy_cycle == 8'b000000);

        @(negedge QSPI_SCLK);
        push_data (32'b0101_1100_0111_1100_1010_1110_0110_1011, 2);
        push_data (32'b0111_0100_0110_0001_1011_1001_1011_1101, 2);

        //wait(dut.busy == 0);
        

        // Biraz bekle
        #100; 
        
        $finish;
    end

endmodule