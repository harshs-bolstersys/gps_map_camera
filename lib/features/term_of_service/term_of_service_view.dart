import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gps_map_camera/core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  terms_of_service_view.dart
//  GPS Camera — Terms of Service Screen
// ─────────────────────────────────────────────────────────────────────────────

class TermsOfServiceView extends StatefulWidget {
  /// Set [showAcceptButton] to true when shown during onboarding flow.
  final bool showAcceptButton;

  /// Called when the user taps "Accept & Continue" (onboarding flow only).
  final VoidCallback? onAccepted;

  const TermsOfServiceView({super.key, this.showAcceptButton = false, this.onAccepted});

  @override
  State<TermsOfServiceView> createState() => _TermsOfServiceViewState();
}

class _TermsOfServiceViewState extends State<TermsOfServiceView> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _hasScrolledToBottom = false;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    if (widget.showAcceptButton) {
      _scrollController.addListener(_onScroll);
    }
  }

  void _onScroll() {
    if (!_hasScrolledToBottom) {
      final max = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      if (current >= max - 80) {
        setState(() => _hasScrolledToBottom = true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── palette (complementary warm tone vs. Privacy's cool blue) ─────────────
  static const Color _accentGold = Color(0xFFFFD580);
  static const Color _bg = AppColors.background;
  static const Color _surface = AppColors.surface;
  static const Color _accent = AppColors.primary;
  static const Color _accentSoft = Color(0x33FFC107);
  static const Color _textPrimary = AppColors.textPrimary;
  static const Color _textSecondary = AppColors.textSecondary;
  static const Color _divider = AppColors.divider;
  static const Color _chipBg = Color(0xFFFFF8E1);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light),
      child: Scaffold(
        backgroundColor: _bg,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              _buildBackground(),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        children: [
                          _buildHeroCard(),
                          const SizedBox(height: 8),
                          _buildMetaChips(),
                          const SizedBox(height: 24),
                          _buildKeyPoints(),
                          const SizedBox(height: 20),
                          _buildIntroText(),
                          const SizedBox(height: 20),
                          ..._buildSections(),
                          const SizedBox(height: 8),
                          _buildContactCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.showAcceptButton) _buildAcceptBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── background blobs ──────────────────────────────────────────────────────
  Widget _buildBackground() {
    return Positioned.fill(child: CustomPaint(painter: _BlobPainter()));
  }

  // ── header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textPrimary, size: 20),
          ),
          const Spacer(),
          const Text(
            'Terms of Service',
            style: TextStyle(color: _textPrimary, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 0.3),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── hero card ─────────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8E1), Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentSoft, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: _accentSoft, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.gavel_rounded, color: _accent, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Terms of Service',
                  style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w700, height: 1.2),
                ),
                const SizedBox(height: 6),
                Text(
                  'These terms govern your use of GPS Camera. By using the app you agree to them. Please read each section carefully.',
                  style: TextStyle(color: _textSecondary, fontSize: 13, height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── meta chips ────────────────────────────────────────────────────────────
  Widget _buildMetaChips() {
    final chips = [
      (Icons.calendar_today_outlined, 'Effective June 1, 2026'),
      (Icons.tag_rounded, 'Version 1.1.0'),
      (Icons.language_rounded, 'English'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((c) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _chipBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(c.$1, color: _textSecondary, size: 13),
              const SizedBox(width: 6),
              Text(
                c.$2,
                style: const TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── key points summary ────────────────────────────────────────────────────
  Widget _buildKeyPoints() {
    final points = [
      (Icons.check_circle_outline_rounded, 'All data stays on your device'),
      (Icons.check_circle_outline_rounded, 'No account or login required'),
      (Icons.check_circle_outline_rounded, 'No ads or data selling'),
      (Icons.warning_amber_rounded, 'GPS accuracy not guaranteed'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _chipBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _accent, size: 15),
              const SizedBox(width: 7),
              const Text(
                'Key Points',
                style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(p.$1, color: p.$1 == Icons.warning_amber_rounded ? _accentGold : _accent, size: 15),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(p.$2, style: const TextStyle(color: _textSecondary, fontSize: 13, height: 1.4)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── intro text ────────────────────────────────────────────────────────────
  Widget _buildIntroText() {
    return Text(
      'Please read these Terms of Service ("Terms") carefully before using GPS Camera. '
      'By downloading, installing, or using the App, you agree to be bound by these Terms. '
      'If you do not agree, please discontinue use immediately.',
      style: TextStyle(color: _textSecondary, fontSize: 13.5, height: 1.7),
    );
  }

  // ── sections ──────────────────────────────────────────────────────────────
  List<Widget> _buildSections() {
    return List.generate(_termsSections.length, (i) {
      final section = _termsSections[i];
      final isExpanded = _expandedIndex == i;
      return _TermsTile(
        section: section,
        isExpanded: isExpanded,
        onTap: () => setState(() => _expandedIndex = isExpanded ? null : i),
      );
    });
  }

  // ── contact card ──────────────────────────────────────────────────────────
  Widget _buildContactCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mail_outline_rounded, color: _accent, size: 18),
              SizedBox(width: 8),
              Text(
                'Contact Us',
                style: TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Questions about these Terms? We\'re here to help.',
            style: TextStyle(color: _textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.business_rounded, 'HkEdgeTech LLP'),
          const SizedBox(height: 6),
          _infoRow(Icons.email_rounded, 'hkedgetech@gmail.com'),
          const SizedBox(height: 6),
          _infoRow(Icons.language_rounded, 'www.hkedgetech.com'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: _textSecondary, size: 14),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ── accept bar ────────────────────────────────────────────────────────────
  Widget _buildAcceptBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bg.withOpacity(0), _bg, _bg],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: AnimatedOpacity(
          opacity: _hasScrolledToBottom ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 300),
          child: GestureDetector(
            onTap: _hasScrolledToBottom ? () => widget.onAccepted?.call() : null,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: _accent.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: const Center(
                child: Text(
                  'Accept & Continue',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Terms Tile Widget
// ─────────────────────────────────────────────────────────────────────────────

class _TermsTile extends StatelessWidget {
  const _TermsTile({required this.section, required this.isExpanded, required this.onTap});

  final _TermsSection section;
  final bool isExpanded;
  final VoidCallback onTap;

  static const Color _surface = AppColors.surface;
  static const Color _surfaceHigh = Color(0xFFFFF8E1);
  static const Color _accent = AppColors.primary;
  static const Color _accentSoft = Color(0x33FFC107);
  static const Color _textPrimary = AppColors.textPrimary;
  static const Color _textSecondary = AppColors.textSecondary;
  static const Color _divider = AppColors.divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isExpanded ? _surfaceHigh : _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isExpanded ? _accentSoft : _divider, width: isExpanded ? 1.5 : 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: _accentSoft,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isExpanded ? _accentSoft : _divider,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(section.icon, color: isExpanded ? _accent : _textSecondary, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          section.title,
                          style: const TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(Icons.keyboard_arrow_down_rounded, color: isExpanded ? _accent : _textSecondary, size: 22),
                      ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  child: isExpanded
                      ? Column(
                          children: [
                            Divider(height: 1, color: _divider),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                              child: Text(
                                section.body,
                                style: const TextStyle(color: _textSecondary, fontSize: 13, height: 1.75),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Background Painter
// ─────────────────────────────────────────────────────────────────────────────

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0x0EA78BFA);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.07), 130, paint);

    paint.color = const Color(0x087C3AED);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.3), 100, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Data Model
// ─────────────────────────────────────────────────────────────────────────────

class _TermsSection {
  const _TermsSection(this.title, this.icon, this.body);
  final String title;
  final IconData icon;
  final String body;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Terms of Service Content
// ─────────────────────────────────────────────────────────────────────────────

const List<_TermsSection> _termsSections = [
  _TermsSection(
    '1. Acceptance of Terms',
    Icons.handshake_outlined,
    'By accessing or using GPS Camera, you confirm that:\n\n'
        '• You are at least 13 years of age (or the applicable minimum age in your jurisdiction).\n'
        '• You have read and understood these Terms.\n'
        '• You agree to be bound by them and all applicable laws and regulations.\n\n'
        'If you are using the App on behalf of an organisation, you represent that you have the authority to bind that organisation to these Terms.',
  ),
  _TermsSection(
    '2. Description of the App',
    Icons.camera_alt_outlined,
    'GPS Camera is a mobile application that allows you to:\n\n'
        '• Capture photos using your device camera.\n'
        '• Automatically embed GPS coordinates and a human-readable address onto captured photos.\n'
        '• Save GPS-stamped photos to your device\'s local photo gallery.\n'
        '• View previously saved photos within the App\'s built-in gallery/inbox.\n\n'
        'The App operates entirely on-device. No account creation, subscription, or internet access (other than optional geocoding lookups) is required for core functionality.',
  ),
  _TermsSection(
    '3. Required Permissions',
    Icons.admin_panel_settings_outlined,
    'The App requires Location, Camera, and Storage/Photo Library permissions to function. By granting these permissions you acknowledge:\n\n'
        '• Location — used solely to obtain GPS coordinates for photo stamping.\n'
        '• Camera — used solely to capture photos within the App.\n'
        '• Storage / Photo Library — used solely to save and display photos on your device.\n\n'
        'The camera view will not activate unless all permissions are granted. You may revoke permissions at any time in device Settings, which will limit or disable the relevant features.',
  ),
  _TermsSection(
    '4. User Responsibilities',
    Icons.person_outline_rounded,
    'You agree NOT to:\n\n'
        '• Capture photos of individuals without their consent where required by law.\n'
        '• Use the App in locations where photography is prohibited.\n'
        '• Use GPS-stamped photos to stalk, harass, or harm any person.\n'
        '• Reverse-engineer, decompile, or disassemble the App.\n'
        '• Use the App in any manner that damages or impairs third-party services the App relies on.\n'
        '• Use the App for any unlawful surveillance or tracking.\n\n'
        'You are solely responsible for photos you capture, save, or share, and for ensuring your use complies with all applicable laws.',
  ),
  _TermsSection(
    '5. Intellectual Property',
    Icons.copyright_rounded,
    'Our Property — The App, its design, code, graphics, and UI are the exclusive property of Your Company Name, protected by applicable intellectual property laws. You are granted a limited, non-exclusive, non-transferable, revocable licence to use the App for personal, non-commercial purposes.\n\n'
        'Your Content — You retain full ownership of all photos you capture. We claim no ownership or rights over your photos. Because photos are stored entirely on your device, you are responsible for their management, backup, and security.\n\n'
        'Restrictions — You may not copy, modify, distribute, sell, or sublicence the App without our prior written consent.',
  ),
  _TermsSection(
    '6. Privacy',
    Icons.shield_outlined,
    'Your use of the App is also governed by our Privacy Policy, which is incorporated into these Terms by reference.\n\n'
        'By using the App, you acknowledge that you have read and understood our Privacy Policy and consent to the data practices described therein.',
  ),
  _TermsSection(
    '7. Third-Party Services',
    Icons.cloud_outlined,
    'The App may interact with third-party services (e.g., platform geocoding APIs) to provide address information. These services are governed by their own terms and privacy policies.\n\n'
        'We are not responsible for the practices of any third-party service and your use of such services is at your own risk. References to third-party services do not constitute our endorsement.',
  ),
  _TermsSection(
    '8. Disclaimers',
    Icons.info_outline_rounded,
    'THE APP IS PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS WITHOUT WARRANTIES OF ANY KIND, INCLUDING WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR UNINTERRUPTED OPERATION.\n\n'
        'We do not warrant that:\n'
        '• The App will be error-free or uninterrupted.\n'
        '• GPS coordinates will be accurate or fit for any specific purpose.\n'
        '• The App will be compatible with all devices or OS versions.\n\n'
        'GPS accuracy depends on device hardware, satellite availability, and environmental conditions. Do not rely solely on App-generated GPS data for navigation or safety-critical purposes.',
  ),
  _TermsSection(
    '9. Limitation of Liability',
    Icons.balance_rounded,
    'TO THE FULLEST EXTENT PERMITTED BY LAW, YOUR COMPANY NAME SHALL NOT BE LIABLE FOR:\n\n'
        '• Indirect, incidental, special, consequential, or punitive damages.\n'
        '• Loss of profits, data, goodwill, or other intangible losses.\n'
        '• Damages arising from unauthorised access to your photos or device.\n'
        '• Damages from reliance on GPS coordinates or address information generated by the App.\n'
        '• Damages from your violation of any third party\'s rights using photos captured with the App.\n\n'
        'In jurisdictions that do not allow certain exclusions, our liability shall be limited to the maximum extent permitted by law.',
  ),
  _TermsSection(
    '10. Indemnification',
    Icons.security_rounded,
    'You agree to indemnify, defend, and hold harmless Your Company Name and its officers, directors, employees, and agents from and against any claims, liabilities, damages, losses, costs, or fees (including reasonable legal fees) arising out of or relating to:\n\n'
        '• Your violation of these Terms.\n'
        '• Your use or misuse of the App.\n'
        '• Any photos you capture, save, or share using the App.\n'
        '• Your violation of any applicable law or third-party rights.',
  ),
  _TermsSection(
    '11. Updates & Modifications',
    Icons.update_rounded,
    'We reserve the right to modify, suspend, or discontinue the App (or any part thereof) at any time with or without notice.\n\n'
        'We may also update these Terms at any time. The revised Terms will be posted within the App with an updated "Effective Date". Your continued use after changes constitutes acceptance of the new Terms.\n\n'
        'For material changes, we will provide a prominent in-app notice or prompt you to review and re-accept the updated Terms before continuing use.',
  ),
  _TermsSection(
    '12. Termination',
    Icons.block_rounded,
    'We may terminate or suspend your access to the App at our sole discretion, without notice, for conduct that we believe violates these Terms or is harmful to other users, us, or third parties.\n\n'
        'Upon termination, the licence granted to you will automatically terminate. Provisions that by their nature should survive termination — including Intellectual Property, Disclaimers, Limitation of Liability, and Indemnification — shall survive.',
  ),
  _TermsSection(
    '13. Governing Law & Disputes',
    Icons.gavel_rounded,
    'These Terms shall be governed by and construed in accordance with the laws of [Your Jurisdiction] — TODO: replace — without regard to conflict of law principles.\n\n'
        'Any dispute shall first be attempted to be resolved through good-faith negotiation. If unresolved, disputes shall be submitted to the exclusive jurisdiction of the courts in [Your Jurisdiction].\n\n'
        'If you are a consumer in a jurisdiction providing mandatory consumer protection laws, nothing in these Terms limits your rights under such laws.',
  ),
  _TermsSection(
    '14. Severability & Entire Agreement',
    Icons.article_outlined,
    'Severability — If any provision of these Terms is found invalid or unenforceable, that provision shall be limited to the minimum extent necessary, and the remaining provisions shall continue in full force.\n\n'
        'Entire Agreement — These Terms, together with the Privacy Policy, constitute the entire agreement between you and Your Company Name with respect to the App and supersede all prior agreements, communications, and understandings relating to the App.',
  ),
];
