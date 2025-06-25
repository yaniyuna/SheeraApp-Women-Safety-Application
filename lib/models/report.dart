class Report{
  //deklarasi variabel untuk menerima inputan
  //tidak sama dg field pada tabel
  int? id;
  String? kategori;
  String? lokasi;
  String? keterangan;
  String? tanggal;
  //deklarasi parameter untuk menerima inputan pada class
  Report( this.id,  this.kategori, this.lokasi,  this.keterangan,  this.tanggal);
  //memasukkan atribut pada map yang nantinya akan ditampilkan
  //memasukkan atribut pada map yang nantinya akan ditampilkan
  Report.fromMap(Map<String, dynamic> map){
    this.id=map['id'];
    //terdapat toString(), jika terdapat nilai angka tetap ditampilkan sebagai string
    this.kategori=map['kategori'].toString();
    this.lokasi=map['lokasi'].toString();
    this.keterangan=map['keterangan'].toString();
    this.tanggal=map['tanggal'].toString();
  }
  // int? get id =>_id;
  //return map digunakan pada database, nama variabel disamakan dg field
 Map<String, dynamic> toMap() {
    return {
      'id': this.id, //  Ensure 'id' exists
      'kategori': this.kategori,
      'lokasi': this.lokasi,
      'keterangan': this.keterangan,
      'tanggal': this.tanggal,
    };
  }
}