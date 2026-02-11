# engine/pieces/__init__.py
from typing import Optional
from engine.utils.position import is_empty, color_of, type_of

from engine.pieces.rook import Rook
from engine.pieces.knight import Knight
from engine.pieces.cannon import Cannon
from engine.pieces.elephant import Elephant
from engine.pieces.advisor import Advisor
from engine.pieces.king import King
from engine.pieces.pawn import Pawn

PIECE_CLASS = {
    "R": Rook,
    "N": Knight,
    "C": Cannon,
    "E": Elephant,
    "A": Advisor,
    "K": King,
    "P": Pawn,
}

def piece_from_cell(cell: str):
    if is_empty(cell):
        return None
    c = color_of(cell)   
    t = type_of(cell)    
    cls = PIECE_CLASS.get(t)
    if cls is None:
        return None
    return cls(c)
