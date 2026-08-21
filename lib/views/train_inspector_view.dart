import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/train_composition_model.dart';
import '../services/trip_details_service.dart';

class TrainInspectorView extends StatefulWidget {
  const TrainInspectorView({super.key});

  @override
  State<TrainInspectorView> createState() => _TrainInspectorViewState();
}

class _TrainInspectorViewState extends State<TrainInspectorView> {
  String _selectedTrainLine = 'SJ 524';
  TripDetailsService? _tripDetailsService;
  TrainComposition? _composition;
  bool _isLoading = true;
  String? _errorMessage;

  static const Map<String, String> _tripIdMapping = {
    'SJ 524': 'SJ_524_20250101',
    'Mälartåg 912': 'ML_912_20250101',
    'Öresundståg 1042': 'OT_1042_20250101',
  };

  @override
  void initState() {
    super.initState();
    _loadTrainComposition(_selectedTrainLine);
  }

  Future<void> _loadTrainComposition(String trainLine) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _tripDetailsService = TripDetailsService();
      final tripId = _tripIdMapping[trainLine] ?? 'TRIP_$trainLine';
      final today = DateTime.now();
      
      final composition = await _tripDetailsService!.fetchTripDetails(tripId, today);
      
      if (!mounted) return;
      
      setState(() {
        _composition = composition;
        _isLoading = false;
        if (composition == null) {
          _errorMessage = 'Keine Echtzeitdaten verfügbar. Zeige Fallback-Daten.';
          _composition = _getFallbackComposition(trainLine);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fehler beim Laden der Zugdaten: ${e.toString()}';
        _composition = _getFallbackComposition(trainLine);
      });
    }
  }

  void _switchTrain(String line) {
    _loadTrainComposition(line);
  }

  TrainComposition _getFallbackComposition(String trainLine) {
    if (trainLine.contains('SJ')) {
      return const TrainComposition(
        trainNumber: 'SJ 524 (X2000)',
        trainType: 'X2000 Snabbåt',
        operatorName: 'SJ AB',
        delayReason: 'Signal fel vid Katrineholm (Banverket åtgärdar)',
        wagons: [
          WagonUnit(carriageNumber: 1, classType: '1a Klass', hasWheelchairRamp: true, hasBicycleSpace: false, hasPowerSockets: true, isQuietZone: false, seatingCapacity: 48, currentOccupancyPct: 92),
          WagonUnit(carriageNumber: 2, classType: '1a Klass (Tyst)', hasWheelchairRamp: false, hasBicycleSpace: false, hasPowerSockets: true, isQuietZone: true, seatingCapacity: 48, currentOccupancyPct: 88),
          WagonUnit(carriageNumber: 3, classType: 'Bistro & Cafe', hasWheelchairRamp: true, hasBicycleSpace: false, hasPowerSockets: true, isQuietZone: false, seatingCapacity: 20, currentOccupancyPct: 60),
          WagonUnit(carriageNumber: 4, classType: '2a Klass', hasWheelchairRamp: true, hasBicycleSpace: true, hasPowerSockets: true, isQuietZone: false, seatingCapacity: 72, currentOccupancyPct: 98),
          WagonUnit(carriageNumber: 5, classType: '2a Klass (Djur tillåtet)', hasWheelchairRamp: false, hasBicycleSpace: true, hasPowerSockets: true, isQuietZone: false, seatingCapacity: 72, currentOccupancyPct: 75),
        ],
      );
    } else if (trainLine.contains('Mälartåg')) {
      return const TrainComposition(
        trainNumber: 'Mälartåg 912',
        trainType: 'Stadler KISS ER1',
        operatorName: 'Mälardalstrafik',
        delayReason: 'Gleiswechsel vid Knivsta på grund av tågmöte',
        wagons: [
          WagonUnit(carriageNumber: 1, classType: '2a Klass (Flex)', hasWheelchairRamp: true, hasBicycleSpace: true, hasPowerSockets: true, isQuietZone: false, seatingCapacity: 85, currentOccupancyPct: 40),
          WagonUnit(carriageNumber: 2, classType: '2a Klass', hasWheelchairRamp: true, hasBicycleSpace: true, hasPowerSockets: true, isQuietZone: true, seatingCapacity: 90, currentOccupancyPct: 35),
        ],
      );
    } else {
      return const TrainComposition(
        trainNumber: 'Öresundståg 1042',
        trainType: 'X31K Öresundståg',
        operatorName: 'Skånetrafiken',
        delayReason: 'Normal drift',
        wagons: [
          WagonUnit(carriageNumber: 11, classType: '1a & 2a Klass', hasWheelchairRamp: true, hasBicycleSpace: true, hasPowerSockets: true, isQuietZone: false, seatingCapacity: 70, currentOccupancyPct: 65),
          WagonUnit(carriageNumber: 12, classType: 'Låggolv / Barnvagn', hasWheelchairRamp: true, hasBicycleSpace: true, hasPowerSockets: true, isQuietZone: false, seatingCapacity: 60, currentOccupancyPct: 80),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: theme.colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: theme.colorScheme.tertiary, shape: BoxShape.circle),
                    child: Icon(Icons.train_rounded, color: theme.colorScheme.onTertiary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trafikverket Tåg API Extra', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onTertiaryContainer)),
                        Text('Vagnsammansättning, Tillgänglighet & Orsakskoder', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onTertiaryContainer.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['SJ 524', 'Mälartåg 912', 'Öresundståg 1042'].map((line) {
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

          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_errorMessage != null && _composition == null)
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: theme.colorScheme.onErrorContainer),
                    const SizedBox(height: 12),
                    Text(_errorMessage!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _loadTrainComposition(_selectedTrainLine),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
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
                            Text(_composition!.trainNumber, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            Text('Tågtyp: ${_composition!.trainType} • Operatör: ${_composition!.operatorName}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                          child: Text('${_composition!.wagons.length} Vagnar', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer)),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.amber.shade900.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.shade800.withValues(alpha: 0.3))),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Verspätungsursache (Trafikverket Orsakskod)', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                                Text(_composition!.delayReason, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface)),
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
            Text('Vagnsammansättning & Beläggning per Vagn', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _composition!.wagons.length,
              itemBuilder: (context, index) {
                final wagon = _composition!.wagons[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: theme.colorScheme.outlineVariant)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(width: 38, height: 38, decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle), child: Center(child: Text('${wagon.carriageNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(wagon.classType, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                  Text('Kapacitet: ${wagon.seatingCapacity} platser', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: wagon.currentOccupancyPct > 85 ? Colors.red.withValues(alpha: 0.15) : const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                              child: Text('${wagon.currentOccupancyPct}% Belagd', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: wagon.currentOccupancyPct > 85 ? Colors.red : const Color(0xFF10B981))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(value: wagon.currentOccupancyPct / 100.0, minHeight: 8, backgroundColor: theme.colorScheme.surfaceContainerHighest, valueColor: AlwaysStoppedAnimation<Color>(wagon.currentOccupancyPct > 85 ? Colors.red : theme.colorScheme.primary)),
                        ),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 4, children: [
                          if (wagon.hasWheelchairRamp) _buildAmenityBadge(Icons.accessible_rounded, 'Rullstol', theme),
                          if (wagon.hasBicycleSpace) _buildAmenityBadge(Icons.pedal_bike_rounded, 'Cykel', theme),
                          if (wagon.hasPowerSockets) _buildAmenityBadge(Icons.power_rounded, '230V Uttag', theme),
                          if (wagon.isQuietZone) _buildAmenityBadge(Icons.volume_off_rounded, 'Tyst Avdelning', theme),
                        ]),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: Duration(milliseconds: 200 + index * 60)).slideX(begin: 0.05, end: 0);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmenityBadge(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: theme.colorScheme.primary), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))]),
    );
  }
}
