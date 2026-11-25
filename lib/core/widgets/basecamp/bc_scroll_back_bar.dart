import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/basecamp_tokens.dart';

/// Fixed header for secondary screens. It is outside the scrollable area,
/// so the back action never disappears or covers the scrolling content.
class BcPinnedBackLayout extends StatelessWidget {
  const BcPinnedBackLayout({
    super.key,
    required this.title,
    required this.backLabel,
    required this.onBack,
    required this.child,
    this.trailing,
  });

  final String title;
  final String backLabel;
  final VoidCallback onBack;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
          child: Material(
            color: BcColors.surface,
            child: SafeArea(
              bottom: false,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 12, 4),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: backLabel,
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded, color: BcColors.ink),
                      ),
                      const SizedBox(width: BcSpace.s2),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: BcText.title(),
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}
