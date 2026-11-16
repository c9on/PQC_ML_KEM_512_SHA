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
    rst_n = 1;
    start = 1;
    @(posedge clk);
    start = 0;
    repeat (5) @(posedge clk);
    if (!valid) $fatal(1, "keygen did not validate");
    $display("keygen status = %0d pk[0:15]=%h", status, pk[15:0]);
    $finish;
  end

  always #5 clk = ~clk;
endmodule
