import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';

class ImageUtils {
  /// Returns a list of asset image paths from a specified directory
  static Future<List<String>> getImagePathsFromDirectory(String directoryPath) async {
    try {
      // Get all assets using the rootBundle
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = Map.from(
        const JsonDecoder().convert(manifestContent)
      );
      
      // Filter for images in the specified directory
      final imagePaths = manifestMap.keys
        .where((String key) => 
          key.startsWith(directoryPath) && 
          (key.endsWith('.png') || key.endsWith('.jpg') || key.endsWith('.jpeg')))
        .toList();
      
      return imagePaths;
    } catch (e) {
      print('Error loading images from $directoryPath: $e');
      return [];
    }
  }
}