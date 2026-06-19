import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.appColors.background,
              AppTheme.primaryPurple.withOpacity(0.05),
              AppTheme.primaryPurple.withOpacity(0.15),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Logo or Balloon representation
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPurple.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(80),
                    child: Image.asset(
                      'assets/tawfiklogo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.lightPurple,
                                AppTheme.primaryPurple,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.air_rounded,
                            size: 80,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                Text(
                  'مرحباً بك في',
                  style: TextStyle(
                    fontSize: 18,
                    color: context.appColors.textSecondary,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'التوفيق',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                    fontFamily: 'IBMPlexSansArabic',
                    height: 1.0,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'تطبيق ذكي لمتابعة المؤشرات الصوتية',
                  style: TextStyle(
                    fontSize: 16,
                    color: context.appColors.textSecondary,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(),
                
                // Buttons
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: AppTheme.primaryPurple.withOpacity(0.4),
                  ),
                  child: const Text(
                    'ابدأ الآن',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                OutlinedButton(
                  onPressed: () {
                    // Logic for login
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryPurple,
                    minimumSize: const Size(double.infinity, 56),
                    side: const BorderSide(color: AppTheme.primaryPurple, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                TextButton(
                  onPressed: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ليس لديك حساب؟ ',
                        style: TextStyle(
                          color: context.appColors.textSecondary,
                          fontSize: 14,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                      const Text(
                        'إنشاء حساب',
                        style: TextStyle(
                          color: AppTheme.primaryPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
      ),
    );
  }
}
