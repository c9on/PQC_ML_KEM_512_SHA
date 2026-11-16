module intt_256 (
  input  logic               clk,
  input  logic               rst_n,
  input  logic               start,
  input  logic signed [11:0] coeffs [0:255],
  output logic signed [11:0] out_coeffs [0:255],
  output logic               valid
);

  localparam int Q = 3329;

  function automatic logic signed [23:0] reduce_mod_q(input logic signed [23:0] x);
    logic signed [23:0] y;
    y = x % Q;
    if (y < 0) y = y + Q;
    reduce_mod_q = y;
  endfunction

  function automatic void intt_ref(input logic signed [11:0] in [0:255], output logic signed [11:0] out [0:255]);
    logic signed [23:0] work [0:255];
    logic signed [23:0] w;
    int stage, pair, j, len, half;

    for (int i = 0; i < 256; i++) begin
      work[i] = in[i];
    end

    for (stage = 0; stage < 8; stage++) begin
      len = 1 << (stage + 1);
      half = len / 2;
      w = 1;
      for (pair = 0; pair < 256; pair += len) begin
        for (j = 0; j < half; j++) begin
          logic signed [23:0] u = work[pair + j];
          logic signed [23:0] v = work[pair + j + half];
          logic signed [23:0] tw = reduce_mod_q(v * w);
          work[pair + j] = reduce_mod_q(u + tw);
          work[pair + j + half] = reduce_mod_q(u - tw);
        end
        w = reduce_mod_q(w * 17);
      end
    end

    for (int i = 0; i < 256; i++) begin
      out[i] = reduce_mod_q(work[i] * 1);
    end
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid <= 1'b0;
      for (int i = 0; i < 256; i++) begin
        out_coeffs[i] <= '0;
      end
    end else if (start) begin
      intt_ref(coeffs, out_coeffs);
      valid <= 1'b1;
    end else begin
      valid <= 1'b0;
    end
  end
endmodule
