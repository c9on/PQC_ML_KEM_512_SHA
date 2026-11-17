module tb_ml_kem_512_kdf;
  logic        clk;
  logic        rst_n;
  logic        start;
  logic [511:0] input_key;
  logic [7:0]  key_len;
  logic [31:0] shared_secret;
  logic        valid;
  logic [7:0]  status;

  ml_kem_512_kdf dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .input_key(input_key),
    .key_len(key_len),
    .shared_secret(shared_secret),
    .valid(valid),
    .status(status)
  );

  initial begin
    clk = 0;
    rst_n = 0;
    start = 0;
    input_key = 512'h0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF;
    key_len = 8'd64;
    repeat (3) @(posedge clk);
    @(negedge clk);
    rst_n = 1;
    start = 1;
    @(negedge clk);
    start = 0;
    wait (valid);
    if (!valid) $fatal(1, "ml_kem_512_kdf did not assert valid");
    if (shared_secret !== 32'h2C0E684A)
      $fatal(1, "ml_kem_512_kdf output mismatch: %h", shared_secret);
    $display("ml_kem_512_kdf: status=%0d shared_secret=%h", status, shared_secret);
    $finish;
  end

  always #5 clk = ~clk;
endmodule
