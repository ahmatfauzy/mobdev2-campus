class BiodataModel {
  final String nama;
  final String tempatLahir;
  final String tanggalLahir;
  final String fotoPath;
  final List<Pengalaman> pengalaman;
  final List<Pendidikan> pendidikan;

  BiodataModel({
    required this.nama,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.fotoPath,
    required this.pengalaman,
    required this.pendidikan,
  });

  String get ttl => '$tempatLahir, $tanggalLahir';
}

class Pengalaman {
  final String tahun;
  final String posisi;
  final String perusahaan;

  Pengalaman({
    required this.tahun,
    required this.posisi,
    required this.perusahaan,
  });
}

class Pendidikan {
  final String periode;
  final String institusi;

  Pendidikan({
    required this.periode,
    required this.institusi,
  });
}

// Data Biodata Ahmat Fauzi
final biodataAhmatFauzi = BiodataModel(
  nama: 'Ahmat Fauzi',
  tempatLahir: 'Cirebon',
  tanggalLahir: '23 Oktober 2005', // Saya koreksi 2025 -> 2005 (lebih masuk akal)
  fotoPath: 'assets/images/profile.png',
  pengalaman: [
    Pengalaman(
      tahun: '2026',
      posisi: 'Fullstack Developer',
      perusahaan: 'Raxza Global Tech',
    ),
    Pengalaman(
      tahun: '2025',
      posisi: 'Fullstack Developer',
      perusahaan: 'Jejak Rempah',
    ),
  ],
  pendidikan: [
    Pendidikan(
      periode: '2023 - Sekarang',
      institusi: 'Universitas Harkat Negeri',
    ),
    Pendidikan(
      periode: '2020 - 2023',
      institusi: 'SMAN 1 Losari Cirebon',
    ),
  ],
);