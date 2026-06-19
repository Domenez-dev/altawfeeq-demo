import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/smartwatch.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

class SmartwatchFormScreen extends StatefulWidget {
  final Smartwatch? smartwatch;

  const SmartwatchFormScreen({super.key, this.smartwatch});

  @override
  State<SmartwatchFormScreen> createState() => _SmartwatchFormScreenState();
}

class _SmartwatchFormScreenState extends State<SmartwatchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _nameFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _db = DatabaseHelper.instance;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.smartwatch != null) {
      _nameController.text = widget.smartwatch!.name;
      _addressController.text = widget.smartwatch!.address;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _nameFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final smartwatch = Smartwatch(
      id: widget.smartwatch?.id,
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
    );

    try {
      if (widget.smartwatch == null) {
        await _db.createSmartwatch(smartwatch);
      } else {
        await _db.updateSmartwatch(smartwatch);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.smartwatch == null
                  ? 'تم إضافة الساعة بنجاح'
                  : 'تم تحديث الساعة بنجاح',
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
    final isEditing = widget.smartwatch != null;
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
          isEditing ? 'تعديل الساعة' : 'إضافة ساعة جديدة',
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

              // Form Fields Section
              _buildFormSection(),

              const SizedBox(height: 40),

              // Save Button
              CustomButton(
                text: _isSaving
                    ? 'جاري الحفظ...'
                    : isEditing
                    ? 'حفظ التعديلات'
                    : 'إضافة الساعة',
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
              Icons.watch_rounded,
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
                  isEditing ? 'تعديل بيانات الساعة' : 'ساعة ذكية جديدة',
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
                      ? 'قم بتحديث المعلومات أدناه'
                      : 'أدخل معلومات المريض والساعة',
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
            'معلومات المريض',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryPurple,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
          const SizedBox(height: 20),

          // Name Field
          _buildTextField(
            controller: _nameController,
            focusNode: _nameFocus,
            label: 'إسم المريض',
            hint: 'أدخل الإسم الكامل',
            icon: Icons.person_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'الرجاء إدخال إسم المريض';
              }
              if (value.trim().length < 3) {
                return 'الإسم يجب أن يكون 3 أحرف على الأقل';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              _nameFocus.unfocus();
              FocusScope.of(context).requestFocus(_addressFocus);
            },
          ),

          const SizedBox(height: 20),

          // Address Field
          _buildTextField(
            controller: _addressController,
            focusNode: _addressFocus,
            label: 'العنوان',
            hint: 'أدخل عنوان المريض',
            icon: Icons.location_on_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'الرجاء إدخال العنوان';
              }
              if (value.trim().length < 5) {
                return 'العنوان يجب أن يكون 5 أحرف على الأقل';
              }
              return null;
            },
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _save(),
            maxLines: 2,
          ),
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
    void Function(String)? onFieldSubmitted,
    int maxLines = 1,
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
          maxLines: maxLines,
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
          onFieldSubmitted: onFieldSubmitted,
        ),
      ],
    );
  }
}
