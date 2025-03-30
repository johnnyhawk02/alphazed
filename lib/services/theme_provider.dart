import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _bgColorKey = 'background_color';
  
  // Default background color from GameConfig
  Color _backgroundColor = Color.fromARGB(255, 255, 247, 17);
  
  // Flash overlay color and opacity
  Color? _flashColor;
  double _flashOpacity = 0.0;
  bool _isPulsing = false;
  
  Color get backgroundColor => _backgroundColor;
  Color? get flashColor => _flashColor;
  double get flashOpacity => _flashOpacity;
  
  ThemeProvider() {
    _loadSavedColor();
  }
  
  // Load the saved color from SharedPreferences
  Future<void> _loadSavedColor() async {
    final prefs = await SharedPreferences.getInstance();
    final savedColorValue = prefs.getInt(_bgColorKey);
    
    if (savedColorValue != null) {
      _backgroundColor = Color(savedColorValue);
      notifyListeners();
    }
  }
  
  // Set a new background color and save it
  Future<void> setBackgroundColor(Color color) async {
    _backgroundColor = color;
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bgColorKey, color.value);
    
    notifyListeners();
  }
  
  // Flash the background with green color for correct answers
  void flashCorrect() {
    _flashColor = Colors.green;
    _flashOpacity = 0.9; // Increased to 90% opacity
    _isPulsing = true;
    notifyListeners();
    
    _startPulsing();
    
    // End the flash effect after 500ms
    Future.delayed(const Duration(milliseconds: 500), () {
      _isPulsing = false;
      _fadeOutFlash();
    });
  }
  
  // Flash the background with red color for incorrect answers
  void flashIncorrect() {
    _flashColor = Colors.red;
    _flashOpacity = 0.9; // Increased to 90% opacity
    _isPulsing = true;
    notifyListeners();
    
    _startPulsing();
    
    // End the flash effect after 500ms
    Future.delayed(const Duration(milliseconds: 500), () {
      _isPulsing = false;
      _fadeOutFlash();
    });
  }
  
  // Create a pulsing effect by varying the opacity
  void _startPulsing() {
    if (!_isPulsing) return;
    
    // Pulse between 70% and 90% opacity
    _flashOpacity = _flashOpacity > 0.8 ? 0.7 : 0.9;
    notifyListeners();
    
    // Continue pulsing every 100ms
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_isPulsing) _startPulsing();
    });
  }
  
  // Gradually fade out the flash effect
  void _fadeOutFlash() {
    if (_flashOpacity <= 0) {
      _flashColor = null;
      notifyListeners();
      return;
    }
    
    _flashOpacity -= 0.1; // Faster fade-out
    notifyListeners();
    
    Future.delayed(const Duration(milliseconds: 20), () {
      _fadeOutFlash();
    });
  }
}