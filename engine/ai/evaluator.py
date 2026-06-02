from engine.utils.position import is_empty, color_of, type_of
from engine.board import Board
from engine.ai.pst import pst_value

PIECE_VALUE = {
    "K": 100000,
    "R": 600,
    "C": 450,
    "N": 350,
    "E": 250,
    "A": 250,
    "P": 100,
}

# ── Try Cython fast path ────────────────────────────────────────────────────
try:
    from engine.ai.fast_eval import evaluate_board_cy as _cy_eval  # type: ignore[import]

    def evaluate_board(board: Board, perspective_color: str) -> int:
        return _cy_eval(board.board, 1 if perspective_color == "r" else -1)

except ImportError:
    # ── Pure Python fallback ────────────────────────────────────────────────
    def evaluate_board(board: Board, perspective_color: str) -> int:
        score = 0
        for i in range(Board.ROWS):
            for j in range(Board.COLS):
                piece = board.board[i * 9 + j]
                if is_empty(piece):
                    continue
                c = color_of(piece)
                t = type_of(piece)
                if not t or not c:
                    continue
                bonus = pst_value(t, c, i, j)
                value = PIECE_VALUE.get(t, 0) + bonus
                if c == perspective_color:
                    score += value
                else:
                    score -= value
        return score
