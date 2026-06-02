import random

_RNG = random.Random(0xDEADBEEF_42424242)

# 90 squares × 15 piece slots (piece codes -7..7, offset +7 → indices 0..14)
PIECE_OFFSET = 7
N_PIECES = 15
N_SQUARES = 90

TABLE: list[list[int]] = [
    [_RNG.getrandbits(64) for _ in range(N_PIECES)]
    for _ in range(N_SQUARES)
]
