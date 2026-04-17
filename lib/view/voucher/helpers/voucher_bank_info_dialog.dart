import 'package:flutter/material.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/models/RedeemedVouchers.dart';
import 'package:recycle_go/utils/bank_constants.dart';

/// Dialog for collecting bank information for exchange vouchers
class VoucherBankInfoDialog {
  /// Show bank information dialog
  static Future<Map<String, String>?> show(
    BuildContext context, {
    required RedeemedVouchers? currentVoucher,
  }) async {
    final theme = AppThemes.color;
    BankModel? selectedBankModel = currentVoucher?.bankName != null
        ? BankConstants.malaysianBanks.firstWhere(
            (bank) => bank.name == currentVoucher?.bankName,
            orElse: () => BankConstants.malaysianBanks.first,
          )
        : null;
    final TextEditingController accountNumberController = TextEditingController(
      text: currentVoucher?.bankAccountNumber ?? '',
    );
    final TextEditingController bankSearchController = TextEditingController();
    List<BankModel> filteredBanks = BankConstants.malaysianBanks;

    return showDialog<Map<String, String>?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Bank Information', style: TextDesign.headingTwo()),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please provide your bank information for the exchange transaction:',
                      style: TextDesign.smallText(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    // Bank Name Dropdown with Search
                    Text(
                      'Bank Name',
                      style: TextDesign.smallText().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: bankSearchController,
                      onChanged: (value) {
                        setState(() {
                          filteredBanks = BankConstants.searchBanks(value);
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search or select bank...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Bank List Dropdown
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredBanks.length,
                        itemBuilder: (context, index) {
                          final bank = filteredBanks[index];
                          final isSelected =
                              bank.code == selectedBankModel?.code;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedBankModel = bank;
                                bankSearchController.text = bank.name;
                                filteredBanks = BankConstants.malaysianBanks;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              color: isSelected
                                  ? theme.primary.withOpacity(0.1)
                                  : null,
                              child: Row(
                                children: [
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: theme.primary,
                                      size: 20,
                                    )
                                  else
                                    const Icon(
                                      Icons.radio_button_unchecked,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bank.name,
                                          style: TextDesign.smallText(),
                                        ),
                                        Text(
                                          'Code: ${bank.code}',
                                          style: TextDesign.smallText(
                                            color: Colors.grey[600],
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (selectedBankModel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: theme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Selected: ${selectedBankModel!.name} (${selectedBankModel!.code})',
                                  style: TextDesign.smallText(
                                    color: theme.primary,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Account Number Field
                    Text(
                      'Account Number',
                      style: TextDesign.smallText().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: accountNumberController,
                      decoration: InputDecoration(
                        hintText: 'Enter your bank account number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedBankModel == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Please select a bank'),
                          backgroundColor: theme.error,
                        ),
                      );
                      return;
                    }

                    final accountNumber = accountNumberController.text.trim();
                    if (accountNumber.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Please enter account number'),
                          backgroundColor: theme.error,
                        ),
                      );
                      return;
                    }

                    // Return bank name (display) but the code is available via BankConstants
                    Navigator.pop(context, {
                      'bankName': selectedBankModel!.name,
                      'bankCode': selectedBankModel!.code, // For Stripe API
                      'accountNumber': accountNumber,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                  ),
                  child: const Text('Save & Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
