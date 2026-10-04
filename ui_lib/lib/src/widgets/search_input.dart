import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SearchInput extends StatefulWidget {
  const SearchInput({
    required this.onChanged,
    super.key,
    this.hint = 'Search...',
    this.debounce = const Duration(milliseconds: 300),
    this.initialValue = '',
  });
  final ValueChanged<String> onChanged;
  final String hint;
  final Duration debounce;
  final String initialValue;

  @override
  State<SearchInput> createState() => SearchInputState();
}

class SearchInputState extends State<SearchInput> {
  Timer? _debounceTimer;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(widget.debounce, () {
      widget.onChanged(query);
    });
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ShadInput(
            controller: _controller,
            placeholder: Text(widget.hint),
            keyboardType: TextInputType.text,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: _onSearchChanged,
          ),
        ),
        if (_controller.text.isNotEmpty)
          ShadButton.ghost(
            width: 40,
            height: 40,
            padding: EdgeInsets.zero,
            onPressed: _clear,
            child: const Icon(LucideIcons.x, size: 16),
          ),
      ],
    );
  }
}
