import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/book.dart';
import '../models/loan.dart';

class BookService {
  BookService({
    this.assetPath = 'databook.json',
    this.loanAssetPath = 'dataloan.json',
  });

  final String assetPath;
  final String loanAssetPath;

  Future<List<Book>> loadBooks() async {
    final jsonText = await rootBundle.loadString(assetPath);
    final data = jsonDecode(jsonText) as List<dynamic>;
    return data
        .map((item) => Book.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Loan>> loadLoans() async {
    final jsonText = await rootBundle.loadString(loanAssetPath);
    final data = jsonDecode(jsonText) as List<dynamic>;
    return data
        .map((item) => Loan.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}