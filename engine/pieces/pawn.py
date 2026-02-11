# Tốt

from typing import List, Tuple
from engine.pieces.base import Piece, Pos
from engine.utils.position import is_empty, same_color, type_of, color_of
from engine.board import Board

class Pawn(Piece):
    @property
    def code(self) -> str:
        return "P"
    
    def moves(self, board:Board, src:Tuple[int, int]) -> List[Tuple[int, int]]:
        sr, sc = src
        piece = board.get(sr, sc)

        if is_empty(piece) or type_of(piece) != "P":
            return []
        
        moves: List[Tuple[int, int]] = []
        my_color = color_of(piece)
        offsets = [(-1,0)] if my_color == "r" else [(1,0)]
        if (my_color == "b" and sr > 4) or (my_color == "r" and sr < 5):
            offsets += [(0,-1), (0,1)]
        
        for dr, dc in offsets:
            pawn_r = dr+sr
            pawn_c = dc+sc
            if board.in_bounds(pawn_r, pawn_c):
                target = board.get(pawn_r, pawn_c)
                if is_empty(target) or not same_color(piece, target):
                    moves.append((pawn_r, pawn_c))

        return moves