module sha3_512 (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start,
  input  logic [7:0]  msg [0:255],
  input  logic [7:0]  msg_len,
  output logic [511:0] digest,
  output logic        valid
);

  function automatic logic [1599:0] keccak_f(input logic [1599:0] s);
    logic [63:0] A [0:24];
    logic [63:0] B [0:24];
    logic [63:0] C [0:4];
    logic [63:0] D [0:4];
    logic [63:0] rc [0:23];
    logic [1599:0] out_state;
    int x, y, i, r;
    int rho [0:4][0:4];

    rho[0][0] = 0;  rho[1][0] = 1;  rho[2][0] = 62; rho[3][0] = 28; rho[4][0] = 27;
    rho[0][1] = 36; rho[1][1] = 44; rho[2][1] = 6;  rho[3][1] = 55; rho[4][1] = 20;
    rho[0][2] = 3;  rho[1][2] = 10; rho[2][2] = 43; rho[3][2] = 25; rho[4][2] = 39;
    rho[0][3] = 41; rho[1][3] = 45; rho[2][3] = 15; rho[3][3] = 21; rho[4][3] = 8;
    rho[0][4] = 18; rho[1][4] = 2;  rho[2][4] = 61; rho[3][4] = 56; rho[4][4] = 14;

    rc[0]  = 64'h0000000000000001; rc[1]  = 64'h0000000000008082; rc[2]  = 64'h800000000000808A;
    rc[3]  = 64'h8000000080008000; rc[4]  = 64'h000000000000808B; rc[5]  = 64'h0000000080000001;
    rc[6]  = 64'h8000000080008081; rc[7]  = 64'h8000000000008009; rc[8]  = 64'h000000000000008A;
    rc[9]  = 64'h0000000000000088; rc[10] = 64'h0000000080008009; rc[11] = 64'h000000008000000A;
    rc[12] = 64'h000000008000808B; rc[13] = 64'h800000000000008B; rc[14] = 64'h8000000000008089;
    rc[15] = 64'h8000000000008003; rc[16] = 64'h8000000000008002; rc[17] = 64'h8000000000000080;
    rc[18] = 64'h000000000000800A; rc[19] = 64'h800000008000000A; rc[20] = 64'h8000000080008081;
    rc[21] = 64'h8000000000008080; rc[22] = 64'h0000000080000001; rc[23] = 64'h8000000080008008;

    for (i = 0; i < 25; i++) begin
      A[i] = s[i * 64 +: 64];
    end

    for (r = 0; r < 24; r++) begin
      for (x = 0; x < 5; x++) begin
        C[x] = A[x] ^ A[x + 5] ^ A[x + 10] ^ A[x + 15] ^ A[x + 20];
      end
      for (x = 0; x < 5; x++) begin
        D[x] = C[(x + 4) % 5] ^ ((C[(x + 1) % 5] << 1) | (C[(x + 1) % 5] >> 63));
        for (y = 0; y < 5; y++) begin
          A[x + 5 * y] = A[x + 5 * y] ^ D[x];
        end
      end
      for (x = 0; x < 5; x++) begin
        for (y = 0; y < 5; y++) begin
          B[y + 5 * ((2 * x + 3 * y) % 5)] = ((A[x + 5 * y] << rho[x][y]) | (A[x + 5 * y] >> (64 - rho[x][y])));
        end
      end
      for (x = 0; x < 5; x++) begin
        for (y = 0; y < 5; y++) begin
          A[x + 5 * y] = B[x + 5 * y] ^ ((~B[(x + 1) % 5 + 5 * y]) & B[(x + 2) % 5 + 5 * y]);
        end
      end
      A[0] = A[0] ^ rc[r];
    end

    for (i = 0; i < 25; i++) begin
      out_state[i * 64 +: 64] = A[i];
    end
    keccak_f = out_state;
  endfunction

  function automatic logic [511:0] sha3_512_compute(input int m_len);
    logic [1599:0] s;
    logic [511:0] digest_bytes;
    logic [1599:0] w;
    int i;
    s = '0;
    for (i = 0; i < m_len; i++) begin
      s[(i * 8) +: 8] = msg[i];
    end
    s[(m_len * 8) +: 8] = 8'h06;
    s[575] = 1'b1;
    w = keccak_f(s);
    for (i = 0; i < 64; i++) begin
      digest_bytes[511 - (i * 8) -: 8] = w[i * 8 +: 8];
    end
    sha3_512_compute = digest_bytes;
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      digest <= '0;
      valid  <= 1'b0;
    end else if (start) begin
      digest <= sha3_512_compute(msg_len);
      valid  <= 1'b1;
    end else begin
      valid <= 1'b0;
    end
  end
endmodule
