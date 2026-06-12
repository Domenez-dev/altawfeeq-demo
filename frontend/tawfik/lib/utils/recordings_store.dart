import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// إدارة ملفات التسجيلات المحفوظة محلياً على الجهاز.
///
/// نُسمّي ملف كل تسجيل باسم الجلسة (`session_<id>.wav`) بعد نجاح التحليل، حتى
/// نتمكن لاحقاً من إيجاد تسجيل أي جلسة قديمة وتشغيله — دون الحاجة إلى قاعدة بيانات.

Future<Directory> recordingsDir() async {
  final dir = await getApplicationDocumentsDirectory();
  final rec = Directory(p.join(dir.path, 'recordings'));
  if (!await rec.exists()) {
    await rec.create(recursive: true);
  }
  return rec;
}

Future<String> sessionRecordingPath(int sessionId) async {
  final dir = await recordingsDir();
  return p.join(dir.path, 'session_$sessionId.wav');
}

/// يُعيد ملف تسجيل الجلسة إن كان موجوداً على هذا الجهاز، وإلا null.
Future<File?> sessionRecordingFile(int sessionId) async {
  try {
    final file = File(await sessionRecordingPath(sessionId));
    return await file.exists() ? file : null;
  } catch (_) {
    return null;
  }
}

/// يحذف تسجيل الجلسة محلياً (إن وُجد). لا يرمي استثناءً أبداً.
Future<void> deleteSessionRecording(int sessionId) async {
  try {
    final file = await sessionRecordingFile(sessionId);
    if (file != null) await file.delete();
  } catch (_) {
    // تجاهل: غياب الملف لا يجب أن يُفشل عملية الحذف.
  }
}
