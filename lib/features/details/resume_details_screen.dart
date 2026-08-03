import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/resume.dart';
import '../shared/page_scaffold.dart';
import 'analysis_sheet.dart';
import 'details_controller.dart';

class ResumeDetailsScreen extends ConsumerWidget {
  const ResumeDetailsScreen({super.key, required this.resumeId, this.highlight});

  final int resumeId;
  final String? highlight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      detailsControllerProvider((id: resumeId, highlight: highlight)),
    );

    return PageScaffold(
      title: 'Candidate profile',
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back),
      ),
      scrollableBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        transitionBuilder: fadeThroughTransition,
        child: Builder(
          key: ValueKey(state.loading || state.resume == null
              ? 'loading-or-error'
              : 'profile-${state.resume!.id}'),
          builder: (context) {
            if (state.loading) {
              return const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: LoadingDots()),
              );
            }
            if (state.error != null || state.resume == null) {
              return EmptyState(
                icon: Icons.person_off_outlined,
                title: 'Profile unavailable',
                message: state.error,
              );
            }
            return _Profile(resume: state.resume!, highlight: state.highlight);
          },
        ),
      ),
    );
  }
}

class _Profile extends StatelessWidget {
  const _Profile({required this.resume, required this.highlight});
  final Resume resume;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _HeaderCard(resume: resume),
      if (resume.summary.isNotEmpty)
        _Section(
          title: 'Summary',
          child: _Highlighted(text: resume.summary, highlight: highlight),
        ),
      if (resume.skillList.isNotEmpty)
        _Section(
          title: 'Skills',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in resume.skillList)
                AppPill(
                  label: s,
                  color: context.colors.onBrandSubtle,
                  background: context.colors.brandSubtle,
                ),
            ],
          ),
        ),
      if (resume.experience.isNotEmpty)
        _Section(
          title: 'Experience',
          child: _Highlighted(text: resume.experience, highlight: highlight),
        ),
      if (resume.education.isNotEmpty)
        _Section(
          title: 'Education',
          child: _Highlighted(text: resume.education, highlight: highlight),
        ),
      if (resume.certifications.isNotEmpty)
        _Section(
          title: 'Certifications',
          child: _Highlighted(text: resume.certifications, highlight: highlight),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.lg),
          StaggeredEntrance(index: i, child: sections[i]),
        ],
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.resume});
  final Resume resume;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Hero(
            tag: 'avatar-${resume.id}',
            child: Monogram(text: resume.initials, seed: resume.fullName, size: 72),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(resume.fullName,
              style: context.text.headlineSmall, textAlign: TextAlign.center),
          if (resume.category.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(resume.category, style: context.text.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              if (resume.email.isNotEmpty)
                _ContactBit(icon: Icons.mail_outline, text: resume.email),
              if (resume.phoneNumber.isNotEmpty)
                _ContactBit(icon: Icons.phone_outlined, text: resume.phoneNumber),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => AnalysisSheet.show(context, resume),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Analyse fit with AI'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined,
                  size: 14, color: context.colors.privacy),
              const SizedBox(width: 5),
              Text('Runs on this device',
                  style: context.text.labelSmall
                      ?.copyWith(color: context.colors.privacy)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactBit extends StatelessWidget {
  const _ContactBit({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: context.colors.textMuted),
        const SizedBox(width: 5),
        Text(text, style: context.text.bodySmall),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: context.text.labelSmall
                  ?.copyWith(color: context.colors.brand, letterSpacing: 0.6)),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// Renders [text], tinting the first occurrence of [highlight] (the matched
/// search segment) so reviewers see *why* a candidate surfaced.
class _Highlighted extends StatelessWidget {
  const _Highlighted({required this.text, required this.highlight});
  final String text;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final base = context.text.bodyMedium!.copyWith(color: context.colors.textPrimary);
    final h = highlight?.trim() ?? '';
    if (h.isEmpty) return Text(text, style: base);

    final lower = text.toLowerCase();
    final idx = lower.indexOf(h.toLowerCase());
    if (idx < 0) return Text(text, style: base);

    return RichText(
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + h.length),
            style: base.copyWith(
              backgroundColor: context.colors.highlightSemantic,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: text.substring(idx + h.length)),
        ],
      ),
    );
  }
}
