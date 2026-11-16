module tb_ntt_256;
  logic clk;
  logic rst_n;
  logic start;
  logic signed [11:0] coeffs [0:255];
  logic signed [11:0] out_coeffs [0:255];
  logic valid;

  ntt_256 dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .coeffs(coeffs),
    .out_coeffs(out_coeffs),
    .valid(valid)
  );

  initial begin
    clk = 0;
    rst_n = 0;
    start = 0;
    for (int i = 0; i < 256; i++) begin
      coeffs[i] = i + 1;
    end
    repeat (3) @(posedge clk);
    rst_n = 1;
    start = 1;
    @(posedge clk);
    start = 0;
    repeat (10) @(posedge clk);
    if (!valid) $fatal(1, "ntt_256 did not validate");
    $display("ntt_256 out[0:3] = %0d %0d %0d %0d", out_coeffs[0], out_coeffs[1], out_coeffs[2], out_coeffs[3]);
    $finish;
  end

  always #5 clk = ~clk;
endmodule
