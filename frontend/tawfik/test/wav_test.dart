import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tawfik/utils/wav.dart';

void main() {
  test('buildWavBytes produces a valid 44.1kHz mono 16-bit WAV', () async {
    const sampleRate = 44100;
    const channels = 1;
    const seconds = 3;

    // اصنع PCM لموجة جيبية 150Hz (s16le) لمحاكاة صوت مستمر.
    final frames = sampleRate * seconds;
    final pcm = Uint8List(frames * 2);
    final view = ByteData.view(pcm.buffer);
    for (var i = 0; i < frames; i++) {
      final sample = (sin(2 * pi * 150 * i / sampleRate) * 0.6 * 32767).round();
      view.setInt16(i * 2, sample, Endian.little);
    }

    final wav = buildWavBytes(pcm, sampleRate: sampleRate, channels: channels);

    // الترويسة الأساسية.
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(String.fromCharCodes(wav.sublist(12, 16)), 'fmt ');
    expect(wav.length, 44 + pcm.length);

    // numChannels و sampleRate في مواضعهما القياسية.
    final header = ByteData.view(wav.buffer);
    expect(header.getUint16(22, Endian.little), channels);
    expect(header.getUint32(24, Endian.little), sampleRate);
    expect(header.getUint16(34, Endian.little), 16); // bitsPerSample

    // تحقّق فعلي عبر ffprobe أن الملف صالح وقابل للقراءة.
    final dir = await Directory.systemTemp.createTemp('wav_test');
    final file = File('${dir.path}/test.wav');
    await file.writeAsBytes(wav, flush: true);

    final probe = await Process.run('ffprobe', [
      '-v', 'error',
      '-show_entries', 'stream=codec_name,sample_rate,channels',
      '-of', 'default=noprint_wrappers=1',
      file.path,
    ]);

    final out = probe.stdout.toString();
    expect(probe.exitCode, 0, reason: 'ffprobe stderr: ${probe.stderr}');
    expect(out, contains('codec_name=pcm_s16le'));
    expect(out, contains('sample_rate=44100'));
    expect(out, contains('channels=1'));

    await dir.delete(recursive: true);
  });
}
