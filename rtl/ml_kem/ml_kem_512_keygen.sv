module ml_kem_512_keygen (
  input  logic           clk,
  input  logic           rst_n,
  input  logic           start,
  input  logic [255:0]   d,
  input  logic [255:0]   z,
  output logic [6399:0]  pk,
  output logic [13055:0] sk,
  output logic           busy,
  output logic           valid,
  output logic [7:0]     status
);

  logic [6143:0] unused_ct;
  logic [255:0]  unused_ss;

  // This wrapper fixes op=00 (ML-KEM.KeyGen) and exposes only its EK/DK.
  // Unused outputs remain connected so the shared engine is used consistently.
  ml_kem_512_engine u_engine (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .op(2'b00),
    .d(d),
    .z(z),
    .m('0),
    .ek('0),
    .dk('0),
    .ct_in('0),
    .ek_out(pk),
    .dk_out(sk),
    .ct_out(unused_ct),
    .ss_out(unused_ss),
    .busy(busy),
    .valid(valid),
    .status(status)
  );
endmodule
