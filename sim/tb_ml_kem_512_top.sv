module tb_ml_kem_512_top;
  logic clk;
  logic rst_n;
  logic start;
  logic [1:0] cmd;
  logic [7:0] seed [0:31];
  logic [799:0] pk_in, pk_out;
  logic [1631:0] sk_in, sk_out;
  logic [767:0] ct_in, ct_out;
  logic [31:0] msg_in, msg_out, ss_out;
  logic valid;
  logic [7:0] status;

  ml_kem_512_top dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .cmd(cmd),
    .seed(seed),
    .pk_in(pk_in),
    .sk_in(sk_in),
    .ct_in(ct_in),
    .msg_in(msg_in),
    .pk_out(pk_out),
    .sk_out(sk_out),
    .ct_out(ct_out),
    .msg_out(msg_out),
    .ss_out(ss_out),
    .valid(valid),
    .status(status)
  );

  initial begin
    clk = 0;
    rst_n = 0;
    start = 0;
    cmd = 2'b00;
    pk_in = '0;
    sk_in = '0;
    ct_in = '0;
    msg_in = 32'h01234567;
    for (int i = 0; i < 32; i++) seed[i] = i[7:0];
    repeat (3) @(posedge clk);
    @(negedge clk);
    rst_n = 1;
    start = 1;
    @(negedge clk);
    start = 0;
    wait (valid);
    if (status !== 8'h10 || pk_out[15:0] !== 16'ha4a5)
      $fatal(1, "ml_kem_512_top keygen output mismatch: status=%h pk=%h", status, pk_out[15:0]);
    $display("ml_kem_512_top: valid, status=%0d pk[15:0]=%h", status, pk_out[15:0]);
    $finish;
  end

  always #5 clk = ~clk;
endmodule
