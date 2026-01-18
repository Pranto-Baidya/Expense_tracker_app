import 'dart:convert';
import 'dart:io';
import 'package:expense_tracker_app/models/budget_model.dart';
import 'package:expense_tracker_app/models/card_model.dart';
import 'package:expense_tracker_app/models/category_model.dart';
import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseConnection {
  static Database? _db;

  Future<Database> getDB() async {
    if (_db != null) {
      return _db!;
    } else {
      _db = await initDB();
      return _db!;
    }
  }

  Future<Database> initDB() async {
    Directory dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'ExpenseDB.db');
    return openDatabase(
      path,
      version: 7,
      onCreate: _createTable,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE expenses ADD COLUMN time TEXT');
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE expenses ADD COLUMN moneyType TEXT DEFAULT "expense"',
          );
        }
        if (oldVersion < 4) {
          await db.execute('''
           CREATE TABLE cards(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cardName TEXT,
            amount REAL
           )
           ''');
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE cards ADD COLUMN iconCode INTEGER');
        }
        if (oldVersion < 6) {
          await db.execute(
            'ALTER TABLE budgets ADD COLUMN moneyType TEXT DEFAULT "expense"',
          );
        }

        if (oldVersion < 7) {
          await db.execute('''
      CREATE TABLE categories(
      categoryId INTEGER PRIMARY KEY AUTOINCREMENT,
      categoryName TEXT,
      categoryType TEXT,
      iconCode INTEGER,
      colorCode INTEGER
      )''');
        }
      },
    );
  }

  Future<void> _createTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses(
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       title TEXT,
       amount REAL,
       category TEXT,
       date TEXT,
       time TEXT,
       moneyType TEXT,
       accountId INTEGER
      )
      ''');

    await db.execute('''
      CREATE TABLE cards(
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       cardName TEXT,
       amount REAL,
       initialAmount REAL,
       iconCode INTEGER,
       progress REAL,
       moneyType TEXT
      )
      ''');

    await db.execute('''
      CREATE TABLE budgets(
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       categoryName TEXT,
       budget REAL,
       spent REAL,
       remaining REAL,
       date TEXT,
       moneyType TEXT
      )
      ''');

    await db.execute('''
      CREATE TABLE categories(
      categoryId INTEGER PRIMARY KEY AUTOINCREMENT,
      categoryName TEXT,
      categoryType TEXT,
      iconCode INTEGER,
      colorCode INTEGER
      )
      ''');
  }

  Future<int> insertExpense(ExpenseModel expense) async {
    final db = await getDB();
    return await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExpenseModel>> getAllExpenses() async {
    final db = await getDB();
    List<Map<String, dynamic>> data = await db.query('expenses', orderBy: 'id DESC');
    return data.map((i) => ExpenseModel.fromMap(i)).toList();
  }

  Future<int> updateExpenses(ExpenseModel expense) async {
    final db = await getDB();
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpenses(int id) async {
    final db = await getDB();
    return await db.delete('expenses', where: 'id=?', whereArgs: [id]);
  }

  Future<void> closeDB() async {
    final db = await getDB();
    db.close();
  }

  //CRUD for cards table

  Future<int> insertCard(CardModel card) async {
    final db = await getDB();
    return await db.insert(
      'cards',
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CardModel>> getAllCards() async {
    final db = await getDB();
    List<Map<String, dynamic>> data = await db.query(
      'cards',
      orderBy: 'id DESC',
    );
    return await data.map((i) => CardModel.fromMap(i)).toList();
  }

  Future<int> updateCard(CardModel card) async {
    final db = await getDB();
    return await db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> deleteCard(int id) async {
    final db = await getDB();
    return await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteExpensesByAccountId(int accountId) async {
    final db = await getDB();
    await db.delete('expenses', where: 'accountId = ?', whereArgs: [accountId]);
  }
  //CRUD for budgets table

  Future<int> insertBudget(BudgetModel budget) async {
    final db = await getDB();
    return await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BudgetModel>> getAllBudgets() async {
    final db = await getDB();
    List<Map<String, dynamic>> values = await db.query(
      'budgets',
      orderBy: 'id DESC',
    );
    return await values.map((i) => BudgetModel.fromMap(i)).toList();
  }

  Future<int> updateBudget(BudgetModel budget) async {
    final db = await getDB();
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<int> deleteBudget(int id) async {
    final db = await getDB();
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  //CRUD for categories table

  Future<int> addCategory(CategoryModel category) async {
    final db = await getDB();
    return await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await getDB();
    List<Map<String, dynamic>> data = await db.query(
      'categories',
      orderBy: 'categoryId DESC',
    );
    return data.map((i) => CategoryModel.fromMap(i)).toList();
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await getDB();
    return await db.update(
      'categories',
      category.toMap(),
      where: 'categoryId = ?',
      whereArgs: [category.categoryId],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await getDB();
    return await db.delete(
      'categories',
      where: 'categoryId = ?',
      whereArgs: [id],
    );
  }

  //Backup+Restore methods

  Future<Map<String, dynamic>> exportFullDatabase() async {
    final db = await getDB();

    final expenses = await db.query('expenses');
    final cards = await db.query('cards');
    final categories = await db.query('categories');
    final budgets = await db.query('budgets');

    return {
      "expenses": expenses,
      "cards": cards,
      "categories": categories,
      "budgets": budgets,
    };
  }

  Future<File> createBackupFile() async {
    final dbData = await exportFullDatabase();

    Directory dir;

    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');

      if (!dir.existsSync()) {
        dir = (await getExternalStorageDirectory())!;
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final backupDir = Directory("${dir.path}/MoneyMateBackups");

    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }

    final now = DateTime.now();
    final filePath = "${backupDir.path}/MoneyMateBackup_${now.year}-${now.month}-${now.day}_${now.hour}-${now.minute}.json";

    final file = File(filePath);
    await file.writeAsString(jsonEncode(dbData));

    print("Backup saved to: $filePath");

    return file;
  }

  Future<void> restoreDataFromBackup(File file) async {
    final db = await getDB();

    final content = await file.readAsString();
    final data = jsonDecode(content);

    await db.delete('expenses');
    await db.delete('cards');
    await db.delete('budgets');
    await db.delete('categories');

    for (var row in data['expenses']) {
      await db.insert(
        'expenses',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    for (var row in data['cards']) {
      await db.insert(
        'cards',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    for (var row in data['budgets']) {
      await db.insert(
        'budgets',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    for (var row in data['categories']) {
      await db.insert(
        'categories',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> deleteAllTables()async{
    final db = await getDB();

    await db.delete('expenses');
    await db.delete('budgets');
    await db.delete('cards');
    await db.delete('categories');
  }

  //Bulk Delete

  Future<void> bulkDeleteForRecords(List<int> allIDs)async{

    if(allIDs.isEmpty){
      return;
    }

    final db = await getDB();

    final placeholders = List.filled(allIDs.length, '?').join(',');

    await db.delete('expenses', where: 'id IN ($placeholders)', whereArgs: allIDs);

  }

  Future<void> bulkDeleteForAccounts(List<int> allAccIds)async{

    if(allAccIds.isEmpty) return;

    final db = await getDB();

    String placeholders = List.filled(allAccIds.length, '?').join(',');

    await db.delete('cards', where: 'id IN ($placeholders)', whereArgs: allAccIds);
  }

  Future<void> bulkDeleteForBudgets(List<int> allBudjIds)async{

    if(allBudjIds.isEmpty){
      return;
    }

    final db = await getDB();

    final placeholders = List.filled(allBudjIds.length, '?').join(',');

    await db.delete('budgets',where: 'id In ($placeholders)',whereArgs: allBudjIds);
  }

  Future<void> bulkDeleteForCategories(List<int> allCatIds)async{

    if(allCatIds.isEmpty) return;

    final db = await getDB();

    final String ph = List.filled(allCatIds.length, '?').join(',');

    await db.delete('categories',where: 'categoryId IN ($ph)',whereArgs: allCatIds);

  }
}
