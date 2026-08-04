import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/app_widgets.dart';
import '../shared/page_scaffold.dart';

class HelpScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return PageScaffold(
      title: 'Help & Beta Support',
      subtitle: 'Plain answers & direct beta feedback',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      scrollableBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Beta Tester Feedback Card
          AppCard(
            color: context.colors.privacySubtle,
            borderColor: AppPalette.privacyEmerald,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mark_chat_read_outlined,
                        color: AppPalette.privacyEmerald),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Beta Feedback & Bug Reports',
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppPalette.privacyEmerald,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Have ideas or issues? Submit feedback to help us refine EdgeTal. No candidate data or personal logs are attached.',
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Send Beta Feedback'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPalette.privacyEmerald,
                    side: const BorderSide(color: AppPalette.privacyEmerald),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feedback dialog launched. Thank you for testing EdgeTal Beta!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Interactive Tours Card
          AppCard(
            color: context.colors.brandSubtle,
            borderColor: context.colors.brand.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tour_outlined, color: context.colors.brand),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Interactive Feature Tours', style: context.text.titleSmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Want to replay the onboarding guides for candidate search, multi-source resume import, and on-device models?',
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                AppGradientButton(
                  icon: Icons.refresh,
                  label: 'Replay Feature Tours',
                  onPressed: () async {
                    final guide = ref.read(inAppGuideServiceProvider);
                    await guide.resetAllGuides();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feature tours reset! Re-visit any screen to view its guided tour.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Frequently Asked Questions', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.md),
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
        color: _expanded ? context.colors.brandSubtle : context.scheme.surface,
        borderRadius: AppRadius.cardXl,
        border: Border.all(
          color: context.colors.border,
          width: 1,
        ),
        boxShadow: AppShadow.soft(AppPalette.midnightNavy),
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
            color: context.colors.textPrimary,
          ),
        ),
        trailing: Icon(
          _expanded ? Icons.expand_less : Icons.expand_more,
          color: context.colors.textPrimary,
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
