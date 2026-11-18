module ml_kem_512_engine
  import ml_kem_fips203_pkg::*;
(
  // cmd/op encoding: 00 keygen, 01 encapsulation, 10 decapsulation.
  // Widths are full FIPS 203 ML-KEM-512 sizes in bits.
  input  logic           clk,
  input  logic           rst_n,
  input  logic           start,
  input  logic [1:0]     op,
  input  logic [255:0]   d,
  input  logic [255:0]   z,
  input  logic [255:0]   m,
  input  logic [6399:0]  ek,
  input  logic [13055:0] dk,
  input  logic [6143:0]  ct_in,
  output logic [6399:0]  ek_out,
  output logic [13055:0] dk_out,
  output logic [6143:0]  ct_out,
  output logic [255:0]   ss_out,
  output logic           busy,
  output logic           valid,
  output logic [7:0]     status
);

  // Control is multi-cycle so callers can observe busy and valid reliably.
  // Cryptographic package functions are currently executed in COMPUTE.
  typedef enum logic [2:0] {
    IDLE,
    ACQUIRE,
    RUN_HASH,
    RUN_POLY,
    COMPUTE,
    DONE
  } state_t;

  // Request data is latched in ACQUIRE so changing input ports while busy
  // cannot alter an operation already accepted by the engine.
  state_t state;

  logic [1:0]     op_r;
  logic [255:0]   d_r;
  logic [255:0]   z_r;
  logic [255:0]   m_r;
  logic [6399:0]  ek_r;
  logic [13055:0] dk_r;
  logic [6143:0]  ct_r;

  // Generate one polynomial A[i][j] with SHAKE128(rho || j || i), followed by
  // rejection sampling. FIPS 203 returns this polynomial in NTT form.
  function automatic logic [3071:0] matrix_poly(
    input logic [255:0] rho,
    input int i,
    input int j
  );
    logic [16383:0] x;
    begin
      x = '0;
      for (int q = 0; q < 32; q = q + 1)
        x[(33 - q)*8 +: 8] = rho[(31 - q)*8 +: 8];
      x[15:8] = j;
      x[7:0] = i;
      matrix_poly = sample_ntt(shake128(x, 34));
    end
  endfunction

  // Sample one centered-binomial polynomial with SHAKE256(seed || nonce).
  function automatic logic [3071:0] noise(
    input logic [255:0] seed,
    input int eta,
    input int nonce
  );
    logic [16383:0] x;
    begin
      x = '0;
      for (int q = 0; q < 32; q = q + 1)
        x[(32 - q)*8 +: 8] = seed[(31 - q)*8 +: 8];
      x[7:0] = nonce;
      noise = cbd(shake256(x, 33), eta);
    end
  endfunction

  // PKE.KeyGen computes A*s + e in the NTT domain and serializes t || rho
  // as the 800-byte public key (encryption key, EK).
  function automatic logic [6399:0] keypair_ek(input logic [255:0] dd);
    logic [511:0] g;
    logic [255:0] rho;
    logic [255:0] sig;
    logic [3071:0] a00;
    logic [3071:0] a01;
    logic [3071:0] a10;
    logic [3071:0] a11;
    logic [3071:0] s0;
    logic [3071:0] s1;
    logic [3071:0] e0;
    logic [3071:0] e1;
    logic [3071:0] b0;
    logic [3071:0] b1;
    logic [3071:0] t0;
    logic [3071:0] t1;
    begin
      g = sha3_512({dd, 8'h02}, 33);
      rho = g[511:256];
      sig = g[255:0];

      a00 = matrix_poly(rho, 0, 0);
      a01 = matrix_poly(rho, 0, 1);
      a10 = matrix_poly(rho, 1, 0);
      a11 = matrix_poly(rho, 1, 1);
      s0 = ntt(noise(sig, 3, 0));
      s1 = ntt(noise(sig, 3, 1));
      e0 = ntt(noise(sig, 3, 2));
      e1 = ntt(noise(sig, 3, 3));

      b0 = addp(basemul(a00, s0), basemul(a01, s1));
      b1 = addp(basemul(a10, s0), basemul(a11, s1));
      t0 = addp(b0, e0);
      t1 = addp(b1, e1);

      keypair_ek = {pack12(t0), pack12(t1), rho};
    end
  endfunction

  // The ML-KEM decapsulation key is
  // Encode(s_hat) || EK || H(EK) || z, exactly as required by FIPS 203.
  function automatic logic [13055:0] keypair_dk(
    input logic [255:0] dd,
    input logic [255:0] zz,
    input logic [6399:0] pk
  );
    logic [511:0] g;
    logic [3071:0] s0;
    logic [3071:0] s1;
    begin
      g = sha3_512({dd, 8'h02}, 33);
      s0 = ntt(noise(g[255:0], 3, 0));
      s1 = ntt(noise(g[255:0], 3, 1));
      keypair_dk = {pack12(s0), pack12(s1), pk, sha3_256(pk, 800), zz};
    end
  endfunction

  // PKE.Encrypt computes u = A^T*r + e1 and v = t^T*r + e2 + Encode(m),
  // then compresses and packs the 768-byte ciphertext.
  function automatic logic [6143:0] encrypt_pke(
    input logic [6399:0] pk,
    input logic [255:0] mm,
    input logic [255:0] coins
  );
    logic [255:0] rho;
    logic [3071:0] t0;
    logic [3071:0] t1;
    logic [3071:0] a00;
    logic [3071:0] a01;
    logic [3071:0] a10;
    logic [3071:0] a11;
    logic [3071:0] r0;
    logic [3071:0] r1;
    logic [3071:0] e0;
    logic [3071:0] e1;
    logic [3071:0] e2;
    logic [3071:0] u0;
    logic [3071:0] u1;
    logic [3071:0] v;
    begin
      rho = pk[255:0];
      t0 = unpack12(pk[6399:3328]);
      t1 = unpack12(pk[3327:256]);

      a00 = matrix_poly(rho, 0, 0);
      a01 = matrix_poly(rho, 0, 1);
      a10 = matrix_poly(rho, 1, 0);
      a11 = matrix_poly(rho, 1, 1);
      r0 = ntt(noise(coins, 3, 0));
      r1 = ntt(noise(coins, 3, 1));
      e0 = noise(coins, 2, 2);
      e1 = noise(coins, 2, 3);
      e2 = noise(coins, 2, 4);

      u0 = addp(
        intt(addp(basemul(a00, r0), basemul(a10, r1))),
        e0
      );
      u1 = addp(
        intt(addp(basemul(a01, r0), basemul(a11, r1))),
        e1
      );
      v = addp(
        intt(addp(basemul(t0, r0), basemul(t1, r1))),
        addp(e2, encode_msg(mm))
      );

      encrypt_pke = {
        pack10(compress(u0, 10)),
        pack10(compress(u1, 10)),
        pack4(compress(v, 4))
      };
    end
  endfunction

  // PKE.Decrypt recovers the message polynomial as v - s^T*u and maps each
  // coefficient back to one message bit.
  function automatic logic [255:0] decrypt_pke(
    input logic [6143:0] c,
    input logic [13055:0] sk
  );
    logic [3071:0] s0;
    logic [3071:0] s1;
    logic [3071:0] u0;
    logic [3071:0] u1;
    logic [3071:0] v;
    logic [3071:0] w;
    begin
      s0 = unpack12(sk[13055:9984]);
      s1 = unpack12(sk[9983:6912]);
      u0 = decompress(unpack10(c[6143:3584]), 10);
      u1 = decompress(unpack10(c[3583:1024]), 10);
      v = decompress(unpack4(c[1023:0]), 4);
      w = intt(addp(basemul(s0, ntt(u0)), basemul(s1, ntt(u1))));
      decrypt_pke = decode_msg(subp(v, w));
    end
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    logic [511:0] g;
    logic [6399:0] pk;
    logic [6143:0] cc;
    logic [255:0] h;
    logic [255:0] kh;
    logic [255:0] kb;
    logic [255:0] mm;
    logic ok;
    integer i;

    if (!rst_n) begin
      state  <= IDLE;
      busy   <= 1'b0;
      valid  <= 1'b0;
      status <= 8'h00;
      ek_out <= '0;
      dk_out <= '0;
      ct_out <= '0;
      ss_out <= '0;
      op_r <= '0;
      d_r <= '0;
      z_r <= '0;
      m_r <= '0;
      ek_r <= '0;
      dk_r <= '0;
      ct_r <= '0;
    end else begin
      valid <= 1'b0;

      case (state)
        // A valid command is acknowledged by busy=1 and remains active until DONE.
        IDLE: begin
          busy <= 1'b0;
          if (start) begin
            if (op == 2'b11) begin
              busy   <= 1'b0;
              valid  <= 1'b1;
              status <= 8'hF1;
            end else begin
              busy <= 1'b1;
              op_r <= op;
              d_r <= d;
              z_r <= z;
              m_r <= m;
              ek_r <= ek;
              dk_r <= dk;
              ct_r <= ct_in;
              status <= 8'h80;
              state <= ACQUIRE;
            end
          end
        end

        // Validate key-shaped inputs before performing an operation.
        ACQUIRE: begin
          if (((op_r == 2'b01) && !ek_valid(ek_r)) ||
              ((op_r == 2'b10) && !dk_valid(dk_r))) begin
            busy   <= 1'b0;
            valid  <= 1'b1;
            status <= 8'hE1;
            state  <= IDLE;
          end else begin
            state <= RUN_HASH;
          end
        end

        // These states reserve control phases for eventual iterative hash and
        // polynomial hardware. Today the verified package functions run below.
        RUN_HASH: begin
          state <= RUN_POLY;
        end

        RUN_POLY: begin
          state <= COMPUTE;
        end

        // KEM.KeyGen uses d as the deterministic key seed and stores z in DK.
        // KEM.Encaps derives (Kbar, coins) with G(m || H(EK)).
        // KEM.Decaps re-encrypts and selects Kbar or SHAKE256(z || c).
        COMPUTE: begin
          if (op_r == 2'b00) begin
            pk = keypair_ek(d_r);
            ek_out <= pk;
            dk_out <= keypair_dk(d_r, z_r, pk);
            status <= 8'h10;
          end else if (op_r == 2'b01) begin
            h = sha3_256(ek_r, 800);
            g = sha3_512({m_r, h}, 64);
            cc = encrypt_pke(ek_r, m_r, g[255:0]);
            ct_out <= cc;
            ss_out <= g[511:256];
            status <= 8'h20;
          end else begin
            pk = dk_r[6911:512];
            h = dk_r[511:256];
            mm = decrypt_pke(ct_r, dk_r);
            g = sha3_512({mm, h}, 64);
            cc = encrypt_pke(pk, mm, g[255:0]);
            ok = 1'b1;
            for (i = 0; i < 768; i = i + 1)
              ok = ok && (cc[i*8 +: 8] === ct_r[i*8 +: 8]);
            kh = g[511:256];
            kb = shake256_32({dk_r[255:0], ct_r}, 800);
            for (i = 0; i < 32; i = i + 1)
              ss_out[i*8 +: 8] <= ok ? kh[i*8 +: 8] : kb[i*8 +: 8];
            status <= ok ? 8'h30 : 8'h34;
          end
          state <= DONE;
        end

        // valid is pulsed for one cycle after computation and busy is cleared.
        DONE: begin
          busy  <= 1'b0;
          valid <= 1'b1;
          state <= IDLE;
        end

        default: begin
          busy   <= 1'b0;
          valid  <= 1'b1;
          status <= 8'hFE;
          state  <= IDLE;
        end
      endcase

      if (start && busy && state != IDLE) begin
        busy   <= 1'b1;
        valid  <= 1'b1;
        status <= 8'hF2;
      end
    end
  end
endmodule
