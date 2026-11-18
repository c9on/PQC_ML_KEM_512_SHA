package ml_kem_fips203_pkg;

  // ML-KEM-512 polynomial size and coefficient modulus.
  localparam int Q = 3329;
  localparam int N = 256;

  // Barrett-style reduction shared by the arithmetic functions below.
  function automatic logic [11:0] reduce_q(input logic signed [63:0] x);
    logic [63:0] magnitude;
    logic [63:0] quotient;
    logic [63:0] remainder;
    begin
      magnitude = x[63] ? -x : x;
      quotient = (magnitude * 64'd5039) >> 24;
      remainder = magnitude - quotient * Q;
      if (remainder >= Q)
        remainder = remainder - Q;
      if (remainder >= Q)
        remainder = remainder - Q;
      if (x[63] && (remainder != 0))
        remainder = Q - remainder;
      reduce_q = remainder[11:0];
    end
  endfunction

  function automatic integer modq(input integer x);
    begin
      modq = reduce_q(x);
    end
  endfunction

  function automatic logic [63:0] rol64(
    input logic [63:0] x,
    input integer n
  );
    integer r;
    begin
      r = n % 64;
      rol64 = (r == 0) ? x : (x << r) | (x >> (64 - r));
    end
  endfunction

  // Keccak-f[1600] is the common permutation used by SHA3 and SHAKE.
  function automatic logic [1599:0] keccak(input logic [1599:0] s);
    logic [63:0] a [0:24];
    logic [63:0] b [0:24];
    logic [63:0] c [0:4];
    logic [63:0] d [0:4];
    logic [63:0] rc [0:23];
    integer rho [0:4][0:4];
    integer x;
    integer y;
    integer i;
    integer r;
    begin
      rho[0][0] = 0;  rho[1][0] = 1;  rho[2][0] = 62; rho[3][0] = 28; rho[4][0] = 27;
      rho[0][1] = 36; rho[1][1] = 44; rho[2][1] = 6;  rho[3][1] = 55; rho[4][1] = 20;
      rho[0][2] = 3;  rho[1][2] = 10; rho[2][2] = 43; rho[3][2] = 25; rho[4][2] = 39;
      rho[0][3] = 41; rho[1][3] = 45; rho[2][3] = 15; rho[3][3] = 21; rho[4][3] = 8;
      rho[0][4] = 18; rho[1][4] = 2;  rho[2][4] = 61; rho[3][4] = 56; rho[4][4] = 14;

      rc[0]  = 64'h0000000000000001; rc[1]  = 64'h0000000000008082;
      rc[2]  = 64'h800000000000808A; rc[3]  = 64'h8000000080008000;
      rc[4]  = 64'h000000000000808B; rc[5]  = 64'h0000000080000001;
      rc[6]  = 64'h8000000080008081; rc[7]  = 64'h8000000000008009;
      rc[8]  = 64'h000000000000008A; rc[9]  = 64'h0000000000000088;
      rc[10] = 64'h0000000080008009; rc[11] = 64'h000000008000000A;
      rc[12] = 64'h000000008000808B; rc[13] = 64'h800000000000008B;
      rc[14] = 64'h8000000000008089; rc[15] = 64'h8000000000008003;
      rc[16] = 64'h8000000000008002; rc[17] = 64'h8000000000000080;
      rc[18] = 64'h000000000000800A; rc[19] = 64'h800000008000000A;
      rc[20] = 64'h8000000080008081; rc[21] = 64'h8000000000008080;
      rc[22] = 64'h0000000080000001; rc[23] = 64'h8000000080008008;

      for (i = 0; i < 25; i = i + 1)
        a[i] = s[i*64 +: 64];

      for (r = 0; r < 24; r = r + 1) begin
        for (x = 0; x < 5; x = x + 1)
          c[x] = a[x] ^ a[x + 5] ^ a[x + 10] ^ a[x + 15] ^ a[x + 20];

        for (x = 0; x < 5; x = x + 1) begin
          d[x] = c[(x + 4) % 5] ^ rol64(c[(x + 1) % 5], 1);
          for (y = 0; y < 5; y = y + 1)
            a[x + 5*y] ^= d[x];
        end

        for (x = 0; x < 5; x = x + 1)
          for (y = 0; y < 5; y = y + 1)
            b[y + 5*((2*x + 3*y) % 5)] = rol64(a[x + 5*y], rho[x][y]);

        for (x = 0; x < 5; x = x + 1)
          for (y = 0; y < 5; y = y + 1)
            a[x + 5*y] = b[x + 5*y]
                       ^ ((~b[(x + 1) % 5 + 5*y]) & b[(x + 2) % 5 + 5*y]);

        a[0] ^= rc[r];
      end

      for (i = 0; i < 25; i = i + 1)
        keccak[i*64 +: 64] = a[i];
    end
  endfunction

  // Sponge absorption; vectors are represented as MSB-first buses and are
  // presented to the permutation in hexadecimal byte-stream order.
  function automatic logic [1599:0] absorb(
    input logic [16383:0] m,
    input int len,
    input int rate,
    input logic [7:0] padbyte
  );
    logic [1599:0] s;
    integer i;
    integer p;
    begin
      s = '0;
      p = 0;
      for (i = 0; i < len; i = i + 1) begin
        s[p*8 +: 8] ^= m[(len - 1 - i)*8 +: 8];
        p = p + 1;
        if (p == rate) begin
          s = keccak(s);
          p = 0;
        end
      end
      s[p*8 +: 8] ^= padbyte;
      s[(rate*8) - 1] ^= 1'b1;
      absorb = keccak(s);
    end
  endfunction

  // Sponge squeezing produces the stream needed for sampling operations.
  function automatic logic [8191:0] squeeze(
    input logic [1599:0] st,
    input int rate
  );
    integer i;
    logic [1599:0] s;
    begin
      s = st;
      for (i = 0; i < 1024; i = i + 1) begin
        squeeze[(1023 - i)*8 +: 8] = s[(i % rate)*8 +: 8];
        if (((i % rate) == (rate - 1)) && (i < 1023))
          s = keccak(s);
      end
    end
  endfunction

  // FIPS 202 wrappers: SHA3 uses suffix 0x06; SHAKE uses suffix 0x1F.
  function automatic logic [255:0] sha3_256(input logic [16383:0] m, input int len);
    logic [1599:0] s;
    integer i;
    begin
      s = absorb(m, len, 136, 8'h06);
      for (i = 0; i < 32; i = i + 1)
        sha3_256[(31 - i)*8 +: 8] = s[i*8 +: 8];
    end
  endfunction

  // SHA3-512 is used by ML-KEM's G function to produce a 64-byte value.
  // For key generation this is split into rho and sigma; for encapsulation it
  // is split into Kbar and encryption coins.
  function automatic logic [511:0] sha3_512(input logic [16383:0] m, input int len);
    logic [1599:0] s;
    integer i;
    begin
      s = absorb(m, len, 72, 8'h06);
      for (i = 0; i < 64; i = i + 1)
        sha3_512[(63 - i)*8 +: 8] = s[i*8 +: 8];
    end
  endfunction

  // SHAKE128 expands the public seed rho plus matrix coordinates j and i.
  // Rejection sampling turns this XOF stream into the 256 NTT coefficients.
  function automatic logic [8191:0] shake128(input logic [16383:0] m, input int len);
    integer i;
    logic [1599:0] s;
    begin
      s = absorb(m, len, 168, 8'h1F);
      shake128 = '0;
      for (i = 0; i < 768; i = i + 1) begin
        shake128[(1023 - i)*8 +: 8] = s[(i % 168)*8 +: 8];
        if (((i % 168) == 167) && (i < 767))
          s = keccak(s);
      end
    end
  endfunction

  // SHAKE256 supplies deterministic polynomial noise bytes from seed||nonce.
  // It is also used for implicit rejection as SHAKE256(z || ciphertext).
  function automatic logic [8191:0] shake256(input logic [16383:0] m, input int len);
    integer i;
    logic [1599:0] s;
    begin
      s = absorb(m, len, 136, 8'h1F);
      shake256 = '0;
      for (i = 0; i < 192; i = i + 1) begin
        shake256[(1023 - i)*8 +: 8] = s[(i % 136)*8 +: 8];
        if (((i % 136) == 135) && (i < 191))
          s = keccak(s);
      end
    end
  endfunction

  // Convenience wrapper that keeps only the first 32 bytes of SHAKE256 output.
  function automatic logic [255:0] shake256_32(input logic [16383:0] m, input int len);
    logic [8191:0] x;
    integer i;
    begin
      x = shake256(m, len);
      for (i = 0; i < 32; i = i + 1)
        shake256_32[(31 - i)*8 +: 8] = x[(1023 - i)*8 +: 8];
    end
  endfunction

  // Twiddle-factor generation for the ML-KEM negacyclic NTT.
  function automatic logic [11:0] zeta(input int k);
    integer r;
    integer i;
    integer p;
    begin
      r = 0;
      for (i = 0; i < 7; i = i + 1)
        r = (r << 1) | ((k >> i) & 1);
      p = 1;
      for (i = 0; i < r; i = i + 1)
        p = p * 17 % Q;
      zeta = p;
    end
  endfunction

  // Forward Cooley-Tukey transform; inverse transform uses the reverse stages
  // and the final 128^-1 scaling modulo q.
  function automatic logic [3071:0] ntt(input logic [3071:0] src);
    integer len;
    integer bs;
    integer j;
    integer k;
    integer z;
    integer t;
    logic [11:0] a [0:255];
    begin
      for (j = 0; j < N; j = j + 1)
        a[j] = src[j*12 +: 12];
      k = 1;
      for (len = 128; len >= 2; len = len >> 1) begin
        for (bs = 0; bs < N; bs = bs + 2*len) begin
          z = zeta(k);
          k = k + 1;
          for (j = bs; j < bs + len; j = j + 1) begin
            t = modq(z * a[j + len]);
            a[j + len] = modq(a[j] - t);
            a[j] = modq(a[j] + t);
          end
        end
      end
      for (j = 0; j < N; j = j + 1)
        ntt[j*12 +: 12] = a[j];
    end
  endfunction

  // Inverse NTT reverses the transform stages and applies 128^-1 modulo 3329.
  function automatic logic [3071:0] intt(input logic [3071:0] src);
    integer len;
    integer bs;
    integer j;
    integer k;
    integer z;
    integer t;
    logic [11:0] a [0:255];
    begin
      for (j = 0; j < N; j = j + 1)
        a[j] = src[j*12 +: 12];
      k = 127;
      for (len = 2; len <= 128; len = len << 1) begin
        for (bs = 0; bs < N; bs = bs + 2*len) begin
          z = zeta(k);
          k = k - 1;
          for (j = bs; j < bs + len; j = j + 1) begin
            t = a[j];
            a[j] = modq(t + a[j + len]);
            a[j + len] = modq(z * (a[j + len] - t));
          end
        end
      end
      for (j = 0; j < N; j = j + 1)
        intt[j*12 +: 12] = modq(a[j] * 3303);
    end
  endfunction

  // Multiply two polynomials already in ML-KEM NTT form using quadratic bases.
  // Products are reduced before summation to keep the intermediate bounded.
  function automatic logic [3071:0] basemul(input logic [3071:0] a, input logic [3071:0] b);
    integer i;
    integer z;
    integer p0;
    integer p1;
    begin
      basemul = '0;
      for (i = 0; i < 64; i = i + 1) begin
        z = zeta(64 + i);
        p0 = modq(a[(4*i)*12 +: 12] * b[(4*i)*12 +: 12]);
        p1 = modq(modq(a[(4*i + 1)*12 +: 12] * b[(4*i + 1)*12 +: 12]) * z);
        basemul[(4*i)*12 +: 12] = modq(p0 + p1);
        basemul[(4*i + 1)*12 +: 12] = modq(
          a[(4*i)*12 +: 12] * b[(4*i + 1)*12 +: 12]
          + a[(4*i + 1)*12 +: 12] * b[(4*i)*12 +: 12]
        );

        p0 = modq(a[(4*i + 2)*12 +: 12] * b[(4*i + 2)*12 +: 12]);
        p1 = modq(modq(a[(4*i + 3)*12 +: 12] * b[(4*i + 3)*12 +: 12]) * z);
        basemul[(4*i + 2)*12 +: 12] = modq(p0 - p1);
        basemul[(4*i + 3)*12 +: 12] = modq(
          a[(4*i + 2)*12 +: 12] * b[(4*i + 3)*12 +: 12]
          + a[(4*i + 3)*12 +: 12] * b[(4*i + 2)*12 +: 12]
        );
      end
    end
  endfunction

  // Coefficient-wise polynomial addition modulo q.
  function automatic logic [3071:0] addp(input logic [3071:0] a, input logic [3071:0] b);
    integer i;
    begin
      for (i = 0; i < N; i = i + 1)
        addp[i*12 +: 12] = modq(a[i*12 +: 12] + b[i*12 +: 12]);
    end
  endfunction

  // Coefficient-wise polynomial subtraction modulo q; used for v - s^T*u.
  function automatic logic [3071:0] subp(input logic [3071:0] a, input logic [3071:0] b);
    integer i;
    begin
      for (i = 0; i < N; i = i + 1)
        subp[i*12 +: 12] = modq(a[i*12 +: 12] - b[i*12 +: 12]);
    end
  endfunction

  // Matrix coefficients are generated by rejecting 12-bit values >= 3329.
  function automatic logic [3071:0] sample_ntt(input logic [8191:0] s);
    integer i;
    integer p;
    logic [11:0] a;
    logic [11:0] b;
    begin
      i = 0;
      p = 0;
      sample_ntt = '0;
      while ((p < N) && (i < 1022)) begin
        a = s[(1023 - i)*8 +: 8] | (s[(1022 - i)*8 +: 8] << 8);
        a &= 4095;
        b = (s[(1022 - i)*8 +: 8] >> 4) | (s[(1021 - i)*8 +: 8] << 4);
        if (a < Q) begin
          sample_ntt[p*12 +: 12] = a;
          p = p + 1;
        end
        if ((p < N) && (b < Q)) begin
          sample_ntt[p*12 +: 12] = b;
          p = p + 1;
        end
        i = i + 3;
      end
    end
  endfunction

  // Centered binomial distribution: eta=3 for ML-KEM-512 key-encryption
  // randomness and eta=2 for the specified e2/noise path.
  function automatic logic [3071:0] cbd(input logic [8191:0] s, input int eta);
    integer i;
    integer j;
    integer pos;
    integer a;
    integer b;
    begin
      cbd = '0;
      for (i = 0; i < N; i = i + 1) begin
        a = 0;
        b = 0;
        for (j = 0; j < eta; j = j + 1) begin
          pos = 2*eta*i + j;
          a = a + s[8184 - (pos/8)*8 + (pos%8)];
          pos = 2*eta*i + eta + j;
          b = b + s[8184 - (pos/8)*8 + (pos%8)];
        end
        cbd[i*12 +: 12] = modq(a - b);
      end
    end
  endfunction

  // FIPS 203 coefficient serialization. pack12/unpack12 handle keys, while
  // pack10/unpack10 and pack4/unpack4 handle the two ciphertext components.
  function automatic logic [3071:0] pack12(input logic [3071:0] p);
    integer i;
    logic [11:0] x;
    logic [11:0] y;
    logic [3071:0] b;
    begin
      b = '0;
      for (i = 0; i < 128; i = i + 1) begin
        x = p[(2*i)*12 +: 12];
        y = p[(2*i + 1)*12 +: 12];
        b[(383 - 3*i)*8 +: 8] = x;
        b[(382 - 3*i)*8 +: 8] = (x >> 8) | (y << 4);
        b[(381 - 3*i)*8 +: 8] = y >> 4;
      end
      pack12 = b;
    end
  endfunction

  function automatic logic [3071:0] unpack12(input logic [3071:0] b);
    integer i;
    logic [7:0] x;
    logic [7:0] y;
    logic [7:0] z;
    begin
      for (i = 0; i < 128; i = i + 1) begin
        x = b[(383 - 3*i)*8 +: 8];
        y = b[(382 - 3*i)*8 +: 8];
        z = b[(381 - 3*i)*8 +: 8];
        unpack12[(2*i)*12 +: 12] = x | ((y & 15) << 8);
        unpack12[(2*i + 1)*12 +: 12] = (y >> 4) | (z << 4);
      end
    end
  endfunction

  // 10-bit packing represents each compressed u polynomial in 320 bytes.
  function automatic logic [2559:0] pack10(input logic [3071:0] p);
    logic [3199:0] b;
    integer i;
    begin
      b = '0;
      for (i = 0; i < N; i = i + 1)
        b[i*10 +: 10] = p[i*12 +: 10];
      for (i = 0; i < 320; i = i + 1)
        pack10[(319 - i)*8 +: 8] = b[i*8 +: 8];
    end
  endfunction

  function automatic logic [3071:0] unpack10(input logic [2559:0] p);
    logic [3199:0] b;
    integer i;
    begin
      b = '0;
      for (i = 0; i < 320; i = i + 1)
        b[i*8 +: 8] = p[(319 - i)*8 +: 8];
      for (i = 0; i < N; i = i + 1)
        unpack10[i*12 +: 12] = b[i*10 +: 10];
    end
  endfunction

  // 4-bit packing represents the compressed v polynomial in 128 bytes.
  function automatic logic [1023:0] pack4(input logic [3071:0] p);
    integer i;
    begin
      for (i = 0; i < 128; i = i + 1) begin
        pack4[(127 - i)*8 +: 4] = p[(2*i)*12 +: 4];
        pack4[(127 - i)*8 + 4 +: 4] = p[(2*i + 1)*12 +: 4];
      end
    end
  endfunction

  function automatic logic [3071:0] unpack4(input logic [1023:0] p);
    integer i;
    begin
      for (i = 0; i < 128; i = i + 1) begin
        unpack4[(2*i)*12 +: 12] = p[(127 - i)*8 +: 4];
        unpack4[(2*i + 1)*12 +: 12] = p[(127 - i)*8 + 4 +: 4];
      end
    end
  endfunction

  // Compression and decompression are applied coefficient by coefficient
  // before ciphertext packing or after ciphertext unpacking.
  function automatic logic [3071:0] compress(input logic [3071:0] p, input int d);
    integer i;
    begin
      for (i = 0; i < N; i = i + 1)
        compress[i*12 +: 12] = (((p[i*12 +: 12] << d) + Q/2) / Q) & ((1 << d) - 1);
    end
  endfunction

  function automatic logic [3071:0] decompress(input logic [3071:0] p, input int d);
    integer i;
    begin
      for (i = 0; i < N; i = i + 1)
        decompress[i*12 +: 12] = (p[i*12 +: 12] * Q + (1 << (d - 1))) >> d;
    end
  endfunction

  // A message bit is encoded near q/2 and decoded using quarter-range bounds.
  function automatic logic [255:0] decode_msg(input logic [3071:0] p);
    integer i;
    begin
      decode_msg = '0;
      for (i = 0; i < N; i = i + 1)
        decode_msg[248 - (i/8)*8 + (i%8)] =
          (p[i*12 +: 12] > Q/4) && (p[i*12 +: 12] < 3*Q/4);
    end
  endfunction

  function automatic logic [3071:0] encode_msg(input logic [255:0] m);
    integer i;
    begin
      for (i = 0; i < N; i = i + 1)
        encode_msg[i*12 +: 12] = m[248 - (i/8)*8 + (i%8)] ? 1665 : 0;
    end
  endfunction

  // Key checks used by the request FSM and ACVP key-check vectors:
  // EK coefficients must be canonical and DK must contain H(EK).
  function automatic logic ek_valid(input logic [6399:0] ek);
    logic [3071:0] t0;
    logic [3071:0] t1;
    logic all_canonical;
    integer i;
    begin
      t0 = unpack12(ek[6399:3328]);
      t1 = unpack12(ek[3327:256]);
      all_canonical = 1'b1;
      for (i = 0; i < N; i = i + 1) begin
        if (t0[i*12 +: 12] >= Q)
          all_canonical = 1'b0;
        if (t1[i*12 +: 12] >= Q)
          all_canonical = 1'b0;
      end
      ek_valid = all_canonical;
    end
  endfunction

  function automatic logic dk_valid(input logic [13055:0] dk);
    logic [6399:0] ek;
    logic [255:0] h;
    begin
      ek = dk[6911:512];
      h = sha3_256(ek, 800);
      dk_valid = (dk[511:256] === h);
    end
  endfunction

endpackage
