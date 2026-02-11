# engine/serializer/fen.py
from typing import Tuple, Optional
from engine.board import Board
from engine.utils.position import EMPTY

# map fen char -> board string
FEN_TO_CELL = {
    # black (lower)
    "r": "bR",
    "n": "bN",
    "e": "bE",
    "a": "bA",
    "k": "bK",
    "c": "bC",
    "p": "bP",
    # red (upper)
    "R": "rR",
    "N": "rN",
    "E": "rE",
    "A": "rA",
    "K": "rK",
    "C": "rC",
    "P": "rP",
}

CELL_TO_FEN = {v: k for k, v in FEN_TO_CELL.items()}


def board_to_fen(board: Board, turn: Optional[str] = None) -> str:
    """
    Serialize board -> fen string.
    turn: "r" / "b" hoặc None (không ghi turn)
    """
    rows = []
    for r in range(board.ROWS):
        empties = 0
        parts = []
        for c in range(board.COLS):
            cell = board.get(r, c)
            if cell == EMPTY:
                empties += 1
            else:
                if empties > 0:
                    parts.append(str(empties))
                    empties = 0
                parts.append(CELL_TO_FEN.get(cell, "?"))
        if empties > 0:
            parts.append(str(empties))
        rows.append("".join(parts))
    fen_board = "/".join(rows)

    if turn in ("r", "b"):
        return fen_board + " " + turn
    return fen_board


def load_fen(board: Board, fen: str) -> Optional[str]:
    """
    Load fen -> board.
    Return turn ("r"/"b") nếu có, else None.
    """
    fen = fen.strip()
    if not fen:
        raise ValueError("Empty FEN")

    # split optional turn
    parts = fen.split()
    fen_board = parts[0]
    turn = parts[1] if len(parts) > 1 else None
    if turn is not None and turn not in ("r", "b"):
        raise ValueError(f"Invalid turn: {turn}")

    ranks = fen_board.split("/")
    if len(ranks) != board.ROWS:
        raise ValueError(f"Invalid rank count: {len(ranks)} != {board.ROWS}")

    new_board = [[EMPTY for _ in range(board.COLS)] for _ in range(board.ROWS)]

    for r in range(board.ROWS):
        col = 0
        for ch in ranks[r]:
            if ch.isdigit():
                n = int(ch)
                col += n
            else:
                if col >= board.COLS:
                    raise ValueError(f"Too many columns at row {r}")
                cell = FEN_TO_CELL.get(ch)
                if cell is None:
                    raise ValueError(f"Unknown FEN char: {ch}")
                new_board[r][col] = cell
                col += 1

        if col != board.COLS:
            raise ValueError(f"Row {r} has {col} cols, expected {board.COLS}")

    board.board = new_board
    return turn
