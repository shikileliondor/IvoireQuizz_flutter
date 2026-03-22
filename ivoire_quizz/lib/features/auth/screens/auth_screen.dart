import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthScreen extends StatefulWidget {
  final bool showLogin;
  const AuthScreen({super.key, this.showLogin = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const _storage = FlutterSecureStorage();
  bool _isLoading = false;
  String? _errorMessage;

  // Register controllers
  final _nameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _registerPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  // Login controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.showLogin ? 1 : 0,
    );
    _tabController.addListener(() {
      setState(() => _errorMessage = null);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _confirmPasswordController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  Dio _createDio() {
    return Dio(
      BaseOptions(
        baseUrl: 'http://10.0.2.2:8000/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer votre nom';
        _isLoading = false;
      });
      return;
    }
    if (_registerEmailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer votre email';
        _isLoading = false;
      });
      return;
    }
    if (_registerPasswordController.text.length < 8) {
      setState(() {
        _errorMessage =
            'Le mot de passe doit contenir au moins 8 caractères';
        _isLoading = false;
      });
      return;
    }
    if (_registerPasswordController.text !=
        _confirmPasswordController.text) {
      setState(() {
        _errorMessage =
            'Les mots de passe ne correspondent pas';
        _isLoading = false;
      });
      return;
    }

    try {
      final dio = _createDio();
      final response = await dio.post(
        '/auth/register',
        data: {
          'name': _nameController.text.trim(),
          'email': _registerEmailController.text.trim(),
          'password': _registerPasswordController.text,
          'password_confirmation':
              _confirmPasswordController.text,
        },
      );

      if (response.statusCode == 201) {
        final token = response.data['data']['token'];
        await _storage.write(key: 'auth_token', value: token);
        if (mounted) context.go('/home');
      }
    } on DioException catch (e) {
      String message = 'Une erreur est survenue';
      if (e.response?.data?['message'] != null) {
        message = e.response!.data['message'];
      }
      if (e.response?.data?['errors'] != null) {
        final errors = e.response!.data['errors'] as Map<String, dynamic>;
        message = (errors.values.first as List).first;
      }
      setState(() => _errorMessage = message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_loginEmailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer votre email';
        _isLoading = false;
      });
      return;
    }
    if (_loginPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage =
            'Veuillez entrer votre mot de passe';
        _isLoading = false;
      });
      return;
    }

    try {
      final dio = _createDio();
      final response = await dio.post(
        '/auth/login',
        data: {
          'email': _loginEmailController.text.trim(),
          'password': _loginPasswordController.text,
        },
      );

      if (response.statusCode == 200) {
        final token = response.data['data']['token'];
        await _storage.write(key: 'auth_token', value: token);
        if (mounted) context.go('/home');
      }
    } on DioException catch (e) {
      String message =
          'Email ou mot de passe incorrect';
      if (e.response?.data?['message'] != null) {
        message = e.response!.data['message'];
      }
      setState(() => _errorMessage = message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        setState(() => _isLoading = false);
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        setState(() {
          _errorMessage =
              'Impossible de récupérer le token Google';
          _isLoading = false;
        });
        return;
      }

      final dio = _createDio();
      final response = await dio.post(
        '/auth/google',
        data: {'token': idToken},
      );

      if (response.statusCode == 200) {
        final token = response.data['data']['token'];
        await _storage.write(key: 'auth_token', value: token);
        if (mounted) context.go('/home');
      }
    } on DioException catch (e) {
      String message = 'Erreur de connexion Google';
      if (e.response?.data?['message'] != null) {
        message = e.response!.data['message'];
      }
      setState(() => _errorMessage = message);
    } catch (e) {
      setState(() => _errorMessage = 'Erreur Google Sign In');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomPaint(
            painter: _KentePatternPainter(),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF77F00),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/images/kwame.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'IvoireQuiz',
                        style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF77F00),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3),
                  const SizedBox(height: 8),
                  Text(
                    'Connais-tu vraiment la Côte d\'Ivoire ?',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                  const SizedBox(height: 32),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFFF77F00),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF6B7280),
                      labelStyle: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: 'Inscription'),
                        Tab(text: 'Connexion'),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 560,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRegisterForm(),
                        _buildLoginForm(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.google.com/favicon.ico',
              height: 20,
              width: 20,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.g_mobiledata,
                size: 24,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Continuer avec Google',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword && !isVisible,
          style: GoogleFonts.nunito(
            fontSize: 15,
            color: const Color(0xFF1A1A2E),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.nunito(
              color: const Color(0xFF6B7280),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF6B7280),
              size: 20,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF6B7280),
                      size: 20,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFF77F00),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF4444)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFEF4444),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGoogleButton(),
        const SizedBox(height: 16),
        _buildDivider(),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _nameController,
          label: 'Nom complet',
          hint: 'Kouassi Amon',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 12),
        _buildInputField(
          controller: _registerEmailController,
          label: 'Email',
          hint: 'kouassi@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _buildInputField(
          controller: _registerPasswordController,
          label: 'Mot de passe',
          hint: '8 caractères minimum',
          icon: Icons.lock_outline,
          isPassword: true,
          isVisible: _registerPasswordVisible,
          onToggleVisibility: () => setState(
            () => _registerPasswordVisible = !_registerPasswordVisible,
          ),
        ),
        const SizedBox(height: 12),
        _buildInputField(
          controller: _confirmPasswordController,
          label: 'Confirmer le mot de passe',
          hint: 'Répétez votre mot de passe',
          icon: Icons.lock_outline,
          isPassword: true,
          isVisible: _confirmPasswordVisible,
          onToggleVisibility: () => setState(
            () => _confirmPasswordVisible = !_confirmPasswordVisible,
          ),
        ),
        const SizedBox(height: 16),
        _buildErrorMessage(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF77F00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                : Text(
                    'Créer mon compte',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGoogleButton(),
        const SizedBox(height: 16),
        _buildDivider(),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _loginEmailController,
          label: 'Email',
          hint: 'kouassi@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _buildInputField(
          controller: _loginPasswordController,
          label: 'Mot de passe',
          hint: 'Votre mot de passe',
          icon: Icons.lock_outline,
          isPassword: true,
          isVisible: _loginPasswordVisible,
          onToggleVisibility: () => setState(
            () => _loginPasswordVisible = !_loginPasswordVisible,
          ),
        ),
        const SizedBox(height: 16),
        _buildErrorMessage(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF77F00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                : Text(
                    'Se connecter',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _KentePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF77F00).withOpacity(0.04)
      ..style = PaintingStyle.fill;
    const double diamondSize = 16;
    const double spacing = 10;
    const double step = diamondSize + spacing;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        final path = Path()
          ..moveTo(x, y - diamondSize / 2)
          ..lineTo(x + diamondSize / 2, y)
          ..lineTo(x, y + diamondSize / 2)
          ..lineTo(x - diamondSize / 2, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
