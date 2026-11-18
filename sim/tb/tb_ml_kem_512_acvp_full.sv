module tb_ml_kem_512_acvp_full
  import ml_kem_fips203_pkg::*;
  ();

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
  logic busy;
  logic valid;
  logic [7:0] status;

  // Each memory entry is one complete ACVP vector. A 6400-bit entry therefore
  // represents one 800-byte encapsulation key, not 800 separate test cases.
  logic [255:0] kg_d [0:24];
  logic [255:0] kg_z [0:24];
  logic [6399:0] kg_ek [0:24];
  logic [13055:0] kg_dk [0:24];
  logic [6399:0] enc_ek [0:24];
  logic [255:0] enc_m [0:24];
  logic [6143:0] enc_c [0:24];
  logic [255:0] enc_k [0:24];
  logic [13055:0] dec_dk [0:9];
  logic [6143:0] dec_c [0:9];
  logic [255:0] dec_k [0:9];
  logic [13055:0] dkcheck_dk [0:9];
  logic [7:0] dkcheck_passed [0:9];
  logic [6399:0] ekcheck_ek [0:9];
  logic [7:0] ekcheck_passed [0:9];

  ml_kem_512_engine dut (.*);

  always #5 clk = ~clk;

  // Start one command and wait for the engine's single-cycle valid response.
  // All inputs must remain stable after start because the engine latches them.
  task automatic run_op(input logic [1:0] cmd);
    begin
      op = cmd;
      @(negedge clk);
      start = 1'b1;
      @(negedge clk);
      start = 1'b0;
      wait (valid);
      @(negedge clk);
    end
  endtask

  initial begin
    // Load official NIST prompt/expected-result pairs generated under sim/vectors.
    // readmemh reads each complete hexadecimal row into its corresponding vector.
    $readmemh("sim/vectors/full/kg_d.mem", kg_d);
    $readmemh("sim/vectors/full/kg_z.mem", kg_z);
    $readmemh("sim/vectors/full/kg_ek.mem", kg_ek);
    $readmemh("sim/vectors/full/kg_dk.mem", kg_dk);
    $readmemh("sim/vectors/full/enc_ek.mem", enc_ek);
    $readmemh("sim/vectors/full/enc_m.mem", enc_m);
    $readmemh("sim/vectors/full/enc_c.mem", enc_c);
    $readmemh("sim/vectors/full/enc_k.mem", enc_k);
    $readmemh("sim/vectors/full/dec_dk.mem", dec_dk);
    $readmemh("sim/vectors/full/dec_c.mem", dec_c);
    $readmemh("sim/vectors/full/dec_k.mem", dec_k);
    $readmemh("sim/vectors/full/dkcheck_dk.mem", dkcheck_dk);
    $readmemh("sim/vectors/full/dkcheck_passed.mem", dkcheck_passed);
    $readmemh("sim/vectors/full/ekcheck_ek.mem", ekcheck_ek);
    $readmemh("sim/vectors/full/ekcheck_passed.mem", ekcheck_passed);

    op = 2'b00;
    m = '0;
    ek = '0;
    dk = '0;
    ct_in = '0;
    repeat (3) @(negedge clk);
    rst_n = 1'b1;

    // Phase 1: deterministic key generation compares complete EK and DK values.
    for (int i = 0; i < 25; i = i + 1) begin
      d = kg_d[i];
      z = kg_z[i];
      run_op(2'b00);
      if ((ek_out !== kg_ek[i]) || (dk_out !== kg_dk[i]))
        $fatal(1, "keygen vector %0d failed", i + 1);
    end
    $display("ML-KEM-512 keygen: 25/25 ACVP PASS");

    // Phase 2: encapsulation compares the complete ciphertext and shared key.
    for (int i = 0; i < 25; i = i + 1) begin
      ek = enc_ek[i];
      m = enc_m[i];
      run_op(2'b01);
      if ((ct_out !== enc_c[i]) || (ss_out !== enc_k[i]))
        $fatal(1, "encapsulation vector %0d failed", i + 1);
    end
    $display("ML-KEM-512 encapsulation: 25/25 ACVP PASS");

    // Phase 3: decapsulation includes both valid and rejection-path vectors.
    for (int i = 0; i < 10; i = i + 1) begin
      dk = dec_dk[i];
      ct_in = dec_c[i];
      run_op(2'b10);
      if (ss_out !== dec_k[i])
        $fatal(1, "decapsulation vector tcId %0d failed", 76 + i);
    end
    $display("ML-KEM-512 decapsulation: 10/10 ACVP PASS");

    // Key-check cases validate structural key rules without running a KEM op.
    for (int i = 0; i < 10; i = i + 1) begin
      if (dk_valid(dkcheck_dk[i]) !== dkcheck_passed[i][0])
        $fatal(1, "decapsulation key-check vector tcId %0d failed", 106 + i);
      if (ek_valid(ekcheck_ek[i]) !== ekcheck_passed[i][0])
        $fatal(1, "encapsulation key-check vector tcId %0d failed", 116 + i);
    end
    $display("ML-KEM-512 key checks: 20/20 ACVP PASS");

    $finish;
  end
endmodule
