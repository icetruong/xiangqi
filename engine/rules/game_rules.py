# Tổng hợp rule
from typing import Tuple, Optional
from engine.board import Board
from engine.utils.position import is_empty, color_of
from engine.rules.move_rules import is_legal_basic_move
from engine.rules.king_face_rule import kings_face_each_other
from engine.rules.check_rules import is_in_check

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
    

    