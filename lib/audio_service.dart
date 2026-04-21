import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _bgMusicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _isMuted = false;

  Future<void> init() async {
    await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _sfxPlayer.setVolume(0.7);
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _bgMusicPlayer.pause();
    } else {
      _bgMusicPlayer.resume();
    }
  }

  bool get isMuted => _isMuted;

  // Since we don't have actual sound files, we'll use system sounds
  // In a real app, you would add .mp3/.wav files to assets/sounds/
  Future<void> playEat() async {
    if (_isMuted) return;
    // Placeholder - in production, add eat.mp3 to assets/sounds/
    // await _sfxPlayer.play(AssetSource('sounds/eat.mp3'));
  }

  Future<void> playEvolution() async {
    if (_isMuted) return;
    // Placeholder - in production, add evolution.mp3 to assets/sounds/
    // await _sfxPlayer.play(AssetSource('sounds/evolution.mp3'));
  }

  Future<void> playGameOver() async {
    if (_isMuted) return;
    // Placeholder - in production, add gameover.mp3 to assets/sounds/
    // await _sfxPlayer.play(AssetSource('sounds/gameover.mp3'));
  }

  Future<void> playMove() async {
    if (_isMuted) return;
    // Light movement sound
    // await _sfxPlayer.play(AssetSource('sounds/move.mp3'));
  }

  Future<void> dispose() async {
    await _bgMusicPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
