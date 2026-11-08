import 'package:flutter/material.dart';

/// A compact independently collapsible group for the 3D laboratory.
///
/// Do NOT keep hidden Scrollables and DropdownButtonFormFields mounted
/// during an expansion animation. The old ExpansionTile/maintainState
/// combination could reparent a Scrollable while the MPPT field rebuilt,
/// resulting in duplicate GlobalKeys and inherited-widget assertions.
/// The group keeps only its expanded flag in State; scene/MPPT data live
/// in the editor, not inside its transient controls.
class Solar3dCollapsibleSection extends StatefulWidget {
  final String title;
  final bool initiallyExpanded;
  final List<Widget> children;

  const Solar3dCollapsibleSection({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  State<Solar3dCollapsibleSection> createState() =>
      _Solar3dCollapsibleSectionState();
}

class _Solar3dCollapsibleSectionState
    extends State<Solar3dCollapsibleSection>
    with AutomaticKeepAliveClientMixin<Solar3dCollapsibleSection> {
  @override
  bool get wantKeepAlive => true;

  late bool expanded;

  @override
  void initState() {
    super.initState();
    expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          child: InkWell(
            onTap: () => setState(() => expanded = !expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 14),
              child: Row(children: [
                Expanded(child: Text(widget.title,
                    style: Theme.of(context).textTheme.titleMedium)),
                Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ]),
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.children,
            ),
          ),
      ],
    ),
  );
  }
}
