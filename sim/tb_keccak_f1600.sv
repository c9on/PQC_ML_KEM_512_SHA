module tb_keccak_f1600;
  logic clk;
  logic rst_n;
  logic start;
  logic [1599:0] state_in;
  logic [1599:0] state_out;
  logic done;

  keccak_f1600 dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .state_in(state_in),
    .state_out(state_out),
    .done(done)
  );

  initial begin
    clk = 0;
    rst_n = 0;
    start = 0;
    state_in = '0;
    repeat (3) @(posedge clk);
    rst_n = 1;
    start = 1;
    @(posedge clk);
    start = 0;
    repeat (40) @(posedge clk);
    if (!done) $fatal(1, "keccak_f1600 did not complete");
    $display("keccak_f1600 done, state_out[63:0] = %h", state_out[63:0]);
    $finish;
  end

  always #5 clk = ~clk;
endmodule
