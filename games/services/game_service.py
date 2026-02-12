from django.core.exceptions import ValidationError
from games.models import Game, Move
from games.services import engine_adapter
import logging

logger = logging.getLogger(__name__)

def create_new_game(difficulty='normal', player_side='r', ai_side='b') -> Game:
    """Initialize a new game with default board state."""
    board_state = engine_adapter.init_game_state()
    
    game = Game.objects.create(
        board_state=board_state,
        current_turn='r',
        status='ongoing',
        difficulty=difficulty,
        player_side=player_side,
        ai_side=ai_side
    )
    return game

def handle_player_move(game_id, move_data):
    """
    Handle player move:
    1. Validate & Apply player move
    2. Check endgame
    3. If ongoing, trigger AI move
    4. Check endgame
    5. Return updated game state
    """
    try:
        game = Game.objects.get(id=game_id)
    except Game.DoesNotExist:
        raise ValueError("Game not found")

    if game.status != 'ongoing':
        raise ValueError("Game is finished")

    if game.current_turn != game.player_side:
        raise ValueError("Not your turn")

    # --- 1. Player Move ---
    try:
        new_board, meta = engine_adapter.apply_move(
            game.board_state, 
            game.player_side, 
            move_data
        )
    except ValueError as e:
        raise ValueError(str(e))

    # Save move to history (optional but recommended)
    _save_move(game, move_data, game.player_side, meta)

    # Update Game State
    game.board_state = new_board
    game.current_turn = game.ai_side # Switch turn
    game.save()

    # --- 2. Check Endgame (Player wins?) ---
    status, winner, reason = engine_adapter.check_endgame(new_board, game.ai_side)
    if status == 'finished':
        game.status = status
        game.winner = winner
        game.end_reason = reason
        game.save()
        return game, meta

    # --- 3. AI Move ---
    ai_move_meta = None
    try:
        ai_move = engine_adapter.pick_ai_move(
            game.board_state, 
            game.ai_side, 
            game.difficulty
        )
        
        # Apply AI move
        new_board_ai, meta_ai = engine_adapter.apply_move(
            game.board_state, 
            game.ai_side, 
            ai_move
        )
        
        ai_move_meta = meta_ai
        # Save AI move
        _save_move(game, ai_move, game.ai_side, meta_ai)
        
        # Update Game State
        game.board_state = new_board_ai
        game.current_turn = game.player_side # Switch back to player
        game.save()
        
    except Exception as e:
        logger.error(f"AI Move Error: {e}")
        # If AI fails, maybe we just leave turn as AI? 
        # Or auto-resign AI? For now, just log and keep game ongoing.
        pass

    # --- 4. Check Endgame (AI wins?) ---
    # new_board_ai might be undefined if AI failed
    if ai_move_meta:
        status, winner, reason = engine_adapter.check_endgame(game.board_state, game.player_side)
        if status == 'finished':
            game.status = status
            game.winner = winner
            game.end_reason = reason
            game.save()

    # Return game state and LAST move (which is AI's move if it moved, or Player's if game ended)
    last_move_info = ai_move_meta if ai_move_meta else meta
    # We should probably return both? 
    # Contract says "last_move". Usually the UI just wants to highlight the last action.
    # If the user moved, and then AI moved, the UI wants to see AI's move result.
    
    return game, last_move_info

def _save_move(game, move_data, side, meta):
    """Helper to save Move model."""
    ply = game.moves.count() + 1
    Move.objects.create(
        game=game,
        ply=ply,
        side=side,
        from_row=move_data['from'][0],
        from_col=move_data['from'][1],
        to_row=move_data['to'][0],
        to_col=move_data['to'][1],
        piece=meta.get('piece', ''),
        captured=meta.get('captured', None)
    )
