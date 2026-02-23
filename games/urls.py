from django.urls import path
from . import views, api_views

app_name = 'games'

urlpatterns = [
    # Template Views
    path('', views.index, name='index'),
    path('game/<uuid:game_id>/', views.game_board, name='game_board'),

    # API Endpoints
    path('api/games/', api_views.create_game, name='api_create_game'),
    path('api/games/<uuid:game_id>/', api_views.game_detail, name='api_game_detail'),
    path('api/games/<uuid:game_id>/move', api_views.make_move, name='api_make_move'),
    path('api/games/<uuid:game_id>/resign', api_views.resign_game, name='api_resign_game'),
    path('api/games/<uuid:game_id>/draw', api_views.draw_game, name='api_draw_game'),
]
