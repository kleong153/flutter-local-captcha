# Flutter Local Captcha

This is a fake captcha widget that helps speed up the development of prototype/demo app.

This captcha widget is designed to work locally, with minimum setup, and with basic functions like a real captcha.

This is NOT a real anti-bot solution and is NOT recommended to use in production app.

## Features
- Light weight, pure dart.
- Easy to use. Highly customizable.

## Live Preview
[Website Demo](https://kcflutterlocalcaptcha.surge.sh)

## Installation

```yaml
dependencies:
  local_captcha: ^1.0.1
```

## Import

```dart
import 'package:local_captcha/local_captcha.dart';
```

## Usage

The controller

```dart
// Init controller.
final _localCaptchaController = LocalCaptchaController();

// Validate captcha code.
_localCaptchaController.validate(value);

// Refresh captcha code.
_localCaptchaController.refresh();

// Remember to dispose controller when you no longer need it.
@override
void dispose() {
  _localCaptchaController.dispose();

  super.dispose();
}
```

The widget

```dart
LocalCaptcha(
  key: ValueKey('to tell widget should update'),
  controller: _localCaptchaController,
  height: 150,
  width: 300,
  backgroundColor: Colors.grey[100]!,
  chars: 'abdefghnryABDEFGHNQRY3468',
  length: 5,
  fontSize: 80.0,
  textColors: [
    Colors.black54,
    Colors.grey,
    Colors.blueGrey,
    Colors.redAccent,
    Colors.teal,
    Colors.amber,
    Colors.brown,
  ],
  noiseColors: [
    Colors.black54,
    Colors.grey,
    Colors.blueGrey,
    Colors.redAccent,
    Colors.teal,
    Colors.amber,
    Colors.brown,
  ],
  caseSensitive: false,
  codeExpireAfter: Duration(minutes: 10),
);
```

## Example

See the complete example at GitHub repo, **./example/main.dart** file.
