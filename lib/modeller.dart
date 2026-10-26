import 'dart:typed_data';

class Antique {
  const Antique({
    this.id,
    required this.name,
    required this.category,
    required this.year,
    required this.history,
    required this.value,
    this.purchasePrice = 0,
    this.extraCosts = 0,
    required this.quantity,
    this.minimumStock = 3,
    required this.offer,
    required this.auctionLocation,
    this.location = '',
    this.photoUrl,
    this.condition = '',
    this.conditionPhotoUrl,
    this.selectedPhotoBytes,
    this.selectedPhotoName,
    this.selectedConditionPhotoBytes,
    this.selectedConditionPhotoName,
  });

  final int? id;
  final String name;
  final String category;
  final int year;
  final String history;
  final double value;
  final double purchasePrice;
  final double extraCosts;
  final int quantity;
  final int minimumStock;
  final String offer;
  final String auctionLocation;
  final String location;
  final String? photoUrl;
  final String condition;
  final String? conditionPhotoUrl;
  final Uint8List? selectedPhotoBytes;
  final String? selectedPhotoName;
  final Uint8List? selectedConditionPhotoBytes;
  final String? selectedConditionPhotoName;
}

class Auction {
  const Auction({
    this.id,
    required this.productId,
    required this.startingPrice,
    required this.currentBid,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.auctionLocation,
    this.winner = '',
    this.finalPrice = 0,
    this.paymentStatus = 'Bekliyor',
    this.deliveryStatus = 'Bekliyor',
  });

  final int? id;
  final int productId;
  final double startingPrice;
  final double currentBid;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String auctionLocation;
  final String winner;
  final double finalPrice;
  final String paymentStatus;
  final String deliveryStatus;
}

class AntiqueSale {
  const AntiqueSale({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.unitCost = 0,
    this.productId,
    required this.buyer,
    required this.soldAt,
  });

  final int id;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double unitCost;
  final int? productId;
  final String buyer;
  final DateTime soldAt;

  double get total => quantity * unitPrice;
  double get netProfit => quantity * (unitPrice - unitCost);
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    required this.createdAt,
  });

  final int id;
  final String productName;
  final String type;
  final int quantity;
  final int previousStock;
  final int newStock;
  final DateTime createdAt;
}

class CustomerSummary {
  const CustomerSummary({
    required this.name,
    required this.purchaseCount,
    required this.itemCount,
    required this.totalSpent,
    required this.lastPurchase,
    required this.products,
  });

  final String name;
  final int purchaseCount;
  final int itemCount;
  final double totalSpent;
  final DateTime lastPurchase;
  final List<String> products;
}
