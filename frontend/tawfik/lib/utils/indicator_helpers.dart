import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

Color statusColor(String status) {
  switch (status) {
    case 'جيد':
      return AppTheme.success;
    case 'متوسط':
      return AppTheme.warning;
    default:
      return AppTheme.error; // ضعيف
  }
}

IconData indicatorIcon(String name) {
  if (name.contains('HNR') || name.contains('التوافقي')) return Icons.hearing_rounded;
  if (name.contains('Jitter') || name.contains('Shimmer') || name.contains('اضطراب')) {
    return Icons.show_chart_rounded;
  }
  if (name.contains('الطبقة') || name.contains('تباين')) return Icons.bar_chart_rounded;
  if (name.contains('المدة')) return Icons.timer_outlined;
  if (name.contains('شدة')) return Icons.volume_up_rounded;
  return Icons.graphic_eq_rounded;
}

// ════════════════════════════════════════════════════════════════════════════
// المؤشرات الصوتية السبعة المقاسة على الحرف الممدود "آآآ" (+ مؤشرات زمنية مرجعية).
// هذه الأسماء يجب أن تطابق ما يرسله الخادم (backend/services/indicators.py).
// ════════════════════════════════════════════════════════════════════════════

const List<String> kIndicatorNames = [
  'الطبقة الصوتية',
  'تباين الطبقة (F0 SD)',
  'الاضطراب (Jitter)',
  'اضطراب الشدة (Shimmer)',
  'نسبة HNR',
  'شدة الصوت',
  'المدة',
];

/// مؤشر صوتي مرجعي: اسمه، فئته، وصفه، مجاله الطبيعي، وقاعدة القرار المبنية عليه.
class VocalBiomarker {
  final String name;
  final String category;
  final String description;
  final String normalRange;
  final String decisionRule;

  /// `true` إذا كان يُقاس فعلياً من تسجيل الحرف الممدود "آآآ".
  /// `false` إذا كان مرجعياً فقط (يحتاج كلاماً متصلاً: جملة، وليس حرفاً ممدوداً).
  final bool measured;

  const VocalBiomarker({
    required this.name,
    required this.category,
    required this.description,
    required this.normalRange,
    required this.decisionRule,
    required this.measured,
  });
}

// أسماء الفئات (الكُتل الثلاث في المرجع العلمي + مؤشرات مساعدة).
const String kCatTemporal = 'التوقيت الزمني';
const String kCatPhonation = 'إنتاج الصوت (Phonation)';
const String kCatProsody = 'الإيقاع والتنغيم (Prosody)';
const String kCatExtra = 'مؤشرات مساعدة';

/// كل المؤشرات الصوتية العشرة بقيمها المرجعية وقواعد قرارها.
const List<VocalBiomarker> kBiomarkers = [
  // ─── Bloc 1 — التوقيت الزمني (مرجعي فقط: يحتاج كلاماً متصلاً) ───────────────
  VocalBiomarker(
    name: 'معدل الكلام (Speech Rate)',
    category: kCatTemporal,
    description: 'سرعة إنتاج الكلام (عدد المقاطع في الثانية). يحتاج نطق جملة وليس حرفاً ممدوداً.',
    normalRange: 'سليم: 3.5 – 5.5 مقطع/ثانية (≈ 120 – 160 كلمة/دقيقة)',
    decisionRule: 'اشتباه ضعف إدراكي بسيط إذا < 3.5 — اشتباه ألزهايمر إذا < 2.8 مقطع/ثانية',
    measured: false,
  ),
  VocalBiomarker(
    name: 'متوسط مدة التوقفات (Mean Pause)',
    category: kCatTemporal,
    description: 'متوسط طول فترات الصمت بين الكلمات أثناء الكلام المتصل.',
    normalRange: 'سليم: 0.20 – 0.60 ثانية',
    decisionRule: 'اشتباه MCI: 0.60 – 1.00 ث — اشتباه ألزهايمر: > 1.00 ثانية',
    measured: false,
  ),
  VocalBiomarker(
    name: 'نسبة التوقفات (Pause Ratio)',
    category: kCatTemporal,
    description: 'نسبة الزمن الكلي للصمت إلى زمن الكلام كله.',
    normalRange: 'سليم: < 20% من زمن الكلام',
    decisionRule: 'مشتبه إذا > 25%',
    measured: false,
  ),

  // ─── Bloc 2 — إنتاج الصوت (تُقاس على "آآآ") ─────────────────────────────────
  VocalBiomarker(
    name: 'الاضطراب (Jitter)',
    category: kCatPhonation,
    description: 'مدى انتظام دورات الموجة الصوتية المتتالية في التردد.',
    normalRange: 'سليم: < 1% (الطبيعي 0.2% – 1%)',
    decisionRule: 'مرتفع (مشتبه) إذا > 1% — في ألزهايمر قد يصل 1% – 3% أو أكثر',
    measured: true,
  ),
  VocalBiomarker(
    name: 'اضطراب الشدة (Shimmer)',
    category: kCatPhonation,
    description: 'مدى ثبات شدة (سعة) الصوت من دورة إلى أخرى.',
    normalRange: 'سليم: < 4% (الطبيعي 0.5% – 3%)',
    decisionRule: 'مرتفع (مشتبه) إذا > 4% — في ألزهايمر قد يصل 3% – 8%',
    measured: true,
  ),
  VocalBiomarker(
    name: 'نسبة HNR',
    category: kCatPhonation,
    description: 'نسبة التوافقيات إلى الضجيج: مقياس نقاء الصوت مقابل الضوضاء.',
    normalRange: 'سليم: > 20 dB',
    decisionRule: 'منخفض (مشتبه) إذا < 20 dB',
    measured: true,
  ),

  // ─── Bloc 3 — الإيقاع والتنغيم (تُقاس على "آآآ") ────────────────────────────
  VocalBiomarker(
    name: 'الطبقة الصوتية',
    category: kCatProsody,
    description: 'متوسط التردد الأساسي للصوت (F0).',
    normalRange: 'الرجال: 120 – 180 هرتز — النساء: 220 – 300 هرتز',
    decisionRule: 'في ألزهايمر المبكر: تذبذب أكبر وعدم استقرار في F0',
    measured: true,
  ),
  VocalBiomarker(
    name: 'تباين الطبقة (F0 SD)',
    category: kCatProsody,
    description: 'تباين التردد الأساسي. على الحرف الممدود يدل التباين الكبير على عدم استقرار النبرة (تذبذب/رعشة).',
    normalRange: 'على "آآآ": تباين منخفض ومستقر = صوت ثابت',
    decisionRule: 'في الكلام التلقائي: مشتبه إذا كان التباين ضعيفاً جداً < 20 هرتز (رتابة)',
    measured: true,
  ),

  // ─── مؤشرات مساعدة (تُقاس على "آآآ") ────────────────────────────────────────
  VocalBiomarker(
    name: 'شدة الصوت',
    category: kCatExtra,
    description: 'متوسط شدة (علو) الصوت أثناء التسجيل.',
    normalRange: 'سليم: 70 – 80 dB',
    decisionRule: 'في ألزهايمر: أقل وغير مستقر',
    measured: true,
  ),
  VocalBiomarker(
    name: 'المدة',
    category: kCatExtra,
    description: 'القدرة على إطالة الحرف الممدود بثبات (دعم النفَس).',
    normalRange: 'حرف ممدود مريح: 3 – 8 ثوانٍ',
    decisionRule: 'مدة قصيرة جداً تدل على ضعف دعم النفَس',
    measured: true,
  ),
];

/// تحذير علمي مهم حول مؤشرات إنتاج الصوت (Jitter/Shimmer/HNR).
const String kPhonationCaveat =
    'مؤشرات إنتاج الصوت (Jitter / Shimmer / HNR) تتأثر كثيراً بالميكروفون، البحّة '
    'أو الالتهاب، التعب، ومشاكل الأحبال الصوتية، وطريقة التسجيل. لذلك تُستعمل '
    'كمؤشرات مساعدة فقط ولا يُعتمد عليها وحدها.';

// ════════════════════════════════════════════════════════════════════════════
// التصنيف ثلاثي المستويات (يطابق مفاتيح الخادم: healthy / at_risk / sick).
// ════════════════════════════════════════════════════════════════════════════

const Map<String, String> kClassificationLabels = {
  'healthy': 'سليم معرفياً (CU)',
  'at_risk': 'ضعف إدراكي بسيط (MCI)',
  'sick': 'مريض',
};

const Map<String, String> kClassificationDescriptions = {
  'healthy': 'المؤشرات الصوتية ضمن النطاق الطبيعي، لا توجد علامات مقلقة. استمر في المتابعة.',
  'at_risk': 'بعض المؤشرات تشير إلى احتمال ضعف إدراكي بسيط (MCI). يُنصح بالمتابعة المنتظمة واستشارة مختص.',
  'sick': 'المؤشرات الصوتية تستدعي الانتباه. يُرجى مراجعة مختص في أقرب وقت ممكن.',
};

/// يحوّل مفتاح التصنيف القادم من الخادم إلى تسمية عربية للعرض.
/// عند غياب التصنيف، يُشتق تقديرياً من النسبة الإجمالية (0.0 → 1.0).
String classificationLabelFor(String? key, {double? overallPercent}) {
  final resolved = key ?? _deriveKey(overallPercent);
  return kClassificationLabels[resolved] ?? 'غير محدد';
}

String classificationDescriptionFor(String? key, {double? overallPercent}) {
  final resolved = key ?? _deriveKey(overallPercent);
  return kClassificationDescriptions[resolved] ?? '';
}

Color classificationColor(String? key, {double? overallPercent}) {
  switch (key ?? _deriveKey(overallPercent)) {
    case 'healthy':
      return AppTheme.success;
    case 'at_risk':
      return AppTheme.warning;
    default:
      return AppTheme.error;
  }
}

IconData classificationIcon(String? key, {double? overallPercent}) {
  switch (key ?? _deriveKey(overallPercent)) {
    case 'healthy':
      return Icons.check_circle_rounded;
    case 'at_risk':
      return Icons.info_rounded;
    default:
      return Icons.warning_amber_rounded;
  }
}

/// يطابق عتبات الخادم (HEALTHY_THRESHOLD=70، SICK_THRESHOLD=40) على النسبة 0..1.
String _deriveKey(double? overallPercent) {
  final p = (overallPercent ?? 0.0) * 100.0;
  if (p >= 70.0) return 'healthy';
  if (p >= 40.0) return 'at_risk';
  return 'sick';
}
