import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class SpeechTimerScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _SpeechTimerScreenState createState() => _SpeechTimerScreenState();
}

class _SpeechTimerScreenState extends State<SpeechTimerScreen> {
  int _remainingTime = 0;
  int _defaultTime = 60; // seconds
  bool _isRunning = false;
  late SharedPreferences _prefs;
  int _selectedMinutes = 1;
  int _selectedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadTime();
  }

  Future<void> _loadTime() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultTime = _prefs.getInt('speech_timer_duration') ?? 60;
      _remainingTime = _defaultTime;
      _selectedMinutes = _defaultTime ~/ 60;
      _selectedSeconds = _defaultTime % 60;
    });
  }

  void _startTimer() {
    if (_isRunning) return;
    _isRunning = true;
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (!_isRunning) return false;
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
        return true;
      } else {
        _isRunning = false;
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 500);
        }
        return false;
      }
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    setState(() {
      _remainingTime = _defaultTime;
      _isRunning = false;
    });
  }

  void _updateTime(int minutes, int seconds) {
    int totalSeconds = minutes * 60 + seconds;
    setState(() {
      _defaultTime = totalSeconds;
      _remainingTime = totalSeconds;
      _selectedMinutes = minutes;
      _selectedSeconds = seconds;
    });
    _prefs.setInt('speech_timer_duration', totalSeconds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Speech Timer')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_remainingTime ~/ 60}:${(_remainingTime % 60).toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _startTimer, child: Text('Start')),
                SizedBox(width: 10),
                ElevatedButton(onPressed: _pauseTimer, child: Text('Pause')),
                SizedBox(width: 10),
                ElevatedButton(onPressed: _resetTimer, child: Text('Reset')),
              ],
            ),
            SizedBox(height: 40),
            Text(
              'Set Time:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<int>(
                  value: _selectedMinutes,
                  items: List.generate(60, (index) => index)
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e min')))
                      .toList(),
                  onChanged: (value) {
                    _updateTime(value ?? 0, _selectedSeconds);
                  },
                ),
                SizedBox(width: 10),
                DropdownButton<int>(
                  value: _selectedSeconds,
                  items: List.generate(60, (index) => index)
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e sec')))
                      .toList(),
                  onChanged: (value) {
                    _updateTime(_selectedMinutes, value ?? 0);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
