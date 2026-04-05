import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../models/rules_section.dart';
import 'package:google_fonts/google_fonts.dart';

class RulesContentView extends StatelessWidget {
  final RulesSection section;

  const RulesContentView({
    super.key,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: XiangqiColors.parchment,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            ...section.blocks.map(_buildBlock),
            const SizedBox(height: 48), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.subtitle != null) ...[
          Text(
            section.subtitle!.toUpperCase(),
            style: GoogleFonts.notoSerif(
              textStyle: XiangqiTextStyles.subtitle,
              color: XiangqiColors.crimson,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          section.title.toUpperCase(),
          style: GoogleFonts.notoSerif(
            textStyle: XiangqiTextStyles.displayTitle,
            fontSize: 28, // Scaled down slightly since Noto Serif is chunkier than Cinzel
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 2,
          color: XiangqiColors.goldDark.withAlpha(150),
        ),
      ],
    );
  }

  Widget _buildBlock(RuleContentBlock block) {
    if (block is RuleParagraph) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          block.text,
          style: XiangqiTextStyles.dropdownValue.copyWith(
            height: 1.6,
            fontSize: 16,
          ),
        ),
      );
    } else if (block is RuleBulletList) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: block.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: XiangqiTextStyles.dropdownValue.copyWith(
                      color: XiangqiColors.crimson,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: XiangqiTextStyles.dropdownValue.copyWith(
                        height: 1.5,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    } else if (block is RuleTable) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Table(
          border: TableBorder.all(
            color: const Color(0x2E885A2A),
            width: 1,
          ),
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(3),
          },
          children: block.rows.asMap().entries.map((entry) {
            final isHeader = entry.key == 0;
            final row = entry.value;
            return TableRow(
              decoration: isHeader
                  ? const BoxDecoration(
                      color: Color(0x1A885A2A),
                    )
                  : null,
              children: row.map((cellText) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    cellText,
                    style: XiangqiTextStyles.dropdownValue.copyWith(
                      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                      color: isHeader ? XiangqiColors.textTitle : XiangqiColors.textBody,
                      fontSize: 15,
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
