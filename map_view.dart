import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import 'package:http/http.dart' as http;

class LocationView extends StatefulWidget {
  const LocationView({super.key});

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> with WidgetsBindingObserver {

  TextEditingController _addressController = TextEditingController();
  // TextEditingController _searchController = TextEditingController();
  // TextEditingController _searchController2 = TextEditingController();

  MapController mapController = MapController();

  loc.Location location = loc.Location();
  // bool _serviceEnabled = false;
  // loc.PermissionStatus? _permissionGranted;
  loc.LocationData? _locationData;


  final LatLng _dushanbeCoordinates = LatLng(38.573835, 68.784895);
  double _currentZoom = 16.0;
  // LatLng? _searchedLocation;
  Placemark? _currentAddress;
  LatLng? _currentLocation;

  LatLng? _pointA;
  LatLng? _pointB;
  List<LatLng> routpounts = [LatLng(38.573835, 68.784895)];

  // bool _isSearchOpen = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      initLocation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  void _onTap(TapPosition position, LatLng tappedPoint) {
    setState(()  {

      if (_pointA == null) {
        _pointA = tappedPoint;
      } else if (_pointB == null) {
        _pointB = tappedPoint;

        _getFromWay();

      } else {
        _pointA = tappedPoint;
        _pointB = null;
      }

    });
  }




  Future<void> initLocation() async {
    setState(() {
      _isLoading = true;
    });

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        mapController.move(_dushanbeCoordinates, _currentZoom);
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Доступ к геолокации запрещен"),
            content: Text("Чтобы включить доступ к геолокации, перейдите в настройки приложения."),
            actions: [
              TextButton(
                child: Text("Настройки"),
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
              ),
            ],
          );
        },
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      await Geolocator.openLocationSettings();
      if (!await Geolocator.isLocationServiceEnabled()) {
        mapController.move(_dushanbeCoordinates, _currentZoom);
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (position != null) {
      setState(() {
        _isLoading = false;
        _currentLocation = LatLng(position.latitude, position.longitude);
        mapController.move(_currentLocation!, _currentZoom);
      });
    } else {
      setState(() {
        _isLoading = false;
        mapController.move(_dushanbeCoordinates, _currentZoom);
      });
    }
  }



  // Future<void> _getAddressFromCoordinates(LatLng coordinates) async {
  //   try {
  //     List<Placemark> placemarks = await placemarkFromCoordinates(coordinates.latitude, coordinates.longitude);
  //
  //     if (placemarks.isNotEmpty) {
  //       Placemark place = placemarks.first;
  //
  //       String fullAddress = "${place.locality}, ${place.street}";
  //
  //       setState(() {
  //         _currentAddress = place;
  //         _addressController.text = fullAddress;
  //       });
  //       print("${fullAddress}");
  //     }
  //   } catch (e) {
  //     log('Ошибка получения адреса: $e');
  //   }
  // }

  //
  // Future<void> _searchLocationByAddress(String address) async {
  //   try {
  //     List<Location> locations = await locationFromAddress(address);
  //     if (locations.isNotEmpty) {
  //       Location location = locations.first;
  //       LatLng newLocation = LatLng(location.latitude, location.longitude);
  //
  //       setState(() {
  //         _searchedLocation = newLocation;
  //         mapController.move(newLocation, _currentZoom);
  //       });
  //     }
  //   } catch (e) {
  //   }
  // }


  // Future<void> _searchLocationByAddress(String address) async {
  //   final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$address&format=json&limit=1');
  //
  //   try {
  //     final response = await http.get(url);
  //
  //     if (response.statusCode == 200) {
  //       List data = json.decode(response.body);
  //
  //       if (data.isNotEmpty) {
  //         var locationData = data[0];
  //         LatLng newLocation = LatLng(
  //           double.parse(locationData['lat']),
  //           double.parse(locationData['lon']),
  //         );
  //
  //         setState(() {
  //           _searchedLocation = newLocation;
  //           mapController.move(newLocation, _currentZoom);
  //           _addressController.text = "${locationData['display_name']}";
  //         });
  //
  //         print("Найдено местоположение: ${locationData['display_name']}");
  //       } else {
  //         print("Адрес не найден");
  //       }
  //     } else {
  //       print("Ошибка при подключении к Nominatim API: ${response.statusCode}");
  //     }
  //   } catch (e) {
  //     print('Ошибка поиска по адресу: $e');
  //   }
  // }

  Future<void> _getFromWay() async {

    setState(() {
      _isLoading = true;
    });

    try {
      if (_pointA == null || _pointB == null) {
        // print("Точки A или B не установлены");
        return;
      }

      var url = Uri.parse(
          'http://router.project-osrm.org/route/v1/driving/${_pointA!.longitude},${_pointA!.latitude};${_pointB!.longitude},${_pointB!.latitude}?steps=true&annotations=true&geometries=geojson&overview=full');

      var response = await http.get(url);
      var ruter = jsonDecode(response.body)['routes'][0]['geometry']['coordinates'];

      setState(() {
        routpounts = ruter.map<LatLng>((coord) {
          var lat = coord[1];
          var lon = coord[0];
          return LatLng(lat, lon);
        }).toList();

        print("Маршрут: $routpounts");
      });
    } catch (e) {
      print("Ошибка: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
         FlutterMap(
            mapController: this.mapController,
            options: MapOptions(
              onTap: _onTap,
              initialZoom: 5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              PolylineLayer(
                  polylines: [
                      Polyline(points: routpounts, color: Colors.blue, strokeWidth: 5)
                  ]
              ),
              MarkerLayer(
                markers: [
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 60,
                      height: 60,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.location_history_outlined,
                            color: Colors.red,
                            size: 30,
                          ),
                          // const Text('Вы', style: TextStyle(color: Colors.blue, fontSize: 16)),
                        ],
                      ),
                    ),
                  if (_pointA != null)
                    Marker(
                      point: _pointA!,
                      width: 60,
                      height: 60,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.location_pin,
                            color: Colors.green,
                            size: 35,
                          ),
                          // const Text('A', style: TextStyle(color: Colors.green, fontSize: 16)),
                        ],
                      ),
                    ),
                  if (_pointB != null)
                    Marker(
                      point: _pointB!,
                      width: 60,
                      height: 60,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.location_pin,
                            color: Colors.orange,
                            size: 35,
                          ),
                          // const Text('B', style: TextStyle(color: Colors.orange, fontSize: 16)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5), // Полупрозрачный черный фон
              child: Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: Colors.red,
                ),
              ),
            ),



          // Positioned(
          //   top: 60,
          //   right: 15,
          //   child: AnimatedContainer(
          //     duration: Duration(milliseconds: 300),
          //     curve: Curves.easeInOut,
          //     width: _isSearchOpen ? MediaQuery.of(context).size.width - 30 : 48,
          //     height: 45,
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       borderRadius: BorderRadius.circular(15),
          //     ),
          //     child : Row(
          //       children: [
          //         if (_isSearchOpen)
          //
          //           Expanded(
          //             child: TextField(
          //               controller: _searchController,
          //               cursorColor: Colors.black54,
          //               style: const TextStyle(
          //                 color: Colors.black,
          //                 fontSize: 15,
          //               ),
          //               decoration: InputDecoration(
          //                 prefixIcon: Padding(
          //                   padding: const EdgeInsets.all(0),
          //                   child: InkWell(
          //                     onTap: () {
          //                       setState(() {
          //                         _searchController.clear();
          //                         _isSearchOpen = false;
          //                       });
          //                     },
          //                     child: const Icon(
          //                       Icons.close,
          //                       size: 25,
          //                       color: Colors.black,
          //                     ),
          //                   ),
          //                 ),
          //                 border: InputBorder.none,
          //                 enabledBorder: InputBorder.none,
          //                 focusedBorder: InputBorder.none,
          //                 hintText: "Откуда",
          //                 hintStyle: const TextStyle(
          //                   color: Colors.grey,
          //                   fontSize: 15,
          //                   fontWeight: FontWeight.w600,
          //                 ),
          //                 suffixIcon: InkWell(
          //                     onTap: () {
          //                       FocusScope.of(context).unfocus();
          //                       _searchLocationByAddress(_searchController.text);
          //                     },
          //                     child: Padding(
          //                       padding: const EdgeInsets.all(11),
          //                       child:  Icon(Icons.search,
          //                       size: 25,)
          //                     )
          //                 ),
          //               ),
          //             ),
          //           ),
          //         if (!_isSearchOpen)
          //           IconButton(
          //             icon:  Icon(Icons.search,
          //               size: 25,),
          //             onPressed: () {
          //               setState(() {
          //                 _isSearchOpen = true;
          //               });
          //             },
          //           ),
          //       ],
          //     ),
          //   ),
          // ),

          // Positioned(
          //   top: 125,
          //   left: 15,
          //   child: AnimatedContainer(
          //     duration: Duration(milliseconds: 300),
          //     curve: Curves.easeInOut,
          //     width: _isSearchOpen ? MediaQuery.of(context).size.width - 30 : 48,
          //     height: 45,
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       borderRadius: BorderRadius.circular(15),
          //     ),
          //     child : Row(
          //       children: [
          //         if (_isSearchOpen)
          //
          //           Expanded(
          //             child: TextField(
          //               controller: _searchController2,
          //               cursorColor: Colors.black54,
          //               style: const TextStyle(
          //                 color: Colors.black,
          //                 fontSize: 15,
          //               ),
          //               decoration: InputDecoration(
          //                 prefixIcon: Padding(
          //                   padding: const EdgeInsets.all(0),
          //                   child: InkWell(
          //                     onTap: () {
          //                       FocusScope.of(context).unfocus();
          //                       _searchLocationByAddress(_searchController2.text);
          //                       // setState(() {
          //                       //   _searchController.clear();
          //                       //   _isSearchOpen = false;
          //                       // });
          //                     },
          //                     child: const Icon(
          //                       Icons.search,
          //                       size: 25,
          //                       color: Colors.black,
          //                     ),
          //                   ),
          //                 ),
          //                 border: InputBorder.none,
          //                 enabledBorder: InputBorder.none,
          //                 focusedBorder: InputBorder.none,
          //                 hintText: "Куда",
          //                 hintStyle: const TextStyle(
          //                   color: Colors.grey,
          //                   fontSize: 15,
          //                   fontWeight: FontWeight.w600,
          //                 ),
          //                 suffixIcon: InkWell(
          //                     onTap: () {
          //                       setState(() {
          //                         _searchController2.clear();
          //                         _isSearchOpen = false;
          //                       });
          //                     },
          //                     child: Padding(
          //                         padding: const EdgeInsets.all(11),
          //                         child:  Icon(Icons.close,
          //                           size: 25,)
          //                     )
          //                 ),
          //               ),
          //             ),
          //           ),
          //         if (!_isSearchOpen)
          //           IconButton(
          //             icon:  Icon(Icons.search,
          //               size: 25,),
          //             onPressed: () {
          //               setState(() {
          //                 _isSearchOpen = true;
          //               });
          //             },
          //           ),
          //       ],
          //     ),
          //   ),
          // ),
          //
          //
          // Positioned(
          //   top : 180,
          //   right: 15,
          //   child: ElevatedButton(
          //     style: ElevatedButton.styleFrom(
          //       foregroundColor: Colors.blue,
          //         backgroundColor: Colors.white,
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(15),
          //       )
          //     ),
          //     onPressed: () async {
          //
          //       List<Location> start_l = await locationFromAddress(start.text);
          //       List<Location> end_l = await locationFromAddress(end.text);
          //
          //
          //     },
          //     child: Text('Поиск'),
          //   )
          // )
          //



          Positioned(
            bottom: 220,
              right: 10,
              child: FloatingActionButton(
                heroTag: 'my_location',
                  backgroundColor: Colors.white,
                  onPressed: (){
                  print(_currentLocation!);
                  // _currentLocation!;
                    setState(() {
                      mapController.move(
                        _currentLocation!, _currentZoom
                      );
                    });
                  },
                child: const  Icon(Icons.my_location),
              )
          ),
          Positioned(
            bottom: 50,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    setState(() {
                      if (_currentZoom < 21.0) _currentZoom++;
                      mapController.move(
                          mapController.camera.center, _currentZoom
                      );
                    });
                  },
                  child: Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    setState(() {
                      if (_currentZoom > 2.0) _currentZoom--;
                      mapController.move(
                          mapController.camera.center, _currentZoom
                      );

                    });
                  },
                  child: Icon(Icons.remove),
                ),
              ],
            ),
          ),


        ],
      ),
    );
  }
}
