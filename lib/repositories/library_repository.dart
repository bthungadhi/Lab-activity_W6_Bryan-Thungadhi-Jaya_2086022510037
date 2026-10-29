import '../models/book.dart';
import '../models/loan.dart';
import '../services/book_service.dart';

class LibraryRepository {
  LibraryRepository(this._bookService);

  final BookService _bookService;
  final List<Loan> _loans = [];

  Future<List<Book>> getBooks() => _bookService.loadBooks();
  Future<void> loadLoans() async {
    _loans.clear();
    _loans.addAll(await _bookService.loadLoans());
  }

  List<Loan> getLoans() => List.unmodifiable(_loans);

  Loan? findLoan(String loanId) {
    for (final loan in _loans) {
      if (loan.id == loanId) return loan;
    }
    return null;
  }

  void addLoan(Loan loan) => _loans.add(loan);

  void updateLoan(Loan updated) {
    final index = _loans.indexWhere((loan) => loan.id == updated.id);
    if (index != -1) _loans[index] = updated;
  }
}
