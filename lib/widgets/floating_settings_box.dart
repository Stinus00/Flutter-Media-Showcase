import 'dart:async';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_test/classes/system_data_login_file.dart';

class FloatingSettingsBox extends StatefulWidget {
  const FloatingSettingsBox({
    super.key,
    required this.onCloseSettings,
    required this.onConnected,
    required this.onDisconnected,
    required this.tryConnect,
  });

  final VoidCallback onCloseSettings;
  final Future<void> Function(
    void Function(String phase, int completed, int total) onProgress,
  ) onConnected;
  final Future<void> Function() onDisconnected;
  final Future<bool> Function(String systemId) tryConnect;

  @override
  State<FloatingSettingsBox> createState() => _FloatingSettingsBoxState();
}

enum TextInputTypeCustom {email, password, code, text, none}

class _FloatingSettingsBoxState extends State<FloatingSettingsBox> {

  final _formKey = GlobalKey<FormState>();
  final FocusScopeNode _settingsFocusScope = FocusScopeNode();
  final FocusNode _settingsMenuFocusNode = FocusNode();
  //unused
  final FocusNode _emailFocusNode = FocusNode();
  //unused
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _systemIdFocusNode = FocusNode();
  final FocusNode _mccId1FocusNode = FocusNode();
  final FocusNode _mccId2FocusNode = FocusNode();
  final FocusNode _submitFocusNode = FocusNode();
  final FocusNode _disconnectFocusNode = FocusNode();
  final FocusNode _cancelFocusNode = FocusNode();

  final _systemIdController = TextEditingController();
  final _mccId1Controller = TextEditingController();
  final _mccId2Controller = TextEditingController();
  final ValueNotifier<String> _downloadProgress = ValueNotifier('Starting Download...');

  final SystemDataLoginFile _file = SystemDataLoginFile();

  bool _isEditing = false;
  bool _isConnecting = false;
  bool _startReadOnly = false;
  bool _disableCancel = false;
  String? _connectionError;

  final _borderColor = Color.fromARGB(255, 57, 68, 92);
  final _focusColor = Color.fromARGB(255, 255, 106, 0);
  final _buttonIdleColor = Color.fromARGB(255, 255, 106, 0);
  final _disabledButtonIdleColor = Color.fromARGB(255, 152, 149, 149);
  final _buttonFocusColor = Color.fromARGB(255, 255, 135, 50);
  final _backgroundColor = Color.fromARGB(255, 20, 31, 56);
  final _backgroundTextColor = Color.fromARGB(255, 5, 8, 15);
  final _textColor = Color.fromARGB(255, 255, 250, 250);
  final _disabledTextColor = Color.fromARGB(255, 152, 149, 149);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(initTextFields());
        _settingsFocusScope.requestFocus(_systemIdFocusNode);
      }
    });
  }

  Future<void> initTextFields() async {
    String systemId = '';
    String mccId1 = '';
    String mccId2 = '';
    var ids = await _file.readIds();
    if (ids != null) {
      systemId = ids.$2.split('_')[0];
      var mccIds = ids.$1.split('-');
      if(mccIds.length > 1) {
        mccId1 = mccIds[0];
        mccId2 = mccIds[1];
      }
    }

    _systemIdController.text = systemId;
    _mccId1Controller.text = mccId1;
    _mccId2Controller.text = mccId2;

    if(systemId.isNotEmpty) {
      setState(() {
        _startReadOnly = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _settingsFocusScope.requestFocus(_disconnectFocusNode);
        }
      });
    }
  }

  Widget _buildTextInput({
    required String text,
    required String hintText,
    required TextInputTypeCustom type,
    required FocusNode focusNode,
    required TextEditingController controller,
    bool capitalize = false,
    bool obscureText = false,
    String obscureCharacter = '*',
    String validatorRegex = '',
    String formaterRegex = r'.',
    int minLength = -1,
    int maxLength = -1,
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

    bool isEnabled = !_startReadOnly && !_isConnecting;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(fontSize: 15.0, color: _textColor),
        ),
        SizedBox(
          child: TextFormField(
            enabled: isEnabled,
            focusNode: focusNode,
            readOnly: _startReadOnly || !_isEditing,
            keyboardType: inputType,
            controller: controller,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(formaterRegex)),
              LengthLimitingTextInputFormatter(maxLength),
              if (capitalize) _UpperCaseTextFormatter(),
            ],
            textCapitalization:
                capitalize ? TextCapitalization.characters : TextCapitalization.none,
            textInputAction: TextInputAction.done,
            onTap: () => _beginEditing(focusNode),
            onEditingComplete: () => _finishEditing(focusNode),
            obscureText: obscureText,
            obscuringCharacter: obscureCharacter,
            style: TextStyle(
              color: isEnabled ? _textColor : _disabledTextColor,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: _backgroundTextColor,
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _focusColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _borderColor, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }
              if (type == TextInputTypeCustom.email) {
                if(EmailValidator.validate(value) == false) {
                  return 'Email invalid. Please provide a valid email';
                }
              }
              if (maxLength != -1 && value.length > maxLength) {
                return 'Not allowed. Code is too long.';
              }
              if (minLength != -1 && value.length < minLength) {
                return 'Not allowed. Code is too short.';
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
    if (_startReadOnly || _isEditing || _isConnecting) return;

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
          color: _backgroundColor,
          // boxShadow: [
          //   BoxShadow(
          //       offset: Offset.fromDirection(1, 2),
          //       spreadRadius: 1,
          //       blurRadius: 3,
          //       color: Colors.grey)
          // ],
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          border: Border.all(
              color: _borderColor,
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
                    _finishEditing(
                        // _emailFocusNode.hasFocus
                        // ? _emailFocusNode
                        // : _passwordFocusNode.hasFocus
                        // ? _passwordFocusNode
                        // : 
                        _systemIdFocusNode.hasFocus
                        ? _systemIdFocusNode
                        : _mccId1FocusNode.hasFocus
                        ? _mccId1FocusNode
                        : _mccId2FocusNode);
                  } else {
                    _settingsMenuFocusNode.requestFocus();
                  }
                  return KeyEventResult.handled;
                }

                if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                  return KeyEventResult.ignored;
                }

                List<FocusNode> focusNodes = [
                  _systemIdFocusNode,
                  _mccId1FocusNode,
                  _mccId2FocusNode,
                  _submitFocusNode,
                  _cancelFocusNode,
                ];
                if(_startReadOnly) {
                  focusNodes = [
                    _disconnectFocusNode,
                    _cancelFocusNode,
                  ];
                }
                final currentIndex =
                    focusNodes.indexWhere((focusNode) => focusNode.hasFocus);
                // Check if any of the nodes highlighted is in a row
                if (( focusNodes[currentIndex] == _submitFocusNode ||
                      focusNodes[currentIndex] == _cancelFocusNode ||
                      focusNodes[currentIndex] == _mccId1FocusNode ||
                      focusNodes[currentIndex] == _mccId2FocusNode || 
                      focusNodes[currentIndex] == _disconnectFocusNode ) && (
                        event.logicalKey == LogicalKeyboardKey.arrowUp ||
                        event.logicalKey == LogicalKeyboardKey.arrowDown ||
                        event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                        event.logicalKey == LogicalKeyboardKey.arrowRight
                      )) {
                  if (focusNodes[currentIndex] == _submitFocusNode) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                      _cancelFocusNode.requestFocus();
                    } else
                    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      if (focusNodes.contains(_mccId1FocusNode)) {
                        _mccId1FocusNode.requestFocus();
                      }
                    }
                  } else 
                  if (focusNodes[currentIndex] == _disconnectFocusNode) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                      _cancelFocusNode.requestFocus();
                    } else
                    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      if (focusNodes.contains(_mccId1FocusNode)) {
                        _mccId1FocusNode.requestFocus();
                      }
                    }
                  } else
                  if (focusNodes[currentIndex] == _cancelFocusNode) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                      if(focusNodes.contains(_submitFocusNode)) {
                        _submitFocusNode.requestFocus();
                      } else
                      if (focusNodes.contains(_disconnectFocusNode)) {
                        _disconnectFocusNode.requestFocus();
                      }
                    } else
                    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      if (focusNodes.contains(_mccId2FocusNode)) {
                        _mccId2FocusNode.requestFocus();
                      }
                    }
                  } else
                  if (focusNodes[currentIndex] == _mccId1FocusNode) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                      _mccId2FocusNode.requestFocus();
                    } else
                    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      _submitFocusNode.requestFocus();
                    } else
                    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      _systemIdFocusNode.requestFocus();
                    }
                  } else
                  if (focusNodes[currentIndex] == _mccId2FocusNode) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                      _mccId1FocusNode.requestFocus();
                    } else
                    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      _cancelFocusNode.requestFocus();
                    } else
                    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      _systemIdFocusNode.requestFocus();
                    }
                  }
                  return KeyEventResult.handled;
                }

                if (!_isEditing &&
                    (event.logicalKey == LogicalKeyboardKey.select ||
                        event.logicalKey == LogicalKeyboardKey.enter ||
                        event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
                    currentIndex >= 0 &&
                    currentIndex < focusNodes.length - 2) {
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
                  shrinkWrap: true,
                  children: [
                    Text(
                      'Connect screen',
                      style: TextStyle(fontSize: 25.0, fontWeight: FontWeight(600), color: _textColor),
                    ),
                    // if (_connectionError != null)
                    //   Container(
                    //     margin: const EdgeInsets.symmetric(vertical: 12),
                    //     padding: const EdgeInsets.all(12),
                    //     decoration: BoxDecoration(
                    //       color: Colors.red.shade50,
                    //       border: Border.all(color: Colors.red.shade300),
                    //       borderRadius: BorderRadius.circular(8),
                    //     ),
                    //     child: Row(
                    //       crossAxisAlignment: CrossAxisAlignment.start,
                    //       children: [
                    //         Icon(Icons.error_outline, color: Colors.red.shade700),
                    //         const SizedBox(width: 8),
                    //         Expanded(
                    //           child: Text(
                    //             'Could not prepare media:\n$_connectionError',
                    //             style: TextStyle(color: Colors.red.shade900),
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // _buildTextInput(
                    //   text: 'Email',
                    //   hintText: 'example@email.com',
                    //   type: TextInputTypeCustom.email,
                    //   focusNode: _emailFocusNode,
                    // ),
                    // _buildTextInput(
                    //   text: 'Password',
                    //   hintText: '*********',
                    //   type: TextInputTypeCustom.password,
                    //   focusNode: _passwordFocusNode,
                    //   obscureText: true,
                    //   obscureCharacter: '*',
                    // ),
                    _buildTextInput(
                      text: 'Systeem ID',
                      hintText: '123123123123',
                      type: TextInputTypeCustom.code,
                      controller: _systemIdController,
                      focusNode: _systemIdFocusNode,
                      validatorRegex: r'^[0-9]{12}$',
                      formaterRegex: r'[0-9]',
                      minLength: 12,
                      maxLength: 12,
                    ),
                    Row( //
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child:  _buildTextInput(
                            text: 'MCC Koppel Code',
                            hintText: 'ABC',
                            type: TextInputTypeCustom.text,
                            controller: _mccId1Controller,
                            focusNode: _mccId1FocusNode,
                            validatorRegex: r'^[A-Z]{3}$',
                            formaterRegex: r'[a-zA-Z]',
                            capitalize: true,
                            minLength: 3,
                            maxLength: 3,
                          )
                        ),
                        SizedBox(
                          height: 89,
                          child: Center(
                            child: Text('  —  ', 
                              style: TextStyle(
                                color: (!_startReadOnly && !_isConnecting) ? _textColor : _disabledTextColor
                              )
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildTextInput(
                            text: '',
                            hintText: '12345',
                            type: TextInputTypeCustom.code,
                            controller: _mccId2Controller,
                            focusNode: _mccId2FocusNode,
                            validatorRegex: r'^[0-9]{5}$',
                            formaterRegex: r'[0-9]',
                            minLength: 5,
                            maxLength: 5,
                          )
                        ),
                      ]
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          !_startReadOnly ?
                          Expanded(
                            child: ElevatedButton(
                              focusNode: _submitFocusNode,
                              onPressed: _isConnecting ? null : () async {
                                // Validate returns true if the form is valid, or false otherwise.
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    _connectionError = null;
                                    _isConnecting = true;
                                  });
                                  // If the form is valid, display a snackbar. In the real world,
                                  // you'd often call a server or save the information in a database.
                                  final messenger = ScaffoldMessenger.of(context);
                                  await messenger
                                      .showSnackBar(
                                        SnackBar(
                                          content: const Text('Connecting...'),
                                          duration: Duration(
                                            seconds: 2,
                                          ),
                                        ),
                                      ).closed;
                                  try {
                                    if (!mounted) return;
                                    if(await widget.tryConnect(_systemIdController.text) == false) {
                                      throw Exception("Couldn't connect");
                                    }

                                    setState(() {
                                      _disableCancel = true;
                                    });
                                    _downloadProgress.value = 'Downloading...';
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: ValueListenableBuilder<String>(
                                          valueListenable: _downloadProgress,
                                          builder: (context, progress, _) =>
                                              Text(progress),
                                        ),
                                        duration: const Duration(days: 1),
                                      ),
                                    );
                                    if (!mounted) return;
                                    await _file.storeIds(
                                      mccAppId: '${_mccId1Controller.text}-${_mccId2Controller.text}',
                                      systemId: _systemIdController.text,
                                    );
                                    await widget.onConnected((
                                      phase,
                                      completed,
                                      total,
                                    ) {
                                      if (mounted) {
                                        _downloadProgress.value =
                                            'Downloading $phase: $completed/$total';
                                      }
                                    });

                                    widget.onCloseSettings();

                                    messenger.hideCurrentSnackBar();

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
                                      _isConnecting = false;
                                      _disableCancel = false;
                                    });

                                  } catch (error) {
                                    messenger.hideCurrentSnackBar();
                                    await _file.storeIds(
                                      mccAppId: '',
                                      systemId: '',
                                    );

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
                                      _connectionError = error.toString();
                                      _isConnecting = false;
                                    });
                                  }
                                }
                              },
                              style: ButtonStyle(
                                foregroundColor: WidgetStatePropertyAll<Color>(_textColor),
                                backgroundColor: WidgetStateProperty<Color>.fromMap(
                                  <WidgetStatesConstraint, Color>{
                                    WidgetState.disabled: _disabledButtonIdleColor,
                                    WidgetState.focused: _buttonFocusColor,
                                    WidgetState.pressed | WidgetState.hovered: _buttonFocusColor,
                                    WidgetState.any: _buttonIdleColor,
                                  },
                                ),
                                side: WidgetStateProperty<BorderSide>.fromMap(
                                  <WidgetStatesConstraint, BorderSide>{
                                    WidgetState.disabled: BorderSide(color: _disabledButtonIdleColor),
                                    WidgetState.focused: BorderSide(color: Colors.white),
                                    WidgetState.pressed | WidgetState.hovered: BorderSide(color: Colors.white),
                                    WidgetState.any: BorderSide(color: _buttonIdleColor),
                                  },
                                ),
                              ),
                              child: const Text('Submit'),
                            ),
                          ) : Expanded(
                            child: ElevatedButton(
                              focusNode: _disconnectFocusNode,
                              style: ButtonStyle(
                                foregroundColor: WidgetStatePropertyAll<Color>(_textColor),
                                backgroundColor: WidgetStateProperty<Color>.fromMap(
                                  <WidgetStatesConstraint, Color>{
                                    WidgetState.disabled: _disabledButtonIdleColor,
                                    WidgetState.focused: Colors.red,
                                    WidgetState.pressed | WidgetState.hovered: Colors.red,
                                    WidgetState.any: Color.fromARGB(255, 255, 0, 0),
                                  },
                                ),
                                side: WidgetStateProperty<BorderSide>.fromMap(
                                  <WidgetStatesConstraint, BorderSide>{
                                    WidgetState.disabled: BorderSide(color: _disabledButtonIdleColor),
                                    WidgetState.focused: BorderSide(color: Colors.white),
                                    WidgetState.pressed | WidgetState.hovered: BorderSide(color: Colors.white),
                                    WidgetState.any: BorderSide(color: Color.fromARGB(255, 255, 0, 0)),
                                  },
                                ),
                              ),
                              onPressed: () async {
                                await widget.onDisconnected();

                                await _file.storeIds(mccAppId: '', systemId: '');
                                _systemIdController.text = '';
                                _mccId1Controller.text = '';
                                _mccId2Controller.text = '';
                                setState(() {
                                  _startReadOnly = false;
                                });
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    _disconnectFocusNode.unfocus();
                                    _settingsFocusScope.requestFocus(_submitFocusNode);
                                  }
                                });
                              }, 
                              child: const Text('Disconnect Screen')
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              focusNode: _cancelFocusNode,
                              onPressed: _disableCancel ? null : widget.onCloseSettings,
                              style: ButtonStyle(
                                foregroundColor: WidgetStatePropertyAll<Color>(_textColor),
                                backgroundColor: WidgetStateProperty<Color>.fromMap(
                                  <WidgetStatesConstraint, Color>{
                                    WidgetState.disabled: _disabledButtonIdleColor,
                                    WidgetState.focused: _buttonFocusColor,
                                    WidgetState.pressed | WidgetState.hovered: _buttonFocusColor,
                                    WidgetState.any: _buttonIdleColor,
                                  },
                                ),
                                side: WidgetStateProperty<BorderSide>.fromMap(
                                  <WidgetStatesConstraint, BorderSide>{
                                    WidgetState.disabled: BorderSide(color: _disabledButtonIdleColor),
                                    WidgetState.focused: BorderSide(color: Colors.white),
                                    WidgetState.pressed | WidgetState.hovered: BorderSide(color: Colors.white),
                                    WidgetState.any: BorderSide(color: _buttonIdleColor),
                                  },
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ),
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
    _systemIdFocusNode.dispose();
    _mccId1FocusNode.dispose();
    _mccId2FocusNode.dispose();
    _submitFocusNode.dispose();
    _disconnectFocusNode.dispose();
    _cancelFocusNode.dispose();

    _mccId1Controller.dispose();
    _mccId2Controller.dispose();
    _systemIdController.dispose();
    _downloadProgress.dispose();
    super.dispose();
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upperCaseText = newValue.text.toUpperCase();
    if (upperCaseText == newValue.text) return newValue;

    int clampOffset(int offset) {
      if (offset < 0) return 0;
      if (offset > upperCaseText.length) return upperCaseText.length;
      return offset;
    }

    return TextEditingValue(
      text: upperCaseText,
      selection: TextSelection(
        baseOffset: clampOffset(newValue.selection.baseOffset),
        extentOffset: clampOffset(newValue.selection.extentOffset),
        affinity: newValue.selection.affinity,
        isDirectional: newValue.selection.isDirectional,
      ),
      composing: newValue.composing,
    );
  }
}