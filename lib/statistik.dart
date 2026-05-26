import 'dart:convert';

import 'package:flutter/material.dart';
import 'widgets/indikator.dart';
import 'package:goten/absen.dart';
import 'package:goten/dashboard.dart';
import 'package:goten/statistik_semua.dart';
import 'package:http/http.dart' as http;
import 'package:deep_pick/deep_pick.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:convert/convert.dart';


class Statistik extends StatefulWidget {
  Statistik({super.key, this.nama});
  String? nama;

  @override
  State<Statistik> createState() => _StatistikState();
}

class _StatistikState extends State<Statistik> {
  final TextStyle whiteText = TextStyle(color: Colors.white);
  int touchedIndex = -1;
  String _jmlterlambat = '0';
  String _jmltepat = '0';
  String _persentasetepat = '0';
  String _persentaseterlambat = '0';

  @override
  void initState() {
    _ambilData();
    // TODO: implement initState
    super.initState();
  }

  _ambilData() async {
    final ambilKaryawan = await http.post(Uri.parse('http://188.166.226.122:8080/statistik/bln_ini'),
    headers: {
          "Content-Type": "application/x-www-form-urlencoded",
    },
    body: {"nama" : widget.nama });
    final dataKar = jsonDecode(ambilKaryawan.body);
    final jmlterlambat = pick(dataKar, 'data',0,'JumlahTerlambat').asDoubleOrNull() ?? 0;
    final jmltepat = pick(dataKar, 'data',0,'JumlahTepatWaktu').asDoubleOrNull() ?? 0;
    final persentaseterlambat = pick(dataKar, 'data',0,'PersentaseTerlambat').asDoubleOrNull() ?? 0;
    final persentasetepat = pick(dataKar, 'data',0,'PersentaseTepatWaktu').asDoubleOrNull() ?? 0;

    setState(() {
      _jmlterlambat = jmlterlambat.toStringAsFixed(2);
      _jmltepat = jmltepat.toStringAsFixed(2);
      _persentasetepat = persentasetepat.toStringAsFixed(2);
      _persentaseterlambat = persentaseterlambat.toStringAsFixed(2);
    });

  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(context),
    );
  }


  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
    child:
    Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHeader(),
          SizedBox(height: 20,),
          AspectRatio(
            aspectRatio: 1,
            child: Card(
              margin: EdgeInsets.fromLTRB(16, 16, 16, 16),
              color: Colors.white,
              child: Container(
                child:
                Column (
                children: <Widget>[
                  const SizedBox(
                    height: 10,
                  ),
                  Center(child:Text("Persentase Kehadiran Bulan ini", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),)),
                  SizedBox(
                    height: 16,
                  ),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(
                            show: false,
                          ),
                          sectionsSpace: 0,
                          centerSpaceRadius: 40,
                          sections: showingSections(),
                        ),
                      ),
                    ),
                  ),
                  
                  Padding(padding: EdgeInsets.only(left: 20, top: 16),
                  child:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const <Widget>[
                      Indicator(
                        color: Colors.green,
                        text: 'Tepat Waktu',
                        isSquare: true,
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Indicator(
                        color: Colors.red,
                        text: 'Terlambat',
                        isSquare: true,
                      ),
                      SizedBox(
                        height: 4,
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:  <Widget>[
                      Indicator(
                        color: Colors.green,
                        text: _persentasetepat + ' %',
                        isSquare: true,
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Indicator(
                        color: Colors.red,
                        text: _persentaseterlambat + ' %',
                        isSquare: true,
                      ),
                      SizedBox(
                        height: 4,
                      ),
                    ],
                  ),
                  ]
                  )),
                  
                  
                  SizedBox(
                    height: 16,
                  ),
                ],
              ),
              )
            ),
          ),
          _persentasetepat == '100.00' ?
          Card(
            elevation: 4.0,
            color: Colors.white,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child:  ListTile(
              title: Text("Anda Selalu Datang Tepat Waktu", style: TextStyle(fontWeight: FontWeight.bold),),
              subtitle: Text("Pertahankan Prestasi Anda"),
              onTap: () {
                Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => StatistikSemua(nama: widget.nama,),),);

                },
              trailing:  Icon(
                  Icons.check_box_rounded,
                  size: 40.0,
                  color: Colors.green,
                ),
            )
          )
          :
          SizedBox(height: 0,),


          Card(
            elevation: 4.0,
            color: Colors.white,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child:  ListTile(
              title: Text("Statistik Keseluruhan", style: TextStyle(fontWeight: FontWeight.bold),),
              subtitle: Text("Ketuk disini untuk melihat Statistik"),
              onTap: () {
                Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => StatistikSemua(nama: widget.nama,),),);

                },
              trailing:  Icon(
                  Icons.auto_graph_outlined,
                  size: 40.0,
                  color: Colors.blue,
                ),
            )
          ),
        ],
      ),
      )
    );
  }

  Container _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 50.0, 0, 32.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.0),
          bottomRight: Radius.circular(20.0),
        ),
        color: Colors.blue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            alignment: Alignment.center,
            child: Text(
              "Statistik",
              style: whiteText.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          ),


        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(2, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      switch (i) {
        case 0:
          return PieChartSectionData(
            color: Colors.green,
            value: double.tryParse(_persentasetepat) ?? 0,
            
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xffffffff),
            ),
          );
        case 1:
          return PieChartSectionData(
            color: Colors.red,
            value: double.tryParse(_persentaseterlambat) ?? 0,
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xffffffff),
            ),
          );
        
        default:
          throw Error();
      }
    });
  }
}

