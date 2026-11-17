module tb_ml_kem_512_encaps;
  logic clk;
  logic rst_n;
  logic start;
  logic [799:0] pk;
  logic [31:0] msg;
  logic [767:0] ct;
  logic [31:0] ss;
  logic valid;
  logic [7:0] status;

  ml_kem_512_encaps dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .pk(pk),
    .msg(msg),
    .ct(ct),
    .ss(ss),
    .valid(valid),
    .status(status)
  );

  initial begin
    clk = 0;
    rst_n = 0;
    start = 0;
    msg = 32'h01234567;
    pk = '0;
    repeat (3) @(posedge clk);
    @(negedge clk);
    rst_n = 1;
    start = 1;
    @(negedge clk);
    start = 0;
    wait (valid);
    if (!valid) $fatal(1, "encaps did not validate");
    if (ss !== (msg ^ 32'hA5A5A5A5) || ct[7:0] !== 8'h5A)
      $fatal(1, "encaps scaffold output mismatch: ss=%h ct[7:0]=%h", ss, ct[7:0]);
    $display("encaps status = %0d ss = %h", status, ss);
    $finish;
  end

  always #5 clk = ~clk;
endmodule
