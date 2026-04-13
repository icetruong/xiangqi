class AudioState {
  final bool isMuted;

  const AudioState({
    required this.isMuted,
  });

  AudioState copyWith({
    bool? isMuted,
  }) {
    return AudioState(
      isMuted: isMuted ?? this.isMuted,
    );
  }
}
