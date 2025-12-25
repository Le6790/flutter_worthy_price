class SavedItem {
  final String id;
  final String itemName;
  final double itemPrice;
  final double hourlyWage;
  final double workTimeHours;
  final DateTime savedAt;

  SavedItem({
    required this.id,
    required this.itemName,
    required this.itemPrice,
    required this.hourlyWage,
    required this.workTimeHours,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemName': itemName,
      'itemPrice': itemPrice,
      'hourlyWage': hourlyWage,
      'workTimeHours': workTimeHours,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory SavedItem.fromJson(Map<String, dynamic> json) {
    return SavedItem(
      id: json['id'] as String,
      itemName: json['itemName'] as String,
      itemPrice: (json['itemPrice'] as num).toDouble(),
      hourlyWage: (json['hourlyWage'] as num).toDouble(),
      workTimeHours: (json['workTimeHours'] as num).toDouble(),
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  SavedItem copyWith({
    String? id,
    String? itemName,
    double? itemPrice,
    double? hourlyWage,
    double? workTimeHours,
    DateTime? savedAt,
  }) {
    return SavedItem(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      itemPrice: itemPrice ?? this.itemPrice,
      hourlyWage: hourlyWage ?? this.hourlyWage,
      workTimeHours: workTimeHours ?? this.workTimeHours,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  Map<String, dynamic> getWorkTime() {
    final hours = workTimeHours.floor();
    final minutes = ((workTimeHours - hours) * 60).round();
    return {
      'hours': hours,
      'minutes': minutes,
      'totalHours': workTimeHours,
    };
  }
}
