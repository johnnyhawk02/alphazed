import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';

class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({super.key});

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = Provider.of<ThemeProvider>(context, listen: false).backgroundColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a Background Color'),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: _selectedColor,
          onColorChanged: (color) {
            setState(() {
              _selectedColor = color;
            });
          },
          enableAlpha: false,
          displayThumbColor: true,
          labelTypes: const [],
          pickerAreaHeightPercent: 0.8,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
            themeProvider.setBackgroundColor(_selectedColor);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}