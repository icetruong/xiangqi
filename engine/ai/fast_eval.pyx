# cython: boundscheck=False, wraparound=False, cdivision=True, language_level=3
"""
Cython-optimized board evaluator for Xiangqi.

Piece encoding:
  rK=1 rA=2 rE=3 rN=4 rR=5 rC=6 rP=7
  bK=-1 bA=-2 bE=-3 bN=-4 bR=-5 bC=-6 bP=-7
  EMPTY=0

PST ptype index = abs(piece) - 1  →  0=K 1=A 2=E 3=N 4=R 5=C 6=P
Piece value index = abs(piece)    →  0=empty 1=K 2=A 3=E 4=N 5=R 6=C 7=P
"""

# Piece values indexed by abs(piece_code)
cdef int PIECE_VAL[8]
PIECE_VAL[:] = [0, 100000, 250, 250, 350, 600, 450, 100]

# PST for RED (ptype 0-6, square 0-89).  Zeroed at module load; filled by _init_pst().
cdef int PST_RED[7][90]
cdef int PST_BLACK[7][90]


def _init_pst():
    """Fill PST_RED and PST_BLACK from engine.ai.pst Python tables."""
    from engine.ai.pst import PAWN_RED, KNIGHT_RED, ROOK_RED, CANNON_RED, KING_RED

    # ptype → source table (None = zeroed, already zero-initialized)
    tables = [KING_RED, None, None, KNIGHT_RED, ROOK_RED, CANNON_RED, PAWN_RED]

    cdef int ptype, r, c, sq, mirror_sq, val
    for ptype in range(7):
        table = tables[ptype]
        for r in range(10):
            for c in range(9):
                sq = r * 9 + c
                mirror_sq = (9 - r) * 9 + c
                val = table[r][c] if table is not None else 0
                PST_RED[ptype][sq] = val
                PST_BLACK[ptype][mirror_sq] = val


_init_pst()


def evaluate_board_cy(list board_arr, int perspective) -> int:
    """
    Evaluate board from a given side's perspective.

    perspective: +1 = evaluate for red, -1 = evaluate for black
    """
    cdef int score = 0
    cdef int i, piece, apiece, ptype, piece_sign, val

    for i in range(90):
        piece = board_arr[i]
        if piece == 0:
            continue

        if piece > 0:
            apiece = piece
            piece_sign = perspective
            val = PIECE_VAL[apiece] + PST_RED[apiece - 1][i]
        else:
            apiece = -piece
            piece_sign = -perspective
            val = PIECE_VAL[apiece] + PST_BLACK[apiece - 1][i]

        score += piece_sign * val

    return score
