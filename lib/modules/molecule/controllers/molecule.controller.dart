// lib/modules/molecule/controllers/molecule.controller.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/modules/home/home.dart';

/// Drives a single molecule's screen: the atoms organised into it, with
/// infinite scroll. Page-owned (created by the MoleculePage State) so a quick
/// exit → re-enter can never reuse a dying instance; [active] is the handle
/// other modules refresh (socket events, atom changes).
class MoleculeController extends GetxController {
  MoleculeController({required this.moleculeId, required this.moleculeName});

  static MoleculeController? active;

  final String moleculeId;
  final String moleculeName;

  final HomeService _home = Get.find<HomeService>();

  final RxList<AtomModel> atoms = <AtomModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxBool hasError = false.obs;

  int _currentPage = 1;
  static const int _pageSize = 20;
  static const int _loadAttempts = 3;
  static const Duration _retryBackoff = Duration(milliseconds: 800);

  @override
  void onInit() {
    super.onInit();
    active = this;
    if (Get.testMode) return;
    // Deferred one frame: the controller is created while the route's first
    // build is still running; Rx writes inside a build phase trip flutter's
    // markNeedsBuild guard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      reload();
    });
  }

  @override
  void onClose() {
    if (active == this) active = null;
    super.onClose();
  }

  /// Loads the molecule's first page of atoms, retrying transient cold-start
  /// failures quietly — the same tolerance the old home list had.
  Future<void> reload() async {
    if (moleculeId.isEmpty) {
      isLoading.value = false;
      hasError.value = true;
      return;
    }

    isLoading.value = true;
    hasError.value = false;

    for (var attempt = 1; attempt <= _loadAttempts; attempt++) {
      try {
        final result = await _home.getAtoms(
          page: 1,
          limit: _pageSize,
          categoryId: moleculeId,
        );
        atoms.assignAll(result.records);
        _currentPage = 1;
        hasMore.value =
            result.pagination?.hasNextPage ??
            (result.records.length >= _pageSize);
        hasError.value = false;
        isLoading.value = false;
        return;
      } catch (error) {
        debugPrint(
          '💠 [MoleculeController] reload attempt $attempt/$_loadAttempts: $error',
        );
        if (attempt < _loadAttempts) {
          await Future<void>.delayed(_retryBackoff * attempt);
          continue;
        }
        hasError.value = true;
      }
    }

    isLoading.value = false;
  }

  /// Appends the next page — driven by infinite scroll. A failed page leaves
  /// the list untouched so the next scroll retries.
  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    final nextPage = _currentPage + 1;

    try {
      final result = await _home.getAtoms(
        page: nextPage,
        limit: _pageSize,
        categoryId: moleculeId,
      );

      // Guard against a reload that landed while this page was in flight.
      if (nextPage == _currentPage + 1) {
        atoms.addAll(result.records);
        _currentPage = nextPage;
      }
      hasMore.value =
          result.pagination?.hasNextPage ??
          (result.records.length >= _pageSize);
    } catch (error) {
      debugPrint('💠 [MoleculeController] loadMore page $nextPage failed: $error');
    } finally {
      isLoadingMore.value = false;
    }
  }
}
