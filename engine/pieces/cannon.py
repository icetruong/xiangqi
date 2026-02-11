# Pháo

from typing import List, Tuple
from engine.pieces.base import Piece
from engine.utils.position import is_empty, same_color, type_of, color_of
from engine.board import Board

class Cannon(Piece):
    @property
    def code(self) -> str:
        return "C"
    
    def moves(self, board:Board, src:Tuple[int, int]) -> List[Tuple[int, int]]:
        sr, sc = src
        piece = board.get(sr, sc)

        if is_empty(piece) or type_of(piece) != "C":
            return []
        
        moves: List[Tuple[int, int]] = []
        my_color = color_of(piece)
        directions = [(-1,0), (1,0), (0,-1), (0,1)]

        for dr, dc in directions:
            cannon_r = dr + sr
            cannon_c = dc + sc
            jump = False
            while board.in_bounds(cannon_r, cannon_c):
                target = board.get(cannon_r, cannon_c)
                if not jump:
                    if is_empty(target):
                        moves.append((cannon_r, cannon_c))
                    else:
                        jump = True
                else:
                    if not is_empty(target):
                        if not same_color(piece, target):
                            moves.append((cannon_r, cannon_c))
                        break 
                cannon_r+= dr
                cannon_c+= dc

        return moves