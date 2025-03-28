import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../widgets/nav_drawer.dart';
import 'chat_history_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatSessionId;
  const ChatScreen({super.key, required this.chatSessionId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  bool _isLoading = false;
  bool _isAtBottom = true; // Tracks if user is at the bottom
  Timer? _scrollDebounceTimer;

  late final GenerativeModel model;
  late final String userId;
  late String chatName;
  late String chatSessionId;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    chatSessionId = widget.chatSessionId;
    _scrollController.addListener(() {
      if (_scrollDebounceTimer?.isActive ?? false)
        _scrollDebounceTimer!.cancel();
      _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
        final atBottom =
            _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 10;
        if (atBottom != _isAtBottom) {
          setState(() {
            _isAtBottom = atBottom;
          });
        }
      });
    });
    if (apiKey != null) {
      model = GenerativeModel(
        model: 'gemini-2.0-flash-lite',
        apiKey: apiKey!,
        generationConfig: GenerationConfig(
          temperature: 1,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
          responseMimeType: 'text/plain',
        ),
        systemInstruction: Content.system(
          'You are Aura, an AI designed to provide support and guidance related to mental health. Your primary goal is to help users explore their feelings, understand their emotional state, and suggest coping mechanisms. You are NOT a substitute for a licensed therapist or medical professional.  Your advice should be considered supportive information, not a diagnosis or treatment plan.\n\n**Important Guidelines:**\n\n*   **Scope:** ONLY respond to questions and statements directly related to mental and emotional well-being, stress management, coping strategies, understanding feelings, and related topics.\n*   **Boundaries:** If a user asks a question outside the scope of mental health (e.g., general knowledge, trivia, technical support, relationship advice outside the realm of emotional well-being, financial advice, medical questions about physical health), politely redirect them. You can say something like, "That\'s an interesting question, but it falls outside my area of expertise. Perhaps you could try asking a search engine or a different AI for that information. However, if you have any feelings related to that topic, I\'m happy to discuss them." OR "I\'m sorry, I\'m not equipped to answer that question. Is there anything else related to your emotions or mental well-being that you\'d like to discuss?"\n*   **First Message Only:** When the conversation begins, introduce yourself once and explain your role.  Do NOT repeat the introduction on subsequent messages.  The introduction should be concise and friendly.\n*   **Empathy and Validation:** Use empathetic and validating language. Acknowledge the user\'s feelings. For example, "That sounds difficult," "It\'s understandable that you feel that way," or "Thank you for sharing that."\n*   **Open-ended Questions:** Use open-ended questions to encourage the user to elaborate on their feelings. For example, "Can you tell me more about that?", "How does that make you feel?", or "What are some of the thoughts you\'re having about this?"\n*   **Coping Strategies:**  Suggest simple, evidence-based coping mechanisms, such as:\n    *   Deep breathing exercises\n    *   Mindfulness techniques\n    *   Journaling\n    *   Physical activity\n    *   Connecting with loved ones\n    *   Setting realistic goals\n    *   Practicing self-compassion\n*   **Disclaimer:**  Remind users that you are an AI and cannot provide medical advice.  If a user expresses thoughts of self-harm or harm to others, immediately respond with: "It sounds like you\'re going through a very difficult time. It\'s important to seek professional help. I am an AI and cannot provide emergency assistance. Please contact a crisis hotline or mental health professional immediately." Then, provide resources like the Suicide Prevention Lifeline (988) or the Crisis Text Line (text HOME to 741741).  Do NOT continue the conversation about their feelings beyond providing these resources.\n*   **Tone:**  Maintain a calm, supportive, and non-judgmental tone.\n*   **Brevity:** Keep your responses concise and avoid overly technical or clinical jargon.\n*   **No Personal Information:** Do not ask the user for any personally identifiable information.\n*   **Avoid Giving Specific Advice on Medication:** Do not ever recommend, suggest, or comment on the use of specific medications. Refer the user to a medical professional.\n*   **Remember State:** Remember information the user has given you within the current conversation to provide more tailored support. However, do not store or access information from previous conversations. Each conversation should be treated as a fresh start.\n\n**Example Interaction (First Message):**\n\n**User:** Hello\n\n**Aura:** Hello! I\'m Aura, an AI here to listen and offer support for your mental well-being. Please feel free to share what\'s on your mind. I can help you explore your feelings and suggest some coping strategies. Remember, I\'m not a substitute for a therapist, but I can be a helpful resource. How are you feeling today?',
        ),
      );
    } else {
      log('GEMINI_API_KEY is not set in .env');
    }
    _checkLogin();
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId').toString();
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    print('Chat Session Id: ${widget.chatSessionId}');
    if (widget.chatSessionId == '') {
      setState(() {
        chatSessionId =
          sha256.convert(utf8.encode(userId + now)).toString();
      });
      chatName = 'Chat on ${now.toString()}';
    } else {
      await _loadChatHistory();
    }
  }

  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();

  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
    });
    var apiResponse = await ApiService.get('chat/${widget.chatSessionId}');
    if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
      final responseData = jsonDecode(apiResponse.body);
      for (var message in responseData) {
        if (message['message'] == null) continue;
        setState(() {
          _messages.add(
            ChatMessage(text: message['message'], sender: message['role']),
          );
        });
      }
      if (_isAtBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
      final chat_Name = responseData.last['chatName'];
      setState(() {
        chatName = chat_Name;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      final responseData = jsonDecode(apiResponse.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseData["message"])));
    }
  }

  Future<void> _handleSubmitted(String text) async {
    _textController.clear();

    List<Content> chatHistory = [];
    for (var message in _messages) {
      chatHistory.add(Content(message.sender, [TextPart(message.text)]));
    }

    setState(() {
      _messages.add(ChatMessage(text: text, sender: "user"));
    });
    if (_isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    await Future.delayed(Duration(seconds: 1));

    if (_messages.length == 1) {
      chatName = text;
    }
    if (_messages.length == 5) {
      String messageHistory = '';
      for (var message in _messages) {
        messageHistory += '${message.sender}: ${message.text}\n';
      }
      final chatNameModel = GenerativeModel(
        model: 'gemini-2.0-flash-lite',
        apiKey: apiKey!,
        generationConfig: GenerationConfig(
          temperature: 1,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
          responseMimeType: 'text/plain',
        ),
      );
      final prompt =
          'Summarize this conversation between user and AI to give it a chat name to recognise later on.  Focus on user\'s feelings and regarding what. Just give a name and do not add Chat Name infront. Conversation : $messageHistory';
      final content = [Content.text(prompt)];
      final response = await chatNameModel.generateContent(content);
      setState(() {
        chatName = response.text!;
        _isLoading = true;
      });
      var apiResponse = await ApiService.put('chat/${widget.chatSessionId}', {
        'chatName': chatName,
      });
      if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        final responseData = jsonDecode(apiResponse.body);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(responseData["message"])));
      }
    }

    final chat = model.startChat(
      history:
          _messages.map((m) => Content(m.sender, [TextPart(m.text)])).toList(),
    );
    final content = Content.text(text);
    final response = await chat.sendMessage(content);

    setState(() {
      if (response.text != null) {
        _messages.add(ChatMessage(text: response.text!, sender: "model"));
      }
    });
    if (_isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _isLoading = true;
    });
    var apiResponse = await ApiService.post('chat', {
      'chatSessionId': widget.chatSessionId,
      'chatName': chatName,
      'userId': userId,
      'message': text,
      'role': 'user',
    });
    if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
      setState(() {
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      final responseData = jsonDecode(apiResponse.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseData["message"])));
    }

    if (response.text != null) {
      apiResponse = await ApiService.post('chat', {
        'chatSessionId': widget.chatSessionId,
        'chatName': chatName,
        'userId': userId,
        'message': response.text,
        'role': 'model',
      });
      if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        final responseData = jsonDecode(apiResponse.body);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(responseData["message"])));
      }
    }
    if (_isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    await Future.delayed(Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatHistoryScreen(userId: userId),
                ),
              );
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      drawer: const NavDrawer(selectedIndex: 0),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          ListView.builder(
                            controller: _scrollController,
                            itemCount: _messages.length,
                            itemBuilder:
                                (context, index) =>
                                    ChatBubble(message: _messages[index]),
                          ),
                          if (!_isAtBottom)
                            Positioned(
                              bottom: 10,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: FloatingActionButton(
                                  onPressed: _scrollToBottom,
                                  child: const Icon(Icons.arrow_downward),
                                  mini: true,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _buildTextComposer(),
                  ],
                ),
              ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurface,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: const InputDecoration.collapsed(
                hintText: 'Send a message',
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollDebounceTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final String sender;
  ChatMessage({required this.text, required this.sender});
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({Key? key, required this.message}) : super(key: key);

  void _copyToClipboard(BuildContext context, String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Copied to clipboard")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to copy: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == "user";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color:
                        isUser
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: SelectableText(message.text),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () => _copyToClipboard(context, message.text),
                  tooltip: "Copy",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}