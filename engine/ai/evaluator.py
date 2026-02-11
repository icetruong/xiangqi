from engine.utils.position import is_empty, color_of, type_of
from engine.board import Board

PIECE_VALUE = {
    "K": 100000,  # tướng cực lớn
    "R": 600,
    "C": 450,
    "N": 350,
    "E": 250,
    "A": 250,
    "P": 100,
}

def evaluate_board(board: Board, perspective_color: str) -> int:
    score = 0
    for i in range(Board.ROWS):
        for j in range(Board.COLS):
            piece = board.get(i,j)
            if is_empty(piece):
                continue

            t = type_of(piece)
            value = PIECE_VALUE.get(t, 0)

            if color_of(piece) == perspective_color:
                score += value
            else:
                score -= value

    return score