class Department {
  final int departmentId;
  final String departmentName;
  final String? description;
  final String? location;
  final String? contactInfo;

  Department({
    required this.departmentId,
    required this.departmentName,
    this.description,
    this.location,
    this.contactInfo,
  });

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      departmentId: map['department_id'],
      departmentName: map['department_name'],
      description: map['description'],
      location: map['location'],
      contactInfo: map['contact_info'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'department_id': departmentId,
      'department_name': departmentName,
      'description': description,
      'location': location,
      'contact_info': contactInfo,
    };
  }
}
