module ml_kem_512_decaps (
  input  logic           clk,
  input  logic           rst_n,
  input  logic           start,
  input  logic [6143:0]  ct,
  input  logic [13055:0] sk,
  output logic [255:0]   ss,
  output logic           busy,
  output logic           valid,
  output logic [7:0]     status
);

  logic [6399:0]  unused_ek;
  logic [13055:0] unused_dk;
  logic [6143:0]  unused_ct;

  // op=10 decrypts, re-encrypts, and compares the complete ciphertext.
  // The engine returns Kbar on a match or J(z || c) on implicit rejection.
  ml_kem_512_engine u_engine (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .op(2'b10),
    .d('0),
    .z('0),
    .m('0),
    .ek('0),
    .dk(sk),
    .ct_in(ct),
    .ek_out(unused_ek),
    .dk_out(unused_dk),
    .ct_out(unused_ct),
    .ss_out(ss),
    .busy(busy),
    .valid(valid),
    .status(status)
  );
endmodule
