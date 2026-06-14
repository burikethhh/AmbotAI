import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/theme_colors.dart';

class DesktopToast extends ConsumerStatefulWidget {
  final String message;
  final IconData icon;
  final Duration duration;
  final VoidCallback? onDismiss;

  const DesktopToast({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
  });

  @override
  ConsumerState<DesktopToast> createState() => _DesktopToastState();
}

class _DesktopToastState extends ConsumerState<DesktopToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss?.call());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: c.isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
            border: Border.all(color: c.borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: c.textSecondary),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: c.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DesktopToastManager {
  static final DesktopToastManager _instance = DesktopToastManager._();
  factory DesktopToastManager() => _instance;
  DesktopToastManager._();

  final List<_ToastEntry> _queue = [];
  OverlayState? _overlay;

  void init(BuildContext context) {
    _overlay = Overlay.of(context);
  }

  void show(String message, {IconData icon = Icons.info_outline, Duration duration = const Duration(seconds: 3)}) {
    if (_overlay == null) return;

    final entry = _ToastEntry(
      message: message,
      icon: icon,
      duration: duration,
    );
    _queue.add(entry);

    if (_queue.length == 1) {
      _showNext();
    }
  }

  void _showNext() {
    if (_queue.isEmpty || _overlay == null) return;

    final entry = _queue.first;
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 44,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: DesktopToast(
            message: entry.message,
            icon: entry.icon,
            duration: entry.duration,
            onDismiss: () {
              overlayEntry.remove();
              _queue.removeAt(0);
              _showNext();
            },
          ),
        ),
      ),
    );

    _overlay!.insert(overlayEntry);
  }
}

class _ToastEntry {
  final String message;
  final IconData icon;
  final Duration duration;

  _ToastEntry({
    required this.message,
    required this.icon,
    required this.duration,
  });
}
