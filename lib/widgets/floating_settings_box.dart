import 'dart:math';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FloatingSettingsBox extends StatefulWidget {
  const FloatingSettingsBox({
    super.key,
    required this.onCloseSettings
  });

  final VoidCallback onCloseSettings;

  @override
  State<FloatingSettingsBox> createState() => _FloatingSettingsBoxState();
}

enum TextInputTypeCustom {email, password, code, text}

class _FloatingSettingsBoxState extends State<FloatingSettingsBox> {

  final _formKey = GlobalKey<FormState>();
  final FocusScopeNode _settingsFocusScope = FocusScopeNode();
  final FocusNode _settingsMenuFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _codeFocusNode = FocusNode();
  final FocusNode _submitFocusNode = FocusNode();
  final FocusNode _cancelFocusNode = FocusNode();

  bool disabled = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _settingsFocusScope.requestFocus(_emailFocusNode);
    });
  }

  Widget _buildTextInput({
    required String text,
    required String hintText,
    required TextInputTypeCustom type,
    required FocusNode focusNode,
    bool obscureText = false,
    String obscureCharacter = '*',
    String validatorRegex = '',
    String errorMessage = '',
  }) {

    TextInputType inputType = TextInputType.text;

    switch (type) {
      case TextInputTypeCustom.text:
        inputType = TextInputType.text;
        break;
      case TextInputTypeCustom.email:
        inputType = TextInputType.emailAddress;
        break;
      case TextInputTypeCustom.code:
        inputType = TextInputType.number;
        break;
      case TextInputTypeCustom.password:
        inputType = TextInputType.text;
        break;
      default:
        inputType = TextInputType.text;
    }

    RegExp regExp = RegExp(validatorRegex);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(fontSize: 15.0),
        ),
        SizedBox(
          child: TextFormField(
            focusNode: focusNode,
            readOnly: !_isEditing,
            keyboardType: inputType,
            textInputAction: TextInputAction.done,
            onTap: () => _beginEditing(focusNode),
            onEditingComplete: () => _finishEditing(focusNode),
            obscureText: obscureText,
            obscuringCharacter: obscureCharacter,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey),
              fillColor: Colors.transparent,
              border: OutlineInputBorder(),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue, width: 3),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }
              if (type == TextInputTypeCustom.email) {
                if(EmailValidator.validate(value) == false) {
                  return 'Email unvalid. Please provide a valid email';
                }
              }
              if (validatorRegex.isNotEmpty && regExp.firstMatch(value) == null) {
                return 'Not allowed. Please provide a valid response.';
              }
              return null;
            },
          ),
        ),
        Padding(padding: const EdgeInsets.only(top: 15.0))
      ]
    );

  }

  void _beginEditing(FocusNode focusNode) {
    if (_isEditing || disabled) return;

    focusNode.unfocus();
    setState(() {
      _isEditing = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) focusNode.requestFocus();
    });
  }

  void _finishEditing(FocusNode focusNode) {
    if (!_isEditing) return;

    setState(() {
      _isEditing = false;
    });
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                offset: Offset.fromDirection(1, 2),
                spreadRadius: 1,
                blurRadius: 3,
                color: Colors.grey)
          ],
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          border: Border.all(
              color: Colors.orange,
              width: 2,
              style: BorderStyle.solid)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: IntrinsicWidth(
          child: FocusScope(
            node: _settingsFocusScope,
            child: Focus(
              focusNode: _settingsMenuFocusNode,
              autofocus: true,
              onKeyEvent: (node, event) {
                final isBackKey =
                    event.logicalKey == LogicalKeyboardKey.escape ||
                    event.logicalKey == LogicalKeyboardKey.goBack ||
                    event.logicalKey == LogicalKeyboardKey.browserBack;
                if (isBackKey && event is KeyDownEvent) {
                  if (_isEditing) {
                    _finishEditing(_emailFocusNode.hasFocus
                        ? _emailFocusNode
                        : _passwordFocusNode.hasFocus
                        ? _passwordFocusNode
                        : _codeFocusNode);
                  } else {
                    _settingsMenuFocusNode.requestFocus();
                  }
                  return KeyEventResult.handled;
                }

                if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                  return KeyEventResult.ignored;
                }

                final focusNodes = [
                  _emailFocusNode,
                  _passwordFocusNode,
                  _codeFocusNode,
                  _submitFocusNode,
                  _cancelFocusNode,
                ];
                final currentIndex =
                    focusNodes.indexWhere((focusNode) => focusNode.hasFocus);

                if (currentIndex >= 3 &&
                    (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                        event.logicalKey == LogicalKeyboardKey.arrowRight)) {
                  if (currentIndex == 3 &&
                      event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    _cancelFocusNode.requestFocus();
                  } else if (currentIndex == 4 &&
                      event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    _submitFocusNode.requestFocus();
                  }
                  return KeyEventResult.handled;
                }

                if (currentIndex >= 3 &&
                    event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  _codeFocusNode.requestFocus();
                  return KeyEventResult.handled;
                }

                if (!_isEditing &&
                    (event.logicalKey == LogicalKeyboardKey.select ||
                        event.logicalKey == LogicalKeyboardKey.enter ||
                        event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
                    currentIndex >= 0 &&
                    currentIndex < 3) {
                  _beginEditing(focusNodes[currentIndex]);
                  return KeyEventResult.handled;
                }

                final direction = switch (event.logicalKey) {
                  LogicalKeyboardKey.arrowUp => -1,
                  LogicalKeyboardKey.arrowDown => 1,
                  _ => 0,
                };
                if (direction == 0) return KeyEventResult.ignored;

                final nextIndex = currentIndex == -1
                    ? (direction < 0 ? 0 : 2)
                    : currentIndex + direction;
                if (nextIndex < 0 || nextIndex >= focusNodes.length) {
                  return KeyEventResult.handled;
                }
                if (_isEditing) {
                  setState(() {
                    _isEditing = false;
                  });
                }
                focusNodes[nextIndex].requestFocus();
                return KeyEventResult.handled;
              },
              child: Form(
                key: _formKey,
                child: ListView(
                children: [
                  Text(
                    'Connect screen',
                    style: TextStyle(fontSize: 25.0, fontWeight: FontWeight(1000)),
                  ),
                  _buildTextInput(
                    text: 'Email',
                    hintText: 'example@email.com',
                    type: TextInputTypeCustom.email,
                    focusNode: _emailFocusNode,
                  ),
                  _buildTextInput(
                    text: 'Password',
                    hintText: '*********',
                    type: TextInputTypeCustom.password,
                    focusNode: _passwordFocusNode,
                    obscureText: true,
                    obscureCharacter: '*',
                  ),
                  _buildTextInput(
                    text: 'Code',
                    hintText: '123123123123',
                    type: TextInputTypeCustom.code,
                    focusNode: _codeFocusNode,
                    validatorRegex: r'^[0-9]{12}$'
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            focusNode: _submitFocusNode,
                            onPressed: disabled ? null : () async {
                              // Validate returns true if the form is valid, or false otherwise.
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  disabled = true;
                                });
                                // If the form is valid, display a snackbar. In the real world,
                                // you'd often call a server or save the information in a database.
                                final messenger = ScaffoldMessenger.of(context);
                                await messenger
                                    .showSnackBar(
                                      SnackBar(
                                        content: const Text('Connecting...'),
                                        duration: Duration(
                                          seconds: Random().nextInt(10) + 5,
                                        ),
                                      ),
                                    )
                                    .closed;
                                if (!mounted) return;
                                if(Random().nextInt(2) == 0) {
                                  widget.onCloseSettings();
                                  await messenger
                                      .showSnackBar(
                                        const SnackBar(
                                          content: Text('Connected!'),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 3),
                                        ),
                                      )
                                      .closed;
                                  if (!mounted) return;

                                  setState(() {
                                    disabled = false;
                                  });
                                } else {
                                  await messenger
                                      .showSnackBar(
                                        const SnackBar(
                                          content: Text("Couldn't connect"),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 3),
                                        ),
                                      )
                                      .closed;
                                  if (!mounted) return;

                                  setState(() {
                                    disabled = false;
                                  });
                                }
                              }
                            },
                            child: const Text('Submit'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            focusNode: _cancelFocusNode,
                            onPressed: widget.onCloseSettings,
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _settingsFocusScope.dispose();
    _settingsMenuFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _codeFocusNode.dispose();
    _submitFocusNode.dispose();
    _cancelFocusNode.dispose();
    super.dispose();
  }
}