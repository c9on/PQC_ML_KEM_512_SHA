module tb_shake256;
  logic clk;
  logic rst_n;
  logic start;
  logic [7:0] msg [0:255];
  logic [7:0] msg_len;
  logic [7:0] out_len;
  logic [255:0] digest;
  logic valid;

  shake256 dut (
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
    msg[0] = 8'h10; msg[1]=8'h20; msg[2]=8'h30; msg[3]=8'h40;
    repeat (3) @(posedge clk);
    rst_n = 1;
    start = 1;
    @(posedge clk);
    start = 0;
    repeat (10) @(posedge clk);
    if (!valid) $fatal(1, "shake256 did not validate");
    $display("shake256 digest = %h", digest);
    $finish;
  end

  always #5 clk = ~clk;
endmodule
