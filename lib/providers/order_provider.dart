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

  /// Số dòng món đã thấy lần trước trên stream (để phát hiện đặt thêm lần 2, 3…)
  final Map<String, int> _lastKnownItemLineCountByOrderId = {};

  /// Xử lý kho tuần tự — tránh 2 emit chồng nhau làm sai số dòng / trừ kho
  Future<void> _inventoryProcessQueue = Future.value();

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
          _orders = newList;
          _error = null;
          _setLoading(false);
          notifyListeners();

          // ✅ Trừ kho theo stream (đơn mới + mỗi lần đặt thêm) — xếp hàng tuần tự
          _inventoryProcessQueue = _inventoryProcessQueue.then((_) async {
            try {
              await _detectAndProcessInventoryAsync(newList);
            } catch (e) {
              print('❌ Lỗi xử lý kho từ stream đơn hàng: $e');
            }
          });
        },
        onError: (e) {
          _error = 'Lỗi stream order: $e';
          _setLoading(false);
          notifyListeners();
        },
      );
    }
  }

  /// So sánh stream: đơn mới trừ full; cùng đơn mà [items] dài thêm → trừ đúng phần đặt thêm (lần 2, 3…).
  Future<void> _detectAndProcessInventoryAsync(List<OrderModel> newList) async {
    if (_isFirstStreamLoad) {
      for (final order in newList) {
        if (order.status == OrderStatus.cancelled) {
          _restoredOrderIds.add(order.id);
          _deductedOrderIds.add(order.id);
        } else {
          _deductedOrderIds.add(order.id);
        }
        _lastKnownItemLineCountByOrderId[order.id] = order.items.length;
      }
      _isFirstStreamLoad = false;
      return;
    }

    final seenIds = <String>{};

    for (final newOrder in newList) {
      seenIds.add(newOrder.id);
      final prevLineCount = _lastKnownItemLineCountByOrderId[newOrder.id];

      if (newOrder.status == OrderStatus.cancelled) {
        if (!_restoredOrderIds.contains(newOrder.id) &&
            _deductedOrderIds.contains(newOrder.id)) {
          _restoredOrderIds.add(newOrder.id);
          await _processInventory(newOrder.id, isRestore: true);
          print('🔄 Auto-restore kho cho order ${newOrder.id} (status → cancelled)');
        }
        _lastKnownItemLineCountByOrderId[newOrder.id] = newOrder.items.length;
        continue;
      }

      if (!_deductedOrderIds.contains(newOrder.id)) {
        _deductedOrderIds.add(newOrder.id);
        await _processInventory(newOrder.id, isRestore: false);
        print('🛒 Auto-deduct kho cho order ${newOrder.id} (đơn mới đặt)');
      } else if (prevLineCount != null &&
          newOrder.items.length > prevLineCount) {
        // Đơn đã trừ kho trước đó; có thêm dòng món (đặt thêm)
        final deltaItems =
            newOrder.items.sublist(prevLineCount, newOrder.items.length);
        await _deductStockForItemsOnly(deltaItems);
        print(
          '🛒 Trừ kho cho đặt thêm: order ${newOrder.id} (+${deltaItems.length} dòng)',
        );
      }

      _lastKnownItemLineCountByOrderId[newOrder.id] = newOrder.items.length;
    }

    _lastKnownItemLineCountByOrderId
        .removeWhere((id, _) => !seenIds.contains(id));
  }

  // --- CREATE & UPDATE ---

  /// Cập nhật đơn trên Firestore. Trừ kho cho món đặt thêm do [_detectAndProcessInventoryAsync] xử lý khi stream nhận đơn mới.
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

  static Map<String, dynamic> _parseRecipeMap(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map) {
      final out = <String, dynamic>{};
      for (final e in raw.entries) {
        out[e.key.toString()] = e.value;
      }
      return out;
    }
    return {};
  }

  static double _parseDosage(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  /// Trừ kho + quantity món (theo công thức) cho một tập dòng order — không đụng cờ đơn hàng.
  /// Dùng khi đặt thêm món vào đơn đã trừ kho trước đó.
  Future<void> _deductStockForItemsOnly(
    List<OrderItemModel> items, {
    Map<String, Map<String, dynamic>>? recipesByMenuItemId,
  }) async {
    if (items.isEmpty) return;

    final Map<String, double> ingredientChanges = {};
    final Map<String, int> menuItemQuantities = {};

    for (final item in items) {
      final String menuItemId = item.menuItemId;
      final int quantityOrdered = item.quantity;

      menuItemQuantities[menuItemId] =
          (menuItemQuantities[menuItemId] ?? 0) + quantityOrdered;

      // Giống _processInventory khi hủy đơn: đọc recipe từ Firestore trước (nguồn chuẩn).
      // Trước đây ưu tiên MenuProvider nên client lệch/cũ → đặt thêm không trừ kho dù hủy vẫn hoàn đủ.
      Map<String, dynamic> recipe = {};
      final menuSnap =
          await _firestore.collection('menuItems').doc(menuItemId).get();
      if (menuSnap.exists) {
        final data = menuSnap.data()!;
        recipe = _parseRecipeMap(data['recipe']);
        if (recipe.isEmpty) {
          recipe = _parseRecipeMap(data['Recipe']);
        }
      }
      if (recipe.isEmpty) {
        final fallback = recipesByMenuItemId?[menuItemId];
        if (fallback != null && fallback.isNotEmpty) {
          recipe = Map<String, dynamic>.from(fallback);
        }
      }

      if (recipe.isEmpty) {
        debugPrint(
          '⚠️ Đặt thêm: món $menuItemId không có recipe (kho nguyên liệu không trừ). Hãy gán công thức ở Manager.',
        );
      }

      for (final entry in recipe.entries) {
        final String ingredientId = entry.key;
        final double dosage = _parseDosage(entry.value);
        if (dosage <= 0) continue;
        final double totalChange = dosage * quantityOrdered;
        ingredientChanges[ingredientId] =
            (ingredientChanges[ingredientId] ?? 0) + totalChange;
      }
    }

    if (ingredientChanges.isEmpty && menuItemQuantities.isEmpty) return;

    try {
      await _firestore.runTransaction((tx) async {
        final Map<String, DocumentReference> ingRefs = {};
        final Map<String, DocumentSnapshot> ingSnaps = {};
        for (final entry in ingredientChanges.entries) {
          final ref = _firestore.collection('ingredients').doc(entry.key);
          ingRefs[entry.key] = ref;
          ingSnaps[entry.key] = await tx.get(ref);
        }

        final Map<String, DocumentReference> menuRefs = {};
        final Map<String, DocumentSnapshot> menuSnaps = {};
        for (final entry in menuItemQuantities.entries) {
          final ref = _firestore.collection('menuItems').doc(entry.key);
          menuRefs[entry.key] = ref;
          menuSnaps[entry.key] = await tx.get(ref);
        }

        for (final entry in ingredientChanges.entries) {
          final snap = ingSnaps[entry.key];
          if (snap != null && snap.exists) {
            final currentStock =
                (snap.data() as Map<String, dynamic>)['stock'] ?? 0.0;
            final double currentStockNum =
                currentStock is num ? currentStock.toDouble() : 0.0;
            final newStock =
                (currentStockNum - entry.value).clamp(0.0, double.infinity);
            tx.update(ingRefs[entry.key]!, {'stock': newStock});
          }
        }

        for (final entry in menuItemQuantities.entries) {
          final snap = menuSnaps[entry.key];
          if (snap != null && snap.exists) {
            final currentQty =
                (snap.data() as Map<String, dynamic>)['quantity'] ?? 0;
            final int currentQtyNum =
                currentQty is num ? currentQty.toInt() : 0;
            final newQty =
                (currentQtyNum - entry.value).clamp(0, 999999);
            tx.update(menuRefs[entry.key]!, {'quantity': newQty});
          }
        }
      });

      notifyListeners();
      print('✅ Đã trừ kho cho món đặt thêm (${items.length} dòng)');
    } catch (e) {
      print('❌ Lỗi trừ kho khi đặt thêm món: $e');
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
        Map<String, dynamic> recipe = {};
        if (menuSnap.exists) {
          final d = menuSnap.data()!;
          recipe = _parseRecipeMap(d['recipe']);
          if (recipe.isEmpty) recipe = _parseRecipeMap(d['Recipe']);
        }
        for (final entry in recipe.entries) {
          final String ingredientId = entry.key;
          final double dosage = _parseDosage(entry.value);
          if (dosage <= 0) continue;
          final double totalChange = dosage * quantityOrdered;
          ingredientChanges[ingredientId] =
              (ingredientChanges[ingredientId] ?? 0) + totalChange;
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

  /// Chuẩn hóa batchId (Firestore dùng key 'initial' cho lần đặt đầu).
  static String _normBatchId(String? batchId) =>
      (batchId == null || batchId.isEmpty) ? 'initial' : batchId;

  /// Hoàn kho + quantity món khi hủy một số lần (card) trong đơn — đối xứng [_deductStockForItemsOnly].
  Future<void> _restoreStockForItemsOnly(List<OrderItemModel> items) async {
    if (items.isEmpty) return;

    final Map<String, double> ingredientChanges = {};
    final Map<String, int> menuItemQuantities = {};

    for (final item in items) {
      final String menuItemId = item.menuItemId;
      final int quantityOrdered = item.quantity;

      menuItemQuantities[menuItemId] =
          (menuItemQuantities[menuItemId] ?? 0) + quantityOrdered;

      Map<String, dynamic> recipe = {};
      final menuSnap =
          await _firestore.collection('menuItems').doc(menuItemId).get();
      if (menuSnap.exists) {
        final data = menuSnap.data()!;
        recipe = _parseRecipeMap(data['recipe']);
        if (recipe.isEmpty) recipe = _parseRecipeMap(data['Recipe']);
      }

      for (final entry in recipe.entries) {
        final String ingredientId = entry.key;
        final double dosage = _parseDosage(entry.value);
        if (dosage <= 0) continue;
        final double totalChange = dosage * quantityOrdered;
        ingredientChanges[ingredientId] =
            (ingredientChanges[ingredientId] ?? 0) + totalChange;
      }
    }

    if (ingredientChanges.isEmpty && menuItemQuantities.isEmpty) return;

    try {
      await _firestore.runTransaction((tx) async {
        for (final entry in ingredientChanges.entries) {
          final ref = _firestore.collection('ingredients').doc(entry.key);
          final snap = await tx.get(ref);
          if (snap.exists) {
            final currentStock =
                (snap.data() as Map<String, dynamic>)['stock'] ?? 0.0;
            final double cur =
                currentStock is num ? currentStock.toDouble() : 0.0;
            tx.update(ref, {'stock': cur + entry.value});
          }
        }
        for (final entry in menuItemQuantities.entries) {
          final ref = _firestore.collection('menuItems').doc(entry.key);
          final snap = await tx.get(ref);
          if (snap.exists) {
            final currentQty =
                (snap.data() as Map<String, dynamic>)['quantity'] ?? 0;
            final int cur = currentQty is num ? currentQty.toInt() : 0;
            tx.update(ref, {'quantity': (cur + entry.value).clamp(0, 999999)});
          }
        }
      });
      notifyListeners();
      print('✅ Đã hoàn kho cho ${items.length} dòng món đã hủy');
    } catch (e) {
      print('❌ Lỗi hoàn kho khi hủy lần: $e');
      rethrow;
    }
  }

  static String _recomputeOrderStatusFromBatchMap(Map<String, String> bs) {
    if (bs.isEmpty) return 'cancelled';
    final vals = bs.values.map((e) => e.toString()).toList();
    if (vals.any((s) => s == 'pending')) return 'pending';
    if (vals.any((s) => s == 'preparing')) return 'preparing';
    if (vals.every((s) => s == 'completed')) return 'completed';
    return 'pending';
  }

  /// Hủy một hoặc nhiều lần đặt (card) theo [batchIds] — xóa món thuộc các batch đó, cập nhật tổng tiền, hoàn kho.
  /// Trả về `true` nếu đơn còn món; `false` nếu đã hủy hết (đơn chuyển sang cancelled — UI nên mở bàn).
  Future<bool> cancelOrderBatches({
    required String orderId,
    required List<String> batchIds,
  }) async {
    if (batchIds.isEmpty) {
      throw Exception('Chọn ít nhất một lần đặt để hủy');
    }

    final cancelSet = batchIds.map(_normBatchId).toSet();

    final snap = await _firestore.collection('orders').doc(orderId).get();
    if (!snap.exists) throw Exception('Không tìm thấy đơn');
    final data = snap.data()!;
    final orderStatus = data['status'] as String? ?? 'pending';
    if (orderStatus == 'completed' || orderStatus == 'served') {
      throw Exception('Không thể hủy khi đơn đã hoàn thành/đã phục vụ');
    }
    if (orderStatus == 'cancelled') {
      throw Exception('Đơn đã bị hủy');
    }

    final rawBatchStatus = Map<String, dynamic>.from(
      (data['batchStatus'] as Map?) ?? {},
    );
    final itemsRaw = (data['items'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    for (final bid in cancelSet) {
      final st = (rawBatchStatus[bid] ?? 'pending').toString();
      if (st == 'completed') {
        throw Exception(
          'Không thể hủy lần đã hoàn thành (Lần có batch "$bid")',
        );
      }
    }

    final keptItems = <Map<String, dynamic>>[];
    final removedMaps = <Map<String, dynamic>>[];
    for (final item in itemsRaw) {
      final bid = _normBatchId(item['batchId'] as String?);
      if (cancelSet.contains(bid)) {
        removedMaps.add(item);
      } else {
        keptItems.add(item);
      }
    }

    if (removedMaps.isEmpty) {
      throw Exception('Không có món nào thuộc các lần đã chọn');
    }

    final removedOrderItems =
        removedMaps.map((m) => OrderItemModel.fromMap(m)).toList();

    final remainingBatchIds = keptItems.map((m) => _normBatchId(m['batchId'] as String?)).toSet();

    final newBatchStatus = <String, String>{};
    for (final b in remainingBatchIds) {
      if (rawBatchStatus.containsKey(b)) {
        newBatchStatus[b] = rawBatchStatus[b].toString();
      } else {
        newBatchStatus[b] = 'pending';
      }
    }

    double newTotal = 0;
    for (final item in keptItems) {
      final up = (item['unitPrice'] as num?)?.toDouble() ?? 0;
      final q = (item['quantity'] as num?)?.toInt() ?? 0;
      newTotal += up * q;
    }

    final overall = keptItems.isEmpty
        ? 'cancelled'
        : _recomputeOrderStatusFromBatchMap(newBatchStatus);

    await _firestore.runTransaction((tx) async {
      final ref = _firestore.collection('orders').doc(orderId);
      final cur = await tx.get(ref);
      if (!cur.exists) return;
      final d = cur.data()!;
      if ((d['status'] as String?) == 'completed' ||
          (d['status'] as String?) == 'served') {
        return;
      }

      if (keptItems.isEmpty) {
        tx.update(ref, {
          'items': [],
          'totalAmount': 0,
          'batchStatus': {},
          'status': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.update(ref, {
          'items': keptItems,
          'totalAmount': newTotal,
          'batchStatus': newBatchStatus,
          'status': overall,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });

    final verify = await _firestore.collection('orders').doc(orderId).get();
    final vLen = (verify.data()?['items'] as List?)?.length ?? -1;
    if (vLen != keptItems.length) {
      throw Exception(
        'Không thể hủy — trạng thái đơn đã thay đổi. Vui lòng thử lại.',
      );
    }

    await _restoreStockForItemsOnly(removedOrderItems);
    notifyListeners();
    return keptItems.isNotEmpty;
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