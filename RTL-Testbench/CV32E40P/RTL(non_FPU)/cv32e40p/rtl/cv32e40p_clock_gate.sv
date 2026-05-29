module cv32e40p_clock_gate (
    input  logic clk_i, en_i, scan_cg_en_i,
    output logic clk_o
);
  assign clk_o = clk_i;  // FPGA'da clock gating yerine enable logic kullan
endmodule