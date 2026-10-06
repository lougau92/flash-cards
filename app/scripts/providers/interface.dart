abstract class LlmProvider {
  String get name;
  Future<List<String>> listModels();
  Future<String> summarize({required String text, required String modelName});
}
