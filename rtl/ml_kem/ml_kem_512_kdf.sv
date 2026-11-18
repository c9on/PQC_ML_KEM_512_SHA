module ml_kem_512_kdf
  import ml_kem_fips203_pkg::*;
(
  input  logic          clk,
  input  logic          rst_n,
  input  logic          start,
  input  logic [255:0]  z,
  input  logic [6143:0] ct,
  output logic [255:0]  shared_secret,
  output logic          busy,
  output logic          valid,
  output logic [7:0]    status
);

  logic active;

  // Exposes J(z || c) = SHAKE256(z || c, 32 bytes) as a standalone unit.
  // The active handshake provides a simple two-cycle wrapper around the core.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shared_secret <= '0;
      busy          <= 1'b0;
      valid         <= 1'b0;
      status        <= 8'h00;
      active        <= 1'b0;
    end else begin
      valid <= 1'b0;

      if (start && !active) begin
        busy   <= 1'b1;
        active <= 1'b1;
        status <= 8'h40;
      end else if (active) begin
        shared_secret <= shake256_32({z, ct}, 800);
        busy          <= 1'b0;
        valid         <= 1'b1;
        active        <= 1'b0;
      end
    end
  end
endmodule
