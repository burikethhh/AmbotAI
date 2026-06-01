import 'package:flutter/material.dart';

class LongPressPreview extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context) previewBuilder;
  final VoidCallback? onTap;

  const LongPressPreview({
    super.key,
    required this.child,
    required this.previewBuilder,
    this.onTap,
  });

  @override
  State<LongPressPreview> createState() => _LongPressPreviewState();
}

class _LongPressPreviewState extends State<LongPressPreview> {
  OverlayEntry? _overlayEntry;

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final renderBox = context.findRenderObject() as RenderBox;
    if (!renderBox.hasSize) return;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    final overlay = Overlay.of(context);
    final overlayHeight = overlay.context.size?.height ?? 0;

    const previewHeight = 200.0;
    var top = position.dy - previewHeight - 8;
    if (top < 0) {
      top = position.dy + size.height + 8;
    }
    if (top + previewHeight > overlayHeight) {
      top = overlayHeight - previewHeight - 16;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: top.clamp(8, overlayHeight - previewHeight - 8),
        width: size.width,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.95, end: 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: child,
          ),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(4),
            color: Colors.transparent,
            child: widget.previewBuilder(context),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPressStart: (_) => _showOverlay(),
      onLongPressEnd: (_) => _hideOverlay(),
      onLongPressCancel: _hideOverlay,
      child: widget.child,
    );
  }
}
