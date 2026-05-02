from engine.utils.position import is_empty, color_of, type_of
from engine.board import Board
from engine.ai.pst import pst_value

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
    
    red_kr, red_kc = board.row_col(board.red_king) if board.red_king is not None else (9, 4)
    black_kr, black_kc = board.row_col(board.black_king) if board.black_king is not None else (0, 4)

    for i in range(Board.ROWS):
        for j in range(Board.COLS):
            piece = board.board[i * 9 + j]
            if is_empty(piece):
                continue

            c = color_of(piece)
            t = type_of(piece)
            bonus = pst_value(t,c,i,j)
            value = PIECE_VALUE.get(t, 0) + bonus
            
            # Thêm điểm phụ: Khuyến khích Xe, Pháo, Mã, Tốt tiến gần về Tướng địch
            # if t in ("R", "C", "N", "P"):
            #     if c == "r":
            #         dist = abs(i - black_kr) + abs(j - black_kc)
            #         value += (17 - dist)
            #     else:
            #         dist = abs(i - red_kr) + abs(j - red_kc)
            #         value += (17 - dist)

            # if c == perspective_color:
            #     score += value
            # else:
            #     score -= value

    return score