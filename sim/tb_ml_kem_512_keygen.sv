module tb_ml_kem_512_keygen;
  logic clk = 1'b0;
  logic rst_n = 1'b0;
  logic start = 1'b0;
  logic [255:0] d;
  logic [255:0] z;
  logic [6399:0] pk;
  logic [13055:0] sk;
  logic [6399:0] expected_pk;
  logic [13055:0] expected_sk;
  logic busy;
  logic valid;
  logic [7:0] status;
  logic [7:0] ekmem [0:799];
  logic [7:0] dkmem [0:1631];

  ml_kem_512_keygen dut (.*);

  always #5 clk = ~clk;

  initial begin
    d = 256'h47B893474672BA92E4B12EE44FB32953AF8E8503B5FB471D1614FB8A021A660A;
    z = 256'h1F8CB39E9E30BC458A0DC5408884B1187FB217018DF760FA57317703B844A0A9;

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

    if (busy || (pk !== expected_pk) || (sk !== expected_sk))
      $fatal(1, "keygen ACVP mismatch");

    $display("keygen ACVP PASS");
    $finish;
  end
endmodule
