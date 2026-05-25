import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gps_map_camera/core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  privacy_policy_view.dart
//  GPS Camera — Privacy Policy Screen
// ─────────────────────────────────────────────────────────────────────────────

class PrivacyPolicyView extends StatefulWidget {
  /// Set [showAcceptButton] to true when shown during onboarding flow.
  final bool showAcceptButton;

  /// Called when the user taps "Accept & Continue" (onboarding flow only).
  final VoidCallback? onAccepted;

  const PrivacyPolicyView({super.key, this.showAcceptButton = false, this.onAccepted});

  @override
  State<PrivacyPolicyView> createState() => _PrivacyPolicyViewState();
}

class _PrivacyPolicyViewState extends State<PrivacyPolicyView> with SingleTickerProviderStateMixin {
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

  // ── palette ──────────────────────────────────────────────────────────────
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

  // ── background gradient blobs ─────────────────────────────────────────────
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
          Text(
            'Privacy Policy',
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
            child: const Icon(Icons.shield_outlined, color: _accent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Privacy Matters',
                  style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w700, height: 1.2),
                ),
                const SizedBox(height: 6),
                Text(
                  'GPS Camera keeps all your photos and location data entirely on your device. Nothing is ever uploaded to our servers.',
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
    final chips = [('calendar_today', 'Effective June 1, 2026'), ('tag', 'Version 1.1.0'), ('language', 'English')];
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
              Icon(_iconFor(c.$1), color: _textSecondary, size: 13),
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

  IconData _iconFor(String name) {
    switch (name) {
      case 'calendar_today':
        return Icons.calendar_today_outlined;
      case 'tag':
        return Icons.tag_rounded;
      default:
        return Icons.language_rounded;
    }
  }

  // ── intro ─────────────────────────────────────────────────────────────────
  Widget _buildIntroText() {
    return Text(
      'GPS Camera ("we", "our", or "us") is committed to protecting your privacy. '
      'This Privacy Policy explains how we handle information when you use our app. '
      'Please read it carefully. By using the app you agree to these practices.',
      style: TextStyle(color: _textSecondary, fontSize: 13.5, height: 1.7),
    );
  }

  // ── sections ──────────────────────────────────────────────────────────────
  List<Widget> _buildSections() {
    return List.generate(_privacySections.length, (i) {
      final section = _privacySections[i];
      final isExpanded = _expandedIndex == i;
      return _SectionTile(
        index: i,
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
                'Questions?',
                style: TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'If you have any questions about this Privacy Policy, reach out to us:',
            style: TextStyle(color: _textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
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
                gradient: const LinearGradient(colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)]),
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
//  Section Tile Widget
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.index, required this.section, required this.isExpanded, required this.onTap});

  final int index;
  final _PolicySection section;
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
                          style: TextStyle(
                            color: isExpanded ? _textPrimary : _textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
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
                            Divider(height: 1, color: _divider, thickness: 1),
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

    paint.color = const Color(0x0F4FC3F7);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.08), 140, paint);

    paint.color = const Color(0x080288D1);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.35), 110, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Data Model
// ─────────────────────────────────────────────────────────────────────────────

class _PolicySection {
  const _PolicySection(this.title, this.icon, this.body);
  final String title;
  final IconData icon;
  final String body;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Privacy Policy Content
// ─────────────────────────────────────────────────────────────────────────────

const List<_PolicySection> _privacySections = [
  _PolicySection(
    '1. Information We Collect',
    Icons.data_object,
    'We collect the following types of information:\n\n'
        '• Location Data — Used exclusively to embed GPS coordinates and a human-readable address onto photos you capture. Processed entirely on-device; never transmitted to any server.\n\n'
        '• Camera Access — Used solely to display the viewfinder and capture photos. No images or camera feed are uploaded externally.\n\n'
        '• Storage / Photo Library — Used to save GPS-stamped photos to your gallery and to display previously saved photos inside the App.\n\n'
        '• Anonymous Device Info (optional) — Non-identifying data (OS version, device model) may be collected for crash diagnostics only.\n\n'
        'We do NOT collect names, emails, passwords, or any account credentials. No sign-up is required.',
  ),
  _PolicySection(
    '2. How We Use Your Information',
    Icons.manage_search_rounded,
    'We use collected data solely to:\n\n'
        '• Overlay GPS coordinates and a street address onto your captured photos.\n'
        '• Save stamped photos to your local device gallery on your request.\n'
        '• Display your saved photos within the App gallery/inbox.\n'
        '• Diagnose crashes using anonymous device telemetry (if applicable).\n\n'
        'We do not use your data for advertising, behavioural tracking, or profiling.',
  ),
  _PolicySection(
    '3. Data Storage & Retention',
    Icons.storage_rounded,
    'All data — including photos with embedded GPS metadata — is stored exclusively on your device\'s local storage.\n\n'
        'We do not operate any cloud storage, remote databases, or analytics pipelines that retain personal information.\n\n'
        'Photos remain on your device until you manually delete them. Uninstalling the App does not remove photos already saved to your device gallery.',
  ),
  _PolicySection(
    '4. Permissions Explained',
    Icons.admin_panel_settings_outlined,
    '• LOCATION (ACCESS_FINE_LOCATION / NSLocationWhenInUseUsageDescription)\n  Obtains precise GPS coordinates to embed in photos.\n\n'
        '• CAMERA (CAMERA / NSCameraUsageDescription)\n  Powers the camera viewfinder and photo capture.\n\n'
        '• STORAGE / PHOTO LIBRARY (READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE / NSPhotoLibraryUsageDescription)\n  Saves stamped photos to your gallery and reads them for in-app display.\n\n'
        'All three permissions are required. The camera view will not open unless all are granted. You may revoke permissions at any time in your device Settings.',
  ),
  _PolicySection(
    '5. Sharing of Information',
    Icons.share_outlined,
    'We do not sell, trade, rent, or transfer your personal information to any third party.\n\n'
        'Because all data is stored locally on your device, there is no data in our possession to share.\n\n'
        'If you choose to share a photo via your device\'s native share sheet (messaging, email, social media), that sharing is governed solely by the policies of the platform you share to.',
  ),
  _PolicySection(
    '6. Third-Party Services',
    Icons.cloud_outlined,
    '• Reverse Geocoding API — To convert GPS coordinates into a readable address, the App queries a platform geocoding service (Apple Maps on iOS / Google Maps on Android). Only coordinates are sent; no photos or personal identifiers are transmitted. Subject to Apple\'s and Google\'s privacy policies.\n\n'
        '• Crash Reporting (if applicable) — An anonymised crash reporting library may be used. No photos, location data, or personal identifiers are included in crash reports.',
  ),
  _PolicySection(
    '7. Children\'s Privacy',
    Icons.child_care_rounded,
    'The App is not directed to children under the age of 13 (or the applicable minimum age in your jurisdiction).\n\n'
        'We do not knowingly collect personal information from children. If you believe a child has provided personal information through the App, please contact us at hkedgetech@gmail.com',
  ),
  _PolicySection(
    '8. Your Rights',
    Icons.verified_user_outlined,
    'Depending on your jurisdiction, you may have rights including:\n\n'
        '• The right to access personal data we hold about you.\n'
        '• The right to request deletion of your personal data.\n'
        '• The right to withdraw consent for data processing.\n\n'
        'Because we store no personal data on external servers, exercising these rights primarily involves deleting photos from your own device. For queries, contact: hkedgetech@gmail.com',
  ),
  _PolicySection(
    '9. Security',
    Icons.lock_outline_rounded,
    'Since all data remains on your device, the security of your photos and location information depends largely on the security of your device itself.\n\n'
        'We recommend:\n'
        '• Using a strong device passcode or biometric lock.\n'
        '• Keeping your operating system and App updated.\n'
        '• Being mindful of who has physical access to your device.',
  ),
  _PolicySection(
    '10. Changes to This Policy',
    Icons.update_rounded,
    'We may update this Privacy Policy from time to time. When we do, we will revise the "Last Updated" date and increment the version number.\n\n'
        'We will notify you of material changes through an in-app notification or by prompting you to review the updated policy on next launch.\n\n'
        'Your continued use of the App after any change constitutes acceptance of the revised policy.',
  ),
];
