module tb_shake128;
  logic clk;
  logic rst_n;
  logic start;
  logic [7:0] msg [0:255];
  logic [7:0] msg_len;
  logic [7:0] out_len;
  logic [255:0] digest;
  logic valid;

  shake128 dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .msg(msg),
    .msg_len(msg_len),
    .out_len(out_len),
    .digest(digest),
    .valid(valid)
  );

  initial begin
    clk = 0;
    rst_n = 0;
    start = 0;
    msg_len = 8'd4;
    out_len = 8'd32;
    msg[0] = 8'h00; msg[1]=8'h01; msg[2]=8'h02; msg[3]=8'h03;
    repeat (3) @(posedge clk);
    @(negedge clk);
    rst_n = 1;
    start = 1;
    @(negedge clk);
    start = 0;
    wait (valid);
    if (!valid) $fatal(1, "shake128 did not validate");
    $display("shake128 digest = %h", digest);
    $finish;
  end

  always #5 clk = ~clk;
endmodule
