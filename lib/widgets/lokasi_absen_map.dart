import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'cache_tile.dart';

Future<void> showLokasiAbsenMap(
  BuildContext context, {
  required double latUser,
  required double lngUser,
  required double latUnit,
  required double lngUnit,
  required double radius,
  required double jarak,
  required String namaUnit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _LokasiAbsenSheet(
      user: LatLng(latUser, lngUser),
      unit: LatLng(latUnit, lngUnit),
      radius: radius,
      jarak: jarak,
      namaUnit: namaUnit,
    ),
  );
}

class _LokasiAbsenSheet extends StatelessWidget {
  final LatLng user;
  final LatLng unit;
  final double radius;
  final double jarak;
  final String namaUnit;

  const _LokasiAbsenSheet({
    required this.user,
    required this.unit,
    required this.radius,
    required this.jarak,
    required this.namaUnit,
  });

  static const Color _merahUser = Color(0xFFFF5E62);
  static const Color _biruUnit = Color(0xFF3B6DF0);

  @override
  Widget build(BuildContext context) {
    final tinggi = MediaQuery.of(context).size.height * 0.7;

    return SafeArea(
      child: SizedBox(
        height: tinggi,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.location_off, color: _merahUser),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Anda ${jarak.toStringAsFixed(0)} m dari titik absen '
                      '(batas ${radius.toStringAsFixed(0)} m)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  options: MapOptions(
                    initialCameraFit: CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints([user, unit]),
                      padding: const EdgeInsets.all(56),
                      maxZoom: 19,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      maxZoom: 19,
                      tileProvider: CachedTileProvider(),
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: unit,
                          radius: radius,
                          useRadiusInMeter: true,
                          color: _biruUnit.withOpacity(0.18),
                          borderColor: _biruUnit,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [user, unit],
                          strokeWidth: 3,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      rotate: true,
                      markers: [
                        Marker(
                          width: 44,
                          height: 44,
                          point: unit,
                          alignment: Alignment.topCenter,
                          child: const Icon(
                            Icons.business,
                            color: _biruUnit,
                            size: 36,
                          ),
                        ),
                        Marker(
                          width: 44,
                          height: 44,
                          point: user,
                          alignment: Alignment.topCenter,
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: _merahUser,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.person_pin_circle,
                      color: _merahUser, size: 18),
                  const SizedBox(width: 6),
                  const Text('Lokasi Anda', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 20),
                  const Icon(Icons.business, color: _biruUnit, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      namaUnit,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
