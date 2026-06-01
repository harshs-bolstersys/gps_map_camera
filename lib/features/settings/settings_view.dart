import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:gps_map_camera/core/constants/app_colors.dart';
import 'package:gps_map_camera/features/camera/camera_controller.dart';
import 'package:gps_map_camera/features/term_of_service/term_of_service_view.dart';
import 'package:gps_map_camera/services/adMob_helper.dart';
import 'package:gps_map_camera/services/url_launcher_service.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          log('------------- Banner Ad Loaded -------------');
          setState(() => _isBannerAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          log('------------- Banner Ad Failed: $error -------------');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraControllerProvider);
    final cameraCtrl = ref.read(cameraControllerProvider.notifier);

    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontSize: width * 0.05, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      // ── Bottom Banner Ad ──────────────────────────────────────
      bottomNavigationBar: _bannerAdWidget(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          /// Camera Section
          _section(
            title: 'Camera',
            width: width,
            children: [
              _settingsTile(
                icon: Icons.flash_on_rounded,
                title: 'Flash',
                value: cameraState.flashOn,
                width: width,
                onChanged: (v) {
                  if (v != cameraState.flashOn) cameraCtrl.toggleFlash();
                },
              ),
              _settingsTile(
                icon: Icons.flip_camera_android_rounded,
                title: 'Front Camera',
                value: cameraState.frontCamera,
                width: width,
                onChanged: (v) {
                  if (v != cameraState.frontCamera) cameraCtrl.toggleCamera();
                },
              ),
              _settingsTile(
                icon: Icons.grid_on_rounded,
                title: 'Grid Lines',
                value: cameraState.gridEnabled,
                width: width,
                onChanged: (v) {
                  if (v != cameraState.gridEnabled) cameraCtrl.toggleGrid();
                },
              ),
              _settingsTile(
                icon: Icons.photo,
                title: 'Saved to Gallery',
                value: cameraState.saveToGallery,
                width: width,
                onChanged: (v) {
                  if (v != cameraState.saveToGallery) cameraCtrl.toggleSaveToGallery();
                },
              ),
            ],
          ),

          /// About Section
          _section(
            title: 'About',
            width: width,
            children: [
              _infoTile(icon: Icons.info_outline_rounded, title: 'Version', value: '1.1.0', width: width),
              _infoTile(
                icon: Icons.star_rate_rounded,
                title: 'Rate Us',
                value: '',
                width: width,
                onTap: () {
                  AppLauncher.launch(Platform.isIOS ? AppLauncher.rateUsUrlIos : AppLauncher.rateUsUrlAndroid);
                },
              ),
              _infoTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                value: '',
                width: width,
                onTap: () {
                  AppLauncher.launch(AppLauncher.privacyPolicyUrl);
                },
              ),
              _infoTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                value: '',
                width: width,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => TermsOfServiceView()));
                },
              ),
            ],
          ),

          SizedBox(height: height * 0.05),
        ],
      ),
    );
  }

  // ── Section Widget ──────────────────────────────────────────────
  Widget _section({required String title, required List<Widget> children, required double width}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(width * 0.04, width * 0.05, width * 0.04, width * 0.02),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: width * 0.03,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: width * 0.04),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(width * 0.035),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              final isLast = e.key == children.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast) Divider(height: 0, indent: width * 0.14, endIndent: 0),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Settings Tile Widget ────────────────────────────────────────
  Widget _settingsTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required double width,
  }) {
    return ListTile(
      leading: Container(
        width: width * 0.09,
        height: width * 0.09,
        decoration: BoxDecoration(
          color: value ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(width * 0.022),
        ),
        child: Icon(icon, size: width * 0.045, color: value ? AppColors.primary : AppColors.textSecondary),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: width * 0.037, fontWeight: FontWeight.w600),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.primary,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: AppColors.divider,
        trackOutlineColor: WidgetStateProperty.resolveWith((states) => Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: width * 0.035, vertical: width * 0.01),
    );
  }

  // ── Info Tile Widget ────────────────────────────────────────────
  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
    required double width,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: width * 0.09,
        height: width * 0.09,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(width * 0.022)),
        child: Icon(icon, size: width * 0.045, color: AppColors.textSecondary),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: width * 0.037, fontWeight: FontWeight.w600),
      ),
      trailing: value.isNotEmpty
          ? Text(
              value,
              style: TextStyle(color: AppColors.textSecondary, fontSize: width * 0.032),
            )
          : Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: width * 0.055),
      contentPadding: EdgeInsets.symmetric(horizontal: width * 0.035),
    );
  }

  // ── Banner Ad Widget ────────────────────────────────────────────
  Widget _bannerAdWidget() {
    if (_bannerAd == null || !_isBannerAdLoaded) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.03),
      child: Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        alignment: Alignment.center,
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
