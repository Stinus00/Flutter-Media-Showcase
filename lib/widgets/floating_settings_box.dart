import 'dart:math';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

class FloatingSettingsBox extends StatefulWidget {
  const FloatingSettingsBox({
    super.key,
    required this.onCloseSettings
  });

  final VoidCallback onCloseSettings;

  @override
  State<FloatingSettingsBox> createState() => _FloatingSettingsBoxState();
}

enum TextInputType {email, password, text}

class _FloatingSettingsBoxState extends State<FloatingSettingsBox> {

  final _formKey = GlobalKey<FormState>();

  bool disabled = false;

  Widget _buildTextInput({
    required String text,
    required String hintText,
    required TextInputType type,
    bool obscureText = false,
    String obscureCharacter = '*',
    String validatorRegex = '',
    String errorMessage = '',
  }) {
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
            obscureText: obscureText,
            obscuringCharacter: obscureCharacter,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey),
              fillColor: Colors.transparent,
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }
              if (type == TextInputType.email) {
                if(EmailValidator.validate(value) == false) {
                  return 'Email unvalid. Please provide a valid email';
                }
              }
              return null;
            },
          ),
        ),
        Padding(padding: const EdgeInsets.only(top: 15.0))
      ]
    );

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
                  type: TextInputType.email,
                ),
                _buildTextInput(
                  text: 'Password',
                  hintText: '*********',
                  type: TextInputType.password,
                  obscureText: true,
                  obscureCharacter: '*',
                ),
                _buildTextInput(
                  text: 'Code', 
                  hintText: 'CoDe123', 
                  type: TextInputType.text
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ElevatedButton(
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
              ],
            ),
          ),
        ),
      ),
      
      // Padding(
      //   padding: const EdgeInsets.all(20.0),
      //   child: SingleChildScrollView(
      //     child: Column(
      //       children: [
      //         Row(
      //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //           children: const [
      //             Text(
      //               'Email',
      //               style: TextStyle(color: Colors.black),
      //             ),
      //             SizedBox(
      //               width: 300,
      //               child: TextField(
      //                 decoration: InputDecoration(
      //                   hintText: 'example@email.com',
      //                   hintTextDirection: TextDirection.ltr,
      //                   hintStyle: TextStyle(color: Colors.grey),
      //                   fillColor: Colors.transparent,
      //                 ),
      //               ),
      //             ),
      //           ],
      //         ),
      //         Row(
      //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //           children: const [
      //             Text(
      //               'Password',
      //               style: TextStyle(color: Colors.black),
      //             ),
      //             SizedBox(
      //               width: 300,
      //               child: TextField(
      //                 obscureText: true,
      //                 obscuringCharacter: '*',
      //                 decoration: InputDecoration(
      //                   hintText: "***********",
      //                   hintTextDirection: TextDirection.ltr,
      //                   hintStyle: TextStyle(color: Colors.grey),
      //                   fillColor: Colors.transparent,
      //                 ),
      //               ),
      //             ),
      //           ],
      //         ),
      //         Row(
      //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //           children: const [
      //             Text(
      //               'Test',
      //               style: TextStyle(color: Colors.black),
      //             ),
      //             SizedBox(
      //               width: 300,
      //               child: TextField(),
      //             ),
      //           ],
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
    );
  }
}