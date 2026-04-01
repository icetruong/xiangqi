import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import 'repositories/game_repository.dart';
import 'repositories/game_repository_impl.dart';
import 'services/game_api_service.dart';

final gameApiServiceProvider = Provider<GameApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return GameApiService(dio);
});

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  final apiService = ref.watch(gameApiServiceProvider);
  return GameRepositoryImpl(apiService);
});
