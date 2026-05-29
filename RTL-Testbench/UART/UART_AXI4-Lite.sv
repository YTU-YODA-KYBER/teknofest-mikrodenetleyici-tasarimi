module UART_module (
    // clock ve reset sinyalleri
    input  logic clk,
    input  logic rst_n,

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
    output logic        rvalid,

    input  logic  rx,
    output logic  tx
);
    
    localparam [1:0] IDLE   = 0;
    localparam [1:0] WAIT   = 1;
    localparam [1:0] DATA   = 2;
    localparam [1:0] STOP   = 3;
    localparam [1:0] REPORT = 3;

    logic [2:0] UART_CFG;
    logic [7:0] UART_TDR;
    logic [7:0] UART_RDR;
    logic [7:0] UART_CPB;
    logic [1:0] UART_STP;


    logic       rx_start;         // RX işlemi başladığında tick sayacını sıfırlamak için kullanılır

    logic [1:0] tx_state;         // TX FSM'sinin durumu
    logic [1:0] rx_state;         // RX FSM'sinin durumu
    
    logic [ 3:0] tx_shift_cnt;    // Gönderilen bit sayısını saymak için kullanılır
    logic [ 3:0] rx_shift_cnt;    // Alınan bit sayısını saymak için kullanılır

    logic [15:0] tick_cnt;        // Baud rate'i belirlemek için kullanılan sayaç
    logic [15:0] tick_cnt_limit;  // Baud rate'i belirlemek için kullanılan sayaç limiti
    logic [15:0] cnt_limit_mirror;// Yazma işlemi sırasında baud rate'i değiştirebilmek için kullanılan logicister

    logic [ 1:0] stop_bit;        // Stop bit sayısını takip etmek için kullanılır
    
    logic        middle_alert;    // RX işlemi sırasında orta noktaya gelindiğinde uyarı vermek için kullanılır
    logic [ 4:0] sixteen_cnt_tx;  // TX için 16 baud tick'ini saymak için kullanılır
    logic [ 4:0] sixteen_cnt_rx;  // RX için 16 baud tick'ini saymak için kullanılır


    // ---------------------------------------------------------
    //                  BAUDRATE GENERATOR
    // ---------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin // negedge olarak düzeltildi
        if(!rst_n) begin
            tick_cnt       <= 0;
            sixteen_cnt_tx <= 0;
            sixteen_cnt_rx <= 0;
            tick_cnt_limit <= 5;
        end 
        else begin
            
            if(rx == 0 && !rx_state) rx_start <= 1;

            if(!sixteen_cnt_tx) sixteen_cnt_tx <= 16;
            if(!sixteen_cnt_rx) sixteen_cnt_rx <= 16;

            if(middle_alert) middle_alert <= ~middle_alert;

            if (tick_cnt >= tick_cnt_limit - 1) begin
                tick_cnt_limit <= cnt_limit_mirror;
                tick_cnt <= 0;

                if(rx_start) sixteen_cnt_rx <= 15;
                else sixteen_cnt_rx <= sixteen_cnt_rx - 1;
                rx_start <= 0;

                if(sixteen_cnt_rx == 9) middle_alert <= 1;
                sixteen_cnt_tx <= sixteen_cnt_tx - 1;
            end
            else begin
                tick_cnt <= tick_cnt + 1;
            end
            end
        end


    // ---------------------------------------------------------
    //                  AXI YAZMA/OKUMA IŞLEMLERİ           
    // ---------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            UART_CFG <= 0;
            UART_TDR <= 0;
            UART_RDR <= 0;
            UART_CPB <= 0;
            UART_STP <= 0;

            stop_bit <= 0;

            tx_shift_cnt <= 0;
            rx_shift_cnt <= 0;

            tx_state <= IDLE;
            rx_state <= IDLE;

            bresp   <= 0;
            bvalid  <= 0;
            rresp   <= 0;
            rvalid  <= 0;
            rdata   <= 0;

            awready <= 1;
            wready  <= 1;
            arready <= 1;

            tx      <= 1;
            cnt_limit_mirror <= 5;
            
        end else begin

            // --- AXI YAZMA İŞLEMİ ---
            if (awvalid && wvalid) begin
                bvalid  <= 1'b1;
                awready <= 1'b0; 
                wready  <= 1'b0;
                
                case (awaddr[7:0])
                    8'h00: begin
                        UART_CPB <= wdata;
                        cnt_limit_mirror <= wdata[19:4];
                    end
                    8'h04: UART_STP <= wdata[1:0];
                    8'h0C: UART_TDR <= wdata;
                    8'h10: UART_CFG <= wdata;
                endcase
            end 
            else if (bvalid && bready) begin
                bvalid  <= 1'b0;
                awready <= 1'b1; 
                wready  <= 1'b1;
            end


            // --- AXI OKUMA İŞLEMİ ---
            if (arvalid && arready) begin
                rvalid  <= 1'b1;
                arready <= 1'b0; 
                
                case (araddr[7:0])
                    8'h00: rdata <= UART_CPB;
                    8'h04: rdata <= {29'h0, UART_STP};   
                    8'h08: rdata <= UART_RDR; 
                    8'h0C: rdata <= UART_TDR;
                    8'h10: rdata <= UART_CFG;

                endcase
            end 
            else if (rvalid && rready) begin
                rvalid  <= 1'b0;
                arready <= 1'b1; 
            end



        // ---------------------------------------------------------
        //                        TX BLOĞU
        // ---------------------------------------------------------
        if(!stop_bit) begin
            if(!sixteen_cnt_tx)begin
                case (tx_state)
                    IDLE: begin
                        if (UART_CFG[0]) begin
                            tx <= 0;
                            tx_state <= DATA;
                            tx_shift_cnt <= 0;
                        end
                    end
                    DATA: begin
                        if (tx_shift_cnt == 7) tx_state <= STOP;

                            tx <= UART_TDR[tx_shift_cnt];
                            tx_shift_cnt <= tx_shift_cnt + 1;
                    end
                    STOP: begin
                        tx <= 1;
                        UART_CFG[2] <= 1;
                        UART_CFG[0] <= 0;
                        tx_state <= IDLE;
                        if(UART_STP == 3) stop_bit <= 2;
                        else stop_bit <= UART_STP;
                    end
                endcase
            end
        end
        else begin
            if(sixteen_cnt_tx == 8 || sixteen_cnt_tx == 0) stop_bit <= stop_bit - 1;
        end


        // ---------------------------------------------------------
        //                         RX BLOĞU
        // ---------------------------------------------------------
            case (rx_state)
                IDLE : begin
                    if(rx == 0) rx_state <= WAIT;
                end

                WAIT : begin
                    if(!sixteen_cnt_rx)begin
                        rx_state <= DATA;
                        rx_shift_cnt <= 0;
                    end
                end

                DATA: begin
                    if(middle_alert) begin
                        UART_RDR[rx_shift_cnt] <= rx;
                        if(rx_shift_cnt == 7) rx_state <= REPORT;
                        else rx_shift_cnt <= rx_shift_cnt + 1;
                    end
                end

                REPORT: begin
                    UART_CFG[1] <= 1;
                    rx_state <= IDLE;
                end
            endcase
        end
    end
endmodule
