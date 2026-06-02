from typing import Optional, Tuple

EXACT = 0
LOWERBOUND = 1
UPPERBOUND = 2

_Move = Tuple[Tuple[int, int], Tuple[int, int]]


class TTEntry:
    __slots__ = ("score", "depth", "flag", "best_move")

    def __init__(self, score: int, depth: int, flag: int, best_move: Optional[_Move]):
        self.score = score
        self.depth = depth
        self.flag = flag
        self.best_move = best_move


class TranspositionTable:
    def __init__(self):
        self._table: dict[int, TTEntry] = {}

    def probe(self, key: int, depth: int, alpha: int, beta: int) -> tuple[Optional[int], Optional[_Move]]:
        e = self._table.get(key)
        if e is None:
            return None, None
        best_move = e.best_move
        if e.depth < depth:
            return None, best_move
        if e.flag == EXACT:
            return e.score, best_move
        if e.flag == LOWERBOUND and e.score >= beta:
            return e.score, best_move
        if e.flag == UPPERBOUND and e.score <= alpha:
            return e.score, best_move
        return None, best_move

    def get_best_move(self, key: int) -> Optional[_Move]:
        e = self._table.get(key)
        return e.best_move if e else None

    def store(self, key: int, score: int, depth: int, flag: int, best_move: Optional[_Move] = None) -> None:
        e = self._table.get(key)
        if e is None or e.depth <= depth:
            self._table[key] = TTEntry(score, depth, flag, best_move)

    def clear(self) -> None:
        self._table.clear()
