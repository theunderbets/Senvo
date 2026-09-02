import 'package:flutter/material.dart';
import '../../domain/entities/risk_result.dart';
import '../../../../core/theme/senvo_theme.dart';

class HealthRiskDetailsPage extends StatelessWidget {
  final DomainRiskResult domainResult;

  const HealthRiskDetailsPage({
    super.key,
    required this.domainResult,
  });

  @override
  Widget build(BuildContext context) {
    final color = SenvoColors.colorForRisk(domainResult.level);

    return Scaffold(
      appBar: AppBar(
        title: Text('${domainResult.domain} Risk'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(SenvoSpacing.lg),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(SenvoSpacing.xl),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.1),
                      border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          domainResult.score.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                color: color,
                              ),
                        ),
                        Text(
                          domainResult.level.name.toUpperCase(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SenvoSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: SenvoSpacing.md, vertical: SenvoSpacing.sm),
                    decoration: BoxDecoration(
                      color: SenvoColors.surface,
                      borderRadius: BorderRadius.circular(SenvoRadius.md),
                      border: Border.all(color: SenvoColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.analytics, size: 16, color: SenvoColors.muted),
                        const SizedBox(width: SenvoSpacing.sm),
                        Text(
                          'Confidence: ${(domainResult.confidence * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (domainResult.primaryContributors.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: SenvoSpacing.lg, vertical: SenvoSpacing.md),
                child: Text(
                  'Primary Contributors',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final contributor = domainResult.primaryContributors[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: SenvoSpacing.lg, vertical: SenvoSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.radio_button_checked, size: 16, color: SenvoColors.accent),
                        const SizedBox(width: SenvoSpacing.md),
                        Expanded(
                          child: Text(
                            contributor,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: domainResult.primaryContributors.length,
              ),
            ),
          ],
          
          const SliverToBoxAdapter(child: SizedBox(height: SenvoSpacing.lg)),
          
          if (domainResult.insights.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: SenvoSpacing.lg, vertical: SenvoSpacing.md),
                child: Text(
                  'Insights & Recommendations',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: SenvoSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final insight = domainResult.insights[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: SenvoSpacing.md),
                      child: Padding(
                        padding: const EdgeInsets.all(SenvoSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(SenvoSpacing.sm),
                              decoration: BoxDecoration(
                                color: SenvoColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(SenvoRadius.sm),
                              ),
                              child: const Icon(Icons.lightbulb_outline, color: SenvoColors.accent, size: 20),
                            ),
                            const SizedBox(width: SenvoSpacing.md),
                            Expanded(
                              child: Text(
                                insight,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: domainResult.insights.length,
                ),
              ),
            ),
          ],
          
          const SliverToBoxAdapter(child: SizedBox(height: SenvoSpacing.xl)),
        ],
      ),
    );
  }
}
