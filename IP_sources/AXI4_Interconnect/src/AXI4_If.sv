interface axi4lite_if();
  //  AW PORTLARI
  logic [31:0] axi_awaddr;
  logic        axi_awvalid;
  logic        axi_awready;

  // W PORTLARI
  logic [31:0] axi_wdata;
  logic        axi_wvalid;
  logic        axi_wready;

  // B PORTLARI
  logic [ 1:0] axi_bresp;
  logic        axi_bvalid;
  logic        axi_bready;

  // AR PORTLARI
  logic [31:0] axi_araddr;
  logic        axi_arvalid;
  logic        axi_arready;

  // R PORTLARI
  logic        axi_rready;
  logic [31:0] axi_rdata;
  logic [ 1:0] axi_rresp;
  logic        axi_rvalid;

  modport master(
    input  axi_awready, axi_wready, axi_bresp, axi_bvalid, axi_arready, axi_rdata, axi_rresp, axi_rvalid,
    output axi_awaddr, axi_awvalid, axi_wdata, axi_wvalid, axi_bready, axi_araddr, axi_arvalid, axi_rready
  );
  modport slave(
    input  axi_awaddr, axi_awvalid, axi_wdata, axi_wvalid, axi_bready, axi_araddr, axi_arvalid, axi_rready,
    output axi_awready, axi_wready, axi_bresp, axi_bvalid, axi_arready, axi_rdata, axi_rresp, axi_rvalid
  );
endinterface


interface axi4_if();

  // AW PORTLARI
  logic [ 3:0] axi_awid;
  logic [31:0] axi_awaddr;
  logic [ 3:0] axi_awlen;
  logic [ 2:0] axi_awsize;
  logic [ 1:0] axi_awburst;
  logic [ 2:0] axi_awprot;
  logic        axi_awvalid;
  logic        axi_awready;

  // W PORTLARI
  logic [31:0] axi_wdata;
  logic [ 3:0] axi_wstrb;
  logic        axi_wlast;
  logic        axi_wvalid;
  logic        axi_wready;
  
  // B PORTLARI
  logic        axi_bready;
  logic [ 3:0] axi_bid;
  logic [ 1:0] axi_bresp;
  logic        axi_bvalid;
  
  // AR PORTLARI
  logic [ 3:0] axi_arid;
  logic [31:0] axi_araddr;
  logic [ 3:0] axi_arlen;
  logic [ 2:0] axi_arsize;
  logic [ 1:0] axi_arburst;
  logic [ 2:0] axi_arprot;
  logic        axi_arvalid; 
  logic        axi_arready;
  
  // R PORTLARI
  logic        axi_rready;
  logic [ 3:0] axi_rid;
  logic [31:0] axi_rdata;
  logic [ 1:0] axi_rresp;
  logic        axi_rlast;
  logic        axi_rvalid;

  modport master(
    output axi_rready,axi_arvalid,axi_arprot,axi_arburst,axi_arsize,axi_arlen,axi_araddr,axi_arid,axi_bready,axi_wvalid,axi_wlast,axi_wstrb,axi_wdata,axi_awvalid,axi_awprot,axi_awburst,axi_awsize,axi_awaddr,axi_awlen,axi_awid,
    input  axi_rvalid,axi_rlast,axi_rresp,axi_rdata,axi_rid,axi_arready,axi_bvalid,axi_bresp,axi_bid,axi_wready,axi_awready

  );
  modport slave(
    input  axi_rready,axi_arvalid,axi_arprot,axi_arburst,axi_arsize,axi_arlen,axi_araddr,axi_arid,axi_bready,axi_wvalid,axi_wlast,axi_wstrb,axi_wdata,axi_awvalid,axi_awprot,axi_awburst,axi_awsize,axi_awaddr,axi_awlen,axi_awid,
    output axi_rvalid,axi_rlast,axi_rresp,axi_rdata,axi_rid,axi_arready,axi_bvalid,axi_bresp,axi_bid,axi_wready,axi_awready
  );
endinterface 
