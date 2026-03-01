from typing import List, Tuple
import time
from engine.ai.evaluator import evaluate_board
from engine.rules.game_rules import generate_legal_moves
from engine.utils.position import is_empty
from engine.board import Board
from engine.excaptions import SearchTimeout

def generate_capture_moves(board: Board, color: str) -> List[Tuple[Tuple[int, int], Tuple[int, int]]]:
    """
    Lấy tất cả nước hợp lệ mà có ăn quân (dst đang có quân).
    """
    
    moves = generate_legal_moves(board, color)
    capture:  List[Tuple[Tuple[int, int], Tuple[int, int]]] = []

    for src, dst in moves:
        if not is_empty(board.get(*dst)):
            capture.append((src, dst))
    
    return capture

def quiescence(board, turn_color: str, ai_color: str, alpha: int, beta: int, maximizing: bool, deadline: float | None = None, q_depth=4) -> int:
    """
    Quiescence search:
    - Stand pat = evaluate hiện tại
    - Nếu còn capture moves: thử capture và recurse
    """
    if deadline is not None and time.perf_counter() >= deadline:
                raise SearchTimeout()
    stand_pat = evaluate_board(board, ai_color)

    if q_depth == 0:
        return stand_pat

    if maximizing:
        alpha = max(alpha, stand_pat)
        if alpha >= beta:
            return alpha
    else:
        beta = min(beta, stand_pat)
        if alpha >= beta:
            return beta

    capture_moves = generate_capture_moves(board, turn_color)

    if maximizing:
        best = alpha
        for src, dst in capture_moves:
            if deadline is not None and time.perf_counter() >= deadline:
                raise SearchTimeout()
            undo = board.apply_move(src, dst)
            try:
                score = quiescence(board, _opp(turn_color), ai_color, alpha, beta, not maximizing, deadline, q_depth - 1)
            finally:
                board.undo_move(undo)

            best = max(best, score)
            alpha = max(alpha, score)
            if alpha >= beta:
                break
        return best
    else:
        best = beta
        for src, dst in capture_moves:
            if deadline is not None and time.perf_counter() >= deadline:
                raise SearchTimeout()
            undo = board.apply_move(src, dst)
            try:
                score = quiescence(board, _opp(turn_color), ai_color, alpha, beta, not maximizing, deadline, q_depth - 1)
            finally:
                board.undo_move(undo)

            best = min(best, score)
            beta = min(beta, score)
            if alpha >= beta:
                break
        return best

def _opp(color: str) -> str:
    return "b" if color == "r" else "r"


