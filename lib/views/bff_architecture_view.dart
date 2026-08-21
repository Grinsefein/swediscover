import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../repositories/realtime_repository.dart';

class BffArchitectureView extends StatelessWidget {
  const BffArchitectureView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bffService = Provider.of<RealtimeRepository>(context);
    final tele = bffService.telemetry;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.hub_rounded, color: theme.colorScheme.onPrimary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Backend-for-Frontend & Native Engine',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'Request Collapsing • Protobuf Stream • Isolates • Drift FTS',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Live Metrics Cards Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Request Collapsing',
                  value: '${tele.networkSavingsPercent.toStringAsFixed(1)}%',
                  subtitle: '${tele.collapsedRequests} Requests vermieden',
                  icon: Icons.compress_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Upstream Quota',
                  value: '${tele.upstreamCallsMade}',
                  subtitle: 'Trafiklab Req/Min',
                  icon: Icons.speed_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'Protobuf Stream',
                  value: '${(tele.protobufBytesProcessed / 1024 / 1024).toStringAsFixed(1)} MB',
                  subtitle: 'Transcoded zu JSON WebSocket',
                  icon: Icons.code_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: 'SQLite FTS5 DB',
                  value: '< 10 ms',
                  subtitle: 'Sub-10ms Stop Topology',
                  icon: Icons.storage_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Visual Architecture Diagram Box
          Text(
            'Systemarchitektur Diagramm',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildArchNode(
                    title: '1. Upstream APIs (Trafiklab & Trafikverket)',
                    subtitle: 'GTFS-RT Protobuf • Oxyfi WS • Timetables JSON API • Datex II',
                    color: Colors.blue.shade800,
                  ),
                  const Icon(Icons.arrow_downward_rounded, size: 20),
                  _buildArchNode(
                    title: '2. Backend-for-Frontend (BFF)',
                    subtitle: 'Request Collapsing • Protobuf Parsing • Spatial Bounding-Box Filtering',
                    color: Colors.teal.shade700,
                  ),
                  const Icon(Icons.arrow_downward_rounded, size: 20),
                  _buildArchNode(
                    title: '3. Flutter Native Client',
                    subtitle: 'Background Isolate (60 FPS Vector Interpolation) ──► Main Isolate (MapLibre & M3 Expressive UI)',
                    color: Colors.purple.shade700,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildArchNode({
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
