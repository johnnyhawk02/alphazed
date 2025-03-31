import 'package:flutter/services.dart';
import 'dart:convert';

class AssetLoader {
  static Future<List<String>> getAssets({
    required String directory,
    String? extension,
    List<String>? extensions,
  }) async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      return manifestMap.keys
          .where((key) {
            if (!key.startsWith('assets/$directory/')) return false;
            
            if (extension != null) {
              return key.endsWith(extension);
            }
            
            if (extensions != null) {
              return extensions.any((ext) => key.endsWith(ext));
            }
            
            return true;
          })
          .toList();
    } catch (e) {
      print('Error loading assets from $directory: $e');
      return [];
    }
  }
}