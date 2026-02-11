# engine/serializer/json_serializer.py
from typing import List
from engine.board import Board
from engine.utils.position import EMPTY

def to_json2d(board: Board) -> List[List[str]]:
    """
    Trả về 2D list strings, dùng cho debug/log/test.
    """
    return [row[:] for row in board.board]

def load_json2d(board: Board, data: List[List[str]]) -> None:
    """
    Load từ 2D list. Có validate kích thước cơ bản.
    """
    if len(data) != board.ROWS:
        raise ValueError(f"Invalid rows: {len(data)} != {board.ROWS}")
    for r in range(board.ROWS):
        if len(data[r]) != board.COLS:
            raise ValueError(f"Invalid cols at row {r}: {len(data[r])} != {board.COLS}")
    board.board = [row[:] for row in data]

def empty_json2d() -> List[List[str]]:
    return [[EMPTY for _ in range(9)] for _ in range(10)]
