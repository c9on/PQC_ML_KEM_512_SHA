module poly_core (
  input  logic signed [11:0] a [0:255],
  input  logic signed [11:0] b [0:255],
  output logic signed [11:0] sum [0:255],
  output logic signed [11:0] diff [0:255]
);

  localparam int Q = 3329;

  function automatic logic signed [11:0] reduce_q(input logic signed [23:0] x);
    logic signed [23:0] y;
    y = x % Q;
    if (y < 0) y = y + Q;
    reduce_q = y[11:0];
  endfunction

  always_comb begin
    for (int i = 0; i < 256; i++) begin
      sum[i] = reduce_q(a[i] + b[i]);
      diff[i] = reduce_q(a[i] - b[i]);
    end
  end
endmodule
