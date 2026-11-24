import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/hospital_info_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MisrakChoraApp());
}

class MisrakChoraApp extends StatelessWidget {
  const MisrakChoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Misrak Chora - የምስራቅ ጮራ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D4ED8),
          primary: const Color(0xFF1D4ED8),
          surface: const Color(0xFFFFFFFF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ClinicalChatScreen(),
    );
  }
}

class _ChatSession {
  final String id;
  String title;
  final List messages;

  _ChatSession({
    required this.id,
    required this.title,
    required this.messages,
  });

  Map toJson() => {
        "id": id,
        "title": title,
        "messages": messages,
      };

  factory _ChatSession.fromJson(Map json) {
    final rawMsgs = json["messages"];
    final parsedMsgs = [];
    if (rawMsgs is List) {
      for (final m in rawMsgs) {
        if (m is Map) {
          parsedMsgs.add({
            "sender": (m["sender"] ?? "").toString(),
            "text": (m["text"] ?? "").toString(),
          });
        }
      }
    }
    return _ChatSession(
      id: (json["id"] ?? "").toString(),
      title: (json["title"] ?? "Chat").toString(),
      messages: parsedMsgs,
    );
  }
}

const List kOfflineSevereConditions = [
  {
    "name": "የከንፈላት ደም መፍሰስ (Lip Bleeding)",
    "guide":
        "📌 ምንነት:\nበከንፈር አካባቢ በሚደርስ መቆረጥ፣ መላጥ ወይም በከባድ ስንጥቅ ምክንያት የሚከሰት የደም መፍሰስ ነው።\n\n"
        "⚠️ ምልክቶችና ጥንቃቄ:\nቀጣይነት ያለው ደም መፍሰስ፣ እብጠት ወይም ሕመም ሊታይ ይችላል። ከ10–15 ደቂቃ በላይ በቀጥታ ግፊት የማይቆም ከሆነ ወይም ቁስሉ ጥልቅ ከሆነ ወደ ሆስፒታል ይቅረቡ።\n\n"
        "🩺 የጤና ትምህርት:\nንጹሕ ጋዝ ወይም ጨርቅ በቀስታ በማድረግ ግፊት ይስጡ እና በጨርቅ የተጠቀለለ ቀዝቃዛ ነገር ይጠቀሙ።",
  },
  {
    "name": "የኩላሊት በሽታ (Kidney Disease)",
    "guide":
        "📌 ምንነት:\nኩላሊቶች ከደም ውስጥ ቆሻሻዎችንና ትርፍ ፈሳሽን የማጣራት ተግባራቸው በአጭር ወይም በረጅም ጊዜ የሚዳከምበት የጤና ሁኔታ ነው።\n\n"
        "⚠️ ምልክቶች:\nየእግር፣ የቁርጭምጭሚት ወይም የዓይን ዙሪያ ማበጥ፣ የሽንት ለውጥ፣ ከፍተኛ ድካም እና የትንፋሽ ማጠር።\n\n"
        "🩺 የጤና ትምህርት:\nየደም ግፊትንና የስኳር መጠንን መቆጣጠር፣ ጨው መቀነስ እና ያለሐኪም ትዕዛዝ የሚወሰዱ የሕመም ማስታገሻ መድኃኒቶችን ማስወገድ አስፈላጊ ነው።",
  },
  {
    "name": "የልብ ስራ ማቆም (Cardiac Arrest)",
    "guide":
        "📌 ምንነት:\nየልብ የኤሌክትሪክ እንቅስቃሴ በድንገት በመቋረጡ የደም ዝውውር የሚቋረጥበት እጅግ አስቸኳይ ሁኔታ ነው።\n\n"
        "⚠️ ምልክቶች:\nድንገተኛ ራስን መሳት፣ መደበኛ አተነፋፈስ ማቆም ወይም የልብ ምት አለመኖር።\n\n"
        "🚨 የጤና ትምህርት:\nወዲያውኑ የድንገተኛ ሕክምና እርዳታ ይጥሩ፤ የሰለጠኑ ባለሙያዎች ካሉ CPR ይጀምሩ።",
  },
  {
    "name": "Hypertension (የደም ግፊት)",
    "guide":
        "📌 ምንነት:\nየደም ግፊት ለረጅም ጊዜ ከመደበኛው በላይ ከፍ ብሎ የሚቆይበት ሁኔታ ነው።\n\n"
        "⚠️ ምልክቶች:\nብዙ ጊዜ ምልክት ላይኖረው ይችላል፤ ሲጨምር ራስ ምታት፣ የዕይታ ብዥታ ወይም የደረት ሕመም ሊያስከትል ይችላል።\n\n"
        "🩺 የጤና ትምህርት:\nግፊትን በመደበኛነት መለካት፣ መድኃኒትን በሐኪም መመሪያ መውሰድ፣ ጨው መቀነስ እና አካላዊ እንቅስቃሴ ማድረግ ይመከራል።",
  },
  {
    "name": "ስኳር (Diabetes Mellitus - DM)",
    "guide":
        "📌 ምንነት:\nበደም ውስጥ ያለው የግሉኮስ (ስኳር) መጠን ከመደበኛው በላይ ከፍ ብሎ የሚቆይበት ሥር የሰደደ ሁኔታ ነው።\n\n"
        "⚠️ ምልክቶች:\nከፍተኛ ጥማት፣ ተደጋጋሚ ሽንት፣ ረሃብ ወይም ክብደት መቀነስ፣ ድካም እና የቁስል መዘግየት።\n\n"
        "🩺 የጤና ትምህርት:\nየደም ስኳር ክትትል፣ የተመጣጠነ አመጋገብ እና የእግር እንክብካቤ/ምርመራ አስፈላጊ ናቸው።",
  },
  {
    "name": "ካንሰር (Cancer)",
    "guide":
        "📌 ምንነት:\nየሰውነት ሴሎች ከቁጥጥር ውጭ በመባዛት እብጠት ወይም ዕጢ የሚፈጥሩበት የበሽታዎች ስብስብ ነው።\n\n"
        "⚠️ ምልክቶች:\nየማይጠፋ እብጠት/ዕጢ፣ ያልታወቀ ክብደት መቀነስ፣ ከባድ ድካም ወይም ያልተለመደ ደም መፍሰስ።\n\n"
        "🩺 የጤና ትምህርት:\nቅድመ ምርመራ (Screening) ማድረግ፣ ትምባሆና አልኮል ማስወገድ እና ያልተለመደ ምልክት ሲታይ ሐኪም ማማከር።",
  },
];

class ClinicalChatScreen extends StatefulWidget {
  const ClinicalChatScreen({super.key});

  @override
  State<ClinicalChatScreen> createState() => _ClinicalChatScreenState();
}

class _ClinicalChatScreenState extends State<ClinicalChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List _messages = [];
  final List _chatHistory = [];
  String? _currentSessionId;
  bool _isLoading = false;
  int _selectedOfflineIndex = 0;

  String _activeView = 'chat';
  String _selectedNav = 'new_chat';

  static const String _historyStorageKey = "misrak_chora_chat_history_v1";
  final String apiUrl = "http://127.0.0.1:8000/api/ask";
  static const String _hospitalLogoPath = "assets/logo.jpg";
  static const String _stethoscopeImagePath = "assets/ICONE.png";
  static const String _userImagePath = "assets/user.png";

  static const Color _bgMain = Color(0xFFF9FAFB);
  static const Color _bgSidebar = Color(0xFF1D4ED8);
  static const Color _bgSidebarDeep = Color(0xFF1E3A8A);
  static const Color _bgCard = Color(0xFFFFFFFF);
  static const Color _bgAiBubble = Color(0xFF1E3A8A);
  static const Color _borderAiBubble = Color(0xFF172554);
  static const Color _bgUserBubble = Color(0xFF1D4ED8);
  static const Color _accentBlue = Color(0xFF1D4ED8);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF475569);

  static const List _quickPrompts = [
    {
      "label": "ትኩሳት እና ራስ ምታት",
      "prompt": "ትኩሳት እና ራስ ምታት ሲኖር ምን ሊሆን ይችላል እና ምን ማድረግ አለብኝ?",
    },
    {
      "label": "ሳል እና የመተንፈስ ችግር",
      "prompt": "ሳል እና የመተንፈስ ችግር ምልክቶች ምን ያመለክታሉ?",
    },
    {
      "label": "የሆድ ህመም / ተቅማጥ",
      "prompt": "የሆድ ህመም ወይም ተቅማጥ ሲከሰት የመጀመሪያ ጥንቃቄ ምንድን ነው?",
    },
    {
      "label": "የደረት ህመም / ድንገተኛ",
      "prompt": "የደረት ህመም እና የመተንፈስ እጥረት ተሰምቶኛል — ምን ማድረግ አለብኝ?",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedChatHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List _cloneMessages(List source) {
    final copied = [];
    for (final item in source) {
      if (item is Map) {
        copied.add({
          "sender": (item["sender"] ?? "").toString(),
          "text": (item["text"] ?? "").toString(),
        });
      }
    }
    return copied;
  }

  Future<void> _loadSavedChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_historyStorageKey);
      if (rawJson == null || rawJson.isEmpty) return;

      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        final loaded = [];
        for (final item in decoded) {
          if (item is Map) {
            loaded.add(_ChatSession.fromJson(item));
          }
        }
        if (mounted) {
          setState(() {
            _chatHistory.clear();
            _chatHistory.addAll(loaded);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _persistChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedList = [];
      for (final s in _chatHistory) {
        if (s is _ChatSession) {
          encodedList.add(s.toJson());
        }
      }
      await prefs.setString(_historyStorageKey, jsonEncode(encodedList));
    } catch (_) {}
  }

  _ChatSession _ensureActiveSession(String firstPrompt) {
    if (_currentSessionId != null) {
      for (final s in _chatHistory) {
        if (s is _ChatSession && s.id == _currentSessionId) {
          return s;
        }
      }
    }

    final newSession = _ChatSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: firstPrompt,
      messages: _cloneMessages(_messages),
    );
    _chatHistory.insert(0, newSession);
    _currentSessionId = newSession.id;
    return newSession;
  }

  void _syncSessionMessages() {
    if (_currentSessionId == null) return;
    for (final s in _chatHistory) {
      if (s is _ChatSession && s.id == _currentSessionId) {
        s.messages
          ..clear()
          ..addAll(_cloneMessages(_messages));
        break;
      }
    }
    _persistChatHistory();
  }

  Future<void> _deleteChatSession(
    _ChatSession session, {
    BuildContext? drawerCtx,
  }) async {
    final bool wasCurrentSession = _currentSessionId == session.id;

    setState(() {
      _chatHistory
          .removeWhere((item) => item is _ChatSession && item.id == session.id);
      if (wasCurrentSession) {
        _currentSessionId = null;
        _messages.clear();
        _controller.clear();
        _isLoading = false;
        if (_activeView == 'chat') {
          _selectedNav = 'new_chat';
        }
      }
    });

    await _persistChatHistory();

    if (drawerCtx != null && mounted) {
      _closeDrawerIfOpen(drawerCtx);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ቻቱ ተሰርዟል።'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmDeleteChatSession(
    _ChatSession session, {
    BuildContext? drawerCtx,
  }) async {
    final String displayTitle = session.title.length > 36
        ? '${session.title.substring(0, 36)}...'
        : session.title;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        surfaceTintColor: _bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFBFDBFE)),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'ቻት ይጥፋ?',
              style: TextStyle(
                color: _textDark,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          '"$displayTitle" የሚለውን የንግግር ታሪክ ማጥፋት እንደሚፈልጉ እርግጠኛ ነዎት?',
          style: const TextStyle(
            color: _textDark,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'ይቅር',
              style: TextStyle(color: _textMuted),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
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
      await _deleteChatSession(session, drawerCtx: drawerCtx);
    }
  }

  Future<void> _deleteSingleMessage(int index) async {
    if (index < 0 || index >= _messages.length) return;

    setState(() {
      _messages.removeAt(index);
      if (_currentSessionId != null) {
        for (final s in _chatHistory) {
          if (s is _ChatSession && s.id == _currentSessionId) {
            s.messages
              ..clear()
              ..addAll(_cloneMessages(_messages));
            break;
          }
        }
      }
    });

    await _persistChatHistory();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('መልዕክቱ ተሰርዟል።'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showMessageOptions(int index) async {
    if (index < 0 || index >= _messages.length) return;
    final msg = _messages[index] as Map;
    final fullText = (msg["text"] ?? "").toString();
    final preview = fullText.trim().replaceAll('\n', ' ');
    final shortPreview =
        preview.length > 45 ? '${preview.substring(0, 45)}...' : preview;

    final String? action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        surfaceTintColor: _bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFBFDBFE)),
        ),
        title: const Row(
          children: [
            Icon(Icons.more_horiz_rounded, color: _accentBlue),
            SizedBox(width: 8),
            Text(
              'Message options',
              style: TextStyle(
                color: _textDark,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          shortPreview.isEmpty
              ? 'ይህን መልዕክት ምን ማድረግ ይፈልጋሉ?'
              : '"$shortPreview"\n\nይህን መልዕክት ምን ማድረግ ይፈልጋሉ?',
          style: const TextStyle(
            color: _textDark,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _textMuted),
            ),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(ctx).pop('copy'),
            icon: const Icon(Icons.copy_rounded, size: 17, color: _accentBlue),
            label: const Text(
              'Copy',
              style: TextStyle(color: _accentBlue, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop('delete'),
            icon: const Icon(Icons.delete_outline_rounded, size: 17),
            label: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: fullText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('መልዕክቱ ኮፒ ተደርጓል።'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (action == 'delete') {
      await _deleteSingleMessage(index);
    }
  }

  void _closeDrawerIfOpen(BuildContext context) {
    if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  bool _isIdentityQuestion(String text) {
    final lower = text.toLowerCase().trim();
    return lower.contains('who are you') ||
        lower.contains('who created you') ||
        lower.contains('who made you') ||
        lower.contains('what is your name') ||
        lower.contains('your name') ||
        text.contains('አንተ ማን ነህ') ||
        text.contains('ማን ነህ') ||
        text.contains('ማን ፈጠረህ') ||
        text.contains('ማን ሰራህ') ||
        text.contains('ስምህ ማን ነው') ||
        text.contains('ስምህ ማነው');
  }

  bool _isCodeQuery(String query, String answer) {
    final qLower = query.toLowerCase();
    final aLower = answer.toLowerCase();
    return qLower.contains('code') ||
        qLower.contains('icd') ||
        query.contains('ኮድ') ||
        aLower.contains('matching codes for');
  }

  List _buildHistoryPayload() {
    final startIdx = _messages.length > 8 ? _messages.length - 8 : 0;
    final slice = _messages.sublist(startIdx);
    return slice
        .where((m) => m is Map)
        .map((m) => {
              "sender": (m["sender"] ?? "").toString(),
              "text": (m["text"] ?? "").toString(),
            })
        .toList();
  }

  Future<void> _sendQuery([String? customQuery]) async {
    if (_activeView != 'chat') return;
    final query = (customQuery ?? _controller.text).trim();
    if (query.isEmpty || _isLoading) return;

    final historyPayload = _buildHistoryPayload();

    setState(() {
      _activeView = 'chat';
      _selectedNav = 'chat';
      _messages.add({"sender": "user", "text": query});
      final session = _ensureActiveSession(query);
      session.messages
        ..clear()
        ..addAll(_cloneMessages(_messages));
      _isLoading = true;
    });
    await _persistChatHistory();

    if (customQuery == null) {
      _controller.clear();
    }
    _scrollToBottom();

    if (_isIdentityQuestion(query)) {
      const identityReply =
          'እኔ የምስራቅ ጮራ እባላለሁ — የምስራቅ ዕዝ ደረጃ 3 ሆስፒታል የጤና መረጃና ክሊኒካል ድጋፍ ስርዓት ነኝ።\n'
          'የተፈጠርኩት በአስር አለቃ ስዩም ቦጋለ (Corporal Seyoum Bogale) ነው።';

      setState(() {
        _messages.add({"sender": "ai", "text": identityReply});
        _syncSessionMessages();
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "question": query,
          "history": historyPayload,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final backendText = (data["answer"] ?? "").toString().trim();
        setState(() {
          _messages.add({
            "sender": "ai",
            "text": backendText.isEmpty ? "መልስ አልተገኘም።" : backendText,
          });
          _syncSessionMessages();
        });
      } else {
        setState(() {
          _messages.add({
            "sender": "ai",
            "text": _isCodeQuery(query, "")
                ? "ኮድ ማግኘት አልተቻለም።"
                : "ሰርቨሩ በጊዜው ምላሽ መስጠት አልቻለም (Status ${response.statusCode})። እባክዎን እንደገና ይሞክሩ ወይም የህክምና ባለሙያ ያማክሩ።",
          });
          _syncSessionMessages();
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          "sender": "ai",
          "text": _isCodeQuery(query, "")
              ? "ከሰርቨር ጋር መገናኘት አልተቻለም።"
              : "ከባክኤንድ ሰርቨሩ ($apiUrl) ጋር መገናኘት አልተቻለም። ያለ ኢንተርኔት ለማንበብ ከግራ ሜኑ 'Offline Guide (የሕክምና መጽሐፍ)' ይምረጡ።",
        });
        _syncSessionMessages();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _openHistorySession(_ChatSession session, {BuildContext? drawerCtx}) {
    if (drawerCtx != null) {
      _closeDrawerIfOpen(drawerCtx);
    }
    setState(() {
      _activeView = 'chat';
      _selectedNav = 'history_${session.id}';
      _currentSessionId = session.id;
      _messages
        ..clear()
        ..addAll(_cloneMessages(session.messages));
      _controller.clear();
    });
    _scrollToBottom();
  }

  void _startNewChat({BuildContext? drawerCtx}) {
    if (drawerCtx != null) {
      _closeDrawerIfOpen(drawerCtx);
    }
    setState(() {
      _activeView = 'chat';
      _selectedNav = 'new_chat';
      _currentSessionId = null;
      _messages.clear();
      _controller.clear();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 140,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildHospitalLogo({double size = 44, bool highlighted = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _bgCard,
        border: Border.all(
          color: _accentBlue,
          width: highlighted ? 3.5 : 1.6,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: _accentBlue.withValues(alpha: 0.16),
                  blurRadius: 28,
                  spreadRadius: 3,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        _hospitalLogoPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.local_hospital_rounded,
          color: _accentBlue,
          size: size * 0.56,
        ),
      ),
    );
  }

  Widget _buildChatWatermarkLogo({required bool isMobile}) {
    final double wmSize = isMobile ? 220 : 410;
    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: 0.18,
          child: Container(
            width: wmSize,
            height: wmSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _bgCard,
              border: Border.all(color: const Color(0xFFBFDBFE), width: 3),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              _hospitalLogoPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStethoscopeBadge() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _bgCard,
        border: Border.all(color: _bgAiBubble, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(5),
      child: Image.asset(
        _stethoscopeImagePath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.medical_services_rounded,
          color: _bgAiBubble,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildUserBadge() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _bgCard,
        border: Border.all(color: _bgUserBubble, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(5),
      child: Image.asset(
        _userImagePath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.person_rounded,
          color: _bgUserBubble,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildOfflineHandbookPanel({required bool isMobile}) {
    final selectedItem = kOfflineSevereConditions[_selectedOfflineIndex] as Map;

    return Container(
      margin: EdgeInsets.all(isMobile ? 10 : 16),
      padding: EdgeInsets.all(isMobile ? 14 : 22),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_rounded, color: _accentBlue, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'የሕክምና መጽሐፍ (Offline Guide — ያለ ኢንተርኔት የሚሰራ)',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFBFDBFE), height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(kOfflineSevereConditions.length, (idx) {
              final cond = kOfflineSevereConditions[idx] as Map;
              final bool active = idx == _selectedOfflineIndex;
              return ChoiceChip(
                selected: active,
                selectedColor: _accentBlue,
                label: Text(
                  (cond["name"] ?? "").toString(),
                  style: TextStyle(
                    color: active ? Colors.white : _textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedOfflineIndex = idx;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SelectableText(
                  "${selectedItem["name"]}\n======================================\n\n${selectedItem["guide"]}",
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 14.5,
                    height: 1.65,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressPanel({required bool isMobile}) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 10 : 16),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: _accentBlue, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Address, Contact & Location',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: isMobile ? 17 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFBFDBFE), height: 24),
          const Text(
            'Location / አድራሻ',
            style: TextStyle(
              color: _accentBlue,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'ምስራቅ ዕዝ ደረጃ 3 ሆስፒታል (East Command Level 3 Hospital - ECL3H)\n'
            'ከተማ (City): ድሬዳዋ (Dire Dawa), Ethiopia',
            style: TextStyle(color: _textDark, fontSize: 14.5, height: 1.6),
          ),
          const SizedBox(height: 22),
          const Text(
            'Contact / የመገናኛ አድራሻዎች',
            style: TextStyle(
              color: _accentBlue,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Phone: 0252115095\n'
            'Email: eastcommandlevel3hospital@gmail.com\n'
            'Fax: 0252116704\n'
            'Postal Box: 140',
            style: TextStyle(color: _textDark, fontSize: 14.5, height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorPanel({required bool isMobile}) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 10 : 16),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView(
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  color: _accentBlue, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Creator / ስለ ፈጣሪው',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: isMobile ? 17 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFBFDBFE), height: 24),
          const Text(
            'አስር አለቃ ስዩም ቦጋለ',
            style: TextStyle(
              color: _accentBlue,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'የሳይንስ ባችለር ዲግሪ በኢንፎርሜሽን ኮሙኒኬሽን ቴክኖሎጂ',
            style: TextStyle(
              color: _textDark,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'ሙያና የምሰራቸው አገልግሎቶች',
            style: TextStyle(
              color: _accentBlue,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'የኢንፎርሜሽን እና ኮሙኒኬሽን ቴክኖሎጂ (ICT) ባለሙያ፣ እንዲሁም ዌብሳይት (Website) እና አፕሊኬሽን (Application) ማበልፀግ።\n'
            'የምንሰጣቸው አገልግሎቶች፡ ዘመናዊ ድረ-ገጾች (Websites)፣ የሞባይል እና የዴስክቶፕ አፕሊኬሽኖች (Mobile & Desktop Applications)፣ የሶፍትዌርና የሲስተም ልማት (Software & System Development)፣ ዳታቤዝና ባክኤንድ ስርዓቶች (Backend & Database)፣ UI/UX ዲዛይን እና ሌሎች ተዛማጅ ዲጂታል መፍትሄዎችን ማዘጋጀት።',
            style: TextStyle(color: _textDark, fontSize: 14.5, height: 1.65),
          ),
          const Divider(color: Color(0xFFBFDBFE), height: 28),
          const Text(
            'Corporal Seyoum Bogale',
            style: TextStyle(
              color: _accentBlue,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bachelor of Science (BSc) in Information and Communication Technology (ICT)',
            style: TextStyle(
              color: _textDark,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Profession & Services',
            style: TextStyle(
              color: _accentBlue,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ICT professional and Web & Application Developer holding a Bachelor of Science (BSc) in Information and Communication Technology (ICT). '
            'Develop websites, mobile and desktop applications, custom software and information systems, backend APIs and databases, UI/UX designs, and related digital solutions.',
            style: TextStyle(color: _textMuted, fontSize: 14, height: 1.65),
          ),
          const SizedBox(height: 20),
          const Text(
            'Contact / መገናኛ አድራሻዎች',
            style: TextStyle(
              color: _accentBlue,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const SelectableText(
            'Telegram: https://t.me/SaintMikaele12\n'
            'Phone: +251946183542\n'
            'Email: elshuseyoum@gmail.com',
            style: TextStyle(color: _textDark, fontSize: 14.5, height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({BuildContext? drawerCtx}) {
    return Container(
      width: 268,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bgSidebar, _bgSidebarDeep],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildHospitalLogo(size: 44),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Misrak Chora',
                        style: TextStyle(
                          color: _textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'የምስራቅ ጮራ',
                        style: TextStyle(
                          color: _textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SidebarTile(
            icon: Icons.edit_square,
            label: 'New chat',
            selected: _activeView == 'chat' && _selectedNav == 'new_chat',
            onTap: () => _startNewChat(drawerCtx: drawerCtx),
          ),
          const SizedBox(height: 8),
          _SidebarTile(
            icon: Icons.menu_book_rounded,
            label: 'Offline Guide (የሕክምና መጽሐፍ)',
            selected: _activeView == 'offline_guide',
            onTap: () {
              if (drawerCtx != null) _closeDrawerIfOpen(drawerCtx);
              setState(() {
                _activeView = 'offline_guide';
                _selectedNav = 'offline_guide';
                _controller.clear();
              });
            },
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              'Chat history',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: _chatHistory.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'No recent chats',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  )
                : ListView.builder(
                    itemCount: _chatHistory.length,
                    itemBuilder: (_, index) {
                      final session = _chatHistory[index] as _ChatSession;
                      final isSelected = _activeView == 'chat' &&
                          _currentSessionId == session.id;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _bgCard
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: const EdgeInsets.only(
                            left: 12,
                            right: 4,
                          ),
                          leading: Icon(
                            Icons.chat_bubble_outline,
                            size: 16,
                            color: isSelected ? _accentBlue : Colors.white,
                          ),
                          title: Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected ? _textDark : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              fontSize: 13,
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: 'Delete chat',
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: isSelected ? _textMuted : Colors.white70,
                            ),
                            onPressed: () => _confirmDeleteChatSession(
                              session,
                              drawerCtx: drawerCtx,
                            ),
                          ),
                          onTap: () =>
                              _openHistorySession(session, drawerCtx: drawerCtx),
                        ),
                      );
                    },
                  ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.22), height: 20),
          _SidebarTile(
            icon: Icons.local_hospital_outlined,
            label: 'Hospital information',
            selected: _activeView == 'hospital_info',
            onTap: () {
              if (drawerCtx != null) _closeDrawerIfOpen(drawerCtx);
              setState(() {
                _activeView = 'hospital_info';
                _selectedNav = 'hospital_info';
                _controller.clear();
              });
            },
          ),
          const SizedBox(height: 6),
          _SidebarTile(
            icon: Icons.location_on_outlined,
            label: 'Address',
            selected: _activeView == 'address',
            onTap: () {
              if (drawerCtx != null) _closeDrawerIfOpen(drawerCtx);
              setState(() {
                _activeView = 'address';
                _selectedNav = 'address';
                _controller.clear();
              });
            },
          ),
          const SizedBox(height: 6),
          _SidebarTile(
            icon: Icons.person_outline_rounded,
            label: 'Creator',
            selected: _activeView == 'creator',
            onTap: () {
              if (drawerCtx != null) _closeDrawerIfOpen(drawerCtx);
              setState(() {
                _activeView = 'creator';
                _selectedNav = 'creator';
                _controller.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCenterArea({required bool isMobile}) {
    if (_activeView == 'offline_guide') {
      return _buildOfflineHandbookPanel(isMobile: isMobile);
    }

    if (_activeView == 'hospital_info') {
      return Container(
        margin: EdgeInsets.all(isMobile ? 8 : 16),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        clipBehavior: Clip.antiAlias,
        child: const HospitalInfoScreen(),
      );
    }

    if (_activeView == 'address') {
      return _buildAddressPanel(isMobile: isMobile);
    }

    if (_activeView == 'creator') {
      return _buildCreatorPanel(isMobile: isMobile);
    }

    if (_messages.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 14 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHospitalLogo(
                size: isMobile ? 140 : 260,
                highlighted: true,
              ),
              const SizedBox(height: 16),
              Text(
                'Misrak Chora - የምስራቅ ጮራ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _bgSidebarDeep,
                  fontSize: isMobile ? 21 : 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'የምስራቅ ዕዝ ደረጃ 3 ሆስፒታል — የጤና መረጃና ክሊኒካል ድጋፍ\n'
                'Eastern Command Level 3 Hospital — Health Information and Clinical Support',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _bgSidebarDeep,
                  fontSize: isMobile ? 13 : 15.5,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _quickPrompts.map((item) {
                  final mapItem = item as Map;
                  final labelText = (mapItem["label"] ?? "").toString();
                  final promptText = (mapItem["prompt"] ?? "").toString();
                  return ActionChip(
                    backgroundColor: _bgCard,
                    side: const BorderSide(color: Color(0xFF93C5FD)),
                    label: Text(
                      labelText,
                      style: TextStyle(
                        color: _bgSidebarDeep,
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 12 : 13,
                      ),
                    ),
                    onPressed: () => _sendQuery(promptText),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Container(
                constraints: const BoxConstraints(maxWidth: 680),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  'ማሳሰቢያ፡ ይህ ስርዓት የጤና መረጃ እና የመጀመሪያ ደረጃ ድጋፍ ይሰጣል፤ የሐኪም ምርመራን አይተካም። '
                  'ከባድ ወይም የድንገተኛ ምልክቶች ካሉ ወዲያውኑ ወደ ሆስፒታል ይሂዱ።',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textDark,
                    fontSize: isMobile ? 11.5 : 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        _buildChatWatermarkLogo(isMobile: isMobile),
        ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: isMobile ? 14 : 22,
          ),
          itemCount: _messages.length + (_isLoading ? 1 : 0),
          itemBuilder: (_, index) {
            if (index == _messages.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStethoscopeBadge(),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _bgAiBubble,
                          borderRadius: BorderRadius.circular(18),
                          border:
                              Border.all(color: _borderAiBubble, width: 1.4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'መልስ በማዘጋጀት ላይ...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final msg = _messages[index] as Map;
            final sender = (msg["sender"] ?? "").toString();
            final text = (msg["text"] ?? "").toString();
            final isUser = sender == "user";

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment:
                    isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    _buildStethoscopeBadge(),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 6),
                          bottomRight: Radius.circular(isUser ? 6 : 20),
                        ),
                        onTap: () => _showMessageOptions(index),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 14 : 18,
                            vertical: isMobile ? 11 : 14,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: isMobile ? 290 : 700,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? _bgUserBubble : _bgAiBubble,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isUser ? 20 : 6),
                              bottomRight: Radius.circular(isUser ? 6 : 20),
                            ),
                            border: Border.all(
                              color: isUser
                                  ? const Color(0xFF1E3A8A)
                                  : _borderAiBubble,
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            text,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 13.5 : 14.5,
                              fontWeight: FontWeight.w500,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isUser) ...[
                    const SizedBox(width: 8),
                    _buildUserBadge(),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInputBubble({required bool isMobile}) {
    if (_activeView != 'chat') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 24,
        6,
        isMobile ? 12 : 24,
        isMobile ? 12 : 20,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 780),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 18,
            vertical: isMobile ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFBFDBFE), width: 1.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.health_and_safety_outlined,
                  color: _accentBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: TextStyle(
                    color: _textDark,
                    fontSize: isMobile ? 14 : 15,
                  ),
                  onSubmitted: (_) => _sendQuery(),
                  decoration: InputDecoration(
                    hintText: 'Ask Misrak Chora',
                    hintStyle: TextStyle(
                      color: _textMuted,
                      fontSize: isMobile ? 14 : 15,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _bgUserBubble,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 19),
                  onPressed: () => _sendQuery(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Scaffold(
        backgroundColor: _bgMain,
        appBar: AppBar(
          backgroundColor: _bgSidebar,
          foregroundColor: Colors.white,
          elevation: 1,
          titleSpacing: 4,
          title: Row(
            children: [
              _buildHospitalLogo(size: 32),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Misrak Chora - የምስራቅ ጮራ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        drawer: Builder(
          builder: (drawerCtx) => Drawer(
            child: _buildSidebar(drawerCtx: drawerCtx),
          ),
        ),
        body: Column(
          children: [
            Expanded(child: _buildCenterArea(isMobile: true)),
            if (_activeView == 'chat') _buildInputBubble(isMobile: true),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgMain,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildCenterArea(isMobile: false)),
                if (_activeView == 'chat') _buildInputBubble(isMobile: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: selected ? const Color(0xFF1D4ED8) : Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? const Color(0xFF1E293B) : Colors.white,
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}