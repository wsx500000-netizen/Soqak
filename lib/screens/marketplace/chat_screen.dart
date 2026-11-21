import 'package:flutter/material.dart';
import 'package:shop/services/local_database.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.name = 'البائع'});

  final String name;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  List<Map<String, Object?>> _messages = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final db = await LocalDatabase.instance.database;
    final rows = await db.query('chats',
        where: 'name = ?', whereArgs: [widget.name], orderBy: 'id ASC');
    if (!mounted) return;
    if (rows.isEmpty) {
      await db.insert('chats', {
        'name': widget.name,
        'text': 'مرحباً، هل المنتج متوفر؟',
        'sentByMe': 1,
        'createdAt': DateTime.now().toIso8601String(),
      });
      final seeded = await db.query('chats',
          where: 'name = ?', whereArgs: [widget.name], orderBy: 'id ASC');
      setState(() {
        _messages = seeded;
        _loaded = true;
      });
      return;
    }
    setState(() {
      _messages = rows;
      _loaded = true;
    });
  }

  Future<void> _send(String text) async {
    final db = await LocalDatabase.instance.database;
    await db.insert('chats', {
      'name': widget.name,
      'text': text,
      'sentByMe': 1,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: !_loaded
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => Align(
                      alignment: _messages[index]['sentByMe'] == 1
                          ? AlignmentDirectional.centerEnd
                          : AlignmentDirectional.centerStart,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _messages[index]['sentByMe'] == 1
                              ? const Color(0xFF075E54)
                              : const Color(0xFFF1F2F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _messages[index]['text'] as String,
                          style: TextStyle(
                            color: _messages[index]['sentByMe'] == 1
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالتك',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;
                      setState(() {
                        _controller.clear();
                      });
                      _send(text);
                    },
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
