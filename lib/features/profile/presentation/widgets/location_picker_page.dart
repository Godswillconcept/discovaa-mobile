import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerPage extends ConsumerStatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const LocationPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  });

  @override
  ConsumerState<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends ConsumerState<LocationPickerPage> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  Marker? _marker;
  String _address = '';
  bool _isLoading = true;

  static const _defaultLocation = LatLng(6.5244, 3.3792); // Lagos, Nigeria

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLatitude != null && widget.initialLongitude != null
        ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
        : _defaultLocation;
    _address = widget.initialAddress ?? '';
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    // If no initial location provided, try to get current location
    if (widget.initialLatitude == null || widget.initialLongitude == null) {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });
        await _getAddressFromCoordinates(_selectedLocation!);
      } catch (e) {
        // Fallback to default location
        setState(() {
          _selectedLocation = _defaultLocation;
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getAddressFromCoordinates(LatLng location) async {
    try {
      final places = await geocoding.placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (places.isNotEmpty) {
        final placemark = places.first;
        final address = [
          placemark.street,
          if (placemark.subLocality?.isNotEmpty == true) placemark.subLocality,
          if (placemark.locality?.isNotEmpty == true) placemark.locality,
          if (placemark.administrativeArea?.isNotEmpty == true) placemark.administrativeArea,
          if (placemark.country?.isNotEmpty == true) placemark.country,
        ].where((part) => part != null && part.isNotEmpty).join(', ');
        setState(() {
          _address = address;
        });
      }
    } catch (e) {
      // Address lookup failed, keep existing address
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMarker();
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _selectedLocation = position.target;
    });
  }

  void _onCameraIdle() {
    _updateMarker();
    _getAddressFromCoordinates(_selectedLocation!);
  }

  void _updateMarker() {
    setState(() {
      _marker = Marker(
        markerId: const MarkerId('selected_location'),
        position: _selectedLocation!,
        draggable: true,
        onDragEnd: (position) {
          setState(() {
            _selectedLocation = position;
          });
          _getAddressFromCoordinates(position);
        },
      );
    });
  }

  void _goToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final location = LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 15),
        ),
      );
      setState(() {
        _selectedLocation = location;
      });
      await _getAddressFromCoordinates(location);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get current location')),
        );
      }
    }
  }

  void _confirmLocation() {
    if (_selectedLocation == null) return;
    Navigator.pop(context, {
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
      'address': _address,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Select Location'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToCurrentLocation,
            tooltip: 'Go to current location',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _selectedLocation!,
                zoom: 15,
              ),
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              markers: _marker != null ? {_marker!} : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Address',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _address.isNotEmpty ? _address : 'Fetching address...',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
