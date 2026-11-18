module tb_ml_kem_512_decaps;
  logic clk = 1'b0;
  logic rst_n = 1'b0;
  logic start = 1'b0;
  logic [6143:0] ct;
  logic [13055:0] sk;
  logic [255:0] ss;
  logic [255:0] expected_ss;
  logic busy;
  logic valid;
  logic [7:0] status;
  logic [7:0] cm [0:767];
  logic [7:0] dkm [0:1631];
  logic [7:0] km [0:31];

  ml_kem_512_decaps dut (.*);

  always #5 clk = ~clk;

  initial begin
    $readmemh("sim/vectors/acvp_decap_tc76_ct.hex", cm);
    $readmemh("sim/vectors/acvp_decap_tc76_dk.hex", dkm);
    $readmemh("sim/vectors/acvp_decap_tc76_exp_k.hex", km);

    for (int i = 0; i < 768; i = i + 1)
      ct[(767 - i)*8 +: 8] = cm[i];
    for (int i = 0; i < 1632; i = i + 1)
      sk[(1631 - i)*8 +: 8] = dkm[i];
    for (int i = 0; i < 32; i = i + 1)
      expected_ss[(31 - i)*8 +: 8] = km[i];

    repeat (3) @(negedge clk);
    rst_n = 1'b1;
    @(negedge clk);
    start = 1'b1;
    @(negedge clk);
    start = 1'b0;
    wait (valid);

    if (busy || (ss !== expected_ss))
      $fatal(1, "decaps ACVP mismatch");

    $display("decaps ACVP PASS");
    $finish;
  end
endmodule
