import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  static const Map<String, dynamic> _welcomeMessage = {
    'text':
        'Welcome to Misrak Chora AI.\n\nAI Assistant of East Command Level III Hospital.',
    'isUser': false,
  };

  final List> messages = [
    Map<String, dynamic>.from(_welcomeMessage),
  ];

  // የተቀመጡ የንግግር ታሪኮች ዝርዝር
  final List> chatHistory = [];

  bool isLoading = false;

  void _saveCurrentChatIfNeeded() {
    final bool hasUserMessage = messages.any((m) => m['isUser'] == true);
    if (!hasUserMessage) return;

    final firstUserMsg = messages.firstWhere(
      (m) => m['isUser'] == true,
      orElse: () => {'text': 'Chat'},
    )['text']
        .toString()
        .trim();

    final String title = firstUserMsg.length > 28
        ? '${firstUserMsg.substring(0, 28)}...'
        : firstUserMsg;

    chatHistory.insert(0, {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'title': title,
      'messages': messages.map((m) => Map<String, dynamic>.from(m)).toList(),
    });
  }

  Future<void> sendMessage() async {
    final message = _controller.text.trim();

    if (message.isEmpty || isLoading) return;

    setState(() {
      messages.add({
        'text': message,
        'isUser': true,
      });

      isLoading = true;
    });

    _controller.clear();

    try {
      final response = await AiService.sendMessage(message);

      if (!mounted) return;
      setState(() {
        messages.add({
          'text': response,
          'isUser': false,
        });

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        messages.add({
          'text': 'Error: $e',
          'isUser': false,
        });

        isLoading = false;
      });
    }
  }

  void newChat() {
    setState(() {
      _saveCurrentChatIfNeeded();
      messages
        ..clear()
        ..add(Map<String, dynamic>.from(_welcomeMessage));
      isLoading = false;
    });

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _confirmClearCurrentChat() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ቻት ይጥፋ?'),
        content: const Text(
          'አሁን እየተካሄደ ያለውን የንግግር ገጽ ማጽዳት እንደሚፈልጉ እርግጠኛ ነዎት?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ይቅር'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('አጥፋ'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        messages
          ..clear()
          ..add(Map<String, dynamic>.from(_welcomeMessage));
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('የአሁኑ ቻት ተሰርዟል።'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmDeleteHistoryItem(int index, StateSetter setSheetState) async {
    if (index < 0 || index >= chatHistory.length) return;
    final String title = chatHistory[index]['title'].toString();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ቻት ይጥፋ?'),
        content: Text('"$title" የሚለውን ቻት ማጥፋት እንደሚፈልጉ እርግጠኛ ነዎት?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ይቅር'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('አጥፋ'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        chatHistory.removeAt(index);
      });
      setSheetState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ቻቱ ተሰርዟል።'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _openChatHistoryModal() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chat History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (chatHistory.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('No saved chats yet.')),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: chatHistory.length,
                        itemBuilder: (context, index) {
                          final item = chatHistory[index];
                          return ListTile(
                            leading: const Icon(Icons.chat_bubble_outline),
                            title: Text(
                              item['title'].toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              final savedMsgs = (item['messages'] as List)
                                  .map((m) => Map<String, dynamic>.from(m as Map))
                                  .toList();
                              setState(() {
                                messages
                                  ..clear()
                                  ..addAll(savedMsgs);
                              });
                              Navigator.of(ctx).pop();
                            },
                            trailing: IconButton(
                              tooltip: 'Delete chat',
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () =>
                                  _confirmDeleteHistoryItem(index, setSheetState),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.medical_services,
                    color: Colors.white,
                    size: 50,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Misrak Chora',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New Chat'),
              onTap: newChat,
            ),
            const ListTile(
              leading: Icon(Icons.local_hospital),
              title: Text('Departments'),
            ),
            const ListTile(
              leading: Icon(Icons.info),
              title: Text('Hospital Information'),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Chat History'),
              onTap: _openChatHistoryModal,
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Misrak Chora'),
        actions: [
          IconButton(
            tooltip: 'Delete current chat',
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmClearCurrentChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];

                return Align(
                  alignment: message['isUser']
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message['isUser']
                          ? Colors.blue
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message['text'],
                      style: TextStyle(
                        color: message['isUser']
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) {
                      sendMessage();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Ask Misrak Chora...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}