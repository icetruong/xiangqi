# Tướng

from typing import List, Tuple
from engine.pieces.base import Piece, Pos
from engine.utils.position import is_empty, same_color, type_of, color_of
from engine.board import Board

class King(Piece):
    @property
    def code(self) -> str:
        return "K"
    
    def moves(self, board:Board, src:Tuple[int, int]) -> List[Tuple[int, int]]:
        sr, sc = src
        piece = board.get(sr, sc)

        if is_empty(piece) or type_of(piece) != "K":
            return []
        
        moves: List[Tuple[int, int]] = []
        my_color = color_of(piece)

        offsets = [(-1,0),(1,0),(0,-1),(0,1)]

        for dr, dc in offsets:
            king_r = dr+sr
            king_c = dc+sc
            if board.in_palace(king_r, king_c, my_color):
                target = board.get(king_r, king_c)
                if is_empty(target) or not same_color(piece, target):
                    moves.append((king_r, king_c))

        return moves