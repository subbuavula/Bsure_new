import 'dart:convert';
import 'package:Bsure_devapp/Screens/Assets/Update_asset_screens/LoanGIven_Edit.dart';
import 'package:Bsure_devapp/Screens/Assets/post_asset_addition/LoanGiven.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../Repositary/Models/get_asset_models/loan_given.dart';
import '../../Utils/DisplayUtils.dart';

class LoanGivenScreen extends StatefulWidget {
  final String assetType;
  const LoanGivenScreen({super.key, required this.assetType});

  @override
  _LoanGivenScreenState createState() => _LoanGivenScreenState();
}

class _LoanGivenScreenState extends State<LoanGivenScreen> {
  List<LoanGiven> loanGivens = [];
  bool isLoading = false;

  final String category = 'LoanGiven';

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    var token = prefs.get("token");

    final url = Uri.parse('http://43.205.12.154:8080/v2/asset/category/LoanGiven');
    final response =
        await http.get(url, headers: {"Authorization": token.toString(),"ngrok-skip-browser-warning": "69420",});

    if (response.statusCode == 200) {
      final data = LoanGivenResponse.fromJson(jsonDecode(response.body));
      if (data.success) {
        setState(() {
          loanGivens = data.assets;
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data.message),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch loan details'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff429bb8),
        title: const Text('Loan Given', style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : loanGivens.isNotEmpty
              ? ListView.builder(
                  itemCount: loanGivens.length,
                  itemBuilder: (context, index) {
                    final loangiven = loanGivens[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    final updatedloangiven =
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LoanGivenEdit(
                                          loan: loangiven,
                                          assetType: category,
                                        ),
                                      ),
                                    );
                                    if (updatedloangiven != null) {
                                      setState(() {
                                        loanGivens[index] = updatedloangiven;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            Text('borrowerName: ${loangiven.borrowerName}',),
                            const SizedBox(height: 8.0),
                            Text('loanAmount: ${loangiven.loanAmount}'),
                            const SizedBox(height: 8.0),
                            Text('loanGivenDate: ${loangiven.loanGivenDate}'),
                            const SizedBox(height: 8.0),
                            Text('interestRate: ${loangiven.interestRate?.toStringAsFixed(2) ?? 'N/A'}'), // Display two decimal places
                            const SizedBox(height: 8.0),
                            Text('comments: ${loangiven.comments}'),
                            const SizedBox(height: 8.0),
                            Text('attachment: ${loangiven.attachment}'),
                            const SizedBox(height: 8.0),
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder:
                                      (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text(
                                          "Delete Asset?"),
                                      content: const Text(
                                          "Are you sure you want to delete this Asset?"),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text(
                                            "Cancel",
                                            style: TextStyle(
                                              color: Color(
                                                  0xff429bb8),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop();
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
                                            Navigator.of(context)
                                                .pop();
                                            deleteAssetStatus(
                                                index, context);
                                            setState(() {
                                              loanGivens!
                                                  .removeAt(
                                                  index);
                                            });
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(50),
                                ),
                                backgroundColor:
                                const Color(0xff429bb8),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete,
                                      color: Colors.white),
                                  SizedBox(width: 5),
                                  Text("Delete",
                                      style: TextStyle(
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : const Center(
                  child: Text(
                    'No data found',
                    style: TextStyle(
                      fontSize: 20.0,
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>  LoanGivenAdd(
                assetType: category,
              ),
            ),
          );
        },
        label: const Text(
          'Add New',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        icon: const Icon(
          Icons.add,
          size: 24,
          color: Colors.white,
        ),
        backgroundColor: const Color(0xff429bb8),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Future<void> deleteAssetStatus(int index, BuildContext context) async {
    final mutualFund = loanGivens[index];
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      // Handle token absence or expiration here
      return;
    }

    final dio = Dio();
    dio.options.headers["Authorization"] = token;

    try {
      final response = await dio.delete(
        'http://43.205.12.154:8080/v2/asset/${mutualFund.assetId}',
      );

      if (response.statusCode == 200) {
        // Remove the deleted bank account from the list
        setState(() {
          loanGivens.removeAt(index);
          getData();
        });

        // Call getData() outside setState() to ensure immediate UI update

        DisplayUtils.showToast(" loan given successfully deleted.");
      } else {
        DisplayUtils.showToast("Failed to delete loan given. ${response.data}");
      }
    } catch (e) {
      DisplayUtils.showToast("API failure");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to delete bank account. Please check your internet connection.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
