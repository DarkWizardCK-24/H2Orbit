import 'package:flutter/material.dart';
import 'package:h2orbit/utils/theme.dart';

/// Gradient call-to-action button with a press animation and a loading state.
class AnimatedButton extends StatefulWidget {
  final String text;

  /// `null` disables the button.
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool loading;

  const AnimatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height,
    this.icon,
    this.loading = false,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 160),
    vsync: this,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.96,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.text,
      excludeSemantics: true,
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTapDown: _enabled ? (_) => _controller.forward() : null,
          onTapCancel: () => _controller.reverse(),
          onTapUp: _enabled
              ? (_) {
                  _controller.reverse();
                  widget.onPressed!();
                }
              : null,
          child: Opacity(
            opacity: widget.onPressed == null ? 0.5 : 1,
            child: Container(
              width: widget.width ?? double.infinity,
              height: widget.height ?? 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: AppTheme.buttonGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightCyan.withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: widget.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
