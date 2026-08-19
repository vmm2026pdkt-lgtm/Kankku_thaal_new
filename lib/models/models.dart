class Entry {
  final String id;
  final String date; // yyyy-MM-dd
  final String type; // income | expense
  final double amount;
  final String desc;
  final String category;
  final String createdAt;

  Entry({
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.desc,
    required this.category,
    required this.createdAt,
  });

  Entry copyWith({
    String? date,
    String? type,
    double? amount,
    String? desc,
    String? category,
  }) {
    return Entry(
      id: id,
      date: date ?? this.date,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      desc: desc ?? this.desc,
      category: category ?? this.category,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'type': type,
        'amount': amount,
        'desc': desc,
        'category': category,
        'createdAt': createdAt,
      };

  factory Entry.fromMap(Map<String, dynamic> m) => Entry(
        id: m['id'] as String,
        date: m['date'] as String,
        type: m['type'] as String,
        amount: (m['amount'] as num).toDouble(),
        desc: m['desc'] as String,
        category: m['category'] as String,
        createdAt: m['createdAt'] as String,
      );
}

class Category {
  final String id;
  final String type; // income | expense
  final String icon;
  final String name;
  final bool custom;

  Category({
    required this.id,
    required this.type,
    required this.icon,
    required this.name,
    this.custom = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'icon': icon,
        'name': name,
        'custom': custom ? 1 : 0,
      };

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as String,
        type: m['type'] as String,
        icon: m['icon'] as String,
        name: m['name'] as String,
        custom: (m['custom'] as int) == 1,
      );
}

class RecurringRule {
  final String id;
  final String type; // income | expense
  final double amount;
  final String desc;
  final String category;
  final String frequency; // monthly | weekly
  final String lastRun; // yyyy-MM-dd, last date an entry was auto-created

  RecurringRule({
    required this.id,
    required this.type,
    required this.amount,
    required this.desc,
    required this.category,
    required this.frequency,
    required this.lastRun,
  });

  RecurringRule copyWith({String? lastRun}) => RecurringRule(
        id: id,
        type: type,
        amount: amount,
        desc: desc,
        category: category,
        frequency: frequency,
        lastRun: lastRun ?? this.lastRun,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'desc': desc,
        'category': category,
        'frequency': frequency,
        'lastRun': lastRun,
      };

  factory RecurringRule.fromJson(Map<String, dynamic> j) => RecurringRule(
        id: j['id'] as String,
        type: j['type'] as String,
        amount: (j['amount'] as num).toDouble(),
        desc: j['desc'] as String,
        category: j['category'] as String,
        frequency: j['frequency'] as String,
        lastRun: j['lastRun'] as String,
      );
}

class AppSettings {
  String userName;
  String accountName;
  AppSettings({this.userName = '', this.accountName = ''});

  Map<String, dynamic> toJson() => {'userName': userName, 'accountName': accountName};
  factory AppSettings.fromJson(Map<String, dynamic> j) =>
      AppSettings(userName: j['userName'] ?? '', accountName: j['accountName'] ?? '');
}

class Budgets {
  double overall;
  Map<String, double> categories;
  Budgets({this.overall = 0, Map<String, double>? categories}) : categories = categories ?? {};

  Map<String, dynamic> toJson() => {'overall': overall, 'categories': categories};
  factory Budgets.fromJson(Map<String, dynamic> j) => Budgets(
        overall: (j['overall'] as num?)?.toDouble() ?? 0,
        categories: (j['categories'] as Map?)?.map(
              (k, v) => MapEntry(k as String, (v as num).toDouble()),
            ) ??
            {},
      );
}
