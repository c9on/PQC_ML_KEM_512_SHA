module tb_ntt_256;
  logic clk;
  logic rst_n;
  logic start;
  logic signed [0:255][11:0] coeffs;
  logic signed [0:255][11:0] out_coeffs;
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
    @(negedge clk);
    rst_n = 1;
    start = 1;
    @(negedge clk);
    start = 0;
    wait (valid);
    if (out_coeffs[0] === 'x || out_coeffs[1] === 'x || out_coeffs[2] === 'x || out_coeffs[3] === 'x)
      $fatal(1, "ntt_256 produced unknown output coefficients");
    if (out_coeffs[0] !== -12'sd1251 || out_coeffs[1] !== -12'sd835 ||
        out_coeffs[2] !== 12'sd795 || out_coeffs[3] !== 12'sd1165)
      $fatal(1, "ntt_256 reference mismatch: %0d %0d %0d %0d", out_coeffs[0], out_coeffs[1], out_coeffs[2], out_coeffs[3]);
    if (!valid) $fatal(1, "ntt_256 did not validate");
    $display("ntt_256 out[0:3] = %0d %0d %0d %0d", out_coeffs[0], out_coeffs[1], out_coeffs[2], out_coeffs[3]);
    $finish;
  end

  always #5 clk = ~clk;
endmodule
