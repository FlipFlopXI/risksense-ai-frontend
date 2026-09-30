class MockUser {
  static const String patientName = 'Sarah Mitchell';
  static const String clinicianName = 'Dr. James Osei';
  static const String adminName = 'Admin Console';
  static const String patientEmail = 'sarah.mitchell@email.com';
}

class MockPrediction {
  final String condition;
  final double riskScore;
  final String date;
  final String riskLevel;

  const MockPrediction({
    required this.condition,
    required this.riskScore,
    required this.date,
    required this.riskLevel,
  });
}

final List<MockPrediction> mockHistory = [
  const MockPrediction(
      condition: 'Diabetes Risk',
      riskScore: 0.72,
      date: 'Feb 19, 2026',
      riskLevel: 'High'),
  const MockPrediction(
      condition: 'Heart Disease Risk',
      riskScore: 0.41,
      date: 'Feb 19, 2026',
      riskLevel: 'Moderate'),
  const MockPrediction(
      condition: 'Drug Response Risk',
      riskScore: 0.18,
      date: 'Feb 12, 2026',
      riskLevel: 'Low'),
  const MockPrediction(
      condition: 'Diabetes Risk',
      riskScore: 0.68,
      date: 'Jan 30, 2026',
      riskLevel: 'High'),
  const MockPrediction(
      condition: 'Heart Disease Risk',
      riskScore: 0.38,
      date: 'Jan 30, 2026',
      riskLevel: 'Moderate'),
];

final List<Map<String, dynamic>> mockPatients = [
  {
    'name': 'Sarah Mitchell',
    'age': 42,
    'id': 'PT-00421',
    'riskLevel': 'High',
    'lastVisit': 'Feb 19, 2026',
    'condition': 'Diabetes Risk: 72%',
  },
  {
    'name': 'Marcus Thompson',
    'age': 58,
    'id': 'PT-00389',
    'riskLevel': 'Moderate',
    'lastVisit': 'Feb 17, 2026',
    'condition': 'Heart Disease: 41%',
  },
  {
    'name': 'Aisha Patel',
    'age': 35,
    'id': 'PT-00411',
    'riskLevel': 'Low',
    'lastVisit': 'Feb 15, 2026',
    'condition': 'Drug Response: 18%',
  },
  {
    'name': 'Robert Kim',
    'age': 67,
    'id': 'PT-00399',
    'riskLevel': 'High',
    'lastVisit': 'Feb 14, 2026',
    'condition': 'Diabetes Risk: 81%',
  },
];

final List<Map<String, dynamic>> mockAuditLogs = [
  {
    'timestamp': '2026-02-19 14:23:11',
    'user': 'dr.osei@clinic.com',
    'action': 'View Patient Record',
    'ip': '192.168.1.44',
  },
  {
    'timestamp': '2026-02-19 13:55:02',
    'user': 'sarah.m@email.com',
    'action': 'Run Risk Analysis',
    'ip': '10.0.0.112',
  },
  {
    'timestamp': '2026-02-19 12:10:30',
    'user': 'admin@medsurrogate.ai',
    'action': 'Model Version Update',
    'ip': '192.168.1.1',
  },
  {
    'timestamp': '2026-02-19 11:44:18',
    'user': 'dr.chen@clinic.com',
    'action': 'Generate PDF Report',
    'ip': '192.168.1.67',
  },
  {
    'timestamp': '2026-02-19 10:30:00',
    'user': 'robert.k@email.com',
    'action': 'Login Success',
    'ip': '10.0.0.88',
  },
];
