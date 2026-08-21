import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/traffic_cam_model.dart';
import '../services/trafikverket_service.dart';

class TrafficCamsView extends StatefulWidget {
  const TrafficCamsView({super.key});

  @override
  State<TrafficCamsView> createState() => _TrafficCamsViewState();
}

class _TrafficCamsViewState extends State<TrafficCamsView> {
  Future<List<TrafikverketCam>>? _camerasFuture;
  List<TrafikverketCam> _cachedCameras = [];
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    setState(() {
      _hasError = false;
    });
    
    _camerasFuture = TrafikverketService.fetchTrafficCameras().then((cams) {
      setState(() {
        _cachedCameras = cams;
        _hasError = false;
      });
      return cams;
    }).catchError((error) {
      setState(() {
        _hasError = true;
      });
      debugPrint('Fehler beim Laden der Kameras: $error');
      return <TrafikverketCam>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<TrafikverketCam>>(
      future: _camerasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (_hasError || snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  Intl.message(
                    'Kameradaten konnten nicht geladen werden',
                    desc: 'Error message when camera data fails to load',
                  ),
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error?.toString() ?? 'Unbekannter Fehler',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadCameras,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(Intl.message(
                    'Erneut versuchen',
                    desc: 'Retry button label',
                  )),
                ),
              ],
            ),
          );
        }

        final cameras = _cachedCameras;
        if (cameras.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_off_rounded,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  Intl.message(
                    'Keine Kameradaten verfügbar',
                    desc: 'Message when no camera data is available',
                  ),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        // Finde aktive Brückenöffnung
        final activeBridgeCam = cameras.firstWhere(
          (c) => c.isBridgeActive,
          orElse: () => cameras.first,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
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
                        child: Icon(Icons.videocam_rounded, color: theme.colorScheme.onSecondary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Intl.message(
                                'Trafikverket Datex II Live-Kameror',
                                desc: 'Header title in traffic cams view',
                              ),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                            Text(
                              Intl.message(
                                'Knutpunkter, Broöppningar & Vägarbeten',
                                desc: 'Header subtitle in traffic cams view',
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: _loadCameras,
                        tooltip: 'Uppdatera bilder',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Active Bridge Opening Alert Box
              if (activeBridgeCam.isBridgeActive)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.shade700),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  Intl.message(
                                    'LIVE BROÖPPNING: ${activeBridgeCam.locationName}',
                                    desc: 'Live bridge opening alert text',
                                  ),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeBridgeCam.statusDescription,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().shake(duration: const Duration(milliseconds: 400)),

              // Camera Feeds Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  childAspectRatio: 1.35,
                  mainAxisSpacing: 16,
                ),
                itemCount: cameras.length,
                itemBuilder: (context, index) {
                  final cam = cameras[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                cam.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: const Center(child: Icon(Icons.broken_image_rounded, size: 48)),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        cam.roadName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cam.title,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cam.statusDescription,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
