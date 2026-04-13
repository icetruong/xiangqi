import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_state.dart';
import 'game_sfx_mapper.dart';

class AudioService extends Notifier<AudioState> {
  static const String _mutedPrefKey = 'audio_is_muted';

  late final AudioPlayer _bgmPlayer;
  late final AudioPlayer _sfxPlayer;
  bool _audioAvailable = true;

  @override
  AudioState build() {
    _bgmPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();
    
    // Dispose players when service is disposed
    ref.onDispose(() {
      _bgmPlayer.dispose();
      _sfxPlayer.dispose();
    });

    // Start with default state, then restore from prefs
    _initFromPrefs();

    return const AudioState(isMuted: false);
  }

  Future<void> _initFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isMuted = prefs.getBool(_mutedPrefKey) ?? false;
      
      state = state.copyWith(isMuted: isMuted);
      
      if (!isMuted) {
        _playBgm();
      }
    } catch (e) {
      debugPrint('[AudioService] Failed to init from prefs: $e');
    }
  }

  /// Toggles the mute state. Affects BGM instantly and persists the choice.
  Future<void> toggleMute() async {
    try {
      final isNowMuted = !state.isMuted;
      
      // Persist choice directly
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_mutedPrefKey, isNowMuted);

      if (isNowMuted) {
        await _bgmPlayer.pause();
      } else {
        await _playBgm();
      }
      
      state = state.copyWith(isMuted: isNowMuted);
    } catch (e) {
      debugPrint('[AudioService] Toggle failed: $e');
      _audioAvailable = false;
    }
  }

  Future<void> _playBgm() async {
    if (!_audioAvailable) return;
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      // Ensures the correct volume or reset if it was paused
      await _bgmPlayer.play(AssetSource(GameSfxMapper.bgm));
    } catch (e) {
      debugPrint('[AudioService] Failed to play BGM (Graceful degrading): $e');
      _audioAvailable = false;
    }
  }

  /// Fire-and-forget SFX playback that avoids crashing on missing files.
  Future<void> playSfx(String assetPath) async {
    if (!_audioAvailable || state.isMuted) return;

    try {
      // Create a transient player for SFX to avoid cutting off earlier events if they happen closely,
      // but Audioplayers does support multiple sounds. Reusing _sfxPlayer will cut off currently playing SFX.
      // We will reuse _sfxPlayer to prevent overlapping chaotically.
      await _sfxPlayer.play(AssetSource(assetPath));
    } catch (e) {
      // Swallowing the error to gracefully handle missing dummy SFX assets.
      debugPrint('[AudioService] Failed playing SFX $assetPath: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Audio Providers
// ─────────────────────────────────────────────────────────────────────────────

final audioServiceProvider = NotifierProvider<AudioService, AudioState>(
  AudioService.new,
);
