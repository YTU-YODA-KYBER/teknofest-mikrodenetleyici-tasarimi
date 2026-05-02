
module GPIO_AXI4_Lite(

    // clock ve reset sinyalleri
    input logic clk_i,
    input logic rst_n,

    // GPIO I/O portları
    input  logic [31:0] GPIO_IDR,
    output logic [31:0] GPIO_ODR,

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


    always @(posedge clk_i or negedge rst_n) begin
        
        // ---------------------------------------------------------
        //                      RESET İŞLEMLERİ
        // ---------------------------------------------------------
        if(!rst_n)begin
            GPIO_ODR <= 0;
        
            bresp   <= 0;
            bvalid  <= 0;
            rdata   <= 0;
            rresp   <= 0;
            rvalid  <= 0;
            awready <= 1;
            wready  <= 1;
            arready <= 1;
        end
        else begin

            // ---------------------------------------------------------
            //                      AXI YAZMA İŞLEMİ
            // ---------------------------------------------------------

            if (awvalid && wvalid) begin
                awready <= 0;
                wready  <= 0;
                bvalid  <= 1; 
                
                if (awaddr[3:0] == 4'h4)begin
                    GPIO_ODR <= {16'h0000,wdata[15:0]};
                    end
            end 
            else if (bvalid && bready) begin
                awready <= 1;
                wready  <= 1;
                bvalid  <= 0;
            end


            // ---------------------------------------------------------
            //                  AXI OKUMA İŞLEMİ
            // ---------------------------------------------------------
            if (arvalid) begin
                arready <= 0;
                rvalid  <= 1;
                
                case (araddr[3:0])
                    4'h0:  rdata[31:0] <= GPIO_IDR;
                    4'h4:  rdata[31:0] <= GPIO_ODR; 
                endcase  
            end 
            else if (rvalid && rready) begin
                arready <= 1;
                rvalid  <= 0;
            end
        end
    end  
    
endmodule
