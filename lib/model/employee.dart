import 'dart:convert';

Employee employeeFromJson(String str) => Employee.fromJson(json.decode(str));

String employeeToJson(Employee data) => json.encode(data.toJson());

class Employee {
  Employee({
    required this.karNama,
  });

  String karNama;

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        karNama: json["kar_nama"],
      );

  Map<String, dynamic> toJson() => {
        "kar_nama": karNama,
      };

  @override
  String toString() => karNama;
}
