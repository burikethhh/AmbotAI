# Ambot AI Desktop — Agentic Rebuild Plan

## Vision

Transform Ambot AI Desktop from a mobile-adapted chat UI into a **desktop-native agentic workspace** — a control surface for AI agents, not a conversation partner. Think Cursor 3's Agents Window meets VS Code's Copilot Chat meets OpenCode's terminal-first architecture, all powered by local offline AI.

---

## Part 1: Architecture — Agentic Desktop Layout

### Current State (Mobile-Adapted)
```
┌─────────────────────────────────────────────┐
│ Custom Title Bar                            │
├──────┬──────────────────────────────────────┤
│      │                                      │
│ Side │        Content Area                  │
│ bar  │     (single screen at a time)        │
│      │                                      │
│      │                                      │
├──────┴──────────────────────────────────────┤
│ Status Bar                                 │
└─────────────────────────────────────────────┘
```

### Target State (Agentic Desktop)
```
┌──────────────────────────────────────────────────────────────────────┐
│ Title Bar: App | Session: [v] | Agent: [Build v] | Model: [v] │ ⚙ │
├──────┬───────────────────────────────┬───────────────────────────────┤
│      │                               │                               │
│      │     AGENT CONVERSATION        │     CONTEXT PANEL             │
│  S   │                               │                               │
│  I   │  [User message]               │  📄 Files in Context          │
│  D   │  [Agent: tool call → read]    │  ├── main.dart                │
│  E   │  [Tool: file contents]        │  └── config.yaml              │
│  B   │  [Agent: tool call → edit]    │                               │
│  A   │  [Tool: diff applied]         │  🔧 Agent Logs                │
│  R   │  [Agent: summary]             │  ├── 14:32 Read main.dart     │
│      │                               │  ├── 14:32 Edit config.yaml   │
│      │  ┌─────────────────────────┐  │  └── 14:33 Build complete     │
│      │  │ Message input...    [⏎] │  │                               │
│      │  │ @file  #folder  !shell   │  │ 📊 Token Usage                │
│      │  └─────────────────────────┘  │  Input: 2,340  Output: 890    │
├──────┴───────────────────────────────┴───────────────────────────────┤
│ ● Connected to local AI │ GPU: RTX 4060 │ 8B Q4_K_M │ 23 tok/s    │
└──────────────────────────────────────────────────────────────────────┘
```

### Panel System

| Panel | Purpose | Position |
|-------|---------|----------|
| **Sidebar** | Sessions, navigation, model selector | Left (collapsible) |
| **Agent Chat** | Conversation with tool calls, diffs, results | Center |
| **Context Panel** | Files, logs, token usage, agent state | Right (collapsible) |
| **Terminal** | Shell output, build logs, agent commands | Bottom (tabbed) |
| **Status Bar** | Engine status, model, GPU, tokens/sec | Bottom |

### Key Layout Features

1. **Resizable panels** — Drag dividers to resize any panel
2. **Collapsible panels** — Sidebar and context panel can hide
3. **Multi-tab sessions** — Multiple agent conversations in tabs
4. **Split view** — Side-by-side agent sessions
5. **Focus mode** — Hide everything except the current conversation
6. **Panel persistence** — Layout saved across restarts

---

## Part 2: Agent System Design

### Agent Types

| Agent | Role | Tools | Autonomy |
|-------|------|-------|----------|
| **Build** | Full development agent | read, write, edit, shell, search, web | Execute (with gates) |
| **Plan** | Read-only analysis | read, search, web | Suggest only |
| **Refactor** | Code improvement | read, edit, search | Draft (propose changes) |
| **Debug** | Error investigation | read, shell, web | Suggest → Draft |
| **Document** | Documentation gen | read, write, edit | Draft |

### Tool System

```dart
abstract class AgentTool {
  String get id;
  String get name;
  String get description;
  Map<String, dynamic> get schema; // JSON Schema for parameters
  
  // Permission level required
  PermissionLevel get permissionLevel;
  
  // Execute the tool
  Future<ToolResult> execute(Map<String, dynamic> params, ToolContext context);
}

class ToolResult {
  final String title;
  final String output;
  final bool success;
  final List<ToolAttachment>? attachments;
  final Map<String, dynamic>? metadata;
}

// Permission levels
enum PermissionLevel {
  read,      // Always allowed
  write,     // Ask once per session
  execute,   // Ask every time
  destructive, // Ask with confirmation
}
```

### Tool Catalog

| Tool | Category | Permission | Description |
|------|----------|------------|-------------|
| `read_file` | File | Read | Read file contents |
| `write_file` | File | Write | Create/overwrite file |
| `edit_file` | File | Write | Apply targeted edits |
| `list_files` | File | Read | List directory contents |
| `search_code` | Search | Read | Regex/grep search |
| `search_semantic` | Search | Read | Semantic code search |
| `run_shell` | Execution | Execute | Run shell commands |
| `web_fetch` | Web | Read | Fetch URL content |
| `web_search` | Web | Read | Search the web |
| `memory_add` | Memory | Write | Store information |
| `memory_search` | Memory | Read | Retrieve information |

### Permission Flow

```
User sends message
    ↓
Agent plans actions
    ↓
For each tool call:
    ├── Permission level?
    │   ├── Read → Execute automatically
    │   ├── Write → Check session permission
    │   │   ├── Already granted → Execute
    │   │   └── Not yet → Show inline approval
    │   ├── Execute → Show inline approval every time
    │   └── Destructive → Show confirmation modal
    └── Execute tool → Show result inline
```

---

## Part 3: Local Offline AI Integration

### Inference Engine: llama.cpp via llamadart

The project already uses `llamadart` (Dart bindings for llama.cpp). We'll enhance this with:

### Hardware Detection System

```dart
class HardwareProfile {
  // Detected specs
  final String os;              // windows, macos, linux
  final String cpuModel;        // Intel i7-13700K, Apple M3 Max
  final int cpuCores;           // Physical cores
  final bool hasAvx2;
  final bool hasAvx512;
  
  // Memory
  final int totalRamMB;
  final int availableRamMB;
  
  // GPU
  final GpuInfo? primaryGpu;
  final List<GpuInfo> allGpus;
  
  // Computed
  final RunMode recommendedRunMode;  // GPU, CPU+GPU, CPU
  final int recommendedGpuLayers;
}

class GpuInfo {
  final String name;            // NVIDIA RTX 4060
  final String vendor;          // nvidia, amd, intel, apple
  final int vramMB;
  final int availableVramMB;
  final String driverVersion;
  final bool supportsCUDA;
  final bool supportsVulkan;
  final bool supportsMetal;
}
```

### Hardware Detection Methods

| Platform | GPU Detection | RAM Detection |
|----------|--------------|---------------|
| **Windows** | `nvidia-smi` (NVIDIA), WMI (all) | `wmic OS get TotalVisibleMemorySize` |
| **macOS** | `system_profiler SPDisplaysDataType` | `sysctl hw.memsize` |
| **Linux** | `nvidia-smi`, `rocm-smi`, `lspci` | `/proc/meminfo` |

### Model Recommendation Engine

```dart
class ModelRecommender {
  ModelRecommendation recommend(HardwareProfile hw) {
    final availableMemory = hw.primaryGpu != null
        ? hw.primaryGpu!.availableVramMB
        : hw.availableRamMB;
    
    // Decision tree
    if (availableMemory >= 40000) {
      return ModelRecommendation(
        model: 'llama-3-70b',
        quantization: 'Q4_K_M',
        runMode: RunMode.gpu,
        expectedTokensPerSec: 30,
        reasoning: 'Sufficient VRAM for 70B model',
      );
    } else if (availableMemory >= 16000) {
      return ModelRecommendation(
        model: 'llama-3-8b',
        quantization: 'Q5_K_M',
        runMode: RunMode.gpu,
        expectedTokensPerSec: 35,
        reasoning: 'Good GPU, recommended quantization',
      );
    } else if (availableMemory >= 8000) {
      return ModelRecommendation(
        model: 'llama-3-8b',
        quantization: 'Q4_K_M',
        runMode: RunMode.gpu,
        expectedTokensPerSec: 25,
        reasoning: 'Standard setup, 4-bit quantization',
      );
    } else if (availableMemory >= 4000) {
      return ModelRecommendation(
        model: 'qwen2.5-1.5b',
        quantization: 'Q4_K_M',
        runMode: RunMode.cpu,
        expectedTokensPerSec: 30,
        reasoning: 'Limited memory, small model',
      );
    } else {
      return ModelRecommendation(
        model: 'tinyllama-1.1b',
        quantization: 'Q3_K_M',
        runMode: RunMode.cpu,
        expectedTokensPerSec: 40,
        reasoning: 'Very limited memory, minimal model',
      );
    }
  }
}
```

### Model Catalog

```yaml
models:
  - id: tinyllama-1.1b
    name: TinyLlama 1.1B
    params: 1_100_000_000
    minRam: 2048
    quantizations: [Q3_K_M, Q4_K_M, Q5_K_M]
    use_case: Quick responses, low-resource devices
    
  - id: qwen2.5-1.5b
    name: Qwen 2.5 1.5B
    params: 1_500_000_000
    minRam: 3072
    quantizations: [Q4_K_M, Q5_K_M, Q6_K]
    use_case: General chat, coding (small)
    
  - id: phi-3-mini
    name: Phi-3 Mini 3.8B
    params: 3_800_000_000
    minRam: 4096
    quantizations: [Q4_K_M, Q5_K_M, Q6_K]
    use_case: Coding, reasoning (compact)
    
  - id: llama-3.2-3b
    name: Llama 3.2 3B
    params: 3_000_000_000
    minRam: 4096
    quantizations: [Q4_K_M, Q5_K_M, Q6_K, Q8_0]
    use_case: General purpose, fast
    
  - id: mistral-7b
    name: Mistral 7B
    params: 7_000_000_000
    minRam: 6144
    quantizations: [Q4_K_M, Q5_K_M, Q6_K, Q8_0]
    use_case: Coding, instruction following
    
  - id: llama-3-8b
    name: Llama 3 8B
    params: 8_000_000_000
    minRam: 8192
    quantizations: [Q4_K_M, Q5_K_M, Q6_K, Q8_0]
    use_case: Best quality/size ratio
    
  - id: qwen3-8b
    name: Qwen 3 8B
    params: 8_000_000_000
    minRam: 8192
    quantizations: [Q4_K_M, Q5_K_M, Q6_K, Q8_0]
    use_case: Coding, multilingual
    
  - id: llama-3-70b
    name: Llama 3 70B
    params: 70_000_000_000
    minRam: 40000
    quantizations: [Q4_K_M, Q5_K_M]
    use_case: Frontier quality, requires large GPU/RAM
```

### Model Download & Storage

```
%APPDATA%\AmbotAI\models\
├── llama-3-8b-q4_k_m.gguf          (~4.9 GB)
├── llama-3-8b-q4_k_m.meta.json     (size, hash, recommendations)
├── qwen2.5-1.5b-q4_k_m.gguf       (~1.0 GB)
└── model-cache.json                 (downloaded models index)
```

### Download Flow

```
1. App launches → Hardware detected
2. Recommendation shown in UI
3. User clicks "Download" or "Use Recommended"
4. Download from HuggingFace CDN with progress
5. Verify SHA256 hash
6. Store in models directory
7. Load via llamadart
8. Ready for inference
```

---

## Part 4: UI Component Architecture

### Component Hierarchy

```
DesktopApp
├── TitleBar
│   ├── AppMenu (File, Edit, View, Help)
│   ├── SessionSelector (dropdown)
│   ├── AgentSelector (Build/Plan/Refactor)
│   ├── ModelSelector (dropdown with status)
│   └── WindowControls
├── MainLayout (resizable panels)
│   ├── SidePanel (collapsible)
│   │   ├── SessionList
│   │   ├── ModelManager
│   │   └── Settings
│   ├── CenterPanel
│   │   ├── TabBar (multiple sessions)
│   │   ├── AgentConversation
│   │   │   ├── MessageBubble
│   │   │   │   ├── UserMessage
│   │   │   │   ├── AgentMessage
│   │   │   │   │   ├── TextBlock
│   │   │   │   │   ├── CodeBlock (with syntax highlighting)
│   │   │   │   │   ├── DiffBlock (inline diffs)
│   │   │   │   │   └── ToolCallBlock
│   │   │   │   │       ├── ToolHeader (name, status)
│   │   │   │   │       ├── ToolParams (collapsible)
│   │   │   │   │       └── ToolResult (collapsible)
│   │   │   │   └── ToolApprovalBlock
│   │   │   └── InputArea
│   │   │       ├── MentionsBar (@files, #folders)
│   │   │       ├── TextField (multiline)
│   │   │       └── ActionBar (send, model picker, permissions)
│   │   └── BottomTerminal (tabbed)
│   │       ├── ShellTab
│   │       ├── AgentLogsTab
│   │       └── BuildOutputTab
│   └── RightPanel (collapsible)
│       ├── FileContextList
│       ├── AgentStateDisplay
│       └── TokenUsageDisplay
└── StatusBar
    ├── EngineStatus
    ├── GPUInfo
    ├── ModelInfo
    └── PerformanceMetrics
```

### New Widget Library

```
lib/features/desktop/
├── layout/
│   ├── resizable_panel.dart
│   ├── panel_manager.dart
│   ├── tab_bar.dart
│   └── focus_mode.dart
├── agent/
│   ├── agent_conversation.dart
│   ├── message_bubble.dart
│   ├── tool_call_block.dart
│   ├── diff_block.dart
│   ├── code_block.dart
│   └── approval_block.dart
├── input/
│   ├── agent_input.dart
│   ├── mentions_bar.dart
│   └── permission_picker.dart
├── panels/
│   ├── context_panel.dart
│   ├── file_explorer.dart
│   ├── agent_logs.dart
│   └── token_usage.dart
├── terminal/
│   ├── terminal_panel.dart
│   └── terminal_tab.dart
├── model_manager/
│   ├── model_browser.dart
│   ├── hardware_detector.dart
│   ├── model_recommender.dart
│   └── download_manager.dart
└── settings/
    ├── desktop_settings.dart
    └── agent_settings.dart
```

---

## Part 5: Implementation Phases

### Phase 1: Foundation (Week 1-2)
- [ ] Resizable panel system
- [ ] Tab bar for multi-session
- [ ] Updated title bar with agent/model selectors
- [ ] Status bar with GPU info
- [ ] Hardware detection system

### Phase 2: Agent System (Week 3-4)
- [ ] AgentTool abstract class
- [ ] Tool registry and execution engine
- [ ] Permission system
- [ ] Tool call rendering (collapsible blocks)
- [ ] Inline diff viewer
- [ ] Agent conversation UI

### Phase 3: Local AI (Week 5-6)
- [ ] Enhanced llamadart integration
- [ ] Model download manager with progress
- [ ] Model recommendation engine
- [ ] Model hot-swapping
- [ ] Performance monitoring (tok/s, VRAM usage)

### Phase 4: Input System (Week 7)
- [ ] @mention file picker
- [ ] #folder reference
- [ ] !shell command prefix
- [ ] /command system
- [ ] Autocomplete for mentions

### Phase 5: Terminal Integration (Week 8)
- [ ] Embedded terminal panel
- [ ] Shell output in agent conversation
- [ ] Build output streaming
- [ ] Agent log viewer

### Phase 6: Polish (Week 9-10)
- [ ] Keyboard shortcuts (all actions)
- [ ] Layout persistence
- [ ] Focus mode
- [ ] Multi-window support
- [ ] Theme refinement
- [ ] Performance optimization

---

## Part 6: Technical Decisions

### Why Not Switch from Flutter?
- Already have 331 tests, full mobile app, 1.6.6 release
- Flutter desktop is mature (Windows, macOS, Linux)
- llamadart already provides llama.cpp bindings
- Riverpod state management works well
- Only need to rebuild the UI layer, not the core

### Key Dependencies to Add
| Package | Purpose |
|---------|---------|
| `flutter_terminal` or custom | Embedded terminal |
| `flutter_highlight` or `flutter_markdown` | Syntax highlighting |
| `diff` | Inline diff rendering |
| `file_picker` (already have) | File context selection |
| `process_runner` | Shell command execution |

### What to Keep from Current Desktop
- `core/` layer (AI engines, memory, RAG, document gen)
- `PlatformGuard` utility
- `DesktopWindowManager`
- `DesktopKeyboardHandler`
- Null engines for mobile-only features
- All 331 tests

### What to Replace
- `DesktopHomeScreen` → `DesktopWorkspace` (panel-based)
- `DesktopChatScreen` → `AgentConversation` (tool-aware)
- `DesktopContextMenu` → Integrated in agent tools
- `DesktopToast` → Keep but enhance
- `DesktopCommandPalette` → Enhance with agent commands
- Sidebar → Multi-purpose side panel

---

## Summary

This plan transforms Ambot AI Desktop from a **chat app on desktop** into an **agentic AI workspace** that:

1. **Feels native** — Resizable panels, keyboard-first, multi-tab
2. **Shows agent work** — Every tool call, diff, and result visible
3. **Runs locally** — Hardware-aware model selection, local inference
4. **Gives control** — Permission levels, approval gates, undo
5. **Scales** — From 1B models on laptops to 70B on workstations

The core AI layer stays intact. We're rebuilding the UI to be worthy of the engine underneath.
