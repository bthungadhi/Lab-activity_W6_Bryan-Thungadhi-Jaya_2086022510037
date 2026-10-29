import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/loan.dart';
import '../repositories/library_repository.dart';

enum BookStatus { available, borrowed, overdue, missing }

extension BookStatusLabel on BookStatus {
  String get label {
    switch (this) {
      case BookStatus.available:
        return 'Available';
      case BookStatus.borrowed:
        return 'Borrowed';
      case BookStatus.overdue:
        return 'Overdue';
      case BookStatus.missing:
        return 'Missing';
    }
  }
}


class LibraryViewModel extends ChangeNotifier {

  LibraryViewModel(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final LibraryRepository _repository;
  final DateTime Function() _now;

  List<Book> _books = [];
  bool _isLoading = false;
  String? _errorMessage; 
  String? _lastError; 
  String _searchQuery = '';
  BookStatus? _statusFilter;


  List<Book> get books => _books;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get lastError => _lastError;
  String get searchQuery => _searchQuery;
  BookStatus? get statusFilter => _statusFilter;


  List<Loan> get loans => _repository.getLoans().reversed.toList();
  List<Loan> get activeLoans =>
      _repository.getLoans().where((loan) => loan.isActive).toList();

  List<Loan> get overdueLoans {
    final result = <Loan>[];
    for (final loan in _repository.getLoans()) {
      if (loan.isActive && FinePolicy.isOverdue(loan.dueDate, _today)) {
        result.add(loan);
      }
    }
    return result;
  }


  List<Book> get filteredBooks {
    final query = _searchQuery.trim().toLowerCase();
    return _books.where((book) {
      final matchesSearch =
          query.isEmpty ||
          book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query);
      final matchesFilter =
          _statusFilter == null || statusOf(book) == _statusFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get totalOutstandingFines => _repository.getLoans().fold(
    0,
    (sum, loan) => sum + outstandingFine(loan),
  );


  Future<void> loadLibrary() async {
    _books = await _repository.getBooks();
    await _repository.loadLoans();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _books = await _repository.getBooks();
    } catch (e) {
      _errorMessage = 'Failed to load the book catalogue.';
    }
    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(BookStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }


  DateTime get _today => FinePolicy.dateOnly(_now());

  Book? bookById(String id) {
    for (final book in _books) {
      if (book.id == id) return book;
    }
    return null;
  }

  Loan? activeLoanFor(String bookId) {
    for (final loan in _repository.getLoans()) {
      if (loan.bookId == bookId && loan.isActive) return loan;
    }
    return null;
  }


  BookStatus statusOf(Book book) {
    final loan = activeLoanFor(book.id);
    if (loan == null) return BookStatus.available;
    if (FinePolicy.isMissing(loan.dueDate, _today)) return BookStatus.missing;
    if (FinePolicy.isOverdue(loan.dueDate, _today)) return BookStatus.overdue;
    return BookStatus.borrowed;
  }

  String getOverdueStatus(Loan loan) {
    if (loan.isActive) {
      final book = bookById(loan.bookId);
      return book == null ? 'Unknown' : statusOf(book).label;
    }
    final returnedOn = loan.returnDate!;
    if (FinePolicy.isMissing(loan.dueDate, returnedOn)) {
      return 'Returned after missing';
    }
    return calculateFine(loan) > 0 ? 'Returned late' : 'Returned';
  }

  int calculateFine(Loan loan) {
    final book = bookById(loan.bookId);
    if (book == null) return 0;
    return FinePolicy.calculate(
      dueDate: loan.dueDate,
      evaluationDate: loan.returnDate ?? _today,
      replacementPrice: book.replacementPrice,
    );
  }

  int outstandingFine(Loan loan) => loan.settled ? 0 : calculateFine(loan);

  // ---------- Actions ----------
  bool borrowBook(String bookId, String studentId) {
    final student = studentId.trim();
    if (student.isEmpty) return _fail('Student ID must not be empty.');
    if (bookById(bookId) == null) return _fail('Book not found.');

    if (activeLoanFor(bookId) != null)
      return _fail('This book is not available.');

    final today = _today;
    final number = _repository.getLoans().length + 1;
    _repository.addLoan(
      Loan(
        id: 'L${number.toString().padLeft(3, '0')}',
        bookId: bookId,
        studentId: student,
        borrowDate: today,
        dueDate: FinePolicy.dueDateFrom(today),
      ),
    );
    _lastError = null;
    notifyListeners();
    return true;
  }

  bool returnBook(String loanId) {
    final loan = _repository.findLoan(loanId);
    if (loan == null) return _fail('Loan not found.');
    if (!loan.isActive) return _fail('This loan has already been returned.');

    _repository.updateLoan(loan.copyWith(returnDate: _today));
    _lastError = null;
    notifyListeners();
    return true;
  }

  bool canSettle(Loan loan) =>
      !loan.isActive && !loan.settled && calculateFine(loan) > 0;

  bool settleFine(String loanId) {
    final loan = _repository.findLoan(loanId);
    if (loan == null) return _fail('Loan not found.');
    if (!canSettle(loan)) return _fail('Nothing to settle for this loan.');

    _repository.updateLoan(loan.copyWith(settled: true));
    _lastError = null;
    notifyListeners();
    return true;
  }

  bool _fail(String message) {
    _lastError = message;
    return false;
  }
}

class FinePolicy {
  static const int loanDays = 14; 
  static const int weeklyRate = 5000; 
  static const int missingAfterMonths = 6;

  /// Keeps only year-month-day.
  static DateTime dateOnly(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  static DateTime dueDateFrom(DateTime borrowDate) =>
      dateOnly(borrowDate).add(const Duration(days: loanDays));

  static DateTime missingDate(DateTime dueDate) {
    final due = dateOnly(dueDate);
    final monthIndex = due.month - 1 + missingAfterMonths;
    final year = due.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final lastDayOfMonth = DateTime.utc(year, month + 1, 0).day;
    final day = due.day > lastDayOfMonth ? lastDayOfMonth : due.day;
    return DateTime.utc(year, month, day);
  }

  static int daysOverdue(DateTime dueDate, DateTime evaluationDate) {
    final days = dateOnly(evaluationDate).difference(dateOnly(dueDate)).inDays;
    return days > 0 ? days : 0;
  }

  static bool isOverdue(DateTime dueDate, DateTime evaluationDate) =>
      daysOverdue(dueDate, evaluationDate) > 0;

  /// True on or after the six-month date.
  static bool isMissing(DateTime dueDate, DateTime evaluationDate) =>
      !dateOnly(evaluationDate).isBefore(missingDate(dueDate));

  static int calculate({
    required DateTime dueDate,
    required DateTime evaluationDate,
    required int replacementPrice,
  }) {
    if (isMissing(dueDate, evaluationDate)) return replacementPrice;
    final completedWeeks = daysOverdue(dueDate, evaluationDate) ~/ 7;
    return completedWeeks * weeklyRate;
  }
}
