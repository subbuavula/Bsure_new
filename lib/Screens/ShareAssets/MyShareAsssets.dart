import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Repositary/Models/Share_assets/my_share_asset_res.dart';
import '../Utils/DisplayUtils.dart';

class MyAssetsScreen extends StatefulWidget {
  const MyAssetsScreen({Key? key}) : super(key: key);

  @override
  _MyAssetsScreenState createState() => _MyAssetsScreenState();
}

class _MyAssetsScreenState extends State<MyAssetsScreen> {
  MyShareAssetsResponse? myShareAssetsResponse;
  bool isLoading = true;
  Map<int, List<String>> selectedNomineesMap = {};

  @override
  void initState() {
    super.initState();
    _getSharedAssets();
  }

  Future<void> _getSharedAssets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final dio = Dio();
      dio.options.headers["Authorization"] = token;
      const url = 'http://43.205.12.154:8080/v2/share/by-me';

      final response = await dio.get(
        url,
        options: Options(
          headers: {
            "ngrok-skip-browser-warning": "69420",
          },
        ),
      );

      if (response.statusCode == 200) {
        print("reddy");
        print(response.data);

        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        myShareAssetsResponse = MyShareAssetsResponse.fromJson(data);

        if (myShareAssetsResponse != null &&
            myShareAssetsResponse!.assets != null) {
          for (var asset in myShareAssetsResponse!.assets!) {
            selectedNomineesMap[asset.id] = asset.nominees != null
                ? asset.nominees!
                    .map(
                        (nominee) => '${nominee.firstName} ${nominee.lastName}')
                    .toList()
                : [];
          }
        }

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print('Failed to fetch shared assets: ${response.statusCode}');
        print(response.data);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Failed to fetch shared assets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff429bb8),
        title: const Text(
          'My Shared Assets',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : myShareAssetsResponse != null &&
                  myShareAssetsResponse!.success == true
              ? _buildAssetsList()
              : const Center(
                  child: Text('Failed to fetch shared assets'),
                ),
    );
  }

  Widget _buildAssetsList() {
    return Card(
      color: Colors.lightBlue,
      child: ListView.builder(
        itemCount: myShareAssetsResponse!.assets!.length,
        itemBuilder: (context, index) {
          final asset = myShareAssetsResponse!.assets![index];
          selectedNomineesMap.putIfAbsent(asset.id, () => []);

          return Visibility(
            visible: !_checkAssetDeleted(asset.id),
            child: Card(
              color: Colors.white,
              elevation: 3,
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        asset.category,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._buildDetailsList(asset.details ?? []),
                    const Divider(),
                    for (var nominee in asset.nominees ?? [])
                      CheckboxListTile(
                        title: Text(
                          '${nominee.firstName} ${nominee.lastName}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        value: selectedNomineesMap[asset.id]!.contains(
                            '${nominee.firstName} ${nominee.lastName}'),
                        onChanged: (bool? value) {
                          if (value != null) {
                            if (!value) {
                              _confirmUnshareNominee(asset.id, nominee, nominee.sharedAssetId);
                            } else {
                              setState(() {
                                selectedNomineesMap[asset.id]!.remove(
                                    '${nominee.firstName} ${nominee.lastName}');
                              });
                            }
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmUnshareNominee(int assetId, Nominee nominee, int sharedAssetId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Unshare Nominee?"),
          content: const Text("Are you sure you want to unshare this nominee?"),
          actions: <Widget>[
            TextButton(
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Color(0xff429bb8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                "Confirm",
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _unshareNominee(assetId, nominee, sharedAssetId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _unshareNominee(
      int assetId, Nominee nominee, int sharedAssetId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final dio = Dio();
      dio.options.headers["Authorization"] = token;

      final url = 'http://43.205.12.154:8080/v2/share/$sharedAssetId';
      final response = await dio.delete(
        url,
        options: Options(
          headers: {
            "ngrok-skip-browser-warning": "69420",
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          selectedNomineesMap[assetId]!
              .remove('${nominee.firstName} ${nominee.lastName}');
        });
        DisplayUtils.showToast("Nominee unshared successfully");
      } else {
        print('Failed to unshare nominee: ${response.statusCode}');
        print(response.data);
      }
    } catch (e) {
      print('Failed to unshare nominee: $e');
    }
  }

  bool _checkAssetDeleted(int assetId) {
    return myShareAssetsResponse!.assets!
        .where((asset) => asset.id == assetId)
        .isEmpty;
  }

  List<Widget> _buildDetailsList(List<Detail> details) {
    return details.map((detail) {
      final capitalizedFieldName =
          detail.fieldName.substring(0, 1).toUpperCase() +
              detail.fieldName.substring(1);

      return ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '$capitalizedFieldName:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(
                detail.fieldValue ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
