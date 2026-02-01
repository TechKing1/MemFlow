import 'package:equatable/equatable.dart';

class CaseModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final String status;
  final Map<String, dynamic>? metadata;

  const CaseModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.status,
    this.metadata,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    createdAt,
    status,
    metadata,
  ];
}

class CaseStatus extends Equatable {
  final String caseId;
  final String status;
  final int progress;
  final String? currentTask;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const CaseStatus({
    required this.caseId,
    required this.status,
    required this.progress,
    this.currentTask,
    this.startedAt,
    this.completedAt,
  });

  factory CaseStatus.fromJson(Map<String, dynamic> json) {
    return CaseStatus(
      caseId: json['case_id'].toString(),
      status: json['status'] as String,
      progress: json['progress'] as int,
      currentTask: json['current_task'] as String?,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    caseId,
    status,
    progress,
    currentTask,
    startedAt,
    completedAt,
  ];
}

class CaseReport {
  final String caseId;
  final Map<String, dynamic> reportData;
  final DateTime generatedAt;

  CaseReport({
    required this.caseId,
    required this.reportData,
    required this.generatedAt,
  });

  factory CaseReport.fromJson(Map<String, dynamic> json) {
    return CaseReport(
      caseId: json['case_id'].toString(),
      reportData: json['report_data'] as Map<String, dynamic>,
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );
  }
}
