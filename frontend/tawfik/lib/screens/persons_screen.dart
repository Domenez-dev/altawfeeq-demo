import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../database/database_helper.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';

class PersonsScreen extends StatefulWidget {
  const PersonsScreen({super.key});

  @override
  State<PersonsScreen> createState() => _PersonsScreenState();
}

class _PersonsScreenState extends State<PersonsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FlutterTts _flutterTts = FlutterTts();
  final ImagePicker _picker = ImagePicker();
  List<Person> _persons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadPersons();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('ar-SA');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      if (await _flutterTts.isLanguageAvailable('ar-SA')) {
        final voices = await _flutterTts.getVoices;
        if (voices != null && voices is List) {
          for (var voice in voices) {
            if (voice['locale'] != null &&
                voice['locale'].toString().startsWith('ar')) {
              await _flutterTts.setVoice({
                'name': voice['name'],
                'locale': voice['locale'],
              });
              break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  Future<void> _loadPersons() async {
    setState(() => _isLoading = true);
    try {
      final persons = await _dbHelper.getAllPersons();
      setState(() {
        _persons = persons;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading persons: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('فشل تحميل الأشخاص', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isError ? AppTheme.error : AppTheme.primaryPurple,
      ),
    );
  }

  Future<void> _speakPersonName(String name) async {
    try {
      await _flutterTts.speak(name);
    } catch (e) {
      debugPrint('Error speaking: $e');
    }
  }

  Future<void> _showAddPersonDialog() async {
    final nameController = TextEditingController();
    XFile? selectedImage;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.appColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(24),
          title: Row(
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
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'إضافة شخص جديد',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                // Image picker
                GestureDetector(
                  onTap: () async {
                    final image = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      setDialogState(() => selectedImage = image);
                    }
                  },
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: context.appColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryPurple.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              File(selectedImage!.path),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryPurple.withOpacity(
                                    0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add_a_photo_rounded,
                                  size: 40,
                                  color: AppTheme.primaryPurple,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'اضغط لاختيار صورة',
                                style: TextStyle(
                                  color: context.appColors.textSecondary,
                                  fontFamily: 'IBMPlexSansArabic',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                // Name field
                Column(
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
                          child: const Icon(
                            Icons.badge_rounded,
                            size: 16,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'الإسم',
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
                    TextField(
                      controller: nameController,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'أدخل الإسم الكامل',
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
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: context.appColors.border.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryPurple,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  color: context.appColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  _showSnackBar('الرجاء إدخال الإسم', isError: true);
                  return;
                }
                if (selectedImage == null) {
                  _showSnackBar('الرجاء اختيار صورة', isError: true);
                  return;
                }
                Navigator.pop(context);
                await _addPerson(nameController.text.trim(), selectedImage!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'حفظ',
                style: TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPerson(String name, XFile imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImagePath = path.join(appDir.path, 'persons', fileName);

      final personsDir = Directory(path.join(appDir.path, 'persons'));
      if (!await personsDir.exists()) {
        await personsDir.create(recursive: true);
      }

      await File(imageFile.path).copy(savedImagePath);

      final person = Person(name: name, imagePath: savedImagePath);
      await _dbHelper.createPerson(person);
      await _loadPersons();

      if (mounted) _showSnackBar('تمت إضافة الشخص بنجاح');
    } catch (e) {
      debugPrint('Error adding person: $e');
      if (mounted) _showSnackBar('فشلت إضافة الشخص', isError: true);
    }
  }

  Future<void> _deletePerson(Person person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: AppTheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'تأكيد الحذف',
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'هل تريد حذف ${person.name}؟',
          style: const TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                color: context.appColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'حذف',
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final imageFile = File(person.imagePath);
        if (await imageFile.exists()) await imageFile.delete();

        await _dbHelper.deletePerson(person.id!);
        await _loadPersons();

        if (mounted) _showSnackBar('تم حذف الشخص بنجاح');
      } catch (e) {
        debugPrint('Error deleting person: $e');
        if (mounted) _showSnackBar('فشل حذف الشخص', isError: true);
      }
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'تعريف الأشخاص',
          style: TextStyle(
            color: AppTheme.primaryPurple,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _persons.isEmpty
          ? _buildEmptyState()
          : _buildPersonsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPersonDialog,
        backgroundColor: AppTheme.primaryPurple,
        elevation: 4,
        icon: const Icon(Icons.person_add_rounded, size: 22),
        label: const Text(
          'إضافة شخص',
          style: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.1),
                    AppTheme.primaryPurple.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 80,
                color: AppTheme.primaryPurple.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'لا توجد أشخاص محفوظة',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.appColors.textPrimary,
                fontFamily: 'IBMPlexSansArabic',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'اضغط على الزر أدناه لإضافة شخص جديد\nوتعريفه في النظام',
              style: TextStyle(
                fontSize: 15,
                color: context.appColors.textSecondary,
                fontFamily: 'IBMPlexSansArabic',
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonsList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double childAspectRatio;
        double spacing;

        if (constraints.maxWidth > 900) {
          crossAxisCount = 4;
          childAspectRatio = 0.8;
          spacing = 20;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
          childAspectRatio = 0.8;
          spacing = 16;
        } else if (constraints.maxWidth > 400) {
          crossAxisCount = 2;
          childAspectRatio = 0.75;
          spacing = 12;
        } else {
          crossAxisCount = 2;
          childAspectRatio = 0.7;
          spacing = 10;
        }

        return GridView.builder(
          padding: EdgeInsets.all(spacing),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: _persons.length,
          itemBuilder: (context, index) {
            final person = _persons[index];
            return _PersonCard(
              person: person,
              onTap: () => _speakPersonName(person.name),
              onDelete: () => _deletePerson(person),
            );
          },
        );
      },
    );
  }
}

class _PersonCard extends StatelessWidget {
  final Person person;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PersonCard({
    required this.person,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.appColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.appColors.border.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: File(person.imagePath).existsSync()
                        ? Image.file(
                            File(person.imagePath),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
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
                              Icons.person_rounded,
                              size: 60,
                              color: AppTheme.primaryPurple.withOpacity(0.3),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.error.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: context.appColors.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: context.appColors.border.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    person.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryPurple,
                      fontFamily: 'IBMPlexSansArabic',
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.volume_up_rounded,
                        size: 14,
                        color: context.appColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'اضغط للاستماع',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.appColors.textSecondary,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
