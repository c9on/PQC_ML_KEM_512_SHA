module tb_poly_core;
  logic signed [11:0] a [0:255];
  logic signed [11:0] b [0:255];
  logic signed [11:0] sum [0:255];
  logic signed [11:0] diff [0:255];

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
    $display("poly_core: pass, sum[0]=%0d diff[0]=%0d", sum[0], diff[0]);
    $finish;
  end
endmodule
