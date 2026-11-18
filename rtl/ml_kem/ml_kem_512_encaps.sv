module ml_kem_512_encaps (
  input  logic          clk,
  input  logic          rst_n,
  input  logic          start,
  input  logic [6399:0] pk,
  input  logic [255:0]  msg,
  output logic [6143:0] ct,
  output logic [255:0]  ss,
  output logic          busy,
  output logic          valid,
  output logic [7:0]    status
);

  logic [6399:0]  unused_ek;
  logic [13055:0] unused_dk;

  // op=01 derives ciphertext and the shared secret from EK and a 32-byte
  // message. For ACVP, msg is the deterministic test input.
  ml_kem_512_engine u_engine (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .op(2'b01),
    .d('0),
    .z('0),
    .m(msg),
    .ek(pk),
    .dk('0),
    .ct_in('0),
    .ek_out(unused_ek),
    .dk_out(unused_dk),
    .ct_out(ct),
    .ss_out(ss),
    .busy(busy),
    .valid(valid),
    .status(status)
  );
endmodule
