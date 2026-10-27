import 'package:flutter/material.dart';
import 'package:medguide/widgets/screen_help.dart';
import 'package:medguide/theme/app_theme.dart';
import 'package:medguide/services/api_client.dart';
import 'package:medguide/services/app_preferences.dart';
import 'package:medguide/screens/shared/medication_commands.dart';
import 'package:medguide/screens/shared/health_trend_commands.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MedicationCommands _medicationCommands =
      const MedicationCommands(ApiMedicationStore());
  final HealthTrendCommands _healthTrendCommands = HealthTrendCommands(
      const ApiHealthTrendSource(), now: DateTime.now);
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'Hello, I’m your RiskSense AI Assistant. Ask about a named medication for reviewed educational information, or ask me to "show my health trends" for a summary of your recorded measurements. To save a medication, use this format: add medication name + routine + dosage. For example, type "add medication metformin + every morning + 500 mg". Put a + between the medication name, routine, and dosage. The routine and dosage are optional: "add medication metformin" also works. Type "view medication" to see your list, or "remove medication + metformin" to remove one. I cannot diagnose or prescribe.',
      isUser: false,
    ),
  ];
  bool _isTyping = false;
  String? _sessionId;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      if (RegExp(r'^(add|view|remove) medication', caseSensitive: false)
              .hasMatch(text) &&
          ApiClient.instance.role?.toUpperCase() != 'PATIENT') {
        if (!mounted) return;
        setState(() {
          _isTyping = false;
          _messages.add(const _ChatMessage(
              text: 'Medication list commands are available to patient accounts only.',
              isUser: false));
        });
        return;
      }
      final medicationReply = await _medicationCommands.handle(text);
      if (medicationReply != null) {
        if (!mounted) return;
        setState(() {
          _isTyping = false;
          _messages.add(_ChatMessage(text: medicationReply, isUser: false));
        });
        _scrollToBottom();
        return;
      }
      final trendReply = ApiClient.instance.role?.toUpperCase() == 'PATIENT'
          ? await _healthTrendCommands.handle(text)
          : null;
      if (trendReply != null) {
        if (!mounted) return;
        setState(() {
          _isTyping = false;
          _messages.add(_ChatMessage(text: trendReply, isUser: false));
        });
        _scrollToBottom();
        return;
      }
      final body = <String, dynamic>{'message': text};
      if (_sessionId != null) body['session_id'] = _sessionId;
      final response = Map<String, dynamic>.from(
          await ApiClient.instance.post('/drug-assistant/chat', data: body));
      _sessionId = response['session_id']?.toString();
      final summary = response['summary']?.toString() ??
          'No reviewed information is available for this enquiry.';
      final safety = response['safety_message']?.toString();
      final status = response['evidence_status']?.toString();
      final claims = (response['claims'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((claim) => claim['content']?.toString().trim() ?? '')
          .where((content) => content.isNotEmpty)
          .toList();
      final sources = (response['sources'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((source) => source['url']?.toString() ?? '')
          .where((url) => Uri.tryParse(url)?.isScheme('https') ?? false)
          .toSet()
          .toList();
      final answer = claims.isEmpty ? summary : claims.join('\n\n');
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
            text: safety == null || safety.isEmpty
                ? answer
                : '$answer\n\n$safety',
            isUser: false,
            evidenceStatus: status,
            sources: sources));
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
            text: 'Your enquiry could not be processed: ${error.message}',
            isUser: false));
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return AnimatedBuilder(
        animation: AppPreferences.instance,
        builder: (context, _) => Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: AppColors.cardWhite,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.psychology_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RiskSense AI Assistant',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Educational Support Only',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                actions: const [
                  ScreenHelpButton(topic: 'Assistant'),
                  SizedBox(width: 8),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(color: AppColors.border, height: 1),
                ),
              ),
              body: Column(
                children: [
                  // Disclaimer bar
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: AppColors.amber.withValues(alpha: 0.08),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14, color: AppColors.amber),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'This assistant provides educational support only. It cannot diagnose conditions.',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Suggested prompts (only on first load)
                  if (_messages.length == 1)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Suggested Questions',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'What are the side effects of metformin?',
                              'Can I take metformin while pregnant?',
                              'Show my health trends',
                              'Show my blood pressure trend',
                              'Add medication…',
                              'View medication',
                              'Remove medication…',
                            ]
                                .map(
                                  (q) => GestureDetector(
                                    onTap: () {
                                      _controller.text = switch (q) {
                                        'Add medication…' => 'add medication ',
                                        'Remove medication…' => 'remove medication ',
                                        _ => q,
                                      };
                                      if (!q.endsWith('…')) _sendMessage();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceBlue,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: AppColors.primaryBlue
                                                .withValues(alpha: 0.2)),
                                      ),
                                      child: Text(
                                        q,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),

                  // Messages list
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isTyping && index == _messages.length) {
                          return const _TypingIndicator();
                        }
                        return _MessageBubble(message: _messages[index]);
                      },
                    ),
                  ),

                  // Input area
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: 'Ask about your health data...',
                                filled: true,
                                fillColor: AppColors.background,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide:
                                      BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide:
                                      BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(
                                      color: AppColors.primaryBlue, width: 1.5),
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _sendMessage,
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ));
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String? evidenceStatus;
  final List<String> sources;
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.evidenceStatus,
    this.sources = const [],
  });
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primaryBlue : AppColors.cardWhite,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
          border: message.isUser ? null : Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!message.isUser && message.evidenceStatus != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: message.evidenceStatus == 'LIMITED_EVIDENCE'
                      ? AppColors.amber.withValues(alpha: 0.12)
                      : AppColors.surfaceBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message.evidenceStatus!.replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: message.evidenceStatus == 'LIMITED_EVIDENCE'
                        ? AppColors.amber
                        : AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SelectableText(
              message.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: message.isUser ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (message.sources.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Sources',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  )),
              ...message.sources.map((url) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SelectableText(url,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryBlue,
                        )),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final opacity = 0.3 +
                  (_controller.value * 0.7) *
                      (i == 0
                          ? 1.0
                          : i == 1
                              ? 0.7
                              : 0.4);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
