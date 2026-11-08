import 'package:flutter/material.dart';

/// Reduces information density in the Solar 3D mobile laboratory.
/// ExpansionTile's state remains stable when the editor redraws for a
/// camera or height change, and its children remain mounted while hidden.
class Solar3dCollapsibleSection extends StatelessWidget {
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
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: ExpansionTile(
      key: PageStorageKey('solar3d-section-$title'),
      initiallyExpanded: initiallyExpanded,
      maintainState: true,
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: this.children,
          ),
        ),
      ],
    ),
  );
}
