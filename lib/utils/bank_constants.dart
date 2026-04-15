// Malaysian Banks List with Stripe/FPX Bank Codes
class BankModel {
  final String code; // Bank code for Stripe/FPX
  final String name; // Display name

  BankModel({required this.code, required this.name});

  @override
  String toString() => name;
}

class BankConstants {
  // Malaysian Banks with FPX/Stripe bank codes
  static const List<Map<String, String>> malaysianBanksData = [
    {'code': '002', 'name': 'Maybank'},
    {'code': '004', 'name': 'Public Bank'},
    {'code': '006', 'name': 'RHB Bank'},
    {'code': '008', 'name': 'CIMB Bank'},
    {'code': '011', 'name': 'OCBC Bank'},
    {'code': '012', 'name': 'Affin Bank'},
    {'code': '014', 'name': 'Bank Islam'},
    {'code': '015', 'name': 'Alliance Bank'},
    {'code': '016', 'name': 'AmBank'},
    {'code': '019', 'name': 'UOB Bank'},
    {'code': '020', 'name': 'HSBC Bank'},
    {'code': '023', 'name': 'Standard Chartered'},
    {'code': '025', 'name': 'Citibank'},
    {'code': '026', 'name': 'Deutsche Bank'},
    {'code': '028', 'name': 'KFH (Kuala Lumpur)'},
    {'code': '031', 'name': 'Maybank Islamic'},
    {'code': '034', 'name': 'Bank Muamalat'},
    {'code': '036', 'name': 'CIMB Islamic'},
    {'code': '037', 'name': 'Public Bank Islamic'},
    {'code': '042', 'name': 'OCBC Islamic'},
    {'code': '045', 'name': 'Hong Leong Bank'},
    {'code': '047', 'name': 'Bank Kerjasama Rakyat'},
    {'code': '050', 'name': 'UOB Islamic'},
    {'code': '052', 'name': 'RHB Islamic'},
    {'code': '058', 'name': 'Bank Simpanan Nasional'},
    {'code': '060', 'name': 'Bank Rakyat'},
    {'code': '069', 'name': 'Bank Pembangunan'},
    {'code': '070', 'name': 'Bank Pertanian'},
    {'code': '071', 'name': 'Agrobank'},
    {'code': '072', 'name': 'BAJ Bank'},
    {'code': '073', 'name': 'Bank Negara Malaysia'},
  ];

  static List<BankModel> get malaysianBanks {
    return malaysianBanksData
        .map((data) => BankModel(code: data['code']!, name: data['name']!))
        .toList();
  }

  static List<BankModel> searchBanks(String query) {
    if (query.isEmpty) {
      return malaysianBanks;
    }
    final lowerQuery = query.toLowerCase();
    return malaysianBanks
        .where(
          (bank) =>
              bank.name.toLowerCase().contains(lowerQuery) ||
              bank.code.contains(query),
        )
        .toList();
  }

  // Get bank code by name
  static String? getBankCode(String bankName) {
    try {
      return malaysianBanksData.firstWhere(
        (bank) => bank['name'] == bankName,
      )['code'];
    } catch (e) {
      return null;
    }
  }

  // Get bank name by code
  static String? getBankName(String bankCode) {
    try {
      return malaysianBanksData.firstWhere(
        (bank) => bank['code'] == bankCode,
      )['name'];
    } catch (e) {
      return null;
    }
  }
}
