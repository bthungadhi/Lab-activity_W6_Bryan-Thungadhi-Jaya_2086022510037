import 'package:flutter/material.dart';

import '../models/book.dart';
import '../models/loan.dart';
import '../viewmodels/library_view_model.dart';
import 'widgets/book_card.dart';
import 'widgets/borrow_dialog.dart';
import 'widgets/fine_summary_card.dart';
import 'widgets/loan_card.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, required this.viewModel});

  final LibraryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('University Library'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Catalogue'), Tab(text: 'Loans')],
          ),
        ),

        body: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) => _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(viewModel.errorMessage!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: viewModel.loadLibrary,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        FineSummaryCard(
          totalFine: viewModel.totalOutstandingFines,
          activeLoanCount: viewModel.activeLoans.length,
        ),
        Expanded(
          child: TabBarView(
            children: [_buildCatalogue(context), _buildLoans(context)],
          ),
        ),
      ],
    );
  }


  Widget _buildCatalogue(BuildContext context) {
    final books = viewModel.filteredBooks;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextFormField(
            initialValue: viewModel.searchQuery,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search title or author',
              border: OutlineInputBorder(),
            ),
            onChanged: viewModel.setSearchQuery,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _filterChip('All', null),
              for (final status in BookStatus.values)
                _filterChip(status.label, status),
            ],
          ),
        ),
        Expanded(
          child: books.isEmpty
              ? const Center(child: Text('No books match your search or filter.'))
              : ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return BookCard(
                      book: book,
                      status: viewModel.statusOf(book),
                      onBorrow: () => _onBorrow(context, book),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, BookStatus? status) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: viewModel.statusFilter == status,
        onSelected: (_) => viewModel.setStatusFilter(status),
      ),
    );
  }


  Widget _buildLoans(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (viewModel.activeLoans.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('No active loans right now.')),
          ),
        for (final loan in viewModel.loans) _buildLoanCard(context, loan),
      ],
    );
  }

  Widget _buildLoanCard(BuildContext context, Loan loan) {
    final book = viewModel.bookById(loan.bookId);
    return LoanCard(
      loan: loan,
      bookTitle: book?.title ?? 'Unknown book',
      status: loan.isActive && book != null ? viewModel.statusOf(book) : null,
      statusText: viewModel.getOverdueStatus(loan),
      fine: viewModel.outstandingFine(loan),
      onReturn: loan.isActive
          ? () => _showResult(
              context, viewModel.returnBook(loan.id), 'Book returned.')
          : null,
      onSettle: viewModel.canSettle(loan)
          ? () => _showResult(
              context, viewModel.settleFine(loan.id), 'Fine marked as paid.')
          : null,
    );
  }

  Future<void> _onBorrow(BuildContext context, Book book) async {
    final studentId = await showDialog<String>(
      context: context,
      builder: (_) => BorrowDialog(bookTitle: book.title),
    );
    if (studentId == null || !context.mounted) return;
    _showResult(
      context,
      viewModel.borrowBook(book.id, studentId),
      'Book borrowed successfully.',
    );
  }

  void _showResult(BuildContext context, bool ok, String successMessage) {
    final message =
        ok ? successMessage : (viewModel.lastError ?? 'Something went wrong.');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}