import 'package:flutter/material.dart';
import 'package:web_color_pick/web_color_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Picker Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ColorPickerExample(),
    );
  }
}

class ColorPickerExample extends StatefulWidget {
  const ColorPickerExample({super.key});
  @override
  State<ColorPickerExample> createState() => _ColorPickerExampleState();
}

class _ColorPickerExampleState extends State<ColorPickerExample> {
  Color _pickedColor = Colors.teal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Color Picker Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            WebColorPick(
              initialColor: _pickedColor,
              onColorChanged: (color) {
                setState(() {
                  _pickedColor = color;
                });
              },
            ),
            const SizedBox(height: 24),
            Text('Selected Color:',
                style: Theme.of(context).textTheme.titleMedium),
            Container(
              width: 100,
              height: 50,
              margin: const EdgeInsets.only(top: 8),
              color: _pickedColor,
            ),
          ],
        ),
      ),
    );
  }
}
