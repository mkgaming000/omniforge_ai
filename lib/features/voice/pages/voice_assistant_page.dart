import 'dart:async';
// Voice Assistant Page - live voice chat, STT, TTS, translation
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/errors/failures.dart';
import '../../../core/constants/ai_providers.dart';
import '../../../data/services/ai/ai_provider_factory.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/model_config_entity.dart';
import '../../../injection/injection.dart';

class VoiceAssistantPage extends StatefulWidget {
  const VoiceAssistantPage({super.key});

  @override
  State<VoiceAssistantPage> createState() => _VoiceAssistantPageState();
}

class _VoiceAssistantPageState extends State<VoiceAssistantPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final _speech = stt.SpeechToText();
  final _tts = FlutterTts();
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _speechAvailable = false;
  String _partialTranscript = '';
  final _transcript = <_VoiceLine>[];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (e) => debugPrint('STT error: $e'),
        onStatus: (status) {
          if (status == 'notListening' && _isListening) {
            setState(() => _isListening = false);
            _pulseController.stop();
          }
        },
      );
      if (mounted) setState(() {});
    } catch (_) {
      _speechAvailable = false;
    }
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (_) {
      // TTS not available
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _ModeChip(
                label: 'Live Chat',
                selected: true,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _ModeChip(
                label: 'Translation',
                selected: false,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _ModeChip(
                label: 'Meeting',
                selected: false,
                onTap: () {},
              ),
            ],
          ),
        ),
        Expanded(
          child: _transcript.isEmpty
              ? const _EmptyVoiceState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transcript.length,
                  itemBuilder: (context, index) {
                    final line = _transcript[index];
                    return _TranscriptLine(line: line);
                  },
                ),
        ),
        _buildVoiceControl(),
      ],
    );
  }

  Widget _buildVoiceControl() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6750A4), Color(0xFF00E5FF)],
                    ),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: const Color(0xFF6750A4).withOpacity(0.5),
                              blurRadius: 24 + (_pulseController.value * 12),
                              spreadRadius: 4 + (_pulseController.value * 8),
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    size: 40,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isListening
                ? 'Listening...'
                : _isSpeaking
                    ? 'Speaking...'
                    : 'Tap to start speaking',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available on this device'),
        ),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      _pulseController.stop();
      // If we have a partial transcript, send it to the LLM.
      final userText = _partialTranscript.trim();
      _partialTranscript = '';
      if (userText.isNotEmpty) {
        await _sendToLlm(userText);
      }
      return;
    }

    setState(() {
      _isListening = true;
      _partialTranscript = '';
    });
    unawaited(_pulseController.repeat(reverse: true));

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _partialTranscript = result.recognizedWords;
        });
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _speech.stop();
          setState(() => _isListening = false);
          _pulseController.stop();
          final userText = result.recognizedWords.trim();
          _partialTranscript = '';
          _sendToLlm(userText);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  Future<void> _sendToLlm(String userText) async {
    // Add user line to transcript.
    setState(() {
      _transcript.add(
        _VoiceLine(
          speaker: Speaker.user,
          text: userText,
          timestamp: DateTime.now(),
        ),
      );
      _isSpeaking = true;
    });

    try {
      final factory = getIt<AIProviderFactory>();
      // Try OpenAI first (most common); fall back to auto-select.
      Either<Failure, dynamic> serviceResult =
          await factory.getService(AIProvider.openai);
      if (serviceResult.isLeft()) {
        serviceResult = await factory.autoSelect(
          taskType: ChatTaskType.reasoning,
        );
      }
      if (serviceResult.isLeft()) {
        if (!mounted) return;
        final failure =
            serviceResult.fold((l) => l, (_) => throw StateError(''));
        setState(() {
          _isSpeaking = false;
          _transcript.add(
            _VoiceLine(
              speaker: Speaker.assistant,
              text: 'Sorry, I couldn\'t connect: ${failure.userMessage}',
              timestamp: DateTime.now(),
            ),
          );
        });
        return;
      }
      final service = serviceResult.getOrElse(() => throw StateError(''));

      final result = await service.complete(
        messages: [
          MessageEntity(
            id: 'voice-${DateTime.now().millisecondsSinceEpoch}',
            role: MessageRole.user,
            content: userText,
            createdAt: DateTime.now(),
          ),
        ],
        config: const ModelConfigEntity(
          provider: AIProvider.openai,
          modelId: 'gpt-4o-mini',
          displayName: 'GPT-4o Mini',
          temperature: 0.7,
          maxTokens: 500,
        ),
        systemPrompt: 'You are a helpful voice assistant. Keep responses '
            'concise and conversational (2-3 sentences).',
      );

      if (!mounted) return;
      result.fold(
        (failure) => setState(() {
          _isSpeaking = false;
          _transcript.add(
            _VoiceLine(
              speaker: Speaker.assistant,
              text: 'Error: ${failure.userMessage}',
              timestamp: DateTime.now(),
            ),
          );
        }),
        (response) async {
          final responseText = response as String? ?? '';
          setState(() {
            _transcript.add(
              _VoiceLine(
                speaker: Speaker.assistant,
                text: responseText,
                timestamp: DateTime.now(),
              ),
            );
          });
          // Speak the response.
          try {
            await _tts.speak(responseText);
          } catch (_) {
            setState(() => _isSpeaking = false);
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSpeaking = false;
        _transcript.add(
          _VoiceLine(
            speaker: Speaker.assistant,
            text: 'Something went wrong: $e',
            timestamp: DateTime.now(),
          ),
        );
      });
    }
  }
}

class _VoiceLine {
  const _VoiceLine({
    required this.speaker,
    required this.text,
    required this.timestamp,
  });
  final Speaker speaker;
  final String text;
  final DateTime timestamp;
}

enum Speaker { user, assistant }

class _TranscriptLine extends StatelessWidget {
  const _TranscriptLine({required this.line});
  final _VoiceLine line;

  @override
  Widget build(BuildContext context) {
    final isUser = line.speaker == Speaker.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF6750A4)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? 'You' : 'OmniForge',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isUser
                    ? Colors.white70
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              line.text,
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
    );
  }
}

class _EmptyVoiceState extends StatelessWidget {
  const _EmptyVoiceState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.spatial_audio_off,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 16),
          Text(
            'Start a voice conversation',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Powered by Whisper STT • ElevenLabs TTS • Real-time translation',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
