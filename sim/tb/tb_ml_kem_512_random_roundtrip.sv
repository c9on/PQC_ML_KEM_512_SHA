module tb_ml_kem_512_random_roundtrip;
  // This bench exercises the single production interface ml_kem_512_top for
  // key generation, encapsulation, and decapsulation rather than duplicating
  // identical operation-specific wrapper benches.
  logic clk = 1'b0;
  logic rst_n = 1'b0;
  logic start = 1'b0;
  logic [1:0] cmd;
  logic [255:0] d;
  logic [255:0] z;
  logic [255:0] m;
  logic [6399:0] pk_in;
  logic [13055:0] sk_in;
  logic [6399:0] pk_out;
  logic [13055:0] sk_out;
  logic [6143:0] ct_in;
  logic [6143:0] ct_out;
  logic [255:0] ss_out;
  logic busy;
  logic valid;
  logic [7:0] status;
  logic [255:0] expected_secret;
  logic [63:0] lfsr = 64'hA5C39E71D204F86B;
  integer trial;
  integer i;

  ml_kem_512_top dut (
    .clk(clk), .rst_n(rst_n), .start(start), .cmd(cmd),
    .seed_d(d), .seed_z(z), .msg_in(m),
    .pk_in(pk_in), .sk_in(sk_in), .ct_in(ct_in),
    .pk_out(pk_out), .sk_out(sk_out), .ct_out(ct_out),
    .ss_out(ss_out), .busy(busy), .valid(valid), .status(status)
  );

  always #5 clk = ~clk;

  function automatic logic [63:0] advance_lfsr(input logic [63:0] value);
    advance_lfsr = (value >> 1) ^ (-(value & 1'b1) & 64'hD800000000000000);
  endfunction

  task automatic randomize_bus256(output logic [255:0] value);
    begin
      for (int byte_index = 0; byte_index < 32; byte_index = byte_index + 1) begin
        lfsr = advance_lfsr(lfsr);
        value[byte_index*8 +: 8] = lfsr[7:0];
      end
    end
  endtask

  task automatic run_op(input logic [1:0] command);
    begin
      cmd = command;
      @(negedge clk);
      start = 1'b1;
      @(negedge clk);
      start = 1'b0;
      wait (valid);
      @(negedge clk);
    end
  endtask

  initial begin
    cmd = 2'b00;
    m = '0;
    pk_in = '0;
    sk_in = '0;
    ct_in = '0;
    repeat (3) @(negedge clk);
    rst_n = 1'b1;

    for (trial = 0; trial < 8; trial = trial + 1) begin
      randomize_bus256(d);
      randomize_bus256(z);
      run_op(2'b00);
      pk_in = pk_out;
      sk_in = sk_out;

      randomize_bus256(m);
      run_op(2'b01);
      expected_secret = ss_out;
      ct_in = ct_out;

      run_op(2'b10);
      if (ss_out !== expected_secret)
        $fatal(1, "randomized ML-KEM round trip failed trial=%0d", trial);
    end

    $display("Randomized keygen/encaps/decaps: 8/8 round trips PASS");
    $finish;
  end
endmodule
