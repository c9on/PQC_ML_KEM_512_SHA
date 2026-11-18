module tb_sha3_512;
  logic clk;
  logic rst_n;
  logic start;
  logic [7:0] msg [0:255];
  logic [7:0] msg_len;
  logic [511:0] digest;
  logic valid;

  // NIST ACVP SHA3-512-2.0, tgId 1, tcId 25 (96-bit message).
  localparam integer MSG_BYTES = 12;
  localparam logic [MSG_BYTES*8-1:0] ACVP_MSG = 96'hBE5D626A3D0C52B60875D62A;
  localparam logic [511:0] EXPECTED_DIGEST = 512'h2CE82BA7D697120F03DB3010538E7E0FCF22C84E21610FCD6736D983ECAB56B5039C36C96E68F1F03654E1C6DA6F0FDFDE7FC7F072F49296D4D571D75FC1438A;

  sha3_512 dut (
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
      $fatal(1, "SHA3-512 ACVP tg1 tc25 mismatch: got %h expected %h", digest, EXPECTED_DIGEST);
    $display("SHA3-512 ACVP tg1 tc25 PASS: %h", digest);
    $finish;
  end

  always #5 clk = ~clk;
endmodule
