module tb_sha3_256;
  logic clk;
  logic rst_n;
  logic start;
  logic [7:0] msg [0:255];
  logic [7:0] msg_len;
  logic [255:0] digest;
  logic valid;

  // NIST ACVP SHA3-256-2.0, tgId 1, tcId 19 (168-bit message).
  localparam integer MSG_BYTES = 21;
  localparam logic [MSG_BYTES*8-1:0] ACVP_MSG = 168'hB01239C26852698FBF73156C3C5E3DF12783200902;
  localparam logic [255:0] EXPECTED_DIGEST = 256'h416810B652DE89C206024D8BD14E22249809F55625F0FE23A5B61557501BF8D8;

  sha3_256 dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .msg(msg),
    .msg_len(msg_len),
    .digest(digest),
    .valid(valid)
  );

  integer i;
  initial begin
    clk = 0;
    rst_n = 0;
    start = 0;
    msg_len = MSG_BYTES;
    for (i = 0; i < 256; i = i + 1) msg[i] = 8'h00;
    for (i = 0; i < MSG_BYTES; i = i + 1) msg[i] = ACVP_MSG[(MSG_BYTES-1-i)*8 +: 8];
    repeat (3) @(posedge clk);
    @(negedge clk);
    rst_n = 1;
    start = 1;
    @(negedge clk);
    start = 0;
    wait (valid);
    if (digest !== EXPECTED_DIGEST)
      $fatal(1, "SHA3-256 ACVP tg1 tc19 mismatch: got %h expected %h", digest, EXPECTED_DIGEST);
    $display("SHA3-256 ACVP tg1 tc19 PASS: %h", digest);
    $finish;
  end

  always #5 clk = ~clk;
endmodule
