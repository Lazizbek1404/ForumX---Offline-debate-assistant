// judge_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class JudgeScreen extends StatefulWidget {
  @override
  _JudgeScreenState createState() => _JudgeScreenState();
}

class _JudgeScreenState extends State<JudgeScreen> {
  List<_Participant> _participants = [];

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('participants');
    if (data != null) {
      final decoded = jsonDecode(data) as List;
      setState(() {
        _participants = decoded.map((e) => _Participant.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveParticipants() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_participants.map((e) => e.toJson()).toList());
    await prefs.setString('participants', encoded);
  }

  void _addParticipantDialog() {
    final nameController = TextEditingController();
    final scoreController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Participant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: 'Enter name'),
            ),
            TextField(
              controller: scoreController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: 'Enter score (0-100)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final score = int.tryParse(scoreController.text) ?? 0;
              if (name.isNotEmpty) {
                setState(() {
                  _participants.add(_Participant(name: name, score: score));
                });
                _saveParticipants();
              }
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editParticipantDialog(int index) {
    final nameController = TextEditingController(text: _participants[index].name);
    final scoreController = TextEditingController(text: _participants[index].score.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Participant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: 'Edit name'),
            ),
            TextField(
              controller: scoreController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: 'Edit score (0-100)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _participants[index].name = nameController.text.trim();
                _participants[index].score = int.tryParse(scoreController.text) ?? 0;
              });
              _saveParticipants();
              Navigator.pop(context);
            },
            child: Text('Save'),
          )
        ],
      ),
    );
  }

  void _deleteParticipantDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Participant'),
        content: Text('Are you sure you want to delete this member?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _participants.removeAt(index);
              });
              _saveParticipants();
              Navigator.pop(context);
            },
            child: Text('Delete'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Judge Scoring'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            tooltip: 'Add Participant',
            onPressed: _addParticipantDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _participants.isEmpty
            ? Center(child: Text('No participants yet.'))
            : ListView.builder(
                itemCount: _participants.length,
                itemBuilder: (context, index) => Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text(_participants[index].name),
                    subtitle: Text('Score: ${_participants[index].score}'),
                    trailing: Wrap(
                      spacing: 10,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _editParticipantDialog(index),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteParticipantDialog(index),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _Participant {
  String name;
  int score;

  _Participant({required this.name, this.score = 0});

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
      };

  factory _Participant.fromJson(Map<String, dynamic> json) => _Participant(
        name: json['name'],
        score: json['score'] ?? 0,
      );
}
