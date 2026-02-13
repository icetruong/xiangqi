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

def apply_player_move(game_id, move_data):
    """
    Apply player move and update game state.
    Returns: (game, move_meta)
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

    # Save move to history
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

def process_ai_move(game_id):
    """
    Calculate and apply AI move.
    Designed to run in a background thread.
    """
    logger.info(f"Starting AI move for game {game_id}")
    try:
        game = Game.objects.get(id=game_id)
        
        if game.status != 'ongoing' or game.current_turn != game.ai_side:
            logger.warning(f"AI attempted move invalid state: {game.status}, Turn: {game.current_turn}")
            return

        # --- 3. AI Move ---
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
        
        # Save AI move
        _save_move(game, ai_move, game.ai_side, meta_ai)
        
        # Update Game State
        game.board_state = new_board_ai
        game.current_turn = game.player_side # Switch back to player
        
        # --- 4. Check Endgame (AI wins?) ---
        status, winner, reason = engine_adapter.check_endgame(new_board_ai, game.player_side)
        if status == 'finished':
            game.status = status
            game.winner = winner
            game.end_reason = reason
            
        game.save()
        logger.info(f"AI move completed for game {game_id}")
        
    except Exception as e:
        logger.error(f"AI Move Error for game {game_id}: {e}")

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
