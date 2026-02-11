from typing import Tuple, List
from engine.utils.position import is_empty, type_of
from engine.rules.check_rules import is_in_check
from engine.board import Board

from engine.ai.evaluator import PIECE_VALUE

def opponent(color: str) -> str:
    return "r" if color == "b" else "b"

def move_score(board: Board, move: Tuple[Tuple[int, int], Tuple[int, int]], turn_color: str) -> int:
    (sr, sc), (dr, dc) = move

    capture = board.get(dr, dc)
    score = 0
    if not is_empty(capture):
        score += 10000 + PIECE_VALUE.get(type_of(capture), 0)
    
    undo_info = board.apply_move((sr, sc), (dr, dc))
    if is_in_check(board, turn_color):
        score += 500
    board.undo_move(undo_info)

    return score

def order_moves(board: Board, moves: List[Tuple[Tuple[int, int], Tuple[int, int]]], turn_color: str) -> List[Tuple[Tuple[int, int], Tuple[int, int]]]:
    return sorted(moves, key = lambda mv : move_score(board, mv, turn_color), reverse=True)
