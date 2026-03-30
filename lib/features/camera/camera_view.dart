import 'package:camera/camera.dart' as cam;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gps_map_camera/features/settings/settings_view.dart';
import 'package:gps_map_camera/core/constants/app_colors.dart';
import 'camera_controller.dart';
import 'package:gps_map_camera/features/gallery/gallery_view.dart';

class CameraView extends ConsumerWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cameraControllerProvider);
    final ctrl = ref.read(cameraControllerProvider.notifier);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // ── TOP TOOLBAR ────────────────────────────────────────
              _TopToolbar(state: state, ctrl: ctrl),

              // ── VIEWFINDER ─────────────────────────────────────────
              Expanded(
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    Positioned.fill(child: _CameraPreviewBg(frontCamera: state.frontCamera)),
                    if (state.gridEnabled) const _GridOverlay(),
                    Positioned(bottom: 12, left: 10, right: 10, child: _GpsStampPreview(state: state)),
                    if (state.isCapturing && state.flashOn)
                      Container(color: Colors.white.withOpacity(state.frontCamera ? 1 : 0.0)),
                  ],
                ),
              ),

              // ── BOTTOM CONTROLS ────────────────────────────────────
              _BottomControls(state: state, ctrl: ctrl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Camera Preview Background ───────────────────────────────────────────────

class _CameraPreviewBg extends ConsumerStatefulWidget {
  final bool frontCamera;

  const _CameraPreviewBg({required this.frontCamera});

  @override
  ConsumerState<_CameraPreviewBg> createState() => _CameraPreviewBgState();
}

class _CameraPreviewBgState extends ConsumerState<_CameraPreviewBg> {
  cam.CameraController? _controller;
  bool _loading = true;
  String? _error;
  bool _disposed = false;
  Future<void> _camQueue = Future.value();

  Future<void> _syncFlashMode() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final cameraState = ref.read(cameraControllerProvider);
    final useTorch = cameraState.flashOn && !cameraState.frontCamera;
    try {
      await c.setFlashMode(useTorch ? cam.FlashMode.torch : cam.FlashMode.off);
    } catch (e, st) {
      debugPrint('setFlashMode failed: $e\n$st');
      // Some devices/front camera combinations don't support torch.
      try {
        await c.setFlashMode(cam.FlashMode.off);
      } catch (_) {}
    }
  }

  void _scheduleOpen() {
    _camQueue = _camQueue.then((_) => _openCamera());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleOpen();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    ref.read(nativeCameraControllerProvider.notifier).state = null;
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  cam.CameraDescription _pickLens(List<cam.CameraDescription> cameras, bool front) {
    final want = front ? cam.CameraLensDirection.front : cam.CameraLensDirection.back;
    for (final c in cameras) {
      if (c.lensDirection == want) return c;
    }
    return cameras.first;
  }

  Future<void> _openCamera() async {
    if (!mounted || _disposed) return;
    final wantFront = ref.read(cameraControllerProvider).frontCamera;

    try {
      final cameras = await cam.availableCameras();
      if (!mounted || _disposed) return;
      if (cameras.isEmpty) {
        if (mounted && !_disposed) {
          setState(() {
            _loading = false;
            _error = 'No camera found';
          });
        }
        return;
      }

      final target = _pickLens(cameras, wantFront);
      final c = _controller;

      if (c != null && c.value.isInitialized && c.description.name == target.name) {
        await _syncFlashMode();
        if (mounted && !_disposed) {
          setState(() {
            _loading = false;
            _error = null;
          });
        }
        ref.read(nativeCameraControllerProvider.notifier).state = c;
        return;
      }

      ref.read(nativeCameraControllerProvider.notifier).state = null;
      if (mounted && !_disposed) {
        setState(() {
          _loading = true;
          _error = null;
        });
      }

      if (c != null && c.value.isInitialized) {
        try {
          await c.setDescription(target);
          if (!mounted || _disposed) return;
          _controller = c;
          await _syncFlashMode();
          if (mounted && !_disposed) {
            setState(() {
              _loading = false;
              _error = null;
            });
          }
          ref.read(nativeCameraControllerProvider.notifier).state = c;
          return;
        } catch (e, st) {
          debugPrint('setDescription failed, recreating: $e\n$st');
          await c.dispose();
          if (!mounted || _disposed) return;
          _controller = null;
        }
      }

      final old = _controller;
      _controller = null;
      await old?.dispose();
      if (!mounted || _disposed) return;

      final next = cam.CameraController(target, cam.ResolutionPreset.high, enableAudio: false);
      await next.initialize();
      if (!mounted || _disposed) {
        await next.dispose();
        return;
      }
      _controller = next;
      await _syncFlashMode();
      if (mounted && !_disposed) {
        setState(() {
          _loading = false;
          _error = null;
        });
      }
      ref.read(nativeCameraControllerProvider.notifier).state = next;
    } catch (e, st) {
      debugPrint('Camera open failed: $e\n$st');
      if (mounted && !_disposed) {
        setState(() {
          _loading = false;
          _error = 'Camera unavailable';
        });
      }
    }
  }

  // ─── Cover Preview ─────────────────────────────────────────────────────────────
  Widget _coverPreview(cam.CameraController controller) {
    return cam.CameraPreview(controller);
  }

  Widget _staticFallback({bool showLoading = false, String? message}) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white30),
                    ),
                  )
                else ...[
                  Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white.withOpacity(0.05)),
                  const SizedBox(height: 8),
                  Text(
                    message ?? 'Camera Preview',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12, letterSpacing: message != null ? 0 : 2),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(cameraControllerProvider.select((s) => s.frontCamera), (previous, next) {
      if (previous != null && previous != next) _scheduleOpen();
    });
    ref.listen<bool>(cameraControllerProvider.select((s) => s.flashOn), (previous, next) {
      if (previous != next) {
        _camQueue = _camQueue.then((_) => _syncFlashMode());
      }
    });

    if (_error != null) {
      return _staticFallback(message: _error);
    }
    if (_loading || _controller == null || !_controller!.value.isInitialized) {
      return _staticFallback(showLoading: true);
    }

    return _coverPreview(_controller!);
  }
}

// ─── Top Toolbar ─────────────────────────────────────────────────────────────

class _TopToolbar extends StatelessWidget {
  final CameraState state;
  final CameraController ctrl;
  const _TopToolbar({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _TopBtn(
            icon: state.flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            label: state.flashOn ? 'On' : 'Off',
            active: state.flashOn,
            onTap: ctrl.toggleFlash,
          ),
          _TopBtn(
            icon: state.gridEnabled ? Icons.grid_on_rounded : Icons.grid_off_rounded,
            label: 'Grid',
            active: state.gridEnabled,
            onTap: ctrl.toggleGrid,
          ),
          _TopBtn(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsView())),
          ),
        ],
      ),
    );
  }
}

class _TopBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  const _TopBtn({required this.icon, required this.label, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: active ? AppColors.primary.withOpacity(0.25) : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: active ? AppColors.primary : Colors.white.withOpacity(0.15), width: active ? 1.5 : 1),
            ),
            child: Icon(icon, color: active ? AppColors.primary : Colors.white.withOpacity(0.8), size: 20),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: active ? AppColors.primary : Colors.white.withOpacity(0.5),
              fontSize: 9,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GPS Stamp Preview ───────────────────────────────────────────────────────

class _GpsStampPreview extends StatelessWidget {
  final CameraState state;
  const _GpsStampPreview({required this.state});

  @override
  Widget build(BuildContext context) {
    final loc = state.currentLocation;
    if (loc == null) return const SizedBox.shrink();

    final now = DateTime.now(); // Local time
    final months = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];
    final dateStr = '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]}, ${now.year}';

    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final hour12 = (now.hour % 12 == 0) ? 12 : now.hour % 12;
    final timeStr = '$hour12:${now.minute.toString().padLeft(2, '0')} $amPm';

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.82),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Map thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
              child: Container(
                width: 62,
                color: const Color(0xFF2D4A3E),
                child: Icon(Icons.location_on, color: Colors.red, size: 22),
              ),
            ),

            // GPS info text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App branding
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(3)),
                          child: const Icon(Icons.camera_alt, size: 9, color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'GPS Map Camera',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Address
                    Text(
                      state.currentAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, height: 1.2),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 3),

                    // Coordinates
                    Text(
                      'Lat ${loc.latitude.toStringAsFixed(6)}°  Long ${loc.longitude.toStringAsFixed(6)}°',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9),
                    ),
                    const SizedBox(height: 2),

                    // Date & time
                    Text('$dateStr - $timeStr', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9)),

                    // Optional extras
                    if (state.stampConfig.showAltitude && state.altitude != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Alt: ${state.altitude!.toStringAsFixed(1)}m  ±${state.accuracy?.toStringAsFixed(1) ?? '--'}m',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9),
                      ),
                    ],
                    if (state.stampConfig.showCompass && state.compassBearing != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.explore_rounded, size: 10, color: Colors.white.withOpacity(0.6)),
                          const SizedBox(width: 3),
                          Text(
                            '${state.compassBearing!.toStringAsFixed(0)}° ${_bearing(state.compassBearing!)}',
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _bearing(double deg) {
    if (deg < 22.5 || deg >= 337.5) return 'N';
    if (deg < 67.5) return 'NE';
    if (deg < 112.5) return 'E';
    if (deg < 157.5) return 'SE';
    if (deg < 202.5) return 'S';
    if (deg < 247.5) return 'SW';
    if (deg < 292.5) return 'W';
    return 'NW';
  }
}

// ─── Bottom Controls ─────────────────────────────────────────────────────────
class _BottomControls extends StatelessWidget {
  final CameraState state;
  final CameraController ctrl;
  const _BottomControls({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Photo tab
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_ModeTab(label: 'PHOTO', selected: true, onTap: () {})],
          ),
          const SizedBox(height: 16),

          // Main controls row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Collection
                _BottomNavBtn(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GalleryView())),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                          color: Colors.white.withOpacity(0.06),
                        ),
                        child: const Icon(Icons.collections_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(height: 5),
                      const Text('Collection', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),

                // Locations
                // _BottomNavBtn(
                //   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationsView())),
                //   child: Column(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       Container(
                //         width: 44,
                //         height: 44,
                //         decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white.withOpacity(0.06)),
                //         child: const Icon(Icons.location_on_rounded, color: Colors.white70, size: 22),
                //       ),
                //       const SizedBox(height: 5),
                //       const Text('Locations', style: TextStyle(color: Colors.white54, fontSize: 10)),
                //     ],
                //   ),
                // ),

                // ── Shutter ──
                GestureDetector(
                  onTap: ctrl.capturePhoto,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: state.isCapturing ? 66 : 72,
                    height: state.isCapturing ? 66 : 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.55), blurRadius: 20, spreadRadius: 2)],
                    ),
                    child: null,
                  ),
                ),
                _TopBtn(
                  icon: Icons.flip_camera_android_rounded,
                  label: 'Flip',
                  active: state.frontCamera,
                  onTap: ctrl.toggleCamera,
                ),
                // File Name
                // _BottomNavBtn(
                //   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FileNameView())),
                //   child: Column(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       Container(
                //         width: 44,
                //         height: 44,
                //         decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white.withOpacity(0.06)),
                //         child: const Icon(Icons.drive_file_rename_outline_rounded, color: Colors.white70, size: 22),
                //       ),
                //       const SizedBox(height: 5),
                //       const Text('File Name', style: TextStyle(color: Colors.white54, fontSize: 10)),
                //     ],
                //   ),
                // ),

                // Template
                // _BottomNavBtn(
                //   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TemplatesView())),
                //   child: Column(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       Container(
                //         width: 44,
                //         height: 44,
                //         decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white.withOpacity(0.06)),
                //         child: const Icon(Icons.grid_view_rounded, color: Colors.white70, size: 22),
                //       ),
                //       const SizedBox(height: 5),
                //       const Text('Template', style: TextStyle(color: Colors.white54, fontSize: 10)),
                //     ],
                //   ),
                // ),
                // SizedBox(width: 44, height: 44),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _BottomNavBtn({required this.child, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: child);
}

// ─── Mode Tab ─────────────────────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : Colors.white24, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white54,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ─── Grid Overlay ─────────────────────────────────────────────────────────────

class _GridOverlay extends StatelessWidget {
  const _GridOverlay();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _GridPainter(), size: Size.infinite);
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 0.6;
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), p);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), p);
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), p);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), p);
  }

  @override
  bool shouldRepaint(_) => false;
}
