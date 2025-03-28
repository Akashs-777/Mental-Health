class JournalModel {
  final String journalId;
  final String title;
  final String overallFeeling;
  final String journalEntry;
  final String createdAt;

  JournalModel({
    required this.journalId,
    required this.title,
    required this.overallFeeling,
    required this.journalEntry,
    required this.createdAt,
  });

  factory JournalModel.fromJson(Map<String, dynamic> json) {
    return JournalModel(
      journalId: json['_id'],
      title: json['title'],
      overallFeeling: json['overall_feeling'],
      journalEntry: json['journal_entry'],
      createdAt: json['datetime'],
    );
  }
}