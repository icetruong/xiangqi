from typing import List, Tuple, Dict, Any, Optional
from engine.game import Game as EngineGame
from engine.board import Board
from engine.enums import Color, GameStatus
from engine.utils.position import EMPTY as ENGINE_EMPTY

CONTRACT_EMPTY = ""

def _to_engine_board(board_state: List[List[str]]) -> List[List[str]]:
    """Convert contract board (empty="") to engine board (empty=".")."""
    return [[ENGINE_EMPTY if cell == CONTRACT_EMPTY else cell for cell in row] for row in board_state]

def _to_contract_board(engine_board: List[List[str]]) -> List[List[str]]:
    """Convert engine board (empty=".") to contract board (empty="")."""
    return [[CONTRACT_EMPTY if cell == ENGINE_EMPTY else cell for cell in row] for row in engine_board]

def init_game_state() -> List[List[str]]:
    """
    Initialize game state (standard starting position).
    Returns 10x9 board state.
    """
    game = EngineGame()
    # Engine Board internally uses "." for empty
    # We need to expose it as "" 
    return _to_contract_board(game.board.board)

def apply_move(
    board_state: List[List[str]], 
    side: str, 
    move: Dict[str, Any]
) -> Tuple[List[List[str]], Dict[str, Any]]:
    """
    Apply a move to the board state.
    
    Args:
        board_state: Current 10x9 board
        side: 'r' or 'b'
        move: {'from': [r,c], 'to': [r,c]}
        
    Returns:
        (new_board_state, meta_info)
    """
    # 1. Setup Engine Game with current state
    engine_board = _to_engine_board(board_state)
    game = EngineGame()
    game.board = Board(state=engine_board)
    game.turn = Color(side)
    game._update_status() # Refresh status based on loaded board

    # 2. Parse move
    src = tuple(move['from'])
    dst = tuple(move['to'])

    # 3. Validate & Apply
    # Engine's make_move checks legality internally
    success = game.make_move(src, dst)
    
    if not success:
        # Engine refused move (illegal)
        raise ValueError(f"Invalid move for {side}: {src} -> {dst}")

    # 4. Extract metadata (captured piece, check status)
    # We can inspect the history or last move info from engine if available
    # The engine returns boolean, but stores history.
    last_move_info = game.history[-1] if game.history else None
    
    meta = {
        "piece": last_move_info.moved if last_move_info else None,
        "captured": last_move_info.captured if last_move_info and last_move_info.captured != ENGINE_EMPTY else None,
        "check": game.status == GameStatus.CHECK,
        "checkmate": game.status == GameStatus.CHECKMATE
    }

    return _to_contract_board(game.board.board), meta

def check_endgame(
    board_state: List[List[str]], 
    side_to_move: str
) -> Tuple[str, Optional[str], Optional[str]]:
    """
    Check if game is finished.
    Returns: (status, winner, reason)
    """
    engine_board = _to_engine_board(board_state)
    game = EngineGame()
    game.board = Board(state=engine_board)
    game.turn = Color(side_to_move)
    game._update_status()

    st = game.status
    
    if st == GameStatus.ONGOING:
        return "ongoing", None, None
    elif st == GameStatus.CHECK:
        return "ongoing", None, None # Check is not endgame
    elif st == GameStatus.CHECKMATE:
        # If side_to_move is checkmated, the OTHER side wins
        winner = Color(side_to_move).opposite().value
        return "finished", winner, "checkmate"
    elif st == GameStatus.STALEMATE:
        # Xiangqi rule: Stalemate usually means loss for the one who cannot move?
        # Standard Chinese Chess rules: unable to move = loss.
        # Let's verify engine behavior or assume standard.
        # Engine generic 'STALEMATE' might need clarification.
        # Valid Xiangqi rules: Stuck = Loss (unlike Western Chess Draw).
        winner = Color(side_to_move).opposite().value
        return "finished", winner, "stalemate"
    
    return "ongoing", None, None

def pick_ai_move(
    board_state: List[List[str]], 
    ai_side: str, 
    difficulty: str
) -> Dict[str, list]:
    """
    AI picks a move.
    """
    engine_board = _to_engine_board(board_state)
    game = EngineGame()
    game.board = Board(state=engine_board)
    game.turn = Color(ai_side)
    game._update_status()

    if difficulty == 'hard':
        # Default time limits, 1.0s or whatever is appropriate, though ai_move_time defaults to 0.5s if not specified
        success = game.ai_move_time(time_limit_sec=1.0, max_depth=6)
    else:
        # Determine internal depth based on difficulty
        # easy=2, normal=3
        depth = 3 if difficulty == 'normal' else 2
        success = game.ai_move_minimax(depth=depth)
    
    if not success:
        raise RuntimeError("AI could not find a valid move (Checkmate/Stalemate?)")

    # Retrieve move from history
    last_move = game.history[-1]
    
    return {
        "from": [last_move.src[0], last_move.src[1]],
        "to": [last_move.dst[0], last_move.dst[1]]
    }

def list_legal_moves(
    board_state: List[List[str]], 
    side: str, 
    from_pos: Optional[Tuple[int, int]] = None
) -> List[Dict[str, list]]:
    """
    List legal moves.
    """
    from engine.rules.game_rules import generate_legal_moves
    
    engine_board = _to_engine_board(board_state)
    game = EngineGame()
    game.board = Board(state=engine_board)
    # Note: generate_legal_moves requires Board, not Game
    
    # But we need to check if moves leave self in check?
    # engine.rules.game_rules.generate_legal_moves DOES check `is_legal_move` which checks self-check.
    
    legal_moves = generate_legal_moves(game.board, side)
    
    result = []
    for m_src, m_dst in legal_moves:
        if from_pos and m_src != from_pos:
            continue
            
        result.append({
            "from": [m_src[0], m_src[1]],
            "to": [m_dst[0], m_dst[1]]
        })
        
    return result
