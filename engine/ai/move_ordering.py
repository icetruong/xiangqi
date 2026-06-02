from typing import Tuple, List, Optional
from engine.utils.position import is_empty, type_of
from engine.board import Board
from engine.ai.evaluator import PIECE_VALUE

_Move = Tuple[Tuple[int, int], Tuple[int, int]]


def order_moves(
    board: Board,
    moves: List[_Move],
    turn_color: str,
    killers: Optional[list] = None,
    history: Optional[list] = None,
    tt_move: Optional[_Move] = None,
) -> List[_Move]:
    b = board.board
    cols = board.COLS

    def score(mv: _Move) -> int:
        (sr, sc), (dr, dc) = mv
        s_idx = sr * cols + sc
        d_idx = dr * cols + dc

        # TT best move from previous iteration — highest priority
        if tt_move is not None and mv == tt_move:
            return 10_000_000

        capture = b[d_idx]
        if not is_empty(capture):
            # MVV-LVA: most-valuable victim, least-valuable attacker
            moved = b[s_idx]
            vt = type_of(capture)
            at = type_of(moved)
            victim_val = PIECE_VALUE.get(vt, 0) if vt else 0
            attacker_val = PIECE_VALUE.get(at, 0) if at else 0
            return 1_000_000 + 100 * victim_val - attacker_val

        # Killer moves (non-capture moves that caused beta cutoffs at this depth)
        if killers is not None:
            if mv == killers[0]:
                return 900_000
            if mv == killers[1]:
                return 800_000

        # History heuristic (cumulative score of beta cutoffs)
        if history is not None:
            return history[s_idx][d_idx]

        return 0

    return sorted(moves, key=score, reverse=True)
