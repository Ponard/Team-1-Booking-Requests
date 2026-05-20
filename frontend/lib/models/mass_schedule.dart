class MassSchedule {
  final int? id;
  final int parishId;
  final String? parishName;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int? priestId;
  final String? priestName;
  final String? intentionCutoffTime;
  final bool isActive;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  MassSchedule({
    this.id,
    required this.parishId,
    this.parishName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.priestId,
    this.priestName,
    this.intentionCutoffTime,
    this.isActive = true,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory MassSchedule.fromJson(Map<String, dynamic> json) {
    return MassSchedule(
      id: json['id'],
      parishId: json['parishId'],
      parishName: json['parish']?['name'],
      dayOfWeek: json['dayOfWeek'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      priestId: json['priestId'],
      priestName: json['assignedPriest'] != null
          ? '${json['assignedPriest']['firstName']} ${json['assignedPriest']['lastName']}'
          : null,
      intentionCutoffTime: json['intentionCutoffTime'],
      isActive: json['isActive'] ?? true,
      notes: json['notes'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'parishId': parishId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      if (priestId != null) 'priestId': priestId,
      if (intentionCutoffTime != null) 'intentionCutoffTime': intentionCutoffTime,
      'isActive': isActive,
      if (notes != null) 'notes': notes,
    };
  }

  MassSchedule copyWith({
    int? id,
    int? parishId,
    String? parishName,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    int? priestId,
    String? priestName,
    String? intentionCutoffTime,
    bool? isActive,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return MassSchedule(
      id: id ?? this.id,
      parishId: parishId ?? this.parishId,
      parishName: parishName ?? this.parishName,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      priestId: priestId ?? this.priestId,
      priestName: priestName ?? this.priestName,
      intentionCutoffTime: intentionCutoffTime ?? this.intentionCutoffTime,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
