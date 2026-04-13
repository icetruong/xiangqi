from django.urls import path
from . import views, api_views

app_name = 'games'

urlpatterns = [
    # Template Views
    path('', views.index, name='index'),
    path('lobby/', views.lobby, name='lobby'),
    path('game/<uuid:game_id>/', views.game_board, name='game_board'),
    path('room/<str:room_code>/', views.room_board, name='room_board'),

    # API Endpoints
    path('api/games/', api_views.create_game, name='api_create_game'),
    path('api/games/<uuid:game_id>/', api_views.game_detail, name='api_game_detail'),
    path('api/games/<uuid:game_id>/move', api_views.make_move, name='api_make_move'),
    path('api/games/<uuid:game_id>/resign', api_views.resign_game, name='api_resign_game'),
    path('api/games/<uuid:game_id>/draw', api_views.draw_game, name='api_draw_game'),

    # Room Endpoints
    path('api/rooms/create/', api_views.create_room, name='api_create_room'),
    path('api/rooms/<str:room_code>/join/', api_views.join_room, name='api_join_room'),
    path('api/rooms/<str:room_code>/', api_views.room_detail, name='api_room_detail'),
]
