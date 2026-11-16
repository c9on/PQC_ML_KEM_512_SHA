module tb_ml_kem_512_top;
  logic clk;
  logic rst_n;
  logic start;
  logic [1:0] cmd;
  logic [7:0] msg [0:255];
  logic [7:0] msg_len;
  logic [7:0] out_len;
  logic [255:0] digest;
  logic done;
  logic [7:0] status;

  ml_kem_512_top dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .cmd(cmd),
    .msg(msg),
    .msg_len(msg_len),
    .out_len(out_len),
    .digest(digest),
    .done(done),
    .status(status)
  );

  initial begin
    clk = 0;
    rst_n = 0;
    start = 0;
    cmd = 2'b00;
    msg_len = 8'd3;
    out_len = 8'd32;
    msg[0]=8'h61; msg[1]=8'h62; msg[2]=8'h63;
    repeat (3) @(posedge clk);
    rst_n = 1;
    cmd = 2'b01;
    start = 1;
    @(posedge clk);
    start = 0;
    repeat (10) @(posedge clk);
    if (!done) $fatal(1, "ml_kem_512_top: done did not assert");
    $display("ml_kem_512_top: pass, status=%0d digest=%h", status, digest);
    $finish;
  end

  always #5 clk = ~clk;
endmodule
