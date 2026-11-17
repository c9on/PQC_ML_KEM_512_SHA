module ml_kem_512_encaps (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         start,
  input  logic [799:0] pk,
  input  logic [31:0]  msg,
  output logic [767:0] ct,
  output logic [31:0]  ss,
  output logic         valid,
  output logic [7:0]   status
);

  logic [7:0] pk_words [0:99];
  logic [7:0] ct_words [0:95];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ct    <= '0;
      ss    <= '0;
      valid <= 1'b0;
      status <= 8'h00;
    end else if (start) begin
      for (int i = 0; i < 100; i++) begin
        pk_words[i] <= pk[(i*8)+:8];
      end

      for (int i = 0; i < 96; i++) begin
        ct_words[i] <= pk[(i % 100)*8 +: 8] ^ 8'h5A;
        ct[(i*8)+:8] <= pk[(i % 100)*8 +: 8] ^ 8'h5A;
      end

      ss <= msg ^ 32'hA5A5A5A5;
      valid <= 1'b1;
      status <= 8'h20;
    end else begin
      valid <= 1'b0;
    end
  end
endmodule
