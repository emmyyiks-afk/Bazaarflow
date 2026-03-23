import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iyadunni_shopmore/HomeScreenone.dart';

// ═══════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════════
class _K {
  // Blues
  static const blue900 = Color(0xFF0D3380);
  static const blue800 = Color(0xFF1240A8);
  static const blue700 = Color(0xFF1A56DB);
  static const blue600 = Color(0xFF2563EB);
  static const blue500 = Color(0xFF3B82F6);
  static const blue200 = Color(0xFFBFDBFE);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue50 = Color(0xFFEFF6FF);

  // Accent — warm amber, matches the app's amber badge system
  static const amber = Color(0xFFF59E0B);
  static const amberGlow = Color(0x40F59E0B);

  // Success
  static const green = Color(0xFF059669);
  static const greenGlow = Color(0x3005966); // used as shadow
  static const greenRing = Color(0xFF34D399);

  // Surface
  static const surface = Color(0xFFF0F5FF);
  static const white = Colors.white;
  static const ink = Color(0xFF0F1E40);
  static const inkMid = Color(0xFF4B5E82);
  static const inkLight = Color(0xFF8FA2C4);
  static const border = Color(0xFFDDE5F7);
}

// ═══════════════════════════════════════════════════════════════════
// MAINPAGE SCREEN
// ═══════════════════════════════════════════════════════════════════
class MainpageScreen extends StatefulWidget {
  const MainpageScreen({Key? key}) : super(key: key);

  @override
  State<MainpageScreen> createState() => _MainpageScreenState();
}

class _MainpageScreenState extends State<MainpageScreen>
    with TickerProviderStateMixin {
  // ── Auth ────────────────────────────────────────────────────────
  // FIX: safe null-check — currentUser can theoretically be null
  // between auth state changes, so we fall back to empty strings.
  User? get _user => FirebaseAuth.instance.currentUser;
  String get _email => _user?.email ?? '';
  String get _displayName => (_user?.displayName?.isNotEmpty == true)
      ? _user!.displayName!
      : _email.split('@').first;

  // ── Animation controllers ────────────────────────────────────────
  // 1. Success ring pulse (infinite)
  late final AnimationController _ringCtrl;
  // 2. Staggered content reveal (runs once on entry)
  late final AnimationController _revealCtrl;
  // 3. Checkmark draw animation
  late final AnimationController _checkCtrl;
  // 4. Radial background rings
  late final AnimationController _bgCtrl;

  // Reveal animations (staggered)
  late final Animation<double> _checkScale;
  late final Animation<double> _checkOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _tilesSlide;
  late final Animation<double> _tilesFade;
  late final Animation<Offset> _btnSlide;
  late final Animation<double> _btnFade;

  // Ring pulse
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;

  // BG rotation
  late final Animation<double> _bgRotate;

  // ── Countdown ────────────────────────────────────────────────────
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    // ── Ring controller (infinite pulse) ──────────────────────────
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _ringScale = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut));
    _ringOpacity = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut));

    // ── BG rotation (slow) ────────────────────────────────────────
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _bgRotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(_bgCtrl);

    // ── Check animation ───────────────────────────────────────────
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut));
    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _checkCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut)));

    // ── Staggered reveal ──────────────────────────────────────────
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _revealCtrl,
            curve: const Interval(0.15, 0.55, curve: Curves.easeOut)));
    _titleFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _revealCtrl,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOut)));

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _revealCtrl,
            curve: const Interval(0.35, 0.65, curve: Curves.easeOut)));
    _cardFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _revealCtrl,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut)));

    _tilesSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _revealCtrl,
            curve: const Interval(0.50, 0.78, curve: Curves.easeOut)));
    _tilesFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _revealCtrl,
        curve: const Interval(0.50, 0.78, curve: Curves.easeOut)));

    _btnSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _revealCtrl,
            curve: const Interval(0.65, 0.90, curve: Curves.easeOut)));
    _btnFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _revealCtrl,
        curve: const Interval(0.65, 0.90, curve: Curves.easeOut)));

    // ── Fire animations ───────────────────────────────────────────
    _checkCtrl.forward();
    _revealCtrl.forward();

    // ── Auto-navigate countdown ────────────────────────────────────
    _startCountdown();
  }

  void _startCountdown() async {
    for (int i = 3; i >= 1; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _countdown = i - 1);
    }
    _navigateHome();
  }

  void _navigateHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreenOne(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _revealCtrl.dispose();
    _checkCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _K.white,
      // No default AppBar — we build our own minimal top bar
      body: Stack(
        children: [
          // ── Decorative background ──────────────────────────────
          _buildBackground(size),

          // ── Main content ───────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Minimal top row
                _buildTopRow(),

                // Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // ── Success hero ──────────────────────
                        _buildSuccessHero(),
                        const SizedBox(height: 28),

                        // ── Welcome text ──────────────────────
                        _buildWelcomeText(),
                        const SizedBox(height: 28),

                        // ── User profile card ─────────────────
                        _buildUserCard(),
                        const SizedBox(height: 16),

                        // ── Quick action tiles ────────────────
                        _buildQuickTiles(),
                        const SizedBox(height: 28),

                        // ── Go to Home button ─────────────────
                        _buildGoHomeButton(),
                        const SizedBox(height: 14),

                        // ── Sign out link ─────────────────────
                        _buildSignOutRow(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Background ─────────────────────────────────────────────────────
  Widget _buildBackground(Size size) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Base white surface
          Container(color: _K.white),

          // Top gradient blob
          Positioned(
            top: -60,
            left: -40,
            right: -40,
            child: Container(
              height: size.height * 0.42,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_K.blue900, _K.blue700, _K.blue500],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
            ),
          ),

          // Rotating decorative rings on the top section
          Positioned(
            top: -20,
            left: size.width * 0.5 - 160,
            child: AnimatedBuilder(
              animation: _bgRotate,
              builder: (_, __) => Transform.rotate(
                angle: _bgRotate.value,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                      width: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: size.width * 0.5 - 100,
            child: AnimatedBuilder(
              animation: _bgRotate,
              builder: (_, __) => Transform.rotate(
                angle: -_bgRotate.value * 0.7,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.04),
                      width: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom subtle blue tint
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _K.blue50.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top row ────────────────────────────────────────────────────────
  Widget _buildTopRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand label
          Row(
            children: const [
              Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
              SizedBox(width: 6),
              Text(
                'Bazaarflow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          // Countdown chip
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_rounded,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 5),
                Text(
                  _countdown > 0
                      ? 'Redirecting in $_countdown...'
                      : 'Loading...',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Success hero ───────────────────────────────────────────────────
  Widget _buildSuccessHero() {
    return AnimatedBuilder(
      animation: Listenable.merge([_ringCtrl, _checkCtrl]),
      builder: (_, __) {
        return ScaleTransition(
          scale: _checkScale,
          child: FadeTransition(
            opacity: _checkOpacity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring (pulsing)
                Opacity(
                  opacity: _ringOpacity.value * 0.3,
                  child: Transform.scale(
                    scale: _ringScale.value * 1.4,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _K.green,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // Middle ring (pulsing)
                Opacity(
                  opacity: _ringOpacity.value * 0.55,
                  child: Transform.scale(
                    scale: _ringScale.value * 1.15,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _K.greenRing,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                // Inner filled circle
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _K.green.withOpacity(0.9),
                        _K.green,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _K.green.withOpacity(0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Welcome text ───────────────────────────────────────────────────
  Widget _buildWelcomeText() {
    return SlideTransition(
      position: _titleSlide,
      child: FadeTransition(
        opacity: _titleFade,
        child: Column(
          children: [
            const Text(
              'Welcome back! 🎉',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You've successfully signed in to\nyour Bazaarflow account.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),

            // Email badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.white.withOpacity(0.25), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.email_rounded,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    _email,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

  // ── User profile card ──────────────────────────────────────────────
  Widget _buildUserCard() {
    return SlideTransition(
      position: _cardSlide,
      child: FadeTransition(
        opacity: _cardFade,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _K.blue700.withOpacity(0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: _K.border, width: 1),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_K.blue700, _K.blue500],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _K.blue700.withOpacity(0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _displayName.isNotEmpty
                        ? _displayName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name + email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _K.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _email,
                      style: const TextStyle(fontSize: 12, color: _K.inkLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Verified badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified_rounded,
                        color: Color(0xFF059669), size: 13),
                    SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
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

  // ── Quick action tiles ─────────────────────────────────────────────
  Widget _buildQuickTiles() {
    return SlideTransition(
      position: _tilesSlide,
      child: FadeTransition(
        opacity: _tilesFade,
        child: Row(
          children: [
            Expanded(
              child: _QuickTile(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_K.blue900, _K.blue700],
                ),
                icon: Icons.shopping_bag_rounded,
                label: 'My Orders',
                sublabel: 'Track & reorder',
                glowColor: _K.blue700,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Navigate to orders — add your route here
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _QuickTile(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F766E), Color(0xFF0891B2)],
                ),
                icon: Icons.location_on_rounded,
                label: 'Addresses',
                sublabel: 'Manage locations',
                glowColor: const Color(0xFF0891B2),
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Navigate to addresses — add your route here
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Go to Home button ──────────────────────────────────────────────
  Widget _buildGoHomeButton() {
    return SlideTransition(
      position: _btnSlide,
      child: FadeTransition(
        opacity: _btnFade,
        child: _PressableButton(
          onTap: _navigateHome,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_K.blue800, _K.blue600],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _K.blue700.withOpacity(0.40),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.home_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Go to Home',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Sign out row ───────────────────────────────────────────────────
  Widget _buildSignOutRow() {
    return FadeTransition(
      opacity: _btnFade,
      child: _PressableButton(
        onTap: _signOut,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _K.border, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.logout_rounded, color: _K.inkMid, size: 18),
              SizedBox(width: 8),
              Text(
                'Sign out instead',
                style: TextStyle(
                  color: _K.inkMid,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// QUICK TILE WIDGET
// ═══════════════════════════════════════════════════════════════════
class _QuickTile extends StatefulWidget {
  final Gradient gradient;
  final IconData icon;
  final String label;
  final String sublabel;
  final Color glowColor;
  final VoidCallback onTap;

  const _QuickTile({
    required this.gradient,
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<_QuickTile> createState() => _QuickTileState();
}

class _QuickTileState extends State<_QuickTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() => _pressed = true);
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: widget.glowColor.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon in a frosted pill
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 16),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.sublabel,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PRESSABLE BUTTON WRAPPER
// ═══════════════════════════════════════════════════════════════════
class _PressableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableButton({required this.child, required this.onTap});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() => _pressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: widget.child,
      ),
    );
  }
}
