import 'note.dart';

class MassIntention {
  final int? id;
  final String? type;
  final String? intentionDetails;
  final String? donorName;
  final String? preferredDate;
  final int? parishId;
  final String? parishName;
  final String? massSchedule;
  final String? preferredTimeSlot;
  final String? preferredPriest;
  final List<Note>? notes;
  final String? status;
  final int? userId;
  final String? createdAt;
  final String? updatedAt;

  MassIntention({
    this.id,
    this.type,
    this.intentionDetails,
    this.donorName,
    this.preferredDate,
    this.parishId,
    this.parishName,
    this.massSchedule,
    this.preferredTimeSlot,
    this.preferredPriest,
    this.notes,
    this.status,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory MassIntention.fromJson(Map<String, dynamic> json) {
    List<Note>? notesList;
    if (json['notes'] != null) {
      notesList = (json['notes'] as List).map((note) {
        if (note is Map<String, dynamic>) {
          return Note.fromJson(note);
        } else if (note is String) {
          return Note(content: note);
        }
        return Note(content: note.toString());
      }).toList();
    }

    return MassIntention(
      id: json['id'],
      type: json['type'],
      intentionDetails: json['intentionDetails'],
      donorName: json['donorName'],
      preferredDate: json['preferredDate'],
      parishId: json['parishId'],
      parishName: json['parishName'],
      massSchedule: json['massSchedule'],
      preferredTimeSlot: json['preferredTimeSlot'],
      preferredPriest: json['preferredPriest'],
      notes: notesList,
      status: json['status'] ?? 'pending',
      userId: json['userId'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'intentionDetails': intentionDetails,
      'donorName': donorName,
      'preferredDate': preferredDate,
      'parishId': parishId,
      'massSchedule': massSchedule,
      if (preferredTimeSlot != null) 'preferredTimeSlot': preferredTimeSlot,
      if (preferredPriest != null) 'preferredPriest': preferredPriest,
      if (notes != null) 'notes': notes!.map((n) => n.toJson()).toList(),
      if (status != null) 'status': status,
      'userId': userId,
    };
  }

  MassIntention copyWith({
    int? id,
    String? type,
    String? intentionDetails,
    String? donorName,
    String? preferredDate,
    int? parishId,
    String? massSchedule,
    String? preferredTimeSlot,
    String? preferredPriest,
    List<Note>? notes,
    String? status,
    int? userId,
    String? createdAt,
    String? updatedAt,
  }) {
    return MassIntention(
      id: id ?? this.id,
      type: type ?? this.type,
      intentionDetails: intentionDetails ?? this.intentionDetails,
      donorName: donorName ?? this.donorName,
      preferredDate: preferredDate ?? this.preferredDate,
      parishId: parishId ?? this.parishId,
      massSchedule: massSchedule ?? this.massSchedule,
      preferredTimeSlot: preferredTimeSlot ?? this.preferredTimeSlot,
      preferredPriest: preferredPriest ?? this.preferredPriest,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
