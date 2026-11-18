module tb_ml_kem_512_top;
  logic clk = 1'b0;
  logic rst_n = 1'b0;
  logic start = 1'b0;
  logic [1:0] cmd;
  logic [255:0] seed_d;
  logic [255:0] seed_z;
  logic [255:0] msg_in;
  logic [6399:0] pk_in;
  logic [13055:0] sk_in;
  logic [6143:0] ct_in;
  logic [6399:0] pk_out;
  logic [13055:0] sk_out;
  logic [6143:0] ct_out;
  logic [255:0] ss_out;
  logic [6399:0] expected_pk;
  logic [13055:0] expected_sk;
  logic busy;
  logic valid;
  logic [7:0] status;
  logic [7:0] ekmem [0:799];
  logic [7:0] dkmem [0:1631];

  ml_kem_512_top dut (.*);

  always #5 clk = ~clk;

  initial begin
    cmd = 2'b00;
    seed_d = 256'h47B893474672BA92E4B12EE44FB32953AF8E8503B5FB471D1614FB8A021A660A;
    seed_z = 256'h1F8CB39E9E30BC458A0DC5408884B1187FB217018DF760FA57317703B844A0A9;
    msg_in = '0;
    pk_in = '0;
    sk_in = '0;
    ct_in = '0;

    $readmemh("sim/vectors/acvp_keygen_tc1_exp_ek.hex", ekmem);
    $readmemh("sim/vectors/acvp_keygen_tc1_exp_dk.hex", dkmem);
    for (int i = 0; i < 800; i = i + 1)
      expected_pk[(799 - i)*8 +: 8] = ekmem[i];
    for (int i = 0; i < 1632; i = i + 1)
      expected_sk[(1631 - i)*8 +: 8] = dkmem[i];

    repeat (3) @(negedge clk);
    rst_n = 1'b1;
    @(negedge clk);
    start = 1'b1;
    @(negedge clk);
    start = 1'b0;
    wait (valid);

    if (busy || (pk_out !== expected_pk) || (sk_out !== expected_sk))
      $fatal(1, "top-level ACVP keygen mismatch");

    $display("ml_kem_512_top: ACVP keygen PASS");
    $finish;
  end
endmodule
