
import 'dart:io';
import 'package:expense_tracker_app/models/budget_model.dart';
import 'package:expense_tracker_app/models/card_model.dart';
import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseConnection{
  static Database? _db;

  Future<Database> getDB()async{
    if(_db!=null){
      return _db!;
    }
    else{
      _db = await initDB();
      return _db!;
    }
  }

  Future<Database> initDB()async{
   Directory dir = await getApplicationDocumentsDirectory();
   final path = join(dir.path,'ExpenseDB.db');
   return openDatabase(
     path,
     version: 5,
     onCreate: _createTable,
     onUpgrade: (db,oldVersion, newVersion)async{
       if(oldVersion<2){
         await db.execute('ALTER TABLE expenses ADD COLUMN time TEXT');
       }
       if(oldVersion<3){
         await db.execute('ALTER TABLE expenses ADD COLUMN moneyType TEXT DEFAULT "expense"');
       }
       if(oldVersion<4){
         await db.execute(
           '''
           CREATE TABLE cards(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cardName TEXT,
            amount REAL
           )
           '''
         );
       }
       if(oldVersion<5){
         await db.execute('ALTER TABLE cards ADD COLUMN iconCode INTEGER');
       }
     }
   );
  }

  Future<void> _createTable(Database db, int version)async{
    await db.execute(
      '''
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
      '''
    );

    await db.execute(
      '''
      CREATE TABLE cards(
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       cardName TEXT,
       amount REAL,
       iconCode INTEGER,
       progress REAL,
       moneyType TEXT
      )
      '''
    );

    await db.execute(
      '''
      CREATE TABLE budgets(
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       categoryName TEXT,
       budget REAL,
       spent REAL,
       remaining REAL,
       date TEXT
      )
      '''
    );
  }

  Future<int> insertExpense(ExpenseModel expense)async{
    final db = await getDB();
    return await db.insert('expenses', expense.toMap(),conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ExpenseModel>> getAllExpenses({int offset = 0, int limit = 10})async{
    final db = await getDB();
    List<Map<String,dynamic>> data = await db.query('expenses',orderBy: 'id DESC',offset: offset, limit: limit);
    return await data.map((i)=>ExpenseModel.fromMap(i)).toList();
  }

  Future<int> updateExpenses(ExpenseModel expense)async{
    final db = await getDB();
    return await db.update('expenses', expense.toMap(), where: 'id = ?', whereArgs: [expense.id]);
  }

  Future<int> deleteExpenses(int id)async{
    final db = await getDB();
    return await db.delete('expenses',where: 'id=?', whereArgs: [id]);
  }

  Future<void> closeDB()async{
    final db = await getDB();
    db.close();
  }

  //CRUD for cards table

  Future<int> insertCard(CardModel card)async{
    final db = await getDB();
    return await db.insert('cards', card.toMap(),conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CardModel>> getAllCards()async{
    final db = await getDB();
    List<Map<String,dynamic>> data = await db.query('cards',orderBy: 'id DESC');
    return await data.map((i)=>CardModel.fromMap(i)).toList();
  }

  Future<int> updateCard(CardModel card)async{
    final db = await getDB();
    return await db.update('cards', card.toMap(),where: 'id = ?',whereArgs: [card.id]);
  }

  Future<int> deleteCard(int id)async{
    final db = await getDB();
    return await db.delete('cards',where: 'id = ?', whereArgs: [id]);
  }

//CRUD for budgets table

  Future<int> insertBudget(BudgetModel budget)async{
    final db = await getDB();
    return await db.insert('budgets', budget.toMap(),conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<BudgetModel>> getAllBudgets()async{
    final db = await getDB();
    List<Map<String,dynamic>> values = await db.query('budgets',orderBy: 'id DESC');
    return await values.map((i)=>BudgetModel.fromMap(i)).toList();
  }

  Future<int> updateBudget(BudgetModel budget)async{
    final db = await getDB();
    return await db.update('budgets', budget.toMap(),where: 'id = ?',whereArgs: [budget.id]);
  }

  Future<int> deleteBudget(int id)async{
    final db = await getDB();
    return await db.delete('budgets',where: 'id = ?',whereArgs: [id]);
  }

}