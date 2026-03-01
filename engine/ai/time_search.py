# engine/ai/time_search.py
from typing import Optional, Tuple
import time

from engine.ai.search import find_best_move
from engine.board import Board
from engine.excaptions import SearchTimeout


def best_move_with_time_limit(board: Board, ai_color: str, max_depth: int = 6, time_limit_sec: float = 0.5) -> Optional[Tuple[Tuple[int, int], Tuple[int, int]]]:
    """
    Iterative deepening:
    - chạy depth 1..max_depth
    - hết thời gian -> trả best move của depth gần nhất đã xong
    """
    start = time.perf_counter()
    deadline = start + max(0.01, time_limit_sec)

    best: Optional[Tuple[Tuple[int, int], Tuple[int, int]]] = None

    for d in range(1, max_depth + 1):
        # nếu hết thời gian thì dừng luôn
        if time.perf_counter() >= deadline:
            break

        try:
            mv = find_best_move(board, ai_color, d, deadline)
            if mv is not None:
                best = mv
        except SearchTimeout:
            break

    return best
