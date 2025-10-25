class ExpenseModel{
  final int? id;
  final String title;
  final double amount;
  final String category;
  final String date;

  ExpenseModel({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date
  });

  factory ExpenseModel.fromMap(Map<String,dynamic> map){
    return ExpenseModel(
        id: map['id'],
        title: map['title'],
        amount: map['amount'],
        category: map['category'],
        date: map['date']
    );
  }

  Map<String,dynamic> toMap(){
    return {
      'id' : id,
      'title' : title,
      'amount': amount,
      'category' : category,
      'date' : date
    };
  }
}