module Timer_module(

//  clock ve reset sinyalleri
input clk,
input rst_n,

//  WRITE ADRESS kanlları
input [31:0]awaddr,
input awvalid,
output reg awready,

//  WRITE kanalları
input [31:0]wdata,
input wvalid,
output reg wready,

//  WRITE RESPONSE kanlları
output reg [1:0] bresp,
output reg bvalid,
input bready,

//  READ ADRESS kanalları
input [31:0]araddr,
input arvalid,
output reg arready,

//  READ kanalları
input rready,
output reg [31:0]rdata,
output reg [1:0]rresp,
output reg rvalid

);
    
    //  REGISTER TANIMLARI      
    reg [31:0]TIM_PRE;
    reg [31:0]TIM_PRE_m;
    reg [31:0]TIM_ARE;
    reg [31:0]TIM_CLR;
    reg [31:0]TIM_ENA;
    reg [31:0]TIM_MOD;
    reg [31:0]TIM_CNT;
    reg [31:0]TIM_EVN;
    reg [31:0]TIM_EVC;
    
    
    
    always @(posedge clk, negedge rst_n) begin
        
        //  RESET
        if (!rst_n) begin
            TIM_PRE <= 32'h0000;
            TIM_ARE <= 32'h0000;
            TIM_CLR <= 32'h0000;
            TIM_ENA <= 32'h0000;
            TIM_MOD <= 32'h0000;
            TIM_CNT <= 32'h0000;
            TIM_EVN <= 32'h0000;
            TIM_EVC <= 32'h0000;
            
            awready <= 1'b1;
            wready <= 1'b1;
            bresp <= 2'b00;
            bvalid <= 1'b0;
            arready <= 1'b1;
            rdata <= 32'h0000;
            rresp <= 2'b00;
            rvalid <= 1'b0;
            end
        else begin
        
        //  WRITE ISLEMI
        if(awvalid && awready && wvalid && wready)begin
            awready <= 0;
            wready <= 0;
            case (awaddr[7:0])
                8'h00:  TIM_PRE_m <= wdata;
                8'h04:  TIM_ARE <= wdata;
                8'h08:  TIM_CLR <= wdata;
                8'h0C:  TIM_ENA <= wdata;
                8'h10:  TIM_MOD <= wdata;
                8'h1C:  TIM_EVC <= wdata;
                endcase
                
            bvalid <= 1;             
            end
            
        else if(bready && bvalid)begin
            bvalid <= 0;
            awready <= 1;
            wready <= 1;
            end
            
        //  OKUMA ISLEMI        
        if (arvalid && arready)begin
            arready <= 0;
            case (araddr[7:0])
                8'h00:  rdata <= TIM_PRE;
                8'h04:  rdata <= TIM_ARE;
                8'h08:  rdata <= TIM_CLR;
                8'h0C:  rdata <= TIM_ENA;
                8'h10:  rdata <= TIM_MOD;
                8'h14:  rdata <= TIM_CNT;
                8'h18:  rdata <= TIM_EVN;
                8'h1C:  rdata <= TIM_EVC;
                endcase
                 rvalid <= 1;
                end
         else if(rvalid && rready)begin
                 rvalid <= 0;
                 arready <= 1;
                 end
    
    
    //  TIMER FONKSIYONU
    if (TIM_CLR)begin 
        TIM_CNT <= 32'h00000000;
        TIM_CLR <= 32'h00000000;
    end
        else if(TIM_ENA)begin
        
            if(TIM_EVC == 1)begin                   
                TIM_EVN <= 0;
                TIM_EVC <= 0;
            end
            
            
             else if(TIM_PRE == 0)begin 
                TIM_PRE <= TIM_PRE_m;

                 case(TIM_MOD)
                 1: begin 
                    if (TIM_CNT == TIM_ARE)begin 
                        TIM_EVN <= TIM_EVN + 1;
                        TIM_CNT <= 32'h00000000;
                    end
                    else begin 
                        TIM_CNT <= TIM_CNT + 1;
                    end
                end
                
                0: begin
                    if (TIM_CNT == 0)begin 
                        TIM_CNT <= TIM_ARE;
                        TIM_EVN <= TIM_EVN + 1;
                    end
                    else begin 
                        TIM_CNT <= TIM_CNT -1;
                    end
                end
                endcase
             end
              else begin 
                    TIM_PRE <= TIM_PRE - 1;
                end
            end
        end
    end
endmodule
