# prm393_coffee

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Cấu trúc dự án (Project Structure)

Dự án này là một ứng dụng **Flutter** có tích hợp **Firebase**. Dưới đây là mô tả cấu trúc thư mục chính của dự án, đặc biệt là thư mục `lib/` chứa mã nguồn:

```text
PRM393_Coffee/
│
├── android/, ios/, web/, windows/ # Các nền tảng cụ thể mà Flutter hỗ trợ biên dịch
├── assets/                        # Chứa các tài nguyên tĩnh như hình ảnh (images), biểu tượng (icons)
├── build/                         # Chứa các tệp và file được build ra của dự án (auto-generated)
├── test/                          # Thư mục chứa các tệp kiểm thử (Unit test, Widget test)
│
├── lib/                           # Mã nguồn chính của ứng dụng
│   ├── core/                      # Chứa các yếu tố cốt lõi (ví dụ: constants, enums)
│   ├── data/                      # Nơi chứa các tệp dữ liệu tạo sẵn, mock data, data mapping
│   ├── models/                    # Định nghĩa cấu trúc dữ liệu (User, Coffee, Ingredient, Order,...)
│   ├── providers/                 # Chứa các file quản lý trạng thái (State Management) xử lý logic của app
│   ├── routes/                    # Quản lý điều hướng, thiết lập các route chuyển màn hình
│   ├── screens/                   # Các màn hình giao diện chính của ứng dụng (Cart, Detail, Dashboard,...)
│   ├── services/                  # Cung cấp các thao tác xử lý API, tương tác với Firebase hoặc Backend
│   ├── themes/                    # Định nghĩa màu sắc, font chữ và phong cách giao diện toàn nền tảng
│   ├── widgets/                   # Các thành phần UI độc lập, có thể tái sử dụng (components)
│   ├── firebase_options.dart      # File cài đặt môi trường và các dịch vụ Firebase (tự động gen từ Firebase CLI)
│   └── main.dart                  # File khởi chạy ứng dụng (Entry point)
│
├── firebase.json                  # Cấu hình các dịch vụ của Firebase
└── pubspec.yaml                   # Chứa thông tin cấu hình dự án, quản lý thư viện và assets
```
