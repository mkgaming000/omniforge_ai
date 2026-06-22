// Chat Input - text field with attachment, voice, send buttons
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../presentation/blocs/chat/chat_bloc.dart';
import '../../../presentation/blocs/chat/chat_event.dart';
import '../../../presentation/blocs/chat/chat_state.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({super.key});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _attachments = <MessageAttachment>[];
  final _speech = stt.SpeechToText();
  bool _isRecording = false;
  bool _speechAvailable = false;
  String _transcriptBuffer = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) => debugPrint('STT error: $error'),
        onStatus: (status) {
          if (status == 'notListening' && _isRecording) {
            setState(() => _isRecording = false);
          }
        },
      );
      if (mounted) setState(() {});
    } catch (_) {
      _speechAvailable = false;
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_attachments.isNotEmpty)
                  Container(
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _attachments.length,
                      itemBuilder: (context, index) {
                        final a = _attachments[index];
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage(a.thumbnailUrl ?? a.url),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              width: 80,
                              height: 80,
                            ),
                            Positioned(
                              top: 4,
                              right: 12,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _attachments.removeAt(index));
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                if (_isRecording)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.fiber_manual_record,
                          color: Colors.red,
                          size: 12,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _transcriptBuffer.isEmpty
                                ? 'Listening...'
                                : _transcriptBuffer,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                              fontStyle: _transcriptBuffer.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: _pickImage,
                    ),
                    IconButton(
                      icon: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: _isRecording ? Colors.red : null,
                      ),
                      onPressed: _toggleRecording,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 6,
                        enabled: !state.isBusy,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'Message OmniForge AI...',
                          hintStyle: Theme.of(context).textTheme.bodyMedium,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SendButton(
                      isBusy: state.isBusy,
                      onPressed: _send,
                      onStop: () {
                        context
                            .read<ChatBloc>()
                            .add(const StreamingCancelled(null));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<ChatBloc>().add(
          UserMessageSent(
            content: text,
            attachments: _attachments,
          ),
        );
    _controller.clear();
    setState(() => _attachments.clear());
    _focusNode.requestFocus();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      imageQuality: 80,
      limit: AppConstants.maxAttachments,
    );
    if (images.isEmpty) return;

    final attachments = images
        .map(
          (x) => MessageAttachment(
            id: x.path,
            type: AttachmentType.image,
            url: x.path,
            mimeType: x.mimeType,
            name: x.name,
          ),
        )
        .toList();

    setState(() => _attachments.addAll(attachments));
  }

  Future<void> _toggleRecording() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available on this device'),
        ),
      );
      return;
    }

    if (_isRecording) {
      await _speech.stop();
      setState(() {
        _isRecording = false;
        // Flush the accumulated transcript into the input field.
        if (_transcriptBuffer.trim().isNotEmpty) {
          final existing = _controller.text;
          final separator =
              existing.isEmpty || existing.endsWith(' ') ? '' : ' ';
          _controller.text = '$existing$separator${_transcriptBuffer.trim()}';
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        }
        _transcriptBuffer = '';
      });
      _focusNode.requestFocus();
    } else {
      setState(() {
        _isRecording = true;
        _transcriptBuffer = '';
      });
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _transcriptBuffer = result.recognizedWords;
          });
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
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.isBusy,
    required this.onPressed,
    required this.onStop,
  });

  final bool isBusy;
  final VoidCallback onPressed;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6750A4), Color(0xFF00E5FF)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: IconButton(
        icon: isBusy
            ? const Icon(Icons.stop, color: Colors.white)
            : const Icon(Icons.send, color: Colors.white),
        onPressed: isBusy ? onStop : onPressed,
      ),
    );
  }
}
