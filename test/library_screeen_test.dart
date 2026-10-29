import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w6/models/book.dart';
import 'package:w6/repositories/library_repository.dart';
import 'package:w6/services/book_service.dart';
import 'package:w6/viewmodels/library_view_model.dart';
import 'package:w6/views/library_screen.dart';
import 'package:w6/models/loan.dart';

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
  testWidgets('12. UI reacts when the ViewModel changes', (tester) async {
    final vm = LibraryViewModel(
      LibraryRepository(FakeBookService()),
      now: () => DateTime(2026, 10, 1),
    );
    await vm.loadLibrary();

    await tester.pumpWidget(MaterialApp(home: LibraryScreen(viewModel: vm)));

    expect(find.text('Active loans: 0'), findsOneWidget);
    expect(find.byKey(const ValueKey('borrow-B001')), findsOneWidget);

    // Borrow B001 through the UI.
    await tester.tap(find.byKey(const ValueKey('borrow-B001')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'S001',
    );
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // The screen updated by itself.
    expect(find.text('Active loans: 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('borrow-B001')), findsNothing);
    expect(find.byKey(const ValueKey('borrow-B002')), findsOneWidget);
  });
}
