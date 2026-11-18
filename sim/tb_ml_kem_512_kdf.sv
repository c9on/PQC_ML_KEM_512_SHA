module tb_ml_kem_512_kdf;
  logic clk = 1'b0;
  logic rst_n = 1'b0;
  logic start = 1'b0;
  logic [255:0] z;
  logic [255:0] expected;
  logic [6143:0] ct;
  logic [255:0] shared_secret;
  logic busy;
  logic valid;
  logic [7:0] status;
  logic [7:0] cm [0:767];
  logic [7:0] dkm [0:1631];
  logic [7:0] km [0:31];

  ml_kem_512_kdf dut (.*);

  always #5 clk = ~clk;

  initial begin
    $readmemh("sim/vectors/acvp_decap_tc76_ct.hex", cm);
    $readmemh("sim/vectors/acvp_decap_tc76_dk.hex", dkm);
    $readmemh("sim/vectors/acvp_decap_tc76_exp_k.hex", km);

    for (int i = 0; i < 768; i = i + 1)
      ct[(767 - i)*8 +: 8] = cm[i];
    for (int i = 0; i < 32; i = i + 1) begin
      z[(31 - i)*8 +: 8] = dkm[1600 + i];
      expected[(31 - i)*8 +: 8] = km[i];
    end

    repeat (3) @(negedge clk);
    rst_n = 1'b1;
    @(negedge clk);
    start = 1'b1;
    @(negedge clk);
    start = 1'b0;
    wait (valid);

    if (busy || (shared_secret !== expected))
      $fatal(1, "J(z||c) KDF mismatch");

    $display("KDF rejection ACVP PASS");
    $finish;
  end
endmodule
