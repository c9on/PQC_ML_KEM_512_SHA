module poly_arith (
  input  logic signed [0:255][11:0] a,
  input  logic signed [0:255][11:0] b,
  output logic signed [0:255][11:0] sum,
  output logic signed [0:255][11:0] sub,
  output logic signed [0:255][11:0] mul
);

  localparam int Q = 3329;

  function automatic logic signed [23:0] reduce_q(input logic signed [23:0] x);
    logic signed [23:0] y;
    y = x % Q;
    if (y < 0) y = y + Q;
    reduce_q = y;
  endfunction

  for (genvar i = 0; i < 256; i++) begin : g_coeff
    wire signed [12:0] add_raw = $signed(a[i]) + $signed(b[i]);
    wire signed [12:0] sub_raw = $signed(a[i]) - $signed(b[i]);
    wire signed [23:0] mul_raw = $signed(a[i]) * $signed(b[i]);
    wire signed [23:0] mul_mod = mul_raw % Q;
    assign sum[i] = (add_raw >= Q) ? add_raw - Q : ((add_raw < 0) ? add_raw + Q : add_raw);
    assign sub[i] = (sub_raw < 0) ? sub_raw + Q : sub_raw;
    assign mul[i] = (mul_mod < 0) ? mul_mod + Q : mul_mod;
  end
endmodule
