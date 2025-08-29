import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_footer.dart';
import '../src/services/api.dart';

class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> with SingleTickerProviderStateMixin {
  final List<Map<String, String>> _messages = [
    {'sender': 'AI', 'text': 'Hello! How can I help you today?'},
  ];
  bool _isZulu = false; // Language toggle state

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  Widget _buildMessageBubble(Map<String, String> message) {
    bool isUser = message['sender'] == 'User';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[300] : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser
                ? const Radius.circular(16)
                : const Radius.circular(0),
            bottomRight: isUser
                ? const Radius.circular(0)
                : const Radius.circular(16),
          ),
        ),
        child: Text(
          message['text'] ?? '',
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendMessage() async {
    String input = _controller.text.trim();
    if (input.isEmpty || _isSending) return;

    setState(() {
      _messages.add({'sender': 'User', 'text': input});
      _controller.clear();
      _isSending = true;
    });

    _scrollToBottom();

    try {
      final response = await Api.post('/chat', {
        'message': input,
        'language': _isZulu ? 'zulu' : 'english',
      });
      final aiResponse =
          response['reply'] ?? 'Sorry, I could not process that request.';

      setState(() {
        _messages.add({'sender': 'AI', 'text': aiResponse});
        _isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'AI',
          'text': 'Sorry, I encountered an error. Please try again.',
        });
        _isSending = false;
      });

      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),

            // Language toggle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'English',
                      style: TextStyle(
                        color: _isZulu ? Colors.grey : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: _isZulu,
                      onChanged: (value) {
                        setState(() {
                          _isZulu = value;
                          // Update initial message based on language
                          if (_messages.isNotEmpty &&
                              _messages[0]['sender'] == 'AI') {
                            _messages[0] = {
                              'sender': 'AI',
                              'text': _isZulu
                                  ? 'Sawubona! Ngingakusiza kanjani namuhla?'
                                  : 'Hello! How can I help you today?',
                            };
                          }
                        });
                      },
                      activeColor: Colors.blue,
                    ),
                    Text(
                      'isiZulu',
                      style: TextStyle(
                        color: _isZulu ? Colors.blue : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Info section
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 800;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.topLeft,
                        colors: [
                          Colors.blue.shade100,
                          Colors.blue.shade200,
                          Colors.blue.shade300,
                          Colors.blue.shade400,
                        ],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Need help or have questions?",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Chat with the 24/7 available AI assistant to answer any questions and help you get the most out of this experience.",
                                style: TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 20),
                              Image.asset(
                                'assets/images/Picture1.png',
                                height: 200,
                                fit: BoxFit.contain,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      "Need help or have questions?",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Chat with the 24/7 available AI assistant to answer any questions and help you get the most out of this experience.",
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 6,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Image.asset(
                                    'assets/images/Picture1.png',
                                    height: 300,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // Chat box
            Center(
              child: Container(
                width: 900,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 500,
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessageBubble(_messages[index]);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Input + send
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: "Type your message...",
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _isSending ? null : _sendMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade300,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text("Send"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 50),

            // Footer
            CustomFooter(),
          ],
        ),
      ),
    );
  }
}
