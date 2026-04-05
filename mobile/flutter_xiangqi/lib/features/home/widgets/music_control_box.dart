import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// A faithful adaptation of the web's horizontal framed music control box.
/// Features a dark gradient, thin gold border, tiny corner markers, 
/// a left icon zone, and a visual right horizontal slider.
class MusicControlBox extends StatefulWidget {
  const MusicControlBox({super.key});

  @override
  State<MusicControlBox> createState() => _MusicControlBoxState();
}

class _MusicControlBoxState extends State<MusicControlBox> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  bool _audioAvailable = true;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (!_audioAvailable) return;
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.play(AssetSource('audio/bgm.mp3'));
      }
      if (mounted) setState(() => _isPlaying = !_isPlaying);
    } catch (_) {
      // Platform error — degrade silently.
      if (mounted) setState(() => _audioAvailable = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: !_audioAvailable
          ? 'Music unavailable'
          : _isPlaying
              ? 'Mute music'
              : 'Play music',
      child: GestureDetector(
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 26,
          width: 90,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2E150B), // Deep dark brown
                Color(0xFF140704), // Darker base
              ],
            ),
            border: Border.all(
              color: XiangqiColors.goldDark.withAlpha(220), // Antique gold
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000), // Shadow for floating effect
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // ── Left Icon Block ──────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 24,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: XiangqiColors.goldDark.withAlpha(120),
                        width: 1.0,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _audioAvailable
                        ? (_isPlaying ? Icons.music_note : Icons.music_off)
                        : Icons.volume_off,
                    color: _audioAvailable
                        ? XiangqiColors.goldLight
                        : XiangqiColors.gold.withAlpha(80),
                    size: 14,
                  ),
                ),
              ),
              
              // ── Right Slider Area ─────────────────────────────────────────
              Positioned(
                left: 24,
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxLeft = constraints.maxWidth - 4; // thumb width is 4
                        return Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            // Thin Horizontal Line
                            Container(
                              height: 1,
                              color: XiangqiColors.goldDark.withAlpha(160),
                            ),
                            // Vertical Gold Thumb
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOutBack,
                              left: _isPlaying ? maxLeft : 0.0,
                              child: Container(
                                width: 4,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: XiangqiColors.goldLight,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 2,
                                      offset: Offset(1, 0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ── Tiny Corner Ornaments ─────────────────────────────────────
              _buildCornerMarker(Alignment.topLeft),
              _buildCornerMarker(Alignment.topRight),
              _buildCornerMarker(Alignment.bottomLeft),
              _buildCornerMarker(Alignment.bottomRight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCornerMarker(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 3,
        height: 3,
        color: XiangqiColors.goldLight.withAlpha(150),
      ),
    );
  }
}
