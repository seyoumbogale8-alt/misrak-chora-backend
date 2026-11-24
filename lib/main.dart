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
  final bool isIcd11Mode;
  final List messages;

  _ChatSession({
    required this.id,
    required this.title,
    this.isIcd11Mode = false,
    required this.messages,
  });

  Map toJson() => {
        "id": id,
        "title": title,
        "isIcd11Mode": isIcd11Mode,
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
      isIcd11Mode: json["isIcd11Mode"] == true,
      messages: parsedMsgs,
    );
  }
}

const List kOfflineMedicalTopics = [
  {
    "category": "የሰውነት አካላት ንጽጽር (ጤናማ vs በሽታ)",
    "name": "ሳንባ (Lungs)",
    "mode": "comparison",
    "healthyPhoto": "assets/lungs_healthy.png",
    "diseasedPhoto": "assets/lungs_diseased.png",
    "healthyCaption": "ጤናማ ሳንባ (Healthy Lungs)",
    "diseasedCaption": "በሲጋራ ወይም በበሽታ የተጎዳ ሳንባ (Diseased / Damaged Lungs)",
    "guide":
        "1. መግቢያና ምንነት\n"
        "• ሳንባ በደረት ውስጥ የሚገኙ ሁለት ለስላሳና የአየር ከረጢቶች (Alveoli) የያዙ የሰውነት አካላት ናቸው።\n"
        "• ዋና ተግባራቸው ከምንተነፍሰው አየር ኦክስጅንን ወደ ደም ዝውውር ማስገባት እና ከሰውነት የሚመጣውን ካርቦን ዳይኦክሳይድ ማስወጣት ነው።\n\n"
        "2. የሚከሰትበት መንገድና መንስኤዎች\n"
        "• የሲጋራ ጭስ፣ አቧራ እና መርዛማ ጋዞች የሳንባ ሕብረ ሕዋሳትን ቀስ በቀስ ያቃጥላሉ ወይም ይጎዳሉ።\n"
        "• እንደ ሳምባ ምች (Pneumonia)፣ ቲቢ (Tuberculosis)፣ ሥር የሰደደ ብሮንካይተስ/COPD እና የሳንባ ካንሰር ያሉ በሽታዎች የሳንባን ስራ ያዳክማሉ።\n\n"
        "3. ዋና ምልክቶችና የጉዳት አደጋዎች\n"
        "• የማያቋርጥ ሳል፣ የትንፋሽ ማጠር፣ የደረት ህመም ወይም ጥብደት፣ የትንፋሽ ድምጽ መቀየር እና ፈጣን ድካም ሊታዩ ይችላሉ።\n"
        "• ህክምና ካልተደረገ የደም ኦክስጅን ማነስ፣ ሥር የሰደደ የመተንፈስ ችግር እና ከባድ የሕይወት ስጋት ሊያስከትል ይችላል።\n\n"
        "4. የመከላከያና የጥንቃቄ እርምጃዎች\n"
        "• ሲጋራ ማጨስንና የጭስ አካባቢዎችን ሙሉ በሙሉ ማስወገድ።\n"
        "• ንጹሕ አየር ማግኘት፣ አዘውትሮ አካላዊ እንቅስቃሴ ማድረግ እና የንጽህና ጥንቃቄዎችን መጠበቅ።\n\n"
        "5. በበሽታው ከተያዙ በኋላ ምን ማድረግ አለብን?\n"
        "• ሳል ወይም የትንፋሽ ችግር ከተከሰተ ሳይዘገዩ ወደ ጤና ተቋም በመሄድ መመርመር።\n"
        "• በሐኪም የታዘዙ መድኃኒቶችን በአግባቡና እስኪጠናቀቁ ድረስ መውሰድ፣ ሲጋራን ሙሉ በሙሉ ማቆም እና የድንገተኛ ምልክቶች (ከባድ የትንፋሽ እጥረት፣ ደም የቀላቀለ ሳል፣ የደረት ህመም) ሲታዩ አስቸኳይ ህክምና ማግኘት።",
  },
  {
    "category": "የመተንፈሻ አካላት መረጃ",
    "name": "የመተንፈሻ አካላት (Respiratory Tract)",
    "mode": "single",
    "photo": "assets/Resparatory.png",
    "photoCaption": "የመተንፈሻ አካላት አወቃቀር፣ ጉዳቶችና ጥንቃቄ (Respiratory Tract)",
    "guide":
        "1. መግቢያና ምንነት\n"
        "• የመተንፈሻ አካላት (Respiratory Tract) የአፍንጫ ቀዳዳን፣ ጉሮሮን (Pharynx/Larynx)፣ የአየር ቧንቧን (Trachea)፣ የአየር ቅርንጫፎችን (Bronchi & Bronchioles) እና ሳንባን ያካትታሉ።\n"
        "• ጤናማ በሚሆኑበት ጊዜ አየር በቀላሉ ወደ ውስጥ እንዲገባና እንዲወጣ ያደርጋሉ፣ እንዲሁም አቧራ፣ ጭስና ተህዋሲያንን ያጣራሉ ወይም ያስወግዳሉ።\n\n"
        "2. የሚከሰትበት መንገድና መንስኤዎች\n"
        "• በቫይረስና በባክቴሪያ ኢንፌክሽኖች (እንደ ጉንፋን፣ የጉሮሮ ኢንፌክሽን፣ ብሮንካይተስ፣ ሳምባ ምች ወይም ቲቢ) የመተንፈሻ መንገድ ሊቆጣ ወይም ሊያብጥ ይችላል።\n"
        "• በሲጋራ ጭስ፣ በአየር ብክለት፣ በአለርጂ ወይም በአስም ምክንያት የአየር መተላለፊያ ቱቦዎች ሊጠቡ ወይም በንፍጥ ሊሞሉ ይችላሉ።\n\n"
        "3. ዋና ምልክቶችና የጉዳት አደጋዎች\n"
        "• የጉሮሮ ህመም ወይም ጭርጭር ማለት፣ ሳል፣ ንፍጥ፣ የትንፋሽ ማጠር፣ የደረት ጥብደት ወይም የማስተንፈስ ድምጽ (Wheezing) ሊከሰቱ ይችላሉ።\n"
        "• ችግሩ ከተባባሰ የአየር ዝውውር በመቀነስ የኦክስጅን እጥረት፣ ከባድ የመተንፈስ ድካም ወይም የሕይወት ስጋት ሊያስከትል ይችላል።\n\n"
        "4. የመከላከያና የጥንቃቄ እርምጃዎች\n"
        "• እጅን በሳሙናና በውሃ በመደበኛነት መታጠብ፣ በሽታ ያለባቸው ሰዎች ጋር ሲቀራረቡ ጥንቃቄ ማድረግ እና ሲጋራና ጭስን ማስወገድ።\n"
        "• የአየር ብክለትን መቀነስ፣ በቂ የአየር ዝውውር ያለው ቦታ መጠቀም እና የአለርጂ ቀስቃሽ ነገሮችን ማወቅና ማስወገድ።\n\n"
        "5. በበሽታው ከተያዙ በኋላ ምን ማድረግ አለብን?\n"
        "• በቂ ውሃና ፈሳሽ መጠጣት፣ ማረፍ እና የሕክምና ባለሙያ ምክር በአግባቡ መከተል።\n"
        "• የትንፋሽ ማጠር፣ ከፍተኛ ትኩሳት፣ የደረት ህመም/ጥብደት፣ ደም የቀላቀለ ሳል ወይም ምልክቶች እየባሱ ሲሄዱ ወዲያውኑ ወደ ሆስፒታል መሄድ።",
  },
  {
    "category": "የሰውነት አካላት ንጽጽር (ጤናማ vs በሽታ)",
    "name": "ጉበት (Liver — ንጹሕ ጉበት vs በመጠጥ የተጎዳ)",
    "mode": "comparison",
    "healthyPhoto": "assets/liver_healthy.png",
    "diseasedPhoto": "assets/liver_diseased.png",
    "healthyCaption": "ንጹሕ እና ጤናማ ጉበት (Healthy / Clean Liver)",
    "diseasedCaption": "በመጠጥ (አልኮል) ወይም በበሽታ የተጎዳ ጉበት (Alcohol-Damaged Liver)",
    "guide":
        "1. መግቢያና ምንነት\n"
        "• ጉበት ከደም ውስጥ መርዛማ ነገሮችን የሚያጣራ፣ ምግብን ለመፈጨት የሚረዳ ሀሞት የሚያመርት፣ ስኳርና ቪታሚኖችን የሚያከማች እና የደም መርጋትን የሚደግፍ ዋና የውስጥ አካል ነው።\n"
        "• ጤናማና ንጹሕ ጉበት ለስላሳ እና የተስተካከለ ቅርጽ ያለው ሲሆን ተግባሩን ያለ እንቅፋት ያከናውናል።\n\n"
        "2. የሚከሰትበት መንገድና መንስኤዎች\n"
        "• የአልኮል (መጠጥ) አዘውትሮ መጠጣት፣ የሄፓታይተስ ቫይረሶች ወይም የስብ መከማቸት የጉበት ሕዋሳትን ይጎዳሉ።\n"
        "• መጀመሪያ የስብ መከማቸት (Fatty Liver)፣ ከዚያ እብጠት (Hepatitis) እና ቆይቶም ጠባሳ/ሰርሆሲስ (Cirrhosis) ሊፈጠር ይችላል።\n\n"
        "3. ዋና ምልክቶችና የጉዳት አደጋዎች\n"
        "• የላይኛው የሆድ ህመም፣ ማቅለሽለሽ ወይም ማስታወክ፣ የዓይን ነጭ ክፍል ወይም ቆዳ ቢጫ መሆን (Jaundice)፣ የሆድ ወይም የእግር እብጠት እና ድካም ሊታዩ ይችላሉ።\n"
        "• ጉዳቱ ሲባባስ የጉበት ድካም (Liver Failure)፣ ከባድ ደም መፍሰስ ወይም የንቃተ ህሊና መቀነስ ሊያስከትል ይችላል።\n\n"
        "4. የመከላከያና የጥንቃቄ እርምጃዎች\n"
        "• የአልኮል መጠጥን ማቆም ወይም መገደብ፣ ባዶ ሆድ ላይ አለመጠጣት፣ የተመጣጠነ ምግብ መመገብ እና ለሄፓታይተስ B ጥንቃቄ/ክትባት ማድረግ።\n\n"
        "5. በበሽታው ከተያዙ በኋላ ምን ማድረግ አለብን?\n"
        "• አልኮልን ሙሉ በሙሉ ማቆም፣ ሐኪም ሳያማክሩ በጉበት ላይ ጫና የሚፈጥሩ መድኃኒቶችን አለመውሰድ እና ቢጫነት ወይም እብጠት ሲታይ ፈጣን ህክምና ማግኘት።",
  },
  {
    "category": "የሰውነት አካላት ንጽጽር (ጤናማ vs በሽታ)",
    "name": "ኩላሊት (Kidneys — ጤናማ vs በሽታ ያጠቃው)",
    "mode": "comparison",
    "healthyPhoto": "assets/kidney_healthy.png",
    "diseasedPhoto": "assets/kidney_diseased.png",
    "healthyCaption": "ጤናማ ኩላሊት (Healthy Kidney)",
    "diseasedCaption": "በበሽታ ወይም በጉዳት የተጠቃ ኩላሊት (Diseased Kidney)",
    "guide":
        "1. መግቢያና ምንነት\n"
        "• ኩላሊቶች ደምን በማጣራት ተረፈ ምርቶችንና ትርፍ ፈሳሽን በሽንት የሚያስወግዱ ሁለት አስፈላጊ አካላት ናቸው።\n"
        "• የውሃና የጨው/ማዕድን ሚዛንን ይጠብቃሉ፣ የደም ግፊትን ይቆጣጠራሉ እንዲሁም ቀይ የደም ሕዋሳት እንዲመረቱ ያግዛሉ።\n\n"
        "2. የሚከሰትበት መንገድና መንስኤዎች\n"
        "• ከፍተኛ የደም ግፊት፣ የስኳር በሽታ፣ የኩላሊት ኢንፌክሽን፣ የኩላሊት ጠጠር ወይም የመድኃኒት አላግባብ አጠቃቀም ኩላሊቶችን ይጎዳሉ።\n"
        "• የማጣራት አቅም ሲቀንስ ቆሻሻና ትርፍ ፈሳሽ በሰውነት ውስጥ ይከማቻሉ።\n\n"
        "3. ዋና ምልክቶችና የጉዳት አደጋዎች\n"
        "• በዓይን ዙሪያ፣ በእግር ወይም በቁርጭምጭሚት እብጠት፣ የሽንት መጠን ወይም ቀለም መለወጥ፣ ድካም፣ የምግብ ፍላጎት ማጣት እና ማቅለሽለሽ ሊታዩ ይችላሉ።\n"
        "• ቁጥጥር ሳይደረግበት ከቆየ ሥር የሰደደ የኩላሊት በሽታ (Chronic Kidney Disease) እና የኩላሊት ስራ ማቆም ሊያስከትል ይችላል።\n\n"
        "4. የመከላከያና የጥንቃቄ እርምጃዎች\n"
        "• የደም ግፊትንና የስኳር መጠንን በመደበኛነት መቆጣጠር፣ ጨው መቀነስ፣ በቂ ውሃ መጠጣት እና ያለሐኪም ትዕዛዝ የህመም ማስታገሻ አለማብዛት።\n\n"
        "5. በበሽታው ከተያዙ በኋላ ምን ማድረግ አለብን?\n"
        "• የኩላሊት ምርመራ ማድረግ፣ የደም ግፊትና የስኳር መድኃኒቶችን በአግባቡ መውሰድ እና የእብጠት ወይም የሽንት ለውጥ ሲታይ ሐኪም ማማከር።",
  },
  {
    "category": "በሲጋራ ምክንያት የሚመጡ በሽታዎች",
    "name": "የሲጋራ ጉዳቶች (Smoking-Related Diseases)",
    "mode": "single",
    "photo": "assets/Smoking-Related Diseases.png",
    "photoCaption": "የሲጋራ ማጨስ በሰውነት ላይ የሚያስከትለው ጉዳት (Smoking-Related Diseases)",
    "guide":
        "1. መግቢያና ምንነት\n"
        "• ሲጋራ ማጨስ ኒኮቲን፣ ታር (Tar) እና በርካታ መርዛማ ጋዞችን ወደ መተንፈሻ አካላትና ወደ ደም ዝውውር ያስገባል።\n"
        "• ኒኮቲን ከፍተኛ ሱስ የሚያስይዝ ሲሆን ሌሎች ጎጂ ኬሚካሎች የአካል ክፍሎችን ቀስ በቀስ ያበላሻሉ።\n\n"
        "2. የሚከሰትበት መንገድና መንስኤዎች\n"
        "• ጭስ የሳንባ ሕብረ ሕዋሳትን ያቃጥላል፣ የደም ሥሮችን ያጠባል እና በሰውነት ውስጥ የኦክስጅን አቅርቦትን ይቀንሳል።\n"
        "• ረጅም ጊዜ ማጨስ የሕዋሳት ጉዳትና የካንሰር እድልን ይጨምራል።\n\n"
        "3. ዋና ምልክቶችና የጉዳት አደጋዎች\n"
        "• ሥር የሰደደ ሳል፣ የትንፋሽ ማጠር፣ የደረት ህመም፣ COPD/ብሮንካይተስ፣ የሳንባና የጉሮሮ ካንሰር፣ የልብ ድካም፣ ስትሮክ እና በእርግዝና ወቅት የፅንስ ጉዳት ሊያስከትል ይችላል።\n\n"
        "4. የመከላከያና የጥንቃቄ እርምጃዎች\n"
        "• ሲጋራን ላለመጀመር ወይም ሙሉ በሙሉ ለማቆም መወሰን፣ ጭስ የሚጨስባቸውን ቦታዎች ማስወገድ።\n\n"
        "5. በበሽታው ከተያዙ በኋላ ምን ማድረግ አለብን?\n"
        "• ሲጋራን ሙሉ በሙሉ ማቆም (በማንኛውም እድሜ ማቆም የጤና ጉዳትን ይቀንሳል)፣ የሳንባና የልብ ምርመራ ማድረግ እና የማያቋርጥ ሳል ወይም የትንፋሽ ችግር ካለ ሐኪም ማማከር።",
  },
  {
    "category": "በመጠጥ (አልኮል) ምክንያት የሚመጡ በሽታዎች",
    "name": "የአልኮል / የመጠጥ ጉዳቶች (Alcohol-Related Diseases)",
    "mode": "single",
    "photo": "assets/Alcohol-Related Diseases.png",
    "photoCaption": "የአልኮል (መጠጥ) አጠቃቀም በሰውነት ላይ የሚያስከትለው ተጽዕኖ (Alcohol-Related Diseases)",
    "guide":
        "1. መግቢያና ምንነት\n"
        "• አልኮል (መጠጥ) በብዛት ወይም በተደጋጋሚ ሲወሰድ በዋናነት በጉበት ይስተናገዳል፤ ነገር ግን ጉበትን፣ ጨጓራን፣ ፓንክሪያስን፣ ልብን፣ ነርቭን እና አእምሮን ሊጎዳ ይችላል።\n\n"
        "2. የሚከሰትበት መንገድና መንስኤዎች\n"
        "• ከፍተኛ የአልኮል መጠን የጉበት ስብ መከማቸትን፣ የጉበት እብጠትን እና የጠባሳ/ሰርሆሲስ ሁኔታን ያስከትላል።\n"
        "• የጨጓራ ሽፋንን ያቆጣል፣ የፓንክሪያስ እብጠት ይፈጥራል እንዲሁም የነርቭ ስርዓትን ያዳክማል።\n\n"
        "3. ዋና ምልክቶችና የጉዳት አደጋዎች\n"
        "• የላይኛው የሆድ ህመም፣ ማቅለሽለሽ፣ የዓይን ወይም የቆዳ ቢጫ መሆን፣ የሆድ/እግር እብጠት፣ የደም ግፊት መጨመር፣ የእጅ/እግር መደንዘዝ ወይም መንቀጥቀጥ እና የማስታወስ ችግር ሊከሰቱ ይችላሉ።\n\n"
        "4. የመከላከያና የጥንቃቄ እርምጃዎች\n"
        "• መጠጥን መቆጣጠር ወይም ሙሉ በሙሉ ማቆም፣ ባዶ ሆድ ላይ አለመጠጣት እና በቂ ውሃና ምግብ መጠቀም።\n\n"
        "5. በበሽታው ከተያዙ በኋላ ምን ማድረግ አለብን?\n"
        "• አልኮልን ማቆም ወይም መቀነስ፣ የጉበትና የጨጓራ ምርመራ ማድረግ እና ቢጫነት፣ ከባድ የሆድ ህመም ወይም የነርቭ ምልክቶች ሲታዩ ህክምና ማግኘት።",
  },
  {
    "category": "በግብረ ሥጋ ግንኙነት የሚተላለፉ በሽታዎች",
    "name": "በግብረ ሥጋ ግንኙነት የሚተላለፉ በሽታዎች (STIs)",
    "mode": "single",
    "photo": "assets/STI.png",
    "photoCaption": "በግብረ ሥጋ ግንኙነት የሚተላለፉ በሽታዎች ጉዳቶችና ጥንቃቄ (STIs)",
    "guide":
        "1. መግቢያና ምንነት\n"
        "• በግብረ ሥጋ ግንኙነት የሚተላለፉ በሽታዎች (STIs) በባክቴሪያ፣ በቫይረስ ወይም በሌሎች ተህዋሲያን አማካኝነት በግብረ ሥጋ ግንኙነት ወቅት የሚተላለፉ ኢንፌክሽኖች ናቸው።\n"
        "• ጨብጥ (Gonorrhea)፣ ቂጥኝ (Syphilis)፣ ክላሚዲያ (Chlamydia)፣ ትሪኮሞናስ፣ የብልት ሄርፒስ፣ ሄፓታይተስ B እና C እንዲሁም HIV ይገኙበታል።\n\n"
        "2. የሚከሰትበት መንገድና መንስኤዎች\n"
        "• ጥንቃቄ በጎደለው የግብረ ሥጋ ግንኙነት (vaginal, anal, or oral sex) ወይም በተበከሉ ፈሳሾች/ቁስሎች ንክኪ ይተላለፋሉ።\n"
        "• አንዳንድ ኢንፌክሽኖች ምልክት ሳያሳዩ ሊቆዩ ይችላሉ፤ ይህም ሳይታወቅ ወደ ሌሎች እንዲተላለፉና ጉዳት እንዲያስከትሉ ያደርጋል።\n\n"
        "3. ዋና ምልክቶችና የጉዳት አደጋዎች\n"
        "• ያልተለመደ የብልት ፈሳሽ፣ የሽንት ማቃጠል ወይም ህመም፣ በብልት ወይም በአካባቢው ቁስል፣ እብጠት፣ ሽፍታ ወይም ማሳከክ እና የታችኛው የሆድ/ዳሌ ህመም ሊከሰቱ ይችላሉ።\n"
        "• ህክምና ሳይደረግባቸው ከቆዩ የዳሌ/የመራቢያ አካላት ኢንፌክሽን (PID)፣ የመሃንነት ስጋት፣ የእርግዝና ችግሮች ወይም ሥር የሰደደ የጤና ጉዳት ሊያስከትሉ ይችላሉ።\n\n"
        "4. የመከላከያና የጥንቃቄ እርምጃዎች\n"
        "• ጥንቃቄ የተሞላበት የግብረ ሥጋ ግንኙነት መጠቀም፣ ታማኝነትን መጠበቅ እና ስጋት ሲኖር ወይም አስፈላጊ ሆኖ ሲገኝ የጤና ምርመራ ማድረግ።\n\n"
        "5. በበሽታው ከተያዙ በኋላ ምን ማድረግ አለብን?\n"
        "• ሳይዘገዩ ወደ ጤና ተቋም ሄዶ በላቦራቶሪ/በሐኪም መመርመር እና የታዘዘውን ሕክምና ሙሉ በሙሉ ማጠናቀቅ።\n"
        "• ራስን በራስ ያልተረጋገጠ መድኃኒት አለመውሰድ፣ ሕክምና እስኪጠናቀቅ የግብረ ሥጋ ግንኙነትን መቆጠብ ወይም መጠንቀቅ እና አስፈላጊ ሆኖ ሲገኝ የቅርብ ግንኙነት ያለውን ሰው (partner) ማማከር/ማሳከም።",
  },
  {
    "category": "ተላላፊ ኢንፌክሽን እና ትኩሳት",
    "name": "ትኩሳት እና ኢንፌክሽን (Fever & Infection)",
    "mode": "single",
    "photo": "assets/fever & Infection.png",
    "photoCaption": "ትኩሳት እና ኢንፌክሽን ምልክቶችና ጥንቃቄ (Fever & Infection)",
    "guide":
        "1. መግቢያና ምንነት\n"
        "• ትኩሳት (Fever) የሰውነት ሙቀት ከመደበኛው በላይ ከፍ የሚልበት ሁኔታ ሲሆን ሰውነት ከኢንፌክሽን ጋር እየታገለ መሆኑን የሚያሳይ ምልክት ነው።\n\n"
        "2. የሚከሰትበት መንገድና መንስኤዎች\n"
        "• በባክቴሪያ፣ በቫይረስ ወይም በጥפጥ/ተህዋሲያን ኢንፌክሽን (የመተንፈሻ ኢንፌክሽን፣ ተቅማጥ/የሆድ ኢንፌክሽን፣ ወባ ወይም ሌሎች ኢንፌክሽኖች) ምክንያት ይከሰታል።\n\n"
        "3. ዋና ምልክቶችና የጉዳት አደጋዎች\n"
        "• ከፍተኛ የሰውነት ሙቀት፣ ብርድ ብርድ ማለት፣ ማላብ፣ ራስ ምታት፣ የሰውነት/የመገጣጠሚያ ህመም እና ድካም ሊታዩ ይችላሉ።\n"
        "• ህክምና ሳይደረግበት ከቆየ ወይም መንስኤው ከባድ ከሆነ የሰውነት ፈሳሽ ማነስ፣ ከባድ ኢንፌክሽን ወይም የንቃተ ህሊና መቀነስ ሊያስከትል ይችላል።\n\n"
        "4. የመከላከያና የጥንቃቄ እርምጃዎች\n"
        "• የግልና የአካባቢ ንጽህና መጠበቅ፣ ንጹሕ ውሃና ምግብ መጠቀም እና ተላላፊ በሽታዎችን መከላከል።\n\n"
        "5. በበሽታው ከተያዙ በኋላ ምን ማድረግ አለብን?\n"
        "• በቂ ውሃና ፈሳሽ መጠጣት፣ ማረፍ እና የሙቀት መጠንን መከታተል።\n"
        "• ከፍተኛ ወይም የቆየ ትኩሳት፣ ከባድ ራስ ምታት፣ የአንገት ጥብደት፣ ማስታወክ፣ የትንፋሽ ማጠር ወይም የቆዳ ሽፍታ ካለ ወዲያውኑ ወደ ጤና ተቋም መሄድ።",
  },
  {
    "category": "ሥር የሰደድ የደም ሥር በሽታ",
    "name": "የደም ግፊት (Hypertension)",
    "mode": "single",
    "photo": "assets/Hypertension.png",
    "photoCaption": "ከፍተኛ የደም ግፊት እና መከላከያ (Hypertension)",
    "guide":
        "1. መግቢያና ምንነት\n"
        "• የደም ግፊት (Hypertension) ደም በደም ሥሮች ግድግዳ ላይ የሚያሳድረው ግፊት ለረጅም ጊዜ ከመደበኛው በላይ የሚቆይበት ሥር የሰደድ ሁኔታ ነው።\n\n"
        "2. የሚከሰትበት መንገድና መንስኤዎች\n"
        "• የጨው መብዛት፣ የአካላዊ እንቅስቃሴ ማነስ፣ የክብደት መጨመር፣ የጭንቀት፣ የአልኮል/ሲጋራ አጠቃቀም ወይም የዘር/እድሜ ተጽዕኖ ሊኖር ይችላል።\n\n"
        "3. ዋና ምልክቶችና የጉዳት አደጋዎች\n"
        "• ብዙውን ጊዜ ምልክት ሳያሳይ ይቆያል፤ አልፎ አልፎ ራስ ምታት፣ ማዞር፣ የዕይታ መደብዘዝ ወይም የደረት ምቾት ማጣት ሊታይ ይችላል።\n"
        "• ቁጥጥር ካልተደረገ የልብ ድካም፣ ስትሮክ (የአንጎል ደም መፍሰስ/መዘጋት) እና የኩላሊት ጉዳት ሊያስከትል ይችላል።\n\n"
        "4. የመከላከያና የጥንቃቄ እርምጃዎች\n"
        "• ጨው መቀነስ፣ አትክልትና ፍራፍሬ ማብዛት፣ ጤናማ ክብደት መጠበቅ፣ አዘውትሮ እንቅስቃሴ ማድረግ እና የደም ግፊትን በመደበኛነት መለካት።\n\n"
        "5. በበሽታው ከተያዙ በኋላ ምን ማድረግ አለብን?\n"
        "• በሐኪም የታዘዙ መድኃኒቶችን በየቀኑ በትክክል መውሰድ (ያለሐኪም አለማቋረጥ)፣ የአኗኗር ዘይቤ ማስተካከል እና ከባድ ራስ ምታት ወይም የደረት ህመም ካለ አስቸኳይ እርዳታ ማግኘት።",
  },
  {
    "category": "ሥር የሰደድ የሜታቦሊዝም በሽታ",
    "name": "የስኳር በሽታ (Diabetes Mellitus)",
    "mode": "single",
    "photo": "assets/diabetes.png",
    "photoCaption": "የስኳር በሽታ ምልክቶችና ቁጥጥር (Diabetes Mellitus)",
    "guide":
        "1. መግቢያና ምንነት\n"
        "• የስኳር በሽታ (Diabetes Mellitus) ሰውነት ኢንሱሊንን በበቂ ሁኔታ ባለማመንጨቱ ወይም በአግባቡ ባለመጠቀሙ የደም ስኳር ከፍ ብሎ የሚቆይበት ሥር የሰደድ የጤና ሁኔታ ነው።\n\n"
        "2. የሚከሰትበት መንገድና መንስኤዎች\n"
        "• በዘር፣ በአመጋገብና በክብደት ለውጥ፣ በአካላዊ እንቅስቃሴ ማነስ ወይም በፓንክሪያስ ኢንሱሊን የማምረት ችግር ሊከሰት ይችላል።\n\n"
        "3. ዋና ምልክቶችና የጉዳት አደጋዎች\n"
        "• ከፍተኛ ጥማት፣ ተደጋጋሚ ሽንት፣ ከፍተኛ ረሃብ ወይም ድካም፣ የክብደት መቀነስ፣ የዕይታ መደብዘዝ እና ቁስል በፍጥነት አለመዳን ሊታዩ ይችላሉ።\n"
        "• ረጅም ጊዜ ቁጥጥር ካልተደረገ የዓይን፣ የኩላሊት፣ የነርቭ፣ የእግር ቁስል/ጉዳት እና የልብ በሽታ ሊያስከትል ይችላል።\n\n"
        "4. የመከላከያና የጥንቃቄ እርምጃዎች\n"
        "• የተመጣጠነ ምግብ መመገብ፣ ስኳርና የተጣሩ ምግቦችን መቀነስ፣ አካላዊ እንቅስቃሴ ማድረግ እና የደም ስኳር መጠንን መከታተል።\n\n"
        "5. በበሽታው ከተያዙ በኋላ ምን ማድረግ አለብን?\n"
        "• የታዘዙ መድኃኒቶችን ወይም ኢንሱሊንን በሐኪም መመሪያ መውሰድ፣ የደም ስኳርን መቆጣጠር፣ የእግር ንጽህናና ቁስል ጥንቃቄ ማድረግ እና የስኳር መጠን በጣም ከፍ ሲል ወይም ሲቀንስ ፈጣን እርዳታ ማግኘት።",
  },
  {
    "category": "ድንገተኛ የነርቭና የጭንቅላት ሁኔታ",
    "name": "የጭንቅላት ደም መፍሰስ (Brain Bleed / Hemorrhage)",
    "mode": "single",
    "photo": "assets/Brain Bleed.png",
    "photoCaption": "የጭንቅላት ደም መፍሰስ እና የድንገተኛ ምልክቶች (Brain Bleed / Hemorrhage)",
    "guide":
        "1. መግቢያና ምንነት\n"
        "• የጭንቅላት ደም መፍሰስ (Brain / Intracranial Hemorrhage) በጭንቅላት ውስጥ ወይም አካባቢ የደም ሥር በመሰበር ደም የሚፈስበት አስቸኳይ የሕክምና ድንገተኛ ሁኔታ ነው።\n\n"
        "2. የሚከሰትበት መንገድና መንስኤዎች\n"
        "• በከፍተኛ የደም ግፊት፣ በጭንቅላት ላይ በሚደርስ ድንገተኛ ግጭት/አደጋ ወይም በደም ሥር ድክመት ምክንያት ሊከሰት ይችላል።\n\n"
        "3. ዋና ምልክቶችና የጉዳት አደጋዎች\n"
        "• ድንገተኛና ከባድ ራስ ምታት፣ ማቅለሽለሽ/ማስታወክ፣ ራስን መሳት፣ የንግግር ወይም የዕይታ መዛባት እና የፊት/እጅ/እግር ድክመት ወይም መደንዘዝ ይታያሉ።\n"
        "• ጊዜ ሳያገኝ ህክምና ካልተደረገ ከባድ የነርቭ ጉዳት ወይም ሕይወት ማጣት ሊያስከትል ይችላል።\n\n"
        "4. የመከላከያና የጥንቃቄ እርምጃዎች\n"
        "• የደም ግፊትን በጥብቅ መቆጣጠር፣ የትራፊክ/የስራ ደህንነትና የጭንቅላት መከላከያ መጠቀም።\n\n"
        "5. በበሽታው ከተያዙ በኋላ ምን ማድረግ አለብን?\n"
        "• ጊዜ ሳያጠፉ ወዲያውኑ ወደ ሆስፒታል መውሰድ፣ ታማሚውን ብቻውን አለመተው እና በሐኪም ሳይታዘዝ መድኃኒት ወይም ምግብ/ፈሳሽ በግዳጅ አለመስጠት።",
  },
  {
    "category": "ድንገተኛ የልብ ሁኔታ",
    "name": "የልብ ስራ ማቆም (Cardiac Arrest)",
    "mode": "single",
    "photo": "assets/cardiac-arrest.png",
    "photoCaption": "የልብ ስራ ማቆም እና አስቸኳይ እርዳታ (Cardiac Arrest)",
    "guide":
        "1. መግቢያና ምንነት\n"
        "• የልብ ስራ ማቆም (Cardiac Arrest) የልብ የኤሌክትሪክ እንቅስቃሴ በድንገት ሲቋረጥ ደምን ወደ ሰውነት መርጨት የሚያቆምበት ከፍተኛ የድንገተኛ ሁኔታ ነው።\n\n"
        "2. የሚከሰትበት መንገድና መንስኤዎች\n"
        "• ከባድ የልብ ምት መዛባት፣ የልብ ድካም/የደም ሥር መዘጋት ወይም ሌሎች ከባድ የልብ ሁኔታዎች ሊያስከትሉት ይችላሉ።\n\n"
        "3. ዋና ምልክቶችና የጉዳት አደጋዎች\n"
        "• ድንገተኛ ራስን መሳት (ምላሽ አለመስጠት) እና መደበኛ አተነፋፈስ ማቆም ወይም በጣም ያልተለመደ አተነፋፈስ ናቸው።\n"
        "• በጥቂት ደቂቃዎች ውስጥ እርዳታ ካልተሰጠ የአእምሮ ጉዳትና ሞት ሊያስከትል ይችላል።\n\n"
        "4. የመከላከያና የጥንቃቄ እርምጃዎች\n"
        "• የልብ ጤናን መጠበቅ፣ የደም ግፊትን፣ ስኳርንና ኮሌስትሮልን መቆጣጠር፣ ሲጋራና ከፍተኛ መጠጥ ማስወገድ።\n\n"
        "5. በበሽታው ከተያዙ በኋላ ምን ማድረግ አለብን?\n"
        "• ወዲያውኑ የድንገተኛ ሕክምና እርዳታ መጥራት፣ የሰለጠነ የመጀመሪያ እርዳታ/CPR በፍጥነት መጀመር እና ወደ ሆስፒታል ማድረስ።",
  },
];

enum _ScreenTier { compactPhone, mediumScreen, wideDesktop }

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
  bool _icd11SearchMode = false;

  List _icd11Items = [];
  final List _icd11Suggestions = [];
  bool _icd11Loaded = false;

  static const String _historyStorageKey = "misrak_chora_chat_history_v1";
  final String apiUrl = "https://misrak-chora-backend.onrender.com/api/ask";
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
    _loadOfflineIcd11();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  _ScreenTier _tierForWidth(double width) {
    if (width < 600) return _ScreenTier.compactPhone;
    if (width < 1024) return _ScreenTier.mediumScreen;
    return _ScreenTier.wideDesktop;
  }

  Future<void> _loadOfflineIcd11() async {
    try {
      final raw = await rootBundle.loadString('assets/icd11_kb.json');
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final loaded = [];
        for (final row in decoded) {
          if (row is Map) {
            loaded.add({
              "code": (row["code"] ?? "").toString().trim(),
              "name": (row["name"] ?? "").toString().trim(),
              "chapter": (row["chapter"] ?? "").toString().trim(),
              "definition": (row["definition"] ?? "").toString().trim(),
              "synonyms": (row["synonyms"] ?? "").toString().trim(),
            });
          }
        }
        if (!mounted) return;
        setState(() {
          _icd11Items = loaded;
          _icd11Loaded = loaded.isNotEmpty;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _icd11Loaded = false;
      });
    }
  }

  void _updateIcd11Suggestions(String rawText) {
    if (!_icd11SearchMode || !_icd11Loaded || _icd11Items.isEmpty) {
      if (_icd11Suggestions.isNotEmpty) {
        setState(() {
          _icd11Suggestions.clear();
        });
      }
      return;
    }

    final q = rawText.trim().toLowerCase();
    if (q.isEmpty) {
      if (_icd11Suggestions.isNotEmpty) {
        setState(() {
          _icd11Suggestions.clear();
        });
      }
      return;
    }

    final found = [];
    for (final raw in _icd11Items) {
      if (raw is Map) {
        final code = (raw["code"] ?? "").toString();
        final name = (raw["name"] ?? "").toString();
        final syns = (raw["synonyms"] ?? "").toString();
        final cLow = code.toLowerCase();
        final nLow = name.toLowerCase();
        final sLow = syns.toLowerCase();

        if (cLow.startsWith(q) ||
            nLow.startsWith(q) ||
            nLow.contains(q) ||
            sLow.contains(q)) {
          found.add({
            "code": code,
            "name": name,
          });
          if (found.length >= 6) break;
        }
      }
    }

    setState(() {
      _icd11Suggestions
        ..clear()
        ..addAll(found);
    });
  }

  String _searchOfflineIcd11(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return "እባክዎ የሚፈልጉትን የICD-11 ኮድ (ለምሳሌ 1A00) ወይም የበሽታ ስም ያስገቡ።";
    }
    if (!_icd11Loaded || _icd11Items.isEmpty) {
      return "የOffline ICD-11 ዳታ (assets/icd11_kb.json) አልተጫነም። እባክዎ pubspec.yaml ውስጥ assets/icd11_kb.json መኖሩን ያረጋግጡ።";
    }

    final exactCode = [];
    for (final raw in _icd11Items) {
      if (raw is Map) {
        final c = (raw["code"] ?? "").toString().toLowerCase();
        if (c == q) exactCode.add(raw);
      }
    }

    final matches = [];
    if (exactCode.isNotEmpty) {
      matches.addAll(exactCode);
    } else {
      for (final raw in _icd11Items) {
        if (raw is Map) {
          final code = (raw["code"] ?? "").toString().toLowerCase();
          final name = (raw["name"] ?? "").toString().toLowerCase();
          final syns = (raw["synonyms"] ?? "").toString().toLowerCase();
          final chap = (raw["chapter"] ?? "").toString().toLowerCase();
          if (code == q ||
              code.startsWith(q) ||
              name.contains(q) ||
              syns.contains(q) ||
              chap.contains(q)) {
            matches.add(raw);
          }
        }
      }
    }

    if (matches.isEmpty) {
      return "በOffline ICD-11 ዝርዝር ውስጥ ለ '$query' የሚዛመድ ኮድ ወይም በሽታ አልተገኘም።";
    }

    final shown = matches.take(15).toList();
    final sb = StringBuffer();
    sb.writeln(
      "የተገኙ የICD-11 በሽታዎች (${matches.length} ተገኝተዋል${matches.length > 15 ? " — የመጀመሪያዎቹ 15" : ""}):\n",
    );
    for (final raw in shown) {
      final item = raw as Map;
      final code = (item["code"] ?? "").toString();
      final name = (item["name"] ?? "").toString();
      final chapter = (item["chapter"] ?? "").toString();
      final syns = (item["synonyms"] ?? "").toString();
      final defn = (item["definition"] ?? "").toString();

      sb.writeln("• ኮድ: $code — $name");
      if (chapter.isNotEmpty) sb.writeln("  ምዕራፍ: $chapter");
      if (syns.isNotEmpty) sb.writeln("  ተመሳሳይ ስሞች: $syns");
      if (defn.isNotEmpty) sb.writeln("  ትርጉም: $defn");
      sb.writeln("");
    }
    return sb.toString().trim();
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

  _ChatSession _ensureActiveSession(String firstPrompt, bool isIcd11) {
    if (_currentSessionId != null) {
      for (final s in _chatHistory) {
        if (s is _ChatSession && s.id == _currentSessionId) {
          return s;
        }
      }
    }

    final titleText = isIcd11 ? "ICD-11: $firstPrompt" : firstPrompt;
    final newSession = _ChatSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: titleText,
      isIcd11Mode: isIcd11,
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
        _icd11Suggestions.clear();
        _isLoading = false;
        _icd11SearchMode = false;
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
    final payload = [];
    for (final m in slice) {
      if (m is Map) {
        payload.add({
          "sender": (m["sender"] ?? "").toString(),
          "text": (m["text"] ?? "").toString(),
        });
      }
    }
    return payload;
  }

  Future<void> _sendQuery([String? customQuery]) async {
    if (_activeView != 'chat') return;
    final query = (customQuery ?? _controller.text).trim();
    if (query.isEmpty || _isLoading) return;

    final bool useOfflineIcd11 = _icd11SearchMode;
    final historyPayload = _buildHistoryPayload();

    setState(() {
      _activeView = 'chat';
      _selectedNav = useOfflineIcd11 ? 'icd11_list' : 'chat';
      _icd11Suggestions.clear();
      _messages.add({"sender": "user", "text": query});
      final session = _ensureActiveSession(query, useOfflineIcd11);
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

    if (!useOfflineIcd11 && _isIdentityQuestion(query)) {
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

    if (useOfflineIcd11) {
      final offlineResult = _searchOfflineIcd11(query);
      setState(() {
        _messages.add({"sender": "ai", "text": offlineResult});
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
              : "ከባክኤንድ ሰርቨሩ ($apiUrl) ጋር መገናኘት አልተቻለም። ያለ ኢንተርኔት ለመፈለግ ከግራ ሜኑ 'ICD-11 Diseases List' ወይም 'Offline Guide' ይምረጡ።",
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
      _icd11SearchMode = session.isIcd11Mode;
      _icd11Suggestions.clear();
      _selectedNav =
          session.isIcd11Mode ? 'icd11_list' : 'history_${session.id}';
      _currentSessionId = session.id;
      _messages
        ..clear()
        ..addAll(_cloneMessages(session.messages));
      _controller.clear();
    });
    _scrollToBottom();
  }

  void _startNewChat({BuildContext? drawerCtx, bool icd11 = false}) {
    if (drawerCtx != null) {
      _closeDrawerIfOpen(drawerCtx);
    }
    setState(() {
      _activeView = 'chat';
      _icd11SearchMode = icd11;
      _icd11Suggestions.clear();
      _selectedNav = icd11 ? 'icd11_list' : 'new_chat';
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

  Widget _buildChatWatermarkLogo({required _ScreenTier tier}) {
    final double wmSize = switch (tier) {
      _ScreenTier.compactPhone => 200,
      _ScreenTier.mediumScreen => 300,
      _ScreenTier.wideDesktop => 400,
    };
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

  Widget _buildPhotoCard({
    required String assetPath,
    required String caption,
    required Color badgeColor,
    required Color borderColor,
    required Color bgColor,
    required _ScreenTier tier,
  }) {
    final double photoHeight = switch (tier) {
      _ScreenTier.compactPhone => 185,
      _ScreenTier.mediumScreen => 215,
      _ScreenTier.wideDesktop => 255,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: photoHeight,
            width: double.infinity,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Center(
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_outlined,
                        size: 32, color: badgeColor),
                    const SizedBox(height: 6),
                    Text(
                      assetPath,
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: badgeColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinglePhotoBox({
    required String assetPath,
    required String caption,
    required _ScreenTier tier,
  }) {
    final double boxSide = switch (tier) {
      _ScreenTier.compactPhone => 270,
      _ScreenTier.mediumScreen => 340,
      _ScreenTier.wideDesktop => 420,
    };
    return Center(
      child: Container(
        width: boxSide,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: boxSide - 20,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Center(
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_not_supported_outlined,
                          size: 32, color: _bgSidebarDeep),
                      const SizedBox(height: 6),
                      Text(
                        assetPath,
                        style: const TextStyle(
                          color: _textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _bgSidebarDeep,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoComparisonBox({
    required String healthyPhoto,
    required String diseasedPhoto,
    required String healthyCaption,
    required String diseasedCaption,
    required _ScreenTier tier,
  }) {
    final leftPhoto = _buildPhotoCard(
      assetPath: healthyPhoto,
      caption: healthyCaption,
      badgeColor: const Color(0xFF14532D),
      borderColor: const Color(0xFF86EFAC),
      bgColor: const Color(0xFFF0FDF4),
      tier: tier,
    );

    final rightPhoto = _buildPhotoCard(
      assetPath: diseasedPhoto,
      caption: diseasedCaption,
      badgeColor: const Color(0xFF7F1D1D),
      borderColor: const Color(0xFFFCA5A5),
      bgColor: const Color(0xFFFEF2F2),
      tier: tier,
    );

    if (tier == _ScreenTier.compactPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          leftPhoto,
          const SizedBox(height: 10),
          rightPhoto,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: leftPhoto),
        const SizedBox(width: 12),
        Expanded(child: rightPhoto),
      ],
    );
  }

  Widget _buildOfflineHandbookPanel({required _ScreenTier tier}) {
    final selectedItem = kOfflineMedicalTopics[_selectedOfflineIndex] as Map;
    final titleText = (selectedItem["name"] ?? "").toString();
    final categoryText = (selectedItem["category"] ?? "").toString();
    final mode = (selectedItem["mode"] ?? "none").toString();
    final healthyPhoto = (selectedItem["healthyPhoto"] ?? "").toString();
    final diseasedPhoto = (selectedItem["diseasedPhoto"] ?? "").toString();
    final healthyCaption = (selectedItem["healthyCaption"] ?? "").toString();
    final diseasedCaption = (selectedItem["diseasedCaption"] ?? "").toString();
    final singlePhoto = (selectedItem["photo"] ?? "").toString();
    final singleCaption = (selectedItem["photoCaption"] ?? "").toString();
    final guideText = (selectedItem["guide"] ?? "").toString();

    final double outerPad = tier == _ScreenTier.compactPhone ? 8 : 16;
    final double innerPad = tier == _ScreenTier.compactPhone ? 12 : 20;

    return Container(
      margin: EdgeInsets.all(outerPad),
      padding: EdgeInsets.all(innerPad),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_rounded, color: _accentBlue, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'የሕክምና መጽሐፍ (Offline Guide)',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFBFDBFE), height: 18),
          Align(
            alignment: Alignment.center,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(kOfflineMedicalTopics.length, (idx) {
                final cond = kOfflineMedicalTopics[idx] as Map;
                final bool active = idx == _selectedOfflineIndex;
                return ChoiceChip(
                  selected: active,
                  selectedColor: _accentBlue,
                  label: Text(
                    (cond["name"] ?? "").toString(),
                    style: TextStyle(
                      color: active ? Colors.white : _textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: tier == _ScreenTier.compactPhone ? 11.5 : 12.5,
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
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(
                  tier == _ScreenTier.compactPhone ? 12 : 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (categoryText.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            categoryText,
                            style: const TextStyle(
                              color: _bgSidebarDeep,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    Center(
                      child: SelectableText(
                        titleText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _bgSidebarDeep,
                          fontSize: switch (tier) {
                            _ScreenTier.compactPhone => 16.5,
                            _ScreenTier.mediumScreen => 18.5,
                            _ScreenTier.wideDesktop => 20.5,
                          },
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Divider(color: Color(0xFFCBD5E1), height: 22),
                    if (mode == "comparison") ...[
                      _buildPhotoComparisonBox(
                        healthyPhoto: healthyPhoto,
                        diseasedPhoto: diseasedPhoto,
                        healthyCaption: healthyCaption,
                        diseasedCaption: diseasedCaption,
                        tier: tier,
                      ),
                      const SizedBox(height: 16),
                    ] else if (mode == "single" && singlePhoto.isNotEmpty) ...[
                      _buildSinglePhotoBox(
                        assetPath: singlePhoto,
                        caption: singleCaption,
                        tier: tier,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: SelectableText(
                        guideText,
                        style: TextStyle(
                          color: _textDark,
                          fontSize:
                              tier == _ScreenTier.compactPhone ? 13.5 : 15,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressPanel({required _ScreenTier tier}) {
    final bool compact = tier == _ScreenTier.compactPhone;
    return Container(
      margin: EdgeInsets.all(compact ? 10 : 16),
      padding: EdgeInsets.all(compact ? 16 : 24),
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
                    fontSize: compact ? 17 : 20,
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

  Widget _buildCreatorPanel({required _ScreenTier tier}) {
    final bool compact = tier == _ScreenTier.compactPhone;
    return Container(
      margin: EdgeInsets.all(compact ? 10 : 16),
      padding: EdgeInsets.all(compact ? 16 : 24),
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
                    fontSize: compact ? 17 : 20,
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

  Widget _buildSidebar({BuildContext? drawerCtx, double width = 268}) {
    return Container(
      width: width,
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
            selected: _activeView == 'chat' &&
                !_icd11SearchMode &&
                _selectedNav == 'new_chat',
            onTap: () => _startNewChat(drawerCtx: drawerCtx, icd11: false),
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
                _icd11Suggestions.clear();
                _controller.clear();
              });
            },
          ),
          const SizedBox(height: 8),
          _SidebarTile(
            icon: Icons.format_list_bulleted_rounded,
            label: 'ICD-11 Diseases List',
            selected: _activeView == 'chat' && _icd11SearchMode,
            onTap: () => _startNewChat(drawerCtx: drawerCtx, icd11: true),
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
                            session.isIcd11Mode
                                ? Icons.format_list_bulleted_rounded
                                : Icons.chat_bubble_outline,
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
                _icd11Suggestions.clear();
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
                _icd11Suggestions.clear();
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
                _icd11Suggestions.clear();
                _controller.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCenterArea({required _ScreenTier tier}) {
    final bool compact = tier == _ScreenTier.compactPhone;
    final double padMargin = compact ? 8 : 16;

    if (_activeView == 'offline_guide') {
      return _buildOfflineHandbookPanel(tier: tier);
    }

    if (_activeView == 'hospital_info') {
      return Container(
        margin: EdgeInsets.all(padMargin),
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
      return _buildAddressPanel(tier: tier);
    }

    if (_activeView == 'creator') {
      return _buildCreatorPanel(tier: tier);
    }

    if (_messages.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 14 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHospitalLogo(
                size: switch (tier) {
                  _ScreenTier.compactPhone => 136,
                  _ScreenTier.mediumScreen => 190,
                  _ScreenTier.wideDesktop => 250,
                },
                highlighted: true,
              ),
              const SizedBox(height: 16),
              Text(
                _icd11SearchMode
                    ? 'ICD-11 Diseases List'
                    : 'Misrak Chora - የምስራቅ ጮራ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _bgSidebarDeep,
                  fontSize: switch (tier) {
                    _ScreenTier.compactPhone => 20,
                    _ScreenTier.mediumScreen => 25,
                    _ScreenTier.wideDesktop => 31,
                  },
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              if (!_icd11SearchMode) ...[
                const SizedBox(height: 8),
                Text(
                  'የምስራቅ ዕዝ ደረጃ 3 ሆስፒታል — የጤና መረጃና ክሊኒካል ድጋፍ\n'
                  'Eastern Command Level 3 Hospital — Health Information and Clinical Support',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _bgSidebarDeep,
                    fontSize: compact ? 13 : 15,
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
                          fontSize: compact ? 12 : 13,
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
                    horizontal: compact ? 12 : 14,
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
                      fontSize: compact ? 11.5 : 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        _buildChatWatermarkLogo(tier: tier),
        ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 24,
            vertical: compact ? 14 : 22,
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
                            horizontal: compact ? 14 : 18,
                            vertical: compact ? 11 : 14,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: compact ? 290 : 700,
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
                          child: SelectableText(
                            text,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 13.5 : 14.5,
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

  Widget _buildIcd11SuggestionBar({required _ScreenTier tier}) {
    if (!_icd11SearchMode || _icd11Suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    final bool compact = tier == _ScreenTier.compactPhone;

    return Container(
      constraints: const BoxConstraints(maxWidth: 780, maxHeight: 190),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF93C5FD), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _icd11Suggestions.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          color: Color(0xFFE2E8F0),
        ),
        itemBuilder: (_, idx) {
          final item = _icd11Suggestions[idx] as Map;
          final code = (item["code"] ?? "").toString();
          final name = (item["name"] ?? "").toString();

          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  color: _accentBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _textDark,
                fontSize: compact ? 12.5 : 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              setState(() {
                _icd11Suggestions.clear();
              });
              _sendQuery(code.isNotEmpty ? code : name);
            },
          );
        },
      ),
    );
  }

  Widget _buildInputBubble({required _ScreenTier tier}) {
    if (_activeView != 'chat') {
      return const SizedBox.shrink();
    }
    final bool compact = tier == _ScreenTier.compactPhone;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 24,
        6,
        compact ? 12 : 24,
        compact ? 12 : 20,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcd11SuggestionBar(tier: tier),
            Container(
              constraints: const BoxConstraints(maxWidth: 780),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 18,
                vertical: compact ? 4 : 6,
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
                  Icon(
                    _icd11SearchMode
                        ? Icons.qr_code_2_rounded
                        : Icons.health_and_safety_outlined,
                    color: _accentBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(
                        color: _textDark,
                        fontSize: compact ? 14 : 15,
                      ),
                      onChanged: (val) => _updateIcd11Suggestions(val),
                      onSubmitted: (_) => _sendQuery(),
                      decoration: InputDecoration(
                        hintText: _icd11SearchMode
                            ? 'የICD-11 ኮድ (ለምሳሌ 1A00) ወይም በሽታ ስም ያስገቡ...'
                            : 'Ask Misrak Chora',
                        hintStyle: TextStyle(
                          color: _textMuted,
                          fontSize: compact ? 14 : 15,
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final _ScreenTier tier = _tierForWidth(screenWidth);

    if (tier == _ScreenTier.compactPhone) {
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
              Expanded(
                child: Text(
                  _icd11SearchMode
                      ? 'ICD-11 Diseases List'
                      : 'Misrak Chora - የምስራቅ ጮራ',
                  style: const TextStyle(
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
            Expanded(child: _buildCenterArea(tier: tier)),
            if (_activeView == 'chat') _buildInputBubble(tier: tier),
          ],
        ),
      );
    }

    final double sidebarWidth = tier == _ScreenTier.mediumScreen ? 225 : 268;

    return Scaffold(
      backgroundColor: _bgMain,
      body: Row(
        children: [
          _buildSidebar(width: sidebarWidth),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildCenterArea(tier: tier)),
                if (_activeView == 'chat') _buildInputBubble(tier: tier),
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