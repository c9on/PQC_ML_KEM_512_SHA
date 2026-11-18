module tb_ml_kem_512_encaps;
  logic clk = 1'b0;
  logic rst_n = 1'b0;
  logic start = 1'b0;
  logic [6399:0] pk;
  logic [255:0] msg;
  logic [255:0] ss;
  logic [255:0] expected_ss;
  logic [6143:0] ct;
  logic [6143:0] expected_ct;
  logic busy;
  logic valid;
  logic [7:0] status;
  logic [7:0] ekm [0:799];
  logic [7:0] mm [0:31];
  logic [7:0] cm [0:767];
  logic [7:0] km [0:31];

  ml_kem_512_encaps dut (.*);

  always #5 clk = ~clk;

  initial begin
    $readmemh("sim/vectors/acvp_encap_tc1_ek.hex", ekm);
    $readmemh("sim/vectors/acvp_encap_tc1_m.hex", mm);
    $readmemh("sim/vectors/acvp_encap_tc1_exp_ct.hex", cm);
    $readmemh("sim/vectors/acvp_encap_tc1_exp_k.hex", km);

    for (int i = 0; i < 800; i = i + 1)
      pk[(799 - i)*8 +: 8] = ekm[i];
    for (int i = 0; i < 768; i = i + 1)
      expected_ct[(767 - i)*8 +: 8] = cm[i];
    for (int i = 0; i < 32; i = i + 1) begin
      msg[(31 - i)*8 +: 8] = mm[i];
      expected_ss[(31 - i)*8 +: 8] = km[i];
    end

    repeat (3) @(negedge clk);
    rst_n = 1'b1;
    @(negedge clk);
    start = 1'b1;
    @(negedge clk);
    start = 1'b0;
    wait (valid);

    if (busy || (ct !== expected_ct) || (ss !== expected_ss))
      $fatal(1, "encaps ACVP mismatch");

    $display("encaps ACVP PASS");
    $finish;
  end
endmodule
