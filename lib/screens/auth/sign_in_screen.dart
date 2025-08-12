import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/supabase_auth_service.dart';
import '../../widgets/full_screen_loader.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with SingleTickerProviderStateMixin {
  final _auth = SupabaseAuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _focusEmail = FocusNode();
  final _focusPassword = FocusNode();
  late final AnimationController _fadeController;
  bool _isLoading = false;
  String? _error;

  bool get _isFormValid {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email) && password.isNotEmpty;
  }

  String _extractMessage(String raw) {
    final match = RegExp(r'message:\s*([^,\)]+)', caseSensitive: false).firstMatch(raw);
    if (match != null) return match.group(1)!.trim();
    return raw;
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..forward();
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _focusEmail.dispose();
    _focusPassword.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    // Client-side validation
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty && password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email.');
      return;
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Please enter your password.');
      return;
    }
    setState(() {
      _error = null;
      _isLoading = true;
    });
    AppLoaderOverlay.show(context);
    try {
      await _auth.signInWithEmail(email: email, password: password);
      if (mounted) context.go('/route-after-auth');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
      // Hide immediately; the route-after-auth screen now shows its own loader
      AppLoaderOverlay.hide();
    }
  }

  Future<void> _signUp() async {
    // Client-side validation
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty && password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email.');
      return;
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Please enter your password.');
      return;
    }
    setState(() {
      _error = null;
      _isLoading = true;
    });
    AppLoaderOverlay.show(context);
    try {
      await _auth.signUpWithEmail(email: email, password: password);
      if (mounted) context.go('/onboarding/niche');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
      AppLoaderOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFF7C4DFF), Color(0xFF00D4FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        child: Stack(
          children: [
            // Background subtle radial/linear gradient accents
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.6, -0.8),
                    radius: 1.2,
                    colors: [
                      const Color(0xFF14141A),
                      const Color(0xFF0F0F14),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -120,
              top: -80,
              child: _BlurCircle(color: const Color(0xFF7C4DFF).withValues(alpha: .25)),
            ),
            Positioned(
              right: -100,
              bottom: -120,
              child: _BlurCircle(color: const Color(0xFF00D4FF).withValues(alpha: .2)),
            ),

            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Center(
                        child: Image.asset(
                          'assets/img/ideaxy_logo_only.png',
                          width: 250,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (_error != null) ...[
                        _ErrorNotice(message: _extractMessage(_error!)),
                        const SizedBox(height: 12),
                      ],
                      _GlowTextField(
                        controller: _emailController,
                        label: 'Email',
                        focusNode: _focusEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _GlowTextField(
                        controller: _passwordController,
                        label: 'Password',
                        focusNode: _focusPassword,
                        obscureText: true,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: _GradientButton(
                              gradient: gradient,
                              onPressed: _isLoading || !_isFormValid ? null : _signIn,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Sign In'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _OutlinedSoftButton(
                              onPressed: _isLoading || !_isFormValid ? null : _signUp,
                              child: const Text('Create Account'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowTextField extends StatefulWidget {
  const _GlowTextField({
    required this.controller,
    required this.label,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  State<_GlowTextField> createState() => _GlowTextFieldState();
}

class _GlowTextFieldState extends State<_GlowTextField> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode?.hasFocus == true;
    final glowColor = isFocused
        ? const Color(0xFF7C4DFF).withValues(alpha: 0.5)
        : _hovered
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.transparent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: glowColor, blurRadius: 20, spreadRadius: 1),
          ],
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            labelText: widget.label,
            filled: true,
            fillColor: const Color(0xFF18181F),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2A2A35)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 1.2),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatefulWidget {
  const _GradientButton({required this.onPressed, required this.child, required this.gradient});
  final VoidCallback? onPressed;
  final Widget child;
  final Gradient gradient;

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: enabled ? widget.gradient : null,
            color: enabled ? null : Colors.white12,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (_hovered)
                const BoxShadow(color: Color(0x8027272F), blurRadius: 18, offset: Offset(0, 8)),
              if (_pressed) const BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          transform: Matrix4.identity()..translate(0.0, _pressed ? 2.0 : 0.0),
          child: DefaultTextStyle.merge(
            style: const TextStyle(fontWeight: FontWeight.w600),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _OutlinedSoftButton extends StatefulWidget {
  const _OutlinedSoftButton({required this.onPressed, required this.child});
  final VoidCallback? onPressed;
  final Widget child;
  @override
  State<_OutlinedSoftButton> createState() => _OutlinedSoftButtonState();
}

class _OutlinedSoftButtonState extends State<_OutlinedSoftButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: enabled ? Colors.white24 : Colors.white12),
            color: _hovered ? Colors.white.withValues(alpha: 0.02) : Colors.transparent,
            boxShadow: [
              if (_pressed) const BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          transform: Matrix4.identity()..translate(0.0, _pressed ? 2.0 : 0.0),
          child: DefaultTextStyle.merge(
            style: const TextStyle(fontWeight: FontWeight.w600),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 40)],
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x26FF4D4D),
        border: Border.all(color: const Color(0x4DFF4D4D)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x1AFF4D4D), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF7070)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFFFB3B3)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

