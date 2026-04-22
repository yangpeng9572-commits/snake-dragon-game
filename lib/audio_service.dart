import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _bgMusicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer2 = AudioPlayer();
  bool _isMuted = false;
  bool _bgMusicPlaying = false;

  Future<void> init() async {
    await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _sfxPlayer.setVolume(0.8);
    await _sfxPlayer2.setVolume(0.8);
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _bgMusicPlayer.pause();
    } else {
      if (_bgMusicPlaying) {
        _bgMusicPlayer.resume();
      }
    }
  }

  bool get isMuted => _isMuted;

  // Play background music - exciting chase theme
  Future<void> playBgm() async {
    if (_isMuted) return;
    _bgMusicPlaying = true;
    await _bgMusicPlayer.play(AssetSource('sounds/bgm.wav'));
  }

  // Stop background music
  Future<void> stopBgm() async {
    _bgMusicPlaying = false;
    await _bgMusicPlayer.stop();
  }

  // Pause background music
  Future<void> pauseBgm() async {
    if (_bgMusicPlaying && !_isMuted) {
      await _bgMusicPlayer.pause();
    }
  }

  // Resume background music
  Future<void> resumeBgm() async {
    if (_bgMusicPlaying && !_isMuted) {
      await _bgMusicPlayer.resume();
    }
  }

  // Eat food sound - exciting high-pitched chirp
  Future<void> playEat() async {
    if (_isMuted) return;
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource('sounds/eat.wav'));
  }

  // Evolution sound - magical ascending scale
  Future<void> playEvolution() async {
    if (_isMuted) return;
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource('sounds/evolution.wav'));
  }

  // Game over sound - dramatic descending
  Future<void> playGameOver() async {
    if (_isMuted) return;
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource('sounds/gameover.wav'));
  }

  // Move sound - subtle tick
  Future<void> playMove() async {
    if (_isMuted) return;
    // Skip move sound to avoid audio spam during fast gameplay
    // Future: add a cooldown counter to play every N moves
  }

  // Power-up sound
  Future<void> playPowerUp() async {
    if (_isMuted) return;
    await _sfxPlayer.stop();
    await _sfxPlayer.play(AssetSource('sounds/powerup.wav'));
  }

  Future<void> dispose() async {
    await _bgMusicPlayer.dispose();
    await _sfxPlayer.dispose();
    await _sfxPlayer2.dispose();
  }
}
