module QSPI_Master_AXI4_Lite(

    // clock ve reset sinyalleri
    input logic clk_i,
    input logic rst_n,  

    // WRITE ADDRESS kanalları
    input  logic [31:0] awaddr,
    input  logic        awvalid,
    output logic        awready,

    // WRITE DATA kanalları
    input  logic [31:0] wdata,
    input  logic        wvalid,
    output logic        wready,

    // WRITE RESPONSE kanalları
    output logic [ 1:0] bresp,
    output logic        bvalid,
    input  logic        bready,

    // READ ADDRESS kanalları
    input  logic [31:0] araddr,
    input  logic        arvalid,
    output logic        arready,

    // READ DATA kanalları
    input  logic        rready,
    output logic [31:0] rdata,
    output logic [ 1:0] rresp,
    output logic        rvalid,


    output logic QSPI_SCLK,
    output logic QSPI_CS,

    // I/O Portları
    inout  logic QSPI_IO0,
    inout  logic QSPI_IO1,
    inout  logic QSPI_IO2,
    inout  logic QSPI_IO3

    );

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


    logic [31:0] QSPI_CCR;
    logic [31:0] QSPI_ADR;
    logic [31:0] QSPI_DR;
    logic [31:0] QSPI_DR_read;
    logic [31:0] QSPI_STA;
    logic [31:0] QSPI_FCR;
   
    // BRAM yerine LUTRAM kullanıyoruz
    (* ram_style = "distributed" *) logic [31:0] FIFO_TX [0:63];
    (* ram_style = "distributed" *) logic [31:0] FIFO_RX [0:63];

    logic [31:0] fifo_tx_rdata; // TX FIFO'dan okunan veriyi tutar.
    logic [31:0] fifo_tx_wdata; // TX FIFO'ya yazılacak veriyi tutar.
    logic [ 6:0] fifo_tx_cnt;   // TX FIFO'nun güncel doluluk sayısını tutar.
    logic [ 5:0] tx_wr_ptr;     // TX FIFO'ya yazacağı yeri gösterir.
    logic [ 5:0] tx_rd_ptr;     // TX FIFO'ya yazılacak yeri gösterir.

    logic [31:0] fifo_rx_rdata; // RX FIFO'dan okunan veriyi tutar.
    logic [31:0] fifo_rx_wdata; // RX FIFO'ya yazılacak veriyi tutar.
    logic [ 6:0] fifo_rx_cnt;   // RX FIFO'nun güncel doluluk sayısını tutar.
    logic [ 5:0] rx_wr_ptr;     // RX FIFO'ya yazacağı yeri gösterir.
    logic [ 5:0] rx_rd_ptr;     // RX FIFO'ya yazılacak yeri gösterir.


    localparam IDLE  = 1;
    localparam SEND  = 2;
    localparam LOAD  = 3;

    localparam x1  = 1;
    localparam x2  = 2;
    localparam x4  = 4;

    localparam read   = 0;
    localparam write  = 1;

    logic [ 2:0] fifo_status;       // QSPI ile FIFO I/O işleminin hangi FSM'de olduğunu gösterir.
    logic [ 5:0] prscl_cnt;         // Clk divider için kullanılan sayacın verisini tutar.
    logic        busy;              // Modül flaş bellek ile ilgilenirken değeri 1 olur.
    logic [ 3:0] to_do_list;        // 0. instruction, 1. adres, 2. dummy, 3. bit ise data'nın varlığını temsil ediyor.
    logic        address;           // Yapılacak işlemde adres gönderme fazı varsa değeri 1 olur.
    logic        fifo_rx_pull_data; // Değeri 1 olduğunda RX FIFO'su yeni verisini "fifo_rx_rdata"ya yükler.
    logic        fifo_tx_wr_en;     // TX FIFO'ya "fifo_tx_wdata"daki veriyi yazma sinyali gönderir.
    logic        fifo_rx_wr_en;     // RX FIFO'ya "fifo_tx_wdata"daki veriyi yazma sinyali gönderir.
    logic [ 2:0] data_mode;         // Verinin hangi modda (x1, x2 ya da x4) modunda işleme alınacağının bilgisini tutar.
    logic [ 5:0] shift_cnt;         // FIFO'da veri kaydırma işlemlerinde veri uzunluğu hesaplanırken kullanılır.
    logic [31:0] shift_byte;        // FIFO'da veri kaydırma işlemlerinde kaydırılan veriyi tutar.
    logic        r_w;               // Yapılan işlemin yazma mı yoksa okuma mı olduğu bilgisini tutar.
    logic [ 7:0] data_byte_size;    // Flaşa yazılacak/okunacak kaç bayt verinin kaldığının bilgisini tutar.
    logic [ 7:0] instr_shadow;      // Yeni buyruğun gelip gelmediğini anlamak için önceki buyruğun değerini tutar.
    logic [ 4:0] dummy_cycle;       // Güncel yapılacak dummy cycle sayısını tutar
    logic        rx_pull_once;      // LOAD FSM'sinde AXI üzerinden okunacak ilk veriyi hazır etmek için FIFO'ya istek gönderir.
    logic        fifo_tx_push_data; // AXI TX FIFO'ya yazma isteği gönderdiği zaman gelen veriyi yazmak için FIFO'ya istek gönderir.
    logic        qspi_falling_edge; // QSPI modülünün çalışması için ayarlanan frekanstaki falling edge durumundan 1 clk önce 1 olur.
    logic        qspi_rising_edge;  // QSPI modülünün çalışması için ayarlanan frekanstaki rising edge durumundan 1 clk önce 1 olur.
    logic [ 3:0] fifo_error;        // QSPI_STA register'ının değerini güncellemek için kullanılır.

    logic io0_val;
    logic io1_val;
    logic io2_val;
    logic io3_val;


    // ---------------------------------------------------------
    //                      CLK DIVIDER
    // ---------------------------------------------------------
    always @(posedge clk_i or negedge rst_n) begin

        if(!rst_n)begin
            prscl_cnt <= 0;
            QSPI_SCLK <= 0;
            qspi_falling_edge <= 0;
            qspi_rising_edge  <= 0;
        end
        else if(!QSPI_CS)begin
            if(QSPI_CCR[30:25] == 1 && !QSPI_SCLK) qspi_falling_edge <= 1;
            else if(prscl_cnt + 2 == QSPI_CCR[30:25] && QSPI_SCLK) qspi_falling_edge <= 1;
            else qspi_falling_edge <= 0;

            if(QSPI_CCR[30:25] == 1 && QSPI_SCLK) qspi_rising_edge <= 1;
            else if(prscl_cnt + 2 == QSPI_CCR[30:25] && !QSPI_SCLK) qspi_rising_edge <= 1;
            else qspi_rising_edge <= 0;

            if(prscl_cnt == QSPI_CCR[30:25]-1)begin
                prscl_cnt <= 0;
                QSPI_SCLK <= ~QSPI_SCLK;
            end
            else prscl_cnt <= prscl_cnt +1;
        end
    end

    // ---------------------------------------------------------
    //                      FIFO'LAR
    // ---------------------------------------------------------
    always @(posedge clk_i) begin
        // TX WRITE  
        if(fifo_tx_wr_en) FIFO_TX[tx_wr_ptr] <= fifo_tx_wdata;
        // TX READ - registered output (BRAM doğası)
        fifo_tx_rdata <= FIFO_TX[tx_rd_ptr];
    end
    always @(posedge clk_i) begin
        // RX WRITE  
        if(fifo_rx_wr_en) FIFO_RX[rx_wr_ptr] <= fifo_rx_wdata;
        // RX READ - registered output
        fifo_rx_rdata <= FIFO_RX[rx_rd_ptr];
    end


    assign QSPI_IO0 = io0_val;
    assign QSPI_IO1 = io1_val;
    assign QSPI_IO2 = io2_val;
    assign QSPI_IO3 = io3_val;


    always@(posedge clk_i or negedge rst_n)begin
        if(!rst_n)begin
            QSPI_STA <= 0;
        end
        else if(QSPI_CCR[31]) QSPI_STA <= 0;
        else begin
        QSPI_STA[1]    <= busy;
        QSPI_STA[4]    <= fifo_rx_cnt == 64;     // RX FIFO full.
        QSPI_STA[5]    <= fifo_rx_cnt ? 0 : 1;   // RX FIFO empty.
        QSPI_STA[6]    <= fifo_tx_cnt == 64;     // TX FIFO full.
        QSPI_STA[7]    <= fifo_tx_cnt ? 0 : 1;   // TX FIFO empty.
        QSPI_STA[11:8] <= fifo_error;            // '0000' Hata yok.
                                                 // '0001' RX FIFO boşken okunmaya çalışıldı.
                                                 // '0010' TX FIFO doluyken yazılmaya çalışıldı.
        end
    end


    //FIFO'lar
    always @(posedge clk_i or negedge rst_n) begin

        if(!rst_n)begin
            fifo_tx_wr_en <= 0;
            fifo_rx_wr_en <= 0;

            fifo_rx_cnt <= 0;
            rx_wr_ptr   <= 63;
            rx_rd_ptr   <= 0;
            fifo_tx_cnt <= 0;
            tx_wr_ptr   <= 63;
            tx_rd_ptr   <= 0;

            busy            <= 0;
            fifo_error      <= 0;
            r_w             <= 0;
            rx_pull_once    <= 0;
            dummy_cycle     <= 0;
            instr_shadow    <= 0;
            data_byte_size  <= 0;
            shift_byte      <= 0;
            shift_cnt       <= 0;
            to_do_list      <= 0;
            data_mode       <= 1;
            QSPI_CS         <= 1;
            fifo_status     <= IDLE;

            io0_val <= 1'bz;
            io1_val <= 1'bz;
            io2_val <= 1'bz;
            io3_val <= 1'bz; 
        end
        else begin

            if(fifo_tx_wr_en == 1)fifo_tx_wr_en <= 0;
            if(fifo_rx_wr_en == 1)fifo_rx_wr_en <= 0;
            if(rx_pull_once  == 1)rx_pull_once  <= 0;

            if(QSPI_FCR[0])begin
                    fifo_rx_cnt <= 0;
                    rx_wr_ptr   <= 63;
                    rx_rd_ptr   <= 0;
                end
            if(QSPI_FCR[1])begin
                    fifo_tx_cnt <= 0;
                    tx_wr_ptr   <= 63;
                    tx_rd_ptr   <= 0;
                end

            // TX FIFO'ya data yazma isteği
            if(fifo_tx_push_data && !QSPI_STA[6]) begin
                fifo_tx_wr_en <= 1;

                fifo_tx_wdata <= QSPI_DR;
                tx_wr_ptr <= tx_wr_ptr +1;
                fifo_tx_cnt <= fifo_tx_cnt +1;
                if(tx_wr_ptr == 63) tx_wr_ptr <= 0;
            end

            // RX FIFO'dan data okuma isteği
            if((fifo_rx_pull_data || rx_pull_once) && !QSPI_STA[5]) begin
                QSPI_DR_read <= fifo_rx_rdata;
                rx_rd_ptr <= rx_rd_ptr +1;
                fifo_rx_cnt <= fifo_rx_cnt -1;
                if(rx_rd_ptr == 63) rx_rd_ptr <= 0;
            end

            if(fifo_tx_wr_en && QSPI_STA[6]) fifo_error[1] <= 1;
            if((fifo_rx_pull_data || rx_pull_once) && QSPI_STA[4])fifo_error[0] <= 1;

            case(fifo_status)

                IDLE: begin
                    // instruction değeri değişti mi? değiştiyse ve müsaitsek yeni bir görev var demektir, yani start demek.
                    if(!(QSPI_CCR[7:0] == instr_shadow) && !QSPI_STA[1])begin
                        instr_shadow <= QSPI_CCR[7:0];
                        shift_byte[31:25] <= QSPI_CCR[6:0];
                        busy <= 1;
                        to_do_list[0] <= 1;
                        to_do_list[1] <= address;
                        to_do_list[2] <= |QSPI_CCR[15:11];
                        to_do_list[3] <= |QSPI_CCR[9:8];
                        data_byte_size <= QSPI_CCR[23:16] + 1;
                        QSPI_CS <= 0;

                        io0_val <= QSPI_CCR[7];

                        fifo_status <= SEND;

                        shift_cnt <= 7;
                        r_w <= write;
                    
                        dummy_cycle <= QSPI_CCR[15:11];
                    end
                    else begin
                        if(qspi_falling_edge)begin
                            QSPI_CS <= 1;
                            busy <= 0;
                            data_mode <= 1;
                            
                            io0_val <= 1'bz;
                            io1_val <= 1'bz;
                            io2_val <= 1'bz;
                            io3_val <= 1'bz;
                        end 
                    end
                end

                SEND: begin
                        case(r_w)

                            read: begin
                                if(qspi_rising_edge) begin
                                    case(data_mode)
                                        x1: begin
                                            shift_byte <= {shift_byte[30:0], QSPI_IO0};
                                        end
                                        x2: begin
                                            shift_byte <= {shift_byte[29:0], QSPI_IO1, QSPI_IO0};
                                        end
                                        x4: begin
                                            shift_byte <= {shift_byte[27:0], QSPI_IO3, QSPI_IO2, QSPI_IO1, QSPI_IO0};
                                        end
                                    endcase
                                end
                            end

                            write: begin
                                if(qspi_falling_edge)begin
                                    case(data_mode)
                                        x1: begin
                                            io0_val  <= shift_byte[31];  
                                            shift_byte <= shift_byte << 1;
                                        end

                                        x2: begin
                                            io0_val <= shift_byte[30];
                                            io1_val <= shift_byte[31];
                                            shift_byte  <= shift_byte << 2;

                                        end

                                        x4: begin
                                            io0_val <= shift_byte[28];
                                            io1_val <= shift_byte[29];
                                            io2_val <= shift_byte[30];
                                            io3_val <= shift_byte[31];
                                            shift_byte <= shift_byte << 4;
                                        end
                                    endcase
                                end
                            end
                        endcase
                        if(qspi_falling_edge || (!r_w && shift_cnt == data_mode))begin
                            if (shift_cnt == data_mode)begin
                                io0_val <= 1'bz;
                                io1_val <= 1'bz;
                                io2_val <= 1'bz;
                                io3_val <= 1'bz;

                                if (to_do_list[1:0] == 3) to_do_list[0] <= 0;
                                else if (to_do_list[1:0]) begin
                                    r_w <= QSPI_CCR[10];
                                    to_do_list[1:0] <= 0;
                                    data_mode <= QSPI_CCR[9:8];
                                    if(QSPI_CCR[9:8] == 3) data_mode <= 4;
                                end
                                else if (to_do_list[2])begin
                                    to_do_list[2] <= 0;
                                end
                                else if (to_do_list[3]) to_do_list[3] <= 0;
                                if(!data_byte_size) to_do_list <= 0;
                                fifo_status <= LOAD;
                            end
                                else shift_cnt <= shift_cnt - data_mode;
                        end
                    end


                LOAD:begin
                    if (to_do_list[1])begin
                        shift_byte[31:8]  <= QSPI_ADR[23:0];
                        shift_cnt <= 24;
                        fifo_status <= SEND;
                    end

                    else if (to_do_list[2])begin

                        if(qspi_falling_edge) begin
                            if (dummy_cycle)begin
                                dummy_cycle <= dummy_cycle -1;
                            end
                            else begin
                                if(data_byte_size > 3) begin
                                    shift_cnt <= 32;
                                    data_byte_size <= data_byte_size -4;
                                    to_do_list[2] <= 1;
                                    end
                                else begin 
                                    case (data_byte_size)
                                        1: shift_cnt <= 8;
                                        2: shift_cnt <= 16;
                                        3: shift_cnt <= 24;
                                    endcase
                                end
                                fifo_status <= SEND;
                            end
                        end
                    end

                    else if (to_do_list[3])begin

                        if(data_byte_size > 3) begin
                            shift_cnt <= 32;
                            data_byte_size <= data_byte_size -4;
                            to_do_list[2] <= 1;
                        end
                        else begin 
                            case (data_byte_size)
                                1: shift_cnt <= 8;
                                2: shift_cnt <= 16;
                                3: shift_cnt <= 24;
                            endcase
                        end
                        if (r_w) begin
                            shift_byte <= {fifo_tx_rdata[7:0],
                                           fifo_tx_rdata[15:8],
                                           fifo_tx_rdata[23:16],
                                           fifo_tx_rdata[31:24]
                                           };
                            tx_rd_ptr <= tx_rd_ptr +1;
                            if(tx_rd_ptr == 63) tx_rd_ptr <= 0;
                            fifo_tx_cnt <= fifo_tx_cnt -1;
                        end
                        else begin
                            fifo_rx_wr_en <= 1;
                            fifo_rx_wdata <={shift_byte[7:0],
                                            shift_byte[15:8],
                                            shift_byte[23:16],
                                            shift_byte[31:24]
                                            };
                            rx_wr_ptr <= rx_wr_ptr +1;
                            if(rx_wr_ptr == 63) rx_wr_ptr <= 0;
                            fifo_rx_cnt <= fifo_rx_cnt +1;
                        end

                        fifo_status <= SEND;
                    end

                    else begin
                        if(!r_w) begin 
                                rx_pull_once <= ~rx_pull_once;
                                QSPI_CS <= 1;
                        end
                        fifo_status <= IDLE;

                    end

                end

            endcase

            end

        end




    always @(posedge clk_i or negedge rst_n) begin
       
        // ---------------------------------------------------------
        //                      RESET İŞLEMLERİ
        // ---------------------------------------------------------
        if(!rst_n)begin
            QSPI_CCR <= 0;
            QSPI_ADR <= 0;
            QSPI_DR <= 0;
            QSPI_FCR <= 0;
   
            bresp <= 2'b00;
            bvalid <= 1'b0;
            rdata <= 32'h0000;
            rresp <= 2'b00;
            rvalid <= 1'b0;
            awready <= 1;
            wready <= 1;
            arready <= 1;
            
            fifo_tx_push_data <= 0; 
            fifo_rx_pull_data <= 0;
            address <= 0;
        end
        else begin

            if(fifo_rx_pull_data) fifo_rx_pull_data <= 0;
            if(fifo_tx_push_data) fifo_tx_push_data <= 0;

            // ---------------------------------------------------------
            //                      AXI YAZMA İŞLEMİ
            // ---------------------------------------------------------

            if (awvalid && wvalid) begin
                awready <= 1'b0;
                wready  <= 1'b0;
                bvalid  <= 1'b1;
               
                case (awaddr[7:0])
                    8'h00: QSPI_CCR <= wdata;
                    8'h04: QSPI_ADR <= wdata;
                    8'h08: begin
                            QSPI_DR  <= wdata;
                            fifo_tx_push_data <= 1;
                        end                     
                    8'h10: QSPI_FCR <= wdata;
                    8'h14: address  <= wdata;
                endcase
            end  

            else if (bvalid && bready) begin
                bvalid  <= 1'b0;
                awready <= 1'b1;
                wready  <= 1'b1;
            end


            // ---------------------------------------------------------
            //                  AXI OKUMA İŞLEMİ
            // ---------------------------------------------------------
            if (arvalid) begin
                arready <= 0;
                rvalid  <= 1'b1;
               
                case (araddr[7:0])
                    8'h00: rdata <= QSPI_CCR;
                    8'h04: rdata <= QSPI_ADR;
                    8'h08: begin
                            rdata <= QSPI_DR_read;
                            fifo_rx_pull_data <= 1;                        
                    end                 
                    8'h0C: rdata <= QSPI_STA;
                    8'h10: rdata <= QSPI_FCR;

                  default: rdata <= 32'h00000000;
                endcase
            end
            else if (rvalid && rready) begin
                arready <= 1;
                rvalid  <= 1'b0;                        
            end

        end
    end

endmodule