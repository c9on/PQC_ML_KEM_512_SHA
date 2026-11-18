module tb_poly_core;
  logic signed [0:255][11:0] a;
  logic signed [0:255][11:0] b;
  logic signed [0:255][11:0] sum;
  logic signed [0:255][11:0] diff;

  poly_core dut (
    .a(a),
    .b(b),
    .sum(sum),
    .diff(diff)
  );

  initial begin
    for (int i = 0; i < 256; i++) begin
      a[i] = i;
      b[i] = 256 - i;
    end
    #1;
    if (sum[0] !== 12'd256 || diff[0] !== 12'd3073)
      $fatal(1, "poly_core coefficient 0 mismatch: sum=%0d diff=%0d", sum[0], diff[0]);
    $display("poly_core: pass, sum[0]=%0d diff[0]=%0d", sum[0], diff[0]);
    $finish;
  end
endmodule
