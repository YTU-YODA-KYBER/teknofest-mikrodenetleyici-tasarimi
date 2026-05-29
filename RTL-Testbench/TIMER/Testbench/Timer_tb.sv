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

    //axi okuma yaparken veriyi kaydedecegımız register
    reg [31:0] read_data;


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
        // Reset ile sisteme temiz bir başlangıç yapıyoruz
        reset();

        // 1.Adım : TIM_PRE_m = 0 iken tim_cnt 1453'e kadar sistem saati hızında sayıyor mu ? (TIM_ARE = 1453)
        $display("--- SENARYO 1: TIM_PRE_m = 0 | Hedef = 1453 Basliyor ---");

        axi_write(32'h0000_0000, 32'd0);         // TIM_PRE_m = 0
        axi_write(32'h0000_0004, 32'd1453);      // TIM_ARE = 1453
        axi_write(32'h0000_0010, 32'd1);         // TIM_MOD = 1
        axi_write(32'h0000_000C, 32'd1);         // TIM_ENA = 1

        // clk periyodu 10 ns olduguna gore 1453 x 10 = 14,530 ns beklememiz gerekiyor. Biraz ekstra zaman verelim ki kesinlikle sayma işlemi tamamlanmış olsun.
        #14540;


        // 2.Adım : Maksimum hızda(TIM_PRE_m = 0) 1453 degerinden 0'a geriye sayıyor mu ?)
        $display("--- SENARYO 2: TIM_PRE_m = 0 | Hedef = 0(Geriye sayma) Basliyor ---");
        // ilk önce timerı durdurup ayarları yapıyorum.
        axi_write(32'h0000_000C, 32'd0);         // TIM_ENA = 0 (Timer aktif)



        axi_write(32'h0000_0000, 32'd0);         // TIM_PRE_m = 0
        axi_write(32'h0000_0004, 32'd1453);      // TIM_ARE = 1453
        axi_write(32'h0000_0010, 32'd0);         // TIM_MOD = 0 (Geriye sayma modu)
        axi_write(32'h0000_000C, 32'd1);         // TIM_ENA = 1
        #14540;



        // 3.Adım : TIM_ARE maksimum degerdeyken TIM_CNT FFFF_FFFF e kadar sayıp sonradan kendını sıfırlayıyor mu ?
        $display("--- SENARYO 3: TIM_ARE = Maksimum (FFFF_FFFF) Basliyor ---");

        // Yeni ayarları güvenli yüklemek için önce sayacı durdurup temizleyelim
        axi_write(32'h0000_000C, 32'd0);         // TIM_ENA = 0
        axi_write(32'h0000_0008, 32'h0000_0001); // TIM_CLR = 1
        axi_write(32'h0000_0010, 32'd1);         // TIM_MOD = 1 (Tekrardan 1 yapmamız lazım ki maks degerden 0 a dogru saymasın.)

        // TIM_ARE'ye 32-bitlik en büyük sayıyı yazıyoruz
        axi_write(32'h0000_0004, 32'hFFFF_FFFF); // TIM_ARE = 4294967295
        #50; // AXI yazma işleminin donanımda tam oturması için minik bir bekleme

        // TIM_CNT degerını FFFF_FFFF ye yakın bır degerden baslatıyorum kı sımulasyonu ızlemek kolay olsun.
        force dut.TIM_CNT = 32'hFFFF_FFF0;

        axi_write(32'h0000_000C, 32'd1);         // TIM_ENA = 1
        #10; // Sinyalin kilitlenmesi için 1 clock vuruşu süre

        release dut.TIM_CNT;

        // FFFF_FFF0'dan FFFF_FFFF'e kadar sayıp, tepe noktada TIM_EVN (kesme) bayrağını
        // kaldırarak 0'a tertemiz taşmasını (rollover) izlemek için bekliyoruz.
        wait(dut.TIM_CNT == 32'd0);
        #40;


        // 4.Adım : Axi ile okuma testi
        $display("---SENARYO 4: Axi okuma testi.---");
        axi_write(32'h0000_0004 , 32'd1981); // TIM_ARE ye 1981 yazdık.
        #20; //dalga formunun oturması ıcın bıraz beklıyoruz.
        axi_read(32'h0000_0004, read_data); // TIM_ARE okuyoruz.

        if(read_data == 32'd1981) begin
            $display("AXI okuma testi basarili! Okunan deger: %d",read_data);
        end else begin
            $display("AXI okuma testi basarisiz! Beklenen: 1981, Okunan: %d", read_data);
        end

        #100; // 2. okuma senaryosuna gecmeden once biraz bekliyoruz.

        axi_write(32'h0000_0000, 32'd0);         // TIM_PRE_m = 0
        axi_write(32'h0000_0010, 32'd1);         // TIM_MOD = 1
        axi_write(32'h0000_000C, 32'd1);         // TIM_ENA = 1
        axi_write(32'h0000_0008, 32'h0000_0001); // TIM_CLR = 1

        #250;

        // Sayacı durdurmadan, 0x14 adresindeki TIM_CNT'yi anlık okuyoruz
        axi_read(32'h0000_0014, read_data);


        $display("TEST 2 BASARILI: sayac calisirken anlik sayac (TIM_CNT) degeri %0d olarak okundu!", read_data);

        // Sayacın tepeye (1981'e) ulaşıp tekrar 0'a dönmesini bekle
        wait(dut.TIM_CNT == 32'd0);

        // Sıfırlandığını dalga formunda görmek için minik bir nefes payı
        #50;

        // 5. Adım : Bu senaryoda peşpeşe okuma ve yazma yapacagız.
        axi_write(32'h0000_000C, 32'd0);    // TIM_ENA = 0
        axi_write(32'h0000_0008, 32'd1); // TIM_CLR = 1
        axi_write(32'h0000_0000, 32'd0);   // TIM_PRE_m = 0
        axi_write(32'h0000_0010, 32'd1);    // TIM_MOD = 1
        axi_write(32'h0000_0004, 32'd10);   // TIM_ARE = 10
        axi_write(32'h0000_000C, 32'd1);   // TIM_ENA = 1
        axi_write(32'h0000_0008, 32'd0); // TIM_CLR = 0
        //1.islem
        wait(dut.TIM_EVN > 0);
        axi_read(32'h0000_0018, read_data); // 0018 adresinde TIM_EVN var.Onu kendi registerımıza atıp okuyoruz.
        $display("TIM_EVN kesmesi goruldu: %0d",read_data);

        //2.islem
        wait(dut.TIM_EVN > 0);
        axi_write(32'h0000_001C, 32'd1);
        $display("TIM_EVC'ye 1 yazildi,kesme temizlendi.");

        axi_write(32'h0000_001C, 32'd0); // ardından hemen tim_evc'ye 0 yazıyoruz ki sonraki kesmeleri de görebilelim.


        //3. islem
        axi_read(32'h0000_0018, read_data); // tim_evn'yi tekrar okuyarak kesme temizlenmiş mi kontrol ediyoruz.

        if(read_data == 0) begin
          $display("TIM_EVN basariyla temizlendi. okunan deger : %0d",read_data);
        end else begin
          $display("TIM_EVN temizlenemedi.");
        end


        $display("Sinyal dalga formu akisi basariyla tamamlandi.");
        $finish;
    end

endmodule
