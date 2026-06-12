import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../theme/app_theme.dart';
import '../models/api/models.dart';
import '../providers/api_service_provider.dart';
import '../providers/home_provider.dart';
import '../providers/reports_provider.dart';
import '../providers/sessions_provider.dart';
import '../utils/indicator_helpers.dart';
import '../utils/recordings_store.dart';
import '../widgets/error_retry.dart';
import 'session_detail_screen.dart';
import 'voice_test_screen.dart';

class SessionsTab extends ConsumerWidget {
  const SessionsTab({super.key});

  Future<void> _deleteSelected(BuildContext context, WidgetRef ref, Set<int> ids) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف الجلسات', style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.bold)),
        content: Text('سيتم حذف ${ids.length} جلسة. لا يمكن التراجع عن هذا الإجراء.',
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppTheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(apiServiceProvider).deleteSessions(ids.toList());
      for (final id in ids) {
        await deleteSessionRecording(id);
      }
      ref.read(sessionSelectionProvider.notifier).clear();
      ref.invalidate(sessionsProvider);
      ref.invalidate(homeDataProvider);
      ref.invalidate(reportProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر حذف الجلسات: $e', style: const TextStyle(fontFamily: 'IBMPlexSansArabic')),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(sessionFilterProvider);
    final filteredAsync = ref.watch(filteredSessionsProvider);
    final selected = ref.watch(sessionSelectionProvider);
    final selectionMode = selected.isNotEmpty;
    final filterLabels = ['الكل', 'مكتملة', 'ملغاة'];

    return PopScope(
      canPop: !selectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(sessionSelectionProvider.notifier).clear();
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          centerTitle: true,
          leading: selectionMode
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
                  onPressed: () => ref.read(sessionSelectionProvider.notifier).clear(),
                )
              : null,
          title: Text(
            selectionMode ? '${selected.length} محددة' : 'جلساتي',
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'IBMPlexSansArabic', fontSize: 20),
          ),
          actions: selectionMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                    tooltip: 'حذف المحدد',
                    onPressed: () => _deleteSelected(context, ref, selected),
                  ),
                ]
              : null,
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

              if (!selectionMode)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textSecondary.withOpacity(0.7)),
                      const SizedBox(width: 6),
                      Text('اضغط مطوّلاً لتحديد وحذف الجلسات',
                          style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary, fontFamily: 'IBMPlexSansArabic')),
                    ],
                  ),
                ),

              // Sessions list
              Expanded(
                child: filteredAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => ErrorRetryView(error: e, onRetry: () => ref.invalidate(sessionsProvider)),
                  data: (sessions) => sessions.isEmpty
                      ? Center(
                          child: Text('لا توجد جلسات', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'IBMPlexSansArabic', fontSize: 16)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
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
        floatingActionButton: selectionMode
            ? null
            : Padding(
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
      ),
    );
  }
}

class _SessionItem extends ConsumerWidget {
  final Session session;
  const _SessionItem({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(sessionSelectionProvider);
    final isSelected = selected.contains(session.id);
    final selectionMode = selected.isNotEmpty;

    final color = statusColor(session.overallPercent >= 0.7
        ? 'جيد'
        : session.overallPercent >= 0.4
            ? 'متوسط'
            : 'ضعيف');

    void toggle() => ref.read(sessionSelectionProvider.notifier).toggle(session.id);

    return GestureDetector(
      onTap: () {
        if (selectionMode) {
          toggle();
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => SessionDetailScreen(session: session)));
        }
      },
      onLongPress: toggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPurple.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : AppTheme.border.withOpacity(0.3),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (selectionMode) ...[
                  Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isSelected ? AppTheme.primaryPurple : AppTheme.textSecondary.withOpacity(0.4),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                ],
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
              ],
            ),
            // Bigger ring so the % text never overlaps the circle.
            CircularPercentIndicator(
              radius: 56.0,
              lineWidth: 5.0,
              percent: session.overallPercent.clamp(0.0, 1.0),
              center: Text(
                '${(session.overallPercent * 100).toInt()}%',
                softWrap: false,
                overflow: TextOverflow.visible,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: color),
              ),
              progressColor: color,
              backgroundColor: color.withOpacity(0.1),
              circularStrokeCap: CircularStrokeCap.round,
            ),
          ],
        ),
      ),
    );
  }
}
