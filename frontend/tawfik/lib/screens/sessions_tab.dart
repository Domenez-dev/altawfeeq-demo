import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../theme/app_theme.dart';
import '../models/api/models.dart';
import '../providers/sessions_provider.dart';
import '../utils/indicator_helpers.dart';
import 'voice_test_screen.dart';

class SessionsTab extends ConsumerWidget {
  const SessionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(sessionFilterProvider);
    final filteredAsync = ref.watch(filteredSessionsProvider);
    final filterLabels = ['الكل', 'مكتملة', 'ملغاة'];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text('جلساتي', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic', fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.border.withOpacity(0.3)),
                ),
                child: Row(
                  children: List.generate(3, (i) => Expanded(
                    child: GestureDetector(
                      onTap: () => ref.read(sessionFilterProvider.notifier).state = i,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: filter == i ? AppTheme.primaryPurple : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          filterLabels[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: filter == i ? Colors.white : AppTheme.textSecondary,
                            fontWeight: filter == i ? FontWeight.bold : FontWeight.normal,
                            fontFamily: 'IBMPlexSansArabic',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  )),
                ),
              ),
            ),

            // Sessions list
            Expanded(
              child: filteredAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('حدث خطأ: $e', style: const TextStyle(color: AppTheme.error, fontFamily: 'IBMPlexSansArabic')),
                ),
                data: (sessions) => sessions.isEmpty
                    ? Center(
                        child: Text('لا توجد جلسات', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'IBMPlexSansArabic', fontSize: 16)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        itemCount: sessions.length + 1,
                        itemBuilder: (_, i) {
                          if (i == sessions.length) return const SizedBox(height: 100);
                          return _SessionItem(session: sessions[i]);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, left: 24.0, right: 24.0),
        child: ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceTestScreen())),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryPurple,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
          ),
          child: const Text('+ جلسة جديدة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic')),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _SessionItem extends StatelessWidget {
  final Session session;
  const _SessionItem({required this.session});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(session.overallPercent >= 0.6 ? 'جيد' : session.overallPercent >= 0.4 ? 'متوسط' : 'ضعيف');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'IBMPlexSansArabic')),
              const SizedBox(height: 4),
              Row(children: [
                Text(session.time, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontFamily: 'IBMPlexSansArabic')),
                const SizedBox(width: 8),
                Text('-', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(width: 8),
                Text(session.date, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontFamily: 'IBMPlexSansArabic')),
              ]),
            ],
          ),
          CircularPercentIndicator(
            radius: 24.0,
            lineWidth: 3.0,
            percent: session.overallPercent,
            center: Text(
              '${(session.overallPercent * 100).toInt()}%',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: color),
            ),
            progressColor: color,
            backgroundColor: color.withOpacity(0.1),
            circularStrokeCap: CircularStrokeCap.round,
          ),
        ],
      ),
    );
  }
}
