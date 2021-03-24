import 'package:flutter/material.dart';

class Switch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    bool _lights = false;

    return SwitchListTile(
      title: const Text('Lights'),
      value: _lights,
      onChanged: (bool value) {
        setState(() {
          _lights = value;
        });
      },
      secondary: const Icon(Icons.lightbulb_outline),
    );
  }

  void setState(Null Function() param0) {}
}
