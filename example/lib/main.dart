import 'package:flutter/material.dart';
import 'package:local_captcha/local_captcha.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Captcha Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _captchaFormKey = GlobalKey<FormState>();
  final _configFormKey = GlobalKey<FormState>();
  final _localCaptchaController = LocalCaptchaController();
  final _configFormData = ConfigFormData();

  var _inputCode = '';

  @override
  void dispose() {
    _localCaptchaController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Captcha Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SizedBox(
            width: 300.0,
            child: Form(
              key: _captchaFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LocalCaptcha(
                    key: ValueKey(_configFormData.toString()),
                    controller: _localCaptchaController,
                    height: 150,
                    width: 300,
                    backgroundColor: Colors.grey[100]!,
                    chars: _configFormData.chars,
                    length: _configFormData.length,
                    fontSize: _configFormData.fontSize > 0 ? _configFormData.fontSize : null,
                    caseSensitive: _configFormData.caseSensitive,
                    codeExpireAfter: _configFormData.codeExpireAfter,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Enter code',
                      hintText: 'Enter code',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final validation = _localCaptchaController.validate(value);

                        switch (validation) {
                          case LocalCaptchaValidation.invalidCode:
                            return '* Invalid code.';
                          case LocalCaptchaValidation.codeExpired:
                            return '* Code expired.';
                          case LocalCaptchaValidation.valid:
                          default:
                            return null;
                        }
                      }

                      return '* Required field.';
                    },
                    onSaved: (value) => _inputCode = value ?? '',
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    height: 40.0,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_captchaFormKey.currentState?.validate() ?? false) {
                          _captchaFormKey.currentState!.save();

                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Code: "$_inputCode" is valid.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                      child: const Text('Validate Code'),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    height: 40.0,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _localCaptchaController.refresh(),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blueGrey,
                      ),
                      child: const Text('Refresh'),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(),
                  ),
                  _configForm(context),
                ],
              ),
            ),
          ),
        ),
      ),
      // body: LocalCaptcha(),
    );
  }

  Widget _configForm(BuildContext context) {
    return Form(
      key: _configFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Basic Configs',
              style: Theme.of(context).textTheme.titleLarge!,
            ),
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            initialValue: _configFormData.chars,
            decoration: const InputDecoration(
              labelText: 'Captcha chars',
              hintText: 'Captcha chars',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                return null;
              }

              return '* Required field.';
            },
            onSaved: (value) => _configFormData.chars = value?.trim() ?? '',
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            initialValue: '${_configFormData.length}',
            decoration: const InputDecoration(
              labelText: 'Captcha length',
              hintText: 'Captcha length',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final length = int.tryParse(value) ?? 0;

                if (length < 1) {
                  return '* Length must be greater than 0.';
                }

                return null;
              }

              return '* Required field.';
            },
            onSaved: (value) => _configFormData.length = int.tryParse(value ?? '1') ?? 1,
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            initialValue: '${_configFormData.fontSize > 0 ? _configFormData.fontSize : ''}',
            decoration: const InputDecoration(
              labelText: 'Font size (optional)',
              hintText: 'Font size (optional)',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onSaved: (value) => _configFormData.fontSize = double.tryParse(value ?? '0.0') ?? 0.0,
          ),
          const SizedBox(height: 16.0),
          DropdownButtonFormField<bool>(
            value: _configFormData.caseSensitive,
            isDense: true,
            decoration: const InputDecoration(
              labelText: 'Case sensitive',
              hintText: 'Case sensitive',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: false,
                child: Text('No'),
              ),
              DropdownMenuItem(
                value: true,
                child: Text('Yes'),
              ),
            ],
            onChanged: (value) => _configFormData.caseSensitive = value ?? false,
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            initialValue: '${_configFormData.codeExpireAfter.inMinutes}',
            decoration: const InputDecoration(
              labelText: 'Code expire after (minutes)',
              hintText: 'Code expire after (minutes)',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final length = int.tryParse(value) ?? 0;

                if (length < 1) {
                  return '* Minute must be greater than 0.';
                }

                return null;
              }

              return '* Required field.';
            },
            onSaved: (value) => _configFormData.codeExpireAfter = Duration(minutes: int.tryParse(value ?? '1') ?? 1),
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            height: 40.0,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_configFormKey.currentState?.validate() ?? false) {
                  _configFormKey.currentState!.save();

                  setState(() {});
                }
              },
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfigFormData {
  String chars = 'abdefghnryABDEFGHNQRY3468';
  int length = 5;
  double fontSize = 0;
  bool caseSensitive = false;
  Duration codeExpireAfter = const Duration(minutes: 10);

  @override
  String toString() {
    return '$chars$length$caseSensitive${codeExpireAfter.inMinutes}';
  }
}
