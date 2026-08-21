import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/stop_model.dart';
import '../models/departure_model.dart';
import '../data/stop_repository.dart';
import '../repositories/realtime_repository.dart';
import '../services/trip_details_service.dart';

class DepartureMonitorView extends StatefulWidget {
  const DepartureMonitorView({super.key});

  @override
  State<DepartureMonitorView> createState() => _DepartureMonitorViewState();
}

class _DepartureMonitorViewState extends State<DepartureMonitorView> {
  final TextEditingController _searchController = TextEditingController();
  TransitStop? _selectedStop; // T-Centralen (740000001) wird async geladen
  FtsSearchResult? _searchResults;
  List<TransitDeparture> _departures = [];
  bool _isLoadingDepartures = false;
  String _selectedModeFilter = 'Alla';

  @override
  void initState() {
    super.initState();
    _loadSelectedStop();
    _performSearch('');
  }

  Future<void> _loadSelectedStop() async {
    final stopRepository = Provider.of<StopRepository>(context, listen: false);
    final stop = await stopRepository.getStopById('740000001');
    if (!mounted) return;
    setState(() => _selectedStop = stop);
    _loadDepartures();
  }

  Future<void> _performSearch(String query) async {
    final stopRepository = Provider.of<StopRepository>(context, listen: false);
    final results = await stopRepository.search(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  Future<void> _loadDepartures() async {
    final selected = _selectedStop;
    if (selected == null) return;
    setState(() => _isLoadingDepartures = true);
    final realtimeRepository = Provider.of<RealtimeRepository>(context, listen: false);
    final list = await realtimeRepository.fetchDepartures(selected.id);
    if (mounted) {
      setState(() {
        _departures = list;
        _isLoadingDepartures = false;
      });
    }
  }

  Color _getModeColor(TransitMode mode) {
    switch (mode) {
      case TransitMode.tunnelbana:
        return const Color(0xFFEF4444);
      case TransitMode.pendeltag:
        return const Color(0xFF3B82F6);
      case TransitMode.fjarrtag:
        return const Color(0xFF10B981);
      case TransitMode.tram:
        return const Color(0xFFF59E0B);
      case TransitMode.bus:
        return const Color(0xFF8B5CF6);
      case TransitMode.ferry:
        return const Color(0xFF06B6D4);
    }
  }

  IconData _getModeIcon(TransitMode mode) {
    switch (mode) {
      case TransitMode.tunnelbana:
        return Icons.subway_rounded;
      case TransitMode.pendeltag:
      case TransitMode.fjarrtag:
        return Icons.train_rounded;
      case TransitMode.tram:
        return Icons.tram_rounded;
      case TransitMode.bus:
        return Icons.directions_bus_rounded;
      case TransitMode.ferry:
        return Icons.directions_boat_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filteredDepartures = _departures.where((d) {
      if (_selectedModeFilter == 'Alla') return true;
      if (_selectedModeFilter == 'Tåg' && (d.mode == TransitMode.fjarrtag || d.mode == TransitMode.pendeltag)) return true;
      if (_selectedModeFilter == 'T-bana' && d.mode == TransitMode.tunnelbana) return true;
      if (_selectedModeFilter == 'Buss' && d.mode == TransitMode.bus) return true;
      if (_selectedModeFilter == 'Spårvagn' && d.mode == TransitMode.tram) return true;
      return true;
    }).toList();

    return Column(
      children: [
        // Top Search Header with FTS5 Sub-10ms Engine Tag
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              SearchBar(
                controller: _searchController,
                hintText: Intl.message(
              'Sök hållplats eller ort (t.ex. Slussen, Göteborg)...',
              desc: 'Search bar hint text',
            ),
                leading: const Icon(Icons.search_rounded),
                trailing: [
                  if (_searchResults != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'FTS5 ${_searchResults!.executionMs}ms',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                ],
                onChanged: (val) => _performSearch(val),
              ),

              // Search Auto-complete Suggestions Dropdown
              if (_searchController.text.isNotEmpty && _searchResults != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults!.stops.length,
                    itemBuilder: (context, index) {
                      final stop = _searchResults!.stops[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.place_rounded, size: 20),
                        title: Text(stop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${stop.city} • ${stop.operatorName} • Rikshållplats ${stop.rikshallplatsId}'),
                        onTap: () {
                          setState(() {
                            _selectedStop = stop;
                            _searchController.clear();
                          });
                          _loadDepartures();
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        // Selected Station Hero Card
        if (_selectedStop != null)
          Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.directions_transit_rounded, color: theme.colorScheme.onPrimary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedStop!.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          '${_selectedStop!.city} • Operatör: ${_selectedStop!.operatorName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: _selectedStop!.platforms.map((p) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _loadDepartures,
                    tooltip: 'Uppdatera realtid',
                  ),
                ],
              ),
            ),
          ),
        ),

        // Mode Filter Segment Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Alla', 'T-bana', 'Tåg', 'Buss', 'Spårvagn'].map((label) {
                final isSelected = _selectedModeFilter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: isSelected,
                    label: Text(label),
                    onSelected: (_) {
                      setState(() {
                        _selectedModeFilter = label;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Departure List View
        Expanded(
          child: _isLoadingDepartures
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: filteredDepartures.length,
                  itemBuilder: (context, index) {
                    final dep = filteredDepartures[index];
                    return _buildDepartureCard(context, dep, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDepartureCard(BuildContext context, TransitDeparture dep, int index) {
    final theme = Theme.of(context);
    final isDelayed = dep.status == DepartureStatus.delayed;
    final isCancelled = dep.status == DepartureStatus.cancelled;
    final isPlatformChange = dep.status == DepartureStatus.platformChange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showTripTimelineModal(context, dep),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Line Number Badge
              Container(
                constraints: const BoxConstraints(minWidth: 54),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: _getModeColor(dep.mode),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getModeIcon(dep.mode), color: Colors.white, size: 18),
                    const SizedBox(height: 2),
                    Text(
                      dep.line,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Destination & Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dep.destination,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPlatformChange
                                ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isPlatformChange
                                ? '${dep.track} (Ändrat från ${dep.originalTrack})'
                                : dep.track,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPlatformChange ? const Color(0xFF8B5CF6) : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dep.operatorName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Realtime Time & Delay Pulse Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${dep.realtimeTime.hour.toString().padLeft(2, '0')}:${dep.realtimeTime.minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isCancelled
                          ? Colors.red
                          : (isDelayed ? Colors.amber.shade800 : theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Realtime Delay Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? Colors.red.withValues(alpha: 0.15)
                          : (isDelayed
                              ? Colors.amber.shade800.withValues(alpha: 0.15)
                              : const Color(0xFF10B981).withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      dep.formattedDelay,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCancelled
                            ? Colors.red
                            : (isDelayed ? Colors.amber.shade900 : const Color(0xFF10B981)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: Duration(milliseconds: 200 + (index * 40))).slideY(begin: 0.1, end: 0);
  }

  void _showTripTimelineModal(BuildContext context, TransitDeparture dep) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final tripDetailsService = TripDetailsService();

        return FutureBuilder<List<TripStopInfo>>(
          future: tripDetailsService.fetchTripStops(dep.id, dep.scheduledTime),
          builder: (context, snapshot) {
            final stops = snapshot.data ?? [];
            final isLoading = snapshot.connectionState == ConnectionState.waiting;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getModeIcon(dep.mode), color: _getModeColor(dep.mode)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Linje ${dep.line} mot ${dep.destination}',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text('Operatör: ${dep.operatorName} • Spår: ${dep.track}'),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Text(
                    'Echtes Realtidsförlopp (Trip Details API)',
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else if (stops.isEmpty)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildTimelineStep(_selectedStop?.name ?? 'Start', dep.scheduledTime.toString().substring(11, 16), dep.realtimeTime.toString().substring(11, 16), false, true),
                            _buildTimelineStep(dep.destination, '--:--', '--:--', false, false),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: stops.length,
                        itemBuilder: (context, idx) {
                          final st = stops[idx];
                          return _buildTimelineStep(
                            st.stationName,
                            st.scheduledTime,
                            st.realtimeTime,
                            st.isPassed,
                            st.isCurrent,
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimelineStep(String station, String sched, String realtime, bool isPassed, bool isCurrent) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isCurrent
                ? Icons.radio_button_checked_rounded
                : (isPassed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
            color: isCurrent ? theme.colorScheme.primary : (isPassed ? Colors.grey : theme.colorScheme.outline),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              station,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                decoration: isPassed ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            realtime,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
