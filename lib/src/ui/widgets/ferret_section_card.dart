import 'package:flutter/material.dart';

/// Card section used across Ferret detail tabs.
///
/// With [collapsible], a chevron (or tapping the title) hides the children,
/// e.g. to skip long headers and jump to the body.
class FerretSectionCard extends StatefulWidget {
  const FerretSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.collapsible = false,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final bool collapsible;

  @override
  State<FerretSectionCard> createState() => _FerretSectionCardState();
}

class _FerretSectionCardState extends State<FerretSectionCard> {
  bool _expanded = true;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = Text(
      widget.title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: scheme.primary,
      ),
    );

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: widget.collapsible
                      ? GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _toggle,
                          child: title,
                        )
                      : title,
                ),
                ?widget.trailing,
                if (widget.collapsible)
                  IconButton(
                    onPressed: _toggle,
                    tooltip: _expanded
                        ? 'Collapse ${widget.title}'
                        : 'Expand ${widget.title}',
                    visualDensity: VisualDensity.compact,
                    icon: AnimatedRotation(
                      turns: _expanded ? 0 : -0.25,
                      duration: const Duration(milliseconds: 150),
                      child: const Icon(Icons.expand_more_rounded),
                    ),
                  ),
              ],
            ),
            if (_expanded) ...[const SizedBox(height: 10), ...widget.children],
          ],
        ),
      ),
    );
  }
}

/// Label / value row for overview and message metadata.
class FerretMetricRow extends StatelessWidget {
  const FerretMetricRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: emphasis ? FontWeight.w700 : FontWeight.w500,
      color: emphasis ? scheme.error : scheme.onSurface,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: SelectableText(value, style: valueStyle)),
        ],
      ),
    );
  }
}
