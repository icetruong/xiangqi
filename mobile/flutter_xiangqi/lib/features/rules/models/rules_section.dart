abstract class RuleContentBlock {
  const RuleContentBlock();
}

class RuleParagraph extends RuleContentBlock {
  final String text;
  const RuleParagraph(this.text);
}

class RuleBulletList extends RuleContentBlock {
  final List<String> items;
  const RuleBulletList(this.items);
}

class RuleTable extends RuleContentBlock {
  final List<List<String>> rows; // [ [col1, col2, col3], ... ]
  const RuleTable(this.rows);
}

class RulesSection {
  final String title;
  final String? subtitle;
  final List<RuleContentBlock> blocks;

  const RulesSection({
    required this.title,
    this.subtitle,
    required this.blocks,
  });
}
