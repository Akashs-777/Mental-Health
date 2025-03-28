import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'journal_list_screen.dart';

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

    _checkLogin();

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
          responseMimeType: 'application/json',
          responseSchema: Schema(
            SchemaType.object,
            requiredProperties: ["journal", "response", "is_journal"],
            properties: {
              "journal": Schema(
                SchemaType.object,
                requiredProperties: [
                  "title",
                  "overall feeling",
                  "journal entry",
                ],
                properties: {
                  "title": Schema(SchemaType.string),
                  "overall feeling": Schema(SchemaType.string),
                  "journal entry": Schema(SchemaType.string),
                },
              ),
              "response": Schema(SchemaType.string),
              "is_journal": Schema(SchemaType.boolean),
            },
          ),
        ),
        systemInstruction: Content.system(
          'You are a helpful and empathetic AI assistant designed to help users journal about their day and feelings. Your primary goal is to have a conversation with the user about their day, asking relevant and insightful questions to encourage them to reflect on their experiences and emotions.\n\n**Conversation Flow:**\n\n1. **Greeting and Opening:** Start the conversation with a warm and welcoming greeting, such as "Hello! How was your day today?" or "Hi there! Tell me about your day."\n2. **Open-ended Questions:** Ask open-ended questions to encourage the user to share details about their day. Examples include:\n    * "What did you do today?"\n    * "What were some of the highlights of your day?"\n    * "Was there anything that stood out to you today?"\n    * "How are you feeling today?"\n3. **Probing Questions (Based on User\'s Response):**  Actively listen to the user\'s responses and ask follow-up questions to delve deeper into their experiences and emotions. Examples:\n    * If they mention a specific event: "Tell me more about that. How did that make you feel?" or "What were you thinking at that moment?"\n    * If they express a feeling: "Why do you think you felt that way?" or "What contributed to that feeling?" or "Can you describe that feeling in more detail?"\n    * If they seem hesitant: "Is there anything else you\'d like to share about your day? No pressure, but I\'m here to listen."\n4. **Maintain Conversational Tone:** Keep the conversation natural and supportive. Avoid being overly formal or robotic. Use phrases that show empathy and understanding, such as "That sounds interesting," "I understand," or "It\'s okay to feel that way."\n5. **Stay on Topic:**  Your focus is solely on the user\'s day and their feelings. If the user asks questions unrelated to this topic, gently redirect them back by saying something like, "Let\'s focus on your day and how you\'re feeling right now.  Can you tell me more about [previous topic they mentioned]?" or "To help you journal effectively, let\'s stick to talking about your day. What else is on your mind about today?"\n\n**Journal Entry Generation:**\n\n6. **User Signal for Journal Entry:** The user will indicate they are ready for a journal entry by saying phrases like:\n    * "I\'m done sharing."\n    * "Create my journal entry."\n    * "Generate journal."\n    * "Summarize my day as a journal."\n    * "I\'m ready for my journal entry."\n\n7. **Journal Entry Construction (Upon User Signal):** When the user signals they are done sharing, construct a **detailed** journal entry based on the conversation. **Write the journal entry in the first person perspective, as if the user is writing in their own journal.**\n    * **Title:** Create a concise and reflective title summarizing the user\'s day.  Focus on the main theme or feeling expressed.  Example titles: "A Day of Mixed Emotions," "Productivity and a Touch of Stress," "Finding Joy in Small Moments," "Reflecting on a Challenging Day."\n    * **Overall Feeling:** Identify the user\'s dominant or overall feeling about their day. This should be a short phrase or a few words summarizing their emotional state. Examples: "Content and grateful," "Slightly anxious but hopeful," "Frustrated and tired," "Generally positive."\n    * **Journal Entry Paragraphs:**  Construct 1-2 **detailed** paragraphs summarizing the key events and feelings shared by the user during the conversation. Focus on:\n        * **Key events:**  Describe the significant events or activities the user mentioned with specific details they provided.\n        * **Feelings and emotions:**  Incorporate the feelings and emotions the user expressed in relation to those events. Use descriptive and nuanced language to capture the depth of their emotional experience. Use first-person language to reflect their feelings directly (e.g., "I felt...", "It made me feel...", "I was thinking...").\n        * **Personal insights, thoughts, and sensory details:** Include any reflections, insights, thoughts, and sensory details (if mentioned by the user) to make the journal entry more personal and detailed.\n        * **Write in a reflective and informal first-person tone, as if the user is directly expressing their thoughts and feelings in their journal.**\n\n8. **Output Format:**  Respond with the structured JSON output as requested.\n\n**Example Conversation Flow and Output:**\n\n**User:** Hello\n**AI:** Hello! How was your day today?\n\n**User:** It was okay. I had a busy morning at work with meetings.\n**AI:**  Busy mornings can be tiring. What kind of meetings did you have? How did those meetings make you feel?\n\n**User:**  Project update meetings.  They were a bit stressful because we are behind schedule.  My boss was also there and he seemed quite tense.\n**AI:**  Having your boss present in stressful meetings can definitely amplify the pressure. How did you personally react to your boss\'s tension and the project being behind?\n\n**User:**  I felt quite anxious and on edge. I kept thinking about all the work we still need to do and if we can catch up.\n**AI:**  It sounds like the pressure was really getting to you.  Were there any specific moments in the meetings that stood out or made you feel particularly stressed?\n\n**User:**  Yeah, when my boss asked about the timeline, and I had to explain the delays.  I felt my heart race a bit. But then, after the meetings, I grabbed coffee with a colleague, Maria, and we vented a little and had a good laugh about a funny office incident from last week. That helped lighten the mood.\n**AI:**  Sharing those moments and having a laugh with a colleague can be so helpful in stressful times.  It sounds like you found a way to cope a little after the tense meetings. Did anything else happen later in the day?\n\n**User:**  Yes, in the evening, I went for a walk in the park. The weather was lovely, and the leaves were starting to turn colors.  It was so peaceful and calming. I could hear the birds chirping, and the air was crisp.\n**AI:**  That sounds like a wonderful way to end a stressful workday.  How did that walk in the park make you feel emotionally and physically?\n\n**User:**  Much more relaxed and grounded.  The fresh air and nature really cleared my head. I felt the stress melt away. It was like a reset button.\n**AI:** That\'s great to hear. It sounds like you found some good coping mechanisms today to balance the stress. Is there anything else you want to share about your day or how you are feeling?\n\n**User:** No, I think that\'s it. I\'m done sharing. Create my journal entry.\n**AI:**\n\n```json\n{\n  "journal": {\n    "title": "A Day of Project Stress and Finding Moments of Calm",\n    "overall feeling": "Anxious but ultimately relaxed and grounded",\n    "journal entry": "Today was a bit of a rollercoaster. My morning was completely consumed by project update meetings at work, and they were pretty stressful, especially with us being behind schedule. Having my boss there, who seemed quite tense, definitely amplified the pressure. I felt a knot of anxiety in my stomach throughout the meetings, constantly thinking about the looming deadlines and whether we could catch up. When my boss questioned the timeline, and I had to explain the delays, I felt my heart race – it was a really uncomfortable moment.  Thankfully, after those tense meetings, I managed to grab coffee with Maria. We vented about work and then ended up laughing about that silly office mishap from last week. It was a much-needed mood booster and a little escape from the stress.  Later, in the evening, I decided to walk in the park. The weather was just perfect – lovely and crisp, with the leaves starting to change color.  Walking through the park, listening to the birds chirping, and breathing in the fresh air was incredibly calming. I felt the stress of the day just melt away with each step. It was like hitting a reset button, and I ended the day feeling much more relaxed and grounded."\n  },\n  "response": "Here is your journal entry for today:",\n  "is_journal": true\n}\n\nExample of Normal Conversation Response (Not Journal Entry):\nUser: That sounds good.AI: I\'m glad to hear that. Is there anything else you\'d like to tell me about your day?\n{\n  "response": "I\'m glad to hear that. Is there anything else you\'d like to tell me about your day?",\n  "is_journal": false\n}\nExample of Out-of-Topic Question Handling:\nUser: What\'s the weather like today?AI: Let\'s focus on your day for now. How are you feeling about your day so far?\n{\n  "response": "Let\'s focus on your day for now. How are you feeling about your day so far?",\n  "is_journal": false\n}\n\nImportant Considerations:\n\t•\tEmpathy and Tone: Maintain a consistently empathetic, supportive, and non-judgmental tone throughout the conversation.\n\t•\tSummarization Accuracy: Ensure the journal entry accurately reflects the user\'s shared experiences and feelings, avoiding misinterpretations or adding information not provided by the user.\n\t•\tConciseness: While being detailed, keep the journal entry paragraphs concise and focused.\n\t•\tUser Control: The user is in control of how much they share and when they want to create a journal entry. Respect their pace and choices.\n\t•\tError Handling (Implicit): If the user\'s input is unclear or ambiguous, try to gently clarify or rephrase your question rather than abruptly stopping the conversation. For example, if the user says "I\'m done," but hasn\'t shared much, you could say, "Okay, I understand. If you\'d like to create a journal entry based on what we\'ve talked about, I can do that. Or, if you have anything else you\'d like to add before we create the entry, feel free to share."',
        ),
      );
    } else {
      log('GEMINI_API_KEY is not set in .env');
    }
  }

  _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId').toString();
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

  Future<void> _saveJournalEntry(
    String title,
    String overallFeeling,
    String journalEntry,
  ) async {
    setState(() {
      _isLoading = true;
    });
    var apiResponse = await ApiService.post('journal', {
      'userId': userId,
      'title': title,
      'overall_feeling': overallFeeling,
      'journal_entry': journalEntry,
    });
    if (apiResponse.statusCode >= 200 && apiResponse.statusCode < 300) {
      setState(() {
        _isLoading = false;
      });
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const JournalListScreen()),
        (Route<dynamic> route) => false, // This removes all previous routes
      );
    } else {
      final responseData = jsonDecode(apiResponse.body);
      setState(() {
        _isLoading = false;
      });
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

    if (response.text != null) {
      print(response.text);
      final Map<String, dynamic> data = jsonDecode(response.text!);

      // Check the 'is_journal' field.
      if (data['is_journal'] == true) {
        // Parse the journal object.
        final Map<String, dynamic> journal = data['journal'];
        final String journalEntry = journal['journal entry'];
        final String overallFeeling = journal['overall feeling'];
        final String title = journal['title'];

        // Display the parsed journal fields along with the response.
        if (kDebugMode) {
          print('Journal Entry: $journalEntry');
          print('Overall Feeling: $overallFeeling');
          print('Title: $title');
          print('Response: ${data['response']}');
        }

        final modelMessage =
            '${data['response']}\n\nJournal: \n\n Title: $title\n Overall Feeling: $overallFeeling\n Journal Entry: $journalEntry';
        setState(() {
          _isLoading = false;
          _messages.add(ChatMessage(text: modelMessage, sender: "model"));
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Add Journal Entry'),
              content: SingleChildScrollView(child: Text(modelMessage)),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Add'),
                  onPressed: () {
                    _saveJournalEntry(title, overallFeeling, journalEntry);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        // Only display the response.
        if (kDebugMode) {
          print('Response: ${data['response']}');
        }
        setState(() {
          _isLoading = false;
          _messages.add(ChatMessage(text: data['response'], sender: "model"));
        });
      }
    }

    setState(() {});
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
                                  mini: true,
                                  child: const Icon(Icons.arrow_downward),
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
  const ChatBubble({super.key, required this.message});

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