import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// Styled difficulty dropdown matching the web version's `.form-group` select.
class DifficultySelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const DifficultySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _options = [
    ('easy',   'Easy (depth 1)'),
    ('normal', 'Normal (time search)'),
    ('hard',   'Hard (depth 5)'),
  ];

  @override
  Widget build(BuildContext context) {
    return _LabeledSelector(
      label: 'DIFFICULTY:',
      value: value,
      options: _options,
      onChanged: onChanged,
    );
  }
}

/// Styled side selector dropdown.
class SideSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const SideSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _options = [
    ('r', 'Red (Goes First)'),
    ('b', 'Black'),
  ];

  @override
  Widget build(BuildContext context) {
    return _LabeledSelector(
      label: 'PLAY AS:',
      value: value,
      options: _options,
      onChanged: onChanged,
    );
  }
}

// ── Shared private selector ──────────────────────────────────────────────────

class _LabeledSelector extends StatelessWidget {
  final String label;
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  const _LabeledSelector({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Label: Cinzel, uppercase, letter-spaced, muted brown ────────────
        // Matches web `.form-group label`: Cinzel 12px, #7a5020, ls 2px
        Text(label, style: XiangqiTextStyles.label),

        const SizedBox(height: 6),

        // ── Select field: transparent bg, bottom border only ────────────────
        // Matches web `.custom-select-trigger`: transparent, border-bottom 1px
        Container(
          decoration: XiangqiDecorations.dropdownField(
            XiangqiColors.gold.withAlpha(90), // ~35% opacity, matches rgba(136,90,42,0.35)
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              // Dropdown menu parchment bg — matches web #f5edd8
              dropdownColor: XiangqiColors.parchmentDark,
              // Small triangle caret, warm brown — matches web `.select-arrow`
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0x8C64411A), // ~55% warm brown
                size: 20,
              ),
              // Noto Serif value text — matches web `.custom-select` Noto Serif 14px
              style: XiangqiTextStyles.dropdownValue,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              items: options.map((opt) {
                final (val, display) = opt;
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(display),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
