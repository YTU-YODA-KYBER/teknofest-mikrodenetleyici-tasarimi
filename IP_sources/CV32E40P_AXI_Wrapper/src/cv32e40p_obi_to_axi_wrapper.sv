
import obi_pkg::*;
import axi_port_pkg::*;
import obi_port_pkg::*;

module cv32e40p_obi_to_axi_wrapper#(

    parameter logic [31:0] boot_addr         = 32'h1A00_0000,   //BASLANGIC ADRESI
    parameter logic [31:0] mtvec_addr        = 32'h1F00_0000,   //INTERRUPT GELDIGINDE ISLEMCININ ATLAYACAGI ADRES 
    parameter logic [31:0] dm_halt_addr      = 32'h2F0_0000,    //JTAG KULLANILMAK ISTENDIGINDE ISLEMCISNIN ATLAYACAGI ADRES  
    parameter logic [31:0] hart_id           = 32'h0000_0000,   //CEKIRDEGIN NUMARASI
    parameter logic [31:0] dm_exception_addr = 32'h3F00_0000    //JTAG KULLANILIRKEN HATA OLUSULURSA ISLEMCININ ATLAYACAGI ADRES
)

(
    //  GLOBAL CLOCK VE RESET
    input logic clk_i,
    input logic rst_ni,

    
    //  AR PORTLARI
    output logic [ 3:0] axi_arid,
    output logic [31:0] axi_araddr,
    output logic [ 3:0] axi_arlen,
    output logic [ 2:0] axi_arsize,
    output logic [ 1:0] axi_arburst,
    output logic [ 2:0] axi_arprot,
    output logic        axi_arvalid,
    input  logic        axi_arready,
    
    //  R PORTLARI
    input  logic [ 3:0] axi_rid,
    input  logic [31:0] axi_rdata,
    input  logic [ 1:0] axi_rresp,
    input  logic        axi_rlast,
    input  logic        axi_rvalid,
    output logic        axi_rready,
    
    
    
    
    //  DATA AW PORTLARI
    output logic [ 3:0] axi_data_awid,
    output logic [31:0] axi_data_awaddr,
    output logic [ 3:0] axi_data_awlen,
    output logic [ 2:0] axi_data_awsize,
    output logic [ 1:0] axi_data_awburst,
    output logic [ 2:0] axi_data_awprot,
    output logic        axi_data_awvalid,
    input  logic        axi_data_awready,
    
    //  DATA W PORTLARI
    output logic [31:0] axi_data_wdata,
    output logic [ 3:0] axi_data_wstrb,
    output logic        axi_data_wlast,
    output logic        axi_data_wvalid,
    input  logic        axi_data_wready,
    
    //  DATA B PORTLARI
    input  logic [ 3:0] axi_data_bid,
    input  logic [ 1:0] axi_data_bresp,
    input  logic        axi_data_bvalid,
    output logic        axi_data_bready,
    
    //  DATA AR PORTLARI
    output logic [ 3:0] axi_data_arid,
    output logic [31:0] axi_data_araddr,
    output logic [ 3:0] axi_data_arlen,
    output logic [ 2:0] axi_data_arsize,
    output logic [ 1:0] axi_data_arburst,
    output logic [ 2:0] axi_data_arprot,
    output logic        axi_data_arvalid,
    input  logic        axi_data_arready,
    
    //  DATA R PORTLARI
    input  logic [ 3:0] axi_data_rid,
    input  logic [31:0] axi_data_rdata,
    input  logic [ 1:0] axi_data_rresp,
    input  logic        axi_data_rlast,
    input  logic        axi_data_rvalid,
    output logic        axi_data_rready
    );
    
    
    
    
    
    // INSTRUCTION MEMORY PORTLARI
    logic instr_req;  
    logic instr_gnt;  
    logic instr_rvalid;
    logic [31:0]instr_addr; 
    logic [31:0]instr_rdata;

    // DATA MEMORY PORTLARI
    logic        data_req;
    logic        data_gnt;
    logic        data_rvalid;
    logic        data_we;
    logic [ 3:0] data_be;
    logic [31:0] data_addr;
    logic [31:0] data_wdata;
    logic [31:0] data_rdata;
    
    // INTERRUPT PORTLARI
    logic [31:0] irq = 32'd0;
    logic        irq_ack;
    logic [ 4:0] irq_id;
    
    // DEBUG PORTLARI
    logic debug_req;
    logic debug_havereset;
    logic debug_running;
    logic debug_halted;

    // CPU KONTROL PORTLARI
    logic fetch_enable = 1'd1;
    logic core_sleep;
    
    
    cv32e40p_top
    CORE (
    // Clock and Reset
    .clk_i               (clk_i),
    .rst_ni              (rst_ni),
    
    .pulp_clock_en_i     (1'b1),
    .scan_cg_en_i        (1'b0),
    
    // Core ID, Cluster ID, debug mode halt address and boot address are considered more or less static
    .boot_addr_i         (boot_addr),
    .mtvec_addr_i        (mtvec_addr),
    .dm_halt_addr_i      (dm_halt_addr),
    .hart_id_i           (hart_id),
    .dm_exception_addr_i (dm_exception_addr),
    
    // Instruction memory interface
    .instr_req_o         (instr_req),
    .instr_gnt_i         (instr_gnt),   
    .instr_rvalid_i      (instr_rvalid),   
    .instr_addr_o        (instr_addr),  
    .instr_rdata_i       (instr_rdata),   
    
    // Data memory interface
    .data_req_o          (data_req),   
    .data_gnt_i          (data_gnt),  
    .data_rvalid_i       (data_rvalid),   
    .data_we_o           (data_we),    
    .data_be_o           (data_be),   
    .data_addr_o         (data_addr),   
    .data_wdata_o        (data_wdata),   
    .data_rdata_i        (data_rdata),   
    
    // Interrupt inputs
    .irq_i               (irq),   
    .irq_ack_o           (irq_ack),  
    .irq_id_o           (irq_id),
    
    // Debug Interface
    .debug_req_i         (debug_req),   
    .debug_havereset_o   (debug_havereset),   
    .debug_running_o     (debug_running),   
    .debug_halted_o      (debug_halted),  
     
    // CPU Control Signals
    .fetch_enable_i       (fetch_enable),   
    .core_sleep_o        (core_sleep)
    );
    
    
    
    kyber_obi_req_t instr_obi_istegi;
    kyber_obi_rsp_t instr_obi_cevabi;
    
    kyber_axi_req_t instr_axi_istegi;
    kyber_axi_resp_t instr_axi_cevabi;
    
    
    kyber_obi_req_t data_obi_istegi;
    kyber_obi_rsp_t data_obi_cevabi;
    
    kyber_axi_req_t data_axi_istegi;
    kyber_axi_resp_t data_axi_cevabi;
    
    
    
    obi_to_axi #(
    
    .ObiCfg (obi_pkg::ObiDefaultConfig),
    .MaxRequests(32'd4),    
    
    .obi_req_t(kyber_obi_req_t),
    .obi_rsp_t(kyber_obi_rsp_t),
    
    .axi_req_t(kyber_axi_req_t),
    .axi_rsp_t(kyber_axi_resp_t)

    )
    instr_bridge(
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    .obi_req_i(instr_obi_istegi),
    .obi_rsp_o(instr_obi_cevabi),
    
    .axi_req_o(instr_axi_istegi),
    .axi_rsp_i(instr_axi_cevabi)
    
    );
    


    obi_to_axi #(
    
    .ObiCfg (obi_pkg::ObiDefaultConfig),
    .MaxRequests(32'd4),    
    
    .obi_req_t(kyber_obi_req_t),
    .obi_rsp_t(kyber_obi_rsp_t),
    
    .axi_req_t(kyber_axi_req_t),
    .axi_rsp_t(kyber_axi_resp_t)

    )
    data_bridge(
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    .obi_req_i(data_obi_istegi),
    .obi_rsp_o(data_obi_cevabi),
    
    .axi_req_o(data_axi_istegi),
    .axi_rsp_i(data_axi_cevabi)
    
    );
    
  


    //  AR PORTLARI
    assign axi_arid   =  instr_axi_istegi.ar.id;
    assign axi_araddr =  instr_axi_istegi.ar.addr;
    assign axi_arlen =   instr_axi_istegi.ar.len;
    assign axi_arsize =  instr_axi_istegi.ar.size;
    assign axi_arburst = instr_axi_istegi.ar.burst;
    assign axi_arprot  = instr_axi_istegi.ar.prot;
    assign axi_arvalid = instr_axi_istegi.ar_valid;

    assign instr_axi_cevabi.ar_ready = axi_arready;


   //  R portları
   assign axi_rready   = instr_axi_istegi.r_ready;
   
   assign instr_axi_cevabi.r.id    = axi_rid;
   assign instr_axi_cevabi.r.data  = axi_rdata; 
   assign instr_axi_cevabi.r.resp  = axi_rresp;
   assign instr_axi_cevabi.r.last  = axi_rlast;
   assign instr_axi_cevabi.r_valid = axi_rvalid;

   //  INSTRUCTION KISMINDA KULLANILMAYACAKLARI TOPRAĞA BAĞLA
   assign instr_axi_cevabi.aw_ready = 1'b0;
   assign instr_axi_cevabi.w_ready  = 1'b0;
   assign instr_axi_cevabi.b_valid  = 1'b0;
   assign instr_axi_cevabi.b.id     = 4'd0;
   assign instr_axi_cevabi.b.resp   = 2'b0;


    // obi_typedef'den kullandıklarımız
    // OBI_TYPEDEF_DEFAULT_REQ_T
    // OBI_TYPEDEF_A_CHAN_T
    
    // OBI_TYPEDEF_RSP_T
    // OBI_TYPEDEF_R_CHAN_T
    
    assign instr_obi_istegi.a.addr = instr_addr;
    assign instr_obi_istegi.req = instr_req;
    
    assign instr_obi_istegi.a.we       = 1'b0;
    assign instr_obi_istegi.a.be       = 4'b1111; 
    assign instr_obi_istegi.a.wdata    = 32'd0;     
    assign instr_obi_istegi.a.aid      = 4'd0;      
    assign instr_obi_istegi.a.a_optional = 1'b0;
    
    
    assign instr_rdata = instr_obi_cevabi.r.rdata;
    assign instr_gnt = instr_obi_cevabi.gnt;
    assign instr_rvalid = instr_obi_cevabi.rvalid;





    // AW Kanalı (Yazma Adresi)
    assign axi_data_awid    = data_axi_istegi.aw.id;
    assign axi_data_awaddr  = data_axi_istegi.aw.addr;
    assign axi_data_awlen = data_axi_istegi.aw.len;
    assign axi_data_awsize = data_axi_istegi.aw.size;
    assign axi_data_awburst = data_axi_istegi.aw.burst;
    assign axi_data_awprot  = data_axi_istegi.aw.prot;
    assign axi_data_awvalid = data_axi_istegi.aw_valid;

    assign data_axi_cevabi.aw_ready = axi_data_awready;



    // W Kanalı (Yazma Verisi)
    assign axi_data_wdata   = data_axi_istegi.w.data;
    assign axi_data_wstrb   = data_axi_istegi.w.strb;
    assign axi_data_wlast   = data_axi_istegi.w.last;
    assign axi_data_wvalid  = data_axi_istegi.w_valid;

    assign data_axi_cevabi.w_ready = axi_data_wready;
    
    
    //  B PORTLARI
    assign axi_data_bready  = data_axi_istegi.b_ready;

    assign data_axi_cevabi.b_valid = axi_data_bvalid;
    assign data_axi_cevabi.b.id =    axi_data_bid;
    assign data_axi_cevabi.b.resp =  axi_data_bresp;



    //  AR PORTLARI
    assign axi_data_arid   =  data_axi_istegi.ar.id;
    assign axi_data_araddr =  data_axi_istegi.ar.addr;
    assign axi_data_arlen =   data_axi_istegi.ar.len;
    assign axi_data_arsize =  data_axi_istegi.ar.size;
    assign axi_data_arburst = data_axi_istegi.ar.burst;
    assign axi_data_arprot  = data_axi_istegi.ar.prot;
    assign axi_data_arvalid = data_axi_istegi.ar_valid;
    
    assign data_axi_cevabi.ar_ready = axi_data_arready;


   //R portları
   assign axi_data_rready   = data_axi_istegi.r_ready;

   assign data_axi_cevabi.r.id    = axi_data_rid;
   assign data_axi_cevabi.r.data  = axi_data_rdata; 
   assign data_axi_cevabi.r.resp  = axi_data_rresp;
   assign data_axi_cevabi.r.last  = axi_data_rlast;
   assign data_axi_cevabi.r_valid = axi_data_rvalid;





    assign data_obi_istegi.a.addr = data_addr;
    assign data_obi_istegi.req = data_req;
    
    assign data_obi_istegi.a.we       = data_we;
    assign data_obi_istegi.a.be       = data_be; 
    assign data_obi_istegi.a.wdata    = data_wdata;     
    assign data_obi_istegi.a.aid      = 4'd0;      
    assign data_obi_istegi.a.a_optional = 1'b0;
    
    
    assign data_rdata = data_obi_cevabi.r.rdata;
    assign data_gnt = data_obi_cevabi.gnt;
    assign data_rvalid = data_obi_cevabi.rvalid;

endmodule
