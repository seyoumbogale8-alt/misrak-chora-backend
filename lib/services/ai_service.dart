import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {

  static Future<String> askAI(String message) async {

    try {

      final response = await http.post(
        Uri.parse(
          "https://misrak-chora-backend.onrender.com/api/ask"
        ),
        headers: {
          "Content-Type":
              "application/json",
        },
        body: jsonEncode({
          "question": message,
        }),
      );

      if (response.statusCode == 200) {

        final data =
            jsonDecode(response.body);

        return data["answer"];
      }

      return "Server Error";
    } catch (e) {

      return "Backend Connection Error: $e";
    }
  }
}