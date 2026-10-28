class AudioPreferences {
  const AudioPreferences({
    required this.musicEnabled,
    required this.effectsEnabled,
  });

  const AudioPreferences.defaults()
      : musicEnabled = true,
        effectsEnabled = true;

  factory AudioPreferences.fromMap(Map<String, Object?> values) {
    return AudioPreferences(
      musicEnabled: values[musicKey] is bool
          ? values[musicKey]! as bool
          : const AudioPreferences.defaults().musicEnabled,
      effectsEnabled: values[effectsKey] is bool
          ? values[effectsKey]! as bool
          : const AudioPreferences.defaults().effectsEnabled,
    );
  }

  static const String musicKey = 'audio_music_enabled';
  static const String effectsKey = 'audio_effects_enabled';

  final bool musicEnabled;
  final bool effectsEnabled;

  AudioPreferences copyWith({bool? musicEnabled, bool? effectsEnabled}) {
    return AudioPreferences(
      musicEnabled: musicEnabled ?? this.musicEnabled,
      effectsEnabled: effectsEnabled ?? this.effectsEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AudioPreferences &&
        other.musicEnabled == musicEnabled &&
        other.effectsEnabled == effectsEnabled;
  }

  @override
  int get hashCode => Object.hash(musicEnabled, effectsEnabled);
}
