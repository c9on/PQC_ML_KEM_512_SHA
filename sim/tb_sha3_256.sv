module tb_sha3_256;
  logic clk;
  logic rst_n;
  logic start;
  logic [7:0] msg [0:255];
  logic [7:0] msg_len;
  logic [255:0] digest;
  logic valid;

  sha3_256 dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .msg(msg),
    .msg_len(msg_len),
    .digest(digest),
    .valid(valid)
  );

  initial begin
    clk = 0;
    rst_n = 0;
    start = 0;
    msg_len = 8'd3;
    msg[0] = 8'h61; msg[1] = 8'h62; msg[2] = 8'h63;
    repeat (3) @(posedge clk);
    rst_n = 1;
    start = 1;
    @(posedge clk);
    start = 0;
    repeat (10) @(posedge clk);
    if (!valid) $fatal(1, "sha3_256 did not validate");
    $display("sha3_256 digest = %h", digest);
    $finish;
  end

  always #5 clk = ~clk;
endmodule
