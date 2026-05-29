`timescale 1ns / 1ps

module QSPI_Master_tb;

    // clock ve reset sinyalleri
    logic clk_i = 0;
    logic rst_n = 0;

    // AW Portları
    logic [31:0] awaddr = 0;
    logic        awvalid = 0;
    logic        awready;

    // W Portları
    logic [31:0] wdata = 0;
    logic        wvalid = 0;
    logic        wready;

    // B Portları
    logic        bready = 0;
    logic [ 1:0] bresp;
    logic        bvalid;

    // AR Portları
    logic [31:0] araddr = 0;
    logic        arvalid = 0;
    logic        arready;

    // R Portları
    logic [31:0] rdata;
    logic [ 1:0] rresp;
    logic        rvalid;
    logic        rready = 0;


    logic [ 3:0] basari = 0;    // Testlerdeki başarılı adımları saymak için kullanılıyor.
    logic [31:0] read_data;     // AXI okuma işlemlerinde okunan veriyi geçici olarak tutmak için kullanılıyor.
    logic [31:0] flash_vcc = 0; // Flash model besleme gerilimi

    wire QSPI_CS;
    wire QSPI_SCLK;

    wire QSPI_IO0;
    wire QSPI_IO1;
    wire QSPI_IO2;
    wire QSPI_IO3;


    logic io0_val = 1'bz;
    logic io1_val = 1'bz;;
    logic io2_val = 1'bz;;
    logic io3_val = 1'bz;;

    assign QSPI_IO0 = io0_val;
    assign QSPI_IO1 = io1_val;
    assign QSPI_IO2 = io2_val;
    assign QSPI_IO3 = io3_val;



    // QSPI register adresleri
    localparam QSPI_BASE  = 32'h0000_0000;
    localparam QSPI_CCR   = QSPI_BASE + 32'h00;
    localparam QSPI_ADR   = QSPI_BASE + 32'h04;
    localparam QSPI_DR    = QSPI_BASE + 32'h08;
    localparam QSPI_STA   = QSPI_BASE + 32'h0C;
    localparam QSPI_FCR   = QSPI_BASE + 32'h10;


    //  MODÜLÜ ÇAĞIRMA
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
    

    
    // Micron MT25QL256ABA8E0 non-volatile flash modeli
    N25Qxxx u_flash (
        .S         (QSPI_CS),      // CS active low
        .C_        (QSPI_SCLK),    // SCLK
        .DQ0       (QSPI_IO0),     // IO0
        .DQ1       (QSPI_IO1),     // IO1
        .Vpp_W_DQ2 (QSPI_IO2),     // IO2 / WP
        .HOLD_DQ3  (QSPI_IO3),     // IO3 / HOLD
        .Vcc       (flash_vcc),    // 3.3V
        .RESET2    (1'b1)          // Yazılımla reset - 1'de tut
    );


    // --- CLOCK ÜRETİMİ ---
    always begin
        #10.4166 clk_i = ~clk_i;
    end
    

    // Active low reset için kullanılır
    task reset;
        begin
            rst_n = 0;
            #40;
            rst_n = 1;
            #40;
        end
    endtask 


    // RX FIFO'ya farklı formatlarda(x1, x2, x4) veri basmak için kullanılır
    task push_data (input [31:0]read_data, input [2:0]data_mode);
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
                    read_data = read_data << 4;
                end
                @(negedge QSPI_SCLK);
            end
            io0_val = 1'bz;
            io1_val = 1'bz;
            io2_val = 1'bz;
            io3_val = 1'bz;
        end
    endtask
    
    
    // QSPI register'larına AXI4-Lite ile veri YAZMAYI sağlar.
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


    // QSPI register'larından AXI4-Lite ile veri OKUMAYI sağlar.
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

    // QSPI modülündeki QSPI_STA register'ını AXI4-Lite ile temizlemek için kullanılır.
    task CLSR();
        // Durum register'ını temizle (Clear Status Register)
        //                     clr | prescaler | address | data_size | dummy | r_w | data_mode | instr_val
        axi_write(QSPI_CCR, 32'b1_____000001________0______00000000____00000____0_______00_______00000000); // Durum register'ını temizle
        $display("CLSR komutu gönderildi. Durum register'i(QSPI_STA) temizlendi.");
    endtask

    // QSPI modülüne WREN komutunu göndererek yazma izni vermek için kullanılır.
    task WREN();
        CLSR();
        // Yazma İzni Ver (Write Enable)
        //                     clr | prescaler | address | data_size | dummy | r_w | data_mode | instr_val
        axi_write(QSPI_CCR, 32'b0_____000001________0______00000000____00000____0_______00_______00000110); // WREN komutu
        polling_transaction_finish(); // Transaction'ın tamamlanmasını bekle
        $display("WREN komutu gönderildi. Yazma izni verildi.");

        CLSR();
    endtask

    // Flash belleğe CLSR komutunu göndererek flag durum register'ını temizlemek için kullanılır.
    task Clear_Flag_Status();
        CLSR();
        // Flag Durum Yazmacını Temizle (Clear Flag Status Register)
        axi_write(QSPI_CCR, 32'b0_____000001________0______00000000____00000____0_______00_______01010000); // Clear Flag Status Register komutu   
        polling_transaction_finish(); // Transaction'ın tamamlanmasını bekle
        $display("Clear_Flag_Status komutu gönderildi. Flag durum register'i temizlendi.");

        CLSR();
    endtask

    // QSPI modülünde başlatılan bir transaction'ın tamamlanmasını beklemek için kullanılır. QSPI_STA register'ının 0. bitini kontrol ederek transaction'ın tamamlanıp tamamlanmadığını belirler.
    task polling_transaction_finish();
        begin
            read_data = 0;
            while(read_data[0] == 0) begin
                axi_read(QSPI_STA, read_data);
            end
        end
    endtask

    // Flash bellekteki WIP bitinin temizlenmesini beklemek için kullanılır. RDSR1 komutu ile durum register'ını
    // sürekli okuyarak WIP bitinin 0 olduğunu kontrol eder. WIP biti 1 olduğu sürece beklemeye devam eder.
    task polling_RDSR1_WIP_clear();
        begin
            read_data = 1;
            while(read_data[0] == 1) begin
                CLSR(); // Durum register'ını temizle
                axi_write(QSPI_CCR, 32'b0_____000001________0______00000000____00000____0_______01_______00000101); // RDSR1 komutu ile WIP bitini oku
                polling_transaction_finish(); // Transaction'ın tamamlanmasını bekle     

                axi_read(QSPI_DR, read_data);
            end 
            CLSR(); // Durum register'ını temizle
        end
    endtask

    // Sektörlerin koruma durumunu etkileyen PPB'leri temizlemek için kullanılır.
    task ppb_clean();
    begin
        // ── PPB Temizle (tüm sektörleri korumasız yap) ──────────────
        WREN(); // Yazma izni ver 00000110

        // Adım 2: ERNVLB - tüm NV lock bitlerini siler
        axi_write(QSPI_CCR, {1'b1,6'd1,1'b0,8'd0,5'd0,1'b0,2'b00,8'h00}); // clr
        axi_write(QSPI_CCR, {1'b0,6'd1,1'b0,8'd0,5'd0,1'b0,2'b00,8'hE4}); // ERNVLB

        polling_transaction_finish(); // Transaction'ın tamamlanmasını bekle

        // Adım 3: WIP polling (ERNVLB da zaman alır)
        polling_RDSR1_WIP_clear();
        $display("PPB temizlendi, tüm sektörler korumasiz.");
    end
    endtask

    // Bu task, girdiğimiz sayı kadar AXI4-Lite üzerinden TX FIFO'ya veri doldurur.
    task fill_tx_fifo(input [7:0] number_of_data);
        begin
            $display("TX FIFO %0d veri ile dolduruluyor...", number_of_data);
            repeat(number_of_data) axi_write(QSPI_DR, 32'b0101_1100_0111_1100_1010_1110_0110_0010);  //QSPI_DR
            wait(awready && wready);
            repeat(5) @(negedge clk_i);
            $display("Islem tamamlandi. TX FIFO'da %0d veri var, %0d boş yer kaldi\n", dut.fifo_tx_cnt, 64 - dut.fifo_tx_cnt);
        end
    endtask


    // Bu task, girdiğimiz sayı kadar AXI4-Lite üzerinden RX FIFO'ya veri doldurur.
    task fill_rx_fifo(input clr, input [5:0] prescaler, input address, input [7:0] data_size, input [4:0] dummy, input r_w, input [1:0] data_mode, input [7:0] instr_val);         
        begin
            $display("RX FIFO %0d veri ile dolduruluyor...", (data_size +1)/4);

            axi_write(QSPI_CCR, {clr, prescaler, address, data_size, dummy, r_w, data_mode, instr_val});

            wait(dut.busy == 1);
            wait(dut.dummy_cycle == 0);
            @(negedge QSPI_SCLK);

            repeat((data_size +1)/4) push_data(32'b0101_1100_0111_1100_1010_1110_0110_0010, 4);  //QSPI_DR

            polling_transaction_finish(); // Transaction'ın tamamlanmasını bekle
            $display("Islem tamamlandi. RX FIFO'da %0d veri var, %0d boş yer kaldi\n", dut.fifo_rx_cnt, 64 - dut.fifo_rx_cnt);
        end
    endtask

    // Bu task, QSPI_STA register'ındaki bayrakların durumunu okunabilir şekilde raporlar. Her bir bayrağın ne anlama geldiğini ve şu anda set olup olmadığını gösterir.
    task report_QSPI_STA();

        $display("-----------------------------------------------------------------------");

        if(dut.QSPI_STA[0]) begin
            $display("Okuma/yazma transaction durumu => 1, Transaction tamamlandi!");
        end else begin
            $display("Okuma/yazma transaction durumu => 0, Tamamlanmis transaction yok.");
        end
        if(dut.QSPI_STA[1]) begin
            $display("Mesguliyet durumu              => 1, Mesgul, transaction devam ediyor...");
        end else begin
            $display("Mesguliyet durumu              => 0, Mesgul degil.");
        end
        if(dut.QSPI_STA[4]) begin
            $display("RX FIFO doluluk durumu         => 1, Dolu!");
        end else begin
            $display("RX FIFO doluluk durumu         => 0, Dolu degil.");
        end
        if(dut.QSPI_STA[5]) begin
            $display("RX FIFO bosluluk durumu        => 1, Bos!");
        end else begin
            $display("RX FIFO bosluluk durumu        => 0, Bos degil.");
        end
        if(dut.QSPI_STA[6]) begin
            $display("TX FIFO doluluk durumu         => 1, Dolu!");
        end else begin
            $display("TX FIFO doluluk durumu         => 0, Dolu degil.");
        end
        if(dut.QSPI_STA[7]) begin
            $display("TX FIFO bosluluk durumu        => 1, Bos!");
        end else begin
            $display("TX FIFO bosluluk durumu        => 0, Bos degil");
        end
        if(dut.QSPI_STA[11:8] == 0)begin
            $display("Hata durumu                    => 0000, hata yok.");
        end 
        if(dut.QSPI_STA[8] == 1) begin
            $display("Hata durumu                    => %b, RX FIFO bosken okunmaya calisildi.", dut.QSPI_STA[11:8]);
        end 
        if(dut.QSPI_STA[9] == 1) begin
            $display("Hata durumu                    => %b, TX FIFO doluyken yazilmaya calisildi.", dut.QSPI_STA[11:8]);
        end

        $display("-----------------------------------------------------------------------\n");
    endtask

    
    // Bu QSPI modülünün desteklediği bazı komutlar ve açıklamaları:
    // -------------|------------------|-----------------------------------------------
    //  Komut Adı   | Komut Kodu (Hex) | Komut Açıklaması
    // -------------|------------------|-----------------------------------------------
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


    //=======================================================================
    //                        TEST 1
    // QSPI_STA bayraklarının gerekli koşullarda doğru çalışıp
    // çalışmadığını kontrol eder. Test sırasındaki yazma ve okuma
    // işlemleri AXI4-Lite ile QSPI modülünün kendisi tarafından yapılarak
    // art ardayazma ve okuma durumlarında sorunsuz çalıştığı gösterilmiş olur.
    //========================================================================

    $display("\n=====================================================================");
    $display("=== TEST 1: FIFO bayraklari ve QSPI cekirdegi dogru calisiyor mu? ===");
    $display("=====================================================================\n");

    // Modülü resetliyoruz
    reset();

    $display("Test baslatiliyor...\n");


    //----------------------------------------------------------------------------------------------------------------------------------
    // TEST 1.1: Reset sonrası başlangıç durumunu kontrol ediyoruz. FIFO'ların boş olduğunu ve herhangi bir hata olmadığını doğruluyoruz.
    //----------------------------------------------------------------------------------------------------------------------------------
    $display("-------------------------------------------------");
    $display("--- TEST 1.1 - Reset sonrasi baslangic durumu ---");
    $display("-------------------------------------------------\n");

    report_QSPI_STA();  // QSPI_STA register'ının degerlerini listele 
    if(dut.QSPI_STA[5] == 1)begin
        $display(" => FIFO RX empty flag'i 1, yani RX FIFO bos. DOGRU CALISIYOR.");
        basari += 1;
    end else $error("FIFO RX empty flag'i 0, yani RX FIFO bos degil. YANLIS CALISIYOR.");
    if(dut.QSPI_STA[7] == 1)begin
        $display(" => FIFO TX empty flag'i 1, yani TX FIFO bos. DOGRU CALISIYOR.\n\n");
        basari += 1;
    end else $error(" => FIFO TX empty flag'i 0, yani TX FIFO bos degil. YANLIS CALISIYOR.\n\n");
    

    //-----------------------------------------------------------------------------------------------------------------
    // TEST 1.2: FIFO'ları tamamen dolduruyoruz ve doluluk bayraklarının doğru şekilde set edildiğini kontrol ediyoruz.
    //-----------------------------------------------------------------------------------------------------------------
    $display("---------------------------------------------------------");
    $display("--- TEST 1.2 - Doluluk bayraklari dogru calisiyor mu? ---");
    $display("---------------------------------------------------------\n");

    fill_tx_fifo(64); // TX FIFO'yu tamamen dolduruyoruz.
    //          clr | prescaler | address | data_size | dummy | r_w | data_mode | instr_val
    fill_rx_fifo(0,       1,         1,        255,       1,     0,       3,          0); // RX FIFO'yu tamamen dolduruyoruz.

    report_QSPI_STA();  // QSPI_STA register'ının degerlerini listele 

    if(dut.QSPI_STA[6] == 1) begin
        $display(" => FIFO TX full flag'i 1, yani TX FIFO dolu. DOGRU CALISIYOR.");
        basari += 1;
    end else $error(" => FIFO TX full flag'i 0, yani TX FIFO dolu degil. YANLIS CALISIYOR.");

    if(dut.QSPI_STA[4] == 1)begin
        $display(" => FIFO RX full flag'i 1, yani RX FIFO dolu. DOGRU CALISIYOR.\n\n");
        basari += 1;
    end else $error(" => FIFO RX full flag'i 0, yani RX FIFO dolu degil. YANLIS CALISIYOR.\n\n");


    //-----------------------------------------------------------------------------------------------------------------
    // TEST 1.3: FIFO'ların dolu veya boş olduğu durumlarda, boşken okunmaya veya doluyken yazılmaya çalışıldığında hata
    // bayraklarının doğru şekilde set edildiğini kontrol ediyoruz.
    //-----------------------------------------------------------------------------------------------------------------
    $display("---------------------------------------------------------");
    $display("--- TEST 1.3 - Hata bayraklari dogru calisiyor mu? ------");
    $display("---------------------------------------------------------\n");

    fill_tx_fifo(5); // TX FIFO zaten dolu, 5 veri daha eklemeye çalışıyoruz.

    axi_write(QSPI_FCR, 1); // RX FIFO flush
    repeat(3) @(posedge clk_i); // Biraz bekleyelim ki flush işlemi gerçekleşsin ve bayraklar güncellensin.
    axi_read(QSPI_DR, read_data);

    repeat(3) @(posedge clk_i);
    report_QSPI_STA();

    if(dut.QSPI_STA[8] == 1)begin
        $display(" => RX FIFO bosken okunmaya calisildiginda hata flag'i 1, yani DOGRU CALISIYOR.");
        basari += 1;
    end
    else $error(" => RX FIFO bosken okunmaya calisildiginda hata flag'i 0001 degil, yani YANLIS CALISIYOR.");

    if(dut.QSPI_STA[9] == 1)begin
        $display(" => TX FIFO doluyken yazilmaya calisildiginda hata flag'i 1, yani DOGRU CALISIYOR.\n\n");
        basari += 1;
    end
    else $error(" => TX FIFO doluyken yazilmaya calisildiginda hata flag'i 0010 degil, yani YANLIS CALISIYOR.\n\n");


    //-----------------------------------------------------------------------------------------------------------------
    // TEST 1.4: FIFO'ları temizleme fonksiyonu çalışıyor mu kontrol edeceğiz.
    //-----------------------------------------------------------------------------------------------------------------
    $display("---------------------------------------------------------");
    $display("------- TEST 1.4 - FIFO flush dogru calisiyor mu? -------");
    $display("---------------------------------------------------------\n");


    axi_write(QSPI_FCR, 32'b11);    // QSPI_FCR register'ının 2 bitini de 1 yapıyoruz.
    repeat(3) @(posedge clk_i);

    if(!(dut.fifo_tx_cnt && dut.tx_wr_ptr && dut.tx_rd_ptr))begin
        $display(" => TX FIFO'nun sayaci ve isaretcileri sifirlanmis, yani DOGRU CALISIYOR.");
        basari += 1;
    end
    else $error(" => TX FIFO'nun sayaci ve isaretcileri sifir degil, yani YANLIS CALISIYOR.");

    if(!(dut.fifo_rx_cnt && dut.rx_wr_ptr && dut.rx_rd_ptr))begin
        $display(" => RX FIFO'nun sayaci ve isaretcileri sifirlanmis, yani DOGRU CALISIYOR.\n\n");
        basari += 1;
    end
    else $error(" => RX FIFO'nun sayaci ve isaretcileri sifir degil, yani YANLIS CALISIYOR.\n\n");


    $display("TEST 1 TAMAMLANDI   %d basarili, %d basarisiz\n", basari, 8-basari);

    basari = 0; // basari sayacini sifirliyoruz.




    //=======================================================================
    //                              TEST 2
    // Şartnamede bize gönderilmiş olan Micron MT25QL256ABA8E12 model numaralı
    // flaş belleğin simülasyon modelini QSPI_Master modülümüze bağlayıp şartnamede
    // istenen bütün komutları/işlemleri başarıyla gerçekleştirdiğini göstereceğiz
    //========================================================================


    flash_vcc = 32'd3300;   // Flash modelini çalıştırıyoruz
    #1000000;               // Modelin tam olarak başlatılması ve stabil hale gelmesi için yeterli süreyi veriyoruz.


    $display("\n==========================================================================");
    $display("=== TEST 2: Flash memory simulasyon modeli ile gercek senaryo testleri ===");
    $display("==========================================================================\n");
    


    //-----------------------------------------------------------------------------------------------------------------
    // TEST 2.1: İlk olarak QSPI modülünün flash bellekle başarılı bir şekilde bağlandığını ve temel 
    // komutları doğru şekilde gerçekleştirebildiğini göstermek için flash belleğin JEDEC bilgisini okuyacağız.
    //-----------------------------------------------------------------------------------------------------------------
    $display("---------------------------------------------------------");
    $display("------- TEST 2.1 - JEDEC tanimlama bilgisi okuma --------");
    $display("---------------------------------------------------------\n");


    CLSR(); // Durum register'ını temizle

    // JEDEC tanımlama bilgisini oku ve durum register'ını temizle
    //                     clr | prescaler | address | data_size | dummy | r_w | data_mode | instr_val
    axi_write(QSPI_CCR, 32'b0_____000001________0______00000010____00000____0_______01_______10011111);

    polling_transaction_finish(); // Transaction'ın tamamlanmasını bekle

    // RX FIFO'dan oku
    axi_read(QSPI_DR, read_data);

    $display("JEDEC ID: 0x%06X (beklenen: 0x20BA19)", read_data[23:0]);
    if(read_data[23:0] == 24'h20_BA_19)begin
        $display("OKUMA BASARILI!");
        basari += 1;
    end
    else
        $error("OKUMA BASARISIZ, FLASH MODEL BAGLANTISINDA SORUN VAR!");




    //-----------------------------------------------------------------------------------------------------------------
    // TEST 2.2: Flash belleğe yazma veya okuma işlemi yapmadan önce içindeki verilerin lojik 1 yapılması gerekiyor.
    // Bunun için sektör silme işlemini yapacağız.
    //-----------------------------------------------------------------------------------------------------------------
    $display("----------------------------------------");
    $display("------- TEST 2.2 - Sector Silme --------");
    $display("----------------------------------------\n");

    ppb_clean(); // PPB'leri temizleyelim, böylece tüm sektörler korumasız olsun.
    
    Clear_Flag_Status(); // Flag durum register'ını temizle 01010000
    WREN(); // Yazma izni ver 00000110

    axi_write(QSPI_ADR, 32'd0); // Silme işlemi için adresi 0 yapıyoruz.
    // Sektör silme (Subsector Erase - 64KB)
    //                     clr | prescaler | address | data_size | dummy | r_w | data_mode | instr_val
    axi_write(QSPI_CCR, 32'b0_____000001________1______00000000____00000____0_______00_______11011000);

    polling_transaction_finish(); // Transaction'ın tamamlanmasını bekle
    polling_RDSR1_WIP_clear(); // WIP bitinin temizlenmesini bekle




    //-----------------------------------------------------------------------------------------------------------------
    // TEST 2.3: QSPI modülümüzün sayfa programlama(PP) ve dörtlü sayfa programlama(QPP) komutlarını, farklı frekans ve veri modlarında (x1, x4)
    // flash belleğe veri yazma işlemini başarıyla gerçekleştirebildiğini göstereceğiz.
    //-----------------------------------------------------------------------------------------------------------------
    $display("--------------------------------------------------------------------------------------");
    $display("------- TEST 2.3 - Farkli frekans ve veri modlarinda flash bellege veri yazma --------");
    $display("---------------------------------------------------------------------------------------\n");


    $display("--- 12MHz ile x4 modunda 256 bayt veri yazma islemi baslatiliyor...  \n");

    fill_tx_fifo(64); // TX FIFO'yu tamamen dolduruyoruz.

    Clear_Flag_Status(); // Flag durum register'ını temizle 01010000
    WREN(); // Yazma izni ver 00000110

    $display("--- Flash belleğe veri yazma islemi baslatiliyor...  \n");
    axi_write(QSPI_ADR, 32'd0); // Yazma adresini 0 yapıyoruz.
    // Dörtlü Sayfa Programlama (Quad Page Program - x4)
    //                     clr | prescaler | address | data_size | dummy | r_w | data_mode | instr_val
    axi_write(QSPI_CCR, 32'b0_____000011________1______11111111____00000____1_______11_______00110010);

    polling_transaction_finish(); // Transaction'ın tamamlanmasını bekle
    axi_write(QSPI_FCR, 3); // Tekrar kullanabilmek için TX FIFO flush
    polling_RDSR1_WIP_clear(); // WIP bitinin temizlenmesini bekle

    $display("--- Islem tamamlandi, TX FIFO'da kalan veri: %d  \n", dut.fifo_tx_cnt);




    $display("--- 4MHz ile x1 modunda 256 bayt veri yazma islemi baslatiliyor...  \n");

    fill_tx_fifo(64); // TX FIFO'yu tamamen dolduruyoruz.

    Clear_Flag_Status(); // Flag durum register'ını temizle 01010000
    WREN(); // Yazma izni ver 00000110

    $display("--- Flash belleğe veri yazma islemi baslatiliyor...  \n");
    axi_write(QSPI_ADR, 32'h00000100); // Yazma adresini 00000100 yapıyoruz.
    // Sayfa Programlama (Page Program - x1)
    //                     clr | prescaler | address | data_size | dummy | r_w | data_mode | instr_val
    axi_write(QSPI_CCR, 32'b0_____001011________1______11111111____00000____1_______01_______00000010);
  
    polling_transaction_finish(); // Transaction'ın tamamlanmasını bekle
    axi_write(QSPI_FCR, 3); // Tekrar kullanabilmek için TX FIFO flush
    polling_RDSR1_WIP_clear(); // WIP bitinin temizlenmesini bekle

    $display("--- Islem tamamlandi, TX FIFO'da kalan veri: %d  \n", dut.fifo_tx_cnt);


    axi_write(QSPI_FCR, 3);




    //-----------------------------------------------------------------------------------------------------------------
    // TEST 2.4: QSPI modülümüzün standart okuma(READ), dual output fast read(DOR) ve quad output fast read(QOR) komutlarını,
    // farklı frekans ve veri modlarında (x1, x2, x4) gerçekleştirebildiğini göstereceğiz. Az önce flash belleğe yazmış olduğumuz
    // verileri okuyarak işlemi başarıyla gerçekleştirdiğini göstereceğiz.
    //-----------------------------------------------------------------------------------------------------------------
    $display("----------------------------------------------------------------------------------------");
    $display("------- TEST 2.4 - Farkli frekans ve veri modlarinda flash bellekten veri okuma --------");
    $display("------------------------------------------------------------------------------------------\n");


    $display("--- 6MHz ile x4 modunda 256 bayt veri okuma islemi baslatiliyor...  \n");

    axi_write(QSPI_ADR, 32'h00000000); // Yazma adresini 00000000 yapıyoruz.
    // Quad Output Fast Read (x4 Modu)
    //                     clr | prescaler | address | data_size | dummy | r_w | data_mode | instr_val
    axi_write(QSPI_CCR, 32'b0_____000111________1______11111011____01000____0_______11_______01101011);

    polling_transaction_finish(); // Transaction'ın tamamlanmasını bekle

    axi_read(QSPI_DR, read_data);
    if(read_data == 32'b0101_1100_0111_1100_1010_1110_0110_0010)begin
        $display("OKUMA BASARILI!");
        basari += 1;
    end
    else $error("YANLIS OKUMA, OKUNAN VERI %b", read_data);

    Clear_Flag_Status(); // Flag durum register'ını temizle 01010000
    axi_write(QSPI_FCR, 3); // FIFO'ları temizliyoruz




    $display("--- 12MHz ile x2 modunda 128 bayt veri okuma islemi baslatiliyor...  \n");
    axi_write(QSPI_ADR, 32'h00000100); // Yazma adresini 00000100 yapıyoruz.
    // Dual Output Fast Read (x2 Modu)
    //                     clr | prescaler | address | data_size | dummy | r_w | data_mode | instr_val
    axi_write(QSPI_CCR, 32'b0_____000011________1______01111111____01000____0_______10_______00111011);

    polling_transaction_finish(); // Transaction'ın tamamlanmasını bekle

    axi_read(QSPI_DR, read_data);
    if(read_data == 32'b0101_1100_0111_1100_1010_1110_0110_0010)begin
        $display("OKUMA BASARILI!");
        basari += 1;
    end
    else $error("YANLIS OKUMA, OKUNAN VERI %b", read_data);

    Clear_Flag_Status(); // Flag durum register'ını temizle 01010000
    axi_write(QSPI_FCR, 3); // FIFO'ları temizliyoruz




    $display("--- 24MHz ile x1 modunda 128 bayt veri okuma islemi baslatiliyor...  \n");
    axi_write(QSPI_ADR, 32'h00000180); // Yazma adresini 00000180 yapıyoruz.
    // Dual Output Fast Read (x2 Modu)
    //                     clr | prescaler | address | data_size | dummy | r_w | data_mode | instr_val
    axi_write(QSPI_CCR, 32'b0_____000001________1______01111111____00000____0_______01_______00000011);

    polling_transaction_finish(); // Transaction'ın tamamlanmasını bekle

    axi_read(QSPI_DR, read_data);
    if(read_data == 32'b0101_1100_0111_1100_1010_1110_0110_0010)begin
        $display("OKUMA BASARILI!");
        basari += 1;
    end
    else $error("YANLIS OKUMA, OKUNAN VERI %b", read_data);

    Clear_Flag_Status(); // Flag durum register'ını temizle 01010000
    axi_write(QSPI_FCR, 3); // FIFO'ları temizliyoruz


    $display("TEST 2 TAMAMLANDI   %d basarili, %d basarisiz\n", basari, 4-basari);
    $finish;

end

endmodule
