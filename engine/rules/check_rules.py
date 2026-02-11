# Chiếu, chiếu bí
from typing import Tuple, Optional
from engine.board import Board
from engine.utils.position import is_empty, color_of, type_of
from engine.rules.move_rules import (
    rook_moves, cannon_moves, knight_moves,
    elephant_moves, advisor_moves, king_moves, pawn_moves
)

def find_king(board: Board, color: str) -> Tuple[int, int]:
    target = color+ "K"
    for i in range(Board.ROWS):
        for j in range(Board.COLS):
            if board.get(i, j) == target:
                return (i,j)
    return None

def attacks_square(board: Board, src: Tuple[int, int], dst: Tuple[int, int]) -> bool:
    sr, sc = src
    piece = board.get(sr, sc)
    if is_empty(piece):
        return False
    
    t = type_of(piece)
    if t == "R":
        return dst in rook_moves(board, src)
    if t == "C":
        return dst in cannon_moves(board, src)
    if t == "N":
        return dst in knight_moves(board, src)
    if t == "E":
        return dst in elephant_moves(board, src)
    if t == "A":
        return dst in advisor_moves(board, src)
    if t == "K":
        return dst in king_moves(board, src)
    if t == "P":
        return dst in pawn_moves(board, src)

    return False

# check vua có bị chiếu không
def is_in_check(board: Board, color: str) -> bool:
    king_pos = find_king(board=board, color=color)
    if king_pos is None:
        return False  
    enemy = "r" if color == "b" else "b"
    for i in range(Board.ROWS):
        for j in range(Board.COLS):
            piece = board.get(i, j)
            if is_empty(piece):
                continue
            if color_of(piece) != enemy:
                continue

            if attacks_square(board=board, src=(i,j), dst=king_pos):
                return True
    return False
