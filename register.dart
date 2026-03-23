import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iyadunni_shopmore/mainpage.dart';

// ── Colours matching Bazaarflow login screen ──
const _kBlue = Color(0xFF1A3DC4);
const _kBlueDark = Color(0xFF0F2580);
const _kBlueLight = Color(0xFFEEF2FF);
const _kBlueMid = Color(0xFF2B4EE6);
const _kInk = Color(0xFF111827);
const _kInkMid = Color(0xFF6B7280);
const _kBorder = Color(0xFFDDE5F7);
const _kSurface = Color(0xFFF5F7FF);
const _kError = Color(0xFFDC2626);

class RegisterScreen extends StatefulWidget {
  final VoidCallback? onRegistrationSuccess;
  const RegisterScreen({Key? key, this.onRegistrationSuccess})
      : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // UI state
  bool _showPass = false;
  bool _showConfirmPass = false;
  bool _isLoading = false;
  bool _submitted =
      false; // true once Register tapped — enables live validation

  // Validation errors (null = no error)
  String? _firstNameError;
  String? _lastNameError;
  String? _ageError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPassError;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _ageCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────────────────────
  bool _validate() {
    setState(() {
      _firstNameError =
          _firstNameCtrl.text.trim().isEmpty ? 'First name is required' : null;
      _lastNameError =
          _lastNameCtrl.text.trim().isEmpty ? 'Last name is required' : null;

      final age = int.tryParse(_ageCtrl.text.trim());
      if (_ageCtrl.text.trim().isEmpty) {
        _ageError = 'Age is required';
      } else if (age == null || age < 1 || age > 120) {
        _ageError = 'Enter a valid age';
      } else {
        _ageError = null;
      }

      final email = _emailCtrl.text.trim();
      if (email.isEmpty) {
        _emailError = 'Email is required';
      } else if (!email.contains('@') || !email.contains('.')) {
        _emailError = 'Enter a valid email address';
      } else {
        _emailError = null;
      }

      final pass = _passwordCtrl.text.trim();
      if (pass.isEmpty) {
        _passwordError = 'Password is required';
      } else if (pass.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
      } else {
        _passwordError = null;
      }

      if (_confirmPassCtrl.text.trim().isEmpty) {
        _confirmPassError = 'Please confirm your password';
      } else if (_confirmPassCtrl.text.trim() != pass) {
        _confirmPassError = 'Passwords do not match';
      } else {
        _confirmPassError = null;
      }
    });

    return _firstNameError == null &&
        _lastNameError == null &&
        _ageError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPassError == null;
  }

  // ── Register ─────────────────────────────────────────────────────────────
  Future<void> _register() async {
    setState(() => _submitted = true);
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Create Firebase Auth user
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      // 2. Update display name
      await cred.user!.updateDisplayName(
          '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}');

      // 3. Save to Firestore — use UID as doc ID so it's easily retrievable
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'uid': cred.user!.uid,
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'age': int.parse(_ageCtrl.text.trim()),
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      widget.onRegistrationSuccess?.call();

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => MainpageScreen()));
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'This email is already registered. Please sign in.';
          setState(() => _emailError = msg);
          break;
        case 'invalid-email':
          msg = 'The email address is not valid.';
          setState(() => _emailError = msg);
          break;
        case 'weak-password':
          msg = 'Password is too weak. Use at least 6 characters.';
          setState(() => _passwordError = msg);
          break;
        default:
          msg = e.message ?? 'Registration failed. Please try again.';
          _showSnack(msg, isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Unexpected error: ${e.toString()}', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? _kError : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kBlueDark, _kBlueMid, Color(0xFF3B5EF5)],
              ),
            ),
          ),

          // Decorative circles (matching login screen)
          Positioned(
            top: -60,
            left: -60,
            child: _circle(220, Colors.white.withOpacity(0.05)),
          ),
          Positioned(
            top: 40,
            right: -80,
            child: _circle(200, Colors.white.withOpacity(0.06)),
          ),
          Positioned(
            top: 80,
            left: 40,
            child: _circle(100, Colors.white.withOpacity(0.04)),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  child: Column(
                    children: [
                      // App icon
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3), width: 1.5),
                        ),
                        child: const Icon(Icons.bolt_rounded,
                            color: Colors.white, size: 38),
                      ),
                      const SizedBox(height: 14),
                      const Text('Bazaarflow',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          )),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Text('Create your account',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),

                // ── White form sheet ──
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(36)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 30,
                          offset: Offset(0, -6),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Blue accent bar + title
                          Row(children: [
                            Container(
                              width: 4,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _kBlue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text('Create Account',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: _kInk,
                                  letterSpacing: -0.3,
                                )),
                          ]),
                          const SizedBox(height: 4),
                          const Padding(
                            padding: EdgeInsets.only(left: 14),
                            child: Text('Fill in your details to get started',
                                style:
                                    TextStyle(fontSize: 13, color: _kInkMid)),
                          ),
                          const SizedBox(height: 28),

                          // First & Last name — side by side
                          Row(
                            children: [
                              Expanded(
                                  child: _buildField(
                                label: 'First Name',
                                hint: 'e.g. John',
                                icon: Icons.person_outline_rounded,
                                controller: _firstNameCtrl,
                                error: _firstNameError,
                                type: TextInputType.name,
                                action: TextInputAction.next,
                              )),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _buildField(
                                label: 'Last Name',
                                hint: 'e.g. Doe',
                                icon: Icons.person_outline_rounded,
                                controller: _lastNameCtrl,
                                error: _lastNameError,
                                type: TextInputType.name,
                                action: TextInputAction.next,
                              )),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Age
                          _buildField(
                            label: 'Age',
                            hint: 'e.g. 25',
                            icon: Icons.cake_outlined,
                            controller: _ageCtrl,
                            error: _ageError,
                            type: TextInputType.number,
                            action: TextInputAction.next,
                          ),
                          const SizedBox(height: 18),

                          // Email
                          _buildField(
                            label: 'Email Address',
                            hint: 'yourname@gmail.com',
                            icon: Icons.email_outlined,
                            controller: _emailCtrl,
                            error: _emailError,
                            type: TextInputType.emailAddress,
                            action: TextInputAction.next,
                          ),
                          const SizedBox(height: 18),

                          // Password
                          _buildField(
                            label: 'Password',
                            hint: 'Min. 6 characters',
                            icon: Icons.lock_outline_rounded,
                            controller: _passwordCtrl,
                            error: _passwordError,
                            obscure: !_showPass,
                            action: TextInputAction.next,
                            suffix: IconButton(
                              icon: Icon(
                                _showPass
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _kInkMid,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _showPass = !_showPass),
                            ),
                            onChanged: (_) {
                              if (_submitted) _validate();
                            },
                          ),
                          const SizedBox(height: 18),

                          // Confirm password
                          _buildField(
                            label: 'Confirm Password',
                            hint: 'Repeat your password',
                            icon: Icons.lock_outline_rounded,
                            controller: _confirmPassCtrl,
                            error: _confirmPassError,
                            obscure: !_showConfirmPass,
                            action: TextInputAction.done,
                            suffix: IconButton(
                              icon: Icon(
                                _showConfirmPass
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _kInkMid,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _showConfirmPass = !_showConfirmPass),
                            ),
                            onChanged: (_) {
                              if (_submitted) _validate();
                            },
                          ),
                          const SizedBox(height: 32),

                          // Register button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                padding: EdgeInsets.zero,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: _isLoading
                                      ? null
                                      : const LinearGradient(
                                          colors: [_kBlueDark, _kBlueMid]),
                                  color:
                                      _isLoading ? Colors.grey.shade300 : null,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: _isLoading
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: _kBlue.withOpacity(0.4),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5))
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.person_add_rounded,
                                                color: Colors.white, size: 20),
                                            SizedBox(width: 10),
                                            Text('Create Account',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: 0.3,
                                                )),
                                            SizedBox(width: 10),
                                            Icon(Icons.arrow_forward_rounded,
                                                color: Colors.white70,
                                                size: 18),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Already have account
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account?',
                                  style:
                                      TextStyle(color: _kInkMid, fontSize: 14)),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _kBlue,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('Sign In',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      )),
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
        ],
      ),
    );
  }

  // ── Field builder ────────────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    String? error,
    bool obscure = false,
    TextInputType type = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    Widget? suffix,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with blue accent bar
        Row(children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: hasError ? _kError : _kBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 7),
          Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: hasError ? _kError : _kInk,
                letterSpacing: 0.1,
              )),
        ]),
        const SizedBox(height: 8),

        // Input field
        Container(
          decoration: BoxDecoration(
            color: hasError ? const Color(0xFFFFF0F0) : _kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError ? _kError : _kBorder,
              width: hasError ? 1.5 : 1,
            ),
            boxShadow: hasError
                ? [
                    BoxShadow(
                        color: _kError.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                : [
                    BoxShadow(
                        color: _kBlue.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: type,
            textInputAction: action,
            autocorrect: false,
            onChanged: onChanged ??
                (_) {
                  if (_submitted) _validate();
                },
            style: const TextStyle(
                fontSize: 14, color: _kInk, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _kInkMid, fontSize: 13),
              prefixIcon:
                  Icon(icon, color: hasError ? _kError : _kBlue, size: 20),
              suffixIcon: suffix ??
                  (hasError
                      ? const Icon(Icons.error_outline_rounded,
                          color: _kError, size: 20)
                      : null),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),

        // Error message
        if (hasError) ...[
          const SizedBox(height: 5),
          Row(children: [
            const Icon(Icons.info_outline_rounded, color: _kError, size: 13),
            const SizedBox(width: 4),
            Expanded(
              child: Text(error,
                  style: const TextStyle(
                      color: _kError,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
        ],
      ],
    );
  }

  // ── Decorative circle ───────────────────────────────────────────────────
  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
