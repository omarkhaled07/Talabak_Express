import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'map_picker_screen.dart';

class MapUtils {
  static Future<LatLng?> showMapPicker({
    required BuildContext context,
    LatLng? initialLocation,
  }) async {
    final LatLng? selectedLocation = await Navigator.push<LatLng?>(
      context,
      MaterialPageRoute(
        builder: (context) => GoogleMapPicker(
          initialLocation: initialLocation,
        ),
      ),
    );
    return selectedLocation;
  }

  static Widget buildLocationPreview(LatLng? location) {
    if (location == null) return const SizedBox();

    return SizedBox(
      height: 150,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: location,
          zoom: 15,
        ),
        onMapCreated: (controller) {},
        myLocationEnabled: false,
      ),
    );
  }
}