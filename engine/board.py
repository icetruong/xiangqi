# Bàn cờ 9x10
from typing import Tuple, List, Optional
from engine.move import Move
from engine.utils.position import EMPTY, in_bounds, in_palace
class Board:
    ROWS = 10
    COLS = 9

    def __init__(self, state=None):
        self.black_king: Optional[Tuple[int, int]] = None
        self.red_king: Optional[Tuple[int, int]] = None
        if state is None:
            self.board = self._create_empty_board()
        else:
            self.board = state
            self.update_king_positions()

    def update_king_positions(self) -> None:
        for r in range(self.ROWS):
            for c in range(self.COLS):
                if self.board[r][c] == "rK":
                    self.red_king = (r, c)
                elif self.board[r][c] == "bK":
                    self.black_king = (r, c)

    def _create_empty_board(self) -> List[List[str]]:
        return [["." for _ in range(self.COLS)] for _ in range(self.ROWS)]
    
    def get(self, row: int, col: int) -> str:
        return self.board[row][col]
    
    def set(self, row: int, col: int, value: str) -> None:
        self.board[row][col] = value
        
    def in_bounds(self, row: int, col: int) -> bool:
        return in_bounds(row, col)
    
    def in_palace(self, row: int, col: int, color: str) -> bool:
        return in_palace(row, col, color)
    
    def setup_initial(self):
        self.board = self._create_empty_board()

        # --- BLACK ---
        self.board[0] = ["bR","bN","bE","bA","bK","bA","bE","bN","bR"]
        self.board[2][1] = "bC"
        self.board[2][7] = "bC"
        for c in range(0, 9, 2):
            self.board[3][c] = "bP"

        # --- RED ---
        self.board[9] = ["rR","rN","rE","rA","rK","rA","rE","rN","rR"]
        self.board[7][1] = "rC"
        self.board[7][7] = "rC"
        for c in range(0, 9, 2):
            self.board[6][c] = "rP"

        self.update_king_positions()
        

    def apply_move(self, src: Tuple[int, int], dst: Tuple[int, int]) -> Move:
        sr, sc = src
        dr, dc = dst

        moved = self.get(sr, sc)
        captured = self.get(dr, dc)

        #move
        self.set(sr, sc, EMPTY)
        self.set(dr, dc, moved)

        if moved == "rK":
            self.red_king = (dr, dc)
        elif moved == "bK":
            self.black_king = (dr, dc)

        return Move(src=src, dst=dst, moved=moved, captured=captured)
    
    def undo_move(self, move:Move) -> None:
        sr, sc = move.src
        dr, dc = move.dst

        self.set(sr, sc, move.moved if move.moved is not None else EMPTY)
        self.set(dr, dc, move.captured if move.captured is not None else EMPTY)

        if move.moved == "rK":
            self.red_king = (sr, sc)
        elif move.moved == "bK":
            self.black_king = (sr, sc)


