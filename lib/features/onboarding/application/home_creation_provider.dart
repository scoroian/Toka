import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/home_creation_repository_impl.dart';
import '../domain/home_creation_repository.dart';

part 'home_creation_provider.g.dart';

@Riverpod(keepAlive: true)
HomeCreationRepository homeCreationRepository(Ref ref) {
  return HomeCreationRepositoryImpl(
    functions: FirebaseFunctions.instance,
    firestore: FirebaseFirestore.instance,
  );
}
