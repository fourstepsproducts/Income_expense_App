import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/core/widgets/custom_button.dart';
import 'package:personal_finance_tracker/core/widgets/empty_state.dart';
import 'package:personal_finance_tracker/core/widgets/stat_card.dart';

void main() {
  testWidgets('StatCard renders title, formatted amount and badge correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatCard(
            title: 'NET BALANCE',
            amount: 45000.0,
            currency: 'INR',
            icon: Icons.account_balance_wallet_rounded,
            accentColor: Colors.blue,
            badgeText: '+15%',
            isPositiveBadge: true,
          ),
        ),
      ),
    );

    expect(find.text('NET BALANCE'), findsOneWidget);
    expect(find.textContaining('45,000'), findsOneWidget);
    expect(find.text('+15%'), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_rounded), findsOneWidget);
  });

  testWidgets('EmptyState displays title, message, and responds to action button', (WidgetTester tester) async {
    bool actionTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'No Transactions',
            message: 'You have not added any transactions yet.',
            buttonText: 'Add Transaction',
            onAction: () => actionTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('No Transactions'), findsOneWidget);
    expect(find.text('You have not added any transactions yet.'), findsOneWidget);
    expect(find.text('Add Transaction'), findsOneWidget);

    await tester.tap(find.text('Add Transaction'));
    await tester.pump();
    expect(actionTapped, true);
  });

  testWidgets('CustomButton displays loading spinner when isLoading is true', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Submit Form',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Submit Form'), findsNothing);
  });
}
