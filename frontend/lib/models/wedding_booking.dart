import '../models/document.dart';

class WeddingBooking {
  final int? id;
  final int parishId;
  final int userId;
  final String? groomFullName;
  final String? brideFullName;
  final String? contactEmail;
  final String? contactPhone;
  final String? preferredDate;
  final String? preferredTimeSlot;
  final String? seminarSchedule;
  final int? priestId;
  final List<dynamic>? notes;
  final String status;
  final String? adminNotes;
  final int? approvedBy;
  final String? approvedAt;
  final String? createdAt;
  final String? updatedAt;
  final List<Document>? documents;

  WeddingBooking({
    this.id,
    required this.parishId,
    required this.userId,
    this.groomFullName,
    this.brideFullName,
    this.contactEmail,
    this.contactPhone,
    this.preferredDate,
    this.preferredTimeSlot,
    this.seminarSchedule,
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

  factory WeddingBooking.fromJson(Map<String, dynamic> json) {
    return WeddingBooking(
      id: json['id'],
      parishId: json['parishId'],
      userId: json['userId'],
      groomFullName: json['groomFullName'],
      brideFullName: json['brideFullName'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      preferredDate: json['preferredDate'],
      preferredTimeSlot: json['preferredTimeSlot'],
      seminarSchedule: json['seminarSchedule'],
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
      if (groomFullName != null) 'groomFullName': groomFullName,
      if (brideFullName != null) 'brideFullName': brideFullName,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (preferredDate != null) 'preferredDate': preferredDate,
      if (preferredTimeSlot != null) 'preferredTimeSlot': preferredTimeSlot,
      if (seminarSchedule != null) 'seminarSchedule': seminarSchedule,
      if (priestId != null) 'priestId': priestId,
      if (notes != null) 'notes': notes,
      'status': status,
      if (adminNotes != null) 'adminNotes': adminNotes,
      if (documents != null) 'documents': documents!.map((d) => d.toJson()).toList(),
    };
  }

  WeddingBooking copyWith({
    int? id,
    int? parishId,
    int? userId,
    String? groomFullName,
    String? brideFullName,
    String? contactEmail,
    String? contactPhone,
    String? preferredDate,
    String? preferredTimeSlot,
    String? seminarSchedule,
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
    return WeddingBooking(
      id: id ?? this.id,
      parishId: parishId ?? this.parishId,
      userId: userId ?? this.userId,
      groomFullName: groomFullName ?? this.groomFullName,
      brideFullName: brideFullName ?? this.brideFullName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      preferredDate: preferredDate ?? this.preferredDate,
      preferredTimeSlot: preferredTimeSlot ?? this.preferredTimeSlot,
      seminarSchedule: seminarSchedule ?? this.seminarSchedule,
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
