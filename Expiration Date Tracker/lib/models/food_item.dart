import 'dart:convert';
import 'package:flutter/material.dart';

class FoodItem {
  FoodItem({
    required this.name,
    required this.category,
    required this.expiry,
    required this.location,
    this.quantity = 1,
    Set<int>? reminderDays,
    this.photoUrl,
    this.localImagePath,
    this.localPhoto,
    this.barcode,
    String? id,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        reminderDays = reminderDays ?? {1, 3};

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id'] as String?,
        name: json['name'] as String,
        category: json['category'] as String,
        expiry: DateTime.parse(json['expiry'] as String),
        location: json['location'] as String? ?? 'Fridge',
        quantity: json['quantity'] as int? ?? 1,
        reminderDays:
            ((json['reminderDays'] as List?)?.cast<int>().toSet()) ?? {1, 3},
        photoUrl: json['photoUrl'] as String?,
        localPhoto: json['localPhoto'] as String?,
        barcode: json['barcode'] as String?,
      );

  final String id;
  final String name;
  final String category;
  final DateTime expiry;
  final String location;
  final int quantity;
  final Set<int> reminderDays;
  final String? photoUrl;
  final String? barcode;

  /// Used only while an image is waiting to upload to Firebase Storage.
  final String? localImagePath;
  final String? localPhoto;

  ImageProvider? get photoImage => localPhoto != null
      ? MemoryImage(base64Decode(localPhoto!))
      : photoUrl != null
          ? NetworkImage(photoUrl!)
          : null;

  int get daysLeft => DateTime.utc(expiry.year, expiry.month, expiry.day)
      .difference(DateTime.utc(
          DateTime.now().year, DateTime.now().month, DateTime.now().day))
      .inDays;
  String get expiryLabel => daysLeft < 0
      ? 'Expired ${-daysLeft} day${daysLeft == -1 ? '' : 's'} ago'
      : daysLeft == 0
          ? 'Expires today'
          : 'Expires in $daysLeft days';
  int notificationId(int days) => (id.hashCode & 0x3fffffff) + days;
  IconData get icon => iconForCategory(category);
  String get quantityGuidance => switch (category) {
        'Produce' =>
          'For $quantity ${quantity == 1 ? 'portion' : 'portions'}, plan 1–2 meals this week.',
        'Dairy' =>
          'A $quantity-item supply is best used within 3–5 days after opening.',
        'Meat' =>
          'Portion into meal-sized packs; $quantity serving${quantity == 1 ? '' : 's'} is a practical amount.',
        _ =>
          'Keep enough for $quantity meal${quantity == 1 ? '' : 's'} and restock when you are down to one.',
      };

  FoodItem copyWith(
          {int? quantity,
          String? name,
          String? category,
          DateTime? expiry,
          String? location,
          Set<int>? reminderDays,
          String? photoUrl,
          String? localImagePath,
          String? localPhoto,
          String? barcode}) =>
      FoodItem(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        expiry: expiry ?? this.expiry,
        location: location ?? this.location,
        quantity: quantity ?? this.quantity,
        reminderDays: reminderDays ?? this.reminderDays,
        photoUrl: photoUrl ?? this.photoUrl,
        localImagePath: localImagePath ?? this.localImagePath,
        localPhoto: localPhoto ?? this.localPhoto,
        barcode: barcode ?? this.barcode,
      );

  Map<String, dynamic> toJson({bool includeLocalPhoto = false}) => {
        if (includeLocalPhoto && localPhoto != null) 'localPhoto': localPhoto,
        'id': id,
        'name': name,
        'category': category,
        'expiry': expiry.toIso8601String(),
        'location': location,
        'quantity': quantity,
        'reminderDays': reminderDays.toList(),
        'photoUrl': photoUrl,
        'barcode': barcode,
      };
}

IconData iconForCategory(String category) => switch (category) {
      'Produce' => Icons.eco_outlined,
      'Dairy' => Icons.icecream_outlined,
      'Meat' => Icons.restaurant_outlined,
      'Frozen' => Icons.ac_unit,
      'Beverages' => Icons.local_drink_outlined,
      'Pantry' => Icons.inventory_2_outlined,
      _ => Icons.kitchen_outlined,
    };

String monthName(int month) => const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ][month - 1];
