import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// A small music toggle button that plays/pauses `bgm.mp3`.
///
/// Gracefully handles [MissingPluginException] — the audio simply stays muted
/// if the platform hasn't loaded the plugin (e.g. first Flutter web hot-reload
/// after adding the dependency). A full `flutter run` restart is required to
/// activate audio on web for the first time.
class MusicControlButton extends StatefulWidget {
  const MusicControlButton({super.key});

  @override
  State<MusicControlButton> createState() => _MusicControlButtonState();
}

class _MusicControlButtonState extends State<MusicControlButton> {
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
      // MissingPluginException or platform error — degrade silently.
      if (mounted) setState(() => _audioAvailable = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: !_audioAvailable
          ? 'Music (restart app to enable)'
          : _isPlaying
              ? 'Mute music'
              : 'Play music',
      child: MouseRegion(
        cursor: _audioAvailable ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: XiangqiColors.bgDark.withAlpha(160),
              border: Border.all(
                color: _audioAvailable
                    ? XiangqiColors.gold.withAlpha(200)
                    : XiangqiColors.gold.withAlpha(80),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _audioAvailable
                  ? (_isPlaying ? Icons.music_note : Icons.music_off)
                  : Icons.music_off,
              color: _audioAvailable
                  ? XiangqiColors.goldLight
                  : XiangqiColors.gold.withAlpha(80),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
