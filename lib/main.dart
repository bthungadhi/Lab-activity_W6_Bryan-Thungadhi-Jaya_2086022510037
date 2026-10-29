import 'package:flutter/material.dart';

import 'repositories/library_repository.dart';
import 'services/book_service.dart';
import 'viewmodels/library_view_model.dart';
import 'views/library_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  late final LibraryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LibraryViewModel(LibraryRepository(BookService()));
    _viewModel.loadLibrary();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University Library System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
      home: LibraryScreen(viewModel: _viewModel),
    );
  }
}
