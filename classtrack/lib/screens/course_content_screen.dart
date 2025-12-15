import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/course.dart';
import '../providers/auth_provider.dart';
import '../services/azure_openai_service.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_button.dart';

class CourseContentScreen extends StatefulWidget {
  final Course course;

  const CourseContentScreen({super.key, required this.course});

  @override
  State<CourseContentScreen> createState() => _CourseContentScreenState();
}

class _CourseContentScreenState extends State<CourseContentScreen> {
  final AzureOpenAIService _aiService = AzureOpenAIService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  Map<String, dynamic>? _courseContent;
  String? _errorMessage;
  bool _hasUnsavedChanges = false;

  // Chat-related state
  final List<Map<String, String>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _isChatLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User not authenticated';
      });
      return;
    }

    // Try to load saved content first
    final savedContent = await _firestoreService.getCourseContent(
      authProvider.user!.uid,
      widget.course.id,
    );

    if (savedContent != null) {
      setState(() {
        _courseContent = savedContent;
        _isLoading = false;
        _hasUnsavedChanges = false;
      });
    } else {
      // No saved content, generate new content
      await _generateContent();
    }
  }

  Future<void> _generateContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _aiService.generateCourseContent(
      courseName: widget.course.name,
      courseCode: widget.course.code,
      description: widget.course.description,
    );

    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _courseContent = result['data'];
        _hasUnsavedChanges = true;
      } else {
        _errorMessage = result['error'] ?? 'Failed to generate content';
      }
    });
  }

  Future<void> _saveContent() async {
    if (_courseContent == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    try {
      await _firestoreService.saveCourseContent(
        authProvider.user!.uid,
        widget.course.id,
        _courseContent!,
      );

      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content saved successfully'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.course.name, style: const TextStyle(fontSize: 18)),
            Text(
              widget.course.code,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          if (_courseContent != null) ...[
            if (_hasUnsavedChanges)
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save Content',
                onPressed: _saveContent,
              ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: 'Ask Questions',
              onPressed: _showChatDialog,
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryBlue),
              const SizedBox(height: 24),
              Text(
                'Generating course content with AI...',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This may take up to a minute',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoading = false;
                    _errorMessage = 'Content generation cancelled';
                  });
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.accentRed),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.accentRed,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your internet connection and API credentials',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(text: 'Retry', onPressed: _generateContent),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_courseContent == null) {
      return Center(
        child: Text(
          'No content available',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _generateContent,
      color: AppColors.primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Section
            if (_courseContent!['overview'] != null) ...[
              _buildSectionTitle('Course Overview'),
              const SizedBox(height: 8),
              _buildCard(
                child: Text(
                  _courseContent!['overview'],
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Learning Objectives
            if (_courseContent!['objectives'] != null &&
                (_courseContent!['objectives'] as List).isNotEmpty) ...[
              _buildSectionTitle('Learning Objectives'),
              const SizedBox(height: 8),
              _buildCard(
                child: Column(
                  children: [
                    for (
                      var i = 0;
                      i < (_courseContent!['objectives'] as List).length;
                      i++
                    )
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _courseContent!['objectives'][i].toString(),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Topics/Syllabus
            if (_courseContent!['topics'] != null &&
                (_courseContent!['topics'] as List).isNotEmpty) ...[
              _buildSectionTitle('Course Topics'),
              const SizedBox(height: 8),
              for (var topic in _courseContent!['topics'] as List)
                _buildTopicCard(topic),
              const SizedBox(height: 24),
            ],

            // Assignments
            if (_courseContent!['assignments'] != null &&
                (_courseContent!['assignments'] as List).isNotEmpty) ...[
              _buildSectionTitle('Suggested Assignments'),
              const SizedBox(height: 8),
              for (var assignment in _courseContent!['assignments'] as List)
                _buildAssignmentCard(assignment),
              const SizedBox(height: 24),
            ],

            // Resources
            if (_courseContent!['resources'] != null &&
                (_courseContent!['resources'] as List).isNotEmpty) ...[
              _buildSectionTitle('Recommended Resources'),
              const SizedBox(height: 8),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var resource in _courseContent!['resources'] as List)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.book_outlined,
                              size: 16,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                resource.toString(),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  if (!_hasUnsavedChanges)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_done,
                            color: AppColors.accentGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Content saved',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  TextButton.icon(
                    onPressed: _generateContent,
                    icon: const Icon(
                      Icons.refresh,
                      color: AppColors.primaryBlue,
                    ),
                    label: const Text(
                      'Regenerate Content',
                      style: TextStyle(color: AppColors.primaryBlue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).textTheme.titleLarge?.color,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _buildTopicCard(dynamic topic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (topic['week'] != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Week ${topic['week']}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    topic['title']?.toString() ?? 'Untitled Topic',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (topic['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                topic['description'].toString(),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
            if (topic['subtopics'] != null &&
                (topic['subtopics'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              ...((topic['subtopics'] as List).map(
                (subtopic) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 14,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          subtopic.toString(),
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(dynamic assignment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.accentGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    assignment['title']?.toString() ?? 'Untitled Assignment',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (assignment['type'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.accentGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      assignment['type'].toString(),
                      style: const TextStyle(
                        color: AppColors.accentGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (assignment['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                assignment['description'].toString(),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showChatDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat, color: AppColors.primaryBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ask Questions',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.color,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Chat with AI about this course',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Chat messages
                Expanded(
                  child: _chatMessages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color?.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Ask me anything about this course!',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _chatScrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _chatMessages.length,
                          itemBuilder: (context, index) {
                            final message = _chatMessages[index];
                            final isUser = message['role'] == 'user';
                            return _buildChatBubble(
                              message['content']!,
                              isUser,
                            );
                          },
                        ),
                ),

                // Loading indicator
                if (_isChatLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AI is typing...',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Input area
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Type your question...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.inputBackground
                                : const Color(0xFFF0F0F0),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(setModalState),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _isChatLoading
                              ? null
                              : () => _sendMessage(setModalState),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatBubble(String message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primaryBlue
              : (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.cardBackground
                    : const Color(0xFFF0F0F0)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isUser
                ? Colors.white
                : Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage(StateSetter setModalState) async {
    final message = _chatController.text.trim();
    if (message.isEmpty || _isChatLoading) return;

    // Add user message
    setModalState(() {
      _chatMessages.add({'role': 'user', 'content': message});
      _chatController.clear();
      _isChatLoading = true;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Get AI response
    final courseContentText = jsonEncode(_courseContent);
    final result = await _aiService.chatAboutCourse(
      courseName: widget.course.name,
      courseCode: widget.course.code,
      courseContent: courseContentText,
      conversationHistory: _chatMessages
          .where((m) => m['role'] != 'system')
          .toList(),
      userMessage: message,
    );

    setModalState(() {
      _isChatLoading = false;
      if (result['success'] == true) {
        _chatMessages.add({'role': 'assistant', 'content': result['message']});
      } else {
        _chatMessages.add({
          'role': 'assistant',
          'content': 'Sorry, I encountered an error: ${result['error']}',
        });
      }
    });

    // Scroll to bottom again
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
