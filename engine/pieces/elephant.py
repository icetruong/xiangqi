# Tượng

from typing import List, Tuple
from engine.pieces.base import Piece
from engine.utils.position import is_empty, same_color, type_of, color_of
from engine.board import Board

class Elephant(Piece):
    @property
    def code(self) -> str:
        return "E"
    
    def moves(self, board:Board, src:Tuple[int, int]) -> List[Tuple[int, int]]:
        sr, sc = src
        piece = board.get(sr, sc)

        if is_empty(piece) or type_of(piece) != "E":
            return []
        
        moves: List[Tuple[int, int]] = []
        my_color = color_of(piece)
        
        offsets = [(-2,-2),(-2,2),(2,-2),(2,2)]
        for dr, dc in offsets:
            elephant_r = dr + sr
            elephant_c = dc + sc
            if my_color == "b" and elephant_r > 4:
                continue
            if my_color == "r" and elephant_r < 5:
                continue
            if board.in_bounds(elephant_r, elephant_c):
                target = board.get(elephant_r, elephant_c)
                obstacle_r = sr + dr//2
                obstacle_c = sc + dc//2
                obstacle = board.get(obstacle_r, obstacle_c)
                if is_empty(obstacle):
                    if is_empty(target) or not same_color(piece, target):
                        moves.append((elephant_r, elephant_c))

        return moves