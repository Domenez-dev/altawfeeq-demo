import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/profile_provider.dart';

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
          IconButton(icon: const Icon(Icons.settings_outlined, color: AppTheme.textPrimary), onPressed: () {}),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('حدث خطأ: $e', style: const TextStyle(color: AppTheme.error, fontFamily: 'IBMPlexSansArabic')),
        ),
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
                    IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary), onPressed: () {}),
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
                    _MenuItem(icon: Icons.track_changes_outlined, title: 'الهدف العلاجي'),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _MenuItem(icon: Icons.bar_chart_outlined, title: 'المؤشرات الصوتية'),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _MenuItem(icon: Icons.notifications_active_outlined, title: 'تذكيرات الجلسات', trailingText: 'مفعل'),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _MenuItem(icon: Icons.settings_outlined, title: 'الإعدادات'),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _MenuItem(icon: Icons.help_outline_rounded, title: 'مساعدة'),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _MenuItem(icon: Icons.info_outline_rounded, title: 'حول التطبيق'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              TextButton(
                onPressed: () {},
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

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  const _MenuItem({required this.icon, required this.title, this.trailingText});

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
      onTap: () {},
    );
  }
}
