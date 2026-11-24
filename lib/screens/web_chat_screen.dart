import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// በቀኝ በኩል (image_ea0e05.jpg) የሚታየው ብሩህ ሰማያዊ እና ነጭ ቀለም
const Color kBrightBlue = Color(0xFF1A6DFF);
const Color kBrightBlueDeep = Color(0xFF0E54D4);
const Color kSoftBlueTint = Color(0xFFEAF2FF);
const Color kPureWhite = Color(0xFFFFFFFF);
const Color kLightBlueBg = Color(0xFFF3F7FD);
const Color kBorderBlue = Color(0xFFD2E2F8);
const Color kTextDark = Color(0xFF0B1F3A);
const Color kTextMuted = Color(0xFF526983);

const String kRenderBackendBaseUrl = 'https://misrak-chora-backend.onrender.com';
const String kRenderAskEndpoint = '$kRenderBackendBaseUrl/api/ask';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List> matches;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.matches = const [],
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatSession {
  final String id;
  String title;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
  });
}

class WebChatScreen extends StatefulWidget {
  const WebChatScreen({super.key});

  @override
  State<WebChatScreen> createState() => _WebChatScreenState();
}

class _WebChatScreenState extends State<WebChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final List<ChatSession> _sessions = [];
  int _activeSessionIndex = -1;
  bool _isLoading = false;

  static const String _backendUrl = kRenderAskEndpoint;

  List<ChatMessage> get _currentMessages {
    if (_activeSessionIndex < 0 || _activeSessionIndex >= _sessions.length) {
      return const [];
    }
    return _sessions[_activeSessionIndex].messages;
  }

  void _closeDrawerIfOpen(BuildContext context) {
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  void _startNewChat([BuildContext? contextForDrawer]) {
    if (contextForDrawer != null) {
      _closeDrawerIfOpen(contextForDrawer);
    }
    setState(() {
      _activeSessionIndex = -1;
      _isLoading = false;
    });
    _inputFocusNode.requestFocus();
  }

  void _selectSession(int index, [BuildContext? contextForDrawer]) {
    if (index < 0 || index >= _sessions.length) return;
    if (contextForDrawer != null) {
      _closeDrawerIfOpen(contextForDrawer);
    }
    setState(() {
      _activeSessionIndex = index;
    });
    _scrollToBottom();
  }

  void _deleteSession(int index) {
    if (index < 0 || index >= _sessions.length) return;

    setState(() {
      _sessions.removeAt(index);
      if (_sessions.isEmpty || _activeSessionIndex == index) {
        _activeSessionIndex = -1;
        _isLoading = false;
      } else if (_activeSessionIndex > index) {
        _activeSessionIndex--;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ቻቱ ተሰርዟል።'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmDeleteSession(int index) async {
    if (index < 0 || index >= _sessions.length) return;
    final String title = _sessions[index].title;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kPureWhite,
        surfaceTintColor: kPureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: kBorderBlue),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'ቻት ይጥፋ?',
              style: TextStyle(
                color: kTextDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          '"$title" የሚለውን የንግግር ታሪክ ማጥፋት እንደሚፈልጉ እርግጠኛ ነዎት?',
          style: const TextStyle(
            color: kTextDark,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'ይቅር',
              style: TextStyle(color: kTextMuted),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: kPureWhite,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('አጥፋ'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _deleteSession(index);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 140,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _makeTitle(String prompt) {
    final trimmed = prompt.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.length <= 28) return trimmed;
    return '${trimmed.substring(0, 28)}...';
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = (customText ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    if (customText == null) {
      _controller.clear();
    }

    int sessionIdx = _activeSessionIndex;
    if (sessionIdx < 0 || sessionIdx >= _sessions.length) {
      final newSession = ChatSession(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _makeTitle(text),
        messages: [],
      );
      _sessions.insert(0, newSession);
      sessionIdx = 0;
      _activeSessionIndex = 0;
    }

    setState(() {
      _sessions[sessionIdx].messages.add(
            ChatMessage(text: text, isUser: true),
          );
      _isLoading = true;
    });
    _scrollToBottom();

    String replyText;
    List> parsedMatches = const [];

    try {
      final response = await http
          .post(
            Uri.parse(_backendUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'question': text}),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        replyText = (decoded['answer'] ?? '').toString().trim();
        if (replyText.isEmpty) {
          replyText = 'ምላሽ ማግኘት አልተቻለም። እባክዎ እንደገና ይሞክሩ።';
        }
        if (decoded['matches'] is List) {
          parsedMatches = (decoded['matches'] as List)
              .whereType()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
        }
      } else {
        replyText =
            'የሰርቨር ስህተት (${response.statusCode}) ተፈጥሯል። እባክዎ እንደገና ይሞክሩ።';
      }
    } catch (_) {
      replyText =
          'ከባክኤንድ ሰርቨር ($kRenderBackendBaseUrl) ጋር መገናኘት አልተቻለም። '
          'እባክዎ የ Render ሰርቨሩ መነሳቱን ወይም የኢንተርኔት ግንኙነትዎን ያረጋግጡ።';
    }

    if (!mounted) return;
    setState(() {
      _sessions[sessionIdx].messages.add(
            ChatMessage(
              text: replyText,
              isUser: false,
              matches: parsedMatches,
            ),
          );
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _showHospitalInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kPureWhite,
        surfaceTintColor: kPureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: kBorderBlue),
        ),
        title: const Row(
          children: [
            Icon(Icons.local_hospital_rounded, color: kBrightBlue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'የምስራቅ ዕዝ ደረጃ 3 ሆስፒታል',
                style: TextStyle(
                  color: kTextDark,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'ስርዓት፦ ምስራቅ ጮራ AI (Misrak Chora AI)\n'
          'ፈጣሪ፦ አስር አለቃ ስዩም ቦጋለ (የአይ ሲቲ ሙያተኛ)\n'
          'አገልግሎት፦ የጤና መረጃ፣ የበሽታ/ምልክት ማብራሪያ እና ክሊኒካል ድጋፍ።\n'
          'ማሳሰቢያ፦ ከባድ ወይም አጣዳፊ የጤና ምልክት ሲታይ ሳይዘገዩ በቀጥታ ወደ ሆስፒታል ይቅረቡ።',
          style: TextStyle(
            color: kTextDark,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kBrightBlue,
              foregroundColor: kPureWhite,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ዝጋ'),
          ),
        ],
      ),
    );
  }

  void _showAddressDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kPureWhite,
        surfaceTintColor: kPureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: kBorderBlue),
        ),
        title: const Row(
          children: [
            Icon(Icons.location_on_rounded, color: kBrightBlue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'አድራሻ / Location',
                style: TextStyle(
                  color: kTextDark,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'ምስራቅ ዕዝ ደረጃ 3 ሆስፒታል\n'
          'የሕክምና መረጃና ክሊኒካል ድጋፍ አገልግሎት — Misrak Chora AI',
          style: TextStyle(
            color: kTextDark,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kBrightBlue,
              foregroundColor: kPureWhite,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('እሺ'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 760;

    return Scaffold(
      backgroundColor: kLightBlueBg,
      appBar: isWide
          ? null
          : AppBar(
              backgroundColor: kBrightBlue,
              surfaceTintColor: kBrightBlue,
              elevation: 0,
              iconTheme: const IconThemeData(color: kPureWhite),
              title: const Text(
                'Misrak Chora AI',
                style: TextStyle(
                  color: kPureWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
      drawer: isWide ? null : Drawer(child: _buildSidebar(context)),
      body: Row(
        children: [
          if (isWide)
            SizedBox(
              width: 270,
              child: _buildSidebar(context),
            ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _currentMessages.isEmpty
                      ? _buildWelcomeView()
                      : _buildMessagesList(),
                ),
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext sidebarContext) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kBrightBlue, kBrightBlueDeep],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Brand Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPureWhite,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: kSoftBlueTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        color: kBrightBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Misrak Chora AI',
                            style: TextStyle(
                              color: kTextDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'ምስራቅ ዕዝ ደረጃ 3 ሆስፒታል',
                            style: TextStyle(
                              color: kTextMuted,
                              fontSize: 11.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // New Chat Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: kPureWhite,
                  foregroundColor: kBrightBlue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _startNewChat(sidebarContext),
                icon: const Icon(Icons.edit_square, size: 18),
                label: const Text(
                  'New chat',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Chat History Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'Chat history',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Sessions List
            Expanded(
              child: _sessions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      child: Text(
                        'No recent chats',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: _sessions.length,
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
                        final bool isSelected = index == _activeSessionIndex;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Material(
                            color: isSelected
                                ? kPureWhite
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.only(
                                left: 12,
                                right: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              leading: Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 17,
                                color: isSelected ? kBrightBlue : kPureWhite,
                              ),
                              title: Text(
                                session.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected ? kTextDark : kPureWhite,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  fontSize: 13.5,
                                ),
                              ),
                              trailing: IconButton(
                                tooltip: 'Delete chat',
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: isSelected
                                      ? kTextMuted
                                      : Colors.white70,
                                ),
                                onPressed: () => _confirmDeleteSession(index),
                              ),
                              onTap: () => _selectSession(index, sidebarContext),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),

            // Bottom Hospital Actions
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    leading: const Icon(
                      Icons.add_box_outlined,
                      color: kPureWhite,
                      size: 20,
                    ),
                    title: const Text(
                      'Hospital information',
                      style: TextStyle(
                        color: kPureWhite,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      _closeDrawerIfOpen(sidebarContext);
                      _showHospitalInfoDialog();
                    },
                  ),
                  ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: kPureWhite,
                      size: 20,
                    ),
                    title: const Text(
                      'Address',
                      style: TextStyle(
                        color: kPureWhite,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      _closeDrawerIfOpen(sidebarContext);
                      _showAddressDialog();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [kPureWhite, kLightBlueBg],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  color: kPureWhite,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kBrightBlue.withValues(alpha: 0.25),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kBrightBlue.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: const BoxDecoration(
                      color: kBrightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      size: 44,
                      color: kPureWhite,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Misrak Chora AI',
                style: TextStyle(
                  color: kTextDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'ምስራቅ ዕዝ ደረጃ 3 ሆስፒታል — የጤና መረጃና ክሊኒካል ድጋፍ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kTextMuted,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormattedMessageText(String text, bool isUser) {
    if (isUser) {
      return SelectableText(
        text,
        style: const TextStyle(
          color: kPureWhite,
          fontSize: 14.5,
          height: 1.55,
        ),
      );
    }

    final lines = text.split('\n');
    final List<InlineSpan> spans = [];

    const sectionHeaders = {
      'ምንነት:',
      'ምልክቶች:',
      'መንስኤዎች:',
      'ሕክምና:',
      'Meaning:',
      'Symptoms:',
      'Causes:',
      'Treatment:',
    };

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      final isHeader = sectionHeaders.contains(trimmed);

      spans.add(
        TextSpan(
          text: line + (i < lines.length - 1 ? '\n' : ''),
          style: TextStyle(
            color: isHeader ? kBrightBlueDeep : kTextDark,
            fontSize: isHeader ? 15 : 14.5,
            fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
            height: 1.55,
          ),
        ),
      );
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }

  Widget _buildMessagesList() {
    final messages = _currentMessages;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && _isLoading) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(top: 6, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kPureWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorderBlue),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: kBrightBlue,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'መልስ በማዘጋጀት ላይ...',
                    style: TextStyle(
                      color: kTextMuted,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final msg = messages[index];
        final bool isUser = msg.isUser;

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: isUser ? kBrightBlue : kPureWhite,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: isUser ? null : Border.all(color: kBorderBlue),
              boxShadow: [
                BoxShadow(
                  color: (isUser ? kBrightBlue : kTextDark)
                      .withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _buildFormattedMessageText(msg.text, isUser),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: kLightBlueBg,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: kPureWhite,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: kBorderBlue, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: kBrightBlue.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.add_circle_outline_rounded,
                  color: kBrightBlue,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _inputFocusNode,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (val) => _sendMessage(val),
                    style: const TextStyle(
                      color: kTextDark,
                      fontSize: 14.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Ask Misrak Chora AI',
                      hintStyle: TextStyle(
                        color: kTextMuted,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: kBrightBlue,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _isLoading ? null : () => _sendMessage(),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.send_rounded,
                        color: kPureWhite,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}