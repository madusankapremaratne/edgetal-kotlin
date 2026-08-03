import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../shared/page_scaffold.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    _FaqItem(
      question: 'Does my candidate data ever leave my phone?',
      answer:
          'No. EdgeTal is engineered with a strict 100% on-device architecture. All resume parsing, vector embedding generation, and local LLM candidate fit evaluations run locally using MediaPipe and local SQLite/ObjectBox storage.',
    ),
    _FaqItem(
      question: 'How accurate is the AI candidate match?',
      answer:
          'Matches are calculated using dense vector cosine similarity over technical skills, past job experiences, and section summaries. The local LLM provides explainable rationale highlighting why a candidate fits your role.',
    ),
    _FaqItem(
      question: 'What happens if I lose my phone or switch devices?',
      answer:
          'Since candidate data is stored locally for GDPR compliance, we recommend using the Backup & Export tool to export your talent pool to a secure CSV or JSON file under your control.',
    ),
    _FaqItem(
      question: 'Do I need an internet connection to run searches?',
      answer:
          'No! Once the text embedder and optional Gemma-2B model weights are downloaded onto your device, all candidate imports, semantic searches, and AI fit analyses operate completely offline without internet.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Help / How It Works',
      subtitle: 'Plain answers, no jargon',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      scrollableBody: true,
      body: Column(
        children: [
          for (final faq in _faqs) ...[
            _FaqCard(faq: faq),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
}

class _FaqCard extends StatefulWidget {
  const _FaqCard({required this.faq});
  final _FaqItem faq;

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _expanded
            ? AppPalette.softIceBlue.withAlpha(100)
            : context.scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppPalette.softIceBlue,
          width: 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        title: Text(
          widget.faq.question,
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppPalette.midnightNavy,
          ),
        ),
        trailing: Icon(
          _expanded ? Icons.expand_less : Icons.expand_more,
          color: AppPalette.midnightNavy,
        ),
        onExpansionChanged: (expanded) =>
            setState(() => _expanded = expanded),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Text(
              widget.faq.answer,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
