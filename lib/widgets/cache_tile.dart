import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class CachedTileProvider extends TileProvider {
  @override
  ImageProvider<Object> getImage(TileCoordinates coords, TileLayer layer) {
    // Ambil subdomain pertama kalau ada, kalau tidak kosongkan
    final subdomain = layer.subdomains.isNotEmpty ? layer.subdomains[0] : '';

    // Pastikan urlTemplate tidak null
    final template = layer.urlTemplate ?? '';

    // Susun URL tile secara manual
    final url = template
        .replaceAll('{s}', subdomain)
        .replaceAll('{z}', coords.z.toString())
        .replaceAll('{x}', coords.x.toString())
        .replaceAll('{y}', coords.y.toString());

    return CachedNetworkImageProvider(url);
  }
}
