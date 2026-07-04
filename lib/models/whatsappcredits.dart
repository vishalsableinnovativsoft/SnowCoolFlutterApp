class WhatsAppCredits {
  final int remainingCredits;

  WhatsAppCredits({
    required this.remainingCredits,
  });

  factory WhatsAppCredits.fromResponse(String responseBody) {
    final trimmed = responseBody.trim();
    final remaining = int.tryParse(trimmed) ?? 0;

    return WhatsAppCredits(
      remainingCredits: remaining,
    );
  }
}