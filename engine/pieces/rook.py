# Xe

from typing import List, Tuple
from engine.pieces.base import Piece
from engine.utils.position import is_empty, same_color, type_of, color_of
from engine.board import Board

class Rook(Piece):
    @property
    def code(self) -> str:
        return "R"
    
    def moves(self, board:Board, src:Tuple[int, int]) -> List[Tuple[int, int]]:
        sr, sc = src
        piece = board.get(sr, sc)

        if is_empty(piece) or type_of(piece) != "R":
            return []
        
        moves: List[Tuple[int, int]] = []
        my_color = color_of(piece)

        directions = [(-1,0), (1,0), (0,-1), (0,1)]
        for dr, dc in directions:
            rook_r = dr+sr
            rook_c = dc+sc
            while board.in_bounds(rook_r, rook_c):
                target = board.get(rook_r, rook_c)
                if is_empty(target):
                    moves.append((rook_r, rook_c))
                else:
                    if not same_color(piece, target):
                        moves.append((rook_r, rook_c))
                    break

                rook_r+=dr
                rook_c+=dc

        return moves