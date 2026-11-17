module tb_poly_arith;
  logic signed [0:255][11:0] a;
  logic signed [0:255][11:0] b;
  logic signed [0:255][11:0] sum;
  logic signed [0:255][11:0] sub;
  logic signed [0:255][11:0] mul;

  poly_arith dut (
    .a(a),
    .b(b),
    .sum(sum),
    .sub(sub),
    .mul(mul)
  );

  initial begin
    for (int i = 0; i < 256; i++) begin
      a[i] = i;
      b[i] = 256 - i;
    end
    #1;
    if (sum[0] !== 12'd256 || sub[0] !== 12'd3073 || mul[0] !== 12'd0)
      $fatal(1, "poly_arith coefficient 0 mismatch: sum=%0d sub=%0d mul=%0d", sum[0], sub[0], mul[0]);
    $display("poly_arith sum[0] = %0d sub[0] = %0d mul[0] = %0d", sum[0], sub[0], mul[0]);
    $finish;
  end
endmodule
