// Search Bar - premium search input with debouncing
import 'dart:async';

import 'package:flutter/material.dart';

class OmniSearchBar extends StatefulWidget {
  const OmniSearchBar({
    super.key,
    required this.onChanged,
    this.hintText = 'Search...',
    this.onSubmitted,
    this.autofocus = false,
    this.debounceMs = 300,
    this.leading,
    this.trailing,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final bool autofocus;
  final int debounceMs;
  final Widget? leading;
  final Widget? trailing;

  @override
  State<OmniSearchBar> createState() => _OmniSearchBarState();
}

class _OmniSearchBarState extends State<OmniSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: widget.leading ?? const Icon(Icons.search, size: 20),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              )
            : widget.trailing,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (value) {
        setState(() {});
        _debounce?.cancel();
        _debounce = Timer(
          Duration(milliseconds: widget.debounceMs),
          () => widget.onChanged(value),
        );
      },
      onSubmitted: widget.onSubmitted,
    );
  }
}
