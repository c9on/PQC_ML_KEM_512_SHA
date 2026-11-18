module tb_shake128;
  logic clk;
  logic rst_n;
  logic start;
  logic [7:0] msg [0:255];
  logic [7:0] msg_len;
  logic [7:0] out_len;
  logic [255:0] digest;
  logic valid;

  // NIST ACVP SHAKE-128-FIPS202, tgId 1, tcId 54 (1088-bit input, 256-bit output).
  localparam integer MSG_BYTES = 136;
  localparam logic [MSG_BYTES*8-1:0] ACVP_MSG = 1088'hF48C9A028164A0ACC4F96C7EA5CED26F482C2A834ADFACA22E5351DAE347CD23B86BF68FDF4448809B4B6AC5CF0D1B5CAA4C433D43415FEA1C7A46CAE43BF72EBE3C8CC02B7CBB8B6A6DC5A9CAC81C741E3516DB758C5F442C210C9BD0B3EE60F4348EEC823A92C128B8C9A2868B0C2916167DD29CEC624C280EFBBD3EE44434104B35D6F1328B9C;
  localparam logic [255:0] EXPECTED_DIGEST = 256'h93C658214E0287CA26732DF2847C4CF8B24B1FB14A9435BDFD088BDDDA9FCB75;

  shake128 dut (
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
      $fatal(1, "SHAKE128 ACVP tg1 tc54 mismatch: got %h expected %h", digest, EXPECTED_DIGEST);
    $display("SHAKE128 ACVP tg1 tc54 PASS: %h", digest);
    $finish;
  end

  always #5 clk = ~clk;
endmodule
