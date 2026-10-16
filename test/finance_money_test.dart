import 'package:flutter_test/flutter_test.dart';
import 'package:grupli/core/finance/finance_money.dart';
void main() {
  test('10 euros split three ways preserves every cent', () {
    final shares = FinanceMoney.splitEqual(10, ['c','b','a']);
    expect(shares, {'a':3.34,'b':3.33,'c':3.33});
    expect(FinanceMoney.matchesTotal(10,shares.values),isTrue);
  });
  test('duplicate ids and selection order cannot alter the split', () {
    expect(FinanceMoney.splitEqual(0.01,['b','a','a']),{'a':0.01,'b':0.0});
  });
  test('invalid and incomplete splits are rejected', () {
    expect(FinanceMoney.matchesTotal(10,[3.33,3.33,3.33]),isFalse);
    expect(FinanceMoney.matchesTotal(10,[-1,11]),isFalse);
    expect(()=>FinanceMoney.splitEqual(double.nan,['a']),throwsArgumentError);
    expect(()=>FinanceMoney.splitEqual(10,[]),throwsArgumentError);
  });
  test('small and large groups preserve the exact total', () {
    for(var total=1;total<500;total++) {
      for(var size=1;size<25;size++) {
        final shares=FinanceMoney.splitEqual(total/100,List.generate(size,(i)=>'$i'));
        expect(shares.values.map(FinanceMoney.cents).reduce((a,b)=>a+b),total);
      }
    }
  });
}
