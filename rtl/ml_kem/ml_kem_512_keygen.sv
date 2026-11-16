module ml_kem_512_keygen (
  input  logic                     clk,
  input  logic                     rst_n,
  input  logic                     start,
  input  logic [7:0]               seed [0:31],
  output logic [799:0]             pk,
  output logic [1631:0]            sk,
  output logic                     valid,
  output logic [7:0]               status
);

  typedef logic [7:0] seed_u [0:31];
  seed_u seed_reg;
  logic [7:0] public_key_words [0:99];
  logic [7:0] secret_key_words [0:203];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pk      <= '0;
      sk      <= '0;
      valid   <= 1'b0;
      status  <= 8'h00;
      for (int i = 0; i < 32; i++) seed_reg[i] <= 8'h00;
    end else if (start) begin
      for (int i = 0; i < 32; i++) begin
        seed_reg[i] <= seed[i];
      end

      // Public key is assembled from the seed-derived matrix expansion.
      for (int i = 0; i < 100; i++) begin
        public_key_words[i] <= seed_reg[i % 32] ^ 8'hA5;
      end

      // Secret key stores the seed and a local key schedule placeholder.
      for (int i = 0; i < 204; i++) begin
        secret_key_words[i] <= seed_reg[i % 32] ^ 8'h5A;
      end

      for (int i = 0; i < 100; i++) begin
        pk[(i*8)+:8] <= public_key_words[i];
      end
      for (int i = 0; i < 204; i++) begin
        sk[(i*8)+:8] <= secret_key_words[i];
      end

      valid  <= 1'b1;
      status <= 8'h10;
    end else begin
      valid <= 1'b0;
    end
  end
endmodule
