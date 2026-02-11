# Piece base class

# engine/pieces/base.py
from typing import List, Tuple
from abc import ABC, abstractmethod
from engine.utils.position import is_empty, color_of, type_of
from engine.board import Board

class Piece(ABC):
    """
    Piece object chỉ wrap logic, còn board vẫn lưu string như "rR".
    """

    def __init__(self, color: str):
        self.color = color  # "r" or "b"

    @property
    @abstractmethod
    def code(self) -> str:
        """Piece type code: 'R','N','C','E','A','K','P'"""
        raise NotImplementedError

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}(color={self.color})"

    def is_mine(self, cell: str) -> bool:
        return (not is_empty(cell)) and color_of(cell) == self.color

    def is_enemy(self, cell: str) -> bool:
        return (not is_empty(cell)) and color_of(cell) != self.color

    @abstractmethod
    def moves(self, board:Board, src: Tuple[int, int]) -> List[Tuple[int, int]]:
        """Pseudo-legal moves (chưa xét self-check, king-face)."""
        raise NotImplementedError
