from django.shortcuts import render, get_object_or_404, redirect
from django.views.decorators.csrf import ensure_csrf_cookie
from django.http import JsonResponse
from django.views.decorators.cache import cache_control
from django.templatetags.static import static
from games.models import Game, Room
from games.services import game_service
from games.api_views import _get_in_check
import json

# ── PWA Views ──────────────────────────────────────────────────────────────

@cache_control(max_age=86400)
def pwa_manifest(request):
    """Serve the Web App Manifest at /manifest.json"""
    base = request.build_absolute_uri('/').rstrip('/')
    data = {
        "name": "Cờ Tướng Online",
        "short_name": "Cờ Tướng",
        "description": "Chơi cờ tướng online với bạn bè hoặc đấu với AI",
        "start_url": "/",
        "display": "standalone",
        "orientation": "portrait-primary",
        "theme_color": "#2a120b",
        "background_color": "#0a0503",
        "lang": "vi",
        "icons": [
            {
                "src": base + static("games/img/icon-192.png"),
                "sizes": "192x192",
                "type": "image/png",
                "purpose": "any maskable"
            },
            {
                "src": base + static("games/img/icon-512.png"),
                "sizes": "512x512",
                "type": "image/png",
                "purpose": "any maskable"
            }
        ],
        "screenshots": [],
        "categories": ["games", "entertainment"]
    }
    return JsonResponse(data)


def service_worker(request):
    """Serve the Service Worker at /sw.js (must be at root scope)"""
    response = render(request, 'games/sw.js', content_type='application/javascript')
    response['Service-Worker-Allowed'] = '/'
    response['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    return response


def offline_page(request):
    """PWA offline fallback page"""
    return render(request, 'games/offline.html')


@ensure_csrf_cookie
def index(request):
    if request.method == "POST":
        # Create new game logic directly in view for simplicity, or call service
        difficulty = request.POST.get('difficulty', 'normal')
        player_side = request.POST.get('player_side', 'r')
        ai_side = 'b' if player_side == 'r' else 'r'
        
        game = game_service.create_new_game(
            difficulty=difficulty,
            player_side=player_side,
            ai_side=ai_side
        )
        return redirect('games:game_board', game_id=game.id)
        
    return render(request, 'games/index.html')

@ensure_csrf_cookie
def game_board(request, game_id):
    # Verify game exists
    game = get_object_or_404(Game, id=game_id)
    
    legal_moves = []
    if game.status == 'ongoing' and game.current_turn == game.player_side:
        from games.services import engine_adapter
        legal_moves = engine_adapter.list_legal_moves(game.board_state, game.player_side)
    
    # Get last move
    last_move = game.moves.last()
    last_move_data = None
    if last_move:
        last_move_data = {
            "from": [last_move.from_row, last_move.from_col],
            "to": [last_move.to_row, last_move.to_col],
            "piece": last_move.piece,
            "captured": last_move.captured
        }

    in_check = _get_in_check(game.board_state)

    all_moves = list(game.moves.all().order_by('ply'))
    history_data = [
        {
            "ply": m.ply,
            "side": m.side,
            "from": [m.from_row, m.from_col],
            "to": [m.to_row, m.to_col],
            "piece": m.piece
        }
        for m in all_moves
    ]

    return render(request, 'games/game.html', {
        'game': game, 
        'legal_moves': json.dumps(legal_moves),
        'last_move': json.dumps(last_move_data),
        'in_check': json.dumps(in_check),
        'move_history': json.dumps(history_data)
    })

def lobby(request):
    return render(request, 'games/lobby.html')

def room_board(request, room_code):
    room = Room.objects.filter(room_code=room_code).first()
    if not room:
        return redirect('games:index')
    

    # Use Django session key as the stable player identifier.
    # This is server-generated and unique per browser session.
    if not request.session.session_key:
        request.session.create()
    identifier = request.session.session_key

    # Auto-join: register this player in the room if there is an empty slot.
    from games.services import room_service
    try:
        room, player_side = room_service.join_room(room_code, identifier)
    except Exception:
        # If room is full or any error, derive side from existing data.
        player_side = 'spectator'
        if room.player_red == identifier:
            player_side = 'r'
        elif room.player_black == identifier:
            player_side = 'b'

    game = room.game
    context = {
        'room': room,
        'game': game,
        'player_id': identifier,
        'player_side': player_side,
        'initial_board_state': json.dumps(game.board_state),
        'initial_current_turn': json.dumps(game.current_turn),
        'room_player_red': json.dumps(room.player_red),
        'room_player_black': json.dumps(room.player_black),
    }
    return render(request, 'games/room.html', context)
