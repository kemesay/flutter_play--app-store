class SelectedExtraOption {
  const SelectedExtraOption({
    required this.extraOptionId,
    required this.quantity,
  });

  final int extraOptionId;
  final int quantity;

  Map<String, dynamic> toJson() => {
        'extraOptionId': extraOptionId,
        'quantity': quantity,
      };
}

