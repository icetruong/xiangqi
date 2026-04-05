import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../models/rules_section.dart';
import 'package:google_fonts/google_fonts.dart';

class RulesSidebar extends StatelessWidget {
  final List<RulesSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onSectionSelected;

  const RulesSidebar({
    super.key,
    required this.sections,
    required this.selectedIndex,
    required this.onSectionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: XiangqiColors.parchmentDark,
        border: Border(
          right: BorderSide(
            color: Color(0x2E885A2A),
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                final isSelected = index == selectedIndex;
                return _buildNavItem(context, section.title, isSelected, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0x2E885A2A),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LUẬT CHƠI',
            style: GoogleFonts.notoSerif(
              textStyle: XiangqiTextStyles.displayTitle,
              fontSize: 24,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'HƯỚNG DẪN CƠ BẢN',
            style: GoogleFonts.notoSerif(
              textStyle: XiangqiTextStyles.subtitle,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, String title, bool isSelected, int index) {
    return InkWell(
      onTap: () => onSectionSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x1F885A2A) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? XiangqiColors.crimson : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Text(
          title,
          style: XiangqiTextStyles.dropdownValue.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            color: isSelected ? XiangqiColors.textTitle : XiangqiColors.textMuted,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
