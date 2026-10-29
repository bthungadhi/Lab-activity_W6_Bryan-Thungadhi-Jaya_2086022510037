import 'package:flutter_test/flutter_test.dart';
import 'package:w6/models/book.dart';
import 'package:w6/repositories/library_repository.dart';
import 'package:w6/services/book_service.dart';
import 'package:w6/viewmodels/library_view_model.dart';
import 'package:w6/models/loan.dart';

/// Fake service: no real file needed, so tests are fast and predictable.
class FakeBookService extends BookService {
  @override
  Future<List<Loan>> loadLoans() async => [];
  @override
  Future<List<Book>> loadBooks() async => const [
    Book(
      id: 'B001',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      replacementPrice: 150000,
    ),
    Book(
      id: 'B002',
      title: 'Design Patterns',
      author: 'Erich Gamma',
      replacementPrice: 320000,
    ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now; // the "fake clock" the ViewModel reads
  late LibraryViewModel vm;

  setUp(() async {
    now = DateTime(2026, 10, 1); // borrow day -> due date = 15 Oct 2026
    vm = LibraryViewModel(LibraryRepository(FakeBookService()), now: () => now);
    await vm.loadLibrary();
  });

  test('1. catalogue loads from the real databook.json', () async {
    final realVm = LibraryViewModel(LibraryRepository(BookService()));
    await realVm.loadLibrary();
    expect(realVm.errorMessage, isNull);
    expect(realVm.books, isNotEmpty);
    expect(realVm.books.first.id, 'B001');
  });

  test('2. an available book can be borrowed', () {
    expect(vm.borrowBook('B001', 'S001'), isTrue);
    expect(vm.statusOf(vm.bookById('B001')!), BookStatus.borrowed);
  });

  test('3. an already-borrowed book cannot be borrowed again', () {
    vm.borrowBook('B001', 'S001');
    expect(vm.borrowBook('B001', 'S002'), isFalse);
    expect(vm.loans.length, 1);
  });

  test('4. borrowing creates a correct loan', () {
    vm.borrowBook('B001', 'S001');
    final loan = vm.loans.first;
    expect(loan.bookId, 'B001');
    expect(loan.studentId, 'S001');
    expect(loan.borrowDate, DateTime.utc(2026, 10, 1));
    expect(loan.dueDate, DateTime.utc(2026, 10, 15));
    expect(loan.returnDate, isNull);
  });

  test('5. returned on time has no fine', () {
    vm.borrowBook('B001', 'S001');
    now = DateTime(2026, 10, 15); // exactly on the due date
    vm.returnBook(vm.loans.first.id);
    expect(vm.calculateFine(vm.loans.first), 0);
  });

  test('6. six days overdue has no weekly fine', () {
    vm.borrowBook('B001', 'S001');
    now = DateTime(2026, 10, 21);
    expect(vm.calculateFine(vm.loans.first), 0);
  });

  test('7. seven days overdue = Rp5,000', () {
    vm.borrowBook('B001', 'S001');
    now = DateTime(2026, 10, 22);
    expect(vm.calculateFine(vm.loans.first), 5000);
  });

  test('8. fourteen days overdue = Rp10,000', () {
    vm.borrowBook('B001', 'S001');
    now = DateTime(2026, 10, 29);
    expect(vm.calculateFine(vm.loans.first), 10000);
  });

  test('9. six months overdue = Missing + replacement price', () {
    vm.borrowBook('B001', 'S001');
    now = DateTime(2027, 4, 14); // one day before the threshold
    expect(vm.statusOf(vm.bookById('B001')!), BookStatus.overdue);
    now = DateTime(2027, 4, 15); // due 15 Oct + 6 months
    expect(vm.statusOf(vm.bookById('B001')!), BookStatus.missing);
    expect(vm.calculateFine(vm.loans.first), 150000); // not 150000 + weekly
  });

  test('10. returning a normal loan makes the book available', () {
    vm.borrowBook('B001', 'S001');
    now = DateTime(2026, 10, 5);
    expect(vm.returnBook(vm.loans.first.id), isTrue);
    expect(vm.statusOf(vm.bookById('B001')!), BookStatus.available);
    expect(vm.activeLoans, isEmpty);
    // returning twice must fail
    expect(vm.returnBook(vm.loans.first.id), isFalse);
  });

  test('11. returning a missing book keeps the charge', () {
    vm.borrowBook('B001', 'S001');
    now = DateTime(2027, 4, 15);
    vm.returnBook(vm.loans.first.id);
    final loan = vm.loans.first;
    expect(loan.isActive, isFalse);
    expect(vm.statusOf(vm.bookById('B001')!), BookStatus.available);
    expect(vm.calculateFine(loan), 150000);
    expect(vm.totalOutstandingFines, 150000);
    // only an explicit settle clears it
    vm.settleFine(loan.id);
    expect(vm.totalOutstandingFines, 0);
  });

  test('extra: end-of-month and leap-year missing dates', () {
    expect(
      FinePolicy.missingDate(DateTime.utc(2026, 8, 31)),
      DateTime.utc(2027, 2, 28),
    );
    expect(
      FinePolicy.missingDate(DateTime.utc(2027, 8, 31)),
      DateTime.utc(2028, 2, 29),
    );
  });

  test('extra: listeners are notified after borrowing', () {
    var count = 0;
    vm.addListener(() => count++);
    vm.borrowBook('B001', 'S001');
    expect(count, 1);
  });
}
