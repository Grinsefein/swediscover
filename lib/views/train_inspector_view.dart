import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/train_composition_model.dart';
import '../services/trafikverket_service.dart';

class TrainInspectorView extends StatefulWidget {
  const TrainInspectorView({super.key});

  @override
  State<TrainInspectorView> createState() => _TrainInspectorViewState();
}

class _TrainInspectorViewState extends State<TrainInspectorView> {
  String _selectedTrainLine = 'SJ 524';
  late TrainComposition _composition;

  @override
  void initState() {
    super.initState();
    _composition = TrafikverketService.getTrainComposition(_selectedTrainLine);
  }

  void _switchTrain(String line) {
    setState(() {
      _selectedTrainLine = line;
      _composition = TrafikverketService.getTrainComposition(line);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title card
          Card(
            color: theme.colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.train_rounded, color: theme.colorScheme.onTertiary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Intl.message(
                            'Trafikverket Tåg API Extra',
                            desc: 'Header text in the train inspector view',
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                        Text(
                          Intl.message(
                            'Vagnsammansättning, Tillgänglighet & Orsakskoder',
                            desc: 'Subheader text in the train inspector view',
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer.withValues(alpha: 0.8),
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

          // Train Selection Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
            Intl.message('SJ 524', desc: 'Train line SJ 524'),
            Intl.message('Mälartåg 912', desc: 'Train line Mälartåg 912'),
            Intl.message('Öresundståg 1042', desc: 'Train line Öresundståg 1042'),
          ].map((line) {
                final isSelected = _selectedTrainLine == line;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: isSelected,
                    label: Text(line, style: const TextStyle(fontWeight: FontWeight.bold)),
                    onSelected: (_) => _switchTrain(line),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Train Overview Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _composition.trainNumber,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Tågtyp: ${_composition.trainType} • Operatör: ${_composition.operatorName}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_composition.wagons.length} Vagnar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Delay cause diagnostics alert box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade800.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verspätungsursache (Trafikverket Orsakskod)',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                              Text(
                                _composition.delayReason,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Wagon Composition Interactive Visualizer
          Text(
            'Vagnsammansättning & Beläggning per Vagn',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _composition.wagons.length,
            itemBuilder: (context, index) {
              final wagon = _composition.wagons[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${wagon.carriageNumber}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  wagon.classType,
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Kapacitet: ${wagon.seatingCapacity} platser',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: wagon.currentOccupancyPct > 85
                                  ? Colors.red.withValues(alpha: 0.15)
                                  : const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${wagon.currentOccupancyPct}% Belagd',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: wagon.currentOccupancyPct > 85 ? Colors.red : const Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Linear Occupancy Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: wagon.currentOccupancyPct / 100.0,
                          minHeight: 8,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            wagon.currentOccupancyPct > 85 ? Colors.red : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Amenity Badges (Bistro, Wheelchair, Bicycle, Power, Quiet)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (wagon.hasWheelchairRamp)
                            _buildAmenityBadge(Icons.accessible_rounded, Intl.message('Rullstol', desc: 'Amenity label for wheelchair access'),
                          if (wagon.hasBicycleSpace)
                            _buildAmenityBadge(Icons.pedal_bike_rounded, Intl.message('Cykel', desc: 'Amenity label for bicycle space'),
                          if (wagon.hasPowerSockets)
                            _buildAmenityBadge(Icons.power_rounded, Intl.message('230V Uttag', desc: 'Amenity label for power sockets'),
                          if (wagon.isQuietZone)
                            _buildAmenityBadge(Icons.volume_off_rounded, Intl.message('Tyst Avdelning', desc: 'Amenity label for quiet zone'),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: Duration(milliseconds: 200 + index * 60)).slideX(begin: 0.05, end: 0);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityBadge(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
