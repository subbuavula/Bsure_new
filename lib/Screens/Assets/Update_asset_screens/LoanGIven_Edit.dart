import 'dart:convert';
import 'package:Bsure_devapp/Screens/Assets/get_asset_screens/real_estate_screen.dart';
import 'package:Bsure_devapp/Screens/Repositary/Models/get_asset_models/loan_given.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Repositary/Models/get_asset_models/real_estate.dart';
import '../get_asset_screens/bank_account_screen.dart';
import '../get_asset_screens/loan_given_screen.dart';

class LoanGivenEdit extends StatefulWidget {
  final LoanGiven loan;
  final String assetType;

  const LoanGivenEdit(
      {Key? key, required this.loan, required this.assetType})
      : super(key: key);

  @override
  State<LoanGivenEdit> createState() => _LoanGivenEditState();
}

class _LoanGivenEditState extends State<LoanGivenEdit> {
  late String borrowerName;
  late String loanAmount;
  late String loanGivenDate;
  late String interestRate;
  late String comments;
  late String attachment;

  @override
  void initState() {
    super.initState();
    // Initialize the local variables with the current values
    borrowerName = widget.loan.borrowerName ?? '';
    loanAmount = widget.loan.loanAmount?.toString() ?? '';
    loanGivenDate = widget.loan.loanGivenDate ?? '';
    interestRate = widget.loan.interestRate?.toString() ?? '';
    comments = widget.loan.comments ?? '';
    attachment = widget.loan.attachment ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff429bb8),
        title: const Text('Edit Real Estate',
            style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: borrowerName,
                decoration: const InputDecoration(labelText: 'Borrower Name'),
                onChanged: (value) {
                  setState(() {
                    borrowerName = value;
                  });
                },
              ),
              TextFormField(
                initialValue: loanAmount,
                decoration: const InputDecoration(labelText: 'Loan Amount'),
                onChanged: (value) {
                  setState(() {
                    loanAmount = value;
                  });
                },
              ),
              TextFormField(
                initialValue: loanGivenDate,
                decoration: const InputDecoration(labelText: 'Loan Given Date'),
                onChanged: (value) {
                  setState(() {
                    loanGivenDate = value;
                  });
                },
              ),
              TextFormField(
                initialValue: interestRate,
                decoration:
                const InputDecoration(labelText: 'Interest Rate'),
                onChanged: (value) {
                  setState(() {
                    interestRate = value;
                  });
                },
              ),
              TextFormField(
                initialValue: comments,
                decoration: const InputDecoration(labelText: 'Comments'),
                onChanged: (value) {
                  setState(() {
                    comments = value;
                  });
                },
              ),
              TextFormField(
                initialValue: attachment,
                decoration: const InputDecoration(labelText: 'Attachment'),
                onChanged: (value) {
                  setState(() {
                    attachment = value;
                  });
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  // Update the RealEstate object with the new values
                  final updatedloan = LoanGiven(
                    borrowerName: borrowerName,
                    loanAmount: int.parse(loanAmount),
                    loanGivenDate: loanGivenDate,
                    interestRate: int.parse(interestRate),
                    comments: comments,
                    attachment: attachment,
                    assetId: widget.loan.assetId,
                    category: widget.assetType,
                  );

                  // Call API to update real estate details
                  final response = await updateLoan(updatedloan);
                  print(response);

                  Navigator.pop(context);
                  Navigator.pushReplacement<void, void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => LoanGivenScreen(
                        assetType: widget.assetType,
                      ),
                    ),
                  );
                },
                child: const Text('Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<LoanGiven?> updateLoan(LoanGiven loanGiven) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      // Handle token absence or expiration here
      return null;
    }

    final dio = Dio();
    dio.options.headers["Authorization"] = token; // Add token to headers

    try {
      final response = await dio.put(
        'http://43.205.12.154:8080/v2/asset/${loanGiven.assetId}',
        data: loanGiven
            .toJson(), // Convert real estate object to JSON and send as request body
      );

      if (response.statusCode == 200) {
        // Parse and return updated real estate details
        return LoanGiven.fromJson(jsonDecode(response.data));
      } else {
        return null; // Return null if update fails
      }
    } catch (e) {
      print(e);
      return null; // Return null if an error occurs
    }
  }
}
