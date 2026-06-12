import 'dart:convert';
import 'dart:typed_data';

/// يبني ملف WAV (PCM 16-bit) صالحاً من بيانات PCM خام (s16le).
///
/// نستخدمه على Linux لأن حزمة record (record_linux 2.1.0) فيها خلل يجعل
/// التسجيل المباشر إلى ملف يفشل عند الإيقاف ("streamSink is bound to a stream").
/// لذا نلتقط الـ PCM الخام عبر startStream ونغلّفه بترويسة WAV قياسية بأنفسنا.
Uint8List buildWavBytes(
  Uint8List pcm, {
  required int sampleRate,
  required int channels,
  int bitsPerSample = 16,
}) {
  final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
  final blockAlign = channels * bitsPerSample ~/ 8;
  final dataLen = pcm.length;

  final out = BytesBuilder();

  void writeAscii(String s) => out.add(ascii.encode(s));
  void writeUint32(int v) {
    final b = ByteData(4)..setUint32(0, v, Endian.little);
    out.add(b.buffer.asUint8List());
  }

  void writeUint16(int v) {
    final b = ByteData(2)..setUint16(0, v, Endian.little);
    out.add(b.buffer.asUint8List());
  }

  // RIFF chunk descriptor
  writeAscii('RIFF');
  writeUint32(36 + dataLen); // ChunkSize = 4 + (8 + 16) + (8 + dataLen)
  writeAscii('WAVE');

  // "fmt " sub-chunk
  writeAscii('fmt ');
  writeUint32(16); // Subchunk1Size for PCM
  writeUint16(1); // AudioFormat = 1 (PCM)
  writeUint16(channels);
  writeUint32(sampleRate);
  writeUint32(byteRate);
  writeUint16(blockAlign);
  writeUint16(bitsPerSample);

  // "data" sub-chunk
  writeAscii('data');
  writeUint32(dataLen);
  out.add(pcm);

  return out.toBytes();
}
