module tb_ml_kem_512_acvp;
  logic clk = 1'b0;
  logic rst_n = 1'b0;
  logic start = 1'b0;
  logic [1:0] op;
  logic [255:0] d;
  logic [255:0] z;
  logic [255:0] m;
  logic [6399:0] ek;
  logic [13055:0] dk;
  logic [6143:0] ct_in;
  logic [6399:0] ek_out;
  logic [13055:0] dk_out;
  logic [6143:0] ct_out;
  logic [255:0] ss_out;
  logic [6399:0] expect_ek;
  logic [13055:0] expect_dk;
  logic [6143:0] expect_ct;
  logic [255:0] expect_ss;
  logic busy;
  logic valid;
  logic [7:0] status;
  logic [7:0] ekmem [0:799];
  logic [7:0] dkmem [0:1631];
  logic [7:0] ctmem [0:767];
  logic [7:0] mkmem [0:31];
  logic [7:0] expek [0:799];
  logic [7:0] expdk [0:1631];
  logic [7:0] expct [0:767];
  logic [7:0] expk [0:31];

  ml_kem_512_engine dut (.*);

  always #5 clk = ~clk;

  task tick(input logic [1:0] cmd);
    begin
      op = cmd;
      @(negedge clk);
      start = 1'b1;
      @(negedge clk);
      start = 1'b0;
      if (!busy)
        $fatal(1, "engine did not assert busy");
      wait (valid);
      if (busy)
        $fatal(1, "engine remained busy at completion");
      @(negedge clk);
    end
  endtask

  initial begin
    op = 2'b00;
    m = '0;
    ek = '0;
    dk = '0;
    ct_in = '0;
    d = 256'h47B893474672BA92E4B12EE44FB32953AF8E8503B5FB471D1614FB8A021A660A;
    z = 256'h1F8CB39E9E30BC458A0DC5408884B1187FB217018DF760FA57317703B844A0A9;

    $readmemh("sim/vectors/acvp_keygen_tc1_exp_ek.hex", expek);
    $readmemh("sim/vectors/acvp_keygen_tc1_exp_dk.hex", expdk);
    for (int i = 0; i < 800; i = i + 1)
      expect_ek[(799 - i)*8 +: 8] = expek[i];
    for (int i = 0; i < 1632; i = i + 1)
      expect_dk[(1631 - i)*8 +: 8] = expdk[i];

    $readmemh("sim/vectors/acvp_encap_tc1_ek.hex", ekmem);
    $readmemh("sim/vectors/acvp_encap_tc1_m.hex", mkmem);
    $readmemh("sim/vectors/acvp_encap_tc1_exp_ct.hex", expct);
    $readmemh("sim/vectors/acvp_encap_tc1_exp_k.hex", expk);
    for (int i = 0; i < 800; i = i + 1)
      ek[(799 - i)*8 +: 8] = ekmem[i];
    for (int i = 0; i < 32; i = i + 1) begin
      m[(31 - i)*8 +: 8] = mkmem[i];
      expect_ss[(31 - i)*8 +: 8] = expk[i];
    end
    for (int i = 0; i < 768; i = i + 1)
      expect_ct[(767 - i)*8 +: 8] = expct[i];

    repeat (3) @(negedge clk);
    rst_n = 1'b1;
    tick(2'b00);
    if ((ek_out !== expect_ek) || (dk_out !== expect_dk))
      $fatal(1, "keygen ACVP mismatch");
    $display("ML-KEM-512 keygen ACVP PASS");

    tick(2'b01);
    if ((ct_out !== expect_ct) || (ss_out !== expect_ss))
      $fatal(1, "encapsulation ACVP mismatch");
    $display("ML-KEM-512 encaps ACVP PASS");

    $readmemh("sim/vectors/acvp_decap_tc76_dk.hex", dkmem);
    $readmemh("sim/vectors/acvp_decap_tc76_ct.hex", ctmem);
    $readmemh("sim/vectors/acvp_decap_tc76_exp_k.hex", expk);
    for (int i = 0; i < 1632; i = i + 1)
      dk[(1631 - i)*8 +: 8] = dkmem[i];
    for (int i = 0; i < 768; i = i + 1)
      ct_in[(767 - i)*8 +: 8] = ctmem[i];
    for (int i = 0; i < 32; i = i + 1)
      expect_ss[(31 - i)*8 +: 8] = expk[i];

    tick(2'b10);
    if (ss_out !== expect_ss)
      $fatal(1, "decapsulation ACVP mismatch got=%h expected=%h", ss_out, expect_ss);
    $display("ML-KEM-512 decaps ACVP PASS");
    $finish;
  end
endmodule
