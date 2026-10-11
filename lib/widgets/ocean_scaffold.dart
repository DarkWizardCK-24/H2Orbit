import 'package:flutter/material.dart';
import 'package:h2orbit/utils/breakpoints.dart';
import 'package:h2orbit/utils/theme.dart';
import 'package:h2orbit/widgets/side_rail.dart';

/// "H2Orbit" with a properly lowered, smaller 2. (The font has no subscript
/// glyph, so it is drawn as a separate styled span.)
class BrandTitle extends StatelessWidget {
  final double fontSize;
  final Color color;

  const BrandTitle({super.key, this.fontSize = 26, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 0.3,
    );
    return Semantics(
      label: 'H2Orbit',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            const TextSpan(text: 'H'),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Transform.translate(
                offset: Offset(0, fontSize * 0.14),
                child: Text(
                  '2',
                  style: style.copyWith(
                    fontSize: fontSize * 0.62,
                    color: AppTheme.lightCyan,
                  ),
                ),
              ),
            ),
            const TextSpan(text: 'Orbit'),
          ],
        ),
      ),
    );
  }
}

/// Ocean-gradient page with an optional header (back button, title, actions).
class OceanScaffold extends StatelessWidget {
  final String? title;
  final bool showBack;
  final List<Widget> actions;
  final Widget body;
  final Widget? floatingActionButton;

  /// Keeps content phone-width on tablets, desktops and the web.
  final double maxWidth;

  /// Top-level destination this page belongs to. On wide windows these pages
  /// get a persistent [SideRail] and a roomier content area; phones are
  /// unaffected.
  final AppSection? section;

  /// Content width limit next to the side rail on wide windows.
  final double wideMaxWidth;

  const OceanScaffold({
    super.key,
    required this.body,
    this.title,
    this.showBack = true,
    this.actions = const [],
    this.floatingActionButton,
    this.maxWidth = 600,
    this.section,
    this.wideMaxWidth = 1180,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final railed = section != null && Breakpoints.isWide(context);
    final content = Column(
      children: [
        if (title != null)
          Padding(
            padding: EdgeInsets.fromLTRB(railed ? 28 : 12, 12, 12, 8),
            child: Row(
              children: [
                if (showBack && canPop && !railed)
                  IconButton(
                    tooltip: 'Back',
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.maybePop(context),
                  )
                else if (!railed)
                  const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: railed ? 26 : 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
        Expanded(child: body),
      ],
    );

    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.oceanGradient),
        child: railed
            ? Row(
                children: [
                  SideRail(selected: section!),
                  Expanded(
                    child: SafeArea(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: wideMaxWidth),
                          child: content,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: content,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Small section heading used above groups of cards.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
