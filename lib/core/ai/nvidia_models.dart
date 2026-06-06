// Catalog of available NVIDIA NIM and OpenRouter models.
// Model IDs are compatible with POST /v1/chat/completions
// on either integrate.api.nvidia.com (NVIDIA) or
// openrouter.ai/api/v1 (OpenRouter).

enum NvidiaModelProvider { nvidia, openRouter, qwen }

class NvidiaModel {
  final String id;
  final String name;
  final String description;
  final NvidiaModelProvider provider;
  final int contextLength;
  final int maxTokens;

  const NvidiaModel({
    required this.id,
    required this.name,
    required this.description,
    required this.provider,
    this.contextLength = 8192,
    this.maxTokens = 4096,
  });
}

class NvidiaModelCatalog {
  NvidiaModelCatalog._();

  // ── NVIDIA NIM (build.nvidia.com) ──────────────────────────────────

  static const deepseekV4Flash = NvidiaModel(
    id: 'deepseek-ai/deepseek-v4-flash',
    name: 'DeepSeek V4 Flash',
    description: '284B MoE (13B active). Fast coding, 1M context.',
    provider: NvidiaModelProvider.nvidia,
    contextLength: 1_000_000,
    maxTokens: 8192,
  );

  static const nemotron3Ultra = NvidiaModel(
    id: 'nvidia/nemotron-3-ultra-550b-a55b',
    name: 'Nemotron 3 Ultra',
    description: '550B MoE (55B active). Best quality reasoning & coding.',
    provider: NvidiaModelProvider.nvidia,
    contextLength: 131072,
    maxTokens: 8192,
  );

  static const nemotron3Super = NvidiaModel(
    id: 'nvidia/nemotron-3-super-120b-a12b',
    name: 'Nemotron 3 Super',
    description: '120B MoE (12B active). 1M context, agentic reasoning.',
    provider: NvidiaModelProvider.nvidia,
    contextLength: 1_000_000,
    maxTokens: 8192,
  );

  static const nemotron3Nano = NvidiaModel(
    id: 'nvidia/nemotron-3-nano-30b-a3b',
    name: 'Nemotron 3 Nano',
    description: '30B MoE (3B active). 1M context, efficient coding.',
    provider: NvidiaModelProvider.nvidia,
    contextLength: 1_000_000,
    maxTokens: 4096,
  );

  static const nemotronSuper49B = NvidiaModel(
    id: 'nvidia/llama-3.3-nemotron-super-49b-v1.5',
    name: 'Nemotron Super 49B v1.5',
    description: '49B dense model, successor to Llama 3.3 Nemotron Super.',
    provider: NvidiaModelProvider.nvidia,
    contextLength: 131072,
    maxTokens: 8192,
  );

  static const llama33_70b = NvidiaModel(
    id: 'meta/llama-3.3-70b-instruct',
    name: 'Llama 3.3 70B',
    description: 'Meta Llama 3.3 70B. Strong general-purpose model.',
    provider: NvidiaModelProvider.nvidia,
    contextLength: 131072,
    maxTokens: 8192,
  );

  static const llama32Vision = NvidiaModel(
    id: 'meta/llama-3.2-11b-vision-instruct',
    name: 'Llama 3.2 11B Vision',
    description: 'Vision-language model. Understands text + images.',
    provider: NvidiaModelProvider.nvidia,
    contextLength: 131072,
    maxTokens: 4096,
  );

  static const llama31_8b = NvidiaModel(
    id: 'meta/llama-3.1-8b-instruct',
    name: 'Llama 3.1 8B',
    description: 'State-of-the-art 8B model. Fast & reliable.',
    provider: NvidiaModelProvider.nvidia,
    contextLength: 131072,
    maxTokens: 4096,
  );

  static const nemotronSafety = NvidiaModel(
    id: 'nvidia/nemotron-content-safety-reasoning-4b',
    name: 'Nemotron Content Safety 4B',
    description: 'Content safety & dialogue moderation guardrail.',
    provider: NvidiaModelProvider.nvidia,
    contextLength: 4096,
    maxTokens: 256,
  );

  // ── GLM via NVIDIA NIM ────────────────────────────────────────────

  static const glm5 = NvidiaModel(
    id: 'z-ai/glm5',
    name: 'GLM-5',
    description: 'Zhipu GLM-5. Strong multilingual chat & reasoning.',
    provider: NvidiaModelProvider.nvidia,
    contextLength: 131072,
    maxTokens: 4096,
  );

  static const glm51 = NvidiaModel(
    id: 'z-ai/glm5.1',
    name: 'GLM-5.1',
    description: 'GLM-5.1 updated. Strong multilingual & coding.',
    provider: NvidiaModelProvider.nvidia,
    contextLength: 131072,
    maxTokens: 4096,
  );

  // ── Kimi via OpenRouter ───────────────────────────────────────────

  static const kimiK2 = NvidiaModel(
    id: 'moonshotai/kimi-k2',
    name: 'Kimi K2',
    description: 'Moonshot Kimi K2. Strong reasoning & coding (OpenRouter).',
    provider: NvidiaModelProvider.openRouter,
    contextLength: 131072,
    maxTokens: 8192,
  );

  static const kimiK26Free = NvidiaModel(
    id: 'moonshotai/kimi-k2.6:free',
    name: 'Kimi K2.6 (Free)',
    description: 'Kimi K2.6 free tier on OpenRouter.',
    provider: NvidiaModelProvider.openRouter,
    contextLength: 65536,
    maxTokens: 4096,
  );

  /// All available models for the Programmer role.
  static const List<NvidiaModel> programmerModels = [
    deepseekV4Flash,
    nemotron3Ultra,
    nemotron3Super,
    nemotronSuper49B,
    llama33_70b,
    glm5,
    glm51,
    kimiK2,
    kimiK26Free,
    nemotron3Nano,
  ];

  /// Vision-capable models for General Chat.
  static const List<NvidiaModel> visionModels = [
    llama32Vision,
    llama33_70b,
    nemotron3Super,
    nemotron3Ultra,
    deepseekV4Flash,
  ];

  /// Content safety models.
  static const List<NvidiaModel> safetyModels = [
    nemotronSafety,
  ];
}
