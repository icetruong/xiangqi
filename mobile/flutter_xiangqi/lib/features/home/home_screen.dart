import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../new_game/new_game_controller.dart';
import 'home_controller.dart';
import 'widgets/continue_game_card.dart';
import 'widgets/game_selectors.dart';
import 'widgets/home_background.dart';
import 'widgets/start_button.dart';
import 'widgets/top_left_emblem_badge.dart';
import 'widgets/top_right_header_cluster.dart';
import 'widgets/xiangqi_title_block.dart';
import '../../shared/widgets/framed_panel.dart';
import '../../shared/widgets/ornament_divider.dart';
import '../../app/theme.dart';

/// The main start screen — a full-screen battle painting with a centered
/// parchment panel containing the game setup controls.
///
/// Visually matches the web version's layout:
///   background image → dark overlay → centered framed panel
///   → 将 emblem → XIANGQI title → dropdowns → START GAME button
///
/// Uses [NewGameController] for game creation so no logic is duplicated.
/// Uses [HomeController] to detect and display a resumable session.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newGameState  = ref.watch(newGameControllerProvider);
    final newGameCtrl   = ref.read(newGameControllerProvider.notifier);
    final homeState     = ref.watch(homeControllerProvider);

    // Navigate to game when creation succeeds.
    ref.listen(newGameControllerProvider.select((s) => s.creationState), (
      previous,
      next,
    ) {
      next.when(
        data: (game) {
          if (game?.gameId != null) {
            context.go('/game/${game!.gameId}');
          }
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create game: $error')),
          );
        },
        loading: () {},
      );
    });

    // Derive resumable session from homeController state (null while loading)
    final resumable = homeState.value?.resumableSession;

    return Scaffold(
      backgroundColor: XiangqiColors.darkBrown,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: battle painting + dark overlay ─────────────────────
          const HomeBackground(),

          // ── Layer 2: safe-area content ──────────────────────────────────
          SafeArea(
            child: Stack(
              children: [
                // ── Header Cluster (top-right) ────────────────────────────
                const Positioned(
                  top: 16,
                  right: 16,
                  child: TopRightHeaderCluster(),
                ),

                // ── Emblem (top-left) ─────────────────────────────────────
                const Positioned(
                  top: 16,
                  left: 16,
                  child: TopLeftEmblemBadge(),
                ),

                // ── Centered panel (max 400 px wide) ────────────────────
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: SingleChildScrollView(
                      // Horizontal 36 px gives the 14 px rod overhang room
                      // without clipping on narrow screens.
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 44,
                      ),
                      child: FramedPanel(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 32,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Title block ──────────────────────────────
                            const XiangqiTitleBlock(),

                            OrnamentDivider(verticalPadding: 20),

                            // ── Difficulty ───────────────────────────────
                            DifficultySelector(
                              value: newGameState.difficulty,
                              onChanged: newGameCtrl.setDifficulty,
                            ),

                            const SizedBox(height: 20),

                            // ── Side ─────────────────────────────────────
                            SideSelector(
                              value: newGameState.playerSide,
                              onChanged: newGameCtrl.setPlayerSide,
                            ),

                            const SizedBox(height: 28),

                            // ── START GAME button ─────────────────────────
                            StartButton(
                              isLoading: newGameState.creationState.isLoading,
                              onPressed: newGameState.creationState.isLoading
                                  ? null
                                  : newGameCtrl.createGame,
                            ),

                            // ── Continue Game card (shown only when valid) ─
                            if (resumable != null) ...[
                              const SizedBox(height: 16),
                              OrnamentDivider(verticalPadding: 8),
                              const SizedBox(height: 8),
                              ContinueGameCard(
                                session: resumable,
                                onContinue: () {
                                  context.go('/game/${resumable.gameId}');
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
