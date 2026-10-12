class Parish {
  final int? id;
  final String name;
  final String address;
  final String? contactEmail;
  final String? contactPhone;
  final Map<String, dynamic>? schedule;
  final List<String>? servicesOffered;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? sacramentSettings;

  Parish({
    this.id,
    required this.name,
    required this.address,
    this.contactEmail,
    this.contactPhone,
    this.schedule,
    this.servicesOffered,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.sacramentSettings,
  });

  factory Parish.fromJson(Map<String, dynamic> json) {
    return Parish(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      schedule: json['schedule'] != null
          ? Map<String, dynamic>.from(json['schedule'])
          : null,
      servicesOffered: json['servicesOffered'] != null
          ? List<String>.from(json['servicesOffered'])
          : null,
      isActive: json['isActive'] ?? true,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      sacramentSettings: json['sacramentSettings'] is Map
          ? Map<String, dynamic>.from(json['sacramentSettings'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'schedule': schedule,
      'servicesOffered': servicesOffered,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'sacramentSettings': sacramentSettings,
    };
  }

  Parish copyWith({
    int? id,
    String? name,
    String? address,
    String? contactEmail,
    String? contactPhone,
    Map<String, dynamic>? schedule,
    List<String>? servicesOffered,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? sacramentSettings,
  }) {
    return Parish(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      schedule: schedule ?? this.schedule,
      servicesOffered: servicesOffered ?? this.servicesOffered,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sacramentSettings: sacramentSettings ?? this.sacramentSettings,
    );
  }
}
