
module GPIO_AXI4_Lite(

    // clock ve reset sinyalleri
    input logic clk_i,
    input logic rst_n,

    // GPIO I/O portları
    input  logic [31:0] GPIO_IDR,
    output logic [31:0] GPIO_ODR,

    // WRITE ADRESS kanalları
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

    // READ ADRESS kanalları
    input  logic [31:0] araddr,
    input  logic        arvalid,
    output logic        arready,

    // READ DATA kanalları
    input  logic        rready,
    output logic [31:0] rdata,
    output logic [ 1:0] rresp,
    output logic        rvalid
);
    
    assign awready = 1;
    assign wready  = 1;
    assign arready = 1;



    always @(posedge clk_i or negedge rst_n) begin
        
        // ---------------------------------------------------------
        //                      RESET İŞLEMLERİ
        // ---------------------------------------------------------
        if(!rst_n)begin
            GPIO_ODR <= 0;
        
            bresp <= 2'b00;
            bvalid <= 1'b0;
            rdata <= 32'h0000;
            rresp <= 2'b00;
            rvalid <= 1'b0;
        end
        else begin

            // ---------------------------------------------------------
            //                      AXI YAZMA İŞLEMİ
            // ---------------------------------------------------------

            if (awvalid && wvalid) begin
                bvalid  <= 1'b1; 
                
                if (awaddr[3:0] == 4'h4)begin
                    GPIO_ODR <= {16'h0000,wdata[15:0]};
                    end
            end 
 
            else if (bvalid && bready) begin
                bvalid  <= 1'b0;
            end


            // ---------------------------------------------------------
            //                  AXI OKUMA İŞLEMİ
            // ---------------------------------------------------------
            if (arvalid) begin
                rvalid  <= 1'b1;
                
                case (araddr[3:0])
                    4'h0:  rdata[31:0] <= GPIO_IDR;
                    4'h4:  rdata[31:0] <= GPIO_ODR; 
                    default: rdata <= 32'd0;               
                endcase  
            end 
            else if (rvalid && rready) begin
                rvalid  <= 1'b0;
            end
        end
    end  
    
endmodule
