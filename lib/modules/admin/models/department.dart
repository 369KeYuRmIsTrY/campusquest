class Department {
  final String deptName;
  final String building;
  final double? budget;

  Department({required this.deptName, required this.building, this.budget});

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      deptName: map['dept_name'],
      building: map['building'],
      budget: map['budget'] != null ? (map['budget'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {'dept_name': deptName, 'building': building, 'budget': budget};
  }
}
