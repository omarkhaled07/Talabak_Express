import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'map_bounds.dart';

class GoogleMapPicker extends StatefulWidget {
  final LatLng? initialLocation;

  const GoogleMapPicker({Key? key, this.initialLocation}) : super(key: key);

  @override
  _GoogleMapPickerState createState() => _GoogleMapPickerState();
}

class _GoogleMapPickerState extends State<GoogleMapPicker> {
  late GoogleMapController _mapController;
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  bool _isLoading = true;
  bool _searching = false;
  final TextEditingController _searchController = TextEditingController();
  Set<Marker> _markers = {};
  String _currentAddress = 'جاري تحديد الموقع...';

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _initializeWithLocation(widget.initialLocation!);
    } else {
      _getCurrentLocation();
    }
  }

  void _initializeWithLocation(LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _currentLocation = location;
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      _isLoading = false;
    });
    await _updateAddressFromLocation(location);
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _currentAddress = 'جاري تحديد الموقع الحالي...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تفعيل خدمات الموقع', textDirection: TextDirection.rtl)),
        );
        _setDefaultLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يرجى منح إذن الوصول إلى الموقع', textDirection: TextDirection.rtl)),
          );
          _setDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفض إذن الموقع بشكل دائم، يرجى تفعيله من الإعدادات', textDirection: TextDirection.rtl)),
        );
        _setDefaultLocation();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final newLocation = LatLng(position.latitude, position.longitude);

      if (!MapBounds.isWithinBounds(newLocation)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('موقعك الحالي خارج نطاق التوصيل، لكن يمكنك تحديد موقع داخل النطاق', textDirection: TextDirection.rtl)),
        );
      }

      setState(() {
        _currentLocation = newLocation;
        _selectedLocation = newLocation;
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('selected_location'),
            position: newLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
        _isLoading = false;
      });

      _mapController.animateCamera(CameraUpdate.newLatLngZoom(newLocation, 16));
      await _updateAddressFromLocation(newLocation);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الحصول على الموقع: ${e.toString()}', textDirection: TextDirection.rtl)),
      );
      _setDefaultLocation();
    }
  }

  void _setDefaultLocation() async {
    final defaultLocation = MapBounds.center;
    setState(() {
      _currentLocation = defaultLocation;
      _selectedLocation = defaultLocation;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: defaultLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      _isLoading = false;
      _currentAddress = 'الموقع الافتراضي';
    });

    if (_mapController != null) {
      _mapController.animateCamera(CameraUpdate.newLatLngZoom(defaultLocation, 14));
    }
  }

  Future<void> _updateAddressFromLocation(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _currentAddress = '${place.street}, ${place.locality}, ${place.country}' ?? 'عنوان غير معروف';
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'تعذر الحصول على العنوان';
      });
    }
  }

  Future<void> _searchLocation() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _searching = true;
    });

    try {
      List<Location> locations = await locationFromAddress(_searchController.text);
      if (locations.isNotEmpty) {
        final newLocation = LatLng(locations.first.latitude, locations.first.longitude);

        if (!MapBounds.isWithinBounds(newLocation)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('الموقع المحدد خارج نطاق التوصيل', textDirection: TextDirection.rtl)),
          );
        }

        setState(() {
          _selectedLocation = newLocation;
          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('selected_location'),
              position: newLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );
        });

        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(newLocation, 16),
        );
        await _updateAddressFromLocation(newLocation);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم العثور على العنوان', textDirection: TextDirection.rtl)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء البحث: ${e.toString()}', textDirection: TextDirection.rtl)),
      );
    } finally {
      setState(() {
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('اختر موقع التوصيل', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff112b16),
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentLocation == null) {
                _setDefaultLocation();
              }
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? MapBounds.center,
              zoom: 14,
            ),
            onTap: (latLng) {
              if (MapBounds.isWithinBounds(latLng)) {
                setState(() {
                  _selectedLocation = latLng;
                  _markers.clear();
                  _markers.add(
                    Marker(
                      markerId: const MarkerId('selected_location'),
                      position: latLng,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    ),
                  );
                });
                _mapController.animateCamera(CameraUpdate.newLatLng(latLng));
                _updateAddressFromLocation(latLng);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الموقع المحدد خارج نطاق التوصيل', textDirection: TextDirection.rtl)),
                );
              }
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'ابحث عن عنوان أو مكان...',
                          hintTextDirection: TextDirection.rtl,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          prefixIcon: _searching
                              ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                              : const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        ),
                        onSubmitted: (_) => _searchLocation(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: _searchLocation,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'location_fab',
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.green),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الموقع المحدد:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentAddress,
                      style: const TextStyle(fontSize: 14),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الإحداثيات: ${_selectedLocation?.latitude.toStringAsFixed(6)}, ${_selectedLocation?.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _selectedLocation != null && MapBounds.isWithinBounds(_selectedLocation!)
                            ? () {
                          Navigator.pop(context, _selectedLocation);
                        }
                            : null,
                        child: const Text('تأكيد الموقع', style: TextStyle(fontSize: 16 , color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}