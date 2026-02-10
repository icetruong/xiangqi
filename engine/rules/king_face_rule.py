# Tướng đối mặt
from typing import Optional, Tuple
from engine.board import Board
from engine.utils.position import is_empty

def find_king(board: Board, color: str) -> Tuple[int, int]:
    target = color+ "K"
    for i in range(Board.ROWS):
        for j in range(Board.COLS):
            if board.get(i, j) == target:
                return (i,j)
    return None

def kings_face_each_other(board: Board) -> bool:
    red_pos = find_king(board=board, color="r")
    black_pos = find_king(board=board, color="b")

    if red_pos is None and black_pos is None:
        return False

    red_r, red_c = red_pos
    black_r, black_c = black_pos

    if red_c != black_c:
        return False
    
    start = min(red_r, black_r)+1
    end = max(red_r, black_r)
    for i in range(start, end):
        if not is_empty(board.get(i, red_c)):
            return False
        
    return True
