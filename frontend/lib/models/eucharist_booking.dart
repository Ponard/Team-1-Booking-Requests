import '../models/document.dart';

class EucharistBooking {
  final int? id;
  final int parishId;
  final int userId;
  final String? communicantName;
  final String? fatherName;
  final String? motherName;
  final String? contactEmail;
  final String? contactPhone;
  final String? preferredDate;
  final String? preferredTimeSlot;
  final int? priestId;
  final List<dynamic>? notes;
  final String status;
  final String? adminNotes;
  final int? approvedBy;
  final String? approvedAt;
  final String? createdAt;
  final String? updatedAt;
  final List<Document>? documents;

  EucharistBooking({
    this.id,
    required this.parishId,
    required this.userId,
    this.communicantName,
    this.fatherName,
    this.motherName,
    this.contactEmail,
    this.contactPhone,
    this.preferredDate,
    this.preferredTimeSlot,
    this.priestId,
    this.notes,
    this.status = 'pending',
    this.adminNotes,
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
    this.updatedAt,
    this.documents,
  });

  factory EucharistBooking.fromJson(Map<String, dynamic> json) {
    return EucharistBooking(
      id: json['id'],
      parishId: json['parishId'],
      userId: json['userId'],
      communicantName: json['communicantName'],
      fatherName: json['fatherName'],
      motherName: json['motherName'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      preferredDate: json['preferredDate'],
      preferredTimeSlot: json['preferredTimeSlot'],
      priestId: json['priestId'],
      notes: json['notes'] as List<dynamic>?,
      status: json['status'] ?? 'pending',
      adminNotes: json['adminNotes'],
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      documents: json['documents'] != null
          ? (json['documents'] as List).map((doc) => Document.fromJson(doc)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'parishId': parishId,
      'userId': userId,
      if (communicantName != null) 'communicantName': communicantName,
      if (fatherName != null) 'fatherName': fatherName,
      if (motherName != null) 'motherName': motherName,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (preferredDate != null) 'preferredDate': preferredDate,
      if (preferredTimeSlot != null) 'preferredTimeSlot': preferredTimeSlot,
      if (priestId != null) 'priestId': priestId,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (adminNotes != null) 'adminNotes': adminNotes,
    };
  }

  EucharistBooking copyWith({
    int? id,
    int? parishId,
    int? userId,
    String? communicantName,
    String? fatherName,
    String? motherName,
    String? contactEmail,
    String? contactPhone,
    String? preferredDate,
    String? preferredTimeSlot,
    int? priestId,
    List<dynamic>? notes,
    String? status,
    String? adminNotes,
    int? approvedBy,
    String? approvedAt,
    String? createdAt,
    String? updatedAt,
    List<Document>? documents,
  }) {
    return EucharistBooking(
      id: id ?? this.id,
      parishId: parishId ?? this.parishId,
      userId: userId ?? this.userId,
      communicantName: communicantName ?? this.communicantName,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      preferredDate: preferredDate ?? this.preferredDate,
      preferredTimeSlot: preferredTimeSlot ?? this.preferredTimeSlot,
      priestId: priestId ?? this.priestId,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      documents: documents ?? this.documents,
    );
  }
}
