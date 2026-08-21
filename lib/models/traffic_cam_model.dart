class TrafikverketCam {
  final String id;
  final String title;
  final String locationName;
  final String imageUrl;
  final double lat;
  final double lng;
  final String roadName; // e.g. E4 / E20 Essingeleden, Göta Älvbron
  final DateTime lastUpdated;
  final bool isBridgeActive; // e.g., bridge opening status
  final String statusDescription;

  const TrafikverketCam({
    required this.id,
    required this.title,
    required this.locationName,
    required this.imageUrl,
    required this.lat,
    required this.lng,
    required this.roadName,
    required this.lastUpdated,
    this.isBridgeActive = false,
    required this.statusDescription,
  });
}
