import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_preferences.dart';

enum GameSound {
  correct('audio/correct.wav'),
  incorrect('audio/incorrect.wav'),
  victory('audio/victory.wav'),
  defeat('audio/defeat.wav');

  const GameSound(this.assetPath);

  final String assetPath;

  static GameSound forAnswer({required bool isCorrect}) =>
      isCorrect ? GameSound.correct : GameSound.incorrect;

  static GameSound forResult({required bool celebrates}) =>
      celebrates ? GameSound.victory : GameSound.defeat;
}

class AppAudioController extends ChangeNotifier with WidgetsBindingObserver {
  AppAudioController._();

  static final AppAudioController instance = AppAudioController._();

  static const double _musicVolume = 0.22;
  static const double _effectsVolume = 0.75;

  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'ivoire_music');
  final Map<GameSound, AudioPlayer> _effectPlayers = <GameSound, AudioPlayer>{};

  AudioPreferences _preferences = const AudioPreferences.defaults();
  bool _initialized = false;
  bool _inForeground = true;

  bool get musicEnabled => _preferences.musicEnabled;
  bool get effectsEnabled => _preferences.effectsEnabled;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);

    final SharedPreferences store = await SharedPreferences.getInstance();
    _preferences = AudioPreferences.fromMap(<String, Object?>{
      AudioPreferences.musicKey: store.get(AudioPreferences.musicKey),
      AudioPreferences.effectsKey: store.get(AudioPreferences.effectsKey),
    });
    notifyListeners();

    await _guard(() async {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(_musicVolume);
      for (final GameSound sound in GameSound.values) {
        final AudioPlayer player = AudioPlayer(
          playerId: 'ivoire_effect_${sound.name}',
        );
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(_effectsVolume);
        await player.setSource(AssetSource(sound.assetPath));
        _effectPlayers[sound] = player;
      }
    });

    if (musicEnabled) await _startMusic();
  }

  Future<void> setMusicEnabled(bool enabled) async {
    if (_preferences.musicEnabled == enabled) return;
    _preferences = _preferences.copyWith(musicEnabled: enabled);
    notifyListeners();
    final SharedPreferences store = await SharedPreferences.getInstance();
    await store.setBool(AudioPreferences.musicKey, enabled);
    if (enabled && _inForeground) {
      await _startMusic();
    } else {
      await _guard(_musicPlayer.pause);
    }
  }

  Future<void> setEffectsEnabled(bool enabled) async {
    if (_preferences.effectsEnabled == enabled) return;
    _preferences = _preferences.copyWith(effectsEnabled: enabled);
    notifyListeners();
    final SharedPreferences store = await SharedPreferences.getInstance();
    await store.setBool(AudioPreferences.effectsKey, enabled);
  }

  Future<void> playEffect(GameSound sound) async {
    if (!effectsEnabled) return;
    final AudioPlayer? player = _effectPlayers[sound];
    if (player == null) return;
    await _guard(() async {
      await player.stop();
      await player.resume();
    });
  }

  Future<void> _startMusic() async {
    if (!musicEnabled || !_inForeground) return;
    await _guard(() async {
      if (_musicPlayer.source == null) {
        await _musicPlayer.play(AssetSource('audio/background.wav'));
      } else {
        await _musicPlayer.resume();
      }
    });
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('AUDIO ERROR: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state == AppLifecycleState.resumed;
    if (_inForeground) {
      _startMusic();
    } else {
      _guard(_musicPlayer.pause);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _musicPlayer.dispose();
    for (final AudioPlayer player in _effectPlayers.values) {
      player.dispose();
    }
    _effectPlayers.clear();
    super.dispose();
  }
}
