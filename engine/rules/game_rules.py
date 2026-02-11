# Tổng hợp rule
from typing import Tuple, Optional, List
from engine.board import Board
from engine.utils.position import is_empty, color_of, same_color
from engine.rules.move_rules import is_legal_basic_move
from engine.rules.king_face_rule import kings_face_each_other
from engine.rules.check_rules import is_in_check
from engine.rules.move_rules import (
    rook_moves, knight_moves, cannon_moves,
    elephant_moves, advisor_moves, king_moves, pawn_moves
)

def is_legal_move(board: Board, src: Tuple[int, int], dst: Tuple[int, int], turn_color: str) -> bool:
    """
    Hợp lệ cuối cùng:
    1) có quân ở src
    2) đúng lượt (màu quân = turn_color)
    3) basic move hợp lệ (đúng luật quân)
    4) apply thử -> không được king-face
    5) apply thử -> không được tự đưa tướng vào chiếu
    6) undo
    """
    piece = board.get(*src)
    if is_empty(piece):
        return False
    
    if color_of(piece) != turn_color:
        return False
    
    if not is_legal_basic_move(board, src, dst):
        return False
    
    undo_info = board.apply_move(src, dst)

    if kings_face_each_other(board):
        board.undo_move(undo_info)
        return False
    
    if is_in_check(board, turn_color):
        board.undo_move(undo_info)
        return False
    
    board.undo_move(undo_info)
    return True

#    Quân src có thể đi tới đâu
def pseudo_moves_of_piece(board: Board, src: Tuple[int, int]) -> List[Tuple[int, int]]:
    piece = board.get(*src)
    t = piece[1]  # "R N C E A K P"
    if t == "R": 
        return rook_moves(board, src)
    if t == "N": 
        return knight_moves(board, src)
    if t == "C": 
        return cannon_moves(board, src)
    if t == "E": 
        return elephant_moves(board, src)
    if t == "A": 
        return advisor_moves(board, src)
    if t == "K": 
        return king_moves(board, src)
    if t == "P": 
        return pawn_moves(board, src)
    return []

#   bên color được phép đi những nước nào 
def generate_legal_moves(board: Board, color: str) -> List[Tuple[Tuple[int, int], Tuple[int, int]]]:
    legal: List[Tuple[Tuple[int, int], Tuple[int, int]]] = []

    for i in range(Board.ROWS):
        for j in range(Board.COLS):
            piece = board.get(i, j)
            if is_empty(piece) or color_of(piece) != color:
                continue

            src = (i, j)
            for dst in pseudo_moves_of_piece(board, src):
                if is_legal_move(board, src, dst, color):
                    legal.append((src, dst))

    return legal
    