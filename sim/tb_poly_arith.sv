module tb_poly_arith;
  logic signed [11:0] a [0:255];
  logic signed [11:0] b [0:255];
  logic signed [11:0] sum [0:255];
  logic signed [11:0] sub [0:255];
  logic signed [11:0] mul [0:255];

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
    $display("poly_arith sum[0] = %0d sub[0] = %0d mul[0] = %0d", sum[0], sub[0], mul[0]);
    $finish;
  end
endmodule
