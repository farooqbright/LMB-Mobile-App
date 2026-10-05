class SchoolAnnouncement {
  const SchoolAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    this.branchId,
    this.branchName,
    this.publishedAt,
    this.publishedLabel,
    this.isToday = false,
    this.author,
  });

  final int id;
  final String title;
  final String body;
  final int? branchId;
  final String? branchName;
  final String? publishedAt;
  final String? publishedLabel;
  final bool isToday;
  final String? author;

  factory SchoolAnnouncement.fromJson(Map<String, dynamic> json) {
    return SchoolAnnouncement(
      id: _asInt(json['id']) ?? 0,
      title: (json['title'] ?? '').toString().trim(),
      body: (json['body'] ?? '').toString().trim(),
      branchId: _asInt(json['branch_id']),
      branchName: _nullableString(json['branch_name']),
      publishedAt: _nullableString(json['published_at']),
      publishedLabel: _nullableString(json['published_label']),
      isToday: json['is_today'] == true,
      author: _nullableString(json['author']),
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
