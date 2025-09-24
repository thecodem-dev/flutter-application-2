import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_footer.dart';
import '../src/services/api.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';

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
  
  // Voice recording variables
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _isPlayingAudio = false;
  
  // Animation controller for octopus
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Audio player for playing responses
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    
    // Initialize recorder
    _initRecorder();
    
    // Listen to audio player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlayingAudio = state == PlayerState.playing;
      });
      
      if (state == PlayerState.playing) {
        _startSpeakingAnimation();
      } else if (state == PlayerState.completed) {
        _stopSpeakingAnimation();
      }
    });
  }
  
  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
  }
  
  void _startSpeakingAnimation() {
    _animationController.repeat(reverse: true);
  }
  
  void _stopSpeakingAnimation() {
    _animationController.stop();
    _animationController.value = 0;
  }

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['text'] ?? '',
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            if (message.containsKey('audioUrl') && message['audioUrl'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: IconButton(
                  icon: Icon(
                    _isPlayingAudio ? Icons.stop : Icons.play_arrow,
                    color: isUser ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () => _playAudioMessage(message['audioUrl']!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _playAudioMessage(String audioUrl) async {
    if (_isPlayingAudio) {
      await _audioPlayer.stop();
    } else {
      await _audioPlayer.play(UrlSource(audioUrl));
    }
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

  // Start voice recording
  Future<void> _startRecording() async {
    try {
      await _recorder.startRecorder(toFile: 'audio_message');
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  // Stop voice recording and send for transcription
  Future<void> _stopRecording() async {
    try {
      String? path = await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
      });
      
      if (path != null) {
        await _sendAudioForTranscription(path);
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  // Send audio file to server for transcription
  Future<void> _sendAudioForTranscription(String audioPath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${Api.baseUrl}/speech-to-text'));
      request.files.add(await http.MultipartFile.fromPath('audio', audioPath));
      request.fields['language'] = _isZulu ? 'zulu' : 'english';
      
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var result = String.fromCharCodes(responseData);
        // Parse the JSON response
        // Note: You might want to use a JSON decoder here based on your API response format
        _controller.text = result; // Assuming the response contains the transcribed text
        _sendMessage(); // Automatically send the transcribed message
      }
    } catch (e) {
      print('Error sending audio for transcription: $e');
    }
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
        'generateAudio': true, // Request audio response
      });
      
      final aiResponse = response['reply'] ?? 'Sorry, I could not process that request.';
      final audioUrl = response['audioUrl'];

      setState(() {
        _messages.add({
          'sender': 'AI', 
          'text': aiResponse,
          if (audioUrl != null) 'audioUrl': audioUrl,
        });
        _isSending = false;
      });

      _scrollToBottom();
      
      // Auto-play audio response if available
      if (audioUrl != null) {
        await _audioPlayer.play(UrlSource(audioUrl));
      }
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
  void dispose() {
    _recorder.closeRecorder();
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
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

            // Language toggle and voice recording button
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
                    const SizedBox(width: 20),
                    // Voice recording button
                    IconButton(
                      icon: Icon(
                        _isRecording ? Icons.mic_off : Icons.mic,
                        color: _isRecording ? Colors.red : Colors.blue,
                      ),
                      onPressed: () {
                        if (_isRecording) {
                          _stopRecording();
                        } else {
                          _startRecording();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Info section with animated octopus 
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
                              // Animated octopus image with thinking/talking states
                              Center(
                                child: Column(
                                  children: [
                                    ScaleTransition(
                                      scale: _animation,
                                      child: _isSending
                                          ? Image.asset(
                                              'assets/images/Disa_Thinking.png', // Thinking image
                                              height: 150,
                                              fit: BoxFit.contain,
                                            )
                                          : _isPlayingAudio
                                              ? Image.asset(
                                                  'assets/images/Disa_Talking.png', // Talking image
                                                  height: 150,
                                                  fit: BoxFit.contain,
                                                )
                                              : Image.asset(
                                                  'assets/images/Disa_Normal.png', // Normal image
                                                  height: 150,
                                                  fit: BoxFit.contain,
                                                ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (_isSending)
                                      const Text(
                                        "Thinking...",
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    else if (_isPlayingAudio)
                                      const Text(
                                        "Speaking...",
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
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
                                  children: [
                                    const Text(
                                      "Need help or have questions?",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      "Chat with the 24/7 available AI assistant to answer any questions and help you get the most out of this experience.",
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(height: 20),
                                    if (_isSending)
                                      const Text(
                                        "Thinking...",
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      )
                                    else if (_isPlayingAudio)
                                      const Text(
                                        "Speaking...",
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 6,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ScaleTransition(
                                        scale: _animation,
                                        child: _isSending
                                            ? Image.asset(
                                                'assets/images/Disa_Thinking.png', // Thinking image
                                                height: 250,
                                                fit: BoxFit.contain,
                                              )
                                            : _isPlayingAudio
                                                ? Image.asset(
                                                    'assets/images/Disa_Talking.png', // Talking image
                                                    height: 250,
                                                    fit: BoxFit.contain,
                                                  )
                                                : Image.asset(
                                                    'assets/images/Disa_Normal.png', // Normal image
                                                    height: 250,
                                                    fit: BoxFit.contain,
                                                  ),
                                      ),
                                      const SizedBox(height: 10),
                                      if (_isSending)
                                        const Text(
                                          "Thinking...",
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      else if (_isPlayingAudio)
                                        const Text(
                                          "Speaking...",
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
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

                    // Input + send + record buttons
                    Row(
                      children: [
                        // Voice recording button
                        IconButton(
                          icon: Icon(
                            _isRecording ? Icons.mic_off : Icons.mic,
                            color: _isRecording ? Colors.red : Colors.blue,
                          ),
                          onPressed: () {
                            if (_isRecording) {
                              _stopRecording();
                            } else {
                              _startRecording();
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        
                        // Text input
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: "Type your message or use voice...",
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
                        
                        // Send button
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
                    
                    // Recording indicator
                    if (_isRecording)
                      const Text(
                        "Recording... Speak now",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
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