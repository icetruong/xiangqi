from typing import Tuple, Optional, List
from engine.board import Board
from engine.rules.game_rules import generate_legal_moves
from engine.rules.check_rules import is_in_check
from engine.ai.evaluator import evaluate_board

MATE_SCORE = 10**9

def opponent(color: str) -> str:
    return "r" if color == "b" else "b"

# maximingzing: True là ai -> false là người
def minimax(board: Board, ai_color: str, turn_color: str, maximizing: bool, depth: int, alpha: int, beta: int) -> int:
    if depth == 0:
        return evaluate_board(board, ai_color)
    
    moves = generate_legal_moves(board, turn_color)
    if not moves:
        if is_in_check(board, turn_color):
            if turn_color == ai_color:
                return float('-inf')
            else:
                return float('inf')
        else:
            return 0

    if maximizing:
        max_eval = float('-inf')
        for src, dst in moves:
            undo = board.apply_move(src, dst)
            eval = minimax(board, ai_color, opponent(turn_color), False, depth-1, alpha, beta)
            board.undo_move(undo)

            max_eval = max(max_eval, eval)
            alpha = max(alpha, eval)

            if beta <= alpha:
                break
        return max_eval
    else:
        min_eval = float('inf')
        for src, dst in moves:
            undo = board.apply_move(src, dst)
            eval = minimax(board, ai_color, opponent(turn_color), True, depth-1, alpha, beta)
            board.undo_move(undo)

            min_eval = min(min_eval, eval)
            beta = min(beta, eval)

            if alpha >= beta:
                break
        return min_eval


# depth là độ sâu tìm kiếm
def find_best_move(board: Board, ai_color: str, depth: int) -> Optional[Tuple[Tuple[int, int], Tuple[int, int]]]:
    """
    Trả về nước đi tốt nhất cho ai_color.
    depth: độ sâu tìm kiếm..
    """

    moves = generate_legal_moves(board, ai_color)
    if not moves:
        return None
    
    best_move: Optional[Tuple[Tuple[int, int], Tuple[int, int]]] = None
    best_score = float('-inf')

    for src, dst in moves:
        undo = board.apply_move(src, dst)
        score = minimax(board, ai_color, opponent(ai_color), False, depth-1, float('-inf'), float('inf'))
        board.undo_move(undo)

        if score > best_score:
            best_score = score
            best_move = (src, dst)
    return best_move

