import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/data/member_model.dart';
import 'package:toka/features/members/domain/member.dart';

void main() {
  final now = Timestamp.fromDate(DateTime(2026, 1, 1));

  Map<String, dynamic> baseData({
    String role = 'member',
    String status = 'active',
    String phoneVisibility = 'hidden',
    String? phone,
  }) =>
      {
        'nickname': 'Ana',
        'photoUrl': null,
        'bio': 'Hola soy Ana',
        'phone': phone,
        'phoneVisibility': phoneVisibility,
        'role': role,
        'status': status,
        'joinedAt': now,
        'tasksCompleted': 10,
        'passedCount': 2,
        'complianceRate': 0.83,
        'currentStreak': 3,
        'averageScore': 8.5,
      };

  test('Member.fromMap mapea role owner correctamente', () {
    final member = MemberModel.fromMap(
        'uid1', 'home1', baseData(role: 'owner'));
    expect(member.role, MemberRole.owner);
  });

  test('Member.fromMap mapea role admin correctamente', () {
    final member = MemberModel.fromMap(
        'uid1', 'home1', baseData(role: 'admin'));
    expect(member.role, MemberRole.admin);
  });

  test('Member.fromMap mapea status frozen correctamente', () {
    final member = MemberModel.fromMap(
        'uid1', 'home1', baseData(status: 'frozen'));
    expect(member.status, MemberStatus.frozen);
  });

  test('Member.phoneForViewer retorna null cuando hidden y no es propio', () {
    final member = MemberModel.fromMap(
        'uid1', 'home1', baseData(phone: '123456789', phoneVisibility: 'hidden'));
    expect(member.phoneForViewer(isSelf: false), isNull);
  });

  test('Member.phoneForViewer retorna teléfono cuando sameHomeMembers', () {
    final member = MemberModel.fromMap(
        'uid1', 'home1',
        baseData(phone: '123456789', phoneVisibility: 'sameHomeMembers'));
    expect(member.phoneForViewer(isSelf: false), '123456789');
  });

  test('Member.phoneForViewer retorna teléfono propio aunque sea hidden', () {
    final member = MemberModel.fromMap(
        'uid1', 'home1', baseData(phone: '123456789', phoneVisibility: 'hidden'));
    expect(member.phoneForViewer(isSelf: true), '123456789');
  });

  test('Member tiene valores por defecto cuando campos opcionales son null', () {
    final member = MemberModel.fromMap('uid2', 'home1', {
      'nickname': 'Bob',
      'joinedAt': now,
    });
    expect(member.complianceRate, 0.0);
    expect(member.tasksCompleted, 0);
    expect(member.phoneVisibility, 'hidden');
  });
}
