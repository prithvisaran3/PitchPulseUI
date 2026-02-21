import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isSignUp = false;

  late AnimationController _bgController;
  late AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat();
    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _logoController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (_isSignUp) {
      await auth.signUp(_emailCtrl.text.trim(), _passCtrl.text, 'manager');
    } else {
      await auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => CustomPaint(
                painter: _BgPainter(_bgController.value),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingL,
                vertical: AppConstants.spacingL,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Logo
                  _LogoWidget(controller: _logoController),

                  const SizedBox(height: 48),

                  // Form Card
                  _FormCard(
                    formKey: _formKey,
                    emailCtrl: _emailCtrl,
                    passCtrl: _passCtrl,
                    obscurePass: _obscurePass,
                    isSignUp: _isSignUp,
                    onToggleObscure: () =>
                        setState(() => _obscurePass = !_obscurePass),
                    onToggleMode: () => setState(() => _isSignUp = !_isSignUp),
                    onSubmit: _submit,
                  ),

                  const SizedBox(height: 24),

                  // Admin hint
                  Text(
                    'Admin credentials: admin@pitchpulse.io',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo ──────────────────────────────────────────────────────────────────────

class _LogoWidget extends StatelessWidget {
  final AnimationController controller;
  const _LogoWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final scale = CurvedAnimation(
            parent: controller,
            curve: const Interval(0, 0.6, curve: Curves.elasticOut));
        final fade = CurvedAnimation(
            parent: controller,
            curve: const Interval(0, 0.4, curve: Curves.easeOut));
        return Transform.scale(
          scale: scale.value,
          child: Opacity(
            opacity: fade.value,
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.textPrimary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: 0.1),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('⚡', style: TextStyle(fontSize: 38)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'PitchPulse',
                  style: AppTextStyles.displayLarge
                      .copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Club Readiness Intelligence',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Form Card ─────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscurePass;
  final bool isSignUp;
  final VoidCallback onToggleObscure;
  final VoidCallback onToggleMode;
  final VoidCallback onSubmit;

  const _FormCard({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscurePass,
    required this.isSignUp,
    required this.onToggleObscure,
    required this.onToggleMode,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSignUp ? 'Create Account' : 'Welcome Back',
              style: AppTextStyles.displaySmall,
            ),
            const SizedBox(height: 4),
            Text(
              isSignUp
                  ? 'Set up your coach workspace'
                  : 'Sign in to your workspace',
              style: AppTextStyles.bodyMedium,
            ),

            const SizedBox(height: 28),

            // Email
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined,
                    color: AppColors.textMuted, size: 18),
              ),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Enter a valid email'
                  : null,
            ),

            const SizedBox(height: 14),

            // Password
            TextFormField(
              controller: passCtrl,
              obscureText: obscurePass,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline,
                    color: AppColors.textMuted, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  onPressed: onToggleObscure,
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Min 6 characters' : null,
            ),

            // Error banner
            if (auth.error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.riskHigh.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppColors.riskHigh.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.riskHigh, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(auth.error!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.riskHigh)),
                    ),
                  ],
                ),
              ).animate().shakeX(duration: 400.ms),
            ],

            const SizedBox(height: 24),

            // Submit button
            _GradientButton(
              label: isSignUp ? 'Create Account' : 'Sign In',
              loading: auth.status == AuthStatus.loading,
              onTap: onSubmit,
            ),

            const SizedBox(height: 16),

            // Toggle mode
            Center(
              child: GestureDetector(
                onTap: onToggleMode,
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodySmall,
                    children: [
                      TextSpan(
                          text: isSignUp
                              ? 'Already have an account? '
                              : 'New here? '),
                      TextSpan(
                        text: isSignUp ? 'Sign In' : 'Create Account',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(
        begin: 0.2,
        end: 0,
        duration: 600.ms,
        delay: 300.ms,
        curve: Curves.elasticOut);
  }
}

class _GradientButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _GradientButton(
      {required this.label, required this.loading, required this.onTap});

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        if (!widget.loading) widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: widget.loading
                ? AppColors.surfaceElevated
                : AppColors.textPrimary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.textPrimary, width: 2),
            boxShadow: [
              if (!widget.loading)
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: AppColors.textPrimary, strokeWidth: 2.5),
                  )
                : Text(widget.label,
                    style:
                        AppTextStyles.labelLarge.copyWith(color: AppColors.bg)),
          ),
        ),
      ),
    );
  }
}

// ── Background Painter ────────────────────────────────────────────────────────

class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.bg,
    );

    final orbs = [
      _Orb(x: 0.15, y: 0.25, r: 0.35, phase: 0, color: const Color(0xFF1A1A1A)),
      _Orb(
          x: 0.85, y: 0.65, r: 0.3, phase: 0.5, color: const Color(0xFF262626)),
      _Orb(
          x: 0.5,
          y: 0.85,
          r: 0.25,
          phase: 0.25,
          color: const Color(0xFF141414)),
    ];

    for (final orb in orbs) {
      final dx = math.sin((t + orb.phase) * 2 * math.pi) * size.width * 0.03;
      final dy = math.cos((t + orb.phase) * 2 * math.pi) * size.height * 0.02;
      final center = Offset(size.width * orb.x + dx, size.height * orb.y + dy);
      final radius = size.width * orb.r;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = orb.color.withValues(alpha: 0.07)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80),
      );
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}

class _Orb {
  final double x, y, r, phase;
  final Color color;
  const _Orb(
      {required this.x,
      required this.y,
      required this.r,
      required this.phase,
      required this.color});
}
