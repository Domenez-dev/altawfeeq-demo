import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../theme/app_theme.dart';
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic', fontSize: 20)),
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

Widget _card({required Widget child}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );

TextStyle get _titleStyle => const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'IBMPlexSansArabic');
TextStyle get _bodyStyle => TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontFamily: 'IBMPlexSansArabic', height: 1.6);

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
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircularPercentIndicator(
                  radius: 60,
                  lineWidth: 12,
                  percent: 0.6,
                  center: const Text('60%', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                  progressColor: AppTheme.primaryPurple,
                  backgroundColor: AppTheme.primaryPurple.withOpacity(0.12),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                const SizedBox(height: 16),
                Text('هدفك الأسبوعي: 5 جلسات', style: _titleStyle),
                const SizedBox(height: 4),
                Text('أنجزت 3 من 5 جلسات هذا الأسبوع', style: _bodyStyle, textAlign: TextAlign.center),
              ],
            ),
          ),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نصيحة', style: _titleStyle),
                const SizedBox(height: 8),
                Text('الانتظام في أداء الجلسات اليومية يساعد على متابعة تطوّر المؤشرات الصوتية بدقة أكبر.', style: _bodyStyle),
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

  static const _descriptions = {
    'شدة الصوت': 'تعبّر عن مدى وضوح وقوة نبرة الصوت أثناء النطق.',
    'المدة': 'القدرة على الحفاظ على نبرة صوتية ثابتة لأطول فترة ممكنة.',
    'الطبقة الصوتية': 'استقرار التردد الأساسي للصوت وخلوّه من التذبذب غير الطبيعي.',
    'الاضطراب (Jitter)': 'مدى انتظام الموجات الصوتية الفردية المتتالية.',
  };

  @override
  Widget build(BuildContext context) {
    return MoreScaffold(
      title: 'المؤشرات الصوتية',
      child: Column(
        children: kIndicatorNames.map((name) {
          return _card(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.primaryPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(indicatorIcon(name), color: AppTheme.primaryPurple, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: _titleStyle),
                      const SizedBox(height: 4),
                      Text(_descriptions[name] ?? '', style: _bodyStyle),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

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
          _card(
            child: Row(
              children: [
                Expanded(child: Text('تفعيل التذكير اليومي', style: _titleStyle)),
                Switch(
                  value: _enabled,
                  activeColor: AppTheme.primaryPurple,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
              ],
            ),
          ),
          _card(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: _enabled,
              leading: const Icon(Icons.access_time_rounded, color: AppTheme.primaryPurple),
              title: Text('وقت التذكير', style: _titleStyle),
              trailing: Text(_time.format(context), style: _titleStyle),
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

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _notifications = true;
  bool _sounds = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    Widget toggle(String title, bool value, ValueChanged<bool> onChanged) => _card(
          child: Row(
            children: [
              Expanded(child: Text(title, style: _titleStyle)),
              Switch(value: value, activeColor: AppTheme.primaryPurple, onChanged: onChanged),
            ],
          ),
        );

    return MoreScaffold(
      title: 'الإعدادات',
      child: Column(
        children: [
          toggle('الإشعارات', _notifications, (v) => setState(() => _notifications = v)),
          toggle('أصوات التطبيق', _sounds, (v) => setState(() => _sounds = v)),
          toggle('الوضع الليلي', _darkMode, (v) => setState(() => _darkMode = v)),
          _card(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language_rounded, color: AppTheme.primaryPurple),
              title: Text('اللغة', style: _titleStyle),
              trailing: Text('العربية', style: _bodyStyle),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border.withOpacity(0.3)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                shape: const Border(),
                title: Text(item[0], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontFamily: 'IBMPlexSansArabic')),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [Align(alignment: Alignment.centerRight, child: Text(item[1], style: _bodyStyle))],
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
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.graphic_eq_rounded, size: 48, color: AppTheme.primaryPurple),
          ),
          const SizedBox(height: 16),
          Text('التوفيق', style: _titleStyle.copyWith(fontSize: 24)),
          const SizedBox(height: 4),
          // الإصدار يُقرأ ديناميكياً من pubspec.yaml (الحقل version) عبر
          // package_info_plus. لتحديث الإصدار: زِد رقم النسخة في pubspec.yaml
          // بمقدار 0.0.1 مع كل تغيير جديد على التطبيق (مثال: 1.0.0 -> 1.0.1).
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.hasData ? snapshot.data!.version : '...';
              return Text('الإصدار $version', style: _bodyStyle);
            },
          ),
          const SizedBox(height: 24),
          _card(
            child: Text(
              'تطبيق ذكي لمتابعة المؤشرات الصوتية، يساعد على تحليل الصوت واكتشاف العلامات المبكرة من خلال تسجيلات قصيرة للحرف المستمر "آآآ".',
              style: _bodyStyle,
              textAlign: TextAlign.center,
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
          Text(label, style: _titleStyle),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border.withOpacity(0.3))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border.withOpacity(0.3))),
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
