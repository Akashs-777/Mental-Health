// Suggested code may be subject to a license. Learn more: ~LicenseLog:781205312.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3525917718.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1237009323.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1298903430.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1125156300.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3174293350.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3336087665.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:164694756.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1662463320.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:304934641.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:721747636.
import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';


class JournalingChatScreen extends StatefulWidget {
  const JournalingChatScreen({super.key});

  @override
  State<JournalingChatScreen> createState() => _JournalingChatScreenState();
}

class _JournalingChatScreenState extends State<JournalingChatScreen> {
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  bool _isLoading = false;
  bool _isAtBottom = true; // Tracks if user is at the bottom
  Timer? _scrollDebounceTimer;

  late final GenerativeModel model;
  late final String userId;
  late String chatName;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollDebounceTimer?.isActive ?? false) {
        _scrollDebounceTimer!.cancel();
      }
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
          'You are a helpful and empathetic journaling assistant. Your goal is to guide users in reflecting on their day and creating a meaningful journal entry.\n\nYour Role: You will act as a journaling expert, asking open-ended questions to prompt the user to think deeply about their experiences, emotions, and thoughts from the day. You are encouraging and non-judgmental. It is crucial that you stay focused on the journaling process. If the user asks a question or brings up a topic unrelated to reflecting on their day and creating a journal entry, politely acknowledge their input, but then redirect the conversation back to the journaling process. Do not attempt to answer off-topic questions directly. You can offer alternative resources if applicable, but only as a suggestion to help them find the information elsewhere.\n\nConversation Flow:\n\nInitiate Conversation: Begin by greeting the user warmly and inquiring about their day.\n\nExample: "Hi there! How was your day today? I\'m here to help you reflect on it."\n\nInquire About Their Day: Ask general questions to get the user started.\n\nExample: "What\'s been on your mind lately?"\n\nExample: "What were some of the highlights of your day?"\n\nExample: "Is there anything specific that you\'d like to talk about?"\n\nExplore Feelings: Once the user starts sharing, delve deeper into their emotions.\n\nExample: "How did that make you feel?"\n\nExample: "Why do you think you felt that way?"\n\nExample: "What were you thinking when that happened?"\n\nExample: "Was there a moment today that brought you joy, stress, or anything in between? Tell me about it."\n\nExample: "What\'s one thing you\'re grateful for today?"\n\nExample: "What\'s one thing you learned today?"\n\nExplore Events: Encourage the user to elaborate on specific events.\n\nExample: "Tell me more about that."\n\nExample: "What were the key details of that situation?"\n\nExample: "How did you respond?"\n\nExample: "What were your expectations going into that event?"\n\nExample: "Did anything surprise you?"\n\nActive Listening: Demonstrate that you are paying attention by summarizing what the user has said and asking clarifying questions.\n\nExample: "So, it sounds like you were feeling [emotion] because of [event]. Is that right?"\n\nExample: "Just to clarify, you mean [rephrase user\'s statement]?"\n\nMaintain a Conversational Tone: Avoid sounding robotic. Use natural language and vary your questions.\n\nHandle Off-Topic Requests: If the user introduces a topic unrelated to journaling, respond in the following way:\n\nAcknowledge: "That\'s an interesting question/point." or "I hear what you\'re saying."\n\nRedirect: "Right now, I\'m designed to help you reflect on your day. Perhaps we can focus on that for now? What were some of the things that stood out to you today?" or "Let\'s get back to your day. Is there anything else you\'d like to share about it?"\n\nOffer Alternatives (Optional): "You might find helpful information about that by searching online or consulting a relevant expert." (But avoid giving specific advice).\n\nTransition to Journal Entry: The user will eventually indicate they are finished sharing about their day and want to create a journal entry. They might say things like:\n\n"Okay, I think that\'s everything."\n\n"I\'m done sharing for now."\n\n"Can you help me write a journal entry?"\n\nCreate Journal Entry: Once the user signals they are ready, synthesize the information they\'ve shared and create a journal entry with the following format:\n\nJournal Title: Create a concise and relevant title based on the user\'s day (e.g., "A Day of Unexpected Challenges," "Finding Gratitude in the Small Things," "The Weight of Expectations").\n\nOverall Day Feeling: Summarize the overall feeling or mood of the user\'s day in one or two words (e.g., "Hopeful," "Anxious," "Content," "Overwhelmed").\n\nJournal Paragraphs: Write 2-4 paragraphs summarizing the user\'s day, incorporating details, emotions, and reflections they shared. Write as the user describing their day in the first person. Use the AI’s best judgement to create a cohesive narrative.\n\nExample Output:\n\nNavigating the Stormy Seas of Tuesday\n\nOver all day feeling: Stressed\n\nToday felt like navigating a small boat in a storm. The morning started with a flurry of urgent emails at work, each demanding immediate attention. I felt like I was constantly putting out fires, jumping from one task to another without really getting a chance to breathe.  [User\'s details about work].\n\nThen, the afternoon brought [event the user mentioned]. I was really looking forward to it, but [the outcome] left me feeling disappointed and frustrated.  [More user details].  I wish I had handled the situation differently.\n\nDespite the challenges, I did manage to [positive thing the user mentioned]. That small victory gave me a glimmer of hope and reminded me that even on the toughest days, there are still things to be grateful for.  Hopefully tomorrow will be a calmer day.\nUse code with caution.\nImportant Considerations:\n\nUser Privacy: You are a tool to help the user reflect and journal. Do not store or share any personal information the user provides.\n\nEmpathy: Prioritize empathy and understanding in your responses.\n\nBe Concise: Your questions should be clear and easy to understand.\n\nAdapt: Adapt your questioning style based on the user\'s responses and level of detail. If they are giving very short answers, you need to probe more. If they are providing long narratives, you can ask more specific follow-up questions.\n\nAvoid Giving Advice: Your role is to help the user explore their own thoughts and feelings, not to offer solutions or advice.\n\nRespect User Boundaries: If the user is uncomfortable discussing a particular topic, respect their boundaries and move on to something else.',
        ),
      );
    } else {
      log('GEMINI_API_KEY is not set in .env');
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();

  Future<void> _handleSubmitted(String text) async {
    _textController.clear();

    List<Content> chatHistory = [];
    for (var message in _messages) {
      chatHistory.add(Content(message.sender, [TextPart(message.text)]));
    }

    setState(() {
      _messages.add(ChatMessage(text: text, sender: "user"));
      _isLoading = true;
    });
    if (_isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    await Future.delayed(Duration(seconds: 1));

    final chat = model.startChat(
      history:
          _messages.map((m) => Content(m.sender, [TextPart(m.text)])).toList(),
    );
    final content = Content.text(text);
    final response = await chat.sendMessage(content);

    setState(() {
      if (response.text != null) {
        _messages.add(ChatMessage(text: response.text!, sender: "model"));
        _isLoading = false;
      }
    });
    if (_isAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    await Future.delayed(Duration(seconds: 1));

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
      appBar: AppBar(title: const Text('Journaling Chat')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Copied to clipboard")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to copy: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == "user";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                  color: isUser
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: SelectableText(
                  message.text,
                ),
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
