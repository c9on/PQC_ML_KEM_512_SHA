module tb_shake256;
  logic clk;
  logic rst_n;
  logic start;
  logic [7:0] msg [0:255];
  logic [7:0] msg_len;
  logic [7:0] out_len;
  logic [255:0] digest;
  logic valid;

  // NIST ACVP SHAKE-256-FIPS202, tgId 1, tcId 188 (168-bit input, 256-bit output).
  localparam integer MSG_BYTES = 21;
  localparam logic [MSG_BYTES*8-1:0] ACVP_MSG = 168'hDB0E6BC71E17E888558517180B776991A926B23A75;
  localparam logic [255:0] EXPECTED_DIGEST = 256'hB8DDCBC9E42B9A7A0E235D29F0A917390C8650313C83380FCC730691540FC5D0;

  shake256 dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .msg(msg),
    .msg_len(msg_len),
    .out_len(out_len),
    .digest(digest),
    .valid(valid)
  );

  integer i;
  initial begin
    clk = 0;
    rst_n = 0;
    start = 0;
    msg_len = MSG_BYTES;
    out_len = 8'd32;
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
      $fatal(1, "SHAKE256 ACVP tg1 tc188 mismatch: got %h expected %h", digest, EXPECTED_DIGEST);
    $display("SHAKE256 ACVP tg1 tc188 PASS: %h", digest);
    $finish;
  end

  always #5 clk = ~clk;
endmodule
