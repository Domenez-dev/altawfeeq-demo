import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../theme/app_theme.dart';
import 'voice_test_screen.dart';
import 'smartwatches_screen.dart';
import 'reports_screen.dart';
import 'persons_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
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
              debugPrint('Using Arabic voice: ${voice['name']}');
              break;
            }
          }
        }
      }

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
      });
      _flutterTts.setCompletionHandler(() {
        debugPrint('TTS completed speaking');
      });
      _flutterTts.setStartHandler(() {
        debugPrint('TTS started speaking');
      });

      debugPrint('TTS initialized successfully');
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speakLocation() async {
    debugPrint('Location button tapped - attempting to speak');

    const text =
        'تم تحديد موقعك باستخدام نظام تحديد المواقع العالمي. '
        'أنت الآن في الجزائر العاصمة، وسط شارع الحرية.';

    try {
      final result = await _flutterTts.speak(text);
      debugPrint('TTS speak result: $result');

      if (result == 0) {
        debugPrint('Speech started successfully');
      } else {
        debugPrint('Speech failed with result: $result');
      }
    } catch (e) {
      debugPrint('Error during speech: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'حدث خطأ في تشغيل الصوت',
              style: TextStyle(fontFamily: 'IBMPlexSansArabic'),
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
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(context),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildWelcomeSection(context),
                  const SizedBox(height: 24),
                  _buildServicesGrid(context),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryPurple.withOpacity(0.08),
              context.appColors.background,
            ],
          ),
        ),
        child: Column(
          children: [
            // شعار التطبيق داخل التطبيق (in app logo) — يحمل اسم Taoufik
            Image.asset(
              'assets/inapplogo.jpeg',
              height: 64,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Text(
                'Taoufik',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryPurple,
                  fontFamily: 'IBMPlexSansArabic',
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: const Text(
                'نظام المراقبة الصحية الذكي',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryPurple,
                  fontFamily: 'IBMPlexSansArabic',
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple.withOpacity(0.06),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryPurple,
                  AppTheme.primaryPurple.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مرحباً بك',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                    fontFamily: 'IBMPlexSansArabic',
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اختر خدمة للبدء',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.appColors.textSecondary,
                    fontFamily: 'IBMPlexSansArabic',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Location Icon button for TTS
          Container(
            decoration: BoxDecoration(
              color: context.appColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryPurple.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: _speakLocation,
              icon: Icon(
                Icons.location_on_rounded,
                color: AppTheme.primaryPurple,
                size: 22,
              ),
              tooltip: 'إعلان الموقع بصوت',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        double spacing = 14;

        if (constraints.maxWidth > 900) {
          crossAxisCount = 4;
          spacing = 16;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
          spacing = 16;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.0,
          children: [
            _ServiceCard(
              title: 'إختبار الصوت',
              icon: Icons.mic_rounded,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              imagePath: 'assets/voicetest.jpg',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VoiceTestScreen()),
              ),
            ),
            _ServiceCard(
              title: 'الساعات الذكية',
              icon: Icons.watch_rounded,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
              ),
              imagePath: 'assets/smarthelthwatch.jpg',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SmartwatchesScreen()),
              ),
            ),
            _ServiceCard(
              title: 'التقارير الطبية',
              icon: Icons.description_rounded,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
              ),
              imagePath: 'assets/repports.jpg',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              ),
            ),
            _ServiceCard(
              title: 'تعريف',
              icon: Icons.people_rounded,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFfa709a), Color(0xFFfee140)],
              ),
              imagePath: 'assets/persons.jpg',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PersonsScreen()),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final String imagePath;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.appColors.border.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: _isPressed
                  ? widget.gradient.colors.first.withOpacity(0.2)
                  : widget.gradient.colors.first.withOpacity(0.3),
              blurRadius: _isPressed ? 8 : 12,
              offset: Offset(0, _isPressed ? 2 : 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              Image.asset(
                widget.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(gradient: widget.gradient),
                  );
                },
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.65),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon at top
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.gradient.colors.first,
                          size: 22,
                        ),
                      ),
                    ),

                    // Title at bottom
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'IBMPlexSansArabic',
                        height: 1.3,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
