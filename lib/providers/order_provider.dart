import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../core/enums/order_status.dart';
import '../services/firebase_service.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _orderSubscription;

  // ✅ Theo dõi các order đã trừ kho để tránh trừ trùng
  final Set<String> _deductedOrderIds = {};
  final Set<String> _restoredOrderIds = {};
  bool _isFirstStreamLoad = true;

  List<OrderModel> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get error => _error;

  OrderProvider() {
    startOrderListener();
  }

  void startOrderListener() {
    print('📦 Bắt đầu listener cập nhật Stream Đơn Hàng realtime...');
    if (_orderSubscription == null) {
      _setLoading(true);
      _orderSubscription = _firebaseService.getOrdersStream().listen(
            (newList) {
          // ✅ Phát hiện order mới để trừ kho (ngay khi đặt) & order hủy để cộng lại
          _detectAndProcessInventory(newList);

          _orders = newList;
          _error = null;
          _setLoading(false);
          notifyListeners();
        },
        onError: (e) {
          _error = 'Lỗi stream order: $e';
          _setLoading(false);
          notifyListeners();
        },
      );
    }
  }

  /// ✅ So sánh danh sách cũ và mới, xử lý ngay khi đăt đơn hoặc hủy đơn
  void _detectAndProcessInventory(List<OrderModel> newList) {
    if (_isFirstStreamLoad) {
      // Lần đầu load: theo dõi các đơn hiện tại để không xử lý lại
      for (final order in newList) {
        if (order.status == OrderStatus.cancelled) {
          _restoredOrderIds.add(order.id);
          _deductedOrderIds.add(order.id);
        } else {
          _deductedOrderIds.add(order.id);
        }
      }
      _isFirstStreamLoad = false;
      return;
    }

    for (final newOrder in newList) {
      if (newOrder.status == OrderStatus.cancelled) {
        // Nếu chuyển sang hủy và chưa được cộng lại
        if (!_restoredOrderIds.contains(newOrder.id) && _deductedOrderIds.contains(newOrder.id)) {
          _restoredOrderIds.add(newOrder.id);
          _processInventory(newOrder.id, isRestore: true);
          print('🔄 Auto-restore kho cho order ${newOrder.id} (status → cancelled)');
        }
      } else {
        // Nếu là đơn mới chưa được trừ kho
        if (!_deductedOrderIds.contains(newOrder.id)) {
          _deductedOrderIds.add(newOrder.id);
          _processInventory(newOrder.id, isRestore: false);
          print('🛒 Auto-deduct kho cho order ${newOrder.id} (đơn mới đặt)');
        }
      }
    }
  }

  // --- CREATE & UPDATE ---

  Future<bool> addItemsToExistingOrder({
    required String orderId,
    required List<OrderItemModel> newItems,
  }) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists) return false;

      List<dynamic> currentItemsRaw = List.from(doc.data()?['items'] ?? []);
      double currentTotal = (doc.data()?['totalAmount'] ?? 0).toDouble();

      final batchId = 'add_${DateTime.now().millisecondsSinceEpoch}';

      for (var newItem in newItems) {
        final itemWithBatch = OrderItemModel(
          menuItemId: newItem.menuItemId,
          menuItemName: newItem.menuItemName,
          unitPrice: newItem.unitPrice,
          quantity: newItem.quantity,
          note: newItem.note,
          isDone: newItem.isDone,
          batchId: batchId,
        );
        currentItemsRaw.add(itemWithBatch.toMap());
        currentTotal += (itemWithBatch.unitPrice * itemWithBatch.quantity);
      }

      await _firestore.collection('orders').doc(orderId).update({
        'items': currentItemsRaw,
        'totalAmount': currentTotal,
        'updatedAt': FieldValue.serverTimestamp(),
        'batchStatus.$batchId': 'pending',
        'status': 'pending',
      });
      return true;
    } catch (e) {
      print('❌ Lỗi thêm món: $e');
      return false;
    }
  }

  Future<String?> createOrder({
    required String tableId,
    required int tableNumber,
    required String waiterId,
    required String waiterName,
    required List<OrderItemModel> items,
    required double totalAmount,
  }) async {
    try {
      final orderId = await _firebaseService.createOrder(
        tableId: tableId,
        tableNumber: tableNumber,
        waiterId: waiterId,
        waiterName: waiterName,
        items: items,
        totalAmount: totalAmount,
      );
      return orderId;
    } catch (e) {
      _error = 'Lỗi tạo order: $e';
      return null;
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      // Cập nhật trạng thái đơn hàng
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus.toString().split('.').last,
      });
      // ✅ Trừ/cộng kho được xử lý tự động trong stream listener (_detectAndProcessInventory)
      notifyListeners();
    } catch (e) {
      print('❌ Lỗi updateOrderStatus: $e');
    }
  }

  Future<void> _processInventory(String orderId, {required bool isRestore}) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return;
      
      final data = orderDoc.data();
      final isDeducted = data?['isInventoryDeducted'] == true;
      final isRestored = data?['isInventoryRestored'] == true;

      // Bảo vệ không thực thi kép
      if (!isRestore && isDeducted) return;
      if (isRestore && isRestored) return;
      if (isRestore && !isDeducted) return; // Không thể cộng lại nếu chưa từng trừ

      final List items = data?['items'] ?? [];

      final Map<String, double> ingredientChanges = {};
      final Map<String, int> menuItemQuantities = {};

      for (var itemData in items) {
        final String menuItemId = itemData['menuItemId'];
        final int quantityOrdered = (itemData['quantity'] as num).toInt();

        menuItemQuantities[menuItemId] = (menuItemQuantities[menuItemId] ?? 0) + quantityOrdered;

        final menuSnap = await _firestore.collection('menuItems').doc(menuItemId).get();
        if (menuSnap.exists && menuSnap.data()!.containsKey('recipe')) {
          final recipe = Map<String, dynamic>.from(menuSnap.data()!['recipe']);

          for (var entry in recipe.entries) {
            final String ingredientId = entry.key;
            final double dosage = (entry.value as num).toDouble();
            final double totalChange = dosage * quantityOrdered;
            ingredientChanges[ingredientId] = (ingredientChanges[ingredientId] ?? 0) + totalChange;
          }
        }
      }

      if (ingredientChanges.isEmpty && menuItemQuantities.isEmpty) {
        if (isRestore) {
          await _firestore.collection('orders').doc(orderId).update({'isInventoryRestored': true});
        } else {
          await _firestore.collection('orders').doc(orderId).update({'isInventoryDeducted': true});
        }
        return;
      }

      // ✅ Dùng 1 Transaction ĐƠN NHẤT để kiểm tra & cập nhật đồng loạt
      await _firestore.runTransaction((tx) async {
        final orderRef = _firestore.collection('orders').doc(orderId);
        final txOrderSnap = await tx.get(orderRef);
        
        // Kiểm tra lại khóa bảo vệ bên trong Transaction
        if (!txOrderSnap.exists) return;
        final txData = txOrderSnap.data();
        if (!isRestore && txData?['isInventoryDeducted'] == true) return;
        if (isRestore && txData?['isInventoryRestored'] == true) return;

        // Đọc snapshot nguyên liệu
        final Map<String, DocumentReference> ingRefs = {};
        final Map<String, DocumentSnapshot> ingSnaps = {};
        for (var entry in ingredientChanges.entries) {
          final ref = _firestore.collection('ingredients').doc(entry.key);
          ingRefs[entry.key] = ref;
          ingSnaps[entry.key] = await tx.get(ref);
        }

        // Đọc snapshot món ăn
        final Map<String, DocumentReference> menuRefs = {};
        final Map<String, DocumentSnapshot> menuSnaps = {};
        for (var entry in menuItemQuantities.entries) {
          final ref = _firestore.collection('menuItems').doc(entry.key);
          menuRefs[entry.key] = ref;
          menuSnaps[entry.key] = await tx.get(ref);
        }

        // Ghi dữ liệu nguyên liệu
        for (var entry in ingredientChanges.entries) {
          final snap = ingSnaps[entry.key];
          if (snap != null && snap.exists) {
            final currentStock = (snap.data() as Map<String, dynamic>)['stock'] ?? 0.0;
            double currentStockNum = currentStock is num ? currentStock.toDouble() : 0.0;
            double newStock;
            if (isRestore) {
              newStock = currentStockNum + entry.value;
            } else {
              newStock = (currentStockNum - entry.value).clamp(0.0, double.infinity);
            }
            tx.update(ingRefs[entry.key]!, {'stock': newStock});
          }
        }

        // Ghi dữ liệu món ăn (số lượng)
        for (var entry in menuItemQuantities.entries) {
          final snap = menuSnaps[entry.key];
          if (snap != null && snap.exists) {
            final currentQty = (snap.data() as Map<String, dynamic>)['quantity'] ?? 0;
            int currentQtyNum = currentQty is num ? currentQty.toInt() : 0;
            int newQty;
            if (isRestore) {
              newQty = currentQtyNum + entry.value;
            } else {
              newQty = (currentQtyNum - entry.value).clamp(0, 999999);
            }
            tx.update(menuRefs[entry.key]!, {'quantity': newQty});
          }
        }

        // Đánh dấu order đã được xử lý kho
        if (isRestore) {
          tx.update(orderRef, {'isInventoryRestored': true});
        } else {
          tx.update(orderRef, {'isInventoryDeducted': true});
        }
      });

      notifyListeners();
      print(isRestore 
          ? '✅ Đã RESTORE kho & quantity món ăn bằng Transaction!' 
          : '✅ Đã DEDUCT kho & quantity món ăn bằng Transaction!');

    } catch (e) {
      print('❌ Lỗi hệ thống cập nhật kho: $e');
    }
  }

  // --- QUERIES ---
  List<OrderModel> ordersByTable(String tableId) {
    return _orders.where((o) => o.tableId == tableId).toList();
  }

  List<OrderModel> get pendingOrders =>
      _orders.where((o) => o.status == OrderStatus.pending).toList();

  List<OrderModel> get preparingOrders =>
      _orders.where((o) => o.status == OrderStatus.preparing).toList();

  Future<void> updateOrderBatchStatus({
    required String orderId,
    required String batchId,
    required OrderStatus status,
  }) async {
    try {
      final statusString = status.toString().split('.').last;
      await _firebaseService.updateOrderBatchStatus(
        orderId: orderId,
        batchId: batchId,
        status: statusString,
      );
    } catch (e) {
      _error = 'Lỗi cập nhật trạng thái card: $e';
    }
  }

  Future<void> updateOrderItems(String orderId, List<OrderItemModel> items) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'items': items.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      print("❌ Lỗi cập nhật món: $e");
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _firebaseService.updateOrderStatus(orderId, 'cancelled');
    } catch (e) {
      _error = 'Lỗi hủy đơn: $e';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }
}