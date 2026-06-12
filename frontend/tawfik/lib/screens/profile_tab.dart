import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/profile_provider.dart';
import '../widgets/error_retry.dart';
import 'more_screens.dart';
import 'splash_screen.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text('الملف الشخصي', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic', fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textPrimary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppSettingsScreen())),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetryView(error: e, onRetry: () => ref.invalidate(profileProvider)),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Profile card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border.withOpacity(0.3)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(color: AppTheme.primaryPurple, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'M',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'IBMPlexSansArabic')),
                          const SizedBox(height: 4),
                          Text(profile.email, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EditProfileScreen(name: profile.name, email: profile.email)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Menu
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border.withOpacity(0.3)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    _MenuItem(
                      icon: Icons.track_changes_outlined,
                      title: 'الهدف العلاجي',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TherapeuticGoalScreen())),
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _MenuItem(
                      icon: Icons.bar_chart_outlined,
                      title: 'المؤشرات الصوتية',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VocalIndicatorsInfoScreen())),
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _MenuItem(
                      icon: Icons.notifications_active_outlined,
                      title: 'تذكيرات الجلسات',
                      trailingText: 'مفعل',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionRemindersScreen())),
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _MenuItem(
                      icon: Icons.settings_outlined,
                      title: 'الإعدادات',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppSettingsScreen())),
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _MenuItem(
                      icon: Icons.help_outline_rounded,
                      title: 'مساعدة',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _MenuItem(
                      icon: Icons.info_outline_rounded,
                      title: 'حول التطبيق',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              TextButton(
                onPressed: () => _confirmLogout(context),
                child: const Text('تسجيل الخروج', style: TextStyle(color: AppTheme.error, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic')),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('تسجيل الخروج', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.bold)),
      content: const Text('هل تريد تسجيل الخروج من التطبيق؟', style: TextStyle(fontFamily: 'IBMPlexSansArabic')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('إلغاء', style: TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppTheme.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('خروج', style: TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppTheme.error, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const SplashScreen()),
    (route) => false,
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback? onTap;
  const _MenuItem({required this.icon, required this.title, this.trailingText, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppTheme.textPrimary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontFamily: 'IBMPlexSansArabic')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(trailingText!, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontFamily: 'IBMPlexSansArabic')),
            const SizedBox(width: 8),
          ],
          Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textSecondary, size: 16),
        ],
      ),
      onTap: onTap,
    );
  }
}
