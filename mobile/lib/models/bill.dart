class BillItem {
  final String name;
  final int qty;
  final double price;
  final String category;
  BillItem(this.name, this.qty, this.price, this.category);

  factory BillItem.fromJson(Map<String, dynamic> j) => BillItem(
        j['name'] as String,
        (j['qty'] as num).toInt(),
        (j['price'] as num).toDouble(),
        j['category'] as String,
      );
}

class Bill {
  final int id;
  final String provider;
  final String date;
  final double total;
  final List<BillItem> items;
  final List<String> flags;

  Bill(this.id, this.provider, this.date, this.total, this.items, this.flags);

  factory Bill.fromJson(Map<String, dynamic> j) => Bill(
        j['id'] as int,
        j['provider'] as String,
        j['bill_date'] as String,
        (j['total'] as num).toDouble(),
        (j['items'] as List).map((e) => BillItem.fromJson(e as Map<String, dynamic>)).toList(),
        (j['flags'] as List).map((e) => (e as Map<String, dynamic>)['message'] as String).toList(),
      );
}

String rupees(num v) => '₹${v.toStringAsFixed(v % 1 == 0 ? 0 : 2)}';
