import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'antiafk.dart';
import 'config.dart';
import 'helpers.dart';

const Size _kToolSize = Size(500, 300);

void main() => runApp(NWAntiAfk());

class NWAntiAfk extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: getRandomString(16),
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainPage(title:'New World Anti AFK'),
    );
  }
}

class MainPage extends StatefulWidget {
  final String title;

  const MainPage({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _switchValue = false;
  RangeValues _currentRangeValues = const RangeValues(3, 8);
  final AntiAfk _antiAfk = AntiAfk(
    Config(
      0x5A, // Z
      0x51, // S
      0x53, // Q
      0x44, // D
    )
  );

  @override
  void initState() {
    super.initState();
    _setWindowSize()/*.whenComplete(() {})*/;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Delay (in minutes)'),
                        RangeSlider(
                          values: _currentRangeValues,
                          min: 1,
                          max: 10,
                          divisions: 10,
                          labels: RangeLabels(
                            '${_currentRangeValues.start.floor()}',
                            '${_currentRangeValues.end.floor()}',
                          ),
                          onChanged: (RangeValues values) {
                            setState(() {
                              _currentRangeValues = values;
                              _antiAfk.min = values.start.floor();
                              _antiAfk.max = values.end.floor();
                            });
                          },
                        )
                      ]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Enable'),
                        const SizedBox(width: 10.0),
                        CupertinoSwitch(
                            value: _switchValue,
                            onChanged: (value) {
                              setState(() {
                                _switchValue = value;
                                if (_switchValue) {
                                  _antiAfk.start();
                                } else {
                                  _antiAfk.stop();
                                }
                              });
                            })
                      ])
                ])));
  }

  Future<void> _setWindowSize() async {
    await DesktopWindow.setMinWindowSize(_kToolSize);
    await DesktopWindow.setMaxWindowSize(_kToolSize);
    await DesktopWindow.setWindowSize(_kToolSize);
  }
}
