# Tướng đối mặt
from typing import Optional, Tuple
from engine.board import Board
from engine.utils.position import is_empty

def kings_face_each_other(board: Board) -> bool:
    if board.red_king is None or board.black_king is None:
        return False

    red_r, red_c = board.row_col(board.red_king)
    black_r, black_c = board.row_col(board.black_king)

    if red_c != black_c:
        return False
    
    start = min(red_r, black_r)+1
    end = max(red_r, black_r)
    for i in range(start, end):
        if not is_empty(board.board[i * 9 + red_c]):
            return False
        
    return True
