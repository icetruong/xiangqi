import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../data/rules_content.dart';
import 'package:google_fonts/google_fonts.dart';
import 'rules_content_view.dart';
import 'rules_sidebar.dart';

class RulesBookModal extends StatefulWidget {
  const RulesBookModal({super.key});

  @override
  State<RulesBookModal> createState() => _RulesBookModalState();
}

class _RulesBookModalState extends State<RulesBookModal> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.85,
          constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
          decoration: XiangqiDecorations.panel,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 650;

                    if (isNarrow) {
                      return Column(
                        children: [
                          // Top navigation for narrow screens
                          Container(
                            height: 120, // Enough for header + horizontal list
                            decoration: const BoxDecoration(
                              color: XiangqiColors.parchmentDark,
                              border: Border(
                                bottom: BorderSide(color: Color(0x2E885A2A), width: 1.5),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                                  child: Text(
                                    'LUẬT CHƠI',
                                    style: GoogleFonts.notoSerif(
                                      textStyle: XiangqiTextStyles.displayTitle,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: xiangqiRulesContent.length,
                                    itemBuilder: (context, index) {
                                      final isSelected = index == _selectedIndex;
                                      return InkWell(
                                        onTap: () => setState(() => _selectedIndex = index),
                                        child: Container(
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          margin: const EdgeInsets.only(right: 8, bottom: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0x1F885A2A) : Colors.transparent,
                                            border: Border(
                                              bottom: BorderSide(
                                                color: isSelected ? XiangqiColors.crimson : Colors.transparent,
                                                width: 3,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            xiangqiRulesContent[index].title,
                                            style: XiangqiTextStyles.dropdownValue.copyWith(
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                              color: isSelected ? XiangqiColors.textTitle : XiangqiColors.textMuted,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: RulesContentView(
                                    section: xiangqiRulesContent[_selectedIndex],
                                  ),
                                ),
                                _buildPaginationFooter(),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    // Wide screens: Side-by-side book layout
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RulesSidebar(
                          sections: xiangqiRulesContent,
                          selectedIndex: _selectedIndex,
                          onSectionSelected: (index) {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: RulesContentView(
                                  section: xiangqiRulesContent[_selectedIndex],
                                ),
                              ),
                              _buildPaginationFooter(),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              ),
              
              // Close button
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: XiangqiColors.textTitle),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Đóng',
                ),
              ),
              
              // Optional: a decorative stamp in the bottom left or right corner
              Positioned(
                bottom: 24,
                right: 32,
                child: IgnorePointer(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: XiangqiColors.crimson.withAlpha(150), width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Tướng\nKỳ',
                      textAlign: TextAlign.center,
                      style: XiangqiTextStyles.displayTitle.copyWith(
                        color: XiangqiColors.crimson.withAlpha(150),
                        fontSize: 14,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: XiangqiColors.parchmentDark,
        border: Border(top: BorderSide(color: Color(0x2E885A2A), width: 1.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Button
          InkWell(
            onTap: _selectedIndex > 0 ? () => setState(() => _selectedIndex--) : null,
            child: Opacity(
              opacity: _selectedIndex > 0 ? 1.0 : 0.3,
              child: Row(
                children: [
                  const Icon(Icons.arrow_back_ios, size: 14, color: XiangqiColors.textTitle),
                  const SizedBox(width: 4),
                  Text(
                    'Trang trước',
                    style: GoogleFonts.notoSerif(
                      color: XiangqiColors.textTitle,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Page Indicator
          Text(
            '${_selectedIndex + 1} / ${xiangqiRulesContent.length}',
            style: GoogleFonts.notoSerif(
              color: XiangqiColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          
          // Next Button
          InkWell(
            onTap: _selectedIndex < xiangqiRulesContent.length - 1 ? () => setState(() => _selectedIndex++) : null,
            child: Opacity(
              opacity: _selectedIndex < xiangqiRulesContent.length - 1 ? 1.0 : 0.3,
              child: Row(
                children: [
                  Text(
                    'Trang sau',
                    style: GoogleFonts.notoSerif(
                      color: XiangqiColors.textTitle,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: XiangqiColors.textTitle),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

