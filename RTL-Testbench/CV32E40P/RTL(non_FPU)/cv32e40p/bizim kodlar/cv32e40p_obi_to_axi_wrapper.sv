
import obi_pkg::*;
import axi_port_pkg::*;
import obi_port_pkg::*;

module cv32e40p_obi_to_axi_wrapper#(

    parameter logic [31:0] boot_addr         = 32'h0000_0000,   //BASLANGIC ADRESI
    parameter logic [31:0] mtvec_addr        = 32'h1F00_0000,   //INTERRUPT GELDIGINDE ISLEMCININ ATLAYACAGI ADRES
    parameter logic [31:0] dm_halt_addr      = 32'h2F0_0000,    //JTAG KULLANILMAK ISTENDIGINDE ISLEMCISNIN ATLAYACAGI ADRES
    parameter logic [31:0] hart_id           = 32'h0000_0000,   //CEKIRDEGIN NUMARASI(TEK CEKIRDEK OLDUGU ICIN DIREKT 0 YAZDIK)
    parameter logic [31:0] dm_exception_addr = 32'h3F00_0000    //JTAG KULLANILIRKEN HATA OLUSULURSA ISLEMCININ ATLAYACAGI ADRES
)

(
    //  GLOBAL CLOCK VE RESET
    input logic clk_i,
    input logic rst_ni,

    // INTERRUPT PORTLARI
    input  logic [31:0] interrupt_i,
    output logic        interrupt_ack,
    output logic [ 4:0] interrupt_id,

    //  INSTRUCTION AR PORTLARI
    output logic [31:0] axi_instr_araddr,
    output logic [ 2:0] axi_instr_arprot = 3'b000,
    output logic        axi_instr_arvalid,
    input  logic        axi_instr_arready,

    //  INSTRUCTION R PORTLARI
    output logic        axi_instr_rready,
    input  logic [31:0] axi_instr_rdata,
    input  logic [ 1:0] axi_instr_rresp,
    input  logic        axi_instr_rvalid,

    //  INSTRUCTION AW PORTLARI
    output logic [31:0] axi_instr_awaddr,
    output logic [ 2:0] axi_instr_awprot = 3'b000,
    output logic        axi_instr_awvalid,
    input  logic        axi_instr_awready,

    //  INSTRUCTION W PORTLARI
    output logic [31:0] axi_instr_wdata,
    output logic [ 3:0] axi_instr_wstrb = 4'b1111,
    output logic        axi_instr_wvalid,
    input  logic        axi_instr_wready,

    //  INSTRUCTION B PORTLARI
    output logic        axi_instr_bready,
    input  logic [ 1:0] axi_instr_bresp,
    input  logic        axi_instr_bvalid,


    //  DATA AR PORTLARI
    output logic [31:0] axi_data_araddr,
    output logic [ 2:0] axi_data_arprot = 3'b000,
    output logic        axi_data_arvalid,
    input  logic        axi_data_arready,

    //  DATA R PORTLARI
    output logic        axi_data_rready,
    input  logic [31:0] axi_data_rdata,
    input  logic [ 1:0] axi_data_rresp,
    input  logic        axi_data_rvalid,

    //  DATA AW PORTLARI
    output logic [31:0] axi_data_awaddr,
    output logic [ 2:0] axi_data_awprot = 3'b000,
    output logic        axi_data_awvalid,
    input  logic        axi_data_awready,

    //  DATA W PORTLARI
    output logic [31:0] axi_data_wdata,
    output logic [ 3:0] axi_data_wstrb = 4'b1111,
    output logic        axi_data_wvalid,
    input  logic        axi_data_wready,

    //  DATA B PORTLARI
    output logic        axi_data_bready,
    input  logic [ 1:0] axi_data_bresp,
    input  logic        axi_data_bvalid

    );



    // INSTRUCTION MEMORY PORTLARI
    logic       instr_req;
    logic       instr_gnt;
    logic       instr_rvalid;
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


    // DEBUG PORTLARI
    logic debug_req = 0;
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
    .irq_i               (interrupt_i),
    .irq_ack_o           (interrupt_ack),
    .irq_id_o            (interrupt_id),

    // Debug Interface
    .debug_req_i         (debug_req),
    .debug_havereset_o   (debug_havereset),
    .debug_running_o     (debug_running),
    .debug_halted_o      (debug_halted),

    // CPU Control Signals
    .fetch_enable_i      (fetch_enable),
    .core_sleep_o        (core_sleep)
    );


    ////////////////////////////////////////////////////////////////////////////////////////////
    // AXI'nin istek kısmı(Master => Slave) ve cevap kısmı(Slave => Master) ile ilgili bütün
    // portları boyutlarına göre tanımlayan struct içi struct yapısına erişmek için aşağıdaki
    // isimlendirmeyi yaptık. Portları kolayca tanımlayıp aşağıdaki "obi_to_axi" kodunu
    // çağırırken içine koymak için bu hazır makroları kullanıyoruz.
    ////////////////////////////////////////////////////////////////////////////////////////////
    kyber_obi_req_t instr_obi_istegi;
    kyber_obi_rsp_t instr_obi_cevabi;

    kyber_axi_req_t  instr_axi_istegi;
    kyber_axi_resp_t instr_axi_cevabi;


    kyber_obi_req_t data_obi_istegi;
    kyber_obi_rsp_t data_obi_cevabi;

    kyber_axi_req_t  data_axi_istegi;
    kyber_axi_resp_t data_axi_cevabi;


    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Burada obi protokolünü axi'ye çevirecek ana kodu, "obi_to_axi"yi koda bağlıyoruz.
    // 2 Çıkış portu kullanacağımız için aynı işlemi 2 defa yaptık.
    //
    //   PARAMETRE KISMININ SIRAYLA AÇIKLAMALARI:
    // - OBI protokolünün standart ayarlarını (adres genişliği, veri genişliği vb.) bu
    //   paket üzerinden modüle aktarırız.
    //
    // - Tek seferde gelebilecek AXI istek sayısını belirler, ona göre FIFO ayarlar.
    //
    // - .obi_req_t(kyber_obi_req_t) Bu 4 satırda obi_to_axi modülünün type parametresine
    //   .obi_rsp_t(kyber_obi_rsp_t) yukarıda oluşturduğumuz struct'ın şablonunu veririz.
    //   .axi_req_t(kyber_axi_req_t) Bu sayede modüle hangi portları kullandığımızın ve
    //   .axi_rsp_t(kyber_axi_resp_t)genişliklerinin bilgisini vermiş oluruz. Kod ona göre ayarlanır.
    //
    //   "input  obi_req_t obi_req_i" instr_bridge ismiyle kodumuzda oluşturduğumuz struct'ları instr_bridge
    //   "output obi_rsp_t obi_rsp_o" ismiyle soldaki obi_to_axi kodundaki port tanımını kendi kodumuza bağlamış oluyoruz.
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
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



    /////////////////////////////////////////////////////////////////////////////////////
    // Yukarıda kodumuza getirdiğimiz obi_to_axi portlarını burada obi/axi ve giriş/çıkış
    // yönlerine göre bu koddaki portlara bağlarız.
    /////////////////////////////////////////////////////////////////////////////////////


    ///////////////////////////////////////
    // INSTRUCTION OBI PORT BAĞLANTILARI //
    ///////////////////////////////////////

    assign instr_obi_istegi.a.addr       = instr_addr;
    assign instr_obi_istegi.req          = instr_req;
    assign instr_obi_istegi.a.we         = 1'b0;
    assign instr_obi_istegi.a.be         = 4'b1111;
    assign instr_obi_istegi.a.wdata      = 32'd0;
    assign instr_obi_istegi.a.aid        = 4'd0;
    assign instr_obi_istegi.a.a_optional = 1'b0;

    assign instr_rdata  = instr_obi_cevabi.r.rdata;
    assign instr_gnt    = instr_obi_cevabi.gnt;
    assign instr_rvalid = instr_obi_cevabi.rvalid;



    ///////////////////////////////////////
    // INSTRUCTION AXI PORT BAĞLANTILARI //
    ///////////////////////////////////////

    //  AR PORTLARI
    assign axi_instr_araddr  = instr_axi_istegi.ar.addr;
    assign axi_instr_arvalid = instr_axi_istegi.ar_valid;

    assign instr_axi_cevabi.ar_ready = axi_instr_arready;


    //  R PORTLARI
    assign axi_instr_rready = instr_axi_istegi.r_ready;

    assign instr_axi_cevabi.r.data  = axi_instr_rdata;
    assign instr_axi_cevabi.r.resp  = axi_instr_rresp;
    assign instr_axi_cevabi.r_valid = axi_instr_rvalid;


    //  INSTRUCTION KISMINDA KULLANILMAYACAK PORTLAR'IN 0'A ÇEKİLMESİ
    assign instr_axi_cevabi.aw_ready = 1'b0;
    assign instr_axi_cevabi.w_ready  = 1'b0;
    assign instr_axi_cevabi.b_valid  = 1'b0;
    assign instr_axi_cevabi.b.resp   = 2'b0;




    ////////////////////////////////
    // DATA OBI PORT BAĞLANTILARI //
    ////////////////////////////////

    assign data_obi_istegi.a.addr = data_addr;
    assign data_obi_istegi.req    = data_req;

    assign data_obi_istegi.a.we         = data_we;
    assign data_obi_istegi.a.be         = data_be;
    assign data_obi_istegi.a.wdata      = data_wdata;
    assign data_obi_istegi.a.aid        = 4'd0;
    assign data_obi_istegi.a.a_optional = 1'b0;


    assign data_rdata  = data_obi_cevabi.r.rdata;
    assign data_gnt    = data_obi_cevabi.gnt;
    assign data_rvalid = data_obi_cevabi.rvalid;



    ////////////////////////////////
    // DATA AXI PORT BAĞLANTILARI //
    ////////////////////////////////

    // AW Kanalı (Yazma Adresi)
    assign axi_data_awaddr  = data_axi_istegi.aw.addr;
    assign axi_data_awvalid = data_axi_istegi.aw_valid;

    assign data_axi_cevabi.aw_ready = axi_data_awready;


    // W Kanalı (Yazma Verisi)
    assign axi_data_wdata   = data_axi_istegi.w.data;
    assign axi_data_wvalid  = data_axi_istegi.w_valid;

    assign data_axi_cevabi.w_ready = axi_data_wready;


    //  B PORTLARI
    assign axi_data_bready = data_axi_istegi.b_ready;

    assign data_axi_cevabi.b_valid = axi_data_bvalid;
    assign data_axi_cevabi.b.resp  = axi_data_bresp;


    //  AR PORTLARI
    assign axi_data_araddr  = data_axi_istegi.ar.addr;
    assign axi_data_arvalid = data_axi_istegi.ar_valid;

    assign data_axi_cevabi.ar_ready = axi_data_arready;


    //R portları
    assign axi_data_rready   = data_axi_istegi.r_ready;

    assign data_axi_cevabi.r.data  = axi_data_rdata;
    assign data_axi_cevabi.r.resp  = axi_data_rresp;
    assign data_axi_cevabi.r_valid = axi_data_rvalid;

endmodule
