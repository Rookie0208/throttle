import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; // optional

class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;

  const MapPickerScreen({super.key, required this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? selectedLocation;
  String locationName = "";

  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialLocation;
  }

  Future<void> _getAddress(LatLng position) async {
    try {
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          locationName = "${place.locality}, ${place.country}";
        });
      }
    } catch (e) {
      setState(() {
        locationName = "${position.latitude}, ${position.longitude}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Location"),
        backgroundColor: Colors.orange,
        actions: [
          TextButton(
            onPressed: () {
              if (selectedLocation != null) {
                Navigator.pop(context, {
                  "name": locationName,
                  "latitude": selectedLocation!.latitude,
                  "longitude": selectedLocation!.longitude,
                });
              }
            },
            child: const Text("Select",
                style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.initialLocation,
          zoom: 14,
        ),
        onMapCreated: (controller) => _mapController = controller,
        onTap: (position) async {
          setState(() => selectedLocation = position);
          await _getAddress(position);
        },
        markers: selectedLocation != null
            ? {
                Marker(
                    markerId: const MarkerId("selected"),
                    position: selectedLocation!)
              }
            : {},
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black87,
        child: Text(
          selectedLocation != null
              ? "Selected: $locationName"
              : "Tap on map to select a location",
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
