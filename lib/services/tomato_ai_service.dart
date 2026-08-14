import 'dart:io';
import 'package:flutter_litert/flutter_litert.dart';
import 'package:image/image.dart' as img;

class TomatoAiService {
  static const String modelPath = 'assets/models/tomato_classifier.tflite';

  static const List<String> labels = ['Damaged', 'Old', 'Ripe', 'Unripe'];

  Interpreter? _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(modelPath);

    print('✅ Tomato AI model loaded successfully');
    print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
    print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
  }

  Future<Map<String, dynamic>> predict(String imagePath) async {
    if (_interpreter == null) {
      throw Exception('AI model is not loaded');
    }

    final bytes = await File(imagePath).readAsBytes();

    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Unable to read image');
    }

    // Resize to MobileNetV2 input size
    final resized = img.copyResize(image, width: 224, height: 224);

    // MobileNetV2 preprocessing:
    // pixel 0-255 -> -1 to +1
    final input = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(224, (x) {
          final pixel = resized.getPixel(x, y);

          return [
            (pixel.r.toDouble() / 127.5) - 1.0,
            (pixel.g.toDouble() / 127.5) - 1.0,
            (pixel.b.toDouble() / 127.5) - 1.0,
          ];
        }),
      ),
    );

    final output = [
      [0.0, 0.0, 0.0, 0.0],
    ];

    _interpreter!.run(input, output);

    final probabilities = output[0];

    int bestIndex = 0;

    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > probabilities[bestIndex]) {
        bestIndex = i;
      }
    }

    final confidence = probabilities[bestIndex] * 100;

    print('==============================');
    print('🍅 AI Prediction');
    print('Class: ${labels[bestIndex]}');
    print('Confidence: ${confidence.toStringAsFixed(2)}%');
    print('Damaged: ${(probabilities[0] * 100).toStringAsFixed(2)}%');
    print('Old: ${(probabilities[1] * 100).toStringAsFixed(2)}%');
    print('Ripe: ${(probabilities[2] * 100).toStringAsFixed(2)}%');
    print('Unripe: ${(probabilities[3] * 100).toStringAsFixed(2)}%');
    print('==============================');

    return {
      'class': labels[bestIndex],
      'confidence': confidence,
      'probabilities': probabilities,
    };
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}
