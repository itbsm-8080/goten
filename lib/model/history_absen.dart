// To parse this JSON data, do
//
//     final historyAbsensi = historyAbsensiFromJson(jsonString);

import 'dart:convert';

HistoryAbsensi historyAbsensiFromJson(String str) => HistoryAbsensi.fromJson(json.decode(str));

String historyAbsensiToJson(HistoryAbsensi data) => json.encode(data.toJson());

class HistoryAbsensi {
    HistoryAbsensi({
        required this.nama,
        required this.tanggal,
        required this.historyAbsensiIn,
        required this.out,
        required this.status,
    });

    String nama;
    String tanggal;
    dynamic historyAbsensiIn;
    dynamic out;
    String status;

    factory HistoryAbsensi.fromJson(Map<String, dynamic> json) => HistoryAbsensi(
        nama: json["Nama"],
        tanggal: json["Tanggal"],
        historyAbsensiIn: json["_IN"] == null ? '' : json["_IN"],
        out: json["_OUT"] == null ? '' : json["_OUT"],
        status: json["Status"],
    );

    Map<String, dynamic> toJson() => {
        "Nama": nama,
        "Tanggal": tanggal,
        "_IN": historyAbsensiIn,
        "_OUT": out.toString(),
        "Status": status,
    };
}
