module tb_ml_kem_512_keygen;
  logic clk;
  logic rst_n;
  logic start;
  logic [7:0] seed [0:31];
  logic [799:0] pk;
  logic [1631:0] sk;
  logic valid;
  logic [7:0] status;

  ml_kem_512_keygen dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .seed(seed),
    .pk(pk),
    .sk(sk),
    .valid(valid),
    .status(status)
  );

  initial begin
    clk = 0;
    rst_n = 0;
    start = 0;
    for (int i = 0; i < 32; i++) seed[i] = i[7:0];
    repeat (3) @(posedge clk);
    @(negedge clk);
    rst_n = 1;
    start = 1;
    @(negedge clk);
    start = 0;
    wait (valid);
    if (!valid) $fatal(1, "keygen did not validate");
    if (pk[15:0] !== 16'ha4a5 || sk[15:0] !== 16'h5b5a)
      $fatal(1, "keygen scaffold output mismatch: pk=%h sk=%h", pk[15:0], sk[15:0]);
    $display("keygen status = %0d pk[0:15]=%h", status, pk[15:0]);
    $finish;
  end

  always #5 clk = ~clk;
endmodule
