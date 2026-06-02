from typing import Optional, Tuple, List
from engine.move import Move
from engine.ai import zobrist

EMPTY = 0

rK, rA, rE, rN, rR, rC, rP = 1, 2, 3, 4, 5, 6, 7
bK, bA, bE, bN, bR, bC, bP = -1, -2, -3, -4, -5, -6, -7

_STR_TO_INT = {
    "rK": rK, "rA": rA, "rE": rE, "rN": rN, "rR": rR, "rC": rC, "rP": rP,
    "bK": bK, "bA": bA, "bE": bE, "bN": bN, "bR": bR, "bC": bC, "bP": bP,
    "": EMPTY, ".": EMPTY,
}


class Board:
    __slots__ = ("board", "red_king", "black_king", "zobrist_hash")

    ROWS = 10
    COLS = 9
    SIZE = 90

    def __init__(self, state: Optional[List[int]] = None):
        self.red_king: Optional[int] = None
        self.black_king: Optional[int] = None
        self.zobrist_hash: int = 0

        if state is None:
            self.board = [EMPTY] * self.SIZE
        else:
            self.board = state
            self.update_king_positions()

    def index(self, row: int, col: int) -> int:
        return row * self.COLS + col

    def row_col(self, index: int) -> Tuple[int, int]:
        return divmod(index, self.COLS)

    def get(self, row: int, col: int) -> int:
        return self.board[row * self.COLS + col]

    def set(self, row: int, col: int, value) -> None:  # type: ignore[override]
        if isinstance(value, str):
            value = _STR_TO_INT[value]
        idx = row * self.COLS + col
        previous = self.board[idx]
        self.board[idx] = value

        if previous == rK:
            self.red_king = None
        elif previous == bK:
            self.black_king = None

        if value == rK:
            self.red_king = idx
        elif value == bK:
            self.black_king = idx

    def update_king_positions(self) -> None:
        self.red_king = None
        self.black_king = None
        tbl = zobrist.TABLE
        offset = zobrist.PIECE_OFFSET
        h = 0

        for i, piece in enumerate(self.board):
            if piece == rK:
                self.red_king = i
            elif piece == bK:
                self.black_king = i
            if piece != EMPTY:
                h ^= tbl[i][piece + offset]

        self.zobrist_hash = h

    def setup_initial(self) -> None:
        self.board = [EMPTY] * self.SIZE

        # BLACK
        self.board[0:9] = [bR, bN, bE, bA, bK, bA, bE, bN, bR]
        self.board[self.index(2, 1)] = bC
        self.board[self.index(2, 7)] = bC
        for c in range(0, 9, 2):
            self.board[self.index(3, c)] = bP

        # RED
        self.board[self.index(9, 0):self.index(9, 0) + 9] = [
            rR, rN, rE, rA, rK, rA, rE, rN, rR
        ]
        self.board[self.index(7, 1)] = rC
        self.board[self.index(7, 7)] = rC
        for c in range(0, 9, 2):
            self.board[self.index(6, c)] = rP

        self.update_king_positions()

    def apply_move_idx(self, src: int, dst: int) -> Move:
        moved = self.board[src]
        captured = self.board[dst]

        # Incremental Zobrist update
        tbl = zobrist.TABLE
        offset = zobrist.PIECE_OFFSET
        h = self.zobrist_hash
        h ^= tbl[src][moved + offset]          # remove piece from src
        if captured != EMPTY:
            h ^= tbl[dst][captured + offset]   # remove captured piece
        h ^= tbl[dst][moved + offset]           # place piece at dst
        self.zobrist_hash = h

        self.board[src] = EMPTY
        self.board[dst] = moved

        if moved == rK:
            self.red_king = dst
        elif moved == bK:
            self.black_king = dst

        return Move(src=src, dst=dst, moved=moved, captured=captured)

    def undo_move_idx(self, move: Move) -> None:
        src = move.src
        dst = move.dst

        # Undo Zobrist update (same XOR operations — XOR is self-inverse)
        tbl = zobrist.TABLE
        offset = zobrist.PIECE_OFFSET
        h = self.zobrist_hash
        h ^= tbl[dst][move.moved + offset]          # remove piece from dst
        if move.captured != EMPTY:
            h ^= tbl[dst][move.captured + offset]   # restore captured piece
        h ^= tbl[src][move.moved + offset]           # restore piece at src
        self.zobrist_hash = h

        self.board[src] = move.moved
        self.board[dst] = move.captured

        if move.moved == rK:
            self.red_king = src
        elif move.moved == bK:
            self.black_king = src
