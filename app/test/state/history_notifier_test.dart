import 'package:app/models/llm_provider_type.dart' show LLMProviderType;
import 'package:flutter_test/flutter_test.dart'
    show addTearDown, expect, hasLength, isFalse, test;

import 'history_notifier_test_support.dart'
    show createHistoryFixture, sampleRun;

void main() {
  _loadHistoryTest();
  _providerFilterTest();
  _searchFilterTest();
  _selectionLimitTest();
  _deleteRunTest();
}

void _loadHistoryTest() {
  test('loadHistory populates all runs from storage', () async {
    final fixture = createHistoryFixture();
    addTearDown(fixture.notifier.dispose);
    await fixture.notifier.loadHistory(fixture.storage);
    expect(fixture.notifier.allRuns, hasLength(2));
  });
}

void _providerFilterTest() {
  test('filteredRuns filters by provider type', () async {
    final fixture = createHistoryFixture();
    addTearDown(fixture.notifier.dispose);
    await fixture.notifier.loadHistory(fixture.storage);
    fixture.notifier.setProviderFilter(LLMProviderType.gemini);
    expect(fixture.notifier.filteredRuns, hasLength(1));
    expect(fixture.notifier.filteredRuns.single.id, '1');
  });
}

void _searchFilterTest() {
  test('filteredRuns filters by search query', () async {
    final fixture = createHistoryFixture();
    addTearDown(fixture.notifier.dispose);
    await fixture.notifier.loadHistory(fixture.storage);
    fixture.notifier.setSearchQuery('mistral');
    expect(fixture.notifier.filteredRuns, hasLength(1));
    expect(fixture.notifier.filteredRuns.single.id, '2');
  });
}

void _selectionLimitTest() {
  test('comparison selection is limited to four loaded runs', () async {
    final fixture = createHistoryFixture();
    addTearDown(fixture.notifier.dispose);
    fixture.storage.runs
      ..clear()
      ..addAll(List.generate(6, (index) => sampleRun('run_$index')));
    await fixture.notifier.loadHistory(fixture.storage);
    for (var index = 0; index < 4; index++) {
      fixture.notifier.toggleRunSelectionForComparison('run_$index');
    }
    expect(fixture.notifier.toggleRunSelectionForComparison('run_4'), isFalse);
    expect(fixture.notifier.toggleRunSelectionForComparison('run_5'), isFalse);
    expect(fixture.notifier.selectedRunIdsForComparison, hasLength(4));
  });
}

void _deleteRunTest() {
  test('deleteRun updates history state and storage', () async {
    final fixture = createHistoryFixture();
    addTearDown(fixture.notifier.dispose);
    await fixture.notifier.loadHistory(fixture.storage);
    await fixture.notifier.deleteRun('1', fixture.storage);
    expect(fixture.notifier.allRuns, hasLength(1));
    expect(fixture.notifier.allRuns.single.id, '2');
    expect(fixture.storage.runs, hasLength(1));
  });
}
