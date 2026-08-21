import 'package:flutter/material.dart';

import '../models/train_composition_model.dart';
import '../services/trafikverket_service.dart';

class TrainInspectorView extends StatefulWidget {
  const TrainInspectorView({super.key});

  @override
  State<TrainInspectorView> createState() => _TrainInspectorViewState();
}

class _TrainInspectorViewState extends State<TrainInspectorView> {
  final TextEditingController _tripSearchController = TextEditingController(text: '524');
  String _selectedTripId = '524';
  bool _isLoading = true;
  String? _errorMessage;
  TrainComposition? _composition;

  @override
  void initState() {
    super.initState();
    _loadTrainComposition(_selectedTripId);
  }

  @override
  void dispose() {
    _tripSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrainComposition(String tripId) async {
    if (tripId.trim().isEmpty) return;

    setState(() {
      _selectedTripId = tripId.trim();
      _isLoading = true;
      _errorMessage = null;
      _composition = null;
    });

    try {
      final composition = await TrafikverketService.getTrainComposition(_selectedTripId);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (composition == null) {
          _errorMessage = 'Ingen tågkompositionsdata hittades för trip ID: "$_selectedTripId"';
        } else {
          _composition = composition;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fehler beim Laden: ${e.toString()}';
      });
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
                        Text('Trafikverket & Trafiklab Trip Inspector', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onTertiaryContainer)),
                        Text('Echte Vagnsammansättning, Tillgänglighet & Orsakskoder', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onTertiaryContainer.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search Field for any Trip ID
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tripSearchController,
                  decoration: InputDecoration(
                    labelText: 'Sök Trip ID / Tågnummer',
                    hintText: 't.ex. 524, 912, 1042',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onSubmitted: (val) => _loadTrainComposition(val),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _loadTrainComposition(_tripSearchController.text),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Sök'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
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
                      onPressed: () => _loadTrainComposition(_selectedTripId),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
            )
          else if (_composition != null)
            Column(
              children: [
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
                    );
                  },
                ),
              ],
            ),
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
