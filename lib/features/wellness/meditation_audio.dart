import 'package:just_audio/just_audio.dart';

abstract class MeditationAudio {
  Stream<Duration> get positions;
  Stream<Duration?> get durations;
  Stream<bool> get playing;
  Stream<void> get completed;
  Future<void> load(String asset);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();
  Future<void> dispose();
}

class AssetMeditationAudio implements MeditationAudio {
  final AudioPlayer _player = AudioPlayer();

  @override
  Stream<Duration> get positions => _player.positionStream;
  @override
  Stream<Duration?> get durations => _player.durationStream;
  @override
  Stream<bool> get playing => _player.playerStateStream.map((state) =>
      state.playing && state.processingState != ProcessingState.completed);
  @override
  Stream<void> get completed => _player.playerStateStream
      .where((state) => state.processingState == ProcessingState.completed)
      .map((_) {});

  @override
  Future<void> load(String asset) async {
    await _player.setAsset(asset);
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> dispose() => _player.dispose();
}
