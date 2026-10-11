import 'package:flutter/material.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:h2orbit/widgets/glass_container.dart';

/// One-tap "add a drink" tile.
class BeverageCard extends StatefulWidget {
  final String name;
  final IconData icon;
  final int ml;
  final VoidCallback onTap;

  const BeverageCard({
    super.key,
    required this.name,
    required this.icon,
    required this.ml,
    required this.onTap,
  });

  @override
  State<BeverageCard> createState() => _BeverageCardState();
}

class _BeverageCardState extends State<BeverageCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 140),
    vsync: this,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.93,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add ${widget.ml} millilitres, ${widget.name}',
      excludeSemantics: true,
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _controller.forward(),
          onTapCancel: () => _controller.reverse(),
          onTapUp: (_) {
            _controller.reverse();
            widget.onTap();
          },
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            borderRadius: BorderRadius.circular(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.lightCyan.withValues(alpha: 0.45),
                        AppTheme.oceanBlue.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                  child: Icon(widget.icon, size: 24, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${widget.ml} ml',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
