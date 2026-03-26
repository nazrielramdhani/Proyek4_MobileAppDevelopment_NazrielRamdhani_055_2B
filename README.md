## Refleksi Penerapan Single Responsibility Principle (SRP)

Penerapan prinsip Single Responsibility Principle (SRP) sangat membantu saya saat menambahkan fitur History Logger pada aplikasi Counter ini.

Dengan memisahkan tanggung jawab antara Controller dan View, seluruh logika bisnis seperti pengelolaan counter, step, dan riwayat aktivitas ditempatkan di CounterController. Sementara itu, CounterView hanya bertugas menampilkan data dan menangani interaksi pengguna.

Saat menambahkan fitur History Logger, saya tidak perlu mengubah struktur utama aplikasi. Saya hanya menambahkan List untuk menyimpan riwayat dan memanggil pencatatan aktivitas di setiap fungsi increment, decrement, dan reset pada Controller. View cukup membaca data history dan menampilkannya dalam bentuk ListView.

Prinsip SRP membuat kode lebih terstruktur, mudah dipahami, dan mempermudah pengembangan fitur baru tanpa merusak bagian lain dari aplikasi.
