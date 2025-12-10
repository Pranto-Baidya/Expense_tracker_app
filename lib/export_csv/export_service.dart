

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:path_provider/path_provider.dart';

class ExportsService{

  static Future<String> exportToCSV(List<ExpenseModel> records) async {
    List<List<dynamic>> rows = [
      ['ID', 'TITLE', 'AMOUNT', 'CATEGORY', 'TYPE', 'DATE']
    ];

    for (var r in records) {
      rows.add([r.id, r.title, r.amount, r.category, r.moneyType, r.date]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    final directory = await getExternalStorageDirectory();
    final downloadsDir = Directory("${directory!.path}/MoneyMate");

    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final path = "${downloadsDir.path}/records.csv";
    final file = File(path);

    await file.writeAsString(csvData);

    return path;
  }

}