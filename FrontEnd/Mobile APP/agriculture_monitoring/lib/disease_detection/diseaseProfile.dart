class DiseaseProfile {
  final String name;
  final String severity;
  final String harmfulness;
  final List<String> prevention;
  final String treatment;
  final List<String> pesticide;
  final double confidence;

  DiseaseProfile({
    required this.name,
    required this.severity,
    required this.harmfulness,
    required this.prevention,
    required this.treatment,
    required this.pesticide,
    required this.confidence,
  });

  factory DiseaseProfile.fromJson(Map<String, dynamic> json) {
    return DiseaseProfile(
      name: json['name'] as String,
      severity: json['severity'] as String,
      harmfulness: json['harmfulness'] as String,
      prevention: json['prevention'] is List
          ? List<String>.from(json['prevention'])
          : [json['prevention'] as String],
      treatment: json['treatment'] as String,
      pesticide: json['pesticide'] is List
          ? List<String>.from(json['pesticide'])
          : [json['pesticide'] as String],
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}
