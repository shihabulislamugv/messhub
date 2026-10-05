import '../models/user_profile.dart';
import '../models/mess.dart';
import '../models/monthly_cycle.dart';
import '../models/bill.dart';
import '../models/expense.dart';
import '../models/meal.dart';
import '../../domain/calculations/bill_split_validator.dart';
import '../../domain/calculations/meal_rate_calculator.dart';

class MockSeedService {
  static final UserProfile currentMember = UserProfile(
    id: 'user_shihab',
    name: 'Shihabul Islam',
    email: 'shihab@messhub.app',
    phone: '01711223344',
    avatarUrl: null,
    createdAt: DateTime(2026, 1, 1),
  );

  static final List<UserProfile> allUsers = [
    currentMember,
    UserProfile(
      id: 'user_rahim',
      name: 'Rahim Ahmed',
      email: 'rahim@messhub.app',
      phone: '01811223344',
      avatarUrl: null,
      createdAt: DateTime(2026, 1, 1),
    ),
    UserProfile(
      id: 'user_karim',
      name: 'Karim Chowdhury',
      email: 'karim@messhub.app',
      phone: '01911223344',
      avatarUrl: null,
      createdAt: DateTime(2026, 1, 1),
    ),
    UserProfile(
      id: 'user_hasan',
      name: 'Hasan Mahmud',
      email: 'hasan@messhub.app',
      phone: '01611223344',
      avatarUrl: null,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  static final Mess sampleMess = Mess(
    id: 'mess_swapno_neer',
    name: 'Swapno Neer (স্বপ্ন নীড়)',
    area: 'Mirpur-2, Dhaka',
    inviteCode: 'MH8824',
    cycleStartDay: 1,
    description: 'Bachelor mess for university students and professionals.',
    createdBy: 'user_shihab',
    createdAt: DateTime(2026, 1, 1),
  );

  static final List<MessMember> sampleMembers = [
    MessMember(
      id: 'mem_1',
      messId: 'mess_swapno_neer',
      userId: 'user_shihab',
      role: MemberRole.admin,
      joinedAt: DateTime(2026, 1, 1),
      userName: 'Shihabul Islam',
      userEmail: 'shihab@messhub.app',
    ),
    MessMember(
      id: 'mem_2',
      messId: 'mess_swapno_neer',
      userId: 'user_rahim',
      role: MemberRole.member,
      joinedAt: DateTime(2026, 1, 2),
      userName: 'Rahim Ahmed',
      userEmail: 'rahim@messhub.app',
    ),
    MessMember(
      id: 'mem_3',
      messId: 'mess_swapno_neer',
      userId: 'user_karim',
      role: MemberRole.member,
      joinedAt: DateTime(2026, 1, 2),
      userName: 'Karim Chowdhury',
      userEmail: 'karim@messhub.app',
    ),
    MessMember(
      id: 'mem_4',
      messId: 'mess_swapno_neer',
      userId: 'user_hasan',
      role: MemberRole.member,
      joinedAt: DateTime(2026, 1, 3),
      userName: 'Hasan Mahmud',
      userEmail: 'hasan@messhub.app',
    ),
  ];

  static final MonthlyCycle currentCycle = MonthlyCycle(
    id: 'cycle_current',
    messId: 'mess_swapno_neer',
    year: 2027,
    month: 3, // March 2027
    isClosed: false,
    createdAt: DateTime(2027, 3, 1),
  );

  static List<Bill> getInitialBills() => [
    Bill(
      id: 'bill_rent_1',
      messId: 'mess_swapno_neer',
      cycleId: 'cycle_current',
      billType: BillType.rent,
      title: 'Basha Vara (House Rent)',
      totalAmount: 15000.0,
      paidBy: 'user_shihab',
      splitMethod: SplitMethod.custom,
      dueDate: DateTime(2027, 3, 5),
      note: 'Room 1 master (Shihab & Hasan), Room 2 (Rahim & Karim)',
      createdAt: DateTime(2027, 3, 1),
      paidByName: 'Shihabul Islam',
      splits: const [
        BillSplit(id: 's_1', billId: 'bill_rent_1', memberId: 'user_shihab', amount: 4000.0, memberName: 'Shihabul Islam'),
        BillSplit(id: 's_2', billId: 'bill_rent_1', memberId: 'user_rahim', amount: 3500.0, memberName: 'Rahim Ahmed'),
        BillSplit(id: 's_3', billId: 'bill_rent_1', memberId: 'user_karim', amount: 3500.0, memberName: 'Karim Chowdhury'),
        BillSplit(id: 's_4', billId: 'bill_rent_1', memberId: 'user_hasan', amount: 4000.0, memberName: 'Hasan Mahmud'),
      ],
    ),
    Bill(
      id: 'bill_elec_1',
      messId: 'mess_swapno_neer',
      cycleId: 'cycle_current',
      billType: BillType.electricity,
      title: 'DESCO Electricity Bill',
      totalAmount: 2400.0,
      paidBy: 'user_rahim',
      splitMethod: SplitMethod.equal,
      dueDate: DateTime(2027, 3, 15),
      createdAt: DateTime(2027, 3, 5),
      paidByName: 'Rahim Ahmed',
      splits: const [
        BillSplit(id: 's_5', billId: 'bill_elec_1', memberId: 'user_shihab', amount: 600.0, memberName: 'Shihabul Islam'),
        BillSplit(id: 's_6', billId: 'bill_elec_1', memberId: 'user_rahim', amount: 600.0, memberName: 'Rahim Ahmed'),
        BillSplit(id: 's_7', billId: 'bill_elec_1', memberId: 'user_karim', amount: 600.0, memberName: 'Karim Chowdhury'),
        BillSplit(id: 's_8', billId: 'bill_elec_1', memberId: 'user_hasan', amount: 600.0, memberName: 'Hasan Mahmud'),
      ],
    ),
    Bill(
      id: 'bill_water_1',
      messId: 'mess_swapno_neer',
      cycleId: 'cycle_current',
      billType: BillType.water,
      title: 'WASA Pani Bill',
      totalAmount: 600.0,
      paidBy: 'user_karim',
      splitMethod: SplitMethod.equal,
      createdAt: DateTime(2027, 3, 10),
      paidByName: 'Karim Chowdhury',
      splits: const [
        BillSplit(id: 's_9', billId: 'bill_water_1', memberId: 'user_shihab', amount: 150.0, memberName: 'Shihabul Islam'),
        BillSplit(id: 's_10', billId: 'bill_water_1', memberId: 'user_rahim', amount: 150.0, memberName: 'Rahim Ahmed'),
        BillSplit(id: 's_11', billId: 'bill_water_1', memberId: 'user_karim', amount: 150.0, memberName: 'Karim Chowdhury'),
        BillSplit(id: 's_12', billId: 'bill_water_1', memberId: 'user_hasan', amount: 150.0, memberName: 'Hasan Mahmud'),
      ],
    ),
    Bill(
      id: 'bill_bua_1',
      messId: 'mess_swapno_neer',
      cycleId: 'cycle_current',
      billType: BillType.housekeeper,
      title: 'Bua (Cooking & Cleaning)',
      totalAmount: 2000.0,
      paidBy: 'user_hasan',
      splitMethod: SplitMethod.custom,
      createdAt: DateTime(2027, 3, 2),
      paidByName: 'Hasan Mahmud',
      splits: const [
        BillSplit(id: 's_13', billId: 'bill_bua_1', memberId: 'user_shihab', amount: 500.0, memberName: 'Shihabul Islam'),
        BillSplit(id: 's_14', billId: 'bill_bua_1', memberId: 'user_rahim', amount: 500.0, memberName: 'Rahim Ahmed'),
        BillSplit(id: 's_15', billId: 'bill_bua_1', memberId: 'user_karim', amount: 500.0, memberName: 'Karim Chowdhury'),
        BillSplit(id: 's_16', billId: 'bill_bua_1', memberId: 'user_hasan', amount: 500.0, memberName: 'Hasan Mahmud'),
      ],
    ),
    Bill(
      id: 'bill_wifi_1',
      messId: 'mess_swapno_neer',
      cycleId: 'cycle_current',
      billType: BillType.internet,
      title: 'Amber IT Wi-Fi Bill',
      totalAmount: 800.0,
      paidBy: 'user_shihab',
      splitMethod: SplitMethod.equal,
      createdAt: DateTime(2027, 3, 1),
      paidByName: 'Shihabul Islam',
      splits: const [
        BillSplit(id: 's_17', billId: 'bill_wifi_1', memberId: 'user_shihab', amount: 200.0, memberName: 'Shihabul Islam'),
        BillSplit(id: 's_18', billId: 'bill_wifi_1', memberId: 'user_rahim', amount: 200.0, memberName: 'Rahim Ahmed'),
        BillSplit(id: 's_19', billId: 'bill_wifi_1', memberId: 'user_karim', amount: 200.0, memberName: 'Karim Chowdhury'),
        BillSplit(id: 's_20', billId: 'bill_wifi_1', memberId: 'user_hasan', amount: 200.0, memberName: 'Hasan Mahmud'),
      ],
    ),
  ];

  static List<Expense> getInitialExpenses() => [
    Expense(
      id: 'exp_1',
      messId: 'mess_swapno_neer',
      cycleId: 'cycle_current',
      title: 'Monthly Dry Bazar (Rice, Oil, Spices)',
      amount: 4200.0,
      category: ExpenseCategory.bazar,
      paidBy: 'user_rahim',
      expenseDate: DateTime(2027, 3, 2),
      paidByName: 'Rahim Ahmed',
      createdAt: DateTime(2027, 3, 2),
      bazarItems: const [
        BazarItem(id: 'b_1', itemName: 'Miniket Rice', quantity: 25, unit: 'kg', price: 1800.0),
        BazarItem(id: 'b_2', itemName: 'Soybean Oil (Rupchanda)', quantity: 5, unit: 'litre', price: 950.0),
        BazarItem(id: 'b_3', itemName: 'Onion & Garlic', quantity: 5, unit: 'kg', price: 450.0),
        BazarItem(id: 'b_4', itemName: 'Spices & Salt', quantity: 1, unit: 'pack', price: 1000.0),
      ],
    ),
    Expense(
      id: 'exp_2',
      messId: 'mess_swapno_neer',
      cycleId: 'cycle_current',
      title: 'Weekly Fresh Bazar (Fish, Chicken, Eggs, Veggies)',
      amount: 4250.0,
      category: ExpenseCategory.bazar,
      paidBy: 'user_shihab',
      expenseDate: DateTime(2027, 3, 8),
      paidByName: 'Shihabul Islam',
      createdAt: DateTime(2027, 3, 8),
      bazarItems: const [
        BazarItem(id: 'b_5', itemName: 'Rui Fish', quantity: 3, unit: 'kg', price: 1200.0),
        BazarItem(id: 'b_6', itemName: 'Broiler Chicken', quantity: 4, unit: 'kg', price: 880.0),
        BazarItem(id: 'b_7', itemName: 'Farm Eggs', quantity: 30, unit: 'pcs', price: 390.0),
        BazarItem(id: 'b_8', itemName: 'Vegetables & Potatoes', quantity: 8, unit: 'kg', price: 1780.0),
      ],
    ),
    Expense(
      id: 'exp_3',
      messId: 'mess_swapno_neer',
      cycleId: 'cycle_current',
      title: 'Flat Cleaning Supplies (Vim, Harpic, Floor Cleaner)',
      amount: 1200.0,
      category: ExpenseCategory.cleaning,
      paidBy: 'user_karim',
      expenseDate: DateTime(2027, 3, 3),
      paidByName: 'Karim Chowdhury',
      createdAt: DateTime(2027, 3, 3),
    ),
    Expense(
      id: 'exp_4',
      messId: 'mess_swapno_neer',
      cycleId: 'cycle_current',
      title: 'Plumbing Tap Repair in Bathroom',
      amount: 500.0,
      category: ExpenseCategory.repair,
      paidBy: 'user_shihab',
      expenseDate: DateTime(2027, 3, 11),
      paidByName: 'Shihabul Islam',
      createdAt: DateTime(2027, 3, 11),
    ),
    Expense(
      id: 'exp_5',
      messId: 'mess_swapno_neer',
      cycleId: 'cycle_current',
      title: 'Gas Cylinder Transport Van',
      amount: 450.0,
      category: ExpenseCategory.transport,
      paidBy: 'user_hasan',
      expenseDate: DateTime(2027, 3, 12),
      paidByName: 'Hasan Mahmud',
      createdAt: DateTime(2027, 3, 12),
    ),
  ];

  static List<MealEntry> getInitialMeals() => [
    MealEntry(
      id: 'meal_1',
      messId: 'mess_swapno_neer',
      cycleId: 'cycle_current',
      memberId: 'user_shihab',
      mealDate: DateTime(2027, 3, 15),
      breakfast: 1.0,
      lunch: 1.0,
      dinner: 1.0,
      createdAt: DateTime(2027, 3, 15),
      memberName: 'Shihabul Islam',
    ),
    MealEntry(
      id: 'meal_2',
      messId: 'mess_swapno_neer',
      cycleId: 'cycle_current',
      memberId: 'user_rahim',
      mealDate: DateTime(2027, 3, 15),
      breakfast: 1.0,
      lunch: 1.0,
      dinner: 1.0,
      createdAt: DateTime(2027, 3, 15),
      memberName: 'Rahim Ahmed',
    ),
    MealEntry(
      id: 'meal_3',
      messId: 'mess_swapno_neer',
      cycleId: 'cycle_current',
      memberId: 'user_karim',
      mealDate: DateTime(2027, 3, 15),
      breakfast: 0.0,
      lunch: 1.0,
      dinner: 1.0,
      createdAt: DateTime(2027, 3, 15),
      memberName: 'Karim Chowdhury',
    ),
    MealEntry(
      id: 'meal_4',
      messId: 'mess_swapno_neer',
      cycleId: 'cycle_current',
      memberId: 'user_hasan',
      mealDate: DateTime(2027, 3, 15),
      breakfast: 1.0,
      lunch: 1.0,
      dinner: 1.0,
      createdAt: DateTime(2027, 3, 15),
      memberName: 'Hasan Mahmud',
    ),
  ];

  static Map<String, double> getMonthlyMemberMealTotals() => {
    'user_shihab': 42.0,
    'user_rahim': 40.0,
    'user_karim': 38.0,
    'user_hasan': 40.0,
  };

  static List<SettlementRecord> getInitialSettlements() => [
    SettlementRecord(
      id: 'set_1',
      messId: 'mess_swapno_neer',
      cycleId: 'cycle_current',
      senderId: 'user_rahim',
      receiverId: 'user_shihab',
      amount: 600.0,
      paymentDate: DateTime(2027, 3, 16),
      note: 'Partial settlement paid via bKash',
      createdAt: DateTime(2027, 3, 16),
      senderName: 'Rahim Ahmed',
      receiverName: 'Shihabul Islam',
    ),
  ];
}
