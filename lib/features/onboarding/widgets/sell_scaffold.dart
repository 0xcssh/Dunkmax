import 'package:flutter/material.dart';

import '../../shared/layout_density.dart';
import '../../shared/widgets/fit_or_scroll.dart';
import '../../shared/widgets/primary_button.dart';

/// Chrome shared by the sell screens after the quiz (gap, potential, how it
/// works, plan reveal): a back chevron, the screen's content, and a pinned
/// CTA.
///
/// The content is a [FitOrScrollColumn.fill]: a screen marks the block that
/// should grow (a chart, a summary card, the week list) as `Expanded`, and on
/// a tall phone that block takes the spare height, so the content reaches
/// down to the CTA instead of stopping short of it. Otherwise it takes
/// the room between the chevron and the CTA and nothing scrolls; a longer
/// locale on a shorter phone degrades to a scroll rather than a clip.
class SellScaffold extends StatelessWidget {
  final VoidCallback onBack;
  final String ctaLabel;
  final VoidCallback onContinue;
  final List<Widget> children;

  const SellScaffold({
    super.key,
    required this.onBack,
    required this.ctaLabel,
    required this.onContinue,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final density = LayoutDensity.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 4, 22, density.pick(12, 10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: onBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                alignment: Alignment.centerLeft,
                icon: const Icon(Icons.chevron_left,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: FitOrScrollColumn.fill(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
              SizedBox(height: density.pick(12, 10)),
              PrimaryButton(label: ctaLabel, onPressed: onContinue),
            ],
          ),
        ),
      ),
    );
  }
}
