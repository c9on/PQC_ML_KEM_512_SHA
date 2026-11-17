module intt_256 (
  input  logic               clk,
  input  logic               rst_n,
  input  logic               start,
  input  logic signed [0:255][11:0] coeffs,
  output logic signed [0:255][11:0] out_coeffs,
  output logic               valid
);

  localparam int Q = 3329;
  logic signed [23:0] work [0:255];

  for (genvar i = 0; i < 256; i++) begin : g_out
    assign out_coeffs[i] = work[i][11:0];
  end

  function automatic integer mod_q(input integer x);
    integer r;
    begin
      r = x % Q;
      mod_q = (r < 0) ? r + Q : r;
    end
  endfunction

  function automatic integer zeta(input integer k);
    integer reversed, power, result, bit_index;
    begin
      reversed = 0;
      for (bit_index = 0; bit_index < 7; bit_index++)
        reversed = (reversed << 1) | ((k >> bit_index) & 1);
      power = reversed;
      result = 1;
      for (bit_index = 0; bit_index < power; bit_index++)
        result = (result * 17) % Q;
      zeta = result;
    end
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    integer k, len, block_start, j, z, t, scale;
    if (!rst_n) begin
      valid <= 1'b0;
      for (int i = 0; i < 256; i++) begin
        work[i] <= '0;
      end
    end else if (start) begin
      for (int i = 0; i < 256; i++) work[i] = mod_q(coeffs[i]);
      k = 127;
      for (len = 2; len <= 128; len = len << 1) begin
        for (block_start = 0; block_start < 256; block_start = block_start + 2 * len) begin
          z = zeta(k);
          k = k - 1;
          for (j = block_start; j < block_start + len; j++) begin
            t = work[j];
            work[j] = mod_q(t + work[j + len]);
            work[j + len] = mod_q(z * (work[j + len] - t));
          end
        end
      end
      scale = 3303; // 128^-1 mod 3329
      for (int i = 0; i < 256; i++) work[i] = mod_q(work[i] * scale);
      valid <= 1'b1;
    end else begin
      valid <= 1'b0;
    end
  end
endmodule
