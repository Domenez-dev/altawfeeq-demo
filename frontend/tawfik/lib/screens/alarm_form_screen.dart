import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/smartwatch.dart';
import '../models/alarm.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

class AlarmFormScreen extends StatefulWidget {
  final Smartwatch smartwatch;
  final Alarm? alarm;

  const AlarmFormScreen({super.key, required this.smartwatch, this.alarm});

  @override
  State<AlarmFormScreen> createState() => _AlarmFormScreenState();
}

class _AlarmFormScreenState extends State<AlarmFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicineController = TextEditingController();
  final _medicineFocus = FocusNode();
  final _db = DatabaseHelper.instance;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.alarm != null) {
      _medicineController.text = widget.alarm!.medicineName;
      final parts = widget.alarm!.time.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
  }

  @override
  void dispose() {
    _medicineController.dispose();
    _medicineFocus.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryPurple,
              onPrimary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryPurple,
                textStyle: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final timeString =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    final alarm = Alarm(
      id: widget.alarm?.id,
      watchId: widget.smartwatch.id!,
      medicineName: _medicineController.text.trim(),
      time: timeString,
      enabled: widget.alarm?.enabled ?? true,
    );

    try {
      if (widget.alarm == null) {
        await _db.createAlarm(alarm);
      } else {
        await _db.updateAlarm(alarm);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.alarm == null
                  ? 'تم إضافة التنبيه بنجاح'
                  : 'تم تحديث التنبيه بنجاح',
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء الحفظ',
              style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.alarm != null;
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
            child: Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.primaryPurple,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'تعديل التنبيه' : 'إضافة تنبيه جديد',
          style: TextStyle(
            color: AppTheme.primaryPurple,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 48 : 24,
              vertical: 24,
            ),
            children: [
              // Header Card
              _buildHeaderCard(isEditing),

              const SizedBox(height: 32),

              // Patient Info Card
              _buildPatientInfoCard(),

              const SizedBox(height: 24),

              // Form Fields Section
              _buildFormSection(),

              const SizedBox(height: 40),

              // Save Button
              CustomButton(
                text: _isSaving
                    ? 'جاري الحفظ...'
                    : isEditing
                    ? 'حفظ التعديلات'
                    : 'إضافة التنبيه',
                onPressed: _isSaving ? () {} : _save,
                icon: _isSaving
                    ? Icons.hourglass_empty_rounded
                    : isEditing
                    ? Icons.check_rounded
                    : Icons.add_rounded,
                isFullWidth: true,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple.withOpacity(0.08),
            AppTheme.primaryPurple.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryPurple,
                  AppTheme.primaryPurple.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.alarm_add_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'تعديل بيانات التنبيه' : 'تنبيه دوائي جديد',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditing
                      ? 'قم بتحديث معلومات التنبيه'
                      : 'حدد الدواء ووقت الإستهلاك',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.appColors.textSecondary,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.border.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_rounded,
              color: AppTheme.primaryPurple,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المريض',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.appColors.textSecondary,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.smartwatch.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.appColors.textPrimary,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.watch_rounded,
                  size: 14,
                  color: AppTheme.primaryPurple,
                ),
                const SizedBox(width: 6),
                Text(
                  'ساعة ذكية',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryPurple,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appColors.border.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تفاصيل التنبيه',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryPurple,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
          const SizedBox(height: 20),

          // Medicine Name Field
          _buildTextField(
            controller: _medicineController,
            focusNode: _medicineFocus,
            label: 'إسم الدواء',
            hint: 'أدخل إسم الدواء',
            icon: Icons.medication_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'الرجاء إدخال إسم الدواء';
              }
              if (value.trim().length < 2) {
                return 'الإسم يجب أن يكون حرفين على الأقل';
              }
              return null;
            },
            textInputAction: TextInputAction.done,
          ),

          const SizedBox(height: 20),

          // Time Picker Field
          _buildTimePicker(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputAction? textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: AppTheme.primaryPurple),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryPurple,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(fontSize: 15, fontFamily: 'IBMPlexSansArabic'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: context.appColors.textSecondary.withOpacity(0.5),
              fontSize: 14,
              fontFamily: 'IBMPlexSansArabic',
            ),
            filled: true,
            fillColor: context.appColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: context.appColors.border.withOpacity(0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: context.appColors.border.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppTheme.primaryPurple,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.error, width: 2),
            ),
            errorStyle: const TextStyle(
              fontSize: 12,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
          validator: validator,
          textInputAction: textInputAction,
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppTheme.primaryPurple,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'وقت الإستهلاك',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryPurple,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectTime,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: context.appColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.appColors.border.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryPurple,
                        AppTheme.primaryPurple.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الوقت المحدد',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appColors.textSecondary,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedTime.format(context),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.appColors.textPrimary,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: AppTheme.primaryPurple,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
