import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../database/database_helper.dart';
import '../models/report.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import 'report_form_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _db = DatabaseHelper.instance;
  List<Report> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final reports = await _db.getAllReports();
    setState(() {
      _reports = reports;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    // Format: "2026/02/10"
    return DateFormat('yyyy/MM/dd').format(date);
  }

  String _formatTime(DateTime date) {
    // Format: "02:30 PM"
    return DateFormat('hh:mm a').format(date);
  }

  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final reportDate = DateTime(date.year, date.month, date.day);

    if (reportDate == today) {
      return 'اليوم';
    } else if (reportDate == yesterday) {
      return 'أمس';
    } else {
      final difference = today.difference(reportDate).inDays;
      if (difference < 7) {
        return 'منذ $difference أيام';
      } else {
        return _formatDate(date);
      }
    }
  }

  Future<void> _deleteReport(Report report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'حذف التقرير',
                style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'هل تريد حذف "${report.title}"؟ لن تتمكن من التراجع عن هذا الإجراء.',
          style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppTheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'حذف',
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteReport(report.id!);
      _loadReports();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حذف "${report.title}" بنجاح',
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
      }
    }
  }

  void _navigateToForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportFormScreen()),
    );
    if (result == true) {
      _loadReports();
    }
  }

  void _openReport(Report report) async {
    final result = await OpenFilex.open(report.pdfPath);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'تعذر فتح الملف',
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic'),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.primaryPurple,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'التقارير الطبية',
          style: TextStyle(
            color: AppTheme.primaryPurple,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        centerTitle: true,
        actions: [
          if (_reports.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_reports.length}',
                    style: const TextStyle(
                      color: AppTheme.primaryPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.description_rounded,
                    color: AppTheme.primaryPurple,
                    size: 18,
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _reports.isEmpty
            ? _buildEmptyState()
            : _buildReportsList(isTablet),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToForm,
        backgroundColor: AppTheme.primaryPurple,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'إضافة تقرير',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 5,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryPurple,
              ),
              backgroundColor: AppTheme.primaryPurple.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'جاري التحميل...',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.1),
                    AppTheme.primaryPurple.withOpacity(0.05),
                  ],
                ),
              ),
              child: Icon(
                Icons.description_rounded,
                size: 70,
                color: AppTheme.primaryPurple.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'لا توجد تقارير طبية',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryPurple,
                fontFamily: 'IBMPlexSansArabic',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'ابدأ بإضافة تقرير طبي جديد لحفظ السجلات',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
                fontFamily: 'IBMPlexSansArabic',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: AppTheme.primaryPurple,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'اضغط على زر + للبدء',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryPurple,
                      fontFamily: 'IBMPlexSansArabic',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsList(bool isTablet) {
    return RefreshIndicator(
      onRefresh: _loadReports,
      color: AppTheme.primaryPurple,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 16,
          vertical: 20,
        ),
        itemCount: _reports.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _buildReportCard(report, isTablet);
        },
      ),
    );
  }

  Widget _buildReportCard(Report report, bool isTablet) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return CustomCard(
      onTap: () => _openReport(report),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon, Title, and Delete Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PDF Icon Container
                Container(
                  width: isTablet ? 64 : 56,
                  height: isTablet ? 64 : 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.error.withOpacity(0.15),
                        AppTheme.error.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.error.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AppTheme.error,
                    size: isTablet ? 32 : 28,
                  ),
                ),
                const SizedBox(width: 12),

                // Title (Flexible to prevent overflow)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 17 : 15,
                          color: AppTheme.primaryPurple,
                          fontFamily: 'IBMPlexSansArabic',
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Delete Button
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_rounded,
                      color: AppTheme.error,
                      size: isTablet ? 22 : 20,
                    ),
                    onPressed: () => _deleteReport(report),
                    tooltip: 'حذف',
                    padding: EdgeInsets.all(isTablet ? 10 : 8),
                    constraints: BoxConstraints(
                      minWidth: isTablet ? 44 : 36,
                      minHeight: isTablet ? 44 : 36,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bottom Row: Date and Time Badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Date Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: isSmallScreen ? 12 : 13,
                        color: AppTheme.primaryPurple.withOpacity(0.7),
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 6),
                      Flexible(
                        child: Text(
                          _getRelativeDate(report.createdAt),
                          style: TextStyle(
                            color: AppTheme.primaryPurple,
                            fontSize: isSmallScreen ? 11 : 12,
                            fontFamily: 'IBMPlexSansArabic',
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Time Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: isSmallScreen ? 12 : 13,
                        color: AppTheme.textSecondary.withOpacity(0.7),
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 6),
                      Text(
                        _formatTime(report.createdAt),
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: isSmallScreen ? 11 : 12,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
