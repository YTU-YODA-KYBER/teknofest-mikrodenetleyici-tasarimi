`include "axi_typedef.svh"

package axi_port_pkg;

localparam int unsigned AXI_ADDR_WIDTH = 32;
localparam int unsigned AXI_DATA_WIDTH = 32;
localparam int unsigned AXI_STRB_WIDTH = 4;

`AXI_LITE_TYPEDEF_ALL(
        kyber_axi,                       // Üretilecek tüm paketlerin ön adı
        logic [AXI_ADDR_WIDTH-1:0],      // Adres kablosu tipi
        logic [AXI_DATA_WIDTH-1:0],      // Veri kablosu tipi
        logic [AXI_STRB_WIDTH-1:0]      // Strobe kablosu tipi
    )

endpackage

