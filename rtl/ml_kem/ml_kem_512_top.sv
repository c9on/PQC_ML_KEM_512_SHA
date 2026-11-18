module ml_kem_512_top (
  input  logic           clk,
  input  logic           rst_n,
  input  logic           start,
  input  logic [1:0]     cmd,
  input  logic [255:0]   seed_d,
  input  logic [255:0]   seed_z,
  input  logic [6399:0]  pk_in,
  input  logic [13055:0] sk_in,
  input  logic [6143:0]  ct_in,
  input  logic [255:0]   msg_in,
  output logic [6399:0]  pk_out,
  output logic [13055:0] sk_out,
  output logic [6143:0]  ct_out,
  output logic [255:0]   ss_out,
  output logic           busy,
  output logic           valid,
  output logic [7:0]     status
);

  // Command 00: key generation
  // Command 01: encapsulation
  // Command 10: decapsulation
  // Command 11: rejected
  // This is the production ML-KEM-512 entry point. It routes commands to the
  // validated engine rather than to the legacy placeholder arithmetic.
  // Keys and ciphertext use complete FIPS 203 byte sizes: 800, 1632, and 768.
  ml_kem_512_engine u_engine (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .op(cmd),
    .d(seed_d),
    .z(seed_z),
    .m(msg_in),
    .ek(pk_in),
    .dk(sk_in),
    .ct_in(ct_in),
    .ek_out(pk_out),
    .dk_out(sk_out),
    .ct_out(ct_out),
    .ss_out(ss_out),
    .busy(busy),
    .valid(valid),
    .status(status)
  );
endmodule
