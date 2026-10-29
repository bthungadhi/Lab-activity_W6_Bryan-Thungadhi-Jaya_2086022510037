class Loan {
  final String id;
  final String bookId;
  final String studentId;
  final DateTime borrowDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final bool settled;

  const Loan({
    required this.id,
    required this.bookId,
    required this.studentId,
    required this.borrowDate,
    required this.dueDate,
    this.returnDate,
    this.settled = false,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    final returned = json['returnDate'] as String?;
    return Loan(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      studentId: json['studentId'] as String,
      borrowDate: DateTime.parse(json['borrowDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      returnDate: returned == null ? null : DateTime.parse(returned),
    );
  }

  bool get isActive => returnDate == null;

  Loan copyWith({DateTime? returnDate, bool? settled}) {
    return Loan(
      id: id,
      bookId: bookId,
      studentId: studentId,
      borrowDate: borrowDate,
      dueDate: dueDate,
      returnDate: returnDate ?? this.returnDate,
      settled: settled ?? this.settled,
    );
  }
}