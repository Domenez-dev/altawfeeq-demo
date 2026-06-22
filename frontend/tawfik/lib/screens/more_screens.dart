import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../utils/indicator_helpers.dart';

// ════════════════════════════════════════════════════════════════════════════
// شاشات واجهة بسيطة لعناصر صفحة "المزيد".
// الغرض منها عرض واجهة فقط (دون منطق حقيقي خلفها بعد).
// ════════════════════════════════════════════════════════════════════════════

/// هيكل موحّد لكل شاشات "المزيد": شريط علوي بعنوان + محتوى قابل للتمرير.
class MoreScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const MoreScaffold({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.appColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: TextStyle(color: context.appColors.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic', fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: child,
        ),
      ),
    );
  }
}

Widget _card(BuildContext context, {required Widget child}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appColors.border.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );

TextStyle _titleStyle(BuildContext context) => TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appColors.textPrimary, fontFamily: 'IBMPlexSansArabic');
TextStyle _bodyStyle(BuildContext context) => TextStyle(fontSize: 14, color: context.appColors.textSecondary, fontFamily: 'IBMPlexSansArabic', height: 1.6);

// ─── الهدف العلاجي ──────────────────────────────────────────────────────────

class TherapeuticGoalScreen extends StatelessWidget {
  const TherapeuticGoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MoreScaffold(
      title: 'الهدف العلاجي',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _card(context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircularPercentIndicator(
                  radius: 96,
                  lineWidth: 12,
                  percent: 0.6,
                  center: const Text(
                    '60%',
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple),
                  ),
                  progressColor: AppTheme.primaryPurple,
                  backgroundColor: AppTheme.primaryPurple.withOpacity(0.12),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                const SizedBox(height: 16),
                Text('هدفك الأسبوعي: 5 جلسات', style: _titleStyle(context)),
                const SizedBox(height: 4),
                Text('أنجزت 3 من 5 جلسات هذا الأسبوع', style: _bodyStyle(context), textAlign: TextAlign.center),
              ],
            ),
          ),
          _card(context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نصيحة', style: _titleStyle(context)),
                const SizedBox(height: 8),
                Text('الانتظام في أداء الجلسات اليومية يساعد على متابعة تطوّر المؤشرات الصوتية بدقة أكبر.', style: _bodyStyle(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── المؤشرات الصوتية ───────────────────────────────────────────────────────

class VocalIndicatorsInfoScreen extends StatelessWidget {
  const VocalIndicatorsInfoScreen({super.key});

  static const _categoryOrder = [kCatProsody, kCatPhonation, kCatExtra, kCatTemporal];

  @override
  Widget build(BuildContext context) {
    return MoreScaffold(
      title: 'المؤشرات الصوتية',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // مقدمة موجزة
          _card(context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('كيف نقرأ المؤشرات؟', style: _titleStyle(context)),
                const SizedBox(height: 8),
                Text(
                  'يقيس التطبيق سبعة مؤشرات صوتية من تسجيل الحرف الممدود "آآآ"، ويقارنها بقيم '
                  'مرجعية علمية لتحديد ما إذا كانت ضمن النطاق الطبيعي. المؤشرات الزمنية (معدل '
                  'الكلام والتوقفات) مرجعية فقط لأنها تحتاج كلاماً متصلاً (جملة) وليس حرفاً ممدوداً.',
                  style: _bodyStyle(context),
                ),
              ],
            ),
          ),
          for (final category in _categoryOrder) ...[
            _categoryHeader(context, category),
            ...kBiomarkers.where((b) => b.category == category).map((b) => _biomarkerCard(context, b)),
          ],
          // تحذير علمي حول مؤشرات إنتاج الصوت
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.warning.withOpacity(0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(kPhonationCaveat, style: _bodyStyle(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _categoryHeader(BuildContext context, String title) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8, right: 4),
      child: Row(
        children: [
          Container(width: 4, height: 18, decoration: BoxDecoration(color: AppTheme.primaryPurple, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: _titleStyle(context).copyWith(fontSize: 17)),
        ],
      ),
    );

Widget _biomarkerCard(BuildContext context, VocalBiomarker b) => _card(context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primaryPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(indicatorIcon(b.name), color: AppTheme.primaryPurple, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(b.name, style: _titleStyle(context))),
              // وسم يوضّح هل المؤشر مُقاس فعلياً أم مرجعي فقط
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (b.measured ? AppTheme.success : AppTheme.warning).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  b.measured ? 'يُقاس' : 'مرجعي',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic', color: b.measured ? AppTheme.success : AppTheme.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(b.description, style: _bodyStyle(context)),
          const SizedBox(height: 10),
          _metaRow(context, Icons.check_circle_outline_rounded, AppTheme.success, b.normalRange),
          const SizedBox(height: 6),
          _metaRow(context, Icons.rule_rounded, AppTheme.primaryPurple, b.decisionRule),
        ],
      ),
    );

Widget _metaRow(BuildContext context, IconData icon, Color color, String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: _bodyStyle(context).copyWith(fontSize: 13)),
        ),
      ],
    );

// ─── تذكيرات الجلسات ────────────────────────────────────────────────────────

class SessionRemindersScreen extends StatefulWidget {
  const SessionRemindersScreen({super.key});

  @override
  State<SessionRemindersScreen> createState() => _SessionRemindersScreenState();
}

class _SessionRemindersScreenState extends State<SessionRemindersScreen> {
  bool _enabled = true;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);

  @override
  Widget build(BuildContext context) {
    return MoreScaffold(
      title: 'تذكيرات الجلسات',
      child: Column(
        children: [
          _card(context,
            child: Row(
              children: [
                Expanded(child: Text('تفعيل التذكير اليومي', style: _titleStyle(context))),
                Switch(
                  value: _enabled,
                  activeColor: AppTheme.primaryPurple,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
              ],
            ),
          ),
          _card(context,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: _enabled,
              leading: const Icon(Icons.access_time_rounded, color: AppTheme.primaryPurple),
              title: Text('وقت التذكير', style: _titleStyle(context)),
              trailing: Text(_time.format(context), style: _titleStyle(context)),
              onTap: !_enabled
                  ? null
                  : () async {
                      final picked = await showTimePicker(context: context, initialTime: _time);
                      if (picked != null) setState(() => _time = picked);
                    },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── الإعدادات ──────────────────────────────────────────────────────────────

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  bool _notifications = true;
  bool _sounds = true;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    // الصندوق بأكمله قابل للنقر لتبديل الإعداد (وليس مفتاح التبديل فقط).
    Widget toggle(String title, bool value, ValueChanged<bool> onChanged) => _card(context,
          child: InkWell(
            onTap: () => onChanged(!value),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Expanded(child: Text(title, style: _titleStyle(context))),
                Switch(value: value, activeColor: AppTheme.primaryPurple, onChanged: onChanged),
              ],
            ),
          ),
        );

    return MoreScaffold(
      title: 'الإعدادات',
      child: Column(
        children: [
          toggle('الإشعارات', _notifications, (v) => setState(() => _notifications = v)),
          toggle('أصوات التطبيق', _sounds, (v) => setState(() => _sounds = v)),
          toggle('الوضع الليلي', isDarkMode,
              (v) => ref.read(themeModeProvider.notifier).setDark(v)),
          _card(context,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language_rounded, color: AppTheme.primaryPurple),
              title: Text('اللغة', style: _titleStyle(context)),
              trailing: Text('العربية', style: _bodyStyle(context)),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

// ─── مساعدة ─────────────────────────────────────────────────────────────────

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faq = [
    ['كيف أبدأ جلسة جديدة؟', 'اضغط على زر الميكروفون في الأسفل، ثم انطق الحرف "آآآ" بصوت ثابت لعدة ثوانٍ.'],
    ['لماذا ظهرت رسالة "جودة التسجيل غير كافية"؟', 'تأكد من وجودك في مكان هادئ والاقتراب من الميكروفون، وأطِل نطق الحرف بثبات.'],
    ['أين تُحفظ تسجيلاتي؟', 'تُحفظ تسجيلاتك على جهازك ويمكنك الاستماع إليها من تفاصيل كل جلسة.'],
    ['كيف أحذف جلسة؟', 'اضغط مطوّلاً على الجلسة في قائمة الجلسات لتحديدها ثم اضغط أيقونة الحذف.'],
  ];

  @override
  Widget build(BuildContext context) {
    return MoreScaffold(
      title: 'مساعدة',
      child: Column(
        children: _faq.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: context.appColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.appColors.border.withOpacity(0.3)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                shape: const Border(),
                title: Text(item[0], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.appColors.textPrimary, fontFamily: 'IBMPlexSansArabic')),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [Align(alignment: Alignment.centerRight, child: Text(item[1], style: _bodyStyle(context)))],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── حول التطبيق ────────────────────────────────────────────────────────────

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MoreScaffold(
      title: 'حول التطبيق',
      child: Column(
        children: [
          const SizedBox(height: 16),
          // شعار التطبيق داخل التطبيق (يحمل اسم Taoufik)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/inapplogo.jpeg',
              height: 72,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Text(
                'Taoufik',
                style: _titleStyle(context).copyWith(fontSize: 28, color: AppTheme.primaryPurple),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // الإصدار يُقرأ ديناميكياً من pubspec.yaml (الحقل version) عبر
          // package_info_plus. لتحديث الإصدار: زِد رقم النسخة في pubspec.yaml
          // بمقدار 0.0.1 مع كل تغيير جديد على التطبيق (مثال: 1.0.0 -> 1.0.1).
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.hasData ? snapshot.data!.version : '...';
              return Text('الإصدار $version', style: _bodyStyle(context));
            },
          ),
          const SizedBox(height: 24),
          _card(context,
            child: Text(
              'تطبيق Taoufik أداة ذكية للكشف المبكر عن مؤشرات الضعف الإدراكي البسيط (MCI) '
              'ومرض ألزهايمر عبر تحليل الصوت. يسجّل المستخدم الحرف الممدود "آآآ" لبضع ثوانٍ، '
              'فيستخرج التطبيق سبعة مؤشرات صوتية (الطبقة الصوتية وتباينها، الاضطراب Jitter، '
              'اضطراب الشدة Shimmer، نسبة HNR، شدة الصوت، والمدة) ويصنّف النتيجة إلى: '
              'سليم معرفياً (CU)، أو ضعف إدراكي بسيط (MCI)، أو مريض.',
              style: _bodyStyle(context),
              textAlign: TextAlign.center,
            ),
          ),
          _card(context,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.medical_information_outlined, color: AppTheme.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تنبيه: هذا التطبيق أداة مساعدة للفحص المبدئي وليس تشخيصاً طبياً. '
                    'يُرجى دائماً مراجعة مختص لتأكيد أي نتيجة.',
                    style: _bodyStyle(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── تعديل الملف الشخصي ─────────────────────────────────────────────────────

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  const EditProfileScreen({super.key, required this.name, required this.email});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl = TextEditingController(text: widget.name);
  late final TextEditingController _emailCtrl = TextEditingController(text: widget.email);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Widget _field(String label, TextEditingController ctrl) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _titleStyle(context)),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
            decoration: InputDecoration(
              filled: true,
              fillColor: context.appColors.cardBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.appColors.border.withOpacity(0.3))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.appColors.border.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryPurple)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return MoreScaffold(
      title: 'تعديل الملف',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field('الاسم', _nameCtrl),
          _field('البريد الإلكتروني', _emailCtrl),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حفظ التغييرات', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
                  backgroundColor: AppTheme.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('حفظ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic')),
          ),
        ],
      ),
    );
  }
}
