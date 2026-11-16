module poly_arith (
  input  logic signed [11:0] a [0:255],
  input  logic signed [11:0] b [0:255],
  output logic signed [11:0] sum [0:255],
  output logic signed [11:0] sub [0:255],
  output logic signed [11:0] mul [0:255]
);

  localparam int Q = 3329;

  function automatic logic signed [23:0] reduce_q(input logic signed [23:0] x);
    logic signed [23:0] y;
    y = x % Q;
    if (y < 0) y = y + Q;
    reduce_q = y;
  endfunction

  always_comb begin
    for (int i = 0; i < 256; i++) begin
      sum[i] = reduce_q(a[i] + b[i]);
      sub[i] = reduce_q(a[i] - b[i]);
      mul[i] = reduce_q(a[i] * b[i]);
    end
  end
endmodule
