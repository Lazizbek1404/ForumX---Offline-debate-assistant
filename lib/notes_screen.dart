// notes_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotesScreen extends StatefulWidget {
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final List<_Note> _notes = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesData = prefs.getString('notes');
    if (notesData != null) {
      final decoded = jsonDecode(notesData) as List;
      setState(() {
        _notes.addAll(decoded.map((e) => _Note.fromJson(e)).toList());
      });
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_notes.map((e) => e.toJson()).toList());
    await prefs.setString('notes', encoded);
  }

  void _addNote(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _notes.add(_Note(text: text));
      _controller.clear();
    });
    _saveNotes();
  }

  void _togglePin(int index) {
    setState(() {
      _notes[index].isPinned = !_notes[index].isPinned;
    });
    _saveNotes();
  }

  void _editNoteDialog(int index) {
    final TextEditingController editController = TextEditingController(text: _notes[index].text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Note'),
        content: TextField(
          controller: editController,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _notes[index].text = editController.text;
              });
              _saveNotes();
              Navigator.pop(context);
            },
            child: Text('Save'),
          )
        ],
      ),
    );
  }

  void _deleteNoteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note'),
        content: Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _notes.removeAt(index);
              });
              _saveNotes();
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
    final pinned = _notes.where((note) => note.isPinned).toList();
    final others = _notes.where((note) => !note.isPinned).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              onSubmitted: _addNote,
              decoration: InputDecoration(
                hintText: 'Enter your note...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _addNote(_controller.text),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 1,
                childAspectRatio: 3.5,
                mainAxisSpacing: 10,
                children: [
                  ...pinned.map((note) => _buildNoteCard(note, _notes.indexOf(note))),
                  ...others.map((note) => _buildNoteCard(note, _notes.indexOf(note))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(_Note note, int index) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                note.text,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            IconButton(
              icon: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              onPressed: () => _togglePin(index),
            ),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _editNoteDialog(index),
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteNoteDialog(index),
            ),
          ],
        ),
      ),
    );
  }
}

class _Note {
  String text;
  bool isPinned;

  _Note({required this.text, this.isPinned = false});

  Map<String, dynamic> toJson() => {
        'text': text,
        'isPinned': isPinned,
      };

  factory _Note.fromJson(Map<String, dynamic> json) => _Note(
        text: json['text'],
        isPinned: json['isPinned'] ?? false,
      );
}
