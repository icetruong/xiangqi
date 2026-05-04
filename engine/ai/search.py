from typing import Tuple, Optional, List
import time
from engine.board import Board
from engine.rules.game_rules import generate_legal_moves
from engine.rules.check_rules import is_in_check
from engine.ai.evaluator import evaluate_board
from engine.ai.move_ordering import order_moves
from engine.ai.quiescence import quiescence
from engine.exceptions import SearchTimeout

MATE_SCORE = 10**9

def opponent(color: str) -> str:
    return "r" if color == "b" else "b"

# maximingzing: True là ai -> false là người
def minimax(board: Board, ai_color: str, turn_color: str, maximizing: bool, depth: int, alpha: int, beta: int, deadline: float | None = None) -> int:
    if deadline is not None and time.perf_counter() >= deadline:
        raise SearchTimeout()

    # Quiescence Search
    if depth == 0:
        return quiescence(board, turn_color, ai_color, alpha, beta, maximizing, deadline)
    
    moves = generate_legal_moves(board, turn_color)
    if not moves:
        # Trong cờ tướng, hết nước đi (dù bị chiếu hay không) đều là thua.
        if turn_color == ai_color:
            return -MATE_SCORE - depth
        else:
            return MATE_SCORE + depth
    moves = order_moves(board, moves, turn_color)
    if maximizing:
        max_eval = float('-inf')
        for src, dst in moves:
            if deadline is not None and time.perf_counter() >= deadline:
                raise SearchTimeout()
            undo = board.apply_move_idx(board.index(*src), board.index(*dst))
            try:
                eval = minimax(board, ai_color, opponent(turn_color), False, depth-1, alpha, beta, deadline)
            finally:  
                board.undo_move_idx(undo)

            max_eval = max(max_eval, eval)
            alpha = max(alpha, eval)

            if beta <= alpha:
                break
        return max_eval
    else:
        min_eval = float('inf')
        for src, dst in moves:
            if deadline is not None and time.perf_counter() >= deadline:
                raise SearchTimeout()
            
            undo = board.apply_move_idx(board.index(*src), board.index(*dst))
            try:
                eval = minimax(board, ai_color, opponent(turn_color), True, depth-1, alpha, beta, deadline)
            finally:
                board.undo_move_idx(undo)

            min_eval = min(min_eval, eval)
            beta = min(beta, eval)

            if alpha >= beta:
                break
        return min_eval


# depth là độ sâu tìm kiếm
def find_best_move(board: Board, ai_color: str, depth: int, deadline: float | None = None) -> Optional[Tuple[Tuple[int, int], Tuple[int, int]]]:
    """
    Trả về nước đi tốt nhất cho ai_color.
    depth: độ sâu tìm kiếm..
    """

    moves = generate_legal_moves(board, ai_color)
    if not moves:
        return None
    moves = order_moves(board, moves, ai_color)
    best_move: Optional[Tuple[Tuple[int, int], Tuple[int, int]]] = None
    best_score = float('-inf')

    for src, dst in moves:
        if deadline is not None and time.perf_counter() >= deadline:
            raise SearchTimeout()
        undo = board.apply_move_idx(board.index(*src), board.index(*dst))
        try:
            score = minimax(board, ai_color, opponent(ai_color), False, depth-1, float('-inf'), float('inf'), deadline)
        finally:
            board.undo_move_idx(undo)

        if score > best_score:
            best_score = score
            best_move = (src, dst)
    return best_move

