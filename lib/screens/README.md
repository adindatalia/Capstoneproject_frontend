# Screens - ResepIn App

## Struktur Folder

```
screens/
├── auth/                    # Halaman autentikasi
│   ├── login_screen.dart   # Halaman login
│   └── register_screen.dart # Halaman registrasi
├── home/                   # Halaman beranda
│   └── home_screen.dart    # Halaman utama dengan resep terbaru
├── search/                 # Halaman pencarian
│   └── search_screen.dart  # Halaman pencarian resep dan filter bahan
├── recipe/                 # Halaman detail resep
│   └── recipe_detail_screen.dart # Detail resep dengan instruksi lengkap
├── favorites/              # Halaman favorit
│   └── favorites_screen.dart # Halaman resep favorit pengguna
├── profile/                # Halaman profil
│   └── profile_screen.dart # Halaman profil pengguna dan pengaturan
└── main_scaffold.dart      # Scaffold utama dengan bottom navigation
```

## Fitur Desain Baru

### 🎨 Design System

- **Color Palette**: Orange primary (#FF6B35), Green secondary (#4CAF50), Pink accent (#E91E63)
- **Typography**: Google Fonts (Poppins untuk heading, Inter untuk body text)
- **Spacing**: Konsisten 8px grid system
- **Border Radius**: Rounded corners dengan radius 12-20px

### ✨ Animasi & Interaksi

- **Smooth Transitions**: Slide dan fade animations pada navigasi
- **Haptic Feedback**: Getaran ringan pada interaksi penting
- **Loading States**: Shimmer loading dan skeleton screens
- **Micro-interactions**: Hover effects dan animated buttons

### 📱 Bottom Navigation

- **Modern Design**: Floating bottom navigation dengan shadow
- **Color-coded Icons**: Setiap tab memiliki warna unik
- **Smooth Transitions**: Page transitions yang smooth
- **Visual Feedback**: Active state yang jelas

## Detail Halaman

### 🔐 Authentication (auth/)

- **Login Screen**: Form login dengan validasi real-time
- **Register Screen**: Form registrasi dengan konfirmasi password
- **Visual Design**: Gradient backgrounds dengan ilustrasi

### 🏠 Home Screen (home/)

- **Hero Section**: Welcome message dengan search bar
- **Categories**: Horizontal scrollable categories dengan icons
- **Featured Section**: Banner promosi dengan gradient
- **Recipe Grid**: Grid resep dengan rating dan waktu masak

### 🔍 Search Screen (search/)

- **Advanced Search**: Search bar dengan voice input
- **Ingredient Filter**: Visual ingredient selector dengan emoji
- **Recent Searches**: History pencarian sebelumnya
- **Popular Searches**: Trending searches dengan badges

### 📖 Recipe Detail (recipe/)

- **Hero Image**: Large image header dengan parallax effect
- **Recipe Info**: Waktu masak, porsi, dan level kesulitan
- **Ingredients**: List bahan dengan quantity adjuster
- **Instructions**: Step-by-step dengan timeline visual
- **Nutrition**: Bar chart informasi gizi

### ❤️ Favorites (favorites/)

- **Tabbed Interface**: Filter by "Semua", "Baru Saja", "Paling Suka"
- **Recipe Cards**: Horizontal layout dengan kategori tags
- **Empty States**: Ilustrasi dan call-to-action yang menarik
- **Date Information**: Kapan resep ditambahkan ke favorit

### 👤 Profile (profile/)

- **Header Section**: Avatar dengan gradient background
- **Stats Cards**: Resep favorit, dibuat, dan poin
- **Menu Items**: Organized menu dengan icons dan descriptions
- **Settings**: Notifikasi, bantuan, dan tentang aplikasi

## Teknologi yang Digunakan

### 🛠️ Flutter Packages

- `google_fonts`: Typography yang konsisten
- `provider`: State management
- `flutter_svg`: Icon dan ilustrasi vector
- `http`: API communication
- `shared_preferences`: Local storage

### 🎭 Animation Libraries

- `TickerProviderStateMixin`: Untuk custom animations
- `AnimationController`: Kontrol animasi yang presisi
- `CurvedAnimation`: Easing curves yang natural

### 📐 Layout Techniques

- `CustomScrollView`: Advanced scrolling behaviors
- `SliverAppBar`: Collapsible app bars
- `GridView.builder`: Efficient grid layouts
- `PageView`: Smooth page transitions

## Best Practices

### 🏗️ Architecture

- **Separation of Concerns**: Setiap screen memiliki tanggung jawab yang jelas
- **Reusable Components**: Widget yang dapat digunakan kembali
- **Consistent Naming**: Konvensi penamaan yang konsisten

### 🎨 Design Patterns

- **Material Design 3**: Mengikuti guidelines terbaru
- **Responsive Design**: Adaptif untuk berbagai ukuran layar
- **Accessibility**: Support untuk screen readers dan keyboard navigation

### ⚡ Performance

- **Lazy Loading**: Memuat data sesuai kebutuhan
- **Image Optimization**: Placeholder dan caching
- **Memory Management**: Proper disposal untuk animations

## Cara Penggunaan

1. **Import Screen**:

   ```dart
   import 'package:frontend/screens/home/home_screen.dart';
   ```

2. **Navigation**:

   ```dart
   Navigator.push(
     context,
     PageRouteBuilder(
       pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
       transitionsBuilder: (context, animation, secondaryAnimation, child) {
         return SlideTransition(
           position: Tween<Offset>(
             begin: const Offset(1.0, 0.0),
             end: Offset.zero,
           ).animate(animation),
           child: child,
         );
       },
     ),
   );
   ```

3. **State Management**:
   ```dart
   Provider.of<AuthProvider>(context, listen: false)
   ```

## Future Enhancements

### 🎯 Performance Optimizations

- [ ] Image lazy loading dengan cached_network_image
- [ ] Pagination untuk recipe lists
- [ ] Background sync untuk favorites
- [ ] Prefetching untuk popular recipes
