module tb_ml_kem_512_decaps;
  logic clk;
  logic rst_n;
  logic start;
  logic [767:0] ct;
  logic [1631:0] sk;
  logic [31:0] msg;
  logic [31:0] ss;
  logic valid;
  logic [7:0] status;

  ml_kem_512_decaps dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .ct(ct),
    .sk(sk),
    .msg(msg),
    .ss(ss),
    .valid(valid),
    .status(status)
  );

  initial begin
    clk = 0;
    rst_n = 0;
    start = 0;
    ct = '0;
    sk = '0;
    repeat (3) @(posedge clk);
    rst_n = 1;
    start = 1;
    @(posedge clk);
    start = 0;
    repeat (5) @(posedge clk);
    if (!valid) $fatal(1, "decaps did not validate");
    $display("decaps status = %0d msg = %h ss = %h", status, msg, ss);
    $finish;
  end

  always #5 clk = ~clk;
endmodule
