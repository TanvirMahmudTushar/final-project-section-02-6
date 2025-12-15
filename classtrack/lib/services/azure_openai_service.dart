import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AzureOpenAIService {
  final String _endpoint = dotenv.env['AZURE_OPENAI_ENDPOINT'] ?? '';
  final String _apiKey = dotenv.env['AZURE_OPENAI_API_KEY'] ?? '';

  Future<Map<String, dynamic>> generateCourseContent({
    required String courseName,
    required String courseCode,
    String? description,
  }) async {
    try {
      if (_endpoint.isEmpty || _apiKey.isEmpty) {
        throw Exception('Azure OpenAI credentials not configured');
      }

      final prompt = _buildPrompt(courseName, courseCode, description);

      print('🔵 Calling Azure OpenAI API...');
      print('Endpoint: ${_endpoint.split('?').first}');

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json', 'api-key': _apiKey},
            body: jsonEncode({
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are an expert academic advisor and curriculum designer. Generate comprehensive, well-structured course content in JSON format.',
                },
                {'role': 'user', 'content': prompt},
              ],
              'max_tokens': 2000,
              'temperature': 0.7,
            }),
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              print('❌ Request timed out after 60 seconds');
              throw Exception('Request timed out. Please try again.');
            },
          );

      print('✅ Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        print('✅ Content received, length: ${content.length}');

        // Parse the AI response (assuming it returns JSON)
        try {
          final courseContent = jsonDecode(content);
          return {'success': true, 'data': courseContent};
        } catch (e) {
          print('⚠️ Content is not JSON, using as text');
          // If not valid JSON, return as text
          return {
            'success': true,
            'data': {
              'overview': content,
              'topics': [],
              'objectives': [],
              'assignments': [],
            },
          };
        }
      } else {
        print('❌ Error response: ${response.body}');
        return {
          'success': false,
          'error': 'API Error ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Exception: $e');
      return {'success': false, 'error': 'Error: ${e.toString()}'};
    }
  }

  String _buildPrompt(
    String courseName,
    String courseCode,
    String? description,
  ) {
    return '''
Generate a comprehensive course outline for the following course:

Course Name: $courseName
Course Code: $courseCode
${description != null ? 'Description: $description' : ''}

Please provide the following in JSON format:
{
  "overview": "A brief 2-3 sentence overview of the course",
  "objectives": ["Learning objective 1", "Learning objective 2", ...],
  "topics": [
    {
      "week": 1,
      "title": "Topic title",
      "description": "Brief description",
      "subtopics": ["Subtopic 1", "Subtopic 2"]
    }
  ],
  "assignments": [
    {
      "title": "Assignment title",
      "type": "Type (e.g., Project, Quiz, Essay)",
      "description": "Brief description"
    }
  ],
  "resources": ["Recommended resource 1", "Recommended resource 2", ...]
}

Generate content for at least 8-12 weeks of topics.
''';
  }

  Future<Map<String, dynamic>> chatAboutCourse({
    required String courseName,
    required String courseCode,
    required String courseContent,
    required List<Map<String, String>> conversationHistory,
    required String userMessage,
  }) async {
    try {
      if (_endpoint.isEmpty || _apiKey.isEmpty) {
        throw Exception('Azure OpenAI credentials not configured');
      }

      // Build messages with context
      final messages = [
        {
          'role': 'system',
          'content':
              'You are a helpful teaching assistant for the course "$courseName ($courseCode)". Answer questions about the course content, clarify concepts, provide examples, and help students understand the material better. Be concise but informative.',
        },
        {'role': 'system', 'content': 'Course Content:\n$courseContent'},
        ...conversationHistory,
        {'role': 'user', 'content': userMessage},
      ];

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json', 'api-key': _apiKey},
            body: jsonEncode({
              'messages': messages,
              'max_tokens': 800,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return {'success': true, 'message': content};
      } else {
        return {
          'success': false,
          'error': 'Failed to get response: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error: ${e.toString()}'};
    }
  }
}
