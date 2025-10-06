import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';

/// Asset Path Service
/// Handles loading assets from external files or bundled assets
class AssetPathService {
  static String? _executableDir;
  
  /// Get the executable directory
  static String get executableDirectory {
    _executableDir ??= path.dirname(Platform.resolvedExecutable);
    return _executableDir!;
  }
  
  /// Get external data directory
  static String get dataDirectory => path.join(executableDirectory, 'data');
  
  /// Get external images directory
  static String get imagesDirectory => path.join(executableDirectory, 'images');
  
  /// Check if running from external deployment
  static Future<bool> isExternalDeployment() async {
    try {
      final dataDir = Directory(dataDirectory);
      final imagesDir = Directory(imagesDirectory);
      
      return await dataDir.exists() && await imagesDir.exists();
    } catch (e) {
      return false;
    }
  }
  
  /// Get image path (external or asset)
  static Future<String> getImagePath(String imageName) async {
    final isExternal = await isExternalDeployment();
    
    if (isExternal) {
      final externalPath = path.join(imagesDirectory, imageName);
      final file = File(externalPath);
      
      if (await file.exists()) {
        return externalPath;
      }
    }
    
    // Fall back to bundled asset
    return 'assets/images/$imageName';
  }
  
  /// Get data file path (external or asset)
  static Future<String> getDataPath(String fileName) async {
    final isExternal = await isExternalDeployment();
    
    if (isExternal) {
      final externalPath = path.join(dataDirectory, fileName);
      final file = File(externalPath);
      
      if (await file.exists()) {
        return externalPath;
      }
    }
    
    // Fall back to bundled asset
    return 'assets/data/$fileName';
  }
  
  /// Load image from external file or assets
  static Future<String> loadImageAsString(String imageName) async {
    final imagePath = await getImagePath(imageName);
    
    if (imagePath.startsWith('assets/')) {
      // Load from bundled assets
      final byteData = await rootBundle.load(imagePath);
      final bytes = byteData.buffer.asUint8List();
      return String.fromCharCodes(bytes);
    } else {
      // Load from external file
      final file = File(imagePath);
      return await file.readAsString();
    }
  }
  
  /// Load data file content
  static Future<String> loadDataFile(String fileName) async {
    final dataPath = await getDataPath(fileName);
    
    if (dataPath.startsWith('assets/')) {
      // Load from bundled assets
      return await rootBundle.loadString(dataPath);
    } else {
      // Load from external file
      final file = File(dataPath);
      return await file.readAsString();
    }
  }
  
  /// List all files in data directory
  static Future<List<String>> listDataFiles() async {
    final isExternal = await isExternalDeployment();
    
    if (isExternal) {
      final dataDir = Directory(dataDirectory);
      if (await dataDir.exists()) {
        final files = await dataDir.list().toList();
        return files
            .where((entity) => entity is File)
            .map((entity) => path.basename(entity.path))
            .toList();
      }
    }
    
    // For bundled assets, return known files
    return [
      'db-struct',
      'db-value',
      'kantor.csv',
      'klu.csv',
      'map.csv',
      'jatuhtempo.csv',
      'maxlapor.csv',
    ];
  }
  
  /// Check if specific data file exists
  static Future<bool> dataFileExists(String fileName) async {
    final dataPath = await getDataPath(fileName);
    
    if (dataPath.startsWith('assets/')) {
      // For bundled assets, try to load
      try {
        await rootBundle.loadString(dataPath);
        return true;
      } catch (e) {
        return false;
      }
    } else {
      // For external files, check existence
      final file = File(dataPath);
      return await file.exists();
    }
  }
  
  /// Get deployment info
  static Future<Map<String, dynamic>> getDeploymentInfo() async {
    final isExternal = await isExternalDeployment();
    
    return {
      'isExternalDeployment': isExternal,
      'executableDirectory': executableDirectory,
      'dataDirectory': dataDirectory,
      'imagesDirectory': imagesDirectory,
      'hasExternalData': isExternal ? await Directory(dataDirectory).exists() : false,
      'hasExternalImages': isExternal ? await Directory(imagesDirectory).exists() : false,
    };
  }
}