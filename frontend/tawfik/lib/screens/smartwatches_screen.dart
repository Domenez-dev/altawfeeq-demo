import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/smartwatch.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import 'smartwatch_form_screen.dart';
import 'alarms_screen.dart';

class SmartwatchesScreen extends StatefulWidget {
  const SmartwatchesScreen({super.key});

  @override
  State<SmartwatchesScreen> createState() => _SmartwatchesScreenState();
}

class _SmartwatchesScreenState extends State<SmartwatchesScreen> {
  final _db = DatabaseHelper.instance;
  List<Smartwatch> _smartwatches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSmartwatches();
  }

  Future<void> _loadSmartwatches() async {
    setState(() => _isLoading = true);
    final watches = await _db.getAllSmartwatches();
    setState(() {
      _smartwatches = watches;
      _isLoading = false;
    });
  }

  Future<void> _deleteSmartwatch(Smartwatch watch) async {
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
                'حذف الساعة',
                style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'هل تريد حذف ساعة ${watch.name}؟ لن تتمكن من التراجع عن هذا الإجراء.',
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

    if (confirm == true && watch.id != null) {
      await _db.deleteSmartwatch(watch.id!);
      _loadSmartwatches();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حذف ${watch.name} بنجاح',
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

  void _navigateToForm([Smartwatch? watch]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SmartwatchFormScreen(smartwatch: watch),
      ),
    );

    if (result == true) {
      _loadSmartwatches();
    }
  }

  void _navigateToAlarms(Smartwatch watch) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AlarmsScreen(smartwatch: watch)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.appColors.background,
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
          'الساعات الذكية',
          style: TextStyle(
            color: AppTheme.primaryPurple,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        centerTitle: true,
        actions: [
          if (_smartwatches.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 12, right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_smartwatches.length}',
                    style: const TextStyle(
                      color: AppTheme.primaryPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.watch_rounded,
                    color: AppTheme.primaryPurple,
                    size: 16,
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _smartwatches.isEmpty
                ? _buildEmptyState()
                : _buildWatchesList(isTablet),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: AppTheme.primaryPurple,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'إضافة ساعة',
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
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
              backgroundColor: AppTheme.primaryPurple.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'جاري التحميل...',
            style: TextStyle(
              color: context.appColors.textSecondary,
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
                Icons.watch_rounded,
                size: 70,
                color: AppTheme.primaryPurple.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'لا توجد ساعات ذكية',
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
              'ابدأ بإضافة ساعة ذكية لتتبع بياناتك الصحية',
              style: TextStyle(
                fontSize: 15,
                color: context.appColors.textSecondary,
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

  Widget _buildWatchesList(bool isTablet) {
    return RefreshIndicator(
      onRefresh: _loadSmartwatches,
      color: AppTheme.primaryPurple,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 16,
          vertical: 20,
        ),
        itemCount: _smartwatches.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final watch = _smartwatches[index];
          return _buildSmartwatchCard(watch, isTablet);
        },
      ),
    );
  }

  Widget _buildSmartwatchCard(Smartwatch watch, bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isTiny = availableWidth < 340;
        final isSmall = availableWidth < 380;

        // Adaptive sizes
        final iconSize = isTiny ? 48.0 : (isSmall ? 52.0 : (isTablet ? 64.0 : 56.0));
        final iconInnerSize = isTiny ? 24.0 : (isSmall ? 26.0 : (isTablet ? 32.0 : 28.0));
        final cardPadding = isTiny ? 10.0 : (isSmall ? 12.0 : (isTablet ? 18.0 : 14.0));
        final nameFontSize = isTiny ? 14.0 : (isSmall ? 15.0 : (isTablet ? 18.0 : 16.0));
        final addressFontSize = isTiny ? 11.0 : (isSmall ? 12.0 : 13.0);

        return CustomCard(
          onTap: () => _navigateToAlarms(watch),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              children: [
                Row(
                  children: [
                    // Icon Container - Smaller
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryPurple.withOpacity(0.15),
                            AppTheme.primaryPurple.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.primaryPurple.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.watch_rounded,
                        color: AppTheme.primaryPurple,
                        size: iconInnerSize,
                      ),
                    ),
                    SizedBox(width: isTiny ? 10 : 12),

                    // Watch Info - Flexible
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            watch.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: nameFontSize,
                              color: AppTheme.primaryPurple,
                              fontFamily: 'IBMPlexSansArabic',
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: isTiny ? 13 : 14,
                                color: context.appColors.textSecondary.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  watch.address,
                                  style: TextStyle(
                                    color: context.appColors.textSecondary,
                                    fontSize: addressFontSize,
                                    fontFamily: 'IBMPlexSansArabic',
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: isTiny ? 6 : 8),

                    // Actions Menu - Compact
                    SizedBox(
                      width: isTiny ? 36 : 40,
                      height: isTiny ? 36 : 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: AppTheme.primaryPurple,
                            size: isTiny ? 18 : 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.zero,
                          elevation: 8,
                          offset: const Offset(-10, 10),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _navigateToForm(watch);
                            } else if (value == 'delete') {
                              _deleteSmartwatch(watch);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryPurple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      size: 18,
                                      color: AppTheme.primaryPurple,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'تعديل',
                                    style: TextStyle(
                                      fontFamily: 'IBMPlexSansArabic',
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.delete_rounded,
                                      size: 18,
                                      color: AppTheme.error,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'حذف',
                                    style: TextStyle(
                                      color: AppTheme.error,
                                      fontFamily: 'IBMPlexSansArabic',
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}