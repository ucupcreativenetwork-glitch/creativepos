import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/delivery_models.dart';

class DeliveryMapWidget extends StatelessWidget {
  const DeliveryMapWidget({
    super.key,
    required this.trackingPoints,
    this.height = 220,
  });

  final List<TrackingPoint> trackingPoints;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (trackingPoints.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Belum ada data GPS')),
      );
    }

    final latest = trackingPoints.first;
    final markers = <Marker>{
      for (var i = 0; i < trackingPoints.length; i++)
        Marker(
          markerId: MarkerId('p$i'),
          position: LatLng(
            trackingPoints[i].latitude,
            trackingPoints[i].longitude,
          ),
          infoWindow: InfoWindow(
            title: i == 0 ? 'Terbaru' : 'Titik ${trackingPoints.length - i}',
            snippet: trackingPoints[i].recordedAt,
          ),
        ),
    };

    final polylines = trackingPoints.length > 1
        ? {
            Polyline(
              polylineId: const PolylineId('route'),
              color: Theme.of(context).colorScheme.primary,
              width: 4,
              points: [
                for (final p in trackingPoints.reversed)
                  LatLng(p.latitude, p.longitude),
              ],
            ),
          }
        : <Polyline>{};

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(latest.latitude, latest.longitude),
            zoom: 14,
          ),
          markers: markers,
          polylines: polylines,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
        ),
      ),
    );
  }
}