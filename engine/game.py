# Game controller (turn, move, status)
from typing import Tuple, Optional, List
from engine.board import Board
from engine.enums import Color, GameStatus
from engine.move import Move
from engine.rules.game_rules import generate_legal_moves, is_legal_move
from engine.rules.check_rules import is_in_check


class Game:
    def __init__(self):
        self.board: Board = Board()
        self.board.setup_initial()

        self.turn: Color = Color.RED # đỏ đi đầu tiên
        self.status: GameStatus = GameStatus.ONGOING
        self.history: List[Move] = []
        self._update_status()

    def _update_status(self) -> None:

        turn_color = self.turn.value

        in_check = is_in_check(self.board, turn_color)

        legal_moves = generate_legal_moves(self.board, turn_color)

        if in_check and not legal_moves:
            self.status = GameStatus.CHECKMATE
        elif not in_check and not legal_moves:
            self.status = GameStatus.STALEMATE
        elif in_check:
            self.status = GameStatus.CHECK
        else:
            self.status = GameStatus.ONGOING

    def make_move(self, src: Tuple[int, int], dst: Tuple[int, int]) -> bool:
        """
        Thực hiện 1 nước đi nếu hợp lệ.
        - validate bằng game_rules (basic + king-face + self-check)
        - apply move
        - đổi lượt
        - update status
        """
        turn_color = self.turn.value

        if not is_legal_move(self.board, src, dst, turn_color):
            return False
        
        undo_info = self.board.apply_move_idx(self.board.index(*src), self.board.index(*dst))
        self.history.append(undo_info)

        self.turn = self.turn.opposite()
        
        self._update_status()
        return True
    
    def undo(self) -> bool:
        if not self.history:
            return False
        
        undo_info = self.history.pop()
        self.board.undo_move_idx(undo_info)
        self.turn = self.turn.opposite()
        self._update_status()
        return True
         
    def get_turn(self) -> str:
        return self.turn.value
    
    def get_status(self) -> str:
        return self.status.value
    
    def ai_move_minimax(self, depth: int = 3) -> bool:
        from engine.ai.search import find_best_move, SearchContext

        turn_color = self.turn.value
        # Iterative deepening so TT/killers warm up before the target depth
        ctx = SearchContext()
        best_move = None
        for d in range(1, depth + 1):
            mv = find_best_move(self.board, turn_color, d, ctx=ctx)
            if mv is not None:
                best_move = mv

        if best_move is None:
            return False

        src, dst = best_move
        return self.make_move(src, dst)
    
    def _piece_count(self) -> int:
        return sum(1 for p in self.board.board if p != 0)

    def get_dynamic_time_limit(self) -> float:
        """Time limit for 'normal' difficulty (depth=4 fixed, so this is unused)."""
        count = self._piece_count()
        if count >= 24:
            return 1.5
        elif count >= 12:
            return 1.0
        return 0.6

    def get_hard_time_limit(self) -> float:
        """
        Time limit for 'hard' difficulty, scaled by game phase:
          Opening  (>=24 pieces): 5.0s  → reaches depth 4-5
          Midgame  (>=12 pieces): 4.5s  → reaches depth 6-7
          Endgame  (< 12 pieces): 4.0s  → reaches depth 8+
        """
        count = self._piece_count()
        if count >= 24:
            return 5.0
        elif count >= 12:
            return 4.5
        return 4.0

    def ai_move_time(self, time_limit_sec: Optional[float] = None, max_depth: int = 6) -> bool:
        from engine.ai.time_search import best_move_with_time_limit

        turn_color = self.turn.value
        
        # Nếu chưa truyền thời gian, tự động cấp phát thông minh
        if time_limit_sec is None:
            time_limit_sec = self.get_dynamic_time_limit()

        move = best_move_with_time_limit(self.board, turn_color, max_depth=max_depth, time_limit_sec=time_limit_sec)
        
        if move is None:
            return False
            
        src, dst = move
        return self.make_move(src, dst)

