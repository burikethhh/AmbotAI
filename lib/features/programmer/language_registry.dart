import 'package:flutter/material.dart';

enum PreviewType { web, terminal, file, none }

class LanguageConfig {
  final String id;
  final String name;
  final String defaultFilename;
  final String highlightLang;
  final Color tabColor;
  final Color tabTextColor;
  final IconData fileIcon;
  final PreviewType previewType;
  final String? defaultContent;
  final List<String> extensions;
  final String? fileComment;

  const LanguageConfig({
    required this.id,
    required this.name,
    required this.defaultFilename,
    required this.highlightLang,
    required this.tabColor,
    required this.tabTextColor,
    required this.fileIcon,
    this.previewType = PreviewType.none,
    this.defaultContent,
    this.extensions = const [],
    this.fileComment,
  });
}

class LanguageRegistry {
  LanguageRegistry._();

  static final List<LanguageConfig> all = [
    // ─── Web ───────────────────────────────────────────────
    const LanguageConfig(
      id: 'html',
      name: 'HTML',
      defaultFilename: 'index.html',
      highlightLang: 'xml',
      tabColor: Color(0xFFE44D26),
      tabTextColor: Colors.white,
      fileIcon: Icons.code,
      previewType: PreviewType.web,
      extensions: ['.html', '.htm'],
      fileComment: '//',
      defaultContent: '<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width, initial-scale=1.0">\n  <title>Document</title>\n</head>\n<body>\n  \n</body>\n</html>',
    ),
    const LanguageConfig(
      id: 'css',
      name: 'CSS',
      defaultFilename: 'style.css',
      highlightLang: 'css',
      tabColor: Color(0xFF1572B6),
      tabTextColor: Colors.white,
      fileIcon: Icons.palette_outlined,
      previewType: PreviewType.web,
      extensions: ['.css'],
      fileComment: '/*',
      defaultContent: '* {\n  margin: 0;\n  padding: 0;\n  box-sizing: border-box;\n}\n\nbody {\n  font-family: system-ui, sans-serif;\n  line-height: 1.6;\n  color: #333;\n}',
    ),
    const LanguageConfig(
      id: 'javascript',
      name: 'JavaScript',
      defaultFilename: 'script.js',
      highlightLang: 'javascript',
      tabColor: Color(0xFFF7DF1E),
      tabTextColor: Color(0xFF333333),
      fileIcon: Icons.javascript,
      previewType: PreviewType.web,
      extensions: ['.js', '.mjs', '.jsx'],
      fileComment: '//',
      defaultContent: 'console.log("Hello from Ambot AI!");',
    ),

    // ─── Systems & Compiled ────────────────────────────────
    const LanguageConfig(
      id: 'python',
      name: 'Python',
      defaultFilename: 'main.py',
      highlightLang: 'python',
      tabColor: Color(0xFF3776AB),
      tabTextColor: Colors.white,
      fileIcon: Icons.code,
      previewType: PreviewType.terminal,
      extensions: ['.py', '.pyw'],
      fileComment: '#',
      defaultContent: '#!/usr/bin/env python3\n"""Main script."""\n\ndef main():\n    print("Hello from Ambot AI!")\n\nif __name__ == "__main__":\n    main()',
    ),
    const LanguageConfig(
      id: 'typescript',
      name: 'TypeScript',
      defaultFilename: 'main.ts',
      highlightLang: 'typescript',
      tabColor: Color(0xFF3178C6),
      tabTextColor: Colors.white,
      fileIcon: Icons.code,
      previewType: PreviewType.terminal,
      extensions: ['.ts', '.tsx'],
      fileComment: '//',
      defaultContent: 'interface Config {\n  name: string;\n  version: string;\n}\n\nconst config: Config = {\n  name: "ambot",\n  version: "1.0.0",\n};\n\nconsole.log(config);',
    ),
    const LanguageConfig(
      id: 'java',
      name: 'Java',
      defaultFilename: 'Main.java',
      highlightLang: 'java',
      tabColor: Color(0xFFED8B00),
      tabTextColor: Colors.white,
      fileIcon: Icons.code,
      previewType: PreviewType.terminal,
      extensions: ['.java'],
      fileComment: '//',
      defaultContent: 'public class Main {\n    public static void main(String[] args) {\n        System.out.println("Hello from Ambot AI!");\n    }\n}',
    ),
    const LanguageConfig(
      id: 'csharp',
      name: 'C#',
      defaultFilename: 'Program.cs',
      highlightLang: 'csharp',
      tabColor: Color(0xFF68217A),
      tabTextColor: Colors.white,
      fileIcon: Icons.code,
      previewType: PreviewType.terminal,
      extensions: ['.cs'],
      fileComment: '//',
      defaultContent: 'using System;\n\nclass Program\n{\n    static void Main()\n    {\n        Console.WriteLine("Hello from Ambot AI!");\n    }\n}',
    ),
    const LanguageConfig(
      id: 'cpp',
      name: 'C++',
      defaultFilename: 'main.cpp',
      highlightLang: 'cpp',
      tabColor: Color(0xFF00599C),
      tabTextColor: Colors.white,
      fileIcon: Icons.code,
      previewType: PreviewType.terminal,
      extensions: ['.cpp', '.cc', '.cxx', '.hpp'],
      fileComment: '//',
      defaultContent: '#include <iostream>\n\nint main() {\n    std::cout << "Hello from Ambot AI!" << std::endl;\n    return 0;\n}',
    ),
    const LanguageConfig(
      id: 'c',
      name: 'C',
      defaultFilename: 'main.c',
      highlightLang: 'c',
      tabColor: Color(0xFFA8B9CC),
      tabTextColor: Color(0xFF333333),
      fileIcon: Icons.code,
      previewType: PreviewType.terminal,
      extensions: ['.c', '.h'],
      fileComment: '//',
      defaultContent: '#include <stdio.h>\n\nint main() {\n    printf("Hello from Ambot AI!\\n");\n    return 0;\n}',
    ),
    const LanguageConfig(
      id: 'go',
      name: 'Go',
      defaultFilename: 'main.go',
      highlightLang: 'go',
      tabColor: Color(0xFF00ADD8),
      tabTextColor: Colors.white,
      fileIcon: Icons.code,
      previewType: PreviewType.terminal,
      extensions: ['.go'],
      fileComment: '//',
      defaultContent: 'package main\n\nimport "fmt"\n\nfunc main() {\n    fmt.Println("Hello from Ambot AI!")\n}',
    ),
    const LanguageConfig(
      id: 'rust',
      name: 'Rust',
      defaultFilename: 'main.rs',
      highlightLang: 'rust',
      tabColor: Color(0xFFCE422B),
      tabTextColor: Colors.white,
      fileIcon: Icons.code,
      previewType: PreviewType.terminal,
      extensions: ['.rs'],
      fileComment: '//',
      defaultContent: 'fn main() {\n    println!("Hello from Ambot AI!");\n}',
    ),
    const LanguageConfig(
      id: 'ruby',
      name: 'Ruby',
      defaultFilename: 'main.rb',
      highlightLang: 'ruby',
      tabColor: Color(0xFFCC342D),
      tabTextColor: Colors.white,
      fileIcon: Icons.code,
      previewType: PreviewType.terminal,
      extensions: ['.rb'],
      fileComment: '#',
      defaultContent: '#!/usr/bin/env ruby\n# Main script\n\ndef main\n  puts "Hello from Ambot AI!"\nend\n\nmain',
    ),
    const LanguageConfig(
      id: 'php',
      name: 'PHP',
      defaultFilename: 'index.php',
      highlightLang: 'php',
      tabColor: Color(0xFF777BB4),
      tabTextColor: Colors.white,
      fileIcon: Icons.code,
      previewType: PreviewType.terminal,
      extensions: ['.php'],
      fileComment: '//',
      defaultContent: '<?php\n/**\n * Main script.\n */\n\necho "Hello from Ambot AI!";\n',
    ),
    const LanguageConfig(
      id: 'swift',
      name: 'Swift',
      defaultFilename: 'main.swift',
      highlightLang: 'swift',
      tabColor: Color(0xFFF05138),
      tabTextColor: Colors.white,
      fileIcon: Icons.code,
      previewType: PreviewType.terminal,
      extensions: ['.swift'],
      fileComment: '//',
      defaultContent: 'import Foundation\n\nprint("Hello from Ambot AI!")',
    ),
    const LanguageConfig(
      id: 'kotlin',
      name: 'Kotlin',
      defaultFilename: 'Main.kt',
      highlightLang: 'kotlin',
      tabColor: Color(0xFF7F52FF),
      tabTextColor: Colors.white,
      fileIcon: Icons.code,
      previewType: PreviewType.terminal,
      extensions: ['.kt', '.kts'],
      fileComment: '//',
      defaultContent: 'fun main() {\n    println("Hello from Ambot AI!")\n}',
    ),

    // ─── Scripting & Markup ────────────────────────────────
    const LanguageConfig(
      id: 'shell',
      name: 'Shell',
      defaultFilename: 'script.sh',
      highlightLang: 'bash',
      tabColor: Color(0xFF4EAA25),
      tabTextColor: Colors.white,
      fileIcon: Icons.terminal,
      previewType: PreviewType.terminal,
      extensions: ['.sh', '.bash', '.zsh'],
      fileComment: '#',
      defaultContent: '#!/bin/bash\n\necho "Hello from Ambot AI!"',
    ),
    const LanguageConfig(
      id: 'sql',
      name: 'SQL',
      defaultFilename: 'query.sql',
      highlightLang: 'sql',
      tabColor: Color(0xFF336791),
      tabTextColor: Colors.white,
      fileIcon: Icons.storage_outlined,
      previewType: PreviewType.none,
      extensions: ['.sql'],
      fileComment: '--',
      defaultContent: '-- Query\nSELECT * FROM users\nWHERE active = 1\nORDER BY created_at DESC\nLIMIT 10;',
    ),
    const LanguageConfig(
      id: 'json',
      name: 'JSON',
      defaultFilename: 'data.json',
      highlightLang: 'json',
      tabColor: Color(0xFF5B5B5B),
      tabTextColor: Colors.white,
      fileIcon: Icons.data_object,
      previewType: PreviewType.none,
      extensions: ['.json'],
      defaultContent: '{\n  "name": "ambot",\n  "version": "1.0.0",\n  "description": "AI Desktop Assistant"\n}',
    ),
    const LanguageConfig(
      id: 'yaml',
      name: 'YAML',
      defaultFilename: 'config.yaml',
      highlightLang: 'yaml',
      tabColor: Color(0xFFCB171E),
      tabTextColor: Colors.white,
      fileIcon: Icons.data_object,
      previewType: PreviewType.none,
      extensions: ['.yaml', '.yml'],
      fileComment: '#',
      defaultContent: 'name: ambot\nversion: 1.0.0\nsettings:\n  theme: dark\n  language: en',
    ),
    const LanguageConfig(
      id: 'markdown',
      name: 'Markdown',
      defaultFilename: 'README.md',
      highlightLang: 'markdown',
      tabColor: Color(0xFF555555),
      tabTextColor: Colors.white,
      fileIcon: Icons.description_outlined,
      previewType: PreviewType.none,
      extensions: ['.md', '.markdown'],
      defaultContent: '# Hello World\n\nThis is a **markdown** document.\n\n## Features\n- Feature 1\n- Feature 2\n',
    ),
    const LanguageConfig(
      id: 'xml',
      name: 'XML',
      defaultFilename: 'data.xml',
      highlightLang: 'xml',
      tabColor: Color(0xFF0060AC),
      tabTextColor: Colors.white,
      fileIcon: Icons.code,
      previewType: PreviewType.none,
      extensions: ['.xml'],
      defaultContent: '<?xml version="1.0" encoding="UTF-8"?>\n<root>\n  <item>\n    <name>Ambot</name>\n  </item>\n</root>',
    ),
    const LanguageConfig(
      id: 'toml',
      name: 'TOML',
      defaultFilename: 'config.toml',
      highlightLang: 'ini',
      tabColor: Color(0xFF9C4221),
      tabTextColor: Colors.white,
      fileIcon: Icons.data_object,
      previewType: PreviewType.none,
      extensions: ['.toml'],
      defaultContent: '[app]\nname = "ambot"\nversion = "1.0.0"\n\n[settings]\ntheme = "dark"',
    ),

    // ─── Data Science ──────────────────────────────────────
    const LanguageConfig(
      id: 'r',
      name: 'R',
      defaultFilename: 'analysis.R',
      highlightLang: 'r',
      tabColor: Color(0xFF276DC3),
      tabTextColor: Colors.white,
      fileIcon: Icons.code,
      previewType: PreviewType.terminal,
      extensions: ['.R', '.r'],
      fileComment: '#',
      defaultContent: '# Analysis script\ncat("Hello from Ambot AI!\\n")',
    ),
    const LanguageConfig(
      id: 'matlab',
      name: 'MATLAB',
      defaultFilename: 'script.m',
      highlightLang: 'matlab',
      tabColor: Color(0xFFFF8C00),
      tabTextColor: Colors.white,
      fileIcon: Icons.code,
      previewType: PreviewType.terminal,
      extensions: ['.m'],
      fileComment: '%',
      defaultContent: '% MATLAB script\ndisp("Hello from Ambot AI!")',
    ),
  ];

  static final Map<String, LanguageConfig> _byId = {
    for (final lang in all) lang.id: lang,
  };

  static final Map<String, LanguageConfig> _byExt = {
    for (final lang in all)
      for (final ext in lang.extensions) ext: lang,
  };

  static LanguageConfig? findById(String id) => _byId[id];

  static LanguageConfig? findByFilename(String filename) {
    final ext = _extensionOf(filename);
    return _byExt[ext];
  }

  static LanguageConfig? findByExtension(String ext) => _byExt[ext];

  static LanguageConfig fallback() => _byId['html']!;

  static String _extensionOf(String filename) {
    final dot = filename.lastIndexOf('.');
    return dot == -1 ? '' : filename.substring(dot).toLowerCase();
  }

  static String languageNameFromHighlight(String highlightLang) {
    for (final lang in all) {
      if (lang.highlightLang == highlightLang) return lang.name;
    }
    return highlightLang.toUpperCase();
  }

  static List<LanguageConfig> get webLanguages =>
      all.where((l) => l.previewType == PreviewType.web).toList();

  static List<LanguageConfig> get terminalLanguages =>
      all.where((l) => l.previewType == PreviewType.terminal).toList();
}
