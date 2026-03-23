import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iyadunni_shopmore/register.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  DESIGN TOKENS  — deep navy → royal blue → white
// ═══════════════════════════════════════════════════════════════════════════
class _D {
  // Blues
  static const b950 = Color(0xFF060F2E);
  static const b900 = Color(0xFF0D2260);
  static const b800 = Color(0xFF1240A8);
  static const b700 = Color(0xFF1A56DB);
  static const b600 = Color(0xFF2563EB);
  static const b500 = Color(0xFF3B82F6);
  static const b400 = Color(0xFF60A5FA);
  static const b200 = Color(0xFFBFDBFE);
  static const b100 = Color(0xFFDBEAFE);
  static const b50 = Color(0xFFEFF6FF);

  // Accent gold — only for highlights
  static const gold = Color(0xFFF59E0B);
  static const goldGlow = Color(0x30F59E0B);

  // Surfaces
  static const white = Colors.white;
  static const ink = Color(0xFF0A1628);
  static const inkMid = Color(0xFF3D5170);
  static const inkSub = Color(0xFF8FA2C4);
  static const border = Color(0xFFD4E0F7);
  static const surf = Color(0xFFF4F8FF);

  // Shadows
  static List<BoxShadow> card = [
    BoxShadow(color: Color(0x1A1A56DB), blurRadius: 32, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x0D1A56DB), blurRadius: 8, offset: Offset(0, 3)),
  ];
  static List<BoxShadow> btn = [
    BoxShadow(
        color: Color(0x661A56DB),
        blurRadius: 22,
        offset: Offset(0, 8),
        spreadRadius: -3),
  ];
  static List<BoxShadow> field = [
    BoxShadow(color: Color(0x0D1A56DB), blurRadius: 8, offset: Offset(0, 2)),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
//  LOGIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Form state ───────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _rememberMe = false;
  bool _passwordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Animation controllers ─────────────────────────────────────────────
  late final AnimationController _revealCtrl; // staggered entry
  late final AnimationController _orbitCtrl; // bg ring rotation
  late final AnimationController _shimCtrl; // button shimmer
  late final AnimationController _errorShake; // shake on error

  // Reveal animations
  late final Animation<double> _bgScale;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;

  // Error shake
  late final Animation<double> _shake;

  @override
  void initState() {
    super.initState();

    // Staggered reveal — 1.4 s
    _revealCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));

    _bgScale = Tween<double>(begin: 0.50, end: 1.0).animate(CurvedAnimation(
        parent: _revealCtrl,
        curve: const Interval(0.00, 0.45, curve: Curves.easeOut)));

    _logoSlide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _revealCtrl,
            curve: const Interval(0.15, 0.55, curve: Curves.easeOut)));
    _logoFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _revealCtrl,
        curve: const Interval(0.15, 0.50, curve: Curves.easeOut)));

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _revealCtrl,
            curve: const Interval(0.30, 0.80, curve: Curves.easeOut)));
    _cardFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _revealCtrl,
        curve: const Interval(0.30, 0.75, curve: Curves.easeOut)));

    // Orbit — slow background rings
    _orbitCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 26))
          ..repeat();

    // Shimmer — button glow sweep
    _shimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();

    // Error shake
    _errorShake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _shake = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _errorShake, curve: Curves.elasticIn));

    _revealCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _revealCtrl.dispose();
    _orbitCtrl.dispose();
    _shimCtrl.dispose();
    _errorShake.dispose();
    super.dispose();
  }

  // ── Firebase sign in ─────────────────────────────────────────────────────
  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      _triggerShake();
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      HapticFeedback.heavyImpact();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _friendlyError(e.code);
        _isLoading = false;
      });
      _triggerShake();
    } catch (_) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
      _triggerShake();
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait.';
      default:
        return 'Sign in failed. Check your details.';
    }
  }

  void _triggerShake() {
    HapticFeedback.heavyImpact();
    _errorShake.forward(from: 0);
  }

  // ── Forgot password dialog ────────────────────────────────────────────────
  void _showForgotPassword() {
    final ctrl = TextEditingController(text: _emailCtrl.text.trim());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: _D.ink,
              fontSize: 18,
            )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email and we\'ll send you a reset link.',
              style: TextStyle(color: _D.inkSub, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            _StyledField(
              controller: ctrl,
              hint: 'your@email.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style:
                    TextStyle(color: _D.inkSub, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: ctrl.text.trim());
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Reset link sent! Check your inbox.'),
                  backgroundColor: _D.b700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _D.b700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Send Link',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // ── Background ──────────────────────────────────────────────
            _buildBackground(size),

            // ── Content ─────────────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Logo / brand area (fixed height)
                  _buildLogoSection(),

                  // Scrollable form card
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: FadeTransition(
                          opacity: _cardFade,
                          child: _buildFormCard(mq),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Background ────────────────────────────────────────────────────────────
  Widget _buildBackground(Size s) {
    return Positioned.fill(
      child: Stack(children: [
        Container(color: Colors.white),

        // Main deep blue blob — top half
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ScaleTransition(
            scale: _bgScale,
            alignment: Alignment.topCenter,
            child: Container(
              height: s.height * 0.46,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF060F2E),
                    Color(0xFF0D2260),
                    Color(0xFF1A56DB),
                    Color(0xFF3B82F6),
                  ],
                  stops: [0.0, 0.25, 0.62, 1.0],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(56),
                  bottomRight: Radius.circular(56),
                ),
              ),
            ),
          ),
        ),

        // Slow orbiting decorative rings
        Positioned(
          top: -s.height * 0.06,
          left: s.width * 0.5 - 180,
          child: AnimatedBuilder(
            animation: _orbitCtrl,
            builder: (_, __) => Transform.rotate(
              angle: _orbitCtrl.value * 2 * math.pi,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.038), width: 42),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: s.height * 0.02,
          left: s.width * 0.5 - 110,
          child: AnimatedBuilder(
            animation: _orbitCtrl,
            builder: (_, __) => Transform.rotate(
              angle: -_orbitCtrl.value * 2 * math.pi * 0.6,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.030), width: 22),
                ),
              ),
            ),
          ),
        ),

        // Corner glow accents
        Positioned(
            top: -50,
            left: -50,
            child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _D.b600.withOpacity(0.16),
                ))),
        Positioned(
            top: -30,
            right: -40,
            child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _D.b400.withOpacity(0.12),
                ))),

        // Bottom subtle blue tint
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: s.height * 0.18,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, _D.b50.withOpacity(0.45)],
                ),
              ),
            )),
      ]),
    );
  }

  // ── Logo / brand section ──────────────────────────────────────────────────
  Widget _buildLogoSection() {
    return SlideTransition(
      position: _logoSlide,
      child: FadeTransition(
        opacity: _logoFade,
        child: SizedBox(
          height: 210,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo mark
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.30), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _D.b900.withOpacity(0.40),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 14),

              // Brand name
              const Text(
                'Bazaarflow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),

              // Tagline
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.22), width: 1),
                ),
                child: Text(
                  'Your marketplace, reimagined',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.80),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Form card ─────────────────────────────────────────────────────────────
  Widget _buildFormCard(MediaQueryData mq) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x1A1A56DB), blurRadius: 40, offset: Offset(0, -8)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(28, 36, 28, mq.padding.bottom + 36),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card header ──────────────────────────────────────────
            _buildCardHeader(),
            const SizedBox(height: 32),

            // ── Error banner ─────────────────────────────────────────
            if (_errorMessage != null) ...[
              _buildErrorBanner(),
              const SizedBox(height: 20),
            ],

            // ── Email field ──────────────────────────────────────────
            _FieldLabel(label: 'Email Address'),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _shake,
              builder: (_, child) => Transform.translate(
                offset: Offset(
                  _errorMessage != null
                      ? math.sin(_shake.value * math.pi * 6) * 7
                      : 0,
                  0,
                ),
                child: child,
              ),
              child: _StyledField(
                controller: _emailCtrl,
                focusNode: _emailFocus,
                hint: 'Enter your email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_passwordFocus),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!v.contains('@') || !v.contains('.')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 22),

            // ── Password field ───────────────────────────────────────
            _FieldLabel(label: 'Password'),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _shake,
              builder: (_, child) => Transform.translate(
                offset: Offset(
                  _errorMessage != null
                      ? math.sin(_shake.value * math.pi * 6) * 7
                      : 0,
                  0,
                ),
                child: child,
              ),
              child: _StyledField(
                controller: _passwordCtrl,
                focusNode: _passwordFocus,
                hint: 'Enter your password',
                icon: Icons.lock_outline_rounded,
                obscureText: !_passwordVisible,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _signIn(),
                suffixIcon: GestureDetector(
                  onTap: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _passwordVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      key: ValueKey(_passwordVisible),
                      color: _D.inkSub,
                      size: 20,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6)
                    return 'Password must be at least 6 characters';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),

            // ── Forget password + Remember me ────────────────────────
            _buildOptionsRow(),
            const SizedBox(height: 28),

            // ── Sign In button ───────────────────────────────────────
            _buildSignInButton(),
            const SizedBox(height: 16),

            // ── Divider ──────────────────────────────────────────────
            _buildOrDivider(),
            const SizedBox(height: 16),

            // ── Sellers login ────────────────────────────────────────
            _buildSellersButton(),
            const SizedBox(height: 28),

            // ── Register row ─────────────────────────────────────────
            _buildRegisterRow(),
          ],
        ),
      ),
    );
  }

  // ── Card header ───────────────────────────────────────────────────────────
  Widget _buildCardHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Accent bar
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_D.b800, _D.b500]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Welcome back',
          style: TextStyle(
            color: _D.ink,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Sign in to your account to continue shopping',
          style: TextStyle(
            color: _D.inkSub,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Error banner ──────────────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) => Transform.translate(
        offset: Offset(math.sin(_shake.value * math.pi * 6) * 8, 0),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFDC2626), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _errorMessage = null),
              child: const Icon(Icons.close_rounded,
                  color: Color(0xFFFCA5A5), size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ── Options row (remember me + forgot) ───────────────────────────────────
  Widget _buildOptionsRow() {
    return Row(
      children: [
        // Remember me
        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _rememberMe ? _D.b700 : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _rememberMe ? _D.b700 : _D.border,
                    width: 1.8,
                  ),
                  boxShadow: _rememberMe
                      ? [
                          BoxShadow(
                              color: _D.b700.withOpacity(0.30),
                              blurRadius: 8,
                              offset: const Offset(0, 3)),
                        ]
                      : [],
                ),
                child: _rememberMe
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 8),
              Text('Remember me',
                  style: TextStyle(
                    color: _D.inkMid,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ),

        const Spacer(),

        // Forgot password
        GestureDetector(
          onTap: _showForgotPassword,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _D.b50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Forgot Password?',
              style: TextStyle(
                color: _D.b700,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Sign in button ────────────────────────────────────────────────────────
  Widget _buildSignInButton() {
    return _PressBtn(
      onTap: _isLoading ? null : _signIn,
      child: AnimatedBuilder(
        animation: _shimCtrl,
        builder: (_, __) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            gradient: _isLoading
                ? const LinearGradient(
                    colors: [Color(0xFFCBD5E1), Color(0xFFCBD5E1)])
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_D.b900, _D.b700, _D.b600],
                    stops: [0.0, 0.50, 1.0],
                  ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: _isLoading ? [] : _D.btn,
          ),
          child: Stack(
            children: [
              // Shimmer sweep (only when not loading)
              if (!_isLoading)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: FractionallySizedBox(
                      widthFactor: 0.36,
                      alignment: Alignment((_shimCtrl.value * 3.4) - 1.7, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.white.withOpacity(0),
                            Colors.white.withOpacity(0.10),
                            Colors.white.withOpacity(0),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),

              // Button content
              Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.login_rounded,
                                color: Colors.white, size: 17),
                          ),
                          const SizedBox(width: 12),
                          const Text('Sign In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              )),
                          const SizedBox(width: 12),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 15),
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

  // ── Divider ───────────────────────────────────────────────────────────────
  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: _D.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('or',
              style: TextStyle(
                color: _D.inkSub,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
        ),
        Expanded(child: Container(height: 1, color: _D.border)),
      ],
    );
  }

  // ── Sellers button ────────────────────────────────────────────────────────
  Widget _buildSellersButton() {
    return _PressBtn(
      onTap: () {
        // Add Sellers Login navigation here
      },
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _D.b200, width: 1.5),
          boxShadow: _D.field,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _D.b50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.storefront_rounded, color: _D.b700, size: 17),
            ),
            const SizedBox(width: 10),
            Text('Sellers Login',
                style: TextStyle(
                  color: _D.b700,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                )),
          ],
        ),
      ),
    );
  }

  // ── Register row ──────────────────────────────────────────────────────────
  Widget _buildRegisterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account?",
            style: TextStyle(
              color: _D.inkSub,
              fontSize: 14,
            )),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const RegisterScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 400),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_D.b800, _D.b600]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _D.b700.withOpacity(0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Register here',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STYLED TEXT FIELD
// ═══════════════════════════════════════════════════════════════════════════
class _StyledField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.validator,
  });

  @override
  State<_StyledField> createState() => _StyledFieldState();
}

class _StyledFieldState extends State<_StyledField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _focused = widget.focusNode?.hasFocus ?? false);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _focused ? Colors.white : _D.surf,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focused ? _D.b600 : _D.border,
          width: _focused ? 1.8 : 1.2,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                    color: _D.b600.withOpacity(0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 4))
              ]
            : _D.field,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted,
        validator: widget.validator,
        autocorrect: false,
        style: const TextStyle(
          fontSize: 15,
          color: _D.ink,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: _D.inkSub,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(14),
            child: Icon(
              widget.icon,
              color: _focused ? _D.b700 : _D.inkSub,
              size: 20,
            ),
          ),
          suffixIcon: widget.suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: widget.suffixIcon)
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          errorStyle: const TextStyle(
            color: Color(0xFFDC2626),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  FIELD LABEL
// ═══════════════════════════════════════════════════════════════════════════
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_D.b700, _D.b500],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _D.ink,
              letterSpacing: -0.1,
            )),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PRESSABLE BUTTON WRAPPER
// ═══════════════════════════════════════════════════════════════════════════
class _PressBtn extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _PressBtn({required this.child, required this.onTap});

  @override
  State<_PressBtn> createState() => _PressBtnState();
}

class _PressBtnState extends State<_PressBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (widget.onTap == null) return;
        setState(() => _down = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: widget.child,
      ),
    );
  }
}
