class Intention {
  final int? id;
  final int? userId;
  final int? parishId;
  final String? parishName;
  final DateTime massDate;
  final String intentionType;
  final String? intentionFor;
  final String? specialNotes;
  final double? offeringAmount;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Intention({
    this.id,
    this.userId,
    this.parishId,
    this.parishName,
    required this.massDate,
    required this.intentionType,
    this.intentionFor,
    this.specialNotes,
    this.offeringAmount,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Intention.fromJson(Map<String, dynamic> json) {
    return Intention(
      id: json['id'],
      userId: json['userId'],
      parishId: json['parishId'],
      parishName: json['parishName'] ??
          json['parish']?['name'], // Include parish data if available
      massDate: DateTime.parse(json['massDate']),
      intentionType: json['intentionType'],
      intentionFor: json['intentionFor'],
      specialNotes: json['specialNotes'],
      offeringAmount: json['offeringAmount']?.toDouble(),
      status: json['status'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'parishId': parishId,
      'parishName': parishName,
      'massDate': massDate.toIso8601String(),
      'intentionType': intentionType,
      'intentionFor': intentionFor,
      'specialNotes': specialNotes,
      'offeringAmount': offeringAmount,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Intention copyWith({
    int? id,
    int? userId,
    int? parishId,
    String? parishName,
    DateTime? massDate,
    String? intentionType,
    String? intentionFor,
    String? specialNotes,
    double? offeringAmount,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Intention(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      parishId: parishId ?? this.parishId,
      parishName: parishName ?? this.parishName,
      massDate: massDate ?? this.massDate,
      intentionType: intentionType ?? this.intentionType,
      intentionFor: intentionFor ?? this.intentionFor,
      specialNotes: specialNotes ?? this.specialNotes,
      offeringAmount: offeringAmount ?? this.offeringAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

