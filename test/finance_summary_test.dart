import 'package:flutter_test/flutter_test.dart';
import 'package:grupli/main.dart';
void main() {
  test('a one-cent outstanding share remains visible and is settled exactly', () {
    final summary=FinanceSummary.from([
      {'amount':0.02,'paid_by':'a','status':'pending','expense_participants':[
        {'user_id':'a','share_amount':0.01,'paid':true},
        {'user_id':'b','share_amount':0.01,'paid':false},
      ]},
    ],[{'user_id':'a','profiles':{'full_name':'A'}},{'user_id':'b','profiles':{'full_name':'B'}}],[],currentUserId:'b');
    expect(summary.balances['a'],0.01);
    expect(summary.balances['b'],-0.01);
    expect(summary.peopleWithBalance,2);
    expect(summary.pendingAmount,0.01);
    expect(summary.settlementAmount,0.01);
  });
}
