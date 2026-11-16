module ml_kem_512_decaps (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         start,
  input  logic [767:0] ct,
  input  logic [1631:0] sk,
  output logic [31:0]  msg,
  output logic [31:0]  ss,
  output logic         valid,
  output logic [7:0]   status
);

  logic [7:0] sk_words [0:203];
  logic [7:0] ct_words [0:95];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      msg   <= '0;
      ss    <= '0;
      valid <= 1'b0;
      status <= 8'h00;
    end else if (start) begin
      for (int i = 0; i < 96; i++) begin
        ct_words[i] <= ct[(i*8)+:8];
      end
      for (int i = 0; i < 204; i++) begin
        sk_words[i] <= sk[(i*8)+:8];
      end

      msg <= {ct_words[0], ct_words[1], ct_words[2], ct_words[3]} ^ 32'hA5A5A5A5;
      ss  <= {sk_words[0], sk_words[1], sk_words[2], sk_words[3]} ^ 32'h5A5A5A5A;
      valid <= 1'b1;
      status <= 8'h30;
    end else begin
      valid <= 1'b0;
    end
  end
endmodule
