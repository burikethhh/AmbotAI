import 'package:flutter/material.dart';

enum PanelAxis { horizontal, vertical }

class ResizablePanel extends StatefulWidget {
  final Widget child;
  final Widget panel;
  final PanelAxis axis;
  final double initialRatio;
  final double minRatio;
  final double maxRatio;
  final bool collapsible;
  final bool collapsed;
  final VoidCallback? onToggleCollapse;
  final Color? dividerColor;
  final double dividerThickness;
  final String? panelId;
  final ValueChanged<double>? onRatioChanged;

  const ResizablePanel({
    super.key,
    required this.child,
    required this.panel,
    this.axis = PanelAxis.horizontal,
    this.initialRatio = 0.7,
    this.minRatio = 0.2,
    this.maxRatio = 0.9,
    this.collapsible = false,
    this.collapsed = false,
    this.onToggleCollapse,
    this.dividerColor,
    this.dividerThickness = 4.0,
    this.panelId,
    this.onRatioChanged,
  });

  @override
  State<ResizablePanel> createState() => _ResizablePanelState();
}

class _ResizablePanelState extends State<ResizablePanel> {
  late double _ratio;
  late bool _collapsed;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _ratio = widget.initialRatio;
    _collapsed = widget.collapsed;
  }

  @override
  void didUpdateWidget(ResizablePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collapsed != widget.collapsed) {
      _collapsed = widget.collapsed;
    }
  }

  void _onDragStart(DragStartDetails details) {
    setState(() => _dragging = true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final total = widget.axis == PanelAxis.horizontal ? size.width : size.height;
    final delta = widget.axis == PanelAxis.horizontal ? details.delta.dx : details.delta.dy;
    setState(() {
      _ratio = (_ratio + delta / total).clamp(widget.minRatio, widget.maxRatio);
    });
    widget.onRatioChanged?.call(_ratio);
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() => _dragging = false);
  }

  void _toggleCollapse() {
    setState(() => _collapsed = !_collapsed);
    widget.onToggleCollapse?.call();
  }

  @override
  Widget build(BuildContext context) {
    final dividerColor = _dragging
        ? Theme.of(context).colorScheme.primary
        : (widget.dividerColor ?? Theme.of(context).dividerColor);

    if (widget.axis == PanelAxis.horizontal) {
      return _buildHorizontal(dividerColor);
    }
    return _buildVertical(dividerColor);
  }

  Widget _buildHorizontal(Color dividerColor) {
    if (_collapsed) {
      return widget.child;
    }
    return Row(
      children: [
        Expanded(
          flex: (_ratio * 1000).toInt(),
          child: widget.child,
        ),
        GestureDetector(
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          onDoubleTap: widget.collapsible ? _toggleCollapse : null,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: Container(
              width: widget.dividerThickness,
              color: dividerColor,
              child: Center(
                child: Container(
                  width: 2,
                  height: 40,
                  decoration: BoxDecoration(
                    color: dividerColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: ((1 - _ratio) * 1000).toInt(),
          child: widget.panel,
        ),
      ],
    );
  }

  Widget _buildVertical(Color dividerColor) {
    if (_collapsed) {
      return widget.child;
    }
    return Column(
      children: [
        Expanded(
          flex: (_ratio * 1000).toInt(),
          child: widget.child,
        ),
        GestureDetector(
          onVerticalDragStart: _onDragStart,
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          onDoubleTap: widget.collapsible ? _toggleCollapse : null,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeRow,
            child: Container(
              height: widget.dividerThickness,
              color: dividerColor,
              child: Center(
                child: Container(
                  width: 40,
                  height: 2,
                  decoration: BoxDecoration(
                    color: dividerColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: ((1 - _ratio) * 1000).toInt(),
          child: widget.panel,
        ),
      ],
    );
  }
}

class CollapsiblePanel extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final PanelAxis axis;
  final double initialSize;
  final double minSize;
  final double maxSize;
  final bool initialCollapsed;
  final Color? accentColor;
  final List<Widget>? actions;

  const CollapsiblePanel({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.axis = PanelAxis.horizontal,
    this.initialSize = 250,
    this.minSize = 100,
    this.maxSize = 500,
    this.initialCollapsed = false,
    this.accentColor,
    this.actions,
  });

  @override
  State<CollapsiblePanel> createState() => _CollapsiblePanelState();
}

class _CollapsiblePanelState extends State<CollapsiblePanel>
    with SingleTickerProviderStateMixin {
  late bool _collapsed;
  late AnimationController _animController;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _collapsed = widget.initialCollapsed;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: _collapsed ? 0.0 : 1.0,
    );
    _sizeAnimation = Tween<double>(
      begin: widget.minSize,
      end: widget.initialSize,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleCollapse() {
    setState(() => _collapsed = !_collapsed);
    if (_collapsed) {
      _animController.reverse();
    } else {
      _animController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_collapsed) {
      return _buildCollapsed();
    }
    return _buildExpanded();
  }

  Widget _buildCollapsed() {
    final accent = widget.accentColor ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: _toggleCollapse,
      child: Container(
        width: 48,
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Icon(widget.icon, color: accent, size: 20),
            const SizedBox(height: 8),
            RotatedBox(
              quarterTurns: -1,
              child: Text(
                widget.title.toUpperCase(),
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpanded() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return SizedBox(
          width: _sizeAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Expanded(child: widget.child),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final accent = widget.accentColor ?? Theme.of(context).colorScheme.primary;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(widget.icon, color: accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title.toUpperCase(),
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
          if (widget.actions != null) ...widget.actions!,
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _toggleCollapse,
            child: Icon(
              Icons.chevron_left,
              color: Theme.of(context).textTheme.bodySmall?.color,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
