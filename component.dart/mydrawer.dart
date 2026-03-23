import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iyadunni_shopmore/Settingsscreen.dart';

import 'package:iyadunni_shopmore/service/admin_loginscreen.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  static const Color _brightBlue = Color(0xFF2952E3);
  static const Color _orange = Color(0xFFF5A623);
  static const Color _bgGrey = Color(0xFFF5F7FC);
  static const Color _textDark = Color(0xFF0D1B3E);
  static const Color _textMuted = Color(0xFF8A96B0);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Guest';
    final name = (user?.displayName?.isNotEmpty == true)
        ? user!.displayName!
        : email.split('@').first;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.83,
      backgroundColor: _bgGrey,
      child: Column(
        children: [
          _Header(name: name, email: email, initial: initial),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('MENU'),
                  const SizedBox(height: 10),

                  _MenuCard(
                    icon: Icons.home_rounded,
                    iconBg: const Color(0xFFE8EFFE),
                    iconColor: _brightBlue,
                    title: 'Home',
                    subtitle: 'Back to marketplace',
                    onTap: () => Navigator.pop(context),
                  ),

                  _MenuCard(
                    icon: Icons.settings_rounded,
                    iconBg: const Color(0xFFF0F0F5),
                    iconColor: const Color(0xFF6B7280),
                    title: 'Settings',
                    subtitle: 'Preferences & account',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SettingsScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  const _SectionLabel('SELLER'),
                  const SizedBox(height: 10),

                  // ✅ SIMPLIFIED: Always go to AdminLoginScreen
                  // The login screen handles everything from there
                  _MenuCard(
                    icon: Icons.storefront_rounded,
                    iconBg: const Color(0xFFFFF3E0),
                    iconColor: _orange,
                    title: 'Admin Panel',
                    subtitle: 'Manage orders & products',
                    badge: 'SELLER',
                    badgeColor: _orange,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SellerLoginScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _Footer(
            onLogout: () {
              Navigator.pop(context);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) _showLogoutDialog(context);
              });
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded,
                    color: Colors.red.shade400, size: 30),
              ),
              const SizedBox(height: 18),
              const Text('Log Out?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  )),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to\nlog out of ShopMore?',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 13.5, color: _textMuted, height: 1.55),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          )),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await FirebaseAuth.instance.signOut();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Log Out',
                          style: TextStyle(fontWeight: FontWeight.w700)),
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

// ══════════════════════════════════════════════
//  HEADER
// ══════════════════════════════════════════════
class _Header extends StatelessWidget {
  final String name;
  final String email;
  final String initial;
  const _Header(
      {required this.name, required this.email, required this.initial});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22, topPad + 24, 22, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B1D6E), Color(0xFF1A3FA8), Color(0xFF2952E3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
              top: -50, right: -40, child: _Ring(size: 160, opacity: 0.10)),
          Positioned(top: 10, right: 30, child: _Ring(size: 90, opacity: 0.07)),
          Positioned(
              bottom: -30, right: -10, child: _Ring(size: 110, opacity: 0.06)),
          Positioned(
              bottom: 10, left: -20, child: _Ring(size: 70, opacity: 0.05)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: const Icon(Icons.shopping_bag_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 9),
                  const Text('Bazaarflow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      )),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.35),
                      Colors.white.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.5), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Center(
                    child: Text(initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ))),
              ),
              const SizedBox(height: 14),
              Text('Hi, $name 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  )),
              const SizedBox(height: 5),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                      child: Text(
                    email,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                    ),
                  )),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
//  MENU CARD
// ══════════════════════════════════════════════
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          splashColor: iconColor.withOpacity(0.07),
          highlightColor: iconColor.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D1B3E),
                          )),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A96B0),
                            fontWeight: FontWeight.w400,
                          )),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? iconColor).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(badge!,
                        style: TextStyle(
                          color: badgeColor ?? iconColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        )),
                  )
                else
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: Color(0xFF8A96B0)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
//  FOOTER
// ══════════════════════════════════════════════
class _Footer extends StatelessWidget {
  final VoidCallback onLogout;
  const _Footer({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Log Out',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  )),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side:
                    BorderSide(color: Colors.red.withOpacity(0.3), width: 1.5),
                backgroundColor: Colors.red.withOpacity(0.04),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('ShopMore  ·  v1.0.0',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              )),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
//  SECTION LABEL
// ══════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFFB0B8CC),
            letterSpacing: 1.4,
          )),
    );
  }
}

// ══════════════════════════════════════════════
//  DECORATIVE RING
// ══════════════════════════════════════════════
class _Ring extends StatelessWidget {
  final double size;
  final double opacity;
  const _Ring({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(opacity),
          width: 1.5,
        ),
      ),
    );
  }
}
