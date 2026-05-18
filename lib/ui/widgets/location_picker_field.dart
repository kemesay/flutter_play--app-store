import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart' as typeahead;
import 'package:uuid/uuid.dart';

import '../../data/services/place_service.dart';
import '../../model/place_model.dart';

class LocationPickerField extends StatefulWidget {
  const LocationPickerField({
    super.key,
    required this.controller,
    required this.placeService,
    required this.onPlaceSelected,
    required this.label,
    this.sessionToken,
    this.country,
    this.hintText,
    this.helperText,
    this.prefixIcon = Icons.location_on_outlined,
    this.suggestionIcon = Icons.place_outlined,
    this.onCleared,
  });

  final TextEditingController controller;
  final PlaceService placeService;
  final String? sessionToken;
  final ValueChanged<PlaceDetail> onPlaceSelected;
  final String label;
  final String? country;
  final String? hintText;
  final String? helperText;
  final IconData prefixIcon;
  final IconData suggestionIcon;
  final VoidCallback? onCleared;

  @override
  State<LocationPickerField> createState() => _LocationPickerFieldState();
}

class _LocationPickerFieldState extends State<LocationPickerField> {
  late final String _sessionToken;
  String? _lastSelectedSuggestion;

  @override
  void initState() {
    super.initState();
    _sessionToken = widget.sessionToken ?? const Uuid().v4();
  }

  @override
  Widget build(BuildContext context) {
    return typeahead.TypeAheadField<Place>(
      controller: widget.controller,
      suggestionsCallback: (pattern) async {
        if (pattern.trim().isEmpty) return const [];
        final normalizedPattern = pattern.trim().toLowerCase();
        if (_lastSelectedSuggestion == normalizedPattern) {
          return const [];
        }
        try {
          return await widget.placeService.fetchSuggestions(
            pattern,
            sessionToken: _sessionToken,
            country: widget.country,
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Autocomplete error: $e');
          }
          return const [];
        }
      },
      itemBuilder: (context, suggestion) => ListTile(
        leading: Icon(
          widget.suggestionIcon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          suggestion.description,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        dense: true,
      ),
      onSelected: (suggestion) async {
        widget.controller.text = suggestion.description;
        _lastSelectedSuggestion = suggestion.description.trim().toLowerCase();
        try {
          final detail = await widget.placeService.fetchPlaceDetail(
            suggestion.placeId,
            sessionToken: _sessionToken,
          );
          widget.onPlaceSelected(detail);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load place details: $e'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      hideOnEmpty: false,
      hideOnError: true,
      hideOnLoading: false,
      hideOnSelect: true,
      debounceDuration: const Duration(milliseconds: 300),
      builder: (context, textEditingController, focusNode) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText ?? 'Search any location...',
            helperText: widget.helperText,
            prefixIcon: Icon(widget.prefixIcon),
            suffixIcon: textEditingController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      textEditingController.clear();
                      _lastSelectedSuggestion = null;
                      widget.onCleared?.call();
                      focusNode.unfocus();
                    },
                  )
                : null,
            filled: true,
            fillColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.3),
          ),
        );
      },
    );
  }
}
