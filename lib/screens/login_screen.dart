import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback? onSkip;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    this.onSkip,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    
    final result = await authService.signInWithGoogle();
    
    if (result != null) {
      widget.onLoginSuccess();
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        // Show detailed error message for debugging
        final errorMsg = authService.lastError ?? 
            (appLanguage == 'vi' ? 'Đăng nhập thất bại' : 'Sign in failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg, style: const TextStyle(fontSize: 10)),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4355F0), Color(0xFF2BC0E4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 6),
              // App Name
              const Text(
                'VFinance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              // Google Sign-In Button
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.white)
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        minimumSize: const Size(0, 36),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.g_mobiledata, size: 24),
                          const SizedBox(width: 4),
                          Text(
                            appLanguage == 'vi' ? 'Google' : 'Google',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (widget.onSkip != null)
                      TextButton(
                        onPressed: widget.onSkip,
                        child: Text(
                          appLanguage == 'vi' ? 'Bỏ qua' : 'Skip',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
