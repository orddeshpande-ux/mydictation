enum DomainMode {
  legal,
  academic,
  spiritual,
}

extension DomainModeExtension on DomainMode {
  String get displayName {
    switch (this) {
      case DomainMode.legal:
        return 'Legal';
      case DomainMode.academic:
        return 'Academic';
      case DomainMode.spiritual:
        return 'Spiritual';
    }
  }
}
