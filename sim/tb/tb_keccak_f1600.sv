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
    @(negedge clk);
    rst_n = 1;
    start = 1;
    @(negedge clk);
    start = 0;
    wait (done);
    if (state_out[63:0] !== 64'hF1258F7940E1DDE7)
      $fatal(1, "keccak_f1600 zero-state lane 0 mismatch: %h", state_out[63:0]);
    $display("keccak_f1600 done, state_out[63:0] = %h", state_out[63:0]);
    $finish;
  end

  always #5 clk = ~clk;
endmodule
