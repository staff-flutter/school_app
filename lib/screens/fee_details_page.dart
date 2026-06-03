import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../controllers/my_children_controller.dart';
import '../constants/api_constants.dart';
import '../services/user_session.dart';


// --------------------------------------------- MODEL CLASS MATCHING JSON -----------------------------------


class FeeStructureModel {
  final String id;
  final String type; // "new" or "old"
  final int totalAmount;
  final Map<String, dynamic> feeHead;

  FeeStructureModel({
    required this.id,
    required this.type,
    required this.totalAmount,
    required this.feeHead,
  });

  factory FeeStructureModel.fromJson(Map<String, dynamic> json) {
    return FeeStructureModel(
      id: json['_id'] ?? '',
      type: json['type'] ?? 'Unknown',
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      feeHead: json['feeHead'] ?? {},
    );
  }
}



class FeeDetailsFirstPage extends StatefulWidget {
  const FeeDetailsFirstPage({super.key});

  @override
  State<FeeDetailsFirstPage> createState() => _FeeDetailsFirstPageState();
}

class _FeeDetailsFirstPageState extends State<FeeDetailsFirstPage> with SingleTickerProviderStateMixin {
  final session = Get.find<UserSession>();
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  late Future<List<FeeStructureModel>> _feeFuture;

  final List<String> _feeNames = ['Overview', 'Fee Dues', 'Total Fee', 'Bus Fee', 'History'];

  static const LinearGradient appGradient = LinearGradient(
    colors: [Color(0xff4A90E2), Color(0xff6FD3F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   statusBarColor: Colors.black, // transparent so AppBar image shows through
    //   statusBarIconBrightness: Brightness.light, // dark icons (visible on light bg)
    //   // or Brightness.light if your header image is dark
    // ));
    _feeFuture = fetchFeeDetails();
    _pageController.addListener(() {
      int next = (_pageController.page ?? 0).round();
      if (_currentPageIndex != next) setState(() => _currentPageIndex = next);
    });
  }

  Future<List<FeeStructureModel>> fetchFeeDetails() async {
    String baseUrl = ApiConstants.baseUrl;

    final controller = Get.find<MyChildrenController>();
    final String token = session.token ?? '';
    final String schoolId = session.schoolId ?? '';
    final String classId = controller.selectedChild['classId'] ?? '';

    final queryParameters = {
      "schoolId": schoolId,
      "classId": classId,
    };

    final uri = Uri.parse('$baseUrl/api/feestructure/getbyclass').replace(queryParameters: queryParameters);
    print('classId:$classId');

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        print(response.body);
        final decodedData = jsonDecode(response.body);
        final List<dynamic> list = decodedData['data'] ?? [];
        return list.map((item) => FeeStructureModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint("API Error: $e");
    }
    print('error');
    return [];
  }


  // ------------------------------------------------- BUILD METHOD ----------------------------------------


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // match your blue gradient color
          statusBarIconBrightness: Brightness.light, // white icons
          statusBarBrightness: Brightness.dark,
        ),
        flexibleSpace: Container(decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/Scientific UI background design header.png'), fit: BoxFit.cover))),
        backgroundColor: Colors.transparent,
        title: const Text('Fee Details', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black), // Custom icon and color
          onPressed: () => Navigator.of(context).pop(), // Don't forget this!
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.8),      // Change Circle Color here
          ),
        ),
        toolbarHeight: MediaQuery.sizeOf(context).height * 0.10,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopMenu(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _feeNames.length,
                itemBuilder: (context, index) {
                  return FutureBuilder<List<FeeStructureModel>>(
                    future: _feeFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No fee data found"));


         // --------------------------------- LIST VIEW BUILDER FOR FEE DETAILS ---------------------------------


                      return ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, i) => Column(
                          children: [
                            FeeContainerTile(fee: snapshot.data![i]),
                           // FeeContainerTile(fee: snapshot.data![i]),

                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMenu() {
    return Container(
      decoration: const BoxDecoration(gradient: appGradient),
      child: Container(
        padding: const EdgeInsets.only(top: 20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topRight: Radius.circular(30))),
        child: SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _feeNames.length,
            itemBuilder: (context, index) {
              bool isSelected = _currentPageIndex == index;
              return GestureDetector(
                onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(_feeNames[index], style: TextStyle(color: isSelected ? const Color(0xff4A90E2) : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      if (isSelected) Container(margin: const EdgeInsets.only(top: 4), height: 2, width: 30, color: const Color(0xff4A90E2)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// --- TILE COMPONENT ---

class FeeContainerTile extends StatefulWidget {
  final FeeStructureModel fee;
  const FeeContainerTile({super.key, required this.fee});

  @override
  State<FeeContainerTile> createState() => _FeeContainerTileState();
}

class _FeeContainerTileState extends State<FeeContainerTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(gradient: _FeeDetailsFirstPageState.appGradient, borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        // This removes the border when expanded
        shape: const Border(),
        // This ensures no border appears when collapsed
        collapsedShape: const Border(),
        onExpansionChanged: (val) => setState(() => _isExpanded = val),
        title: Text('${widget.fee.type == 'new' ? 'New Student' : 'Existing Student'} Fee Structure', style: const TextStyle(color: Colors.white, fontSize: 8, letterSpacing: 1.1)),
        subtitle: Text('Total Payable: ₹ ${widget.fee.totalAmount}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        trailing: Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Divider(color: Colors.white24),
                _row("Admission Fee", widget.fee.feeHead['admissionFee']),
                _row("Term 1 Fee", widget.fee.feeHead['firstTermAmt']),
                _row("Term 2 Fee", widget.fee.feeHead['secondTermAmt']),
                if ((widget.fee.feeHead['busFirstTermAmt'] ?? 0) > 0)
                  _row("Bus Fee (Term 1)", widget.fee.feeHead['busFirstTermAmt']),
                if ((widget.fee.feeHead['busSecondTermAmt'] ?? 0) > 0)
                  _row("Bus Fee (Term 2)", widget.fee.feeHead['busSecondTermAmt']),
                const Divider(color: Colors.white24),
                _row("Total Due", widget.fee.totalAmount, isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, dynamic value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text('₹ $value', style: TextStyle(color: Colors.white, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }
}