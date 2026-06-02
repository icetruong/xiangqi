from typing import Tuple, Optional
from engine.board import Board, EMPTY, rR, rC, rN, rP, bR, bC, bN, bP

# ── Reverse-knight table ────────────────────────────────────────────────────
# A knight at (kr+ndr, kc+ndc) attacks king at (kr,kc)
# if the blocking square (kr+bdr, kc+bdc) is empty.
_KN_REVERSE = (
    (-2, -1, -1, -1), (-2,  1, -1,  1),
    ( 2, -1,  1, -1), ( 2,  1,  1,  1),
    (-1, -2, -1, -1), (-1,  2, -1,  1),
    ( 1, -2,  1, -1), ( 1,  2,  1,  1),
)


def is_in_check(board: Board, color: str) -> bool:
    """
    Fast check detection via reverse-attack from the king's position.
    Scans outward in 4 directions for Rook/Cannon, checks 8 knight squares,
    and checks 3 pawn squares — far fewer operations than iterating all 90 cells.
    """
    king_idx = board.red_king if color == "r" else board.black_king
    if king_idx is None:
        return False

    kr = king_idx // 9
    kc = king_idx % 9
    b = board.board

    if color == "r":
        eR, eC, eN, eP = bR, bC, bN, bP   # -5, -6, -4, -7
    else:
        eR, eC, eN, eP = rR, rC, rN, rP   #  5,  6,  4,  7

    # ── Rook & Cannon: 4 orthogonal rays ─────────────────────────────────
    for dr, dc in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        r, c = kr + dr, kc + dc
        screen = False
        while 0 <= r < 10 and 0 <= c < 9:
            p = b[r * 9 + c]
            if p != EMPTY:
                if not screen:
                    if p == eR:
                        return True     # rook with clear line of sight
                    screen = True       # first piece = cannon screen
                else:
                    if p == eC:
                        return True     # cannon behind one screen
                    break               # second blocker ends the ray
            r += dr
            c += dc

    # ── Knight: 8 reverse positions ──────────────────────────────────────
    for ndr, ndc, bdr, bdc in _KN_REVERSE:
        nr, nc = kr + ndr, kc + ndc
        if 0 <= nr < 10 and 0 <= nc < 9 and b[nr * 9 + nc] == eN:
            br_, bc_ = kr + bdr, kc + bdc
            if 0 <= br_ < 10 and 0 <= bc_ < 9 and b[br_ * 9 + bc_] == EMPTY:
                return True

    # ── Pawn: 3 adjacent squares ─────────────────────────────────────────
    # Kings are always inside their palace, so pawns that can attack are
    # guaranteed to be past the river — no extra row-range check needed.
    if color == "r":  # black pawns attack red king
        for pr, pc in ((kr - 1, kc), (kr, kc - 1), (kr, kc + 1)):
            if 0 <= pr < 10 and 0 <= pc < 9 and b[pr * 9 + pc] == eP:
                return True
    else:             # red pawns attack black king
        for pr, pc in ((kr + 1, kc), (kr, kc - 1), (kr, kc + 1)):
            if 0 <= pr < 10 and 0 <= pc < 9 and b[pr * 9 + pc] == eP:
                return True

    return False


# ── Legacy helpers kept for backward compatibility ──────────────────────────

def find_king(board: Board, color: str) -> Optional[Tuple[int, int]]:
    idx = board.red_king if color == "r" else board.black_king
    return board.row_col(idx) if idx is not None else None


def rook_attacks(board: Board, src: Tuple[int, int], dst: Tuple[int, int]) -> bool:
    sr, sc = src
    kr, kc = dst
    if sr != kr and sc != kc:
        return False
    if sr == kr:
        step = 1 if sc < kc else -1
        for cc in range(sc + step, kc, step):
            if not (board.board[sr * 9 + cc] == EMPTY):
                return False
    else:
        step = 1 if sr < kr else -1
        for rr in range(sr + step, kr, step):
            if not (board.board[rr * 9 + sc] == EMPTY):
                return False
    return True


def cannon_attacks(board: Board, src: Tuple[int, int], dst: Tuple[int, int]) -> bool:
    sr, sc = src
    kr, kc = dst
    if sr != kr and sc != kc:
        return False
    count = 0
    if sr == kr:
        step = 1 if sc < kc else -1
        for cc in range(sc + step, kc, step):
            if board.board[sr * 9 + cc] != EMPTY:
                count += 1
    else:
        step = 1 if sr < kr else -1
        for rr in range(sr + step, kr, step):
            if board.board[rr * 9 + sc] != EMPTY:
                count += 1
    return count == 1


def knight_attacks(board: Board, src: Tuple[int, int], dst: Tuple[int, int]) -> bool:
    sr, sc = src
    kr, kc = dst
    for dr, dc in ((-2, -1), (-2, 1), (-1, -2), (-1, 2), (1, -2), (1, 2), (2, 1), (2, -1)):
        nr, nc = sr + dr, sc + dc
        obstacle_r, obstacle_c = sr, sc
        if abs(dr) == 2:
            obstacle_r = sr + dr // 2
        elif abs(dc) == 2:
            obstacle_c = sc + dc // 2
        if (nr, nc) == dst:
            return board.board[obstacle_r * 9 + obstacle_c] == EMPTY
    return False


def pawn_attacks(board: Board, src: Tuple[int, int], dst: Tuple[int, int]) -> bool:
    sr, sc = src
    kr, kc = dst
    piece = board.board[sr * 9 + sc]
    from engine.utils.position import color_of
    c = color_of(piece)
    if c is None:
        return False
    if c == "b":
        if sr <= 4:
            return False
        return (sr == kr and abs(sc - kc) == 1) or (kr - sr == 1 and sc == kc)
    else:  # c == "r"
        if sr >= 5:
            return False
        return (sr == kr and abs(sc - kc) == 1) or (sr - kr == 1 and sc == kc)


def attacks_square(board: Board, src: Tuple[int, int], dst: Tuple[int, int]) -> bool:
    sr, sc = src
    piece = board.board[sr * 9 + sc]
    if piece == EMPTY:
        return False
    from engine.utils.position import type_of
    t = type_of(piece)
    if t == "R":
        return rook_attacks(board, src, dst)
    if t == "C":
        return cannon_attacks(board, src, dst)
    if t == "P":
        return pawn_attacks(board, src, dst)
    if t == "N":
        return knight_attacks(board, src, dst)
    return False
