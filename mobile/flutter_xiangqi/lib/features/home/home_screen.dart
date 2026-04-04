import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../new_game/new_game_controller.dart';
import 'widgets/game_selectors.dart';
import 'widgets/home_background.dart';
import 'widgets/music_control_button.dart';
import 'widgets/start_button.dart';
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
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(newGameControllerProvider);
    final controller = ref.read(newGameControllerProvider.notifier);

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
                // ── Music toggle (top-right) ──────────────────────────────
                const Positioned(
                  top: 12,
                  right: 16,
                  child: MusicControlButton(),
                ),

                // ── Centered panel (max 400 px wide) ────────────────────
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 48,
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
                              value: state.difficulty,
                              onChanged: controller.setDifficulty,
                            ),

                            const SizedBox(height: 20),

                            // ── Side ─────────────────────────────────────
                            SideSelector(
                              value: state.playerSide,
                              onChanged: controller.setPlayerSide,
                            ),

                            const SizedBox(height: 28),

                            // ── START GAME button ─────────────────────────
                            StartButton(
                              isLoading: state.creationState.isLoading,
                              onPressed: state.creationState.isLoading
                                  ? null
                                  : controller.createGame,
                            ),
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
