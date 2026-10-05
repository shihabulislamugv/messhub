enum BillType {
  rent, // Basha Vara
  electricity,
  water, // Pani
  housekeeper, // Bua
  gas,
  internet,
  other,
}

enum SplitMethod {
  equal,
  custom,
}

class BillSplitResult {
  final bool isValid;
  final String? errorMessage;
  final Map<String, double> memberAllocations;

  const BillSplitResult({
    required this.isValid,
    this.errorMessage,
    required this.memberAllocations,
  });
}

class BillSplitValidator {
  /// Validates and computes member shares for a given bill.
  /// 
  /// Critical business rules:
  /// 1. Basha Vara (rent) MUST ONLY support Custom Split.
  /// 2. If equal split is requested for Basha Vara, validation fails.
  /// 3. For Custom Split, SUM(allocations) must equal total bill amount (delta <= 0.01).
  /// 4. For Equal Split, bill amount is divided equally among members.
  static BillSplitResult calculateAndValidate({
    required BillType billType,
    required SplitMethod splitMethod,
    required double totalAmount,
    required List<String> memberIds,
    Map<String, double>? customAllocations,
  }) {
    if (totalAmount <= 0) {
      return const BillSplitResult(
        isValid: false,
        errorMessage: 'Enter a valid amount.',
        memberAllocations: {},
      );
    }

    if (memberIds.isEmpty) {
      return const BillSplitResult(
        isValid: false,
        errorMessage: 'At least one member is required.',
        memberAllocations: {},
      );
    }

    // CRITICAL RULE: Basha Vara MUST ONLY support Custom Split
    if (billType == BillType.rent && splitMethod == SplitMethod.equal) {
      return const BillSplitResult(
        isValid: false,
        errorMessage: 'Basha Vara (House Rent) only supports Custom Split because room rents vary.',
        memberAllocations: {},
      );
    }

    if (splitMethod == SplitMethod.equal) {
      final perMember = totalAmount / memberIds.length;
      final allocations = <String, double>{};
      for (final id in memberIds) {
        allocations[id] = perMember;
      }
      return BillSplitResult(
        isValid: true,
        memberAllocations: allocations,
      );
    } else {
      // Custom Split
      if (customAllocations == null) {
        return const BillSplitResult(
          isValid: false,
          errorMessage: 'Custom allocations must be provided.',
          memberAllocations: {},
        );
      }

      double allocatedSum = 0.0;
      for (final id in memberIds) {
        final amount = customAllocations[id] ?? 0.0;
        if (amount < 0) {
          return const BillSplitResult(
            isValid: false,
            errorMessage: 'Allocation amount cannot be negative.',
            memberAllocations: {},
          );
        }
        allocatedSum += amount;
      }

      // Check sum equality with 0.01 precision
      final diff = (allocatedSum - totalAmount).abs();
      if (diff > 0.01) {
        return BillSplitResult(
          isValid: false,
          errorMessage: 'The member shares must equal the total bill. Allocated: ৳${allocatedSum.toStringAsFixed(2)}, Total: ৳${totalAmount.toStringAsFixed(2)}',
          memberAllocations: customAllocations,
        );
      }

      return BillSplitResult(
        isValid: true,
        memberAllocations: Map.from(customAllocations),
      );
    }
  }
}
