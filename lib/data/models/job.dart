class JobRole {
  const JobRole({
    required this.id,
    required this.title,
    required this.company,
    required this.status,
    required this.shortlisted,
    required this.interviewing,
    required this.offer,
    required this.placed,
  });

  final String id;
  final String title;
  final String company;
  final String status; // 'Open' or 'Filled'
  final int shortlisted;
  final int interviewing;
  final int offer;
  final int placed;
}
