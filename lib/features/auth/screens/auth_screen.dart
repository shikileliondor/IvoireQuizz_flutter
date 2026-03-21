import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ivoirequizz_flutter/features/onboarding/screens/onboarding_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.showLogin = false});

  final bool showLogin;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  static const Color orange = Color(0xFFF77F00);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGray = Color(0xFF6B7280);
  static const Color cardBg = Color(0xFFF8F9FA);
  static const Color neutral = Color(0xFFE5E7EB);
  static const Color correct = Color(0xFF22C55E);
  static const Color incorrect = Color(0xFFEF4444);

  late TabController _tabController;

  late TextEditingController _nameController;
  late TextEditingController _registerEmailController;
  late TextEditingController _registerPasswordController;
  late TextEditingController _confirmPasswordController;

  late TextEditingController _loginEmailController;
  late TextEditingController _loginPasswordController;

  bool _registerPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _loginPasswordVisible = false;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.showLogin ? 1 : 0,
    );

    _nameController = TextEditingController();
    _registerEmailController = TextEditingController();
    _registerPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _loginEmailController = TextEditingController();
    _loginPasswordController = TextEditingController();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomPaint(
            painter: KentePatternPainter(),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
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
                            color: orange,
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
                            color: orange,
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.3),
                    const SizedBox(height: 8),
                    Text(
                      'Connais-tu vraiment\nla Côte d\'Ivoire ?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: textGray,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                    const SizedBox(height: 32),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: textGray,
                        labelStyle: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        tabs: const [
                          Tab(text: 'Inscription'),
                          Tab(text: 'Connexion'),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 500,
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
          side: const BorderSide(color: neutral, width: 1.5),
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
            ),
            const SizedBox(width: 12),
            Text(
              'Continuer avec Google',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textDark,
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
        const Expanded(child: Divider(color: neutral)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: textGray,
            ),
          ),
        ),
        const Expanded(child: Divider(color: neutral)),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
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
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: incorrect),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: incorrect,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: incorrect,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
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
          onToggleVisibility: () =>
              setState(() => _loginPasswordVisible = !_loginPasswordVisible),
        ),
        const SizedBox(height: 16),
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: incorrect),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: incorrect,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: incorrect,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
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
            color: textDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword && !isVisible,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: textGray,
            ),
            prefixIcon: Icon(icon, color: textGray, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: textGray,
                      size: 20,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: neutral),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: neutral),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: orange, width: 2),
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

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer votre nom';
        _isLoading = false;
      });
      return;
    }

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer votre email';
        _isLoading = false;
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _errorMessage =
            'Le mot de passe doit contenir au moins 8 caractères';
        _isLoading = false;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Les mots de passe ne correspondent pas';
        _isLoading = false;
      });
      return;
    }

    try {
      final dio = Dio();
      dio.options.baseUrl = 'http://127.0.0.1:8000/api';
      dio.options.headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final response = await dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': confirmPassword,
        },
      );

      if (response.statusCode == 201) {
        final token = response.data['data']['token'];
        const storage = FlutterSecureStorage();
        await storage.write(key: 'auth_token', value: token);
        if (mounted) context.go('/home');
      }
    } on DioException catch (e) {
      String message = 'Une erreur est survenue';
      if (e.response?.data?['message'] != null) {
        message = e.response!.data['message'];
      }
      if (e.response?.data?['errors'] != null) {
        final errors = e.response!.data['errors'] as Map<String, dynamic>;
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          message = firstError.first.toString();
        }
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

    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer votre email';
        _isLoading = false;
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer votre mot de passe';
        _isLoading = false;
      });
      return;
    }

    try {
      final dio = Dio();
      dio.options.baseUrl = 'http://127.0.0.1:8000/api';
      dio.options.headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final response = await dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final token = response.data['data']['token'];
        const storage = FlutterSecureStorage();
        await storage.write(key: 'auth_token', value: token);
        if (mounted) context.go('/home');
      }
    } on DioException catch (e) {
      String message = 'Email ou mot de passe incorrect';
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
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? account = await googleSignIn.signIn();

      if (account == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      final String? idToken = auth.idToken;

      if (idToken == null) {
        setState(() {
          _errorMessage = 'Impossible de récupérer le token Google';
          _isLoading = false;
        });
        return;
      }

      final dio = Dio();
      dio.options.baseUrl = 'http://127.0.0.1:8000/api';
      dio.options.headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final response = await dio.post(
        '/auth/google',
        data: {'token': idToken},
      );

      if (response.statusCode == 200) {
        final token = response.data['data']['token'];
        const storage = FlutterSecureStorage();
        await storage.write(key: 'auth_token', value: token);
        if (mounted) context.go('/home');
      }
    } on DioException catch (e) {
      String message = 'Erreur de connexion Google';
      if (e.response?.data?['message'] != null) {
        message = e.response!.data['message'];
      }
      setState(() => _errorMessage = message);
    } catch (_) {
      setState(() => _errorMessage = 'Erreur Google Sign In');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
