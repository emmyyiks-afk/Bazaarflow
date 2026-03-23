import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iyadunni_shopmore/service/seller_dashboardscreen.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  SELLER LOGIN SCREEN
//
//  Flow:
//  1. Super-admin creates seller account in Firebase Auth manually
//  2. Super-admin creates sellers/{uid} doc in Firestore
//  3. Seller opens this screen → logs in with given credentials
//  4. If seller account exists in sellers/{uid} → go to SellerDashboard
//  5. If NOT a seller account → show error (blocks non-sellers)
// ═══════════════════════════════════════════════════════════════════════════
class SellerLoginScreen extends StatefulWidget {
  const SellerLoginScreen({super.key});
  @override
  State<SellerLoginScreen> createState() => _SellerLoginScreenState();
}

class _SellerLoginScreenState extends State<SellerLoginScreen>
    with TickerProviderStateMixin {
  // ── Firebase ───────────────────────────────────────────────────────────────
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _showPass = false;
  bool _loading = false;
  String? _error;

  // ── Animations ─────────────────────────────────────────────────────────────
  late final AnimationController _masterCtrl; // staggered reveal
  late final AnimationController _orbitCtrl; // background rings
  late final AnimationController _shimCtrl; // button shimmer
  late final AnimationController _shakeCtrl; // error shake

  // Staggered intervals
  late final Animation<double> _bgFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;

  late final Animation<double> _shimAnim;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();

    _masterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _orbitCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 26))
          ..repeat();
    _shimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));

    // Background fades in first
    _bgFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut)));

    // Logo slides down from top
    _logoSlide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _masterCtrl,
            curve: const Interval(0.15, 0.55, curve: Curves.easeOut)));
    _logoFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.15, 0.50, curve: Curves.easeOut)));

    // Form card rises from bottom
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _masterCtrl,
            curve: const Interval(0.35, 0.85, curve: Curves.easeOut)));
    _cardFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.35, 0.80, curve: Curves.easeOut)));

    // Shimmer sweep
    _shimAnim = Tween<double>(begin: -1, end: 2)
        .animate(CurvedAnimation(parent: _shimCtrl, curve: Curves.easeInOut));

    // Error shake (sinusoidal)
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);

    _masterCtrl.forward();
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    _orbitCtrl.dispose();
    _shimCtrl.dispose();
    _shakeCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF060F2E),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SizedBox.expand(
            child: Stack(
              children: [
                _buildBackground(mq),
                SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minHeight: mq.size.height -
                              mq.padding.top -
                              mq.padding.bottom),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLogoSection(),
                          _buildFormCard(mq),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Background ─────────────────────────────────────────────────────────────
  Widget _buildBackground(MediaQueryData mq) {
    return FadeTransition(
      opacity: _bgFade,
      child: Stack(
        children: [
          // Main gradient
          Container(
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
                stops: [0.0, 0.30, 0.65, 1.0],
              ),
            ),
          ),

          // Top blob (covers top 46%)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: mq.size.height * 0.46,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF060F2E), Color(0xFF0D2260)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(52),
                  bottomRight: Radius.circular(52),
                ),
              ),
            ),
          ),

          // Orbiting rings
          Positioned(
            top: mq.size.height * .06,
            left: mq.size.width * .5 - 160,
            child: AnimatedBuilder(
              animation: _orbitCtrl,
              builder: (_, __) => Transform.rotate(
                angle: _orbitCtrl.value * 2 * math.pi,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(.034), width: 36),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: mq.size.height * .08,
            left: mq.size.width * .5 - 90,
            child: AnimatedBuilder(
              animation: _orbitCtrl,
              builder: (_, __) => Transform.rotate(
                angle: -_orbitCtrl.value * 2 * math.pi * .6,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(.024), width: 20),
                  ),
                ),
              ),
            ),
          ),

          // Corner accent glow
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo section ───────────────────────────────────────────────────────────
  Widget _buildLogoSection() {
    return SlideTransition(
      position: _logoSlide,
      child: FadeTransition(
        opacity: _logoFade,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
          child: Column(
            children: [
              // Store icon in frosted glass square
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(.25), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A56DB).withOpacity(.40),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('Seller Portal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  )),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(.20), width: 1),
                ),
                child: Text('Bazaarflow Marketplace',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.80),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .4,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Form card ──────────────────────────────────────────────────────────────
  Widget _buildFormCard(MediaQueryData mq) {
    return SlideTransition(
      position: _cardSlide,
      child: FadeTransition(
        opacity: _cardFade,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 32),
          padding: EdgeInsets.fromLTRB(24, 28, 24, mq.viewInsets.bottom + 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(36),
              topRight: Radius.circular(36),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4E0F7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Welcome back',
                    style: TextStyle(
                      color: Color(0xFF0A1628),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    )),
                const SizedBox(height: 4),
                Text('Sign in to manage your orders',
                    style: TextStyle(
                      color: const Color(0xFF8FA2C4),
                      fontSize: 13,
                    )),
                const SizedBox(height: 24),

                // Error banner
                if (_error != null) ...[
                  AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(
                        math.sin(_shakeAnim.value * math.pi * 6) * 6,
                        0,
                      ),
                      child: child,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFDC2626).withOpacity(.30),
                            width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Color(0xFFDC2626), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                )),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _error = null),
                            child: const Icon(Icons.close_rounded,
                                color: Color(0xFFDC2626), size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Email field label
                _FieldLabel(label: 'Email Address'),
                const SizedBox(height: 8),
                _StyledField(
                  controller: _emailCtrl,
                  hint: 'your@email.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Password field label
                _FieldLabel(label: 'Password'),
                const SizedBox(height: 8),
                _StyledField(
                  controller: _passCtrl,
                  hint: 'Enter your password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: !_showPass,
                  textInputAction: TextInputAction.done,
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _showPass = !_showPass),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _showPass
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          key: ValueKey(_showPass),
                          color: const Color(0xFF8FA2C4),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _forgotPassword,
                    child: const Text('Forgot password?',
                        style: TextStyle(
                          color: Color(0xFF1A56DB),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ),
                const SizedBox(height: 28),

                // Sign in button
                _buildSignInButton(),
                const SizedBox(height: 20),

                // Info note
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0xFFBFDBFE), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Color(0xFF1A56DB), size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your login credentials are provided by the Bazaarflow admin. '
                          'Contact support if you don\'t have an account.',
                          style: TextStyle(
                            color: const Color(0xFF3D5170),
                            fontSize: 11,
                            height: 1.5,
                          ),
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

  // ── Sign in button with shimmer ────────────────────────────────────────────
  Widget _buildSignInButton() {
    return _PressBtn(
      onTap: _loading ? () {} : _signIn,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: _loading
              ? const LinearGradient(
                  colors: [Color(0xFF8FA2C4), Color(0xFF8FA2C4)])
              : const LinearGradient(colors: [
                  Color(0xFF060F2E),
                  Color(0xFF1A56DB),
                  Color(0xFF3B82F6)
                ], stops: [
                  0.0,
                  0.5,
                  1.0
                ]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: _loading
              ? []
              : const [
                  BoxShadow(
                      color: Color(0x551A56DB),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                      spreadRadius: -3),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shimmer sweep
              if (!_loading)
                AnimatedBuilder(
                  animation: _shimAnim,
                  builder: (_, __) => Positioned(
                    left: _shimAnim.value * MediaQuery.of(context).size.width,
                    child: Container(
                      width: 60,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white.withOpacity(.18),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Label / loader
              _loading
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text('Sign In to Seller Portal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.2,
                            )),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Firebase sign in ───────────────────────────────────────────────────────
  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Sign in with Firebase Auth
      final cred = await _auth.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final uid = cred.user?.uid;
      if (uid == null) throw FirebaseAuthException(code: 'user-not-found');

      // 2. Check Firestore sellers collection — blocks non-sellers
      final sellerDoc = await _db.collection('sellers').doc(uid).get();
      if (!sellerDoc.exists) {
        // Not a seller account — sign them out immediately
        await _auth.signOut();
        throw FirebaseAuthException(code: 'not-a-seller');
      }

      // 3. Check if account is active (you can suspend sellers)
      final sellerData = sellerDoc.data() as Map<String, dynamic>;
      if (sellerData['isActive'] == false) {
        await _auth.signOut();
        throw FirebaseAuthException(code: 'user-disabled');
      }

      // 4. Navigate to seller dashboard
      if (mounted) {
        Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) =>
                  SellerDashboardScreen(sellerData: sellerData, uid: uid),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ));
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
      _shakeCtrl.forward(from: 0);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Forgot password ────────────────────────────────────────────────────────
  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() =>
          _error = 'Enter your email address first, then tap Forgot password.');
      _shakeCtrl.forward(from: 0);
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Password reset email sent to $email'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ));
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
      _shakeCtrl.forward(from: 0);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No seller account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Try again or reset it.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This seller account has been suspended.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment.';
      case 'not-a-seller':
        return 'This account is not registered as a seller.';
      default:
        return 'Sign in failed. Please try again.';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STYLED TEXT FIELD — focus-animated border + glow
// ═══════════════════════════════════════════════════════════════════════════
class _StyledField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const _StyledField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.suffixIcon,
  });

  @override
  State<_StyledField> createState() => _StyledFieldState();
}

class _StyledFieldState extends State<_StyledField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _focused ? Colors.white : const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focused ? const Color(0xFF2563EB) : const Color(0xFFD4E0F7),
          width: _focused ? 1.8 : 1.2,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(.18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focus,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        validator: widget.validator,
        style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF0A1628),
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: Color(0xFF8FA2C4), fontSize: 14),
          prefixIcon: Icon(widget.icon,
              color:
                  _focused ? const Color(0xFF1A56DB) : const Color(0xFF8FA2C4),
              size: 20),
          suffixIcon: widget.suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          errorStyle: const TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 11,
              fontWeight: FontWeight.w500),
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    );
  }
}

// ── Field label with blue accent bar ──────────────────────────────────────
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
              colors: [Color(0xFF1A56DB), Color(0xFF3B82F6)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A1628),
            )),
      ],
    );
  }
}

// ── Press-to-scale button wrapper ─────────────────────────────────────────
class _PressBtn extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressBtn({required this.child, required this.onTap});
  @override
  State<_PressBtn> createState() => _PressBtnState();
}

class _PressBtnState extends State<_PressBtn> {
  bool _d = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() => _d = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _d = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _d = false),
      child: AnimatedScale(
        scale: _d ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: widget.child,
      ),
    );
  }
}
