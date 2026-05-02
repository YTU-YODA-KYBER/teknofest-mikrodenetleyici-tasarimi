module I2C_Master_AXI4_Lite#(

parameter CLK_FREQ_HZ  = 48_000_000,
parameter I2C_FREQ_HZ  = 400_000,
parameter HALF_PERIOD  = (CLK_FREQ_HZ / (2 * I2C_FREQ_HZ)) - 1
)
(
    // clock ve reset sinyalleri
    input logic clk_i,
    input logic rst_n,

    output logic I2C_SCL,
    inout  wire  I2C_SDA,    

    // AW Portları
    input  logic [31:0] awaddr,
    input  logic        awvalid,
    output logic        awready,

    // WD Portları
    input  logic [31:0] wdata,
    input  logic        wvalid,
    output logic        wready,

    // B Portları
    output logic [ 1:0] bresp,
    output logic        bvalid,
    input  logic        bready,

    // AR Portları
    input  logic [31:0] araddr,
    input  logic        arvalid,
    output logic        arready,

    // R Portları
    input  logic        rready,
    output logic [31:0] rdata,
    output logic [ 1:0] rresp,
    output logic        rvalid
);
    
    logic [31: 0] I2C_NBY;
    logic [31: 0] I2C_ADR;
    logic [31: 0] I2C_RDR;
    logic [31: 0] I2C_TDR;
    logic [31: 0] I2C_CFG;
    logic [ 1: 0] I2C_CFG_clr;


    logic [ 6: 0] freq_div_cnt;   // Frekans bölücünün sayacıdır.
    logic         freq_div_en;    // SCL'yi açma/kapama logicister'ı.
    logic [ 2: 0] current_state;  // FSM içindeki durum belirteci.
    logic [ 7: 0] shift_byte;     // Yazma/okuma yaparken kullanılan logicister.
    logic [ 2: 0] shift_cnt;      // 8 kaydırma işlemi yapmak için güncel değeri aklında tutan logicister.  
    logic [ 2: 0] nby_cnt;        // Kaç baytın yazılacağı/okunacağı verisini tutan logicister.
    logic [ 2: 0] byte_cnt;       // Kaçıncı baytın yazıldığı/okunduğu verisini tutan logicister.
    logic         restart;        // Okuma yaparken restart yapmaya yarayan logicister.
    logic         r_w;            // İşlemin 1 ise okuma, 0 ise yazma olduğunu belirtir.
    logic         delay;          // FSM'nin doğru çalışması için işlemi 1 döngü geciktirmeye yarar.          
    logic         is_read_op;     // Okuma işleminin yazma fazında mı yoksa okuma fazında mı olduğunu belirten logicister.
    logic         sda_out_val;    // FSM'ler içinde I2C_SDA'nın değerini değiştirmek için kullanılır.
    //--------------------------------------------------------------------------
    // NOT: I2C protokolünde okuma işlemi kısaca sırasıyla şöyle gerçekleşir:
    // -Start
    // -Verinin okunacağı çevre biriminin adresi(yazma fazı)
    // -ACK
    // -Verinin okunacağı logicister'ın adresi(yazma fazı)
    // -ACK
    // -Restart
    // -Verinin okunacağı verinin adresi(okuma fazı)
    // -ACK
    // -Slave veriyi gönderir, okur ve kaydederiz(okuma fazı)
    // -NACK
    // -Stop
    //--------------------------------------------------------------------------
    localparam load_data        = 1;
    localparam push_data        = 2;
    localparam decide           = 3;
    localparam ack              = 4;
    localparam stop_and_clear   = 5;
    localparam idle             = 6;
      
    // SDA portunu sürme işlemi  
    assign I2C_SDA = (sda_out_val == 1'b0) ? 1'b0 : 1'bz;  
        


    // ---------------------------------------------------------
    //                    SCL DIVIDER(400KHz)
    // ---------------------------------------------------------
    always @(posedge clk_i or negedge rst_n) begin
        if(!rst_n)begin
            I2C_SCL <= 1;
            freq_div_cnt <= 0;
        end
        else begin
            if (freq_div_en) begin
            
                if(freq_div_cnt == HALF_PERIOD)begin
                    freq_div_cnt <= 0;
                    I2C_SCL      <= ~I2C_SCL;
                end    
                else freq_div_cnt <= freq_div_cnt + 1; 
            end
            else begin
                freq_div_cnt <= 0;
                I2C_SCL <= 1;
                end
        end
    end  



    always @(posedge clk_i or negedge rst_n) begin
        
        // ---------------------------------------------------------
        //                      RESET İŞLEMLERİ
        // ---------------------------------------------------------
        if(!rst_n)begin
            I2C_NBY <= 0;
            I2C_ADR <= 0;
            I2C_RDR <= 0;
            I2C_TDR <= 0;
            I2C_CFG <= 0;
                        
            shift_byte      <= 0;
            shift_cnt       <= 0;
            byte_cnt        <= 0;
            restart         <= 0;
            r_w             <= 0;
            is_read_op      <= 0;
            freq_div_en     <= 0;
            delay           <= 0;
            bresp           <= 0;
            bvalid          <= 0;
            rdata           <= 0;
            rresp           <= 0;
            rvalid          <= 0;
            awready         <= 1;
            wready          <= 1;
            arready         <= 1;
            sda_out_val     <= 1;
            current_state   <= push_data;

        end
        else begin

            
            // ---------------------------------------------------------
            //                      AXI YAZMA İŞLEMİ
            // ---------------------------------------------------------
            if (awvalid && wvalid) begin
                awready <= 1'b0;
                wready  <= 1'b0;
                bvalid  <= 1'b1; 
                
                case (awaddr[7:0])
                    8'h00:if (wdata > 4)   I2C_NBY  <= 4;
                          else if (!wdata) I2C_NBY  <= 1;
                          else             I2C_NBY  <= wdata;
                    8'h04: I2C_ADR      <= wdata;
                    8'h0C: I2C_TDR      <= wdata;
                    8'h10: I2C_CFG      <= wdata;
                    8'h14: I2C_CFG_clr  <= wdata[1:0]; 
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
                rvalid  <= 1;
                
                case (araddr[7:0])
                    8'h00: rdata <= I2C_NBY;
                    8'h04: rdata <= I2C_ADR;
                    8'h08: rdata <= I2C_RDR;
                    8'h0C: rdata <= I2C_TDR;
                    8'h10: rdata <= I2C_CFG;
                endcase
            end 
            else if (rvalid && rready) begin
                rvalid  <= 0;
                arready <= 1;
            end 
            

            // ---------------------------------------------------------
            //                       I2C ÇEKİRDEĞİ 
            // ---------------------------------------------------------

            if(I2C_CFG[0] || I2C_CFG[2]) begin

                if (!freq_div_en) begin 
                    if (I2C_CFG[0]) nby_cnt <= I2C_NBY;
                    else            nby_cnt <= 1;
                    sda_out_val     <= 0;
                    byte_cnt        <= 0;
                    r_w             <= 0;
                    is_read_op      <= 0;
                    awready         <= 0;
                    wready          <= 0;
                    freq_div_en     <= 1;
                    shift_byte      <= {I2C_ADR[6:0], 1'h0};
                    shift_cnt       <= 7; 
                    current_state   <= push_data;
                end

                if (freq_div_cnt == 29 && freq_div_en)begin
                    if(restart)begin
                        if(I2C_SCL)begin
                            sda_out_val     <= 0;
                            nby_cnt         <= 0;
                            restart         <= 0;
                            is_read_op      <= 1;
                            shift_byte      <= {I2C_ADR[6:0],1'b1};
                            current_state   <= push_data;
                        end
                    end
                    else begin
                        case(current_state)

                            0: begin
                                if (!I2C_SCL) begin
                                    current_state       <= load_data;
                                    if(r_w)sda_out_val  <= 0;
                                    else   sda_out_val  <= 1;
                                end
                            end

                            load_data: begin
                                if (I2C_SCL && !r_w) begin
                                    if (!I2C_SDA) begin
                                        current_state <= push_data;

                                        case (byte_cnt)
                                            1: shift_byte <= I2C_TDR[7:0];
                                            2: shift_byte <= I2C_TDR[15:8];
                                            3: shift_byte <= I2C_TDR[23:16];
                                            4: shift_byte <= I2C_TDR[31:24];
                                        endcase
                                    end
                                    else begin
                                        current_state <= decide;
                                    end
                                end 
                                else if (!I2C_SCL && r_w) begin
                                    sda_out_val     <= 1;
                                    current_state   <= push_data; 
                                    
                                    case (byte_cnt)
                                        1: I2C_RDR[ 7: 0] <= shift_byte[7:0];
                                        2: I2C_RDR[15: 8] <= shift_byte[7:0];
                                        3: I2C_RDR[23:16] <= shift_byte[7:0];
                                        4: I2C_RDR[31:24] <= shift_byte[7:0];
                                    endcase
                                end
                            end
                        
                            push_data: begin
                                case(r_w)
                                    0:begin
                                        if (!I2C_SCL) begin
                                            sda_out_val <= shift_byte[7];   
                                            shift_byte  <= shift_byte << 1; 

                                            if (!shift_cnt)begin
                                                shift_cnt <= 3'd7;

                                                    if(nby_cnt)begin
                                                        byte_cnt        <= byte_cnt +1;
                                                        nby_cnt         <= nby_cnt -1;
                                                        current_state   <= 0;
                                                    end
                                                    else begin
                                                        byte_cnt        <= 1;
                                                        current_state   <= decide;
                                                    end
                                                end

                                            else begin
                                                shift_cnt <= shift_cnt - 1;
                                            end
                                        end
                                    end

                                    1:begin
                                        if (I2C_SCL) begin
                                            shift_byte <= {shift_byte[6:0], I2C_SDA};

                                            if (!shift_cnt)begin
                                                shift_cnt <= 3'd7;

                                                if(nby_cnt > 1)begin
                                                    byte_cnt        <= byte_cnt +1;
                                                    nby_cnt         <= nby_cnt -1;
                                                    current_state   <= 0;
                                                end
                                                else begin
                                                    byte_cnt        <= 0;
                                                    current_state   <= decide;
                                                end
                                            end

                                            else begin
                                                shift_cnt <= shift_cnt - 1;
                                            end
                                        end
                                    end
                                endcase//r_w    
                            end//case_2
                            
                            decide: begin
                                if (!I2C_CFG[0]) begin
                                    if (I2C_SCL && r_w) begin
                                            case (I2C_NBY)
                                                1: I2C_RDR[ 7: 0] <= shift_byte[7:0];
                                                2: I2C_RDR[15: 8] <= shift_byte[7:0];
                                                3: I2C_RDR[23:16] <= shift_byte[7:0];
                                                4: I2C_RDR[31:24] <= shift_byte[7:0];
                                            endcase
                                            current_state <= stop_and_clear;
                                    end
                                    else if(!I2C_SCL && !r_w) begin
                                        if(delay)begin
                                            if(!is_read_op)restart <= 1;
                                            else begin
                                                r_w     <= 1;
                                                nby_cnt <= I2C_NBY;
                                            end 
                                            byte_cnt        <= 0;
                                            sda_out_val     <= 1;
                                            current_state   <= load_data;
                                        end
                                        else delay <= ~delay;
                                    end                                
                                end
                                else if(!I2C_SCL) begin
                                        current_state   <= ack;
                                    end
                            end

                            ack: begin
                                if(I2C_SCL && !I2C_SDA) current_state <= stop_and_clear;
                            end

                            stop_and_clear : begin
                                if (!I2C_SCL) sda_out_val <= 0;
                                if (I2C_SCL) begin
                                    sda_out_val <= 1;
                                    shift_cnt   <= 7;
                                    byte_cnt    <= 1;
                                    awready     <= 1;
                                    wready      <= 1;

                                    freq_div_en     <= 1'b0;                                
                                    current_state   <= idle;

                                    if(r_w)begin
                                        I2C_CFG[2] <= 1'b0; 
                                        I2C_CFG[3] <= 1'b1;
                                    end
                                    else begin
                                        I2C_CFG[1] <= 1'b1; 
                                        I2C_CFG[0] <= 1'b0;
                                    end
                                end    
                            end
                            idle:begin
                                if(I2C_CFG_clr[0])I2C_CFG[1] <= 0;
                                if(I2C_CFG_clr[1])I2C_CFG[3] <= 0;
                            end

                        endcase//current_state  
                    end
                end//case_up_if
            end//çekirdek_yazma_if    
        end//else                  
    end//always 
endmodule
