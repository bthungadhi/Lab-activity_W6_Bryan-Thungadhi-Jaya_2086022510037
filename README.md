1. model disini cuma untuk menyimpan book dan loan, view itu UI yang menampilkan interaksi user, viewmodel simpan state dan aturan perpustakaan
2. buku tidak bisa dipinjam karena bukunya belum dikembalikan tombol Borrow juga disembunyikan di UI, tetapi pengaman utamanya ada di ViewModel agar tetap aman walau method terpanggil dua kali. Buku bisa dipinjam lagi setelah dikembalikan.
3. untuk menghindari duplikat kode, dan kalau ada perubahan yang perlu diubah bisa labngsung diubah di 1 file
4. kalau berstatus overdue artinya dai lewati tenggat pengumpulan tapi belum sampai 6 bulan, tapi kalau dia statusnya missing berarti sudah melewati batas 6 bulan
5. bisa diubah di bagian kalkulasi yang viewmodel, mnaka perhitungan lgsg berubah