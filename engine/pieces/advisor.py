# Sĩ
from typing import List, Tuple
from engine.pieces.base import Piece, Pos
from engine.utils.position import is_empty, same_color, type_of, color_of
from engine.board import Board

class Advisor(Piece):
    @property
    def code(self) -> str:
        return "A"
    
    def moves(self, board:Board, src:Tuple[int, int]) -> List[Tuple[int, int]]:
        sr, sc = src
        piece = board.get(sr, sc)

        if is_empty(piece) or type_of(piece) != "A":
            return []
        
        moves: List[Tuple[int, int]] = []
        my_color = color_of(piece)

        offsets = [(-1,-1),(-1,1),(1,-1),(1,1)]

        for dr, dc in offsets:
            advisor_r = dr+sr
            advisor_c = dc+sc
            if board.in_palace(advisor_r, advisor_c, my_color):
                target = board.get(advisor_r, advisor_c)
                if is_empty(target) or not same_color(piece, target):
                    moves.append((advisor_r, advisor_c))

        return moves