import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/game/game_screen.dart';
import '../features/home/home_screen.dart';
import '../features/new_game/new_game_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/new-game',
        builder: (context, state) => const NewGameScreen(),
      ),
      GoRoute(
        path: '/game/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return GameScreen(gameId: id);
        },
      ),
    ],
  );
});
