module ml_kem_512_kdf (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start,
  input  logic [511:0] input_key,
  input  logic [7:0]  key_len,
  output logic [31:0] shared_secret,
  output logic        valid,
  output logic [7:0]  status
);

  logic [7:0] key_buf [0:63];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shared_secret <= '0;
      valid        <= 1'b0;
      status       <= 8'h00;
      for (int i = 0; i < 64; i++) key_buf[i] <= 8'h00;
    end else if (start) begin
      for (int i = 0; i < 64; i++) begin
        key_buf[i] <= input_key[(i * 8) +: 8];
      end
      shared_secret <= 32'hA5A5A5A5 ^ {key_buf[0], key_buf[1], key_buf[2], key_buf[3]};
      valid        <= 1'b1;
      status       <= 8'h40;
    end else begin
      valid <= 1'b0;
    end
  end
endmodule
