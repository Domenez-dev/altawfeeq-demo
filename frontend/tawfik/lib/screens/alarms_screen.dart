import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/smartwatch.dart';
import '../models/alarm.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import 'alarm_form_screen.dart';

class AlarmsScreen extends StatefulWidget {
  final Smartwatch smartwatch;

  const AlarmsScreen({super.key, required this.smartwatch});

  @override
  State<AlarmsScreen> createState() => _AlarmsScreenState();
}

class _AlarmsScreenState extends State<AlarmsScreen> {
  final _db = DatabaseHelper.instance;
  List<Alarm> _alarms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    setState(() => _isLoading = true);
    final alarms = await _db.getAlarmsForWatch(widget.smartwatch.id!);
    setState(() {
      _alarms = alarms;
      _isLoading = false;
    });
  }

  Future<void> _toggleAlarm(Alarm alarm) async {
    final updated = alarm.copyWith(enabled: !alarm.enabled);
    await _db.updateAlarm(updated);
    _loadAlarms();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            alarm.enabled ? 'تم تعطيل التنبيه' : 'تم تفعيل التنبيه',
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppTheme.primaryPurple,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteAlarm(Alarm alarm) async {
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
                'حذف التنبيه',
                style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'هل تريد حذف تنبيه "${alarm.medicineName}"؟ لن تتمكن من التراجع عن هذا الإجراء.',
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

    if (confirm == true && alarm.id != null) {
      await _db.deleteAlarm(alarm.id!);
      _loadAlarms();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حذف "${alarm.medicineName}" بنجاح',
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

  void _navigateToForm([Alarm? alarm]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AlarmFormScreen(smartwatch: widget.smartwatch, alarm: alarm),
      ),
    );

    if (result == true) {
      _loadAlarms();
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
        title: Text(
          'تنبيهات ${widget.smartwatch.name}',
          style: const TextStyle(
            color: AppTheme.primaryPurple,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'IBMPlexSansArabic',
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        centerTitle: true,
        actions: [
          if (_alarms.isNotEmpty)
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
                    '${_alarms.length}',
                    style: const TextStyle(
                      color: AppTheme.primaryPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.alarm_rounded,
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
            : _alarms.isEmpty
            ? _buildEmptyState()
            : _buildAlarmsList(isTablet),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: AppTheme.primaryPurple,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'إضافة تنبيه',
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
                Icons.alarm_rounded,
                size: 70,
                color: AppTheme.primaryPurple.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'لا توجد تنبيهات',
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
              'ابدأ بإضافة تنبيه جديد للأدوية',
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

  Widget _buildAlarmsList(bool isTablet) {
    return RefreshIndicator(
      onRefresh: _loadAlarms,
      color: AppTheme.primaryPurple,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 16,
          vertical: 20,
        ),
        itemCount: _alarms.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final alarm = _alarms[index];
          return _buildAlarmCard(alarm, isTablet);
        },
      ),
    );
  }

  Widget _buildAlarmCard(Alarm alarm, bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available width
        final availableWidth = constraints.maxWidth;
        final isTiny = availableWidth < 340;
        final isSmall = availableWidth < 380;

        // Adaptive sizes based on available width
        final iconSize = isTiny
            ? 44.0
            : (isSmall ? 50.0 : (isTablet ? 64.0 : 56.0));
        final iconInnerSize = isTiny
            ? 22.0
            : (isSmall ? 24.0 : (isTablet ? 32.0 : 28.0));
        final cardPadding = isTiny
            ? 8.0
            : (isSmall ? 10.0 : (isTablet ? 20.0 : 14.0));
        final fontSize = isTiny
            ? 13.0
            : (isSmall ? 14.0 : (isTablet ? 17.0 : 15.0));
        final timeFontSize = isTiny ? 10.0 : (isSmall ? 11.0 : 12.0);

        return CustomCard(
          onTap: () => _navigateToForm(alarm),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Row(
              children: [
                // Medicine Icon Container
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: alarm.enabled
                          ? [
                              AppTheme.primaryPurple.withOpacity(0.15),
                              AppTheme.primaryPurple.withOpacity(0.05),
                            ]
                          : [
                              AppTheme.textSecondary.withOpacity(0.1),
                              AppTheme.textSecondary.withOpacity(0.05),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: alarm.enabled
                          ? AppTheme.primaryPurple.withOpacity(0.1)
                          : AppTheme.textSecondary.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    color: alarm.enabled
                        ? AppTheme.primaryPurple
                        : AppTheme.textSecondary,
                    size: iconInnerSize,
                  ),
                ),

                SizedBox(width: isTiny ? 8 : 12),

                // Medicine Name and Time - Takes available space
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        alarm.medicineName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                          color: alarm.enabled
                              ? AppTheme.primaryPurple
                              : AppTheme.textSecondary,
                          fontFamily: 'IBMPlexSansArabic',
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isTiny ? 4 : 6),
                      IntrinsicWidth(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTiny ? 6 : 8,
                            vertical: isTiny ? 3 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: alarm.enabled
                                ? AppTheme.primaryPurple.withOpacity(0.08)
                                : AppTheme.textSecondary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: isTiny ? 10 : 12,
                                color: alarm.enabled
                                    ? AppTheme.primaryPurple.withOpacity(0.7)
                                    : AppTheme.textSecondary.withOpacity(0.7),
                              ),
                              SizedBox(width: isTiny ? 3 : 5),
                              Text(
                                alarm.time,
                                style: TextStyle(
                                  color: alarm.enabled
                                      ? AppTheme.primaryPurple
                                      : AppTheme.textSecondary,
                                  fontSize: timeFontSize,
                                  fontFamily: 'IBMPlexSansArabic',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: isTiny ? 6 : 8),

                // Switch - Fixed width
                SizedBox(
                  width: isTiny ? 40 : 48,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Switch(
                      value: alarm.enabled,
                      onChanged: (_) => _toggleAlarm(alarm),
                      activeThumbColor: AppTheme.primaryPurple,
                      activeTrackColor: AppTheme.primaryPurple.withOpacity(0.5),
                      inactiveThumbColor: AppTheme.textSecondary,
                      inactiveTrackColor: AppTheme.textSecondary.withOpacity(
                        0.3,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),

                SizedBox(width: isTiny ? 8 : 12),

                // Menu Button - Fixed width
                SizedBox(
                  width: isTiny ? 32 : 40,
                  height: isTiny ? 32 : 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: AppTheme.primaryPurple,
                        size: isTiny ? 16 : 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                      iconSize: isTiny ? 16 : 20,
                      onSelected: (value) {
                        if (value == 'edit') {
                          _navigateToForm(alarm);
                        } else if (value == 'delete') {
                          _deleteAlarm(alarm);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: 20,
                                color: AppTheme.primaryPurple,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'تعديل',
                                style: TextStyle(
                                  fontFamily: 'IBMPlexSansArabic',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_rounded,
                                size: 20,
                                color: AppTheme.error,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'حذف',
                                style: TextStyle(
                                  color: AppTheme.error,
                                  fontFamily: 'IBMPlexSansArabic',
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
          ),
        );
      },
    );
  }
}
