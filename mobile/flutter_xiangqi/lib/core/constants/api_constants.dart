class ApiConstants {
  static const String baseUrl = 'https://YOUR-RAILWAY-DOMAIN';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // Endpoints
  static const String games = '/api/games/';
  static String gameDetail(String gameId) => '/api/games/$gameId/';
  static String gameMove(String gameId) => '/api/games/$gameId/move/';
  static String gameResign(String gameId) => '/api/games/$gameId/resign/';
  static String gameDraw(String gameId) => '/api/games/$gameId/draw/';
  static String gameLegalMoves(String gameId, int row, int col) => '/api/games/$gameId/legal-moves?from=$row,$col';
}
