import 'package:flutter/material.dart';

enum BookFormat { paperback, hardcover, ebook, poster }

extension BookFormatX on BookFormat {
  String get label => switch (this) {
        BookFormat.paperback => 'Paperback',
        BookFormat.hardcover => 'Hardcover',
        BookFormat.ebook => 'eBook',
        BookFormat.poster => 'Poster',
      };
  IconData get icon => switch (this) {
        BookFormat.paperback => Icons.menu_book_outlined,
        BookFormat.hardcover => Icons.book,
        BookFormat.ebook => Icons.tablet_mac_outlined,
        BookFormat.poster => Icons.image_outlined,
      };
}

class Language {
  final String code, name, native, script;
  const Language(this.code, this.name, this.native, this.script);
}

class Book {
  final String id, group, title, language, author, category, description, isbn;
  final int pages;
  final Map<BookFormat, int> prices;
  final int stock;
  final double rating;
  final int ratingCount;
  final Color color;
  final bool isNew, featured, subEligible, isPoster;
  final String aliases;
  final int newRank;

  const Book({
    required this.id,
    required this.group,
    required this.title,
    required this.language,
    required this.author,
    required this.category,
    required this.description,
    required this.isbn,
    required this.pages,
    required this.prices,
    required this.stock,
    required this.rating,
    required this.ratingCount,
    required this.color,
    this.isNew = false,
    this.featured = false,
    this.subEligible = true,
    this.isPoster = false,
    this.aliases = '',
    this.newRank = 0,
  });

  Book copyWith({String? title, int? stock, Map<BookFormat, int>? prices, String? category, bool? featured, bool? isNew, bool? subEligible, String? description}) => Book(
        id: id,
        group: group,
        title: title ?? this.title,
        language: language,
        author: author,
        category: category ?? this.category,
        description: description ?? this.description,
        isbn: isbn,
        pages: pages,
        prices: prices ?? this.prices,
        stock: stock ?? this.stock,
        rating: rating,
        ratingCount: ratingCount,
        color: color,
        isNew: isNew ?? this.isNew,
        featured: featured ?? this.featured,
        subEligible: subEligible ?? this.subEligible,
        isPoster: isPoster,
        aliases: aliases,
        newRank: newRank,
      );

  /// Formats that can be bought through the cart (physical goods).
  List<BookFormat> get purchasable =>
      prices.keys.where((f) => f != BookFormat.ebook).toList();

  int get basePrice => prices[purchasable.isNotEmpty ? purchasable.first : BookFormat.ebook] ?? 0;
  bool get inStock => stock > 0;
  bool get lowStock => stock > 0 && stock <= 10;
  bool get hasEbook => prices.containsKey(BookFormat.ebook);
}

class Plan {
  final String id, name, kind, blurb;
  final int monthly, yearly, trialDays;
  final List<String> perks;
  const Plan({
    required this.id,
    required this.name,
    required this.kind,
    required this.blurb,
    required this.monthly,
    required this.yearly,
    required this.trialDays,
    required this.perks,
  });
}

class CartLine {
  final String bookId;
  final BookFormat format;
  int qty;
  CartLine(this.bookId, this.format, this.qty);
}

class Address {
  final String id, name, phone, line1, city, state, pin, country;
  final String? gstin;
  Address({
    required this.id,
    required this.name,
    required this.phone,
    required this.line1,
    required this.city,
    required this.state,
    required this.pin,
    this.country = 'India',
    this.gstin,
  });
  bool get isIndia => country == 'India';
  String get oneLine => '$line1, $city, $state $pin${isIndia ? '' : ', $country'}';
}

class ShippingOption {
  final String id, name, courier, eta;
  final int fee;
  const ShippingOption(this.id, this.name, this.courier, this.eta, this.fee);
}

class OrderEvent {
  final String title, detail;
  final DateTime at;
  final bool whatsapp;
  const OrderEvent(this.title, this.detail, this.at, {this.whatsapp = false});
}

class OrderLine {
  final String bookId, title;
  final BookFormat format;
  final int qty, unitPrice;
  const OrderLine(this.bookId, this.title, this.format, this.qty, this.unitPrice);
}

class Order {
  final String id;
  final DateTime date;
  final List<OrderLine> lines;
  final Address address;
  final int subtotal, discount, shipping, tax, total;
  final String payment, courier, awb;
  int stage; // 0 confirmed … 5 delivered, -1 cancelled, -2 returned
  final bool isDonation;
  final bool isSubscription;
  Order({
    required this.id,
    required this.date,
    required this.lines,
    required this.address,
    required this.subtotal,
    required this.discount,
    required this.shipping,
    required this.tax,
    required this.total,
    required this.payment,
    required this.courier,
    required this.awb,
    required this.stage,
    this.isDonation = false,
    this.isSubscription = false,
  });
  static const stages = [
    'Order Confirmed',
    'Payment Received',
    'Order Packed',
    'Dispatched',
    'Out for Delivery',
    'Delivered',
  ];
  String get statusLabel => stage == -1
      ? 'Cancelled'
      : stage == -2
          ? 'Return Initiated'
          : stages[stage.clamp(0, 5)];
}

class Subscription {
  final String id, planId, title;
  final DateTime started;
  DateTime renews;
  String status; // trial, active, grace, paused, cancelled
  bool yearly, autoRenew;
  final bool gift;
  final String? giftTo;
  Subscription({
    required this.id,
    required this.planId,
    required this.title,
    required this.started,
    required this.renews,
    required this.status,
    this.yearly = false,
    this.autoRenew = true,
    this.gift = false,
    this.giftTo,
  });
}

class Review {
  final String name, text, date;
  final int stars;
  final bool verified;
  const Review(this.name, this.stars, this.text, this.date, {this.verified = true});
}

class AppNotification {
  final String title, body, channel;
  final DateTime at;
  bool read;
  AppNotification(this.title, this.body, this.channel, this.at, {this.read = false});
}

class Article {
  final String id, title, excerpt, author, date, readTime;
  final List<String> body, relatedGroups;
  final Color color;
  const Article(this.id, this.title, this.excerpt, this.author, this.date, this.readTime,
      this.body, this.relatedGroups, this.color);
}

class Chapter {
  final String title;
  final List<String> paragraphs;
  const Chapter(this.title, this.paragraphs);
}
