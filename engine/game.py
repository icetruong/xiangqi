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
        
        undo_info = self.board.apply_move(src, dst)
        self.history.append(undo_info)

        self.turn = self.turn.opposite()
        
        self._update_status()
        return True
    
    def undo(self) -> bool:
        if not self.history:
            return False
        
        undo_info = self.history.pop()
        self.board.undo_move(undo_info)
        self.turn = self.turn.opposite()
        self._update_status()
        return True
         
    def get_turn(self) -> str:
        return self.turn.value
    
    def get_status(self) -> str:
        return self.status.value
    
    def ai_move_minimax(self, depth: int = 3) -> bool:
        from engine.ai.search import find_best_move

        turn_color = self.turn.value
        src, dst = find_best_move(self.board, turn_color, depth)        

        return self.make_move(src, dst)
    
    def get_dynamic_time_limit(self) -> float:
        piece_count = 0
        for r in range(self.board.ROWS):
            for c in range(self.board.COLS):
                if self.board.get(r, c) != ".":
                    piece_count += 1
                    
        if piece_count >= 24:
            return 5.0
        elif piece_count >= 12:
            return 3.0
        else:
            return 1.5

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

        


        