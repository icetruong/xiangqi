import logging
import threading
import time

from django.db import close_old_connections

from games.models import Game, Move
from games.services import engine_adapter

logger = logging.getLogger(__name__)


def start_ai_worker(game_id, delay_seconds: float = 0.1) -> None:
    """Start the background AI worker in one place for easier maintenance."""
    threading.Thread(
        target=process_ai_move,
        args=(game_id, delay_seconds),
        daemon=True,
        name=f"xiangqi-ai-{game_id}",
    ).start()


def create_new_game(difficulty='normal', player_side='r', ai_side='b') -> Game:
    """Initialize a new game with default board state."""
    board_state = engine_adapter.init_game_state()

    game = Game.objects.create(
        board_state=board_state,
        current_turn='r',
        status='ongoing',
        difficulty=difficulty,
        player_side=player_side,
        ai_side=ai_side,
    )

    # If the player chooses black, red AI makes the opening move asynchronously.
    if player_side == 'b':
        start_ai_worker(game.id)

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

    try:
        new_board, meta = engine_adapter.apply_move(
            game.board_state,
            game.player_side,
            move_data,
        )
    except ValueError as e:
        raise ValueError(str(e))

    _save_move(game, move_data, game.player_side, meta)

    game.board_state = new_board
    game.current_turn = game.ai_side
    game.save()

    status, winner, reason = engine_adapter.check_endgame(new_board, game.ai_side)
    if status == 'finished':
        game.status = status
        game.winner = winner
        game.end_reason = reason
        game.save()

    return game, meta


def process_ai_move(game_id, delay_seconds: float = 0.1):
    """
    Calculate and apply AI move.
    Designed to run in a background thread.
    """
    close_old_connections()

    try:
        # Give the HTTP response a brief head start before spending CPU on search.
        time.sleep(delay_seconds)

        logger.info("Starting AI move for game %s", game_id)
        game = Game.objects.get(id=game_id)

        if game.status != 'ongoing' or game.current_turn != game.ai_side:
            logger.warning(
                "AI attempted move in invalid state for game %s: status=%s turn=%s",
                game_id,
                game.status,
                game.current_turn,
            )
            return

        ai_move = engine_adapter.pick_ai_move(
            game.board_state,
            game.ai_side,
            game.difficulty,
        )

        new_board_ai, meta_ai = engine_adapter.apply_move(
            game.board_state,
            game.ai_side,
            ai_move,
        )

        _save_move(game, ai_move, game.ai_side, meta_ai)

        game.board_state = new_board_ai
        game.current_turn = game.player_side

        status, winner, reason = engine_adapter.check_endgame(new_board_ai, game.player_side)
        if status == 'finished':
            game.status = status
            game.winner = winner
            game.end_reason = reason

        game.save()
        logger.info("AI move completed for game %s", game_id)

    except Exception:
        logger.exception("AI move error for game %s", game_id)
    finally:
        close_old_connections()


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
        captured=meta.get('captured', None),
    )
