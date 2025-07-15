import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_color_pick/widgets/eye_dropper_page.dart';

class WebColorPick extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const WebColorPick({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<WebColorPick> createState() => _WebColorPickState();
}

class _WebColorPickState extends State<WebColorPick> {
  late HSVColor _currentHsvColor;
  late final TextEditingController _hexController;
  late final Map<String, TextEditingController> _rgbaControllers;

  @override
  void initState() {
    super.initState();
    _currentHsvColor = HSVColor.fromColor(widget.initialColor);
    final color = _currentHsvColor.toColor();
    _hexController = TextEditingController(
      text: _colorToHex(color, withHash: false),
    );
    _rgbaControllers = {
      'R': TextEditingController(text: color.red.toString()),
      'G': TextEditingController(text: color.green.toString()),
      'B': TextEditingController(text: color.blue.toString()),
      'A': TextEditingController(
        text: (color.opacity * 100).round().toString(),
      ),
    };
  }

  @override
  void dispose() {
    _hexController.dispose();
    _rgbaControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _updateColor(HSVColor newColor) {
    setState(() {
      _currentHsvColor = newColor;
    });

    _updateAllControllers(_currentHsvColor);
    widget.onColorChanged(_currentHsvColor.toColor());
  }

  void _updateAllControllers(HSVColor hsvColor) {
    final color = hsvColor.toColor();
    _hexController.text = _colorToHex(color, withHash: false);
    _rgbaControllers['R']!.text = color.red.toString();
    _rgbaControllers['G']!.text = color.green.toString();
    _rgbaControllers['B']!.text = color.blue.toString();
    _rgbaControllers['A']!.text = (hsvColor.alpha * 100).round().toString();
  }

  String _colorToHex(Color color, {bool withHash = true}) {
    String hex = color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    hex = hex.substring(2); // Remove Alpha from a 6-digit hex
    return withHash ? '#$hex' : hex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTopBar(),
          const SizedBox(height: 12),
          SizedBox(height: 200, width: double.infinity, child: _buildSvBox()),
          const SizedBox(height: 16),
          SizedBox(
            height: 18,
            width: double.infinity,
            child: _buildHueSlider(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 18,
            width: double.infinity,
            child: _buildAlphaSlider(),
          ),
          const SizedBox(height: 16),
          _buildValueInputFields(),
          const SizedBox(height: 16),
          _buildPredefinedSwatches(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.colorize),
          tooltip: 'Pick color from screen (Not Implemented)',
          onPressed: _startEyedropper,
        ),
        const Spacer(),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(color: _currentHsvColor.toColor()),
        ),
      ],
    );
  }

  void _startEyedropper() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => EyedropperOverlay(
        onColorPicked: (color) {
          _updateColor(HSVColor.fromColor(color));
          widget.onColorChanged.call(color);
        },
      ),
    );
  }

  Widget _buildSvBox() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = Size(constraints.maxWidth, 200);
        final indicatorPosition = Offset(
          _currentHsvColor.saturation * boxSize.width,
          (1.0 - _currentHsvColor.value) * boxSize.height,
        );

        return GestureDetector(
          onPanUpdate: (details) => _updateSv(details.localPosition, boxSize),
          onPanStart: (details) => _updateSv(details.localPosition, boxSize),
          onTapDown: (details) => _updateSv(details.localPosition, boxSize),
          child: Stack(
            children: [
              Container(
                width: boxSize.width,
                height: boxSize.height,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      HSVColor.fromAHSV(
                        1.0,
                        _currentHsvColor.hue,
                        1.0,
                        1.0,
                      ).toColor(),
                    ],
                  ),
                ),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: indicatorPosition.dx - 10,
                top: indicatorPosition.dy - 10,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateSv(Offset localPosition, Size boxSize) {
    final sat = (localPosition.dx).clamp(0.0, boxSize.width) / boxSize.width;
    final val =
        1.0 - (localPosition.dy).clamp(0.0, boxSize.height) / boxSize.height;
    _updateColor(_currentHsvColor.withSaturation(sat).withValue(val));
  }

  Widget _buildSliderBase({
    required Gradient gradient,
    required Widget child,
    required void Function(double, double) onUpdate,
    required double handlePosition,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sliderWidth = constraints.maxWidth;
        final position = (handlePosition * sliderWidth).clamp(0.0, sliderWidth);
        return GestureDetector(
          onPanUpdate: (d) => onUpdate(d.localPosition.dx, sliderWidth),
          onPanStart: (d) => onUpdate(d.localPosition.dx, sliderWidth),
          onTapDown: (d) => onUpdate(d.localPosition.dx, sliderWidth),
          child: Container(
            height: 12,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(6)),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                child,
                Positioned(
                  left: position - 8,
                  top: -6,
                  child: Container(
                    width: 16,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHueSlider() {
    return _buildSliderBase(
      handlePosition: (_currentHsvColor.hue / 360.0),
      onUpdate: (position, sliderWidth) {
        _updateColor(
          _currentHsvColor.withHue(
            (position.clamp(0.0, sliderWidth) / sliderWidth) * 360.0,
          ),
        );
      },
      gradient: const LinearGradient(
        colors: [
          Color(0xFFFF0000),
          Color(0xFFFFFF00),
          Color(0xFF00FF00),
          Color(0xFF00FFFF),
          Color(0xFF0000FF),
          Color(0xFFFF00FF),
          Color(0xFFFF0000),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF0000),
              Color(0xFFFFFF00),
              Color(0xFF00FF00),
              Color(0xFF00FFFF),
              Color(0xFF0000FF),
              Color(0xFFFF00FF),
              Color(0xFFFF0000),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlphaSlider() {
    final color = _currentHsvColor.toColor();
    return _buildSliderBase(
      handlePosition: _currentHsvColor.alpha,
      onUpdate: (position, sliderWidth) {
        _updateColor(
          _currentHsvColor.withAlpha(
            (position.clamp(0.0, sliderWidth) / sliderWidth),
          ),
        );
      },
      child: const CustomPaint(
        painter: _CheckerboardPainter(),
        child: SizedBox.expand(),
      ),
      gradient: LinearGradient(
        colors: [color.withOpacity(0.0), color.withOpacity(1.0)],
      ),
    );
  }

  Widget _buildValueInputFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTextField('R', _rgbaControllers['R']!, (value) {
          final c = _currentHsvColor.toColor();
          _updateColor(
            HSVColor.fromColor(Color.fromARGB(c.alpha, value, c.green, c.blue)),
          );
        }, max: 255),
        _buildTextField('G', _rgbaControllers['G']!, (value) {
          final c = _currentHsvColor.toColor();
          _updateColor(
            HSVColor.fromColor(Color.fromARGB(c.alpha, c.red, value, c.blue)),
          );
        }, max: 255),
        _buildTextField('B', _rgbaControllers['B']!, (value) {
          final c = _currentHsvColor.toColor();
          _updateColor(
            HSVColor.fromColor(Color.fromARGB(c.alpha, c.red, c.green, value)),
          );
        }, max: 255),
        _buildTextField('A%', _rgbaControllers['A']!, (value) {
          _updateColor(_currentHsvColor.withAlpha(value / 100.0));
        }, max: 100),
        _buildHexField('Hex', _hexController, (value) {
          if (value.length != 6) return;
          final hexWithHash = '#$value';
          final colorInt = int.tryParse(hexWithHash.substring(1), radix: 16);
          if (colorInt != null) {
            final newHsv = HSVColor.fromColor(
              Color(colorInt | 0xFF000000),
            ).withAlpha(_currentHsvColor.alpha);
            _updateColor(newHsv);
          }
        }),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    Function(int) onChanged, {
    int max = 255,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          children: [
            TextField(
              onTap: () {
                controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: controller.text.length,
                );
              },
              controller: controller,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                border: outlineInputBorder(),
                enabledBorder: outlineInputBorder(),
                focusedBorder: outlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final n = int.tryParse(newValue.text);
                  if (n != null && n > max) return oldValue;
                  return newValue;
                }),
              ],
              onChanged: (v) {
                if (v.isNotEmpty) onChanged(int.parse(v));
              },
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder outlineInputBorder() {
    return OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade300),
    );
  }

  Widget _buildHexField(
    String label,
    TextEditingController controller,
    Function(String) onChanged,
  ) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          children: [
            TextField(
              onTap: () {
                controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: controller.text.length,
                );
              },
              controller: controller,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                border: outlineInputBorder(),
                focusedBorder: outlineInputBorder(),
                enabledBorder: outlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: onChanged,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredefinedSwatches() {
    final List<Color> swatches = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
    ];
    return SizedBox(
      height: 40,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: swatches.length,
        itemBuilder: (context, index) {
          final swatchColor = swatches[index];
          return GestureDetector(
            onTap: () {
              _updateColor(
                HSVColor.fromColor(
                  swatchColor,
                ).withAlpha(_currentHsvColor.alpha),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: swatchColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  final double squareSize;

  const _CheckerboardPainter({this.squareSize = 10});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = const Color(0xffcdd2d7);
    final paint2 = Paint()..color = Colors.white;

    for (var i = 0; i * squareSize < size.width; i++) {
      for (var j = 0; j * squareSize < size.height; j++) {
        final paint = (i + j) % 2 == 0 ? paint2 : paint1;
        canvas.drawRect(
          Rect.fromLTWH(i * squareSize, j * squareSize, squareSize, squareSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
