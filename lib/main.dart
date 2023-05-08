import 'dart:async';
import 'package:address_search_field/address_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;





Future<void> getLocationInfo(Address address) async {

  List<geo.Placemark> placemark =await geo.placemarkFromCoordinates(address.coords!.latitude, address.coords!.longitude);

 // http.Response response=  await http.get(Uri.parse('https://maps.googleapis.com/maps/api/place/autocomplete/json?input=pune&components=postal_code:411041&types=geocode&key=AIzaSyCIRZktY0VH26eMyGAP2lFxuAlkgtKymSk'));
 http.Response response=  await http.get(Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?components=postal_code:415605&key=AIzaSyCIRZktY0VH26eMyGAP2lFxuAlkgtKymSk'));


 print(response.body);




  print(placemark.length);
  placemark.forEach((element) {
    print(placemark.first.locality);
    print(placemark.first.subLocality);
    print(placemark.first.name);
    print(placemark.first.administrativeArea);
    print(placemark.first.subAdministrativeArea);
    print(placemark.first.street);
  });


}

Future<LatLng> _getPosition() async {
  final Location location = Location();
  if (!await location.serviceEnabled()) {
    if (!await location.requestService()) throw 'GPS service is disabled';
  }
  if (await location.hasPermission() == PermissionStatus.denied) {
    if (await location.requestPermission() != PermissionStatus.granted) {
      throw 'No GPS permissions';
    }
  }
   LocationData data = await location.getLocation();
  return LatLng(data.latitude!, data.longitude!);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: const Text('Plugin example app'),
            ),
            body: FutureBuilder(
              future: _getPosition(),
              builder: (BuildContext context, AsyncSnapshot<LatLng> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else {
                  if (snapshot.hasData) {
                    return Example(snapshot.data!);
                  } else {
                    return const Center(
                      child: Text('Location not found!'),
                    );
                  }
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

final routeProvider =
    ChangeNotifierProvider<RouteNotifier>((ref) => RouteNotifier());

class Example extends StatefulWidget {
  const Example(this.initialPositon, {Key? key}) : super(key: key);
  final LatLng initialPositon;

  @override
  State<Example> createState() => _ExampleState();

}

class _ExampleState extends State<Example> {
  final geoMethods = GeoMethods(
    /// [Get API key](https://developers.google.com/maps/documentation/embed/get-api-key)
    googleApiKey: 'AIzaSyCIRZktY0VH26eMyGAP2lFxuAlkgtKymSk',
    language: 'es-419',
  );


  final polylines = <Polyline>{};

  final markers = <Marker>{};

  final origCtrl = TextEditingController();

  final destCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return RouteSearchBox(
      provider: routeProvider,
      geoMethods: geoMethods,
      originController: origCtrl,
      destinationController: destCtrl,
      locationSetters: [
        LocationSetter(
          coords: widget.initialPositon.toCoords(),
          addressId: AddressId.origin,
        ),
      ],
      child: Column(
        children: [
          // Expanded(
          //   child: GoogleMap(
          //     compassEnabled: true,
          //     myLocationEnabled: false,
          //     myLocationButtonEnabled: false,
          //     rotateGesturesEnabled: true,
          //     zoomControlsEnabled: true,
          //     initialCameraPosition: CameraPosition(
          //       target: widget.initialPositon,
          //       zoom: 14.5,
          //     ),
          //     onMapCreated: (GoogleMapController ctrl) {
          //       controller = ctrl;
          //     },
          //     polylines: polylines,
          //     markers: markers,
          //   ),
          // ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            color: Colors.white,
            // height: 150.0,
            child: Center(
              child: ElevatedButton(
                child: Text("Search"),
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) {
                    return AddressSearchDialog.withProvider(
                      provider: routeProvider,
                      addressId: AddressId.origin,
                      onDone: (Address address){
                        print("This is address :" + geoMethods.city ?? '');
                        getLocationInfo(address);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class Waypoints extends ConsumerStatefulWidget {
  const Waypoints(
    this.geoMethods, {
    Key? key,
  }) : super(key: key);

  final GeoMethods geoMethods;

  @override
  ConsumerState<Waypoints> createState() => _WaypointsState();
}

class _WaypointsState extends ConsumerState<Waypoints> {
  bool addNewWP = false;

  @override
  Widget build(BuildContext context) {
    final waypoints = ref.watch(routeProvider).waypoints;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            onPressed: () => !addNewWP ? setState(() => addNewWP = true) : null,
          )
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return AddressLocator(
          coords: const Coords(0.96126, -79.6581883),
          geoMethods: widget.geoMethods,
          onDone: (address) =>
              waypoints.isEmpty ? _onDone(address, waypoints, 0) : null,
          child: ListView.separated(
            itemCount: waypoints.length + (addNewWP ? 1 : 0),
            separatorBuilder: (BuildContext context, int index) {
              return Divider(
                color: Colors.blue[50],
              );
            },
            itemBuilder: (BuildContext context, int index) {
              final TextEditingController controller =
                  TextEditingController(text: waypoints.getReference(index));
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                color: Colors.blue[50],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: constraints.constrainWidth() - 30 - 25,
                      child: TextField(
                        controller: controller,
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => AddressSearchDialog(
                            controller: controller,
                            geoMethods: widget.geoMethods,
                            onDone: (address) =>
                                _onDone(address, waypoints, index),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (index != 0) {
                              ref
                                  .read(routeProvider)
                                  .reorderWaypoint(index, index - 1);
                            }
                          },
                          child: const Icon(Icons.keyboard_arrow_up),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (index + 1 != waypoints.length) {
                              ref
                                  .read(routeProvider)
                                  .reorderWaypoint(index, index + 1);
                            }
                          },
                          child: const Icon(Icons.keyboard_arrow_down),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }

  void _onDone(Address address, List<Address> waypoints, int index) {

    String city=ref
        .read(routeProvider).geoMethods.city;


    if (waypoints.asMap().containsKey(index)) {
      ref.read(routeProvider).updateWaypoint(index, address);
    } else {
      ref.read(routeProvider).addWaypoint(address);
    }
    setState(() => addNewWP = false);
  }
}
