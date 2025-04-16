// Copyright (c) 2022, Klang.C. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum LocalCaptchaValidation {
  /// The code is valid without any issue.
  valid,

  /// Code is invalid due to: code mismatch or case mismatch.
  invalidCode,

  /// Code is already expired.
  codeExpired,
}

/// A controller for [LocalCaptcha].
///
/// Remember to [dispose] of the [LocalCaptchaController] when it is no longer needed.
class LocalCaptchaController {
  final onRefresh = ValueNotifier<DateTime>(DateTime.now());

  LocalCaptchaValidation Function(String code)? _validationFn;

  /// Refresh captcha.
  void refresh() {
    onRefresh.value = DateTime.now();
  }

  /// Validate code. The validation conditions are based on [LocalCaptcha.caseSensitive] and [LocalCaptcha.codeExpireAfter].
  LocalCaptchaValidation validate(String code) {
    return _validationFn!.call(code);
  }

  /// This function is for [LocalCaptcha] to assign closure for code validation.
  void setOnValidateFn(LocalCaptchaValidation Function(String code) fn) {
    _validationFn = fn;
  }

  void dispose() {
    onRefresh.dispose();
  }
}

/// This is a fake captcha widget that helps speed up the development of prototype/demo app.
///
/// This captcha widget is designed to work locally, with minimum setup, and with basic functions like a real captcha.
///
/// This is NOT a real anti-bot solution and is NOT recommended to use in production app.
class LocalCaptcha extends StatefulWidget {
  /// The controller for [LocalCaptcha].
  final LocalCaptchaController controller;

  /// Characters to show in captcha.
  final String chars;

  /// Length of characters to show in captcha.
  final int length;

  /// Height of captcha widget, cannot greater than width.
  final double height;

  /// Width of captcha widget, cannot less than height.
  final double width;

  /// Font size of captcha.
  final double? fontSize;

  /// Background color of captcha widget.
  final Color backgroundColor;

  /// List of colors to use on captcha text layer.
  final List<Color>? textColors;

  /// List of colors to use on captcha noise layer.
  final List<Color>? noiseColors;

  /// Condition for code validation.
  final bool caseSensitive;

  /// Condition for code validation.
  final Duration codeExpireAfter;

  /// Value of captcha when it's generated.
  final Function(String)? onCaptchaGenerated;

  const LocalCaptcha({
    super.key,
    required this.controller,
    this.chars = 'abdefghnryABDEFGHNQRY3468',
    this.length = 5,
    required this.height,
    required this.width,
    this.fontSize,
    this.backgroundColor = Colors.white,
    this.textColors,
    this.noiseColors,
    this.caseSensitive = false,
    this.codeExpireAfter = const Duration(minutes: 10),
    this.onCaptchaGenerated,
  })  : assert(length > 0),
        assert(height <= width);

  @override
  State<LocalCaptcha> createState() => _LocalCaptchaState();
}

class _LocalCaptchaState extends State<LocalCaptcha> {
  final _defaultColors = [
    Colors.black54,
    Colors.grey,
    Colors.blueGrey,
    Colors.redAccent,
    Colors.teal,
    Colors.amber,
    Colors.brown,
  ];

  var _lastRefreshAt = DateTime.fromMillisecondsSinceEpoch(0);
  var _randomText = '';

  void _generateRandomText() {
    final random = Random();
    final charList = widget.chars.runes.toList(growable: false);

    _randomText = '';

    for (var i = 0; i < widget.length; i++) {
      final index = random.nextInt(charList.length);

      _randomText += String.fromCharCode(charList[index]);
    }

    widget.onCaptchaGenerated?.call(_randomText);
  }

  @override
  void initState() {
    super.initState();

    widget.controller.setOnValidateFn((code) {
      if (DateTime.now()
          .subtract(widget.codeExpireAfter)
          .isAfter(_lastRefreshAt)) {
        return LocalCaptchaValidation.codeExpired;
      }

      if (widget.caseSensitive) {
        if (code == _randomText) {
          return LocalCaptchaValidation.valid;
        }
      } else {
        if (code.toLowerCase() == _randomText.toLowerCase()) {
          return LocalCaptchaValidation.valid;
        }
      }

      return LocalCaptchaValidation.invalidCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: widget.controller.onRefresh,
      builder: (context, value, child) {
        if (value != _lastRefreshAt) {
          _lastRefreshAt = value;
          _generateRandomText();
        }

        return Container(
          height: widget.height,
          width: widget.width,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
          ),
          child: _CacheableCaptchaLayers(
            key: ValueKey(_randomText),
            text: _randomText,
            height: widget.height,
            width: widget.width,
            backgroundColor: widget.backgroundColor,
            textColors: widget.textColors ?? _defaultColors,
            noiseColors: widget.noiseColors ?? _defaultColors,
            fontSize: widget.fontSize,
          ),
        );
      },
    );
  }
}

class _CacheableCaptchaLayers extends StatefulWidget {
  final String text;
  final double height;
  final double width;
  final Color backgroundColor;
  final List<Color> textColors;
  final List<Color> noiseColors;
  final double? fontSize;

  const _CacheableCaptchaLayers({
    super.key,
    required this.text,
    required this.height,
    required this.width,
    required this.backgroundColor,
    required this.textColors,
    required this.noiseColors,
    this.fontSize,
  });

  @override
  State<_CacheableCaptchaLayers> createState() =>
      _CacheableCaptchaLayersState();
}

class _CacheableCaptchaLayersState extends State<_CacheableCaptchaLayers> {
  final _captchaBoundaryGlobalKey = GlobalKey();
  final _captchaImageByteDataVN = ValueNotifier<ByteData?>(null);

  var _isCaptchaReady = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // v1.0.5: Fix toImage issue on Flutter Web.
      Future.delayed(const Duration(milliseconds: 100), () async {
        final boundary = _captchaBoundaryGlobalKey.currentContext
            ?.findRenderObject() as RenderRepaintBoundary?;

        if (boundary != null) {
          final boundaryImage = await boundary.toImage(pixelRatio: 1.0);

          _captchaImageByteDataVN.value =
              await boundaryImage.toByteData(format: ui.ImageByteFormat.png);

          if (mounted) {
            setState(() {
              _isCaptchaReady = true;
            });
          }
        } else {
          setState(() {
            _isCaptchaReady = true;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // v1.0.4: amend the way of generate captcha image to resolve screen flickering when scrolling on iOS.
    // When generating captcha layer, cover it with container for improve visual experience purpose,
    // then convert it to an in-memory image. Finally, hide the generated captcha layer, and show the
    // lightweight image instead for improve scrolling performance.
    return Column(
      key: ValueKey(widget.text),
      children: [
        Visibility(
          visible: !_isCaptchaReady,
          child: Stack(
            children: [
              RepaintBoundary(
                key: _captchaBoundaryGlobalKey,
                child: Stack(
                  children: [
                    if (!_isCaptchaReady)
                      _CaptchaTextLayer(
                        text: widget.text,
                        fontSize: widget.fontSize,
                        height: widget.height,
                        width: widget.width,
                        colors: widget.textColors,
                      ),
                    if (!_isCaptchaReady)
                      _CaptchaNoiseLayer(
                        height: widget.height,
                        width: widget.width,
                        colors: widget.noiseColors,
                      ),
                  ],
                ),
              ),
              Container(
                height: widget.height,
                width: widget.width,
                color: widget.backgroundColor,
              ),
            ],
          ),
        ),
        Visibility(
          visible: _isCaptchaReady,
          child: ValueListenableBuilder(
            valueListenable: _captchaImageByteDataVN,
            builder: (context, captchaImageByteData, child) {
              if (captchaImageByteData == null) {
                return const SizedBox.shrink();
              }

              return Image.memory(
                captchaImageByteData.buffer.asUint8List(),
                height: widget.height,
                width: widget.width,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CaptchaTextLayer extends StatelessWidget {
  final String text;
  final double? fontSize;
  final double height;
  final double width;
  final List<Color> colors;

  const _CaptchaTextLayer({
    required this.text,
    this.fontSize,
    required this.height,
    required this.width,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final textList = text.runes.toList(growable: false);

    return Container(
      height: height,
      width: width,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: textList
            .map((e) => _char(String.fromCharCode(e)))
            .toList(growable: false),
      ),
    );
  }

  Widget _char(String char) {
    final random = Random();

    final transform3dPerspective = Matrix4.identity()
      ..setEntry(3, 2, 0.01)
      ..rotateX(
          ((random.nextInt(1) + 2) * 0.1) * (random.nextInt(10) >= 5 ? 1 : -1));

    var mFontSize = 0.0;

    if (fontSize != null) {
      mFontSize = fontSize!;
    } else {
      const fontScale = 0.8;
      var autoFontSize = height * fontScale;

      final fontSizeWithTextLength = (autoFontSize * text.length);

      if (autoFontSize * text.length > width) {
        final overflow =
            (fontSizeWithTextLength - width) / fontSizeWithTextLength * 100;

        autoFontSize = height * (fontScale - (fontScale * overflow / 100));
        autoFontSize /= 0.8;
      }

      mFontSize = autoFontSize;
    }

    return Transform(
      transform: transform3dPerspective,
      alignment: FractionalOffset.center,
      child: Transform.rotate(
        angle: ((random.nextInt(25) + 5) * pi / 180) *
            (random.nextInt(10) >= 5 ? 1 : -1),
        child: Transform.translate(
          offset: Offset(
            random.nextInt(10) * (random.nextInt(10) >= 5 ? 1 : -1),
            random.nextInt(10) * (random.nextInt(10) >= 5 ? 1 : -1),
          ),
          child: Transform(
            transform: Matrix4.skewX((random.nextInt(3) + 1) * 0.1),
            child: Transform.scale(
              scale: ((random.nextInt(3) + 7) * 0.1),
              child: Text(
                char,
                style: TextStyle(
                  color: colors[random.nextInt(colors.length)],
                  fontSize: mFontSize,
                  fontWeight: (random.nextInt(10) >= 5
                      ? FontWeight.normal
                      : FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptchaNoiseLayer extends StatelessWidget {
  final double height;
  final double width;
  final List<Color> colors;

  const _CaptchaNoiseLayer({
    required this.height,
    required this.width,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CaptchaNoisePainter(
        height: height,
        width: width,
        colors: colors,
      ),
    );
  }
}

class _CaptchaNoisePainter extends CustomPainter {
  final double height;
  final double width;
  final List<Color> colors;

  const _CaptchaNoisePainter({
    required this.height,
    required this.width,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random();

    for (var i = 0; i < width; i += 7) {
      for (var j = 0; j < height; j += 7) {
        final point = Offset(
          random.nextDouble() * width,
          random.nextDouble() * height,
        );

        final paint = Paint();

        paint.color = colors[random.nextInt(colors.length)];
        paint.strokeWidth = random.nextDouble() * 2.0;

        canvas.drawPoints(ui.PointMode.points, [point], paint);
      }
    }

    final lineCount = random.nextInt(3) + 4;

    for (var i = 0; i < lineCount; i++) {
      final paint = Paint();

      paint.color = colors[random.nextInt(colors.length)];
      paint.strokeWidth = random.nextInt(1) + 1.0;

      final start = Offset(
        random.nextDouble() * width,
        random.nextDouble() * height,
      );

      final end = Offset(
        random.nextDouble() * width,
        random.nextDouble() * height,
      );

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CaptchaNoisePainter oldDelegate) => false;
}
