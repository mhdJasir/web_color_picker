import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:web_color_pick/utils/js_interop.dart';

class EyedropperOverlay extends StatefulWidget {
  final ValueChanged<Color> onColorPicked;

  const EyedropperOverlay({super.key, required this.onColorPicked});

  @override
  State<EyedropperOverlay> createState() => _EyedropperOverlayState();
}

class _EyedropperOverlayState extends State<EyedropperOverlay> {
  img.Image? _image;

  @override
  void initState() {
    super.initState();
    _capture();
  }

  Future<void> _capture() async {
    final dataUrl = await captureFlutterApp();
    if (!dataUrl.startsWith('data:image')) return;
    final base64Data = dataUrl.split(',').last;
    final bytes = base64Decode(base64Data);
    final decoded = img.decodeImage(bytes);
    if (decoded != null) {
      setState(() {
        _image = decoded;
      });
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (_image == null) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final local = details.localPosition;
    final dx = (local.dx * _image!.width / box.size.width).round();
    final dy = (local.dy * _image!.height / box.size.height).round();

    if (dx >= 0 && dx < _image!.width && dy >= 0 && dy < _image!.height) {
      final pixel = _image!.getPixelSafe(dx, dy);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      final a = pixel.a.toInt();
      final color = Color.fromARGB(a, r, g, b);
      widget.onColorPicked(color);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _image == null
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: _onTapDown,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Image.memory(
                  Uint8List.fromList(img.encodePng(_image!)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
    );
  }
}
