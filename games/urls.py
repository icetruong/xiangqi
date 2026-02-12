from django.urls import path
from . import views, api_views

app_name = 'games'

urlpatterns = [
    # Template Views
    path('game/<uuid:game_id>/', views.game_board, name='game_board'),

    # API Endpoints
    path('api/games/', api_views.create_game, name='api_create_game'),
    path('api/games/<uuid:game_id>/', api_views.game_detail, name='api_game_detail'),
    path('api/games/<uuid:game_id>/move', api_views.make_move, name='api_make_move'),
]
