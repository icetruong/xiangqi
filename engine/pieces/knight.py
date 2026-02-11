# Mã

from typing import List, Tuple
from engine.pieces.base import Piece, Pos
from engine.utils.position import is_empty, same_color, type_of, color_of
from engine.board import Board

class Knight(Piece):
    @property
    def code(self) -> str:
        return "N"
    
    def moves(self, board:Board, src:Tuple[int, int]) -> List[Tuple[int, int]]:
        sr, sc = src
        piece = board.get(sr, sc)

        if is_empty(piece) or type_of(piece) != "N":
            return []
        
        moves: List[Tuple[int, int]] = []
        my_color = color_of(piece)

        offsets = [(-2,-1),(-2,1),(-1,-2),(-1,2),(1,-2),(1,2),(2,1),(2,-1)]
        for dr, dc in offsets:
            knight_r = dr+sr
            knight_c = dc+sc
            if board.in_bounds(knight_r, knight_c):
                target = board.get(knight_r, knight_c)
                obstacle_r: int = 0
                obstacle_c: int = 0
                if abs(dr) == 2:
                    obstacle_r, obstacle_c = sr + dr//2, sc
                else:
                    obstacle_r, obstacle_c = sr , sc + dc//2
                obstacle = board.get(obstacle_r, obstacle_c)
                if is_empty(obstacle):
                    if is_empty(target) or not same_color(piece, target):
                        moves.append((knight_r, knight_c))

        return moves