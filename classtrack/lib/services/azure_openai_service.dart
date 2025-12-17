import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  String _cleanText(String text) {
    // Remove markdown formatting
    String cleaned = text;

    // Remove markdown headers (# ## ### etc.)
    cleaned = cleaned.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');

    // Remove bold/italic markers (** __ * _)
    cleaned = cleaned.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'__([^_]+)__'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'_([^_]+)_'), r'$1');

    // Remove code blocks markers
    cleaned = cleaned.replaceAll(RegExp(r'```[a-z]*\n?'), '');
    cleaned = cleaned.replaceAll(RegExp(r'`([^`]+)`'), r'$1');

    // Remove extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
    cleaned = cleaned.trim();

    return cleaned;
  }

  Future<Map<String, dynamic>> generateCourseContent({
    required String courseName,
    required String courseCode,
    String? description,
  }) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception('Groq API key not configured');
      }

      final prompt = _buildPrompt(courseName, courseCode, description);

      print('🔵 Calling Groq API...');
      print('Model: llama-3.3-70b-versatile');

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'llama-3.3-70b-versatile',
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are an expert academic advisor and curriculum designer. Generate comprehensive, well-structured course content in JSON format.',
                },
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.7,
              'max_tokens': 2000,
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
          // Extract JSON from markdown code blocks if present
          String jsonContent = content;
          if (content.contains('```json')) {
            final startIndex = content.indexOf('```json') + 7;
            final endIndex = content.lastIndexOf('```');
            jsonContent = content.substring(startIndex, endIndex).trim();
          } else if (content.contains('```')) {
            final startIndex = content.indexOf('```') + 3;
            final endIndex = content.lastIndexOf('```');
            jsonContent = content.substring(startIndex, endIndex).trim();
          }

          final courseContent = jsonDecode(jsonContent);

          // Clean markdown from all text fields
          if (courseContent is Map) {
            final cleaned = Map<String, dynamic>.from(courseContent);
            if (cleaned['overview'] != null) {
              cleaned['overview'] = _cleanText(cleaned['overview'].toString());
            }
            if (cleaned['topics'] is List) {
              cleaned['topics'] = (cleaned['topics'] as List).map((topic) {
                if (topic is Map) {
                  final cleanTopic = Map<String, dynamic>.from(topic);
                  if (cleanTopic['title'] != null)
                    cleanTopic['title'] = _cleanText(
                      cleanTopic['title'].toString(),
                    );
                  if (cleanTopic['content'] != null)
                    cleanTopic['content'] = _cleanText(
                      cleanTopic['content'].toString(),
                    );
                  return cleanTopic;
                }
                return topic;
              }).toList();
            }
            if (cleaned['objectives'] is List) {
              cleaned['objectives'] = (cleaned['objectives'] as List)
                  .map((obj) => _cleanText(obj.toString()))
                  .toList();
            }
            if (cleaned['assignments'] is List) {
              cleaned['assignments'] = (cleaned['assignments'] as List).map((
                assignment,
              ) {
                if (assignment is Map) {
                  final cleanAssignment = Map<String, dynamic>.from(assignment);
                  if (cleanAssignment['title'] != null)
                    cleanAssignment['title'] = _cleanText(
                      cleanAssignment['title'].toString(),
                    );
                  if (cleanAssignment['description'] != null)
                    cleanAssignment['description'] = _cleanText(
                      cleanAssignment['description'].toString(),
                    );
                  return cleanAssignment;
                }
                return assignment;
              }).toList();
            }
            return {'success': true, 'data': cleaned};
          }

          return {'success': true, 'data': courseContent};
        } catch (e) {
          print('⚠️ Content is not JSON, using as text');
          // If not valid JSON, return as text
          return {
            'success': true,
            'data': {
              'overview': _cleanText(content),
              'topics': [],
              'objectives': [],
              'assignments': [],
            },
          };
        }
      } else if (response.statusCode == 429) {
        print('❌ Quota exceeded error');
        return {
          'success': false,
          'error': 'Groq API quota exceeded. Please try again later.',
        };
      } else {
        print('❌ Error response: ${response.body}');
        return {
          'success': false,
          'error':
              'API Error ${response.statusCode}. Please check your API key and try again.',
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
      if (_apiKey.isEmpty) {
        throw Exception('Groq API key not configured');
      }

      // Build messages with context
      final messages = [
        {
          'role': 'system',
          'content':
              'You are a helpful teaching assistant for the course "$courseName ($courseCode)". Answer questions about the course content, clarify concepts, provide examples, and help students understand the material better. Be concise but informative. Course Content:\n$courseContent',
        },
        ...conversationHistory,
        {'role': 'user', 'content': userMessage},
      ];

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'llama-3.3-70b-versatile',
              'messages': messages,
              'temperature': 0.7,
              'max_tokens': 800,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return {'success': true, 'message': _cleanText(content)};
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
