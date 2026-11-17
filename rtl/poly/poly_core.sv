module poly_core (
  input  logic signed [0:255][11:0] a,
  input  logic signed [0:255][11:0] b,
  output logic signed [0:255][11:0] sum,
  output logic signed [0:255][11:0] diff
);

  localparam int Q = 3329;

  function automatic logic signed [11:0] reduce_q(input logic signed [23:0] x);
    logic signed [23:0] y;
    y = x % Q;
    if (y < 0) y = y + Q;
    reduce_q = y[11:0];
  endfunction

  for (genvar i = 0; i < 256; i++) begin : g_coeff
    wire signed [12:0] add_raw = $signed(a[i]) + $signed(b[i]);
    wire signed [12:0] sub_raw = $signed(a[i]) - $signed(b[i]);
    assign sum[i] = (add_raw >= Q) ? add_raw - Q : ((add_raw < 0) ? add_raw + Q : add_raw);
    assign diff[i] = (sub_raw < 0) ? sub_raw + Q : sub_raw;
  end
endmodule
