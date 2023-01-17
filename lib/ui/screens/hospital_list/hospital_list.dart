import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loono/repositories/user_repository.dart';
import 'package:loono/services/database_service.dart';
import 'package:loono/utils/registry.dart';

Future<List<Hospital>> getHospitalsHTTP() async {
  final response = await http.get(Uri.parse(
      'https://626113ece7361dff91fed0d7.mockapi.io/api/v1/hospitals'));

  List<Hospital> hospitalList = [];

  dynamic responseDecoded = jsonDecode(utf8.decode(response.bodyBytes));

  if (response.statusCode == 200) {
    for (dynamic item in responseDecoded) {
      hospitalList.add(Hospital(
          Id: item["id"].toString(),
          name: item["name"].toString(),
          addres: item['address'].toString(),
          web: item['web'].toString(),
          checked: false));
    }
    return hospitalList;
  } else {
    throw Exception('Failed to load hospitals');
  }
}

class Hospital {
  final String Id;
  final String name;
  final String addres;
  final String web;
  final bool checked;

  const Hospital({
    required this.Id,
    required this.name,
    required this.addres,
    required this.web,
    required this.checked,
  });
}

class HospitalListScreen extends StatefulWidget {
  const HospitalListScreen({Key? key}) : super(key: key);

  @override
  _HospitalListScreenState createState() => _HospitalListScreenState();
}

class _HospitalListScreenState extends State<HospitalListScreen> {
  static late List<Hospital> hospitalList = [];
  static late List<Hospital> favoriteHospitalList = [];
  final _userRepository = registry.get<UserRepository>();

  final _usersDao = registry.get<DatabaseService>().users;

  void getHospitals() async {
    hospitalList = await getHospitalsHTTP();
    setState(() {});
    getFavorites();
  }

  void getFavorites() async {
    //Get list favorite hospitals
    var favoriteList = _usersDao.user?.favoriteHospital;
    favoriteHospitalList.clear();

    //for (Hospital item in hospitalList) {

    for (var i = 0; i < hospitalList.length; i++) {
      if (favoriteList?.contains(hospitalList[i].Id) == true) {
        favoriteHospitalList.add(Hospital(
            Id: hospitalList[i].Id as String,
            name: hospitalList[i].name as String,
            addres: hospitalList[i].addres as String,
            web: hospitalList[i].web as String,
            checked: true));

        hospitalList[i] = Hospital(
            Id: hospitalList[i].Id as String,
            name: hospitalList[i].name as String,
            addres: hospitalList[i].addres as String,
            web: hospitalList[i].web as String,
            checked: true);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getHospitals();
  }

  void addHospitalFavorite(String favoriteID) async {
    await _userRepository.addFavoriteHospital(favoriteID.toString());
    setState(() {
      getFavorites();
    });
  }

  void removeHospitalFavorite(String favoriteID) async {
    await _userRepository.removeFavoriteHospital(favoriteID.toString());
    setState(() {
      getFavorites();
    });
  }

  void changeFavorite(int index) {
    if (!hospitalList[index].checked) {
      addHospitalFavorite(hospitalList[index].Id);
    } else {
      removeHospitalFavorite(hospitalList[index].Id);
    }
    setState(() {
      hospitalList[index] = Hospital(
          Id: hospitalList[index].Id,
          name: hospitalList[index].name,
          addres: hospitalList[index].addres,
          web: hospitalList[index].web,
          checked: !hospitalList[index].checked);
    });
  }

  void changeFavoriteinFavorites(int index) {
    if (!favoriteHospitalList[index].checked) {
      addHospitalFavorite(favoriteHospitalList[index].Id);
    } else {
      removeHospitalFavorite(favoriteHospitalList[index].Id);
    }

    // TODO : optimize the following code - not efective
    for (var i = 0; i < hospitalList.length; i++) {
      if (favoriteHospitalList[index].Id == hospitalList[i].Id) {
        hospitalList[i] = Hospital(
            Id: hospitalList[i].Id as String,
            name: hospitalList[i].name as String,
            addres: hospitalList[i].addres as String,
            web: hospitalList[i].web as String,
            checked: false);
      }
    }
    setState(() {
      favoriteHospitalList[index] = Hospital(
          Id: favoriteHospitalList[index].Id,
          name: favoriteHospitalList[index].name,
          addres: favoriteHospitalList[index].addres,
          web: favoriteHospitalList[index].web,
          checked: !favoriteHospitalList[index].checked);
    });
  }

  PageController _hospitalPageController = PageController(initialPage: 0);

  int page = 0;
  void pageChange(dynamic currentPage) {
    setState(() {
      page = currentPage as int;
    });
  }

  Widget hospitalCard(Hospital item, int index, bool isFavoriteList) {
    return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          children: [
            Expanded(
                flex: 75,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Container(height: 5),
                      Row(children: [
                        //Container(width:5),
                        Center(child: Text(item.web))
                      ]),
                      Container(height: 5),
                      Text(item.name,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              fontSize: 20.0, color: Color(0xff538e91))),
                      Container(height: 5),
                      Text(item.addres),
                    ],
                  ),
                )),
            Expanded(
                flex: 25,
                child: InkWell(
                  onTap: () async {
                    if (isFavoriteList) {
                      changeFavoriteinFavorites(index);
                    } else {
                      changeFavorite(index);
                    }
                  },
                  child: Column(
                    children: [
                      Icon(item.checked ? Icons.star : Icons.star_border,
                          size: 30.0) //star_border
                    ],
                  ),
                )),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFfac8a7),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 45, left: 25, right: 25),
          child: Column(
            children: [
              Row(
                children: const [
                  Text('SEZNAM NEMOCNIC'),
                ],
              ),
              Container(height: 15),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      _hospitalPageController.animateToPage(0,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.ease);
                    },
                    child: Container(
                      padding: const EdgeInsets.only(
                        bottom: 5, // Space between underline and text
                      ),
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                        color:
                            page == 0 ? Color(0xFFca6e31) : Color(0xFFfac8a7),
                        width: 3.0, // Underline thickness
                      ))),
                      child: const Text(
                        "všechny",
                        style: TextStyle(
                          color: Color(0xFFca6e31),
                        ),
                      ),
                    ),
                  ),
                  Container(width: 15),
                  InkWell(
                    onTap: () {
                      _hospitalPageController.animateToPage(1,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.ease);
                    },
                    child: Container(
                      padding: const EdgeInsets.only(
                        bottom: 5, // Space between underline and text
                      ),
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                        color:
                            page == 1 ? Color(0xFFca6e31) : Color(0xFFfac8a7),
                        width: 3.0, // Underline thickness
                      ))),
                      child: const Text(
                        "oblíbené",
                        style: TextStyle(
                          color: Color(0xFFca6e31),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: PageView(
                    scrollDirection: Axis.horizontal,
                    onPageChanged: pageChange,
                    controller: _hospitalPageController,
                    pageSnapping: true,
                    children: [
                      //Hospital screen
                      ListView.builder(
                          shrinkWrap: true,
                          itemCount: hospitalList.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Container(
                                child: hospitalCard(
                                    hospitalList[index], index, false));
                          }),

                      //Favvorite hospital screen
                      ListView.builder(
                          shrinkWrap: true,
                          itemCount: favoriteHospitalList.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Container(
                                child: hospitalCard(
                                    favoriteHospitalList[index], index, true));
                          }),
                    ]),
              )
            ],
          ),
        ),
      ),
    );
  }
}
