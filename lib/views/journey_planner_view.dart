import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/stop_repository.dart';
import '../models/stop_model.dart';
import '../services/api_exception.dart';
import '../services/resrobot_journey_service.dart';

class JourneyPlannerView extends StatefulWidget {
  const JourneyPlannerView({super.key});

  @override
  State<JourneyPlannerView> createState() => _JourneyPlannerViewState();
}

class _JourneyPlannerViewState extends State<JourneyPlannerView> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destController = TextEditingController();

  TransitStop? _selectedOrigin;
  TransitStop? _selectedDest;

  FtsSearchResult? _originSearchResults;
  FtsSearchResult? _destSearchResults;

  final ResRobotJourneyService _journeyService = ResRobotJourneyService();

  List<JourneyTrip> _trips = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _errorDetail;

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    super.dispose();
  }

  Future<void> _searchOriginStops(String query) async {
    final repo = Provider.of<StopRepository>(context, listen: false);
    final res = await repo.search(query);
    if (mounted) {
      setState(() => _originSearchResults = res);
    }
  }

  Future<void> _searchDestStops(String query) async {
    final repo = Provider.of<StopRepository>(context, listen: false);
    final res = await repo.search(query);
    if (mounted) {
      setState(() => _destSearchResults = res);
    }
  }

  Future<void> _searchJourney() async {
    final origin = _selectedOrigin;
    final dest = _selectedDest;

    if (origin == null || dest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vänligen välj både från- och till-hållplats')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorDetail = null;
      _trips = [];
    });

    try {
      final results = await _journeyService.searchTrip(
        originId: origin.id,
        destId: dest.id,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _trips = results;
        _errorMessage = results.isEmpty ? 'Inga rutter hittades för den valda sträckan.' : null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.userMessage;
        _errorDetail = e.technicalDetail ?? e.toString();
      });
    } catch (e) {
      if (!mounted) return;
      const apiError = ApiException(
        kind: ApiExceptionKind.network,
        userMessage: 'Okänt fel vid rutt-sökningen.',
      );
      setState(() {
        _isLoading = false;
        _errorMessage = apiError.userMessage;
        _errorDetail = e.toString();
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
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.route_rounded, color: theme.colorScheme.onSecondary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ResRobot v2.1 Journeys (A → B)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                        Text(
                          'Hela Sveriges kollektivtrafik & byte-rekommendationer',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
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

          // Origin Search Box
          SearchBar(
            controller: _originController,
            hintText: 'Från (Start-hållplats)...',
            leading: const Icon(Icons.trip_origin_rounded, color: Colors.green),
            onChanged: (val) => _searchOriginStops(val),
          ),
          if (_originController.text.isNotEmpty && _selectedOrigin == null && _originSearchResults != null)
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 8),
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _originSearchResults!.stops.length,
                itemBuilder: (context, idx) {
                  final stop = _originSearchResults!.stops[idx];
                  return ListTile(
                    dense: true,
                    title: Text(stop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(stop.city),
                    onTap: () {
                      setState(() {
                        _selectedOrigin = stop;
                        _originController.text = stop.name;
                      });
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 12),

          // Destination Search Box
          SearchBar(
            controller: _destController,
            hintText: 'Till (Mål-hållplats)...',
            leading: const Icon(Icons.place_rounded, color: Colors.red),
            onChanged: (val) => _searchDestStops(val),
          ),
          if (_destController.text.isNotEmpty && _selectedDest == null && _destSearchResults != null)
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 8),
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _destSearchResults!.stops.length,
                itemBuilder: (context, idx) {
                  final stop = _destSearchResults!.stops[idx];
                  return ListTile(
                    dense: true,
                    title: Text(stop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(stop.city),
                    onTap: () {
                      setState(() {
                        _selectedDest = stop;
                        _destController.text = stop.name;
                      });
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 16),

          // Search Journey Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _searchJourney,
              icon: const Icon(Icons.directions_run_rounded),
              label: const Text('Sök Resa (A → B)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Results
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (_errorMessage != null)
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: theme.colorScheme.onErrorContainer, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: theme.colorScheme.onErrorContainer, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (_errorDetail != null) ...[
                      const SizedBox(height: 8),
                      Theme(
                        data: theme.copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: EdgeInsets.zero,
                          title: Text(
                            'Teknisk detalj',
                            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8)),
                          ),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SelectableText(
                                _errorDetail!,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else if (_trips.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sökresultat & Byten:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _trips.length,
                  itemBuilder: (context, idx) {
                    final trip = _trips[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${trip.departureTime} → ${trip.arrivalTime}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${trip.duration} • ${trip.transfers} byte(n)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            ...trip.legs.map((leg) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.directions_transit_rounded, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Linje ${leg.line} (${leg.transportType})',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text('${leg.originName} (${leg.departureTime}) → ${leg.destinationName} (${leg.arrivalTime})'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
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
}
