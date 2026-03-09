import '../models/coffee_model.dart';

class CoffeeData {
  static const List<CoffeeCategory> categories = [
    CoffeeCategory(id: 'all', name: 'Tất cả', icon: '☕'),
    CoffeeCategory(id: 'espresso', name: 'Espresso', icon: '🍵'),
    CoffeeCategory(id: 'latte', name: 'Latte', icon: '🥛'),
    CoffeeCategory(id: 'cappuccino', name: 'Cappuccino', icon: '☁️'),
    CoffeeCategory(id: 'cold_brew', name: 'Cold Brew', icon: '🧊'),
    CoffeeCategory(id: 'frappe', name: 'Frappe', icon: '🥤'),
  ];

  static const List<CoffeeItem> coffeeList = [
    CoffeeItem(
      id: '1',
      name: 'Espresso Đậm Đà',
      description:
          'Espresso nguyên chất với hương vị đậm đà, thơm nồng đặc trưng của hạt cà phê Arabica thượng hạng. Được pha chế theo công thức truyền thống Italy.',
      price: 35000,
      imageUrl:
          'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?w=400',
      categoryId: 'espresso',
      rating: 4.8,
      reviewCount: 256,
      isPopular: true,
    ),
    CoffeeItem(
      id: '2',
      name: 'Caramel Latte',
      description:
          'Sự kết hợp hoàn hảo giữa espresso đậm đà, sữa tươi mềm mịn và sốt caramel thơm ngọt. Thức uống lý tưởng cho buổi sáng.',
      price: 55000,
      imageUrl:
          'https://images.unsplash.com/photo-1561047029-3000c68339ca?w=400',
      categoryId: 'latte',
      rating: 4.7,
      reviewCount: 312,
      isPopular: true,
    ),
    CoffeeItem(
      id: '3',
      name: 'Cappuccino Cổ Điển',
      description:
          'Cappuccino truyền thống với lớp foam sữa mịn màng, tỉ lệ hoàn hảo giữa espresso và sữa. Được trang trí với bột cacao thơm.',
      price: 50000,
      imageUrl:
          'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400',
      categoryId: 'cappuccino',
      rating: 4.6,
      reviewCount: 189,
      isPopular: true,
    ),
    CoffeeItem(
      id: '4',
      name: 'Cold Brew Mật Ong',
      description:
          'Cold brew ủ lạnh 24 giờ kết hợp với mật ong nguyên chất. Vị đắng nhẹ, ngọt thanh, hoàn hảo cho những ngày hè nóng bức.',
      price: 60000,
      imageUrl:
          'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400',
      categoryId: 'cold_brew',
      rating: 4.9,
      reviewCount: 428,
      isPopular: true,
    ),
    CoffeeItem(
      id: '5',
      name: 'Matcha Frappe',
      description:
          'Frappe matcha Nhật Bản cao cấp với sữa tươi và kem tươi. Vị matcha đắng nhẹ, thơm mát, làm mới tinh thần hoàn toàn.',
      price: 65000,
      imageUrl:
          'https://images.unsplash.com/photo-1515823064-d6e0c04616a7?w=400',
      categoryId: 'frappe',
      rating: 4.5,
      reviewCount: 203,
    ),
    CoffeeItem(
      id: '6',
      name: 'Vanilla Latte',
      description:
          'Espresso kết hợp sữa hấp nóng và syrup vanilla thơm ngọt. Hương vị dịu dàng, ấm áp như một cái ôm trong buổi sáng.',
      price: 58000,
      imageUrl:
          'https://images.unsplash.com/photo-1485808191679-5f86510bd9d4?w=400',
      categoryId: 'latte',
      rating: 4.6,
      reviewCount: 267,
    ),
    CoffeeItem(
      id: '7',
      name: 'Americano Đen',
      description:
          'Americano với 2 shot espresso và nước nóng. Đơn giản nhưng tinh tế, dành cho những ai yêu cà phê thuần túy.',
      price: 40000,
      imageUrl:
          'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=400',
      categoryId: 'espresso',
      rating: 4.4,
      reviewCount: 145,
    ),
    CoffeeItem(
      id: '8',
      name: 'Chocolate Frappe',
      description:
          'Frappe chocolate Bỉ cao cấp với kem tươi và sốt chocolate đặc biệt. Thức uống hoàn hảo cho những tâm hồn yêu ngọt.',
      price: 68000,
      imageUrl:
          'https://images.unsplash.com/photo-1578374173705-969cbe6f2d6b?w=400',
      categoryId: 'frappe',
      rating: 4.7,
      reviewCount: 334,
      isPopular: true,
    ),
  ];
}
