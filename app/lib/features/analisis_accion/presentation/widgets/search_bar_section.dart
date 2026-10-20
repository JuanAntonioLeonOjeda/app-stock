import 'package:flutter/material.dart';

/// Campo de búsqueda. Solo busca al confirmar (botón o intro), nunca
/// mientras se escribe (criterio 2).
class SearchBarSection extends StatefulWidget {
  const SearchBarSection({
    super.key,
    required this.enabled,
    required this.onSearch,
  });

  final bool enabled;
  final ValueChanged<String> onSearch;

  @override
  State<SearchBarSection> createState() => _SearchBarSectionState();
}

class _SearchBarSectionState extends State<SearchBarSection> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    widget.onSearch(_textController.text);
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _textController,
    enabled: widget.enabled,
    textInputAction: TextInputAction.search,
    onSubmitted: (_) => _submit(),
    decoration: InputDecoration(
      hintText: 'Nombre o ticker: Apple, AAPL, Tesco...',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: IconButton(
        tooltip: 'Buscar',
        icon: const Icon(Icons.arrow_forward),
        onPressed: widget.enabled ? _submit : null,
      ),
    ),
  );
}
