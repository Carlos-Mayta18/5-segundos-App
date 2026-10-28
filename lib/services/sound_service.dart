import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Motor de Audio y Vibración 100% Offline.
/// Sintetiza ondas acústicas PCM (.wav) en memoria para garantizar
/// presión sensorial (tic-tac acelerado, campana de fin de tiempo,
/// acierto y fallo) sin depender de conexión ni archivos externos.
class SoundService {
  static final SoundService instance = SoundService._internal();
  SoundService._internal();

  bool soundEnabled = true;
  bool hapticsEnabled = true;

  final AudioPlayer _tickPlayer = AudioPlayer();
  final AudioPlayer _fxPlayer = AudioPlayer();

  late final Uint8List _tickLowWav;
  late final Uint8List _tickMidWav;
  late final Uint8List _tickHighWav;
  late final Uint8List _tickPanicWav;
  late final Uint8List _bellAlarmWav;
  late final Uint8List _successChimeWav;
  late final Uint8List _failBuzzWav;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _tickLowWav = _generateToneWav(freq: 720, durationMs: 55, volume: 0.55);
    _tickMidWav = _generateToneWav(freq: 920, durationMs: 55, volume: 0.65);
    _tickHighWav = _generateToneWav(freq: 1180, durationMs: 50, volume: 0.78);
    _tickPanicWav = _generateToneWav(freq: 1480, durationMs: 45, volume: 0.90);
    _bellAlarmWav = _generateBellAlarmWav();
    _successChimeWav = _generateChordWav([523.25, 659.25, 783.99, 1046.50], 110);
    _failBuzzWav = _generateChordWav([240.0, 180.0], 200, sawWave: true);
    _initialized = true;
  }

  /// Dispara un pulso de tic-tac cuya frecuencia sube conforme queda menos tiempo.
  /// [progress] va de 1.0 (5.0s restantes) a 0.0 (0.0s restantes).
  Future<void> playCountdownTick(double progress) async {
    if (!_initialized) await init();

    if (hapticsEnabled) {
      if (progress < 0.35) {
        HapticFeedback.heavyImpact();
      } else if (progress < 0.7) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }

    if (!soundEnabled) return;

    try {
      Uint8List wavBytes;
      if (progress > 0.70) {
        wavBytes = _tickLowWav;
      } else if (progress > 0.40) {
        wavBytes = _tickMidWav;
      } else if (progress > 0.20) {
        wavBytes = _tickHighWav;
      } else {
        wavBytes = _tickPanicWav;
      }
      await _tickPlayer.stop();
      await _tickPlayer.play(BytesSource(wavBytes, mimeType: 'audio/wav'));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Campana / Alarma intensa cuando se agotan los 5 segundos.
  Future<void> playTimeUpBell() async {
    if (!_initialized) await init();

    if (hapticsEnabled) {
      HapticFeedback.vibrate();
    }

    if (!soundEnabled) return;

    try {
      await _fxPlayer.stop();
      await _fxPlayer.play(BytesSource(_bellAlarmWav, mimeType: 'audio/wav'));
    } catch (_) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  /// Sonido cuando el grupo aprueba la respuesta (+1 punto).
  Future<void> playSuccess() async {
    if (!_initialized) await init();

    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }

    if (!soundEnabled) return;

    try {
      await _fxPlayer.stop();
      await _fxPlayer.play(BytesSource(_successChimeWav, mimeType: 'audio/wav'));
    } catch (_) {}
  }

  /// Sonido cuando el jugador falla el reto de 5 segundos.
  Future<void> playFail() async {
    if (!_initialized) await init();

    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }

    if (!soundEnabled) return;

    try {
      await _fxPlayer.stop();
      await _fxPlayer.play(BytesSource(_failBuzzWav, mimeType: 'audio/wav'));
    } catch (_) {}
  }

  /// Genera un archivo WAV PCM de 16 bits en memoria para un tono corto con envolvente.
  Uint8List _generateToneWav({
    required double freq,
    required int durationMs,
    double volume = 0.7,
  }) {
    const int sampleRate = 22050;
    final int numSamples = (sampleRate * durationMs / 1000).round();
    final ByteData data = ByteData(44 + numSamples * 2);

    _writeWavHeader(data, sampleRate, numSamples);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      // Envolvente percusiva exponencial para sonar como tic-tac de reloj/bomba
      final double envelope = exp(-6.0 * (i / numSamples));
      final double wave = sin(2 * pi * freq * t) + 0.35 * sin(2 * pi * (freq * 2.0) * t);
      final int sample = (wave * envelope * volume * 24000).clamp(-32767, 32767).toInt();
      data.setInt16(44 + i * 2, sample, Endian.little);
    }

    return data.buffer.asUint8List();
  }

  /// Genera una campana / timbre doble intenso para el fin de los 5 segundos.
  Uint8List _generateBellAlarmWav() {
    const int sampleRate = 22050;
    const int durationMs = 680;
    final int numSamples = (sampleRate * durationMs / 1000).round();
    final ByteData data = ByteData(44 + numSamples * 2);

    _writeWavHeader(data, sampleRate, numSamples);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      // Timbre metálico (frecuencias inarmónicas de campana + vibrato rápido)
      final double ringMod = (i % 1800 < 900) ? 1.0 : 0.45;
      final double env = exp(-2.5 * (i / numSamples));
      final double bell = 0.55 * sin(2 * pi * 880 * t) +
          0.30 * sin(2 * pi * 1320 * t) +
          0.15 * sin(2 * pi * 1760 * t);
      final int sample = (bell * env * ringMod * 28000).clamp(-32767, 32767).toInt();
      data.setInt16(44 + i * 2, sample, Endian.little);
    }

    return data.buffer.asUint8List();
  }

  /// Genera una secuencia de notas para acierto o fallo.
  Uint8List _generateChordWav(
    List<double> notes,
    int noteDurationMs, {
    bool sawWave = false,
  }) {
    const int sampleRate = 22050;
    final int samplesPerNote = (sampleRate * noteDurationMs / 1000).round();
    final int totalSamples = samplesPerNote * notes.length;
    final ByteData data = ByteData(44 + totalSamples * 2);

    _writeWavHeader(data, sampleRate, totalSamples);

    for (int n = 0; n < notes.length; n++) {
      final double freq = notes[n];
      for (int i = 0; i < samplesPerNote; i++) {
        final int globalIdx = n * samplesPerNote + i;
        final double t = i / sampleRate;
        final double env = exp(-3.0 * (i / samplesPerNote));
        double wave;
        if (sawWave) {
          wave = 2.0 * (t * freq - (t * freq + 0.5).floorToDouble());
        } else {
          wave = sin(2 * pi * freq * t);
        }
        final int sample = (wave * env * 22000).clamp(-32767, 32767).toInt();
        data.setInt16(44 + globalIdx * 2, sample, Endian.little);
      }
    }

    return data.buffer.asUint8List();
  }

  void _writeWavHeader(ByteData data, int sampleRate, int numSamples) {
    final int byteRate = sampleRate * 2;
    final int dataSize = numSamples * 2;
    // "RIFF"
    data.setUint8(0, 0x52);
    data.setUint8(1, 0x49);
    data.setUint8(2, 0x46);
    data.setUint8(3, 0x46);
    data.setUint32(4, 36 + dataSize, Endian.little);
    // "WAVE"
    data.setUint8(8, 0x57);
    data.setUint8(9, 0x41);
    data.setUint8(10, 0x56);
    data.setUint8(11, 0x45);
    // "fmt "
    data.setUint8(12, 0x66);
    data.setUint8(13, 0x6D);
    data.setUint8(14, 0x74);
    data.setUint8(15, 0x20);
    data.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    data.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    data.setUint16(22, 1, Endian.little); // NumChannels (1 = mono)
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, byteRate, Endian.little);
    data.setUint16(32, 2, Endian.little); // BlockAlign
    data.setUint16(34, 16, Endian.little); // BitsPerSample
    // "data"
    data.setUint8(36, 0x64);
    data.setUint8(37, 0x61);
    data.setUint8(38, 0x74);
    data.setUint8(39, 0x61);
    data.setUint32(40, dataSize, Endian.little);
  }
}
