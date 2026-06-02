from typing import Optional, Tuple
import time

from engine.ai.search import find_best_move, SearchContext
from engine.board import Board
from engine.exceptions import SearchTimeout


def best_move_with_time_limit(
    board: Board,
    ai_color: str,
    max_depth: int = 6,
    time_limit_sec: float = 1.5,
) -> Optional[Tuple[Tuple[int, int], Tuple[int, int]]]:
    """
    Iterative deepening với time limit.
    SearchContext (TT, killers, history) được tái dùng qua các depth iteration
    để TT từ depth nông giúp sắp xếp nước đi ở depth sâu hơn.
    """
    start = time.perf_counter()
    deadline = start + max(0.05, time_limit_sec)

    ctx = SearchContext()
    best: Optional[Tuple[Tuple[int, int], Tuple[int, int]]] = None

    for d in range(1, max_depth + 1):
        if time.perf_counter() >= deadline:
            break
        try:
            mv = find_best_move(board, ai_color, d, deadline, ctx)
            if mv is not None:
                best = mv
        except SearchTimeout:
            break

    if best is None:
        from engine.rules.game_rules import generate_legal_moves
        moves = generate_legal_moves(board, ai_color)
        if moves:
            best = moves[0]

    return best
