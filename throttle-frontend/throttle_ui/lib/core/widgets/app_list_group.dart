import 'package:flutter/material.dart';

/// Grouped list rows with hairline dividers and no per-row outlines (WhatsApp / IG style).
class AppListGroup extends StatelessWidget {
  const AppListGroup({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.margin = const EdgeInsets.only(bottom: 16),
    this.dividerIndent = 56,
  });

  final List<Widget> children;
  final Widget? header;
  final Widget? footer;
  final EdgeInsets margin;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty && header == null && footer == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final dividerColor = theme.dividerColor.withValues(alpha: 0.35);

    Widget hairline({double indent = 0}) {
      return Divider(
        height: 1,
        thickness: 1,
        indent: indent,
        color: dividerColor,
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(hairline(indent: dividerIndent));
      }
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) ...[
            header!,
            if (children.isNotEmpty) hairline(),
          ],
          ...rows,
          if (footer != null) ...[
            if (children.isNotEmpty) hairline(),
            footer!,
          ],
        ],
      ),
    );
  }
}
