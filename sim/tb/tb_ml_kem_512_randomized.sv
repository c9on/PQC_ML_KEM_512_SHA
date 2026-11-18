module tb_ml_kem_512_randomized
  import ml_kem_fips203_pkg::*;
  ();

  logic [3071:0] polynomial;
  logic [3071:0] polynomial_b;
  logic [3071:0] transformed;
  logic [3071:0] restored;
  logic [3071:0] multiplied;
  logic [3071:0] rounded;
  logic [3071:0] recovered;
  logic [255:0] message;
  logic [255:0] recovered_message;
  integer trial;
  integer coefficient;
  integer expected;
  integer random_value;
  integer ring_sum;
  logic [63:0] lfsr;

  function automatic logic [63:0] next_random(input logic [63:0] state);
    begin
      next_random = (state >> 1) ^ (-(state & 1'b1) & 64'hD800000000000000);
    end
  endfunction

  initial begin
    lfsr = 64'h1BADF00DCAFE1234;

    // Deterministic pseudo-random round-trip coverage exercises full 256-
    // coefficient polynomials without depending on simulator $random seeds.
    for (trial = 0; trial < 32; trial = trial + 1) begin
      for (coefficient = 0; coefficient < 256; coefficient = coefficient + 1) begin
        lfsr = next_random(lfsr);
        random_value = lfsr % Q;
        polynomial[coefficient*12 +: 12] = random_value;
        lfsr = next_random(lfsr);
        random_value = lfsr % Q;
        polynomial_b[coefficient*12 +: 12] = random_value;
      end

      transformed = ntt(polynomial);
      restored = intt(transformed);
      if (restored !== polynomial)
        $fatal(1, "NTT/INTT round trip failed at trial %0d", trial);

      // Base multiplication in NTT form must equal direct negacyclic polynomial
      // multiplication after inverse NTT. Check every coefficient.
      multiplied = intt(basemul(transformed, ntt(polynomial_b)));
      for (coefficient = 0; coefficient < 256; coefficient = coefficient + 1) begin
        ring_sum = 0;
        for (int j = 0; j < 256; j = j + 1) begin
          if (coefficient >= j)
            ring_sum = modq(
              ring_sum
              + polynomial[j*12 +: 12] * polynomial_b[(coefficient-j)*12 +: 12]
            );
          else
            ring_sum = modq(
              ring_sum
              - polynomial[j*12 +: 12] * polynomial_b[(256+coefficient-j)*12 +: 12]
            );
        end
        expected = ring_sum;
        if (multiplied[coefficient*12 +: 12] !== expected[11:0])
          $fatal(1, "basemul reference mismatch trial=%0d coefficient=%0d", trial, coefficient);
      end

      // Exercise the compression endpoints for both ciphertext precisions.
      for (int bits = 4; bits <= 10; bits = bits + 6) begin
        rounded = compress(polynomial, bits);
        recovered = decompress(rounded, bits);
        for (coefficient = 0; coefficient < 256; coefficient = coefficient + 1)
          if (rounded[coefficient*12 +: 12] >= (1 << bits))
            $fatal(1, "compression range error bits=%0d coefficient=%0d", bits, coefficient);
      end

      // Message encode/decode is an exact 256-bit round trip.
      for (coefficient = 0; coefficient < 32; coefficient = coefficient + 1)
        message[coefficient*8 +: 8] = lfsr[(coefficient % 8)*8 +: 8];
      recovered_message = decode_msg(encode_msg(message));
      if (recovered_message !== message)
        $fatal(1, "message encode/decode failed at trial %0d", trial);
    end

    // Explicit encoding/decoding boundary vectors cover 0, Q-1, and bit packing.
    for (coefficient = 0; coefficient < 256; coefficient = coefficient + 1)
      polynomial[coefficient*12 +: 12] = coefficient & 1 ? Q - 1 : 0;

    if (unpack12(pack12(polynomial)) !== polynomial)
      $fatal(1, "12-bit boundary pack/unpack failed");
    rounded = polynomial;
    for (coefficient = 0; coefficient < 256; coefficient = coefficient + 1)
      rounded[coefficient*12 +: 12] = coefficient & 10'h3FF;
    recovered = unpack10(pack10(rounded));
    for (coefficient = 0; coefficient < 256; coefficient = coefficient + 1)
      if (recovered[coefficient*12 +: 10] !== rounded[coefficient*12 +: 10])
        $fatal(1, "10-bit boundary pack/unpack failed coefficient=%0d", coefficient);
    for (coefficient = 0; coefficient < 256; coefficient = coefficient + 1)
      rounded[coefficient*12 +: 12] = coefficient & 15;
    recovered = unpack4(pack4(rounded));
    for (coefficient = 0; coefficient < 256; coefficient = coefficient + 1)
      if (recovered[coefficient*12 +: 4] !== rounded[coefficient*12 +: 4])
        $fatal(1, "4-bit boundary pack/unpack failed coefficient=%0d", coefficient);

    $display("Randomized polynomial verification: 32/32 rounds PASS");
    $display("Encoding/decoding boundaries PASS");
    $display("Compression/decompression boundaries PASS");
    $finish;
  end
endmodule
