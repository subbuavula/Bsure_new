import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../Repositary/Models/AssetModels/BankAccountRequest.dart';
import '../Repositary/Retrofit/node_api_client.dart';
import 'GetAssets.dart';

class BankAccountScreen extends StatefulWidget {
  final String assetType;

  const BankAccountScreen({Key? key, required this.assetType})
      : super(key: key);

  @override
  _BankAccountScreenState createState() => _BankAccountScreenState();
}

enum AccountType {
  Saving,
  Current,
  Salary,
}

String accountTypeToString(AccountType type) {
  return type.toString().split('.').last;
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  final TextEditingController _assetTypeController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _ifscCodeController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _attachmentController = TextEditingController();

  AccountType _selectedAccountType = AccountType.Saving;

  File? file;
  String? fileName;
  String? downloadUrl;

  //ImagePicker imagePicker = ImagePicker();
  Color color1 = const Color(0xff429bb8);
  String url = "";
  var name;
  var proof;

  @override
  void initState() {
    super.initState();
    _assetTypeController.text = widget.assetType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff429bb8),
        title:
            const Text('Bank Account', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTextField(
                controller: _bankNameController,
                labelText: 'Bank Name',
                mandatory: true,
              ),
              buildTextField(
                controller: _accountNumberController,
                labelText: 'Account Number (Enter Last 4 digits)',
                mandatory: true,
              ),
              buildTextField(
                controller: _ifscCodeController,
                labelText: 'IFSC Code (Optional)',
                mandatory: false,
              ),
              buildTextField(
                controller: _branchNameController,
                labelText: 'Branch Name',
                mandatory: true,
              ),
              buildAccountTypeDropdown(), // Account Type dropdown field
              buildTextField(
                controller: _commentsController,
                labelText: 'Comments (Optional)',
                mandatory: false,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Flexible(
                      // Wrap TextFormField with Flexible
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.6,
                        margin: const EdgeInsets.only(right: 10, left: 15),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xff429bb8)),
                            ),
                            hintText: "Attach an ID Proof (Optional)",
                            hintStyle: TextStyle(fontSize: 16),
                          ),
                          readOnly: true,
                          controller: _attachmentController,
                          onTap: uploadFile,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    // Add spacing between TextFormField and ElevatedButton
                    Expanded(
                      // Wrap ElevatedButton with Expanded
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.3,
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: uploadFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff429bb8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical:
                                  MediaQuery.of(context).size.width * 0.01,
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.09,
                            ),
                          ),
                          child: const Text(
                            'Pick File',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Handle submit button press
                    _submitForm();
                  },
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String labelText,
    bool mandatory = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              labelText,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (mandatory)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(), // Adding border to text field
            contentPadding:
                EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          ),
        ),
      ],
    );
  }

  Widget buildAccountTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Account Type',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<AccountType>(
          value: _selectedAccountType,
          onChanged: (value) {
            setState(() {
              _selectedAccountType = value!;
            });
          },
          items: AccountType.values.map((type) {
            return DropdownMenuItem<AccountType>(
              value: type,
              child: Text(accountTypeToString(type)),
            );
          }).toList(),
          decoration: const InputDecoration(
            border: OutlineInputBorder(), // Adding border to dropdown field
            contentPadding:
                EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          ),
        ),
      ],
    );
  }

  Future<void> uploadFile() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.any, allowMultiple: false);

    if (result != null) {
      setState(() {
        proof = result.files.single;
        _attachmentController.text = proof.name;
      });

      // Save the file locally
      final fileSaved = await saveFileLocally(proof);
      if (fileSaved != null) {
        setState(() {
          // Update the file variable with the saved file
          file = fileSaved as File?;
        });
      }
    }
  }

  Future<String?> saveFileLocally(FilePickerResult result) async {
    final File file = File(result.files.single.path!); // Get the file
    // Define a directory where the file will be saved
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/${result.files.single.name}';

    // Copy the file to the application directory
    await file.copy(filePath);

    return filePath; // Return the saved file path
  }

  Future<void> _submitForm() async {
    const String token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJ1c2VySWQiOjIsInVzZXJFbWFpbCI6bnVsbCwidXNlck1vYmlsZSI6IjgzM'
        'jg1NjQ2ODMiLCJpYXQiOjE3MTIzMTkyMTUsImV4cCI6MTcxMjkyNDAxNX0.'
        'bh3HdNwm5-SYVIRwkqVl5z3giOUY9kTGSk7pV7aedwc'; // Replace with your actual token

    final dio = Dio();
    final client = NodeClient(dio);

    String? fileUrl;

    // Check if a file is uploaded and saved locally
    if (file != null) {
      // Use the saved file path
      fileUrl = file!.path;
    } else {
      // Get the file URL from the controller
      fileUrl = _attachmentController.value.text.trim();
    }

    // If no file is uploaded, set fileUrl to an empty string or null
    if (fileUrl == null || fileUrl.isEmpty) {
      fileUrl = ''; // or fileUrl = null;
    }

    final req = BankAccountRequest(
      assetType: widget.assetType,
      bankName: _bankNameController.value.text,
      accountNumber: _accountNumberController.value.text,
      ifscCode: _ifscCodeController.value.text,
      branchName: _branchNameController.value.text,
      accountType: _selectedAccountType,
      comments: _commentsController.value.text,
      attachment: fileUrl,
    );

    try {
      final response = await client.CreateBankAccount(token, req);
      print(response); // Handle the response data

      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AssetDetailsList(assetType: widget.assetType),
        ),
      );
    } on DioError catch (e) {
      if (e.response != null) {
        print('Failed to submit data: ${e.response?.statusCode}');
      } else {
        print('Failed to submit data: ${e.message}');
      }
    }
  }
}
