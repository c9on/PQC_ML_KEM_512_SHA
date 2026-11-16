package ml_kem_512_pkg;
  parameter int MLKEM_N = 256;
  parameter int MLKEM_Q = 3329;
  parameter int MLKEM_Q_BITS = 12;

  parameter int MLKEM_BYTES_12 = 12;
  parameter int MLKEM_BYTES_24 = 24;
  parameter int MLKEM_BYTES_32 = 32;
  parameter int MLKEM_BYTES_48 = 48;
  parameter int MLKEM_BYTES_64 = 64;
  parameter int MLKEM_BYTES_768 = 768;
  parameter int MLKEM_BYTES_800 = 800;
  parameter int MLKEM_BYTES_1632 = 1632;

  parameter int MLKEM_SEED_BYTES = 32;
  parameter int MLKEM_MSG_BYTES = 32;
  parameter int MLKEM_SS_BYTES = 32;

  typedef logic [7:0] byte_t;
  typedef logic signed [11:0] coeff_t;
  typedef logic [7:0] seed_t [0:MLKEM_SEED_BYTES-1];
  typedef logic [7:0] msg_t [0:MLKEM_MSG_BYTES-1];
  typedef logic [7:0] ss_t [0:MLKEM_SS_BYTES-1];

  typedef logic [MLKEM_BYTES_800*8-1:0] public_key_t;
  typedef logic [MLKEM_BYTES_1632*8-1:0] secret_key_t;
  typedef logic [MLKEM_BYTES_768*8-1:0] ciphertext_t;
  typedef logic [MLKEM_MSG_BYTES*8-1:0] message_words_t;
  typedef logic [MLKEM_SS_BYTES*8-1:0] shared_secret_t;
endpackage
