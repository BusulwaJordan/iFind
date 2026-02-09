import 'package:latlong2/latlong.dart';

class DistanceCalculator {
  DistanceCalculator._();

  static const Distance _distance = Distance();

  /// Calculate distance between two coordinates in kilometers
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final point1 = LatLng(lat1, lon1);
    final point2 = LatLng(lat2, lon2);

    // Returns distance in meters, convert to km
    return _distance.as(LengthUnit.Kilometer, point1, point2);
  }

  /// Format distance for display
  /// Returns "X.X km" or "X m" depending on distance
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      final meters = (distanceInKm * 1000).round();
      return '$meters m';
    } else {
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

  /// Check if location is within radius
  static bool isWithinRadius({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
    required double radiusInKm,
  }) {
    final distance = calculateDistance(
      lat1: lat1,
      lon1: lon1,
      lat2: lat2,
      lon2: lon2,
    );
    return distance <= radiusInKm;
  }
}
