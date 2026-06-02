# cython: boundscheck=False, wraparound=False, cdivision=True, language_level=3
"""
Cython-accelerated legal move generator for Xiangqi.

Piece encoding (matches board.py):
  rK=1 rA=2 rE=3 rN=4 rR=5 rC=6 rP=7
  bK=-1 bA=-2 bE=-3 bN=-4 bR=-5 bC=-6 bP=-7  EMPTY=0
"""

DEF ROWS = 10
DEF COLS = 9
DEF EMPTY = 0
DEF rK = 1
DEF rA = 2
DEF rE = 3
DEF rN = 4
DEF rR = 5
DEF rC = 6
DEF rP = 7
DEF bK = -1
DEF bA = -2
DEF bE = -3
DEF bN = -4
DEF bR = -5
DEF bC = -6
DEF bP = -7
DEF MAX_PSEUDO = 320


# ── Helper: append one pseudo-legal move ─────────────────────────────────────
cdef inline void _add(int* mv, int* n, int sr, int sc, int dr, int dc) noexcept nogil:
    cdef int base = n[0] * 4
    mv[base]   = sr
    mv[base+1] = sc
    mv[base+2] = dr
    mv[base+3] = dc
    n[0] += 1

cdef inline bint _enemy(int piece, int color) noexcept nogil:
    return (piece > 0) != (color > 0)


# ── Check detection (reverse-attack from king) ────────────────────────────────
cdef bint _in_check(int* b, int kr, int kc,
                    int eR, int eC, int eN, int eP) noexcept nogil:
    cdef int r, c, p
    cdef bint screen
    cdef int nr, nc, br_r, br_c

    # up
    r = kr - 1
    screen = False
    while r >= 0:
        p = b[r * COLS + kc]
        if p:
            if not screen:
                if p == eR:
                    return True
                screen = True
            else:
                if p == eC:
                    return True
                break
        r -= 1
    # down
    r = kr + 1
    screen = False
    while r < ROWS:
        p = b[r * COLS + kc]
        if p:
            if not screen:
                if p == eR:
                    return True
                screen = True
            else:
                if p == eC:
                    return True
                break
        r += 1
    # left
    c = kc - 1
    screen = False
    while c >= 0:
        p = b[kr * COLS + c]
        if p:
            if not screen:
                if p == eR:
                    return True
                screen = True
            else:
                if p == eC:
                    return True
                break
        c -= 1
    # right
    c = kc + 1
    screen = False
    while c < COLS:
        p = b[kr * COLS + c]
        if p:
            if not screen:
                if p == eR:
                    return True
                screen = True
            else:
                if p == eC:
                    return True
                break
        c += 1

    # Knight — 8 reverse positions (unrolled)
    # (-2,-1) block(-1,-1)
    nr = kr - 2
    nc = kc - 1
    if nr >= 0 and nc >= 0 and b[nr * COLS + nc] == eN:
        if b[(kr - 1) * COLS + (kc - 1)] == EMPTY:
            return True
    # (-2,+1) block(-1,+1)
    nr = kr - 2
    nc = kc + 1
    if nr >= 0 and nc < COLS and b[nr * COLS + nc] == eN:
        if b[(kr - 1) * COLS + (kc + 1)] == EMPTY:
            return True
    # (+2,-1) block(+1,-1)
    nr = kr + 2
    nc = kc - 1
    if nr < ROWS and nc >= 0 and b[nr * COLS + nc] == eN:
        if b[(kr + 1) * COLS + (kc - 1)] == EMPTY:
            return True
    # (+2,+1) block(+1,+1)
    nr = kr + 2
    nc = kc + 1
    if nr < ROWS and nc < COLS and b[nr * COLS + nc] == eN:
        if b[(kr + 1) * COLS + (kc + 1)] == EMPTY:
            return True
    # (-1,-2) block(-1,-1)
    nr = kr - 1
    nc = kc - 2
    if nr >= 0 and nc >= 0 and b[nr * COLS + nc] == eN:
        if b[(kr - 1) * COLS + (kc - 1)] == EMPTY:
            return True
    # (-1,+2) block(-1,+1)
    nr = kr - 1
    nc = kc + 2
    if nr >= 0 and nc < COLS and b[nr * COLS + nc] == eN:
        if b[(kr - 1) * COLS + (kc + 1)] == EMPTY:
            return True
    # (+1,-2) block(+1,-1)
    nr = kr + 1
    nc = kc - 2
    if nr < ROWS and nc >= 0 and b[nr * COLS + nc] == eN:
        if b[(kr + 1) * COLS + (kc - 1)] == EMPTY:
            return True
    # (+1,+2) block(+1,+1)
    nr = kr + 1
    nc = kc + 2
    if nr < ROWS and nc < COLS and b[nr * COLS + nc] == eN:
        if b[(kr + 1) * COLS + (kc + 1)] == EMPTY:
            return True

    # Pawn
    if eP == bP:   # red king attacked by black pawns
        if kr > 0 and b[(kr - 1) * COLS + kc] == eP:
            return True
        if kc > 0 and b[kr * COLS + kc - 1] == eP:
            return True
        if kc < COLS - 1 and b[kr * COLS + kc + 1] == eP:
            return True
    else:          # black king attacked by red pawns
        if kr < ROWS - 1 and b[(kr + 1) * COLS + kc] == eP:
            return True
        if kc > 0 and b[kr * COLS + kc - 1] == eP:
            return True
        if kc < COLS - 1 and b[kr * COLS + kc + 1] == eP:
            return True

    return False


cdef bint _kings_face(int* b, int rk_r, int rk_c,
                      int bk_r, int bk_c) noexcept nogil:
    cdef int r
    if rk_c != bk_c:
        return False
    for r in range(bk_r + 1, rk_r):
        if b[r * COLS + rk_c]:
            return False
    return True


# ── Piece move generators ─────────────────────────────────────────────────────
cdef void _rook(int* b, int sr, int sc, int color,
                int* mv, int* n) noexcept nogil:
    cdef int r, c, p
    r = sr - 1
    while r >= 0:
        p = b[r * COLS + sc]
        if p == EMPTY:
            _add(mv, n, sr, sc, r, sc)
        elif _enemy(p, color):
            _add(mv, n, sr, sc, r, sc)
            break
        else:
            break
        r -= 1
    r = sr + 1
    while r < ROWS:
        p = b[r * COLS + sc]
        if p == EMPTY:
            _add(mv, n, sr, sc, r, sc)
        elif _enemy(p, color):
            _add(mv, n, sr, sc, r, sc)
            break
        else:
            break
        r += 1
    c = sc - 1
    while c >= 0:
        p = b[sr * COLS + c]
        if p == EMPTY:
            _add(mv, n, sr, sc, sr, c)
        elif _enemy(p, color):
            _add(mv, n, sr, sc, sr, c)
            break
        else:
            break
        c -= 1
    c = sc + 1
    while c < COLS:
        p = b[sr * COLS + c]
        if p == EMPTY:
            _add(mv, n, sr, sc, sr, c)
        elif _enemy(p, color):
            _add(mv, n, sr, sc, sr, c)
            break
        else:
            break
        c += 1


cdef void _cannon(int* b, int sr, int sc, int color,
                  int* mv, int* n) noexcept nogil:
    cdef int r, c, p
    cdef bint screen
    r = sr - 1
    screen = False
    while r >= 0:
        p = b[r * COLS + sc]
        if p == EMPTY:
            if not screen:
                _add(mv, n, sr, sc, r, sc)
        else:
            if not screen:
                screen = True
            else:
                if _enemy(p, color):
                    _add(mv, n, sr, sc, r, sc)
                break
        r -= 1
    r = sr + 1
    screen = False
    while r < ROWS:
        p = b[r * COLS + sc]
        if p == EMPTY:
            if not screen:
                _add(mv, n, sr, sc, r, sc)
        else:
            if not screen:
                screen = True
            else:
                if _enemy(p, color):
                    _add(mv, n, sr, sc, r, sc)
                break
        r += 1
    c = sc - 1
    screen = False
    while c >= 0:
        p = b[sr * COLS + c]
        if p == EMPTY:
            if not screen:
                _add(mv, n, sr, sc, sr, c)
        else:
            if not screen:
                screen = True
            else:
                if _enemy(p, color):
                    _add(mv, n, sr, sc, sr, c)
                break
        c -= 1
    c = sc + 1
    screen = False
    while c < COLS:
        p = b[sr * COLS + c]
        if p == EMPTY:
            if not screen:
                _add(mv, n, sr, sc, sr, c)
        else:
            if not screen:
                screen = True
            else:
                if _enemy(p, color):
                    _add(mv, n, sr, sc, sr, c)
                break
        c += 1


cdef void _knight(int* b, int sr, int sc, int color,
                  int* mv, int* n) noexcept nogil:
    cdef int p
    # (-2,-1) obs=(-1,0)
    if sr >= 2 and sc >= 1 and b[(sr - 1) * COLS + sc] == EMPTY:
        p = b[(sr - 2) * COLS + sc - 1]
        if p == EMPTY or _enemy(p, color):
            _add(mv, n, sr, sc, sr - 2, sc - 1)
    # (-2,+1) obs=(-1,0)
    if sr >= 2 and sc < COLS - 1 and b[(sr - 1) * COLS + sc] == EMPTY:
        p = b[(sr - 2) * COLS + sc + 1]
        if p == EMPTY or _enemy(p, color):
            _add(mv, n, sr, sc, sr - 2, sc + 1)
    # (+2,-1) obs=(+1,0)
    if sr < ROWS - 2 and sc >= 1 and b[(sr + 1) * COLS + sc] == EMPTY:
        p = b[(sr + 2) * COLS + sc - 1]
        if p == EMPTY or _enemy(p, color):
            _add(mv, n, sr, sc, sr + 2, sc - 1)
    # (+2,+1) obs=(+1,0)
    if sr < ROWS - 2 and sc < COLS - 1 and b[(sr + 1) * COLS + sc] == EMPTY:
        p = b[(sr + 2) * COLS + sc + 1]
        if p == EMPTY or _enemy(p, color):
            _add(mv, n, sr, sc, sr + 2, sc + 1)
    # (-1,-2) obs=(0,-1)
    if sr >= 1 and sc >= 2 and b[sr * COLS + sc - 1] == EMPTY:
        p = b[(sr - 1) * COLS + sc - 2]
        if p == EMPTY or _enemy(p, color):
            _add(mv, n, sr, sc, sr - 1, sc - 2)
    # (-1,+2) obs=(0,+1)
    if sr >= 1 and sc < COLS - 2 and b[sr * COLS + sc + 1] == EMPTY:
        p = b[(sr - 1) * COLS + sc + 2]
        if p == EMPTY or _enemy(p, color):
            _add(mv, n, sr, sc, sr - 1, sc + 2)
    # (+1,-2) obs=(0,-1)
    if sr < ROWS - 1 and sc >= 2 and b[sr * COLS + sc - 1] == EMPTY:
        p = b[(sr + 1) * COLS + sc - 2]
        if p == EMPTY or _enemy(p, color):
            _add(mv, n, sr, sc, sr + 1, sc - 2)
    # (+1,+2) obs=(0,+1)
    if sr < ROWS - 1 and sc < COLS - 2 and b[sr * COLS + sc + 1] == EMPTY:
        p = b[(sr + 1) * COLS + sc + 2]
        if p == EMPTY or _enemy(p, color):
            _add(mv, n, sr, sc, sr + 1, sc + 2)


cdef void _elephant(int* b, int sr, int sc, int color,
                    int* mv, int* n) noexcept nogil:
    cdef int nr, nc, p
    # (-2,-2) obs=(-1,-1)
    if sr >= 2 and sc >= 2:
        nr = sr - 2
        nc = sc - 2
        if (color > 0 and nr >= 5) or (color < 0 and nr <= 4):
            if b[(sr - 1) * COLS + sc - 1] == EMPTY:
                p = b[nr * COLS + nc]
                if p == EMPTY or _enemy(p, color):
                    _add(mv, n, sr, sc, nr, nc)
    # (-2,+2) obs=(-1,+1)
    if sr >= 2 and sc <= COLS - 3:
        nr = sr - 2
        nc = sc + 2
        if (color > 0 and nr >= 5) or (color < 0 and nr <= 4):
            if b[(sr - 1) * COLS + sc + 1] == EMPTY:
                p = b[nr * COLS + nc]
                if p == EMPTY or _enemy(p, color):
                    _add(mv, n, sr, sc, nr, nc)
    # (+2,-2) obs=(+1,-1)
    if sr <= ROWS - 3 and sc >= 2:
        nr = sr + 2
        nc = sc - 2
        if (color > 0 and nr <= 9) or (color < 0 and nr <= 4):
            if b[(sr + 1) * COLS + sc - 1] == EMPTY:
                p = b[nr * COLS + nc]
                if p == EMPTY or _enemy(p, color):
                    _add(mv, n, sr, sc, nr, nc)
    # (+2,+2) obs=(+1,+1)
    if sr <= ROWS - 3 and sc <= COLS - 3:
        nr = sr + 2
        nc = sc + 2
        if (color > 0 and nr <= 9) or (color < 0 and nr <= 4):
            if b[(sr + 1) * COLS + sc + 1] == EMPTY:
                p = b[nr * COLS + nc]
                if p == EMPTY or _enemy(p, color):
                    _add(mv, n, sr, sc, nr, nc)


cdef void _advisor(int* b, int sr, int sc, int color,
                   int* mv, int* n) noexcept nogil:
    cdef int nr, nc, p
    # (-1,-1)
    nr = sr - 1
    nc = sc - 1
    if nc >= 3 and nc <= 5:
        if (color > 0 and nr >= 7 and nr <= 9) or (color < 0 and nr >= 0 and nr <= 2):
            p = b[nr * COLS + nc]
            if p == EMPTY or _enemy(p, color):
                _add(mv, n, sr, sc, nr, nc)
    # (-1,+1)
    nr = sr - 1
    nc = sc + 1
    if nc >= 3 and nc <= 5:
        if (color > 0 and nr >= 7 and nr <= 9) or (color < 0 and nr >= 0 and nr <= 2):
            p = b[nr * COLS + nc]
            if p == EMPTY or _enemy(p, color):
                _add(mv, n, sr, sc, nr, nc)
    # (+1,-1)
    nr = sr + 1
    nc = sc - 1
    if nc >= 3 and nc <= 5:
        if (color > 0 and nr >= 7 and nr <= 9) or (color < 0 and nr >= 0 and nr <= 2):
            p = b[nr * COLS + nc]
            if p == EMPTY or _enemy(p, color):
                _add(mv, n, sr, sc, nr, nc)
    # (+1,+1)
    nr = sr + 1
    nc = sc + 1
    if nc >= 3 and nc <= 5:
        if (color > 0 and nr >= 7 and nr <= 9) or (color < 0 and nr >= 0 and nr <= 2):
            p = b[nr * COLS + nc]
            if p == EMPTY or _enemy(p, color):
                _add(mv, n, sr, sc, nr, nc)


cdef void _king_piece(int* b, int sr, int sc, int color,
                      int* mv, int* n) noexcept nogil:
    cdef int nr, nc, p
    # up
    nr = sr - 1
    if sc >= 3 and sc <= 5:
        if (color > 0 and nr >= 7 and nr <= 9) or (color < 0 and nr >= 0 and nr <= 2):
            p = b[nr * COLS + sc]
            if p == EMPTY or _enemy(p, color):
                _add(mv, n, sr, sc, nr, sc)
    # down
    nr = sr + 1
    if sc >= 3 and sc <= 5:
        if (color > 0 and nr >= 7 and nr <= 9) or (color < 0 and nr >= 0 and nr <= 2):
            p = b[nr * COLS + sc]
            if p == EMPTY or _enemy(p, color):
                _add(mv, n, sr, sc, nr, sc)
    # left
    nc = sc - 1
    if nc >= 3 and nc <= 5:
        if (color > 0 and sr >= 7 and sr <= 9) or (color < 0 and sr >= 0 and sr <= 2):
            p = b[sr * COLS + nc]
            if p == EMPTY or _enemy(p, color):
                _add(mv, n, sr, sc, sr, nc)
    # right
    nc = sc + 1
    if nc >= 3 and nc <= 5:
        if (color > 0 and sr >= 7 and sr <= 9) or (color < 0 and sr >= 0 and sr <= 2):
            p = b[sr * COLS + nc]
            if p == EMPTY or _enemy(p, color):
                _add(mv, n, sr, sc, sr, nc)


cdef void _pawn(int* b, int sr, int sc, int color,
                int* mv, int* n) noexcept nogil:
    cdef int p
    if color > 0:   # red: moves upward
        if sr > 0:
            p = b[(sr - 1) * COLS + sc]
            if p == EMPTY or p < 0:
                _add(mv, n, sr, sc, sr - 1, sc)
        if sr <= 4:   # past river → sideways allowed
            if sc > 0:
                p = b[sr * COLS + sc - 1]
                if p == EMPTY or p < 0:
                    _add(mv, n, sr, sc, sr, sc - 1)
            if sc < COLS - 1:
                p = b[sr * COLS + sc + 1]
                if p == EMPTY or p < 0:
                    _add(mv, n, sr, sc, sr, sc + 1)
    else:           # black: moves downward
        if sr < ROWS - 1:
            p = b[(sr + 1) * COLS + sc]
            if p == EMPTY or p > 0:
                _add(mv, n, sr, sc, sr + 1, sc)
        if sr >= 5:   # past river → sideways allowed
            if sc > 0:
                p = b[sr * COLS + sc - 1]
                if p == EMPTY or p > 0:
                    _add(mv, n, sr, sc, sr, sc - 1)
            if sc < COLS - 1:
                p = b[sr * COLS + sc + 1]
                if p == EMPTY or p > 0:
                    _add(mv, n, sr, sc, sr, sc + 1)


# ── Public entry point ────────────────────────────────────────────────────────
def cy_generate_legal_moves(list board_list, str color_str,
                             int red_king_idx, int black_king_idx):
    """
    Generate all legal moves for the given color. Drop-in replacement for
    engine.rules.game_rules.generate_legal_moves.
    Returns list of ((sr,sc),(dr,dc)) tuples.
    """
    cdef int b[90]
    cdef int i
    for i in range(90):
        b[i] = board_list[i]

    cdef int color = 1 if color_str == 'r' else -1
    cdef int eR, eC, eN, eP
    if color > 0:
        eR = bR; eC = bC; eN = bN; eP = bP
    else:
        eR = rR; eC = rC; eN = rN; eP = rP

    cdef int rk_r = red_king_idx   // 9
    cdef int rk_c = red_king_idx   % 9
    cdef int bk_r = black_king_idx // 9
    cdef int bk_c = black_king_idx % 9

    # Generate pseudo-legal moves
    cdef int pseudo[MAX_PSEUDO * 4]
    cdef int n_pseudo = 0
    cdef int piece, abs_piece, sr, sc

    for i in range(90):
        piece = b[i]
        if piece == EMPTY:
            continue
        if (piece > 0) != (color > 0):
            continue
        sr = i // 9
        sc = i % 9
        abs_piece = piece if piece > 0 else -piece
        if abs_piece == 5:
            _rook(b, sr, sc, color, pseudo, &n_pseudo)
        elif abs_piece == 6:
            _cannon(b, sr, sc, color, pseudo, &n_pseudo)
        elif abs_piece == 4:
            _knight(b, sr, sc, color, pseudo, &n_pseudo)
        elif abs_piece == 3:
            _elephant(b, sr, sc, color, pseudo, &n_pseudo)
        elif abs_piece == 2:
            _advisor(b, sr, sc, color, pseudo, &n_pseudo)
        elif abs_piece == 1:
            _king_piece(b, sr, sc, color, pseudo, &n_pseudo)
        elif abs_piece == 7:
            _pawn(b, sr, sc, color, pseudo, &n_pseudo)

    # Validate each pseudo-legal move
    cdef int m_sr, m_sc, m_dr, m_dc, src_idx, dst_idx
    cdef int moved, captured
    cdef int ok_kr, ok_kc

    legal = []

    for i in range(n_pseudo):
        m_sr = pseudo[i * 4]
        m_sc = pseudo[i * 4 + 1]
        m_dr = pseudo[i * 4 + 2]
        m_dc = pseudo[i * 4 + 3]
        src_idx = m_sr * COLS + m_sc
        dst_idx = m_dr * COLS + m_dc

        moved    = b[src_idx]
        captured = b[dst_idx]

        b[src_idx] = EMPTY
        b[dst_idx] = moved

        if color > 0:
            ok_kr = m_dr if moved == rK else rk_r
            ok_kc = m_dc if moved == rK else rk_c
            if not _kings_face(b, ok_kr, ok_kc, bk_r, bk_c):
                if not _in_check(b, ok_kr, ok_kc, bR, bC, bN, bP):
                    legal.append(((m_sr, m_sc), (m_dr, m_dc)))
        else:
            ok_kr = m_dr if moved == bK else bk_r
            ok_kc = m_dc if moved == bK else bk_c
            if not _kings_face(b, rk_r, rk_c, ok_kr, ok_kc):
                if not _in_check(b, ok_kr, ok_kc, rR, rC, rN, rP):
                    legal.append(((m_sr, m_sc), (m_dr, m_dc)))

        b[src_idx] = moved
        b[dst_idx] = captured

    return legal
