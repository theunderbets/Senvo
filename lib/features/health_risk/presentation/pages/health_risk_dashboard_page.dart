import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/health_risk_bloc.dart';
import '../bloc/health_risk_event.dart';
import '../bloc/health_risk_state.dart';
import '../widgets/health_risk_domain_card.dart';
import '../../../../core/theme/senvo_theme.dart';
import 'health_risk_details_page.dart';

class HealthRiskDashboardPage extends StatefulWidget {
  const HealthRiskDashboardPage({super.key});

  @override
  State<HealthRiskDashboardPage> createState() => _HealthRiskDashboardPageState();
}

class _HealthRiskDashboardPageState extends State<HealthRiskDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<HealthRiskBloc>().add(const EvaluateHealthRisk());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Risk Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<HealthRiskBloc>().add(const EvaluateHealthRisk());
            },
          )
        ],
      ),
      body: BlocBuilder<HealthRiskBloc, HealthRiskState>(
        builder: (context, state) {
          if (state is HealthRiskLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HealthRiskInitial) {
            return _buildEmptyDomainList(context);
          } else if (state is HealthRiskError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(SenvoSpacing.lg),
                child: Text(
                  'Error loading risk data:\n${state.message}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: context.themeColors.riskEmergency),
                ),
              ),
            );
          } else if (state is HealthRiskLoaded) {
            final result = state.riskResult;
            
            return CustomScrollView(
              slivers: [
                if (result.criticalAlerts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(SenvoSpacing.md),
                      margin: const EdgeInsets.all(SenvoSpacing.md),
                      decoration: BoxDecoration(
                        color: context.themeColors.riskEmergency.withValues(alpha: 0.1),
                        border: Border.all(color: context.themeColors.riskEmergency.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(SenvoRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: context.themeColors.riskEmergency),
                              SizedBox(width: SenvoSpacing.sm),
                              Text(
                                'CRITICAL ALERTS',
                                style: TextStyle(
                                  color: context.themeColors.riskEmergency,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: SenvoSpacing.sm),
                          ...result.criticalAlerts.map((alert) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text('- $alert',
                                    style: const TextStyle(color: context.themeColors.text)),
                              )),
                        ],
                      ),
                    ),
                  ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: SenvoSpacing.lg, vertical: SenvoSpacing.md),
                    child: Text(
                      'Domain Analysis',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final domainName = result.domainResults.keys.elementAt(index);
                      final domainResult = result.domainResults[domainName]!;
                      return HealthRiskDomainCard(
                        domainResult: domainResult,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HealthRiskDetailsPage(
                                domainResult: domainResult,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: result.domainResults.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: SenvoSpacing.xl)),
              ],
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyDomainList(BuildContext context) {
    const domains = [
      'Cardiovascular',
      'Respiratory',
      'Heat Stress',
      'Dehydration',
      'Sleep Quality',
      'Activity Level',
    ];
    return ListView(
      padding: const EdgeInsets.all(SenvoSpacing.md),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: SenvoSpacing.md),
          child: Container(
            padding: const EdgeInsets.all(SenvoSpacing.md),
            decoration: BoxDecoration(
              color: context.themeColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(SenvoRadius.md),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: context.themeColors.accent),
                SizedBox(width: SenvoSpacing.sm),
                Expanded(
                  child: Text(
                    'Take a vital scan to see your personalized health risk analysis.',
                    style: TextStyle(color: context.themeColors.accent),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: SenvoSpacing.md),
          child: Text(
            'Domain Analysis',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ...domains.map((domain) => Padding(
          padding: const EdgeInsets.only(bottom: SenvoSpacing.sm),
          child: Container(
            padding: const EdgeInsets.all(SenvoSpacing.md),
            decoration: BoxDecoration(
              color: context.themeColors.surface,
              borderRadius: BorderRadius.circular(SenvoRadius.md),
              border: Border.all(color: context.themeColors.muted.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(_iconForDomain(domain), color: context.themeColors.muted, size: 28),
                const SizedBox(width: SenvoSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(domain, style: const TextStyle(color: context.themeColors.text, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text('Not yet assessed', style: TextStyle(color: context.themeColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.themeColors.muted.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(SenvoRadius.sm),
                  ),
                  child: const Text('N/A', style: TextStyle(color: context.themeColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  IconData _iconForDomain(String domain) {
    switch (domain) {
      case 'Cardiovascular': return Icons.favorite_border;
      case 'Respiratory': return Icons.air;
      case 'Heat Stress': return Icons.local_fire_department;
      case 'Dehydration': return Icons.water_drop;
      case 'Sleep Quality': return Icons.bedtime;
      case 'Activity Level': return Icons.directions_run;
      default: return Icons.health_and_safety;
    }
  }
}
