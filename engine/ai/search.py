from typing import Tuple, Optional
import time

from engine.board import Board
from engine.rules.game_rules import generate_legal_moves
from engine.rules.check_rules import is_in_check
from engine.ai.evaluator import evaluate_board
from engine.ai.move_ordering import order_moves
from engine.ai.quiescence import quiescence
from engine.ai.transposition import TranspositionTable, EXACT, LOWERBOUND, UPPERBOUND
from engine.exceptions import SearchTimeout

MATE_SCORE = 10**9
NULL_MOVE_R = 2   # null-move depth reduction
MAX_DEPTH = 64


def _opp(color: str) -> str:
    return "r" if color == "b" else "b"


class SearchContext:
    """Shared state across all nodes of a single search."""
    __slots__ = ("tt", "killers", "history")

    def __init__(self) -> None:
        self.tt = TranspositionTable()
        # killers[depth] = [best_killer, second_killer]
        self.killers: list[list] = [[None, None] for _ in range(MAX_DEPTH + 1)]
        # history[src_idx][dst_idx] = cumulative cutoff score
        self.history: list[list[int]] = [[0] * 90 for _ in range(90)]


def _update_killers(killers: list, move: tuple) -> None:
    if killers[0] != move:
        killers[1] = killers[0]
        killers[0] = move


def minimax(
    board: Board,
    ai_color: str,
    turn_color: str,
    maximizing: bool,
    depth: int,
    alpha: int,
    beta: int,
    deadline: float | None = None,
    ctx: SearchContext | None = None,
    in_null: bool = False,
) -> int:
    if deadline is not None and time.perf_counter() >= deadline:
        raise SearchTimeout()

    hash_key = board.zobrist_hash

    # ── Transposition table probe ───────────────────────────────────────────
    tt_move: Optional[tuple] = None
    if ctx is not None:
        tt_score, tt_move = ctx.tt.probe(hash_key, depth, alpha, beta)
        if tt_score is not None:
            return tt_score

    # ── Leaf node ──────────────────────────────────────────────────────────
    if depth == 0:
        return quiescence(board, turn_color, ai_color, alpha, beta, maximizing, deadline)

    # ── Null move pruning (maximizing only, not in check, no consecutive) ──
    if maximizing and depth >= 3 and not in_null and not is_in_check(board, turn_color):
        null_score = minimax(
            board, ai_color, _opp(turn_color), False,
            depth - 1 - NULL_MOVE_R, alpha, beta, deadline, ctx, in_null=True,
        )
        if null_score >= beta:
            return beta

    # ── Generate and order moves ───────────────────────────────────────────
    moves = generate_legal_moves(board, turn_color)
    if not moves:
        return (-MATE_SCORE - depth) if turn_color == ai_color else (MATE_SCORE + depth)

    killers = ctx.killers[depth] if ctx is not None else None
    history = ctx.history if ctx is not None else None
    moves = order_moves(board, moves, turn_color, killers=killers, history=history, tt_move=tt_move)

    best_move_found: Optional[tuple] = None
    cols = board.COLS

    # ── Maximizing ─────────────────────────────────────────────────────────
    if maximizing:
        best: int = -MATE_SCORE * 2
        flag = UPPERBOUND

        for src, dst in moves:
            if deadline is not None and time.perf_counter() >= deadline:
                raise SearchTimeout()
            src_idx = src[0] * cols + src[1]
            dst_idx = dst[0] * cols + dst[1]
            undo = board.apply_move_idx(src_idx, dst_idx)
            try:
                score = minimax(board, ai_color, _opp(turn_color), False,
                                depth - 1, alpha, beta, deadline, ctx, False)
            finally:
                board.undo_move_idx(undo)

            if score > best:
                best = score
                best_move_found = (src, dst)
            if score > alpha:
                alpha = score
                flag = EXACT
            if alpha >= beta:
                flag = LOWERBOUND
                # Non-capture beta-cutoff → update killers & history
                if ctx is not None and board.board[dst_idx] == 0:
                    _update_killers(ctx.killers[depth], (src, dst))
                    ctx.history[src_idx][dst_idx] += depth * depth
                break

    # ── Minimizing ─────────────────────────────────────────────────────────
    else:
        best: int = MATE_SCORE * 2
        flag = EXACT

        for src, dst in moves:
            if deadline is not None and time.perf_counter() >= deadline:
                raise SearchTimeout()
            src_idx = src[0] * cols + src[1]
            dst_idx = dst[0] * cols + dst[1]
            undo = board.apply_move_idx(src_idx, dst_idx)
            try:
                score = minimax(board, ai_color, _opp(turn_color), True,
                                depth - 1, alpha, beta, deadline, ctx, False)
            finally:
                board.undo_move_idx(undo)

            if score < best:
                best = score
                best_move_found = (src, dst)
            if score < beta:
                beta = score
            if alpha >= beta:
                flag = UPPERBOUND
                if ctx is not None and board.board[dst_idx] == 0:
                    _update_killers(ctx.killers[depth], (src, dst))
                    ctx.history[src_idx][dst_idx] += depth * depth
                break

    # ── Store in transposition table ───────────────────────────────────────
    if ctx is not None and best_move_found is not None:
        ctx.tt.store(hash_key, best, depth, flag, best_move_found)

    return best


def find_best_move(
    board: Board,
    ai_color: str,
    depth: int,
    deadline: float | None = None,
    ctx: SearchContext | None = None,
) -> Optional[Tuple[Tuple[int, int], Tuple[int, int]]]:
    moves = generate_legal_moves(board, ai_color)
    if not moves:
        return None

    # Single legal move — return immediately without searching
    if len(moves) == 1:
        return moves[0]

    killers = ctx.killers[depth] if ctx is not None else None
    history = ctx.history if ctx is not None else None
    tt_move = ctx.tt.get_best_move(board.zobrist_hash) if ctx is not None else None
    moves = order_moves(board, moves, ai_color, killers=killers, history=history, tt_move=tt_move)

    best_move: Optional[Tuple[Tuple[int, int], Tuple[int, int]]] = None
    best_score: int = -MATE_SCORE * 2

    for src, dst in moves:
        if deadline is not None and time.perf_counter() >= deadline:
            raise SearchTimeout()
        undo = board.apply_move_idx(board.index(*src), board.index(*dst))
        try:
            score = minimax(board, ai_color, _opp(ai_color), False,
                            depth - 1, -MATE_SCORE * 2, MATE_SCORE * 2, deadline, ctx, False)
        finally:
            board.undo_move_idx(undo)

        if score > best_score:
            best_score = score
            best_move = (src, dst)

    return best_move
