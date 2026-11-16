module ml_kem_512_top (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         start,
  input  logic [1:0]   cmd,
  input  logic [7:0]   seed [0:31],
  input  logic [799:0] pk_in,
  input  logic [1631:0] sk_in,
  input  logic [767:0] ct_in,
  input  logic [31:0]  msg_in,
  output logic [799:0] pk_out,
  output logic [1631:0] sk_out,
  output logic [767:0] ct_out,
  output logic [31:0]  msg_out,
  output logic [31:0]  ss_out,
  output logic         valid,
  output logic [7:0]   status
);

  logic [799:0] pk_local;
  logic [1631:0] sk_local;
  logic [767:0] ct_local;
  logic [31:0] msg_local;
  logic [31:0] ss_local;
  logic key_valid, enc_valid, dec_valid;
  logic [7:0] key_status, enc_status, dec_status;

  ml_kem_512_keygen u_keygen (
    .clk(clk),
    .rst_n(rst_n),
    .start(start && (cmd == 2'b00)),
    .seed(seed),
    .pk(pk_local),
    .sk(sk_local),
    .valid(key_valid),
    .status(key_status)
  );

  ml_kem_512_encaps u_encaps (
    .clk(clk),
    .rst_n(rst_n),
    .start(start && (cmd == 2'b01)),
    .pk(pk_in),
    .msg(msg_in),
    .ct(ct_local),
    .ss(ss_local),
    .valid(enc_valid),
    .status(enc_status)
  );

  ml_kem_512_decaps u_decaps (
    .clk(clk),
    .rst_n(rst_n),
    .start(start && (cmd == 2'b10)),
    .ct(ct_in),
    .sk(sk_in),
    .msg(msg_local),
    .ss(ss_local),
    .valid(dec_valid),
    .status(dec_status)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pk_out <= '0;
      sk_out <= '0;
      ct_out <= '0;
      msg_out <= '0;
      ss_out <= '0;
      valid  <= 1'b0;
      status <= 8'h00;
    end else if (start) begin
      case (cmd)
        2'b00: begin
          pk_out <= pk_local;
          sk_out <= sk_local;
          valid  <= key_valid;
          status <= 8'h10;
        end
        2'b01: begin
          ct_out <= ct_local;
          ss_out <= ss_local;
          valid  <= enc_valid;
          status <= 8'h20;
        end
        2'b10: begin
          msg_out <= msg_local;
          ss_out  <= ss_local;
          valid   <= dec_valid;
          status  <= 8'h30;
        end
        default: begin
          valid <= 1'b0;
          status <= 8'h00;
        end
      endcase
    end else begin
      valid <= 1'b0;
    end
  end
endmodule
