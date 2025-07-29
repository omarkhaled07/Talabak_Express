import 'package:google_maps_flutter/google_maps_flutter.dart';


class MapBounds {
  // الحدود الجديدة
  static const double north = 31.408083; // 31°24'29.1"N
  static const double south = 31.166401; // 31°10'0.0"N
  static const double east = 30.895194;  // 30°53'42.7"E
  static const double west = 30.679305;  // 30°40'45.5"E

  static bool isWithinBounds(LatLng point) {
    return point.latitude <= north &&
        point.latitude >= south &&
        point.longitude <= east &&
        point.longitude >= west;
  }

  static String getBoundsMessage() {
    return 'نطاق التوصيل الحالي:\n'
        'الشمال: 31°24\'29.1"N\n'
        'الجنوب: 31°10\'0.0"N\n'
        'الشرق: 30°53\'42.7"E\n'
        'الغرب: 30°40\'45.5"E';
  }

  static LatLng get center => const LatLng(
    (31.408083 + 31.166401) / 2,
    (30.895194 + 30.679305) / 2,
  );
}