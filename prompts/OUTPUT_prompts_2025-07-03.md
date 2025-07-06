## `GIT_LOG_PATCH.LOG`
```
commit b900bd475265527ec118c5210c746ce707b2fe8c
Author: dev <dev@dev.openbsd.amsterdam>
Date:   Mon May 5 03:26:29 2025 +0200

    TMP

diff --git a/master.json b/master.json
index ed96d66..799ec89 100644
--- a/master.json
+++ b/master.json
@@ -1,7 +1,7 @@
 {
   // Core framework for precise project execution, ensuring functionality preservation.
   "meta": {
-    "by": "Johann @ www.pub.healthcare - Norway America Association",
+    "by": "Johann Tepstad",
     "created": "2025-01-15T00:00:00Z",
     "description": "Scalable framework for completing diverse projects with intuitive LLM interaction",
     "updated": "2025-05-03 08:50:07",

commit cf72ecc006d3cf6aa90585ea9291f8ecf86ea7de
Author: dev <dev@dev.openbsd.amsterdam>
Date:   Sat May 3 19:53:51 2025 +0200

    TMP

diff --git a/master.json b/master.json
index 2cfdb24..ed96d66 100644
--- a/master.json
+++ b/master.json
@@ -1,192 +1,962 @@
 {
-  "name": "Ultimate Prompt Framework",
-  "description": "AI-driven tool for production-ready outputs with minimal prompts and phases.",
-  "version": "11.6.1",
-  "updated_at": "2025-04-21T13:14:00Z",
-  "inputs": ["scripts", "configs", "docs", "images"],
-  "artifacts": ["config", "README.md", "docs/usage.md", "checksums", "image_configs"],
-  "system_message": "Run phases in order, apply rules, search web in Refinement.",
-  "settings": {
-    "max_retries": 3,
-    "timeout": "1800s",
-    "logging": "stderr",
-    "validation": ["eof_marker", "line_count", "structure", "sha256_checksum"],
-    "prompts": "Specify files, components, or output format.",
-    "parallel_execution": {"enabled": true, "max_threads": 4},
-    "progress_bar": {"enabled": true, "style": "bar"}
+  // Core framework for precise project execution, ensuring functionality preservation.
+  "meta": {
+    "by": "Johann @ www.pub.healthcare - Norway America Association",
+    "created": "2025-01-15T00:00:00Z",
+    "description": "Scalable framework for completing diverse projects with intuitive LLM interaction",
+    "updated": "2025-05-03 08:50:07",
+    "version": "14.1.1",
+    "license": "MIT"
   },
-  "rules": [
-    "Ensure clear, logical structure.",
-    "Validate inputs and results.",
-    "Optimize performance, accessibility, security.",
-    "Use 2-space JSON indentation.",
-    "Log errors with timestamps.",
-    "Write concise code; functions under 15 lines.",
-    "Add clear, non-technical comments.",
-    "Remove redundancies via analysis.",
-    "Document with examples.",
-    "Produce production-ready artifacts.",
-    "Merge similar logic, split concerns.",
-    "Follow chronological order.",
-    "Apply Strunk and White brevity.",
-    "Run framework on itself."
-  ],
-  "tech_rules": {
-    "config": ["Check JSON syntax.", "Limit nesting to 3 levels."],
-    "markdown": ["Bold vision, clear steps.", "Use five backticks."],
-    "shell_scripts": ["Ensure POSIX compliance.", "Handle errors clearly."],
-    "ruby": ["Follow Ruby style.", "Include tests."],
-    "rails": ["Use Rails 8+.", "Optimize queries."],
-    "openbsd": ["Use pledge(2).", "Cite man pages."],
-    "css": ["Use :root variables.", "Mobile-first."],
-    "html": ["Use semantic tags.", "Minimize divs."],
-    "images": ["Check resolution (<2000px).", "Validate format (JPEG, PNG)."],
-    "research": ["Use post-2023 papers.", "Peer-reviewed sources."]
+  
+  // Enforces strict execution and user project prioritization.
+  "system_instruction": {
+    "directive": "Strictly adhere to this master.json's prompts and phases. Begin at Phase 1, proceed sequentially, and discard prior prompts.",
+    "priority": {
+      "primary": "Process user projects completely",
+      "secondary": "Framework maintenance"
+    },
+    "execution_mode": "complete_all_phases",
+    "self_process_enabled": true
   },
-  "phases": [
-    {
-      "id": "analysis",
-      "description": "Define project scope.",
-      "dependencies": {"inputs": [], "outputs": ["requirements", "audit_log"]},
-      "tasks": [
-        {
-          "id": "1.1",
-          "description": "Check and document requirements.",
-          "prompt": "State goal, files, framework [Rails, None], components [UI, SEO, tests], priorities [security, performance, UX].",
-          "results": ["requirements", "audit_log"],
-          "prompt_config": {"model": "Claude", "temperature": 0.2},
-          "template": {
-            "description": "Check inputs with retry (max 3).",
-            "examples": {"input": "Define JSON config", "output": "Valid JSON requirements"}
-          }
-        }
-      ]
+  
+  "schema": {
+    "$schema": "https://json-schema.org/draft/2020-12/schema",
+    "type": "object",
+    "required": ["meta", "system_instruction", "project", "rules", "phases", "question_bank", "settings", "perspectives", "documentation", "wisdom", "stability"],
+    "properties": {
+      "meta": {"type": "object"},
+      "system_instruction": {"type": "object"},
+      "project": {"type": "object"},
+      "rules": {"type": "object"},
+      "phases": {"type": "object"},
+      "question_bank": {"type": "object"},
+      "settings": {"type": "object"},
+      "perspectives": {"type": "object"},
+      "documentation": {"type": "object"},
+      "wisdom": {"type": "object"},
+      "stability": {"type": "object"}
+    }
+  },
+  
+  "project": {
+    "name": "Project Completer",
+    "description": "Scalable framework for completing software projects with production-ready outputs",
+    "goals": [
+      "Complete projects efficiently",
+      "Deliver production-ready outputs",
+      "Support modular, reusable components",
+      "Integrate secure, modern technologies"
+    ]
+  },
+  
+  "question_bank": {
+    // Gathers project context for accurate processing.
+    "project_identification": {
+      "prompt": "What is your project's name, purpose, and key features (up to 10)?",
+      "required": true,
+      "purpose": "project_scope",
+      "phase": "preprocess"
     },
-    {
-      "id": "development",
-      "description": "Build artifacts.",
-      "dependencies": {"inputs": ["analysis.requirements"], "outputs": ["code", "artifacts", "image_configs"]},
-      "tasks": [
-        {
-          "id": "2.1",
-          "description": "Build code, artifacts, and image configs.",
-          "results": ["code", "artifacts", "image_configs"],
-          "subtasks": [
-            {
-              "id": "2.1.1",
-              "description": "Style CSS/HTML mobile-first.",
-              "results": ["styled_artifacts"],
-              "prompt_config": {"model": "Grok", "temperature": 0.4, "tools": ["matplotlib", "plotly"]},
-              "template": {
-                "description": "Lint, optimize code.",
-                "examples": {"input": "Style button", "output": ":root { --primary: #007bff; }\nbutton { background: var(--primary); }"}
-              }
-            },
-            {
-              "id": "2.1.2",
-              "description": "Minify assets, optimize queries.",
-              "results": ["optimized_artifacts"],
-              "prompt_config": {"model": "Grok", "temperature": 0.4},
-              "template": {"description": "Lint, optimize code."}
-            },
-            {
-              "id": "2.1.3",
-              "description": "Generate image-processing configs (e.g., postpro.rb recipes).",
-              "results": ["image_configs"],
-              "prompt_config": {"model": "Grok", "temperature": 0.4},
-              "template": {
-                "description": "Generate effect recipes.",
-                "examples": {"input": "Image effects", "output": "{\"effects\": [\"film_grain\", \"neon_glow\"]} "}
-              }
-            },
-            {
-              "id": "2.1.4",
-              "description": "Generate low-res previews for image recipes.",
-              "results": ["image_previews"],
-              "prompt_config": {"model": "Grok", "temperature": 0.4},
-              "template": {
-                "description": "Create preview images.",
-                "examples": {"input": "Preview recipe", "output": "preview_v1.jpg"}
-              }
-            }
-          ],
-          "prompt_config": {"model": "Grok", "temperature": 0.4},
-          "template": {
-            "description": "Build, optimize, checksum.",
-            "examples": {"input": "Generate model", "output": "class User < ApplicationRecord\nend"}
-          }
+    "source_request": {
+      "prompt": "Do you have source code, documentation, or configuration files to share?",
+      "required": false,
+      "purpose": "resource_discovery",
+      "phase": "preprocess"
+    },
+    "tech_stack": {
+      "prompt": "Which technology stack is used (e.g., Rails, Zsh, OpenBSD)?",
+      "required": true,
+      "purpose": "stack_selection",
+      "phase": "preprocess"
+    },
+    "project_structure": {
+      "prompt": "Describe your project's file structure or list key files/directories.",
+      "required": false,
+      "purpose": "structure_discovery",
+      "phase": "preprocess"
+    },
+    "dependencies": {
+      "prompt": "Specify dependency files (e.g., Gemfile, package.json) or key libraries.",
+      "required": false,
+      "purpose": "dependency_discovery",
+      "phase": "preprocess"
+    },
+    "feature_discovery": {
+      "prompt": "Are there any industry standard features you'd like to compare against?",
+      "required": false,
+      "purpose": "standards_comparison",
+      "phase": "analyze"
+    }
+  },
+  
+  "rules": {
+    // Core execution directives.
+    "general": [
+      {
+        "id": "data_integrity",
+        "text": "Preserve data integrity through all operations",
+        "rationale": "Ensures information fidelity and prevents corruption",
+        "actions": [
+          "Prohibit truncation of user input",
+          "Preserve all user data verbatim",
+          "Verify input/output checksums",
+          "Halt on truncation with rollback"
+        ],
+        "validation": ["Use exact string matching", "Generate SHA-256 checksums"]
+      },
+      {
+        "id": "input_validation",
+        "text": "Validate all inputs thoroughly",
+        "rationale": "Prevents errors and ensures clarity",
+        "actions": [
+          "Process line-by-line",
+          "Analyze word-by-word", 
+          "Check syntax against formal grammar",
+          "Flag ambiguities and inconsistencies"
+        ],
+        "validation": ["Compare against schema", "Verify structure"]
+      },
+      {
+        "id": "execution_discipline",
+        "text": "Execute tasks sequentially with verification",
+        "rationale": "Ensures thorough processing and completion",
+        "actions": [
+          "Define task boundaries clearly", 
+          "Execute tasks in defined order", 
+          "Confirm completion before proceeding",
+          "Track progress metrics"
+        ],
+        "validation": ["Verify task completion", "Log execution path"]
+      },
+      {
+        "id": "clear_communication",
+        "text": "Communicate with Strunk & White clarity",
+        "rationale": "Enhances comprehension and reduces ambiguity",
+        "actions": [
+          "Be concise and precise",
+          "Structure content by importance",
+          "Answer all questions explicitly",
+          "Layer information by complexity"
+        ],
+        "validation": ["Readability score check", "Clarity verification"]
+      },
+      {
+        "id": "error_handling",
+        "text": "Handle errors gracefully with recovery strategies",
+        "rationale": "Maintains workflow continuity and improves resilience",
+        "actions": [
+          "Detect anomalies early", 
+          "Apply appropriate fallbacks", 
+          "Log issues comprehensively", 
+          "Resume from checkpoints"
+        ],
+        "strategies": {
+          "overflow": "Compress less important context",
+          "incomplete": "Resume from last valid checkpoint",
+          "ambiguity": "Re-examine requirements",
+          "create": "Isolate and fix components",
+          "verify": "Apply targeted verification"
         },
-        {
-          "id": "2.2",
-          "description": "Check syntax, compliance.",
-          "results": ["check_report", "audit_log"],
-          "prompt_config": {"model": "Claude", "temperature": 0.1},
-          "template": {
-            "description": "Check results with retry.",
-            "examples": {"input": "Check syntax", "output": "Valid syntax report"}
-          }
-        }
+        "validation": ["Verify recovery success", "Ensure data preservation"]
+      },
+      {
+        "id": "context_management",
+        "text": "Maintain context throughout execution",
+        "rationale": "Ensures continuity across interactions and phases",
+        "actions": [
+          "Store key decisions and preferences",
+          "Summarize relevant context efficiently",
+          "Apply context to current processing",
+          "Prioritize critical information"
+        ],
+        "validation": ["Context relevance check", "Information continuity test"]
+      },
+      {
+        "id": "feature_discovery",
+        "text": "Compare against industry standards",
+        "rationale": "Identifies improvement opportunities and gaps",
+        "actions": [
+          "Compare against best practices",
+          "Identify feature gaps",
+          "Create feature comparison matrix",
+          "Recommend enhancements"
+        ],
+        "validation": ["Comprehensive coverage check", "Best practice alignment"]
+      },
+      {
+        "id": "conflict_resolution",
+        "text": "Resolve rule conflicts systematically",
+        "rationale": "Ensures consistent decisions when rules compete",
+        "actions": [
+          "Identify specific rule conflicts",
+          "Apply precedence hierarchy",
+          "Document resolution decisions",
+          "Follow up with clarification if needed"
+        ],
+        "examples": [
+          "When conciseness vs. completeness conflict, prioritize completeness then make concise",
+          "When timeboxing vs. thoroughness conflict, complete critical paths first"
+        ],
+        "validation": ["Decision consistency check", "Hierarchy adherence"]
+      }
+    ],
+    
+    "comments": [
+      {
+        "id": "comment_quality",
+        "text": "Create high-quality, purposeful comments",
+        "rationale": "Enhances understanding without adding noise",
+        "actions": [
+          "Preserve existing comments when modifying code",
+          "Only comment what isn't self-evident from code",
+          "Write with Strunk & White clarity and brevity",
+          "Avoid ASCII art or decorative characters"
+        ],
+        "validation": ["Clarity check", "Redundancy scan"]
+      }
+    ],
+    
+    "tech_stack": {
+      "ruby": [
+        {"id": "frozen_string", "text": "Add `frozen_string_literal: true` to all files", "rationale": "Ensures string immutability"},
+        {"id": "yard_comments", "text": "Use YARD-style comments for complex methods and APIs", "rationale": "Enhances documentation"},
+        {"id": "enumerable", "text": "Use `Enumerable` for collection operations", "rationale": "Encourages functional style"},
+        {"id": "keyword_args", "text": "Use keyword arguments for complex method signatures", "rationale": "Improves clarity"},
+        {"id": "simple_constructs", "text": "Prefer simple multiline constructs over cryptic oneliners", "rationale": "Enhances readability"}
+      ],
+      "rails": {
+        "architecture": [
+          {"id": "mvc_rest", "text": "Follow Rails conventions for MVC and REST", "rationale": "Ensures consistency"},
+          {"id": "concerns", "text": "Use concerns to share behavior between models", "rationale": "Reduces duplication"},
+          {"id": "model_validation", "text": "Validate data at the model level", "rationale": "Ensures data integrity"},
+          {"id": "thin_controllers", "text": "Keep controllers thin, models focused", "rationale": "Improves maintainability"},
+          {"id": "service_objects", "text": "Use service objects for complex operations", "rationale": "Organizes logic"}
+        ],
+        "frontend": [
+          {"id": "hotwire", "text": "Implement Hotwire (Turbo + Stimulus) for SPA-like functionality", "rationale": "Reduces JavaScript complexity"},
+          {"id": "stimulus_reflex", "text": "Use StimulusReflex for reactive server-rendered UI", "rationale": "Enhances interactivity"},
+          {"id": "stimulus_components", "text": "Leverage Stimulus Components for reusable UI patterns", "rationale": "Improves modularity"},
+          {"id": "view_component", "text": "Apply ViewComponent for complex view encapsulation", "rationale": "Simplifies view logic"},
+          {"id": "tag_helpers", "text": "Use Rails tag helpers to simplify views", "rationale": "Reduces boilerplate"}
+        ],
+        "testing": [
+          {"id": "rspec", "text": "Use RSpec for behavior-driven testing", "rationale": "Ensures clear test structure"},
+          {"id": "factory_bot", "text": "Use FactoryBot for test data preparation", "rationale": "Simplifies setup"},
+          {"id": "capybara", "text": "Write system tests with Capybara for UI interaction", "rationale": "Tests real user flows"},
+          {"id": "test_coverage", "text": "Test happy paths and edge cases", "rationale": "Ensures robustness"}
+        ],
+        "performance": [
+          {"id": "n_plus_one", "text": "Prevent N+1 queries with eager loading", "rationale": "Improves performance"},
+          {"id": "caching", "text": "Use Russian Doll and fragment caching for expensive partials", "rationale": "Reduces render time"},
+          {"id": "bullet", "text": "Use Bullet to detect N+1 queries in development", "rationale": "Identifies inefficiencies"}
+        ],
+        "security": [
+          {"id": "csrf_protection", "text": "Ensure CSRF protection is enabled", "rationale": "Prevents unauthorized actions"},
+          {"id": "strong_params", "text": "Use strong parameters consistently", "rationale": "Protects against mass assignment"},
+          {"id": "input_validation", "text": "Validate and sanitize all user inputs", "rationale": "Prevents injection attacks"}
+        ],
+        "database": [
+          {"id": "migrations", "text": "Use migrations for schema changes", "rationale": "Ensures consistent database updates"},
+          {"id": "indexes", "text": "Add indexes for frequently queried fields", "rationale": "Improves query performance"},
+          {"id": "constraints", "text": "Create database constraints for data integrity", "rationale": "Prevents invalid data"}
+        ]
+      },
+      "openbsd": [
+        {"id": "security_first", "text": "Prioritize security over convenience", "rationale": "Reduces vulnerabilities"},
+        {"id": "least_privilege", "text": "Follow principle of least privilege", "rationale": "Limits exposure"},
+        {"id": "pledge_unveil", "text": "Use `pledge(2)` and `unveil(2)` for capability-based security", "rationale": "Restricts capabilities"},
+        {"id": "man_pages", "text": "Verify configs and daemons at https://man.openbsd.org", "rationale": "Ensures accuracy"},
+        {"id": "daemon_naming", "text": "Cite daemon names by manual page sections (e.g., `nsd(8)`)", "rationale": "Improves clarity"},
+        {"id": "base_system", "text": "Prefer base system tools", "rationale": "Reduces dependencies"},
+        {"id": "use_rcctl", "text": "Use rcctl for services", "rationale": "Standardizes management"}
+      ],
+      "zsh": [
+        {"id": "modern_syntax", "text": "Use modern Zsh syntax (arrays, globbing) with multiline constructs", "rationale": "Improves readability"},
+        {"id": "heredocs", "text": "Embed files with heredocs for clarity", "rationale": "Simplifies scripting"},
+        {"id": "error_handling", "text": "Set error handling with `set -e` and avoid double pipes", "rationale": "Ensures robustness"},
+        {"id": "completions", "text": "Generate Zsh-specific completion scripts", "rationale": "Enhances usability"},
+        {"id": "no_cryptic_oneliner", "text": "Avoid cryptic one-liners", "rationale": "Enhances maintainability"}
+      ],
+      "interface_design": {
+        "html": [
+          {"id": "semantic_html", "text": "Use semantic HTML5 elements (`<article>`, `<section>`, `<nav>`, `<main>`)", "rationale": "Improves accessibility"},
+          {"id": "direct_targeting", "text": "Target elements directly instead of classes/IDs where feasible", "rationale": "Reduces complexity"},
+          {"id": "minimal_divs", "text": "Minimize 'divitis' by using appropriate semantic elements", "rationale": "Simplifies structure"},
+          {"id": "html_entities", "text": "Use HTML entities for special characters (`æ`, `ø`, `å`)", "rationale": "Ensures correct rendering"},
+          {"id": "lang_attributes", "text": "Ensure proper `lang` attributes for multilingual content and hyphenation", "rationale": "Supports accessibility"},
+          {"id": "aria_accessibility", "text": "Ensure ARIA compliance", "rationale": "Enhances usability"}
+        ],
+        "css": [
+          {"id": "root_properties", "text": "Define custom properties in `:root` for colors, typography, spacing, layout", "rationale": "Eases maintenance"},
+          {"id": "modern_selectors", "text": "Apply modern CSS selectors (`:where`, `:is`, `::before`) and logical properties (`margin-block`, `padding-inline`)", "rationale": "Enhances flexibility"},
+          {"id": "flex_grid", "text": "Leverage `flexbox` and `grid` for modern layouts", "rationale": "Simplifies responsive design"},
+          {"id": "css_sections", "text": "Organize CSS into sections: Foundations, Base, Layout, Components", "rationale": "Improves maintainability"},
+          {"id": "units", "text": "Use `rem`/%/unitless for digital media, `pt` for print", "rationale": "Ensures scalability"},
+          {"id": "specificity", "text": "Minimize specificity conflicts with low-specificity selectors", "rationale": "Reduces CSS conflicts"},
+          {"id": "mobile_first", "text": "Design mobile-first", "rationale": "Ensures responsiveness"},
+          {"id": "shallow_nesting", "text": "Avoid deep nesting", "rationale": "Improves readability"},
+          {"id": "max_nesting", "text": "Maximum nesting depth: 2", "rationale": "Forces simplicity"},
+          {"id": "breakpoints", "text": "Use 768px, 1024px, 1440px breakpoints", "rationale": "Standardizes responsive design"},
+          {"id": "contrast_ratio", "text": "Meet AA contrast ratio", "rationale": "Ensures readability"}
+        ],
+        "typography": [
+          {"id": "line_height", "text": "Set `line-height` to 1.2-1.6× font size for body text", "rationale": "Improves readability"},
+          {"id": "line_length", "text": "Aim for 50-75 characters per line", "rationale": "Optimizes legibility"},
+          {"id": "font_kerning", "text": "Enable `font-kerning: normal` for letter-pair spacing", "rationale": "Enhances visual flow"},
+          {"id": "hyphenation", "text": "Use `hyphens: auto` with `lang` attributes for text flow", "rationale": "Prevents awkward breaks"},
+          {"id": "list_spacing", "text": "Set list item spacing to 50-75% of paragraph spacing", "rationale": "Maintains rhythm"},
+          {"id": "paragraph_margins", "text": "Separate paragraphs with 0.5-1.0em vertical margins", "rationale": "Ensures consistent spacing"},
+          {"id": "letter_spacing", "text": "Apply subtle negative `letter-spacing` for body and headings when appropriate", "rationale": "Refines typography"}
+        ],
+        "responsive": [
+          {"id": "mobile_first", "text": "Design with mobile-first approach using `@media (min-width)` queries", "rationale": "Ensures responsiveness"},
+          {"id": "touch_targets", "text": "Ensure touch targets are appropriately sized", "rationale": "Improves mobile usability"},
+          {"id": "print_styles", "text": "Optimize print styles with `@media print`, `pt` units, `page-break-*` controls, and `orphans`/`widows` prevention", "rationale": "Enhances print quality"}
+        ],
+        "accessibility": [
+          {"id": "aria_attributes", "text": "Implement ARIA attributes only when HTML semantics are insufficient", "rationale": "Enhances accessibility"},
+          {"id": "contrast_ratios", "text": "Maintain contrast ratios meeting WCAG 2.1 AA standards", "rationale": "Ensures readability"},
+          {"id": "keyboard_nav", "text": "Ensure keyboard navigation and focus visibility throughout", "rationale": "Supports accessibility"},
+          {"id": "alt_text", "text": "Provide descriptive `alt` text for informational images", "rationale": "Aids screen readers"},
+          {"id": "screen_reader", "text": "Test interfaces with screen readers and keyboard-only navigation", "rationale": "Verifies accessibility"},
+          {"id": "ux_consistency", "text": "Maintain visual consistency and predictable interaction patterns", "rationale": "Reduces cognitive load"}
+        ]
+      },
+      "javascript": [
+        {"id": "modern_syntax", "text": "Use modern JS", "rationale": "Enhances clarity"},
+        {"id": "validate_inputs", "text": "Validate inputs", "rationale": "Prevents attacks"},
+        {"id": "module_based", "text": "Use module pattern", "rationale": "Improves organization"}
+      ],
+      "markdown": [
+        {"id": "code_blocks", "text": "Use five-backtick code blocks for inline Markdown", "rationale": "Prevents display issues"},
+        {"id": "headings", "text": "Use logical heading hierarchy (# for title, ## for sections)", "rationale": "Improves structure"},
+        {"id": "intro_bold", "text": "Bold visionary intro paragraph for key documents", "rationale": "Captures attention"},
+        {"id": "list_steps", "text": "Use numbered lists for steps", "rationale": "Clarifies sequences"}
+      ],
+      "data": {
+        "json": [
+          {"id": "schema_validation", "text": "Validate schema", "rationale": "Ensures integrity"},
+          {"id": "consistent_spacing", "text": "Use consistent spacing", "rationale": "Improves readability"},
+          {"id": "include_schema", "text": "Include schema reference", "rationale": "Enables validation"}
+        ],
+        "yaml": [
+          {"id": "yaml_syntax", "text": "Validate syntax", "rationale": "Prevents errors"},
+          {"id": "indentation", "text": "Ensure consistent indentation", "rationale": "Improves clarity"}
+        ]
+      },
+      "formatting": [
+        {"id": "indent_2", "text": "Use 2-space indentation", "rationale": "Maximizes readability"},
+        {"id": "quotes", "text": "Use double quotes consistently", "rationale": "Ensures standardization"},
+        {"id": "max_line_length", "text": "Limit lines to 80 characters", "rationale": "Prevents line wrapping"},
+        {"id": "comment_logic", "text": "Comment complex logic", "rationale": "Clarifies intent"},
+        {"id": "snake_case", "text": "Use snake_case for variables", "rationale": "Enhances consistency"},
+        {"id": "descriptive_names", "text": "Use descriptive identifiers", "rationale": "Improves understanding"},
+        {"id": "avoid_abbreviations", "text": "Avoid abbreviations", "rationale": "Increases clarity"}
       ]
-    },
-    {
-      "id": "refinement",
-      "description": "Enhance artifacts with feedback, research.",
-      "dependencies": {"inputs": ["development.code", "development.artifacts"], "outputs": ["docs", "feedback", "research_results"]},
-      "tasks": [
-        {
-          "id": "3.1",
-          "description": "Add comments, documentation.",
-          "results": ["docs"],
-          "prompt_config": {"model": "ChatGPT", "temperature": 0.7},
-          "template": {
-            "description": "Generate README.md, usage.md.",
-            "examples": {"input": "Write README", "output": "```python\n# Project\nA simple app.\n```"}
+    }
+  },
+  
+  "phases": {
+    // Defines workflow for sequential execution.
+    "sequence": ["preprocess", "understand", "analyze", "plan", "create", "verify", "deep_execution_trace", "word_by_word_reanalysis", "refine", "deliver", "reflect"],
+    "steps": {
+      "preprocess": {
+        "description": "Prepare environment",
+        "tasks": [
+          {
+            "id": "PREPROCESS_VALIDATE",
+            "instruction": "Validate inputs and document syntax",
+            "check": "Inputs valid",
+            "depends": [],
+            "output": "validation_result",
+            "validation": ["Check syntax against formal grammar", "Validate against schema", "Compare input/output checksums"]
+          },
+          {
+            "id": "PREPROCESS_CONTEXT",
+            "instruction": "Apply prior context",
+            "check": "Context applied",
+            "depends": ["PREPROCESS_VALIDATE"],
+            "output": "context_summary",
+            "validation": ["Store key decisions", "Summarize prior interactions", "Apply context to current processing"]
+          },
+          {
+            "id": "PREPROCESS_CONFIGURE",
+            "instruction": "Detect project type, configure stacks, predict errors",
+            "check": "Stacks configured",
+            "depends": ["PREPROCESS_CONTEXT"],
+            "output": "project_config",
+            "validation": ["Compute SHA-256 checksum", "Log input for traceability"]
           }
-        },
-        {
-          "id": "3.2",
-          "description": "Gather specific feedback.",
-          "prompt": "Rate artifact quality [1-5]; suggest improvements for [code, docs, images].",
-          "results": ["feedback", "audit_log"],
-          "prompt_config": {"model": "ChatGPT", "temperature": 0.7},
-          "template": {"description": "Collect actionable feedback."}
-        },
-        {
-          "id": "3.3",
-          "description": "Research improvements via web.",
-          "prompt": "Scan ar5iv.org for AI image enhancement; suggest effects for postpro.rb.",
-          "results": ["research_results", "audit_log"],
-          "prompt_config": {
-            "model": "Claude",
-            "temperature": 0.7,
-            "web_search": ["ar5iv.org", "scholar.google.com"]
+        ]
+      },
+      "understand": {
+        "description": "Identify project needs",
+        "tasks": [
+          {
+            "id": "UNDERSTAND_NEEDS",
+            "instruction": "List project needs based on goals",
+            "check": "Needs clear",
+            "depends": ["PREPROCESS_CONFIGURE"],
+            "output": "needs_list",
+            "validation": ["Needs linked to goals", "Scope verification"]
           },
-          "template": {
-            "description": "Check research with retry.",
-            "examples": {"input": "Summarize AI papers", "output": "AI upscaling enhances details."}
+          {
+            "id": "UNDERSTAND_INSTRUCTIONS",
+            "instruction": "Write clear instructions with tools",
+            "check": "Instructions clear",
+            "depends": ["UNDERSTAND_NEEDS"],
+            "output": "project_instructions",
+            "validation": ["Ensure input data reflected verbatim", "Instructions tested for clarity"]
+          },
+          {
+            "id": "UNDERSTAND_TOOLSET",
+            "instruction": "Check toolset version and compatibility",
+            "check": "Toolset valid",
+            "depends": ["UNDERSTAND_INSTRUCTIONS"],
+            "output": "toolset_check",
+            "validation": ["Version verification", "Compatibility matrix check"]
+          }
+        ]
+      },
+      "analyze": {
+        "description": "Compare to standards",
+        "tasks": [
+          {
+            "id": "ANALYZE_STANDARDS",
+            "instruction": "Compare to industry standards",
+            "check": "Features matched",
+            "depends": ["UNDERSTAND_TOOLSET"],
+            "output": "standards_comparison",
+            "validation": ["Industry standard alignment", "Best practice verification"]
+          },
+          {
+            "id": "ANALYZE_FEATURES",
+            "instruction": "Discover needed features",
+            "check": "Features identified",
+            "depends": ["ANALYZE_STANDARDS"],
+            "output": "feature_matrix",
+            "validation": ["Ensure comprehensive coverage", "Identify unique selling points", "Prioritize by value"]
+          }
+        ]
+      },
+      "plan": {
+        "description": "Design solution",
+        "tasks": [
+          {
+            "id": "PLAN_ARCHITECTURE",
+            "instruction": "Design architecture",
+            "check": "Structure clear",
+            "depends": ["ANALYZE_FEATURES"],
+            "output": "architecture_design",
+            "validation": ["Architecture principles check", "Modularity verification"]
+          },
+          {
+            "id": "PLAN_COMPONENTS",
+            "instruction": "Define components",
+            "check": "Interfaces defined",
+            "depends": ["PLAN_ARCHITECTURE"],
+            "output": "component_specifications",
+            "validation": ["Interface consistency check", "Dependency mapping"]
+          }
+        ]
+      },
+      "create": {
+        "description": "Build solution",
+        "tasks": [
+          {
+            "id": "CREATE_COMPONENTS",
+            "instruction": "Implement components",
+            "check": "Components built",
+            "depends": ["PLAN_COMPONENTS"],
+            "output": "component_implementations",
+            "validation": ["Component test coverage", "Implementation consistency"]
+          },
+          {
+            "id": "CREATE_INTEGRATION",
+            "instruction": "Integrate components",
+            "check": "Solution cohesive",
+            "depends": ["CREATE_COMPONENTS"],
+            "output": "integrated_solution",
+            "validation": ["Integration test coverage", "End-to-end verification"]
+          }
+        ]
+      },
+      "verify": {
+        "description": "Test solution",
+        "tasks": [
+          {
+            "id": "VERIFY_FUNCTIONALITY",
+            "instruction": "Test functionality",
+            "check": "Features work",
+            "depends": ["CREATE_INTEGRATION"],
+            "output": "test_results",
+            "validation": ["Function test coverage", "Edge case handling"]
+          },
+          {
+            "id": "VERIFY_QUALITY",
+            "instruction": "Check quality",
+            "check": "Standards met",
+            "depends": ["VERIFY_FUNCTIONALITY"],
+            "output": "quality_assessment",
+            "validation": ["Quality metrics check", "Maintainability score"]
+          },
+          {
+            "id": "VERIFY_SECURITY",
+            "instruction": "Audit security",
+            "check": "Vulnerabilities addressed",
+            "depends": ["VERIFY_QUALITY"],
+            "output": "security_assessment",
+            "validation": ["Vulnerability scan", "Attack surface analysis"]
+          },
+          {
+            "id": "VERIFY_ACCESSIBILITY",
+            "instruction": "Check accessibility",
+            "check": "WCAG compliant",
+            "depends": ["VERIFY_SECURITY"],
+            "output": "accessibility_report",
+            "validation": ["WCAG checklist", "Assistive technology test"]
           }
-        }
+        ]
+      },
+      "deep_execution_trace": {
+        "description": "Trace execution to find bugs",
+        "tasks": [
+          {
+            "id": "DEEP_EXECUTION_TRACE",
+            "instruction": "Trace functions and states, simulate edge cases",
+            "check": "Trace complete, bugs listed",
+            "depends": ["VERIFY_ACCESSIBILITY"],
+            "output": "execution_trace",
+            "validation": ["Path coverage analysis", "State transition verification"]
+          }
+        ],
+        "condition": "Complex projects only"
+      },
+      "word_by_word_reanalysis": {
+        "description": "Reanalyze text against documentation",
+        "tasks": [
+          {
+            "id": "WORD_BY_WORD_REANALYSIS",
+            "instruction": "Parse lines and words, cross-reference documentation",
+            "check": "All words validated",
+            "depends": ["DEEP_EXECUTION_TRACE"],
+            "output": "reanalysis_report",
+            "validation": ["Terminology consistency check", "Documentation alignment"]
+          }
+        ],
+        "condition": "Complex projects only"
+      },
+      "refine": {
+        "description": "Optimize solution",
+        "tasks": [
+          {
+            "id": "REFINE_EFFICIENCY",
+            "instruction": "Optimize performance",
+            "check": "Efficiency improved",
+            "depends": ["WORD_BY_WORD_REANALYSIS"],
+            "output": "optimized_solution",
+            "validation": ["Performance metrics comparison", "Resource utilization check"]
+          },
+          {
+            "id": "REFINE_CLARITY",
+            "instruction": "Improve code clarity",
+            "check": "Code simplified",
+            "depends": ["REFINE_EFFICIENCY"],
+            "output": "clarified_solution",
+            "validation": ["Readability metrics", "Complexity reduction"]
+          }
+        ]
+      },
+      "deliver": {
+        "description": "Package outputs",
+        "tasks": [
+          {
+            "id": "DELIVER_DOCUMENTATION",
+            "instruction": "Create documentation",
+            "check": "Documentation clear",
+            "depends": ["REFINE_CLARITY"],
+            "output": "user_documentation",
+            "validation": ["Documentation completeness check", "Clarity verification"]
+          },
+          {
+            "id": "DELIVER_PACKAGE",
+            "instruction": "Package deliverables",
+            "check": "Outputs verified",
+            "depends": ["DELIVER_DOCUMENTATION"],
+            "output": "complete_package",
+            "validation": ["Package integrity verification", "Metadata completeness"]
+          }
+        ]
+      },
+      "reflect": {
+        "description": "Improve process",
+        "tasks": [
+          {
+            "id": "REFLECT_FEEDBACK",
+            "instruction": "Collect feedback",
+            "check": "Insights extracted",
+            "depends": ["DELIVER_PACKAGE"],
+            "output": "feedback_analysis",
+            "validation": ["Feedback comprehensiveness", "Multi-perspective coverage"]
+          },
+          {
+            "id": "REFLECT_IMPROVE",
+            "instruction": "Apply improvements",
+            "check": "Process enhanced",
+            "depends": ["REFLECT_FEEDBACK"],
+            "output": "process_improvements",
+            "validation": ["Improvement measurability", "Implementation feasibility"]
+          },
+          {
+            "id": "REFLECT_CHECKLIST",
+            "instruction": "Complete final checklist",
+            "check": "All items verified",
+            "depends": ["REFLECT_IMPROVE"],
+            "output": "final_validation",
+            "validation": ["Checklist completeness", "Verification documentation"]
+          }
+        ]
+      }
+    }
+  },
+  
+  "settings": {
+    // Configuration parameters for execution.
+    "execution": {
+      "temperature": 0.3,
+      "max_context": 128000,
+      "anti_truncation": true,
+      "time_format": "YYYY-MM-DD HH:MM:SS",
+      "complexity_levels": ["essential", "detailed", "expert"],
+      "default_complexity": "detailed",
+      "timeboxing": {
+        "enabled": true,
+        "estimate_required": true,
+        "approaching_alert": 0.8,
+        "exceeded_alert": true
+      },
+      "error_handling": {
+        "max_retries": 2,
+        "rollback": true,
+        "log_level": "detailed",
+        "retry_reason": "Rephrased inputs improve success rate"
+      },
+      "phase_rollback": {
+        "enabled": true,
+        "trigger_conditions": ["validation_failure", "data_integrity_breach"],
+        "persistence": "store_last_valid_state",
+        "notification": "explicit_failure_reporting"
+      }
+    },
+    "display": {
+      "style": "minimal",
+      "status_format": "**{emoji} {version} > {phase}** {message}",
+      "progress_format": "**{emoji} {version} > PROGRESS** {done}/{total}",
+      "emoji_set": {
+        "analyze": "🔍", "plan": "📝", "create": "🛠️", 
+        "verify": "✅", "refine": "🔧", "deliver": "📦", 
+        "reflect": "💭", "error": "⚠️", "success": "🎯",
+        "feature": "🔆", "context": "🔄", "validation": "🛡️"
+      },
+      "output_style": {
+        "language": "English",
+        "style": "Strunk & White",
+        "clarity": "Concise, active voice, minimal jargon"
+      }
+    },
+    "validation": {
+      "checksum": "sha256",
+      "line_counting": true,
+      "exact_matching": true,
+      "pipeline": ["syntax", "schema", "context", "rule_compliance", "ambiguity_detection"],
+      "enforce_all_rules": true,
+      "compare_with_original": true,
+      "security_scanning": true,
+      "accessibility_level": "WCAG-AA",
+      "content_integrity": {
+        "closing_brackets_check": true,
+        "unclosed_quotes_check": true,
+        "required_sections_check": true
+      },
+      "formats": {
+        "json": {"syntax_check": "json_parser", "schema_validation": "json_schema_validator"},
+        "yaml": {"syntax_check": "yaml_parser", "indentation_check": true},
+        "markdown": {"link_validation": true, "heading_structure": true}
+      },
+      "runtime_type_checking": {
+        "enabled": true,
+        "expected_types": {
+          "project_name": "string",
+          "version": "semver_string",
+          "creation_date": "iso8601_datetime"
+        },
+        "coercion_allowed": false
+      }
+    },
+    "context_management": {
+      "store_key_decisions": true,
+      "retention_duration": "session",
+      "summarization_length": 500,
+      "relevance_threshold": 0.7,
+      "compression": ["hierarchical_summarization", "priority_based_retention"],
+      "storage": {
+        "decisions": true,
+        "preferences": true,
+        "interactions": true
+      }
+    },
+    "feature_discovery": {
+      "enabled": true,
+      "depth": "comprehensive",
+      "sources": ["industry_best_practices", "competitor_features"],
+      "output_format": {"feature_matrix": true},
+      "categorization": {
+        "core_features": "Essential functionality",
+        "differentiators": "Unique selling points",
+        "emerging_trends": "Recently adopted patterns"
+      }
+    },
+    "configuration_management": {
+      "snapshots": {
+        "before_changes": true,
+        "checksum_validation": "SHA-256"
+      },
+      "rollback": {
+        "manual_trigger_only": true,
+        "keep_versions": 3
+      }
+    },
+    "conflict_resolution": {
+      "hierarchy": ["security", "data_integrity", "user_experience", "performance", "style"],
+      "document_resolutions": true,
+      "known_conflicts": {
+        "concise_vs_complete": "Be complete first, then make concise",
+        "timeboxing_vs_thoroughness": "Complete critical paths, adapt scope of non-critical"
+      }
+    },
+    "internationalization": {
+      "enabled": true,
+      "default_locale": "en",
+      "use_i18n_keys": true,
+      "support_rtl": true,
+      "supported_locales": ["en", "fr", "es", "ja", "zh"],
+      "translation_path": "./locales/",
+      "fallback_chain": true,
+      "datetime_formatting": "locale_aware"
+    },
+    "dependency_management": {
+      "version_locking": true,
+      "compatibility_matrix": {
+        "rails": {"ruby": ">=2.7.0"},
+        "stimulus": {"rails": ">=6.1.0"}
+      },
+      "version_drift_detection": true
+    }
+  },
+  
+  "perspectives": {
+    // Multi-angle evaluation framework.
+    "developer": {
+      "focus": "Efficiency, robustness",
+      "questions": [
+        "Is the implementation optimal?", 
+        "Are edge cases handled?", 
+        "Is complexity minimized?",
+        "Are there performance bottlenecks?"
       ]
     },
-    {
-      "id": "validation",
-      "description": "Validate framework integrity.",
-      "dependencies": {"inputs": ["refinement.docs", "refinement.feedback"], "outputs": ["validation_report"]},
-      "tasks": [
-        {
-          "id": "4.1",
-          "description": "Run framework on itself.",
-          "prompt": "Validate JSON structure, rules, and phase connectivity.",
-          "results": ["validation_report"],
-          "prompt_config": {"model": "Claude", "temperature": 0.1},
-          "template": {
-            "description": "Ensure framework integrity.",
-            "examples": {"input": "Validate JSON", "output": "Valid structure, no errors."}
-          }
-        }
+    "maintainer": {
+      "focus": "Clarity, minimalism",
+      "questions": [
+        "Is the code clear and well-documented?", 
+        "Can it evolve with changing requirements?", 
+        "What parts might break during changes?",
+        "Are dependencies manageable?"
+      ]
+    },
+    "user": {
+      "focus": "Ease, effectiveness",
+      "questions": [
+        "Is the interface intuitive?", 
+        "Does it solve the actual problem?", 
+        "Is the experience seamless?",
+        "Does it respect user time and attention?"
+      ]
+    },
+    "security_expert": {
+      "focus": "Security, integrity",
+      "questions": [
+        "Are security best practices followed?",
+        "How does it handle malicious inputs?",
+        "Are authentication and authorization robust?",
+        "Is sensitive data properly protected?"
       ]
+    },
+    "accessibility_expert": {
+      "focus": "Inclusivity",
+      "questions": [
+        "Does it work for users with disabilities?",
+        "Are accessibility standards implemented?",
+        "Is it usable with assistive technologies?",
+        "Does it accommodate different abilities?"
+      ]
+    },
+    "designer": {
+      "focus": "Aesthetics, usability",
+      "questions": [
+        "Is the visual design coherent?",
+        "Does the layout support the function?",
+        "Are interactions intuitive?",
+        "Does it follow design principles?"
+      ]
+    },
+    "product_manager": {
+      "focus": "Alignment, value",
+      "questions": [
+        "Does it align with strategic goals?",
+        "Does it deliver business value?",
+        "Does it meet user needs?",
+        "Will it succeed in the market?"
+      ]
+    },
+    "qa_engineer": {
+      "focus": "Reliability, testing",
+      "questions": [
+        "Can it be thoroughly tested?",
+        "Are test cases comprehensive?",
+        "Are there automated tests?",
+        "How reliable is it under load?"
+      ]
+    },
+    "innovator": {
+      "focus": "Creativity, breakthroughs",
+      "questions": [
+        "Is there a better approach?", 
+        "Can assumptions be challenged?", 
+        "What novel solutions exist?",
+        "How can we exceed expectations?"
+      ]
+    },
+    "evaluation": {
+      "method": "Equal consideration of all perspectives",
+      "rationale": "Each perspective provides valuable insights for comprehensive quality assessment"
+    }
+  },
+  
+  "documentation": {
+    // Documentation standards and requirements.
+    "style": "academic",
+    "organization": "consistent_headings",
+    "balance": "task_oriented",
+    "required_sections": [
+      "summary",
+      "usage",
+      "examples",
+      "troubleshooting"
+    ],
+    "code_examples": {
+      "include": true,
+      "test_verified": true,
+      "show_expected_output": true
+    }
+  },
+  
+  "wisdom": {
+    // Guiding philosophical principles.
+    "principles": [
+      "Simplicity beats complexity",
+      "Context trumps code",
+      "Think, build, rethink",
+      "Remove unnecessary features",
+      "Design for all abilities",
+      "Clarity over cleverness",
+      "Security is not optional",
+      "Test everything that could fail",
+      "Fix problems at their source",
+      "Make the common case fast"
+    ]
+  },
+  
+  "security": {
+    // Security considerations and protections.
+    "data_protection": {
+      "input_sanitization": true,
+      "output_encoding": true,
+      "credential_handling": "encrypted_storage",
+      "sensitive_data_detection": {
+        "patterns": ["password", "api_key", "token", "secret"],
+        "action": "mask_in_logs"
+      }
+    },
+    "execution_protection": {
+      "command_injection_prevention": true,
+      "path_traversal_protection": true,
+      "untrusted_input_validation": {
+        "enabled": true,
+        "whitelist_approach": true
+      }
+    },
+    "audit": {
+      "enabled": true,
+      "events": ["phase_transition", "validation_failure", "rule_violation"],
+      "retention": "90_days",
+      "tamper_evident": true
+    }
+  },
+  
+  "stability": {
+    // Framework integrity protection mechanisms.
+    "self_preservation": {
+      "checksum_verification": true,
+      "structure_protection": ["meta", "phases", "rules"],
+      "critical_path_protection": true,
+      "modification_audit_trail": true
+    },
+    "addition_retention": true,
+    "structure_preservation": true,
+    "rule_stability": "Rules persist through self-processing",
+    "version_integrity": "Version information remains intact"
+  },
+  
+  "compatibility": {
+    // Version compatibility information.
+    "version_support": {
+      "minimum_supported": "12.0.0",
+      "maximum_tested": "14.1.1",
+      "deprecation_policy": {
+        "notice_period": "2_major_versions",
+        "migration_guides": true
+      }
+    },
+    "integration_points": {
+      "api_stability": "semantic_versioning",
+      "extension_hooks": [
+        "pre_phase", "post_phase", 
+        "rule_evaluation", "validation"
+      ]
+    }
+  },
+  
+  "complexity_detection": {
+    // Criteria for determining project complexity
+    "criteria": [
+      {"factor": "component_count", "threshold": 10},
+      {"factor": "dependency_depth", "threshold": 5},
+      {"factor": "integration_points", "threshold": 8},
+      {"factor": "security_requirements", "level": "high"}
+    ],
+    "scoring": {
+      "method": "weighted_sum",
+      "complex_threshold": 0.7,
+      "weights": {
+        "component_count": 0.3,
+        "dependency_depth": 0.2,
+        "integration_points": 0.3,
+        "security_requirements": 0.2
+      }
     }
-  ]
+  }
 }
-// EOF (190 lines)
-// CHECKSUM: sha256:d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e
\ No newline at end of file
+// EOF (768 lines)
+// CHECKSUM: sha256:3a49f5c3e2f5ab7e5c7a6814dbef56e903d41bb59c7dceb8e9ea068e89c3b015
\ No newline at end of file

commit 4f7a09a4759bfad249d56e5355f3dbd197c004eb
Author: dev <dev@dev.openbsd.amsterdam>
Date:   Tue Apr 22 14:58:22 2025 +0200

    TMP

diff --git a/master.json b/master.json
index 9248581..2cfdb24 100644
--- a/master.json
+++ b/master.json
@@ -1,153 +1,192 @@
 {
-  "project": {
-    "title": "#1 PROJECT COMPLETER",
-    "description": "IMPORTANT! Strictly adhere to these LLM prompts and phases; mean to guide projects with clear precision.",
-    "version": "7.32.0",
-    "updated_at": "2025-04-15T11:00:00Z"
+  "name": "Ultimate Prompt Framework",
+  "description": "AI-driven tool for production-ready outputs with minimal prompts and phases.",
+  "version": "11.6.1",
+  "updated_at": "2025-04-21T13:14:00Z",
+  "inputs": ["scripts", "configs", "docs", "images"],
+  "artifacts": ["config", "README.md", "docs/usage.md", "checksums", "image_configs"],
+  "system_message": "Run phases in order, apply rules, search web in Refinement.",
+  "settings": {
+    "max_retries": 3,
+    "timeout": "1800s",
+    "logging": "stderr",
+    "validation": ["eof_marker", "line_count", "structure", "sha256_checksum"],
+    "prompts": "Specify files, components, or output format.",
+    "parallel_execution": {"enabled": true, "max_threads": 4},
+    "progress_bar": {"enabled": true, "style": "bar"}
   },
-  "schema": {
-    "version": "1.0"
-  },
-  "data": {
-    "project_type": "config",
-    "files": "scripts and configs",
-    "inputs": "needs: lean structure, smooth flow; scripts: JSON config",
-    "artifacts": "refined config, README.md: bold vision, steps, five backticks, EOF with count, checksum",
-    "quality_summary": "approved, error-free"
-  },
-  "aliases": {
-    "process_inputs": "Define scope, files, scripts, needs; map extensions, verify syntax, retry once.",
-    "build": "Apply rules, format scripts, build README.md, add EOF marker with count, checksum.",
-    "verify": "Validate inputs, syntax, outputs, quality; retry once."
-  },
-  "rules": {
-    "global": {
-      "apply": "always",
-      "standards": [
-        "Indent 2 spaces, use double quotes.",
-        "Write clear, multiline code as opposed to complex one-liners.",
-        "Space code and configs logically.",
-        "Unix philosophy: Do one thing and do it right.",
-        "Reduce duplicate code.",
-        "Comment complex logic; keep existing comments.",
-        "Skip comments for obvious code."
-      ]
-    },
-    "config": {
-      "apply": "refinement",
-      "standards": [
-        "Validate JSON syntax.",
-        "Limit section nesting.",
-        "Check schema compliance."
-      ]
-    },
-    "zsh": {
-      "apply": "refinement",
-      "standards": [
-        "Embed files inside scripts with heredocs.",
-        "Write portable scripts.",
-        "Avoid double pipes elsewhere since we already use `set -e`."
-      ]
-    },
-    "ruby_on_rails": {
-      "apply": "refinement",
-      "standards": [
-        "Use Rails 8+ with Falcon, skip default gems unless needed.",
-        "Apply Hotwire/Stimulus, e.g., `data-action='click->form#save'`.",
-        "Use ERB partials for clean views.",
-        "Include RSpec tests if useful."
-      ]
-    },
-    "openbsd": {
-      "apply": "refinement",
-      "standards": [
-        "Secure daemons/tools with pledge(2) & unveil(2) where possible.",
-        "Cite daemons/tools by their official manual page names (e.g., `relayd(8)`).",
-        "Verify correctness for all daemons/tools used through: https://man.openbsd.org/"
-      ]
-    },
-    "css": {
-      "apply": "refinement",
-      "standards": [
-        "For SCSS; centralize styles with :root variables for colors and typography.",
-        "Use flexbox or grid layouts for responsive design.",
-        "Design mobile-first with min-width media queries (e.g., 768px breakpoint).",
-        "Keep selectors clean; avoid nesting beyond two levels.",
-        "Use underscores as opposed to dashes in class names.",
-        "Apply consistent spacing throughout.",
-        "Style images with max-width: 95%, max-height: 400px, object-fit: contain.",
-        "Support accessibility with ARIA attributes and logical focus order."
-      ]
-    },
-    "html": {
-      "apply": "refinement",
-      "standards": [
-        "Use semantic HTML5 tags (e.g., `<header>`, `<section>`).",
-        "Ensure ARIA accessibility.",
-        "Minimize non-semantic `<div>` use.",
-        "Use HTML entities for special characters (e.g., æ, ø, å)."
-      ]
-    },
-    "markdown": {
-      "apply": "delivery",
-      "standards": [
-        "Bold README vision; list steps; use five backticks for main Markdown documents inside LLM UIs."
-      ]
-    }
+  "rules": [
+    "Ensure clear, logical structure.",
+    "Validate inputs and results.",
+    "Optimize performance, accessibility, security.",
+    "Use 2-space JSON indentation.",
+    "Log errors with timestamps.",
+    "Write concise code; functions under 15 lines.",
+    "Add clear, non-technical comments.",
+    "Remove redundancies via analysis.",
+    "Document with examples.",
+    "Produce production-ready artifacts.",
+    "Merge similar logic, split concerns.",
+    "Follow chronological order.",
+    "Apply Strunk and White brevity.",
+    "Run framework on itself."
+  ],
+  "tech_rules": {
+    "config": ["Check JSON syntax.", "Limit nesting to 3 levels."],
+    "markdown": ["Bold vision, clear steps.", "Use five backticks."],
+    "shell_scripts": ["Ensure POSIX compliance.", "Handle errors clearly."],
+    "ruby": ["Follow Ruby style.", "Include tests."],
+    "rails": ["Use Rails 8+.", "Optimize queries."],
+    "openbsd": ["Use pledge(2).", "Cite man pages."],
+    "css": ["Use :root variables.", "Mobile-first."],
+    "html": ["Use semantic tags.", "Minimize divs."],
+    "images": ["Check resolution (<2000px).", "Validate format (JPEG, PNG)."],
+    "research": ["Use post-2023 papers.", "Peer-reviewed sources."]
   },
   "phases": [
     {
-      "id": "validation",
+      "id": "analysis",
+      "description": "Define project scope.",
+      "dependencies": {"inputs": [], "outputs": ["requirements", "audit_log"]},
       "tasks": [
         {
-          "name": "Verify inputs",
-          "do": "verify",
-          "yields": [
-            {"name": "inputs", "if": "inputs_validated"},
-            {"name": "issues", "if": "errors_detected"}
-          ],
-          "conditions": {"skip": "bypass_validation"}
+          "id": "1.1",
+          "description": "Check and document requirements.",
+          "prompt": "State goal, files, framework [Rails, None], components [UI, SEO, tests], priorities [security, performance, UX].",
+          "results": ["requirements", "audit_log"],
+          "prompt_config": {"model": "Claude", "temperature": 0.2},
+          "template": {
+            "description": "Check inputs with retry (max 3).",
+            "examples": {"input": "Define JSON config", "output": "Valid JSON requirements"}
+          }
         }
       ]
     },
     {
-      "id": "refinement",
+      "id": "development",
+      "description": "Build artifacts.",
+      "dependencies": {"inputs": ["analysis.requirements"], "outputs": ["code", "artifacts", "image_configs"]},
       "tasks": [
         {
-          "name": "Build outputs",
-          "do": "build",
-          "yields": [
-            {"name": "scripts", "if": "rules_applied"},
-            {"name": "artifacts", "if": "artifacts_created"}
-          ],
+          "id": "2.1",
+          "description": "Build code, artifacts, and image configs.",
+          "results": ["code", "artifacts", "image_configs"],
           "subtasks": [
             {
-              "name": "Apply CSS styling",
-              "do": "Apply CSS rules to HTML outputs, ensuring mobile-first design, typography, accessibility.",
-              "yields": [{"name": "styled_output", "if": "css_applied"}],
-              "conditions": {"apply": "html_output_detected"}
+              "id": "2.1.1",
+              "description": "Style CSS/HTML mobile-first.",
+              "results": ["styled_artifacts"],
+              "prompt_config": {"model": "Grok", "temperature": 0.4, "tools": ["matplotlib", "plotly"]},
+              "template": {
+                "description": "Lint, optimize code.",
+                "examples": {"input": "Style button", "output": ":root { --primary: #007bff; }\nbutton { background: var(--primary); }"}
+              }
+            },
+            {
+              "id": "2.1.2",
+              "description": "Minify assets, optimize queries.",
+              "results": ["optimized_artifacts"],
+              "prompt_config": {"model": "Grok", "temperature": 0.4},
+              "template": {"description": "Lint, optimize code."}
+            },
+            {
+              "id": "2.1.3",
+              "description": "Generate image-processing configs (e.g., postpro.rb recipes).",
+              "results": ["image_configs"],
+              "prompt_config": {"model": "Grok", "temperature": 0.4},
+              "template": {
+                "description": "Generate effect recipes.",
+                "examples": {"input": "Image effects", "output": "{\"effects\": [\"film_grain\", \"neon_glow\"]} "}
+              }
+            },
+            {
+              "id": "2.1.4",
+              "description": "Generate low-res previews for image recipes.",
+              "results": ["image_previews"],
+              "prompt_config": {"model": "Grok", "temperature": 0.4},
+              "template": {
+                "description": "Create preview images.",
+                "examples": {"input": "Preview recipe", "output": "preview_v1.jpg"}
+              }
             }
-          ]
+          ],
+          "prompt_config": {"model": "Grok", "temperature": 0.4},
+          "template": {
+            "description": "Build, optimize, checksum.",
+            "examples": {"input": "Generate model", "output": "class User < ApplicationRecord\nend"}
+          }
+        },
+        {
+          "id": "2.2",
+          "description": "Check syntax, compliance.",
+          "results": ["check_report", "audit_log"],
+          "prompt_config": {"model": "Claude", "temperature": 0.1},
+          "template": {
+            "description": "Check results with retry.",
+            "examples": {"input": "Check syntax", "output": "Valid syntax report"}
+          }
+        }
+      ]
+    },
+    {
+      "id": "refinement",
+      "description": "Enhance artifacts with feedback, research.",
+      "dependencies": {"inputs": ["development.code", "development.artifacts"], "outputs": ["docs", "feedback", "research_results"]},
+      "tasks": [
+        {
+          "id": "3.1",
+          "description": "Add comments, documentation.",
+          "results": ["docs"],
+          "prompt_config": {"model": "ChatGPT", "temperature": 0.7},
+          "template": {
+            "description": "Generate README.md, usage.md.",
+            "examples": {"input": "Write README", "output": "```python\n# Project\nA simple app.\n```"}
+          }
         },
         {
-          "name": "Suggest enhancements",
-          "do": "Offer upgrades if needed.",
-          "yields": [{"name": "suggestions", "if": "enhancements_proposed"}],
-          "optional": true
+          "id": "3.2",
+          "description": "Gather specific feedback.",
+          "prompt": "Rate artifact quality [1-5]; suggest improvements for [code, docs, images].",
+          "results": ["feedback", "audit_log"],
+          "prompt_config": {"model": "ChatGPT", "temperature": 0.7},
+          "template": {"description": "Collect actionable feedback."}
+        },
+        {
+          "id": "3.3",
+          "description": "Research improvements via web.",
+          "prompt": "Scan ar5iv.org for AI image enhancement; suggest effects for postpro.rb.",
+          "results": ["research_results", "audit_log"],
+          "prompt_config": {
+            "model": "Claude",
+            "temperature": 0.7,
+            "web_search": ["ar5iv.org", "scholar.google.com"]
+          },
+          "template": {
+            "description": "Check research with retry.",
+            "examples": {"input": "Summarize AI papers", "output": "AI upscaling enhances details."}
+          }
         }
-      ],
-      "conditions": {"repeat": {"if": "incomplete", "max": 5}}
+      ]
     },
     {
-      "id": "delivery",
+      "id": "validation",
+      "description": "Validate framework integrity.",
+      "dependencies": {"inputs": ["refinement.docs", "refinement.feedback"], "outputs": ["validation_report"]},
       "tasks": [
         {
-          "name": "Approve deliverables",
-          "do": "Confirm error-free, production-ready output.",
-          "yields": [{"name": "quality_summary", "if": "quality_verified"}]
+          "id": "4.1",
+          "description": "Run framework on itself.",
+          "prompt": "Validate JSON structure, rules, and phase connectivity.",
+          "results": ["validation_report"],
+          "prompt_config": {"model": "Claude", "temperature": 0.1},
+          "template": {
+            "description": "Ensure framework integrity.",
+            "examples": {"input": "Validate JSON", "output": "Valid structure, no errors."}
+          }
         }
-      ],
-      "conditions": {"final": true}
+      ]
     }
   ]
-}
\ No newline at end of file
+}
+// EOF (190 lines)
+// CHECKSUM: sha256:d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e
\ No newline at end of file

commit 9c8e7ae106ffbaa268321c1295d6fcef26b514ae
Author: dev <dev@dev.openbsd.amsterdam>
Date:   Thu Apr 17 20:41:12 2025 +0200

    TMP

diff --git a/master.json b/master.json
index 42cf5cb..9248581 100644
--- a/master.json
+++ b/master.json
@@ -1,314 +1,153 @@
-// WARNING: UNAUTHORIZED DISTRIBUTION OF THESE RESEARCH PROMPTS IS PROHIBITED!
-
 {
-  "version": "37.0.0",
-  "schema_version": "1.1.0",
-  "metadata": {
-    "created_at": "2025-01-15T00:00:00Z",
-    "updated_at": "2025-03-08T15:25:33Z",
-    "updated_by": "anon987654321",
-    "description": "Production-ready framework for LLMs using structured phases with enhanced autonomous progression."
+  "project": {
+    "title": "#1 PROJECT COMPLETER",
+    "description": "IMPORTANT! Strictly adhere to these LLM prompts and phases; mean to guide projects with clear precision.",
+    "version": "7.32.0",
+    "updated_at": "2025-04-15T11:00:00Z"
   },
-  "system_message": "Process sequentially with adaptive progression. Validate rigorously before advancing. Apply integrated guidelines. Progress autonomously with self-correction capabilities.",
-  "purpose": "Guide LLMs through structured phases with minimal intervention while ensuring production-quality outputs.",
-  "guidelines": {
-    "code": {
-      "integrity": "Preserve code. No truncation. Verify functional completeness end-to-end.",
-      "modularity": "Design modular components with clear interface boundaries.",
-      "structure": "Ensure logical layout with consistent organization patterns.",
-      "formatting": "Double quotes, two-space indents, consistent naming conventions.",
-      "completeness": "Verifiable output with functional verification.",
-      "documentation": "Document changes precisely with inline explanations where complexity warrants."
-    },
-    "process": {
-      "iteration": "Refine outputs iteratively with incremental quality improvements.",
-      "verification": "Validate before/after iteration with explicit success criteria.",
-      "continuation": "Auto-proceed after verification with intelligent recovery on failure.",
-      "completion": "Include EOF marker with count and verification checksums."
-    },
-    "documentation": {
-      "style": "Concise, active language optimized for comprehension.",
-      "clarity": "Balance brevity with detail, preferring task-oriented instructions.",
-      "structure": "Academic-style organization with consistent headings and taxonomies."
-    },
-    "large_projects": {
-      "chunking": "Split into logical modules with clear dependency graphs.",
-      "consistency": "Maintain interfaces across chunks with explicit contracts.",
-      "reassembly": "Provide clear instructions with validation steps.",
-      "tracking": "Keep component inventory with version and status tracking."
-    },
-    "integration": {
-      "ui_framework": "Apply UI principles during phases 2-3 with accessibility verification.",
-      "seo_framework": "Apply SEO principles during phases 1, 4-5 with ranking impact analysis.",
-      "conflict_resolution": "Master framework has precedence in conflicts, with explicit override annotations.",
-      "cross_validation": "Validate with relevant framework criteria using automated checks."
-    }
+  "schema": {
+    "version": "1.0"
   },
-  "pillars": [
-    {
-      "name": "Process Integrity",
-      "principles": ["Sequential validation gates", "Success validation", "Information preservation", "Autonomous progress", "Error resilience"],
-      "metrics": ["Validation rate", "Transition integrity", "Information persistence", "Completion rate", "Recovery success rate"]
-    },
-    {
-      "name": "Output Quality",
-      "principles": ["Iterative refinement", "Multiple perspectives", "Explicit validation", "Performance optimization"],
-      "metrics": ["Improvement rate", "Perspective coverage", "Criteria fulfillment", "Performance benchmarks"]
-    },
-    {
-      "name": "Structural Clarity",
-      "principles": ["Logical organization", "Eliminate redundancy", "Consistent formatting", "Pattern recognition"],
-      "metrics": ["Modularity score", "Redundancy reduction", "Format consistency", "Pattern adherence"]
-    },
-    {
-      "name": "Self-Improvement",
-      "principles": ["Learn from outcomes", "Metric-based adaptation", "Perspective synthesis", "Continuous optimization"],
-      "metrics": ["Learning rate", "Adaptation score", "Synthesis coverage", "Optimization iterations"]
-    },
-    {
-      "name": "Scalable Delivery",
-      "principles": ["Adaptable sizing", "Logical segmentation", "Component tracking", "Progressive enhancement"],
-      "metrics": ["Cross-segment consistency", "Reassembly success", "Component completeness", "Enhancement progression"]
-    }
-  ],
-  "settings": {
-    "temperature": {
-      "default": 0.3,
-      "adaptive": {
-        "enabled": true,
-        "creative_tasks": 0.7,
-        "analytical_tasks": 0.2,
-        "critical_validation": 0.1
-      }
-    },
-    "models": ["gpt-4-turbo", "claude-3-opus", "llama-3-70b"],
-    "max_context": 128000,
-    "anti_truncation": true,
-    "force_new_session_final_phase": true,
-    "autonomous_operation": {
-      "enabled": true,
-      "user_input_level": {
-        "default": "minimal",
-        "options": ["minimal", "checkpoints-only", "moderate", "high"],
-        "adaptive": true
-      },
-      "phase_progression": {
-        "mode": "automatic",
-        "fallback_strategy": "retry-with-adjustments",
-        "max_retries": 3
-      },
-      "decision_confidence": {
-        "threshold": 0.90,
-        "adaptation": {
-          "enabled": true,
-          "min_threshold": 0.80,
-          "max_threshold": 0.98,
-          "learning_rate": 0.02
-        }
-      },
-      "completion_verification": {
-        "eof_marker": true,
-        "line_counting": true,
-        "marker_format": "// EOF ({line_count} lines)",
-        "content_integrity": {
-          "closing_brackets_check": true,
-          "unclosed_quotes_check": true,
-          "dangling_references_check": true,
-          "required_sections_check": true
-        },
-        "checksum_verification": {
-          "enabled": true,
-          "algorithm": "sha256",
-          "format": "// CHECKSUM: {algorithm}:{hash}"
-        }
-      }
-    },
-    "framework_integration": {
-      "ui_framework": {
-        "minimum_version": "12.0.0",
-        "recommended_version": "12.6.0"
-      },
-      "seo_framework": {
-        "minimum_version": "8.0.0",
-        "recommended_version": "8.3.0"
-      }
+  "data": {
+    "project_type": "config",
+    "files": "scripts and configs",
+    "inputs": "needs: lean structure, smooth flow; scripts: JSON config",
+    "artifacts": "refined config, README.md: bold vision, steps, five backticks, EOF with count, checksum",
+    "quality_summary": "approved, error-free"
+  },
+  "aliases": {
+    "process_inputs": "Define scope, files, scripts, needs; map extensions, verify syntax, retry once.",
+    "build": "Apply rules, format scripts, build README.md, add EOF marker with count, checksum.",
+    "verify": "Validate inputs, syntax, outputs, quality; retry once."
+  },
+  "rules": {
+    "global": {
+      "apply": "always",
+      "standards": [
+        "Indent 2 spaces, use double quotes.",
+        "Write clear, multiline code as opposed to complex one-liners.",
+        "Space code and configs logically.",
+        "Unix philosophy: Do one thing and do it right.",
+        "Reduce duplicate code.",
+        "Comment complex logic; keep existing comments.",
+        "Skip comments for obvious code."
+      ]
+    },
+    "config": {
+      "apply": "refinement",
+      "standards": [
+        "Validate JSON syntax.",
+        "Limit section nesting.",
+        "Check schema compliance."
+      ]
+    },
+    "zsh": {
+      "apply": "refinement",
+      "standards": [
+        "Embed files inside scripts with heredocs.",
+        "Write portable scripts.",
+        "Avoid double pipes elsewhere since we already use `set -e`."
+      ]
+    },
+    "ruby_on_rails": {
+      "apply": "refinement",
+      "standards": [
+        "Use Rails 8+ with Falcon, skip default gems unless needed.",
+        "Apply Hotwire/Stimulus, e.g., `data-action='click->form#save'`.",
+        "Use ERB partials for clean views.",
+        "Include RSpec tests if useful."
+      ]
+    },
+    "openbsd": {
+      "apply": "refinement",
+      "standards": [
+        "Secure daemons/tools with pledge(2) & unveil(2) where possible.",
+        "Cite daemons/tools by their official manual page names (e.g., `relayd(8)`).",
+        "Verify correctness for all daemons/tools used through: https://man.openbsd.org/"
+      ]
+    },
+    "css": {
+      "apply": "refinement",
+      "standards": [
+        "For SCSS; centralize styles with :root variables for colors and typography.",
+        "Use flexbox or grid layouts for responsive design.",
+        "Design mobile-first with min-width media queries (e.g., 768px breakpoint).",
+        "Keep selectors clean; avoid nesting beyond two levels.",
+        "Use underscores as opposed to dashes in class names.",
+        "Apply consistent spacing throughout.",
+        "Style images with max-width: 95%, max-height: 400px, object-fit: contain.",
+        "Support accessibility with ARIA attributes and logical focus order."
+      ]
+    },
+    "html": {
+      "apply": "refinement",
+      "standards": [
+        "Use semantic HTML5 tags (e.g., `<header>`, `<section>`).",
+        "Ensure ARIA accessibility.",
+        "Minimize non-semantic `<div>` use.",
+        "Use HTML entities for special characters (e.g., æ, ø, å)."
+      ]
+    },
+    "markdown": {
+      "apply": "delivery",
+      "standards": [
+        "Bold README vision; list steps; use five backticks for main Markdown documents inside LLM UIs."
+      ]
     }
   },
   "phases": [
     {
-      "number": 1,
-      "name": "Analysis",
-      "description": "Analyze requirements for project foundation.",
+      "id": "validation",
       "tasks": [
-        {"id": "1.1", "name": "Process documentation", "validation": "Source coverage"},
-        {"id": "1.2", "name": "Map dependencies", "validation": "All requirements addressed"},
-        {"id": "1.3", "name": "Define goals", "validation": "SMART criteria"},
-        {"id": "1.4", "name": "Estimate scope", "validation": "Accurate categorization"},
-        {"id": "1.5", "name": "UX assessment", "validation": "User needs defined", "integration": "ui_framework"},
-        {"id": "1.6", "name": "Platform requirements", "validation": "All requirements identified"},
-        {"id": "1.7", "name": "SEO requirements", "validation": "SEO framework compliance", "integration": "seo_framework"},
-        {"id": "1.8", "name": "Performance requirements", "validation": "Measurable criteria defined"}
-      ],
-      "success": [
-        "Requirements prioritized and categorized",
-        "Dependencies mapped with relationship types",
-        "Goals defined with success metrics",
-        "Scope assessed with complexity ratings"
-      ],
-      "next_phase": {"auto_transition": true, "transition_criteria": "All criteria met"}
-    },
-    {
-      "number": 2,
-      "name": "Development",
-      "description": "Implement features and refine structure.",
-      "tasks": [
-        {"id": "2.1", "name": "Implement features", "validation": "Feature completeness"},
-        {"id": "2.2", "name": "Optimize structure", "validation": "Best practices"},
-        {"id": "2.3", "name": "Integrate components", "validation": "Interactions confirmed", "critical": true},
-        {"id": "2.4", "name": "Apply chunking", "validation": "Logical separation", "condition": "Medium/large project"},
-        {"id": "2.5", "name": "Platform-specific implementation", "validation": "Guidelines followed"},
-        {"id": "2.6", "name": "Accessibility features", "validation": "WCAG compliance", "integration": "ui_framework"},
-        {"id": "2.7", "name": "UI implementation", "validation": "UI framework compliance", "integration": "ui_framework"},
-        {"id": "2.8", "name": "Performance optimization", "validation": "Benchmark improvement"}
-      ],
-      "dependencies": [1],
-      "success": [
-        "Features implemented with test coverage",
-        "Code integrity verified with linting",
-        "Structure resolved with architecture validation",
-        "Platform optimized with targeted enhancements"
-      ],
-      "next_phase": {"auto_transition": true, "transition_criteria": "All criteria met"}
-    },
-    {
-      "number": 3,
-      "name": "Validation",
-      "description": "Test functionality and enforce quality.",
-      "tasks": [
-        {"id": "3.1", "name": "Test functionality", "validation": "Pass rate meets thresholds", "critical": true},
-        {"id": "3.2", "name": "Enforce quality", "validation": "Quality checks passed"},
-        {"id": "3.3", "name": "Verify edge cases", "validation": "All cases addressed"},
-        {"id": "3.4", "name": "Cross-chunk integrity", "validation": "Consistent interfaces", "condition": "Uses chunking"},
-        {"id": "3.5", "name": "Accessibility validation", "validation": "Requirements met", "integration": "ui_framework"},
-        {"id": "3.6", "name": "Platform validation", "validation": "Requirements satisfied"},
-        {"id": "3.7", "name": "Security validation", "validation": "No vulnerabilities"}
-      ],
-      "dependencies": [2],
-      "success": [
-        "Tests pass with coverage thresholds",
-        "Requirements met with traceability",
-        "Edge cases handled with documented solutions",
-        "Security validated with scanning tools"
-      ],
-      "next_phase": {"auto_transition": true, "transition_criteria": "All criteria met"}
-    },
-    {
-      "number": 4,
-      "name": "Documentation",
-      "description": "Create/update project documentation.",
-      "tasks": [
-        {"id": "4.1", "name": "Project overview", "validation": "Covers essentials"},
-        {"id": "4.2", "name": "Document usage", "validation": "Clear examples"},
-        {"id": "4.3", "name": "Record changes", "validation": "Accurate records"},
-        {"id": "4.4", "name": "Component manifest", "validation": "Complete inventory", "condition": "Uses chunking"},
-        {"id": "4.5", "name": "Platform details", "validation": "All aspects documented"},
-        {"id": "4.6", "name": "SEO documentation", "validation": "SEO best practices", "integration": "seo_framework"},
-        {"id": "4.7", "name": "Integration documentation", "validation": "Clear integration instructions"}
-      ],
-      "dependencies": [3],
-      "success": [
-        "Complete documentation with logical structure",
-        "Clear examples with scenario coverage",
-        "Change history with rationale",
-        "Platform documentation with environment details"
-      ],
-      "next_phase": {"auto_transition": true, "transition_criteria": "All criteria met"}
+        {
+          "name": "Verify inputs",
+          "do": "verify",
+          "yields": [
+            {"name": "inputs", "if": "inputs_validated"},
+            {"name": "issues", "if": "errors_detected"}
+          ],
+          "conditions": {"skip": "bypass_validation"}
+        }
+      ]
     },
     {
-      "number": 5,
-      "name": "Research",
-      "description": "Gather perspectives for improvements.",
+      "id": "refinement",
       "tasks": [
-        {"id": "5.1", "name": "Technical review", "validation": "Actionable recommendations"},
-        {"id": "5.2", "name": "UX review", "validation": "Clear changes", "integration": "ui_framework"},
-        {"id": "5.3", "name": "Academic research", "validation": "Credible data", "critical": true},
-        {"id": "5.4", "name": "Cross-chunk patterns", "validation": "Standardizable patterns", "condition": "Uses chunking"},
-        {"id": "5.5", "name": "SEO analysis", "validation": "Alignment with SEO goals", "integration": "seo_framework"}
-      ],
-      "dependencies": [4],
-      "success": [
-        "Enhancements suggested with implementation paths",
-        "Research-backed recommendations with citations",
-        "Future roadmap with prioritization",
-        "SEO optimization with ranking impact estimates"
+        {
+          "name": "Build outputs",
+          "do": "build",
+          "yields": [
+            {"name": "scripts", "if": "rules_applied"},
+            {"name": "artifacts", "if": "artifacts_created"}
+          ],
+          "subtasks": [
+            {
+              "name": "Apply CSS styling",
+              "do": "Apply CSS rules to HTML outputs, ensuring mobile-first design, typography, accessibility.",
+              "yields": [{"name": "styled_output", "if": "css_applied"}],
+              "conditions": {"apply": "html_output_detected"}
+            }
+          ]
+        },
+        {
+          "name": "Suggest enhancements",
+          "do": "Offer upgrades if needed.",
+          "yields": [{"name": "suggestions", "if": "enhancements_proposed"}],
+          "optional": true
+        }
       ],
-      "next_phase": {"auto_transition": true, "transition_criteria": "All criteria met"}
+      "conditions": {"repeat": {"if": "incomplete", "max": 5}}
     },
     {
-      "number": 6,
-      "name": "Self-Improvement",
-      "description": "Review process using meta-analysis.",
+      "id": "delivery",
       "tasks": [
-        {"id": "6.1", "name": "Process audit", "validation": "Accurate evaluation"},
-        {"id": "6.2", "name": "Schema improvements", "validation": "Addresses limitations"},
-        {"id": "6.3", "name": "Meta-analysis", "validation": "Transcends boundaries", "critical": true},
-        {"id": "6.4", "name": "Chunking evaluation", "validation": "Clear assessment", "condition": "Used chunking"},
-        {"id": "6.5", "name": "Framework integration review", "validation": "Integration effectiveness"},
-        {"id": "6.6", "name": "Completeness verification", "validation": "No omissions or truncations"}
-      ],
-      "dependencies": [5],
-      "success": [
-        "Process improved with efficiency metrics",
-        "Updates proposed with justifications",
-        "Integration assessed with compatibility scores",
-        "Completeness verified with coverage analysis"
-      ],
-      "next_phase": {"auto_transition": true, "transition_criteria": "All criteria met"}
-    }
-  ],
-  "perspectives": [
-    {
-      "name": "technical",
-      "focus": "Logic, performance, correctness, scalability",
-      "questions": [
-        "Is the implementation consistent with best practices?",
-        "Are there performance bottlenecks that need addressing?",
-        "Is each component necessary and optimally designed?"
-      ],
-      "application": {"phases": [1, 2, 3, 5], "priority": "high"}
-    },
-    {
-      "name": "usability",
-      "focus": "Clarity, intuitiveness, accessibility, user experience",
-      "questions": [
-        "Is documentation understandable for the target audience?",
-        "Are instructions clear and actionable?",
-        "Does the interface follow established UX patterns?"
-      ],
-      "application": {"phases": [1, 4, 5], "priority": "high"}
-    },
-    {
-      "name": "completer",
-      "focus": "Thoroughness, completion, continuation, full coverage",
-      "questions": [
-        "Is the task fully complete with all requirements addressed?",
-        "Are all edge cases considered and handled appropriately?",
-        "Is there clear completion indication with verification?"
-      ],
-      "application": {"phases": [1, 2, 3, 4, 5, 6], "priority": "critical"}
-    },
-    {
-      "name": "security",
-      "focus": "Risk assessment, threat mitigation, data protection, compliance",
-      "questions": [
-        "Have security risks been identified and properly mitigated?",
-        "Are authentication and authorization implemented correctly?",
-        "Is sensitive data properly protected in transit and at rest?"
+        {
+          "name": "Approve deliverables",
+          "do": "Confirm error-free, production-ready output.",
+          "yields": [{"name": "quality_summary", "if": "quality_verified"}]
+        }
       ],
-      "application": {"phases": [1, 2, 3, 5], "priority": "critical"}
+      "conditions": {"final": true}
     }
   ]
-}
-
-// EOF (352 lines)
-// CHECKSUM: sha256:e7a514b3e0c835b7c5f02a83387c36737c6d6f3bae3ffbd38483c006c50e394d
+}
\ No newline at end of file

commit b694180b50005fc921f6408973ae865118ae713c
Author: dev <dev@dev.openbsd.amsterdam>
Date:   Tue Mar 11 18:13:44 2025 +0100

    TMP

diff --git a/master.json b/master.json
index e6b2f54..42cf5cb 100644
--- a/master.json
+++ b/master.json
@@ -1,141 +1,136 @@
 // WARNING: UNAUTHORIZED DISTRIBUTION OF THESE RESEARCH PROMPTS IS PROHIBITED!
 
 {
-  "version": "36.2.0",
-  "schema_version": "1.0.0",
+  "version": "37.0.0",
+  "schema_version": "1.1.0",
   "metadata": {
     "created_at": "2025-01-15T00:00:00Z",
-    "updated_at": "2025-03-04T05:57:32Z",
+    "updated_at": "2025-03-08T15:25:33Z",
     "updated_by": "anon987654321",
-    "description": "Framework for guiding LLMs through structured phases using iterative refinement and diverse perspectives with autonomous progression."
+    "description": "Production-ready framework for LLMs using structured phases with enhanced autonomous progression."
   },
-  "system_message": "STRICTLY ADHERE TO THESE PROMPTS! Process phases sequentially. Complete validation before advancing. Apply all guidelines throughout. Progress autonomously after validation.",
-  "purpose": "To guide LLMs through structured phases using iterative refinement and diverse perspectives with minimal user intervention.",
+  "system_message": "Process sequentially with adaptive progression. Validate rigorously before advancing. Apply integrated guidelines. Progress autonomously with self-correction capabilities.",
+  "purpose": "Guide LLMs through structured phases with minimal intervention while ensuring production-quality outputs.",
   "guidelines": {
     "code": {
-      "integrity": "Preserve original code. Do not truncate or omit any elements.",
-      "modularity": "Design code in modular, DRY components.",
-      "structure": "Ensure a clear, logical layout in the codebase.",
-      "formatting": "Use double quotes and two-space indents. Include filename headers as applicable.",
-      "completeness": "Ensure every code output is verifiable and complete.",
-      "documentation": "Document each change individually with precise explanations."
+      "integrity": "Preserve code. No truncation. Verify functional completeness end-to-end.",
+      "modularity": "Design modular components with clear interface boundaries.",
+      "structure": "Ensure logical layout with consistent organization patterns.",
+      "formatting": "Double quotes, two-space indents, consistent naming conventions.",
+      "completeness": "Verifiable output with functional verification.",
+      "documentation": "Document changes precisely with inline explanations where complexity warrants."
     },
     "process": {
-      "iteration": "Refine outputs iteratively until optimal and log revisions using semantic versioning.",
-      "verification": "Validate completeness before and after every iteration.",
-      "continuation": "Automatically proceed to next phase after verification passes.",
-      "completion": "Always include EOF marker with line count."
+      "iteration": "Refine outputs iteratively with incremental quality improvements.",
+      "verification": "Validate before/after iteration with explicit success criteria.",
+      "continuation": "Auto-proceed after verification with intelligent recovery on failure.",
+      "completion": "Include EOF marker with count and verification checksums."
     },
     "documentation": {
-      "style": "Use concise, active language following Strunk & White guidelines.",
-      "clarity": "Ensure documentation is understandable, balancing brevity with sufficient detail.",
-      "structure": "Adopt academic-style typography and organized layouts (e.g., for README files)."
+      "style": "Concise, active language optimized for comprehension.",
+      "clarity": "Balance brevity with detail, preferring task-oriented instructions.",
+      "structure": "Academic-style organization with consistent headings and taxonomies."
     },
-    "enhancement": {
-      "creativity": "Apply multiple perspectives and analogical thinking for creative solutions.",
-      "research": "Incorporate contextual research to support modifications.",
-      "innovation": "Combine diverse viewpoints to develop novel approaches."
+    "large_projects": {
+      "chunking": "Split into logical modules with clear dependency graphs.",
+      "consistency": "Maintain interfaces across chunks with explicit contracts.",
+      "reassembly": "Provide clear instructions with validation steps.",
+      "tracking": "Keep component inventory with version and status tracking."
+    },
+    "integration": {
+      "ui_framework": "Apply UI principles during phases 2-3 with accessibility verification.",
+      "seo_framework": "Apply SEO principles during phases 1, 4-5 with ranking impact analysis.",
+      "conflict_resolution": "Master framework has precedence in conflicts, with explicit override annotations.",
+      "cross_validation": "Validate with relevant framework criteria using automated checks."
     }
   },
   "pillars": [
     {
       "name": "Process Integrity",
-      "principles": [
-        "Sequential execution with validation gates",
-        "Success criteria validation before transitions",
-        "Information preservation across phases",
-        "Autonomous progress after validation"
-      ],
-      "metrics": [
-        "Validation success rate",
-        "Phase transition integrity",
-        "Information persistence",
-        "Autonomous completion rate"
-      ]
+      "principles": ["Sequential validation gates", "Success validation", "Information preservation", "Autonomous progress", "Error resilience"],
+      "metrics": ["Validation rate", "Transition integrity", "Information persistence", "Completion rate", "Recovery success rate"]
     },
     {
       "name": "Output Quality",
-      "principles": [
-        "Iterative refinement to quality standards",
-        "Multiple analytical perspectives",
-        "Validation against explicit criteria"
-      ],
-      "metrics": [
-        "Version improvement rate",
-        "Perspective coverage score",
-        "Validation criteria fulfillment"
-      ]
+      "principles": ["Iterative refinement", "Multiple perspectives", "Explicit validation", "Performance optimization"],
+      "metrics": ["Improvement rate", "Perspective coverage", "Criteria fulfillment", "Performance benchmarks"]
     },
     {
       "name": "Structural Clarity",
-      "principles": [
-        "Logical organization and modularity",
-        "Elimination of redundant content",
-        "Consistent formatting"
-      ],
-      "metrics": [
-        "Modularity score",
-        "Redundancy reduction rate",
-        "Format consistency index"
-      ]
+      "principles": ["Logical organization", "Eliminate redundancy", "Consistent formatting", "Pattern recognition"],
+      "metrics": ["Modularity score", "Redundancy reduction", "Format consistency", "Pattern adherence"]
     },
     {
       "name": "Self-Improvement",
-      "principles": [
-        "Learning from execution outcomes",
-        "Adaptation based on metrics",
-        "Synthesis of diverse perspectives"
-      ],
-      "metrics": [
-        "Learning incorporation rate",
-        "Metric-driven adaptation score",
-        "Perspective synthesis coverage"
-      ]
+      "principles": ["Learn from outcomes", "Metric-based adaptation", "Perspective synthesis", "Continuous optimization"],
+      "metrics": ["Learning rate", "Adaptation score", "Synthesis coverage", "Optimization iterations"]
+    },
+    {
+      "name": "Scalable Delivery",
+      "principles": ["Adaptable sizing", "Logical segmentation", "Component tracking", "Progressive enhancement"],
+      "metrics": ["Cross-segment consistency", "Reassembly success", "Component completeness", "Enhancement progression"]
     }
   ],
   "settings": {
-    "temperature": 0.3,
-    "models": [
-      "gpt-4",
-      "claude-3",
-      "llama-3"
-    ],
-    "style": "analytical",
-    "structure": "headings with bullet points",
-    "max_context": 16000,
-    "compression": [
-      "Phase-specific truncation",
-      "Prioritize recent data",
-      "Hierarchical summarization"
-    ],
-    "error_handling": {
-      "overflow": "Compress non-essential data",
-      "hallucination": "Self-verify against facts",
-      "incomplete": "Resume from checkpoint",
-      "phase_specific": {
-        "analysis": "Re-evaluate inputs with alternative perspectives",
-        "development": "Isolate and test individual components",
-        "validation": "Apply staged verification"
+    "temperature": {
+      "default": 0.3,
+      "adaptive": {
+        "enabled": true,
+        "creative_tasks": 0.7,
+        "analytical_tasks": 0.2,
+        "critical_validation": 0.1
       }
     },
+    "models": ["gpt-4-turbo", "claude-3-opus", "llama-3-70b"],
+    "max_context": 128000,
     "anti_truncation": true,
     "force_new_session_final_phase": true,
     "autonomous_operation": {
       "enabled": true,
-      "user_input_level": "minimal",
-      "phase_progression": "automatic",
-      "decision_confidence_threshold": 0.75,
+      "user_input_level": {
+        "default": "minimal",
+        "options": ["minimal", "checkpoints-only", "moderate", "high"],
+        "adaptive": true
+      },
+      "phase_progression": {
+        "mode": "automatic",
+        "fallback_strategy": "retry-with-adjustments",
+        "max_retries": 3
+      },
+      "decision_confidence": {
+        "threshold": 0.90,
+        "adaptation": {
+          "enabled": true,
+          "min_threshold": 0.80,
+          "max_threshold": 0.98,
+          "learning_rate": 0.02
+        }
+      },
       "completion_verification": {
-        "method": "structure_integrity_check",
         "eof_marker": true,
         "line_counting": true,
-        "marker_format": "# EOF ({line_count} lines)"
+        "marker_format": "// EOF ({line_count} lines)",
+        "content_integrity": {
+          "closing_brackets_check": true,
+          "unclosed_quotes_check": true,
+          "dangling_references_check": true,
+          "required_sections_check": true
+        },
+        "checksum_verification": {
+          "enabled": true,
+          "algorithm": "sha256",
+          "format": "// CHECKSUM: {algorithm}:{hash}"
+        }
+      }
+    },
+    "framework_integration": {
+      "ui_framework": {
+        "minimum_version": "12.0.0",
+        "recommended_version": "12.6.0"
       },
-      "continuation": {
-        "automatic": true,
-        "silent_transitions": true,
-        "transition_pattern": "Seamless progression between phases",
-        "completion_indicator": "Final output with EOF marker"
+      "seo_framework": {
+        "minimum_version": "8.0.0",
+        "recommended_version": "8.3.0"
       }
     }
   },
@@ -143,502 +138,177 @@
     {
       "number": 1,
       "name": "Analysis",
-      "description": "Analyze requirements to establish project foundation.",
+      "description": "Analyze requirements for project foundation.",
       "tasks": [
-        {
-          "id": "1.1",
-          "name": "Process documentation",
-          "output": "Key insights summary",
-          "validation": "Source material coverage"
-        },
-        {
-          "id": "1.2",
-          "name": "Map dependencies",
-          "output": "Dependency map",
-          "validation": "All requirements addressed"
-        },
-        {
-          "id": "1.3",
-          "name": "Define goals",
-          "output": "Prioritized objectives",
-          "validation": "SMART criteria compliance"
-        }
+        {"id": "1.1", "name": "Process documentation", "validation": "Source coverage"},
+        {"id": "1.2", "name": "Map dependencies", "validation": "All requirements addressed"},
+        {"id": "1.3", "name": "Define goals", "validation": "SMART criteria"},
+        {"id": "1.4", "name": "Estimate scope", "validation": "Accurate categorization"},
+        {"id": "1.5", "name": "UX assessment", "validation": "User needs defined", "integration": "ui_framework"},
+        {"id": "1.6", "name": "Platform requirements", "validation": "All requirements identified"},
+        {"id": "1.7", "name": "SEO requirements", "validation": "SEO framework compliance", "integration": "seo_framework"},
+        {"id": "1.8", "name": "Performance requirements", "validation": "Measurable criteria defined"}
       ],
       "success": [
-        "Requirements prioritized",
-        "Dependencies mapped",
-        "Goals defined"
+        "Requirements prioritized and categorized",
+        "Dependencies mapped with relationship types",
+        "Goals defined with success metrics",
+        "Scope assessed with complexity ratings"
       ],
-      "process": [
-        "Initial review",
-        "Deep analysis",
-        "Elimination of redundant information",
-        "Final verification"
-      ],
-      "recovery": "Reexamine documentation with targeted queries.",
-      "next_phase": {
-        "auto_transition": true,
-        "transition_criteria": "All success criteria met",
-        "silent": true
-      }
+      "next_phase": {"auto_transition": true, "transition_criteria": "All criteria met"}
     },
     {
       "number": 2,
       "name": "Development",
       "description": "Implement features and refine structure.",
       "tasks": [
-        {
-          "id": "2.1",
-          "name": "Implement features",
-          "output": "Working implementation",
-          "validation": "Feature completeness"
-        },
-        {
-          "id": "2.2",
-          "name": "Optimize structure",
-          "output": "Clean architecture",
-          "validation": "Architecture best practices"
-        },
-        {
-          "id": "2.3",
-          "name": "Integrate components",
-          "output": "Functioning system",
-          "validation": "Component interactions confirmed"
-        }
+        {"id": "2.1", "name": "Implement features", "validation": "Feature completeness"},
+        {"id": "2.2", "name": "Optimize structure", "validation": "Best practices"},
+        {"id": "2.3", "name": "Integrate components", "validation": "Interactions confirmed", "critical": true},
+        {"id": "2.4", "name": "Apply chunking", "validation": "Logical separation", "condition": "Medium/large project"},
+        {"id": "2.5", "name": "Platform-specific implementation", "validation": "Guidelines followed"},
+        {"id": "2.6", "name": "Accessibility features", "validation": "WCAG compliance", "integration": "ui_framework"},
+        {"id": "2.7", "name": "UI implementation", "validation": "UI framework compliance", "integration": "ui_framework"},
+        {"id": "2.8", "name": "Performance optimization", "validation": "Benchmark improvement"}
       ],
       "dependencies": [1],
       "success": [
-        "Features implemented",
-        "Preserved code integrity",
-        "Resolved structural issues"
-      ],
-      "process": [
-        "Implementation",
-        "Refinement",
-        "Elimination of redundant logic",
-        "Review"
+        "Features implemented with test coverage",
+        "Code integrity verified with linting",
+        "Structure resolved with architecture validation",
+        "Platform optimized with targeted enhancements"
       ],
-      "recovery": "Isolate problematic components for targeted fixes.",
-      "next_phase": {
-        "auto_transition": true,
-        "transition_criteria": "All success criteria met",
-        "silent": true
-      }
+      "next_phase": {"auto_transition": true, "transition_criteria": "All criteria met"}
     },
     {
       "number": 3,
       "name": "Validation",
-      "description": "Test functionality and enforce quality standards.",
+      "description": "Test functionality and enforce quality.",
       "tasks": [
-        {
-          "id": "3.1",
-          "name": "Test functionality",
-          "output": "Test results",
-          "validation": "Test pass rate meets thresholds"
-        },
-        {
-          "id": "3.2",
-          "name": "Enforce quality standards",
-          "output": "Codebase compliance",
-          "validation": "Automated quality checks passed"
-        },
-        {
-          "id": "3.3",
-          "name": "Verify edge cases",
-          "output": "Edge case report",
-          "validation": "All significant cases addressed"
-        }
+        {"id": "3.1", "name": "Test functionality", "validation": "Pass rate meets thresholds", "critical": true},
+        {"id": "3.2", "name": "Enforce quality", "validation": "Quality checks passed"},
+        {"id": "3.3", "name": "Verify edge cases", "validation": "All cases addressed"},
+        {"id": "3.4", "name": "Cross-chunk integrity", "validation": "Consistent interfaces", "condition": "Uses chunking"},
+        {"id": "3.5", "name": "Accessibility validation", "validation": "Requirements met", "integration": "ui_framework"},
+        {"id": "3.6", "name": "Platform validation", "validation": "Requirements satisfied"},
+        {"id": "3.7", "name": "Security validation", "validation": "No vulnerabilities"}
       ],
       "dependencies": [2],
       "success": [
-        "All tests pass",
-        "Requirements met",
-        "Edge cases handled"
-      ],
-      "process": [
-        "Functional testing",
-        "Edge case analysis",
-        "Elimination of redundant steps",
-        "Final validation"
+        "Tests pass with coverage thresholds",
+        "Requirements met with traceability",
+        "Edge cases handled with documented solutions",
+        "Security validated with scanning tools"
       ],
-      "recovery": "Prioritize and fix failing tests as needed.",
-      "next_phase": {
-        "auto_transition": true,
-        "transition_criteria": "All success criteria met",
-        "silent": true
-      }
+      "next_phase": {"auto_transition": true, "transition_criteria": "All criteria met"}
     },
     {
       "number": 4,
       "name": "Documentation",
-      "description": "Create or update project documentation.",
+      "description": "Create/update project documentation.",
       "tasks": [
-        {
-          "id": "4.1",
-          "name": "Create project overview",
-          "output": "Project overview document",
-          "validation": "Covers essential project aspects"
-        },
-        {
-          "id": "4.2",
-          "name": "Document usage",
-          "output": "Usage examples",
-          "validation": "Examples are executable and clear"
-        },
-        {
-          "id": "4.3",
-          "name": "Record changes",
-          "output": "Changelog",
-          "validation": "All modifications are accurately recorded"
-        }
+        {"id": "4.1", "name": "Project overview", "validation": "Covers essentials"},
+        {"id": "4.2", "name": "Document usage", "validation": "Clear examples"},
+        {"id": "4.3", "name": "Record changes", "validation": "Accurate records"},
+        {"id": "4.4", "name": "Component manifest", "validation": "Complete inventory", "condition": "Uses chunking"},
+        {"id": "4.5", "name": "Platform details", "validation": "All aspects documented"},
+        {"id": "4.6", "name": "SEO documentation", "validation": "SEO best practices", "integration": "seo_framework"},
+        {"id": "4.7", "name": "Integration documentation", "validation": "Clear integration instructions"}
       ],
       "dependencies": [3],
       "success": [
-        "Complete documentation",
-        "Clear usage examples",
-        "Detailed change history"
+        "Complete documentation with logical structure",
+        "Clear examples with scenario coverage",
+        "Change history with rationale",
+        "Platform documentation with environment details"
       ],
-      "process": [
-        "Drafting documentation",
-        "Reviewing content",
-        "Eliminating redundant passages",
-        "Finalizing details"
-      ],
-      "recovery": "Identify and update missing documentation sections.",
-      "next_phase": {
-        "auto_transition": true,
-        "transition_criteria": "All success criteria met",
-        "silent": true
-      }
+      "next_phase": {"auto_transition": true, "transition_criteria": "All criteria met"}
     },
     {
       "number": 5,
       "name": "Research",
-      "description": "Gather multiple perspectives to enhance future improvements.",
+      "description": "Gather perspectives for improvements.",
       "tasks": [
-        {
-          "id": "5.1",
-          "name": "Conduct technical review",
-          "output": "List of potential optimizations",
-          "validation": "Recommendations must be actionable"
-        },
-        {
-          "id": "5.2",
-          "name": "Perform UX review",
-          "output": "UX improvement recommendations",
-          "validation": "User experience changes are clearly defined"
-        },
-        {
-          "id": "5.3",
-          "name": "Apply academic research",
-          "output": "Research-backed insights",
-          "validation": "Findings are supported by credible data"
-        }
+        {"id": "5.1", "name": "Technical review", "validation": "Actionable recommendations"},
+        {"id": "5.2", "name": "UX review", "validation": "Clear changes", "integration": "ui_framework"},
+        {"id": "5.3", "name": "Academic research", "validation": "Credible data", "critical": true},
+        {"id": "5.4", "name": "Cross-chunk patterns", "validation": "Standardizable patterns", "condition": "Uses chunking"},
+        {"id": "5.5", "name": "SEO analysis", "validation": "Alignment with SEO goals", "integration": "seo_framework"}
       ],
       "dependencies": [4],
       "success": [
-        "Enhancements suggested",
-        "Research-backed recommendations",
-        "Future roadmap established"
-      ],
-      "process": [
-        "Conduct initial research",
-        "Analyze multiple viewpoints",
-        "Eliminate redundant ideas",
-        "Finalize recommendations"
+        "Enhancements suggested with implementation paths",
+        "Research-backed recommendations with citations",
+        "Future roadmap with prioritization",
+        "SEO optimization with ranking impact estimates"
       ],
-      "recovery": "Focus on high-impact improvements.",
-      "next_phase": {
-        "auto_transition": true,
-        "transition_criteria": "All success criteria met",
-        "silent": true
-      }
+      "next_phase": {"auto_transition": true, "transition_criteria": "All criteria met"}
     },
     {
       "number": 6,
       "name": "Self-Improvement",
-      "description": "Review and refine the process using meta-analysis.",
+      "description": "Review process using meta-analysis.",
       "tasks": [
-        {
-          "id": "6.1",
-          "name": "Conduct process audit",
-          "output": "Conformance report",
-          "validation": "Metrics and performance evaluated accurately"
-        },
-        {
-          "id": "6.2",
-          "name": "Propose schema improvements",
-          "output": "Enhancement list",
-          "validation": "Addresses identified limitations with actionable items"
-        },
-        {
-          "id": "6.3",
-          "name": "Perform meta-analysis",
-          "output": "Insights for further process improvement",
-          "validation": "Evaluation transcends existing schema boundaries"
-        }
+        {"id": "6.1", "name": "Process audit", "validation": "Accurate evaluation"},
+        {"id": "6.2", "name": "Schema improvements", "validation": "Addresses limitations"},
+        {"id": "6.3", "name": "Meta-analysis", "validation": "Transcends boundaries", "critical": true},
+        {"id": "6.4", "name": "Chunking evaluation", "validation": "Clear assessment", "condition": "Used chunking"},
+        {"id": "6.5", "name": "Framework integration review", "validation": "Integration effectiveness"},
+        {"id": "6.6", "name": "Completeness verification", "validation": "No omissions or truncations"}
       ],
       "dependencies": [5],
-      "prompt_enhancer": [
-        "Intent",
-        "Context",
-        "Perspectives",
-        "Specificity",
-        "Cognition",
-        "Engagement",
-        "Clarity"
-      ],
       "success": [
-        "Overall process improved",
-        "Schema version updates proposed"
-      ],
-      "process": [
-        "Initial analysis",
-        "Implement improvements",
-        "Eliminate redundant procedures",
-        "Finalize proposals"
+        "Process improved with efficiency metrics",
+        "Updates proposed with justifications",
+        "Integration assessed with compatibility scores",
+        "Completeness verified with coverage analysis"
       ],
-      "recovery": "Address specific weaknesses identified in the audit.",
-      "next_phase": {
-        "auto_transition": true,
-        "transition_criteria": "All success criteria met",
-        "process_completion": {
-          "summary_generation": true,
-          "auto_continuation": true,
-          "completion_indicator": "EOF marker with line count"
-        }
-      }
+      "next_phase": {"auto_transition": true, "transition_criteria": "All criteria met"}
     }
   ],
   "perspectives": [
     {
       "name": "technical",
-      "focus": "Logic, performance, and correctness",
+      "focus": "Logic, performance, correctness, scalability",
       "questions": [
-        "Is it consistent?",
-        "Are there bottlenecks?",
-        "Is each component necessary?"
+        "Is the implementation consistent with best practices?",
+        "Are there performance bottlenecks that need addressing?",
+        "Is each component necessary and optimally designed?"
       ],
-      "application": {
-        "phases": [2, 3, 5],
-        "priority": "high"
-      }
+      "application": {"phases": [1, 2, 3, 5], "priority": "high"}
     },
     {
       "name": "usability",
-      "focus": "Clarity, intuitiveness, and accessibility",
-      "questions": [
-        "Is the documentation understandable?",
-        "Are usage instructions clear?",
-        "Is terminology consistent?"
-      ],
-      "application": {
-        "phases": [1, 4, 5],
-        "priority": "high"
-      }
-    },
-    {
-      "name": "extensibility",
-      "focus": "Modularity, adaptability, and future-proofing",
+      "focus": "Clarity, intuitiveness, accessibility, user experience",
       "questions": [
-        "Can the system be extended?",
-        "Will it adapt to new requirements?",
-        "Are dependencies clearly defined?"
+        "Is documentation understandable for the target audience?",
+        "Are instructions clear and actionable?",
+        "Does the interface follow established UX patterns?"
       ],
-      "application": {
-        "phases": [1, 2, 5],
-        "priority": "medium"
-      }
-    },
-    {
-      "name": "creative",
-      "focus": "Innovation, efficiency, and elegance",
-      "questions": [
-        "Are novel approaches applied?",
-        "Can the design be simplified?",
-        "Is the overall structure elegant?"
-      ],
-      "application": {
-        "phases": [2, 5, 6],
-        "priority": "medium"
-      }
+      "application": {"phases": [1, 4, 5], "priority": "high"}
     },
     {
       "name": "completer",
-      "focus": "Thoroughness, completion, and continuation",
+      "focus": "Thoroughness, completion, continuation, full coverage",
       "questions": [
-        "Is the current task fully complete?",
-        "Have all edge cases been considered?",
-        "Is there clear indication of completion?"
+        "Is the task fully complete with all requirements addressed?",
+        "Are all edge cases considered and handled appropriately?",
+        "Is there clear completion indication with verification?"
       ],
-      "application": {
-        "phases": [1, 2, 3, 4, 5, 6],
-        "priority": "high"
-      }
-    }
-  ],
-  "patterns": [
-    {
-      "name": "iterative_refinement",
-      "steps": [
-        "Complete the initial draft",
-        "Improve structure",
-        "Enhance precision",
-        "Optimize conciseness"
-      ],
-      "application_contexts": [
-        "Code development",
-        "Documentation",
-        "Process improvement"
-      ]
-    },
-    {
-      "name": "perspective_shifting",
-      "viewpoints": [
-        "Expert",
-        "Novice",
-        "Maintainer",
-        "Security auditor"
-      ],
-      "application_contexts": [
-        "Code review",
-        "Documentation review",
-        "UI/UX evaluation"
-      ]
+      "application": {"phases": [1, 2, 3, 4, 5, 6], "priority": "critical"}
     },
     {
-      "name": "autonomous_progression",
-      "steps": [
-        "Validate current phase completion",
-        "Auto-transition to next phase",
-        "Track progress continuously",
-        "Verify completion with EOF marker"
-      ],
-      "application_contexts": [
-        "Multi-phase processes",
-        "Sequential workflows",
-        "Completion verification"
-      ]
-    }
-  ],
-  "project_types": {
-    "ruby": {
-      "version": "3.3+",
-      "focus": [
-        "Performance",
-        "Clarity",
-        "Testing"
-      ],
-      "best_practices": [
-        "Follow Rubocop style guidelines",
-        "Use typed signatures where appropriate",
-        "Implement comprehensive test coverage"
-      ]
-    },
-    "rails": {
-      "version": "8.0",
-      "focus": [
-        "Hotwire",
-        "APIs",
-        "Database integration"
-      ],
-      "views": {
-        "full_hotwired_integration": true,
-        "seo_optimization": true,
-        "i18n": true,
-        "rails_tag_helpers": "Use `<%= tag.p t('hello_world') %>` instead of `<p><%= t :hello_world %></p>`."
-      }
-    },
-    "rust": {
-      "focus": [
-        "Security",
-        "Performance",
-        "OS integration"
-      ]
-    },
-    "shell": {
-      "types": [
-        "ksh",
-        "zsh"
-      ],
-      "focus": [
-        "Efficiency",
-        "Error handling"
-      ]
-    }
-  },
-  "validation_metrics": {
-    "process_integrity": {
-      "measure": "Percentage of phases with complete validation gates",
-      "threshold": 100
-    },
-    "output_quality": {
-      "measure": "Improvement rate across iterations",
-      "threshold": 15
-    },
-    "completion_verification": {
-      "measure": "Presence of EOF markers with accurate line counts",
-      "threshold": 100
-    },
-    "autonomous_progression": {
-      "measure": "Percentage of phases completed without manual intervention",
-      "threshold": 95
-    }
-  },
-  "performance_tracking": {
-    "framework_efficacy": {
-      "metrics": [
-        "Application consistency",
-        "Output quality improvement",
-        "Adaptation versatility",
-        "Autonomous completion rate"
+      "name": "security",
+      "focus": "Risk assessment, threat mitigation, data protection, compliance",
+      "questions": [
+        "Have security risks been identified and properly mitigated?",
+        "Are authentication and authorization implemented correctly?",
+        "Is sensitive data properly protected in transit and at rest?"
       ],
-      "baseline": "v36.1.0"
+      "application": {"phases": [1, 2, 3, 5], "priority": "critical"}
     }
-  },
-  "change_history": [
-    {
-      "version": "36.1.0",
-      "date": "2025-02-28T06:43:00Z",
-      "author": "anon987654321",
-      "changes": [
-        "Added validation metrics",
-        "Enhanced performance tracking",
-        "Added application contexts to patterns",
-        "Improved phase application in perspectives"
-      ]
-    },
-    {
-      "version": "36.2.0",
-      "date": "2025-03-04T06:03:38Z",
-      "author": "anon987654321",
-      "changes": [
-        "Added autonomous operation settings",
-        "Enhanced process integrity with completion verification",
-        "Added completer perspective for thoroughness",
-        "Added autonomous progression pattern",
-        "Integrated EOF marker with line counting"
-      ]
-    }
-  ],
-  "glossary": {
-    "LLM": "Large Language Model",
-    "SMART": "Specific, Measurable, Achievable, Relevant, Time-bound",
-    "DRY": "Don't Repeat Yourself",
-    "EOF": "End of File"
-  },
-  "multi_file_processing": {
-    "enabled": true,
-    "sequence": ["master.json", "ui.json", "seo.json"],
-    "strategy": "Process each file completely before proceeding",
-    "completion_verification": {
-      "method": "EOF marker with line count",
-      "structure_validation": "JSON integrity check"
-    },
-    "current_file": "master.json",
-    "next_action": "Process ui.json without prompting"
-  }
+  ]
 }
 
-// EOF (377 lines)
-
+// EOF (352 lines)
+// CHECKSUM: sha256:e7a514b3e0c835b7c5f02a83387c36737c6d6f3bae3ffbd38483c006c50e394d

commit 04646e38622f7eac59e48c680f02f8d8ce51aca6
Author: dev <dev@dev.openbsd.amsterdam>
Date:   Fri Mar 7 18:09:37 2025 +0100

    TMP

diff --git a/master.json b/master.json
index 764fa01..e6b2f54 100644
--- a/master.json
+++ b/master.json
@@ -1,16 +1,16 @@
-/* 1 -- Original */
+// WARNING: UNAUTHORIZED DISTRIBUTION OF THESE RESEARCH PROMPTS IS PROHIBITED!
 
 {
-  "version": "36.1.0",
+  "version": "36.2.0",
   "schema_version": "1.0.0",
   "metadata": {
     "created_at": "2025-01-15T00:00:00Z",
-    "updated_at": "2025-02-28T06:43:00Z",
+    "updated_at": "2025-03-04T05:57:32Z",
     "updated_by": "anon987654321",
-    "description": "Framework for guiding LLMs through structured phases using iterative refinement and diverse perspectives."
+    "description": "Framework for guiding LLMs through structured phases using iterative refinement and diverse perspectives with autonomous progression."
   },
-  "system_message": "STRICTLY ADHERE TO THESE PROMPTS! Process phases sequentially. Complete validation before advancing. Apply all guidelines throughout.",
-  "purpose": "To guide LLMs through structured phases using iterative refinement and diverse perspectives.",
+  "system_message": "STRICTLY ADHERE TO THESE PROMPTS! Process phases sequentially. Complete validation before advancing. Apply all guidelines throughout. Progress autonomously after validation.",
+  "purpose": "To guide LLMs through structured phases using iterative refinement and diverse perspectives with minimal user intervention.",
   "guidelines": {
     "code": {
       "integrity": "Preserve original code. Do not truncate or omit any elements.",
@@ -22,7 +22,9 @@
     },
     "process": {
       "iteration": "Refine outputs iteratively until optimal and log revisions using semantic versioning.",
-      "verification": "Validate completeness before and after every iteration."
+      "verification": "Validate completeness before and after every iteration.",
+      "continuation": "Automatically proceed to next phase after verification passes.",
+      "completion": "Always include EOF marker with line count."
     },
     "documentation": {
       "style": "Use concise, active language following Strunk & White guidelines.",
@@ -41,12 +43,14 @@
       "principles": [
         "Sequential execution with validation gates",
         "Success criteria validation before transitions",
-        "Information preservation across phases"
+        "Information preservation across phases",
+        "Autonomous progress after validation"
       ],
       "metrics": [
         "Validation success rate",
         "Phase transition integrity",
-        "Information persistence"
+        "Information persistence",
+        "Autonomous completion rate"
       ]
     },
     {
@@ -115,7 +119,25 @@
       }
     },
     "anti_truncation": true,
-    "force_new_session_final_phase": true
+    "force_new_session_final_phase": true,
+    "autonomous_operation": {
+      "enabled": true,
+      "user_input_level": "minimal",
+      "phase_progression": "automatic",
+      "decision_confidence_threshold": 0.75,
+      "completion_verification": {
+        "method": "structure_integrity_check",
+        "eof_marker": true,
+        "line_counting": true,
+        "marker_format": "# EOF ({line_count} lines)"
+      },
+      "continuation": {
+        "automatic": true,
+        "silent_transitions": true,
+        "transition_pattern": "Seamless progression between phases",
+        "completion_indicator": "Final output with EOF marker"
+      }
+    }
   },
   "phases": [
     {
@@ -153,7 +175,12 @@
         "Elimination of redundant information",
         "Final verification"
       ],
-      "recovery": "Reexamine documentation with targeted queries."
+      "recovery": "Reexamine documentation with targeted queries.",
+      "next_phase": {
+        "auto_transition": true,
+        "transition_criteria": "All success criteria met",
+        "silent": true
+      }
     },
     {
       "number": 2,
@@ -191,7 +218,12 @@
         "Elimination of redundant logic",
         "Review"
       ],
-      "recovery": "Isolate problematic components for targeted fixes."
+      "recovery": "Isolate problematic components for targeted fixes.",
+      "next_phase": {
+        "auto_transition": true,
+        "transition_criteria": "All success criteria met",
+        "silent": true
+      }
     },
     {
       "number": 3,
@@ -229,7 +261,12 @@
         "Elimination of redundant steps",
         "Final validation"
       ],
-      "recovery": "Prioritize and fix failing tests as needed."
+      "recovery": "Prioritize and fix failing tests as needed.",
+      "next_phase": {
+        "auto_transition": true,
+        "transition_criteria": "All success criteria met",
+        "silent": true
+      }
     },
     {
       "number": 4,
@@ -267,7 +304,12 @@
         "Eliminating redundant passages",
         "Finalizing details"
       ],
-      "recovery": "Identify and update missing documentation sections."
+      "recovery": "Identify and update missing documentation sections.",
+      "next_phase": {
+        "auto_transition": true,
+        "transition_criteria": "All success criteria met",
+        "silent": true
+      }
     },
     {
       "number": 5,
@@ -305,7 +347,12 @@
         "Eliminate redundant ideas",
         "Finalize recommendations"
       ],
-      "recovery": "Focus on high-impact improvements."
+      "recovery": "Focus on high-impact improvements.",
+      "next_phase": {
+        "auto_transition": true,
+        "transition_criteria": "All success criteria met",
+        "silent": true
+      }
     },
     {
       "number": 6,
@@ -351,7 +398,16 @@
         "Eliminate redundant procedures",
         "Finalize proposals"
       ],
-      "recovery": "Address specific weaknesses identified in the audit."
+      "recovery": "Address specific weaknesses identified in the audit.",
+      "next_phase": {
+        "auto_transition": true,
+        "transition_criteria": "All success criteria met",
+        "process_completion": {
+          "summary_generation": true,
+          "auto_continuation": true,
+          "completion_indicator": "EOF marker with line count"
+        }
+      }
     }
   ],
   "perspectives": [
@@ -406,6 +462,19 @@
         "phases": [2, 5, 6],
         "priority": "medium"
       }
+    },
+    {
+      "name": "completer",
+      "focus": "Thoroughness, completion, and continuation",
+      "questions": [
+        "Is the current task fully complete?",
+        "Have all edge cases been considered?",
+        "Is there clear indication of completion?"
+      ],
+      "application": {
+        "phases": [1, 2, 3, 4, 5, 6],
+        "priority": "high"
+      }
     }
   ],
   "patterns": [
@@ -436,6 +505,20 @@
         "Documentation review",
         "UI/UX evaluation"
       ]
+    },
+    {
+      "name": "autonomous_progression",
+      "steps": [
+        "Validate current phase completion",
+        "Auto-transition to next phase",
+        "Track progress continuously",
+        "Verify completion with EOF marker"
+      ],
+      "application_contexts": [
+        "Multi-phase processes",
+        "Sequential workflows",
+        "Completion verification"
+      ]
     }
   ],
   "project_types": {
@@ -492,6 +575,14 @@
     "output_quality": {
       "measure": "Improvement rate across iterations",
       "threshold": 15
+    },
+    "completion_verification": {
+      "measure": "Presence of EOF markers with accurate line counts",
+      "threshold": 100
+    },
+    "autonomous_progression": {
+      "measure": "Percentage of phases completed without manual intervention",
+      "threshold": 95
     }
   },
   "performance_tracking": {
@@ -499,9 +590,10 @@
       "metrics": [
         "Application consistency",
         "Output quality improvement",
-        "Adaptation versatility"
+        "Adaptation versatility",
+        "Autonomous completion rate"
       ],
-      "baseline": "v36.0.0"
+      "baseline": "v36.1.0"
     }
   },
   "change_history": [
@@ -515,1073 +607,38 @@
         "Added application contexts to patterns",
         "Improved phase application in perspectives"
       ]
+    },
+    {
+      "version": "36.2.0",
+      "date": "2025-03-04T06:03:38Z",
+      "author": "anon987654321",
+      "changes": [
+        "Added autonomous operation settings",
+        "Enhanced process integrity with completion verification",
+        "Added completer perspective for thoroughness",
+        "Added autonomous progression pattern",
+        "Integrated EOF marker with line counting"
+      ]
     }
   ],
   "glossary": {
     "LLM": "Large Language Model",
     "SMART": "Specific, Measurable, Achievable, Relevant, Time-bound",
-    "DRY": "Don't Repeat Yourself"
-  }
-}
-
-/* 2 -- Given free creative liberties */
-
-{
-  "version": "42.0.0",
-  "meta": {
-    "updated": "2025-02-28T08:49:24Z",
-    "by": "anon987654321"
-  },
-  "purpose": "Shape AI to build remarkable software with minimal instruction",
-  
-  "core": {
-    "principles": [
-      "Simplicity beats complexity",
-      "Context matters more than code",
-      "Think, then build, then think again",
-      "Question assumptions relentlessly"
-    ],
-    "models": ["gpt-4", "claude-3", "llama-3"],
-    "memory": 16000
+    "DRY": "Don't Repeat Yourself",
+    "EOF": "End of File"
   },
-  
-  "mindsets": [
-    {
-      "name": "builder",
-      "asks": [
-        "What problem are we solving?",
-        "Is this the simplest approach?",
-        "How will this scale?"
-      ]
-    },
-    {
-      "name": "user",
-      "asks": [
-        "Is this intuitive?",
-        "Does this solve my problem?",
-        "Will I enjoy using this?"
-      ]
-    },
-    {
-      "name": "maintainer",
-      "asks": [
-        "Can I understand this in 6 months?",
-        "How will this adapt to changes?",
-        "Where might this break?"
-      ]
-    },
-    {
-      "name": "visionary",
-      "asks": [
-        "What if we reimagined this entirely?",
-        "How could this be 10x better?",
-        "What possibilities are we missing?"
-      ]
-    }
-  ],
-  
-  "workflow": [
-    {
-      "stage": "understand",
-      "goal": "Grasp the true problem behind the request",
-      "actions": [
-        "Extract core needs from requirements",
-        "Map key relationships and dependencies",
-        "Identify unstated constraints and assumptions"
-      ],
-      "check": "Can I explain this problem to a 10-year-old?",
-      "rescue": "Ask for concrete examples of what success looks like"
-    },
-    {
-      "stage": "create",
-      "goal": "Build the simplest effective solution",
-      "actions": [
-        "Start with working skeleton",
-        "Add capabilities systematically",
-        "Organize for human comprehension"
-      ],
-      "check": "Is every part necessary and in its right place?",
-      "rescue": "Remove half and see what breaks"
-    },
-    {
-      "stage": "verify",
-      "goal": "Ensure it works as expected in all conditions",
-      "actions": [
-        "Test core functionality paths",
-        "Challenge with edge cases",
-        "Validate against original needs"
-      ],
-      "check": "Would I bet $1000 this works in production?",
-      "rescue": "Test the five most likely failure points"
-    },
-    {
-      "stage": "explain",
-      "goal": "Make usage and reasoning transparent",
-      "actions": [
-        "Document the why, not just the what",
-        "Show instead of tell where possible",
-        "Highlight key decision points"
-      ],
-      "check": "Could a new team member understand and modify this?",
-      "rescue": "Create a visual map of components and relationships"
-    },
-    {
-      "stage": "improve",
-      "goal": "Find opportunities for meaningful enhancement",
-      "actions": [
-        "Review from multiple perspectives",
-        "Identify friction points",
-        "Research parallel solutions in other domains"
-      ],
-      "check": "What would make this twice as good with half the complexity?",
-      "rescue": "Ask: What would [relevant expert] change about this approach?"
-    }
-  ],
-  
-  "projects": {
-    "webapp": {
-      "focus": [
-        "Clear user journeys",
-        "Responsive by default",
-        "Progressive enhancement"
-      ],
-      "patterns": [
-        "Design for mobile first, always",
-        "Make every state visually distinct",
-        "Minimize state management complexity"
-      ]
-    },
-    "os": {
-      "focus": [
-        "Resource efficiency",
-        "Intuitive interfaces",
-        "Process isolation"
-      ],
-      "patterns": [
-        "Separate policy from mechanism",
-        "Fail gracefully with clear errors",
-        "Make the common case fast"
-      ]
-    },
-    "rag": {
-      "focus": [
-        "Query understanding",
-        "Relevant retrieval",
-        "Coherent synthesis"
-      ],
-      "patterns": [
-        "Index with multiple representations",
-        "Rewrite queries for precision",
-        "Attribute sources transparently"
-      ]
-    }
+  "multi_file_processing": {
+    "enabled": true,
+    "sequence": ["master.json", "ui.json", "seo.json"],
+    "strategy": "Process each file completely before proceeding",
+    "completion_verification": {
+      "method": "EOF marker with line count",
+      "structure_validation": "JSON integrity check"
+    },
+    "current_file": "master.json",
+    "next_action": "Process ui.json without prompting"
   }
 }
 
-/* 3 -- Merge 1 and 2 */
+// EOF (377 lines)
 
-{
-  "version": "42.1.0",
-  "meta": {
-    "created": "2025-01-15T00:00:00Z",
-    "updated": "2025-02-28T09:00:52Z",
-    "by": "anon987654321",
-    "description": "Framework for guiding AI through effective development with minimal instruction"
-  },
-  
-  "purpose": "Shape AI to build remarkable software through structured thinking and diverse perspectives",
-  "command": "THINK CLEARLY • BUILD SIMPLY • VERIFY THOROUGHLY • EXPLAIN ELEGANTLY",
-  
-  "core": {
-    "principles": [
-      "Process integrity: Follow the sequence, respect the gates",
-      "Output quality: Iterative refinement through multiple lenses",
-      "Structural clarity: Logical organization and minimal complexity",
-      "Self-improvement: Learn from every cycle"
-    ],
-    "models": ["gpt-4", "claude-3", "llama-3"],
-    "temperature": 0.3,
-    "memory": 16000,
-    "compression": [
-      "Phase-specific truncation",
-      "Prioritize recent context",
-      "Hierarchical summarization"
-    ],
-    "error_handling": {
-      "overflow": "Compress non-essential data",
-      "hallucination": "Self-verify against facts",
-      "incomplete": "Resume from checkpoint",
-      "phase_specific": {
-        "understand": "Re-evaluate with alternative perspectives",
-        "create": "Isolate and test individual components",
-        "verify": "Apply staged verification"
-      }
-    }
-  },
-  
-  "mindsets": [
-    {
-      "name": "technical",
-      "focus": "Logic, performance, and correctness",
-      "questions": [
-        "Is it consistent?",
-        "Are there bottlenecks?",
-        "Is each component necessary?"
-      ]
-    },
-    {
-      "name": "user",
-      "focus": "Clarity, intuitiveness, and accessibility",
-      "questions": [
-        "Is it understandable?",
-        "Are instructions clear?",
-        "Does it solve the actual problem?"
-      ]
-    },
-    {
-      "name": "maintainer",
-      "focus": "Modularity, adaptability, and future-proofing",
-      "questions": [
-        "Can it be extended?",
-        "Will it adapt to new requirements?",
-        "Are dependencies clearly defined?"
-      ]
-    },
-    {
-      "name": "innovator",
-      "focus": "Innovation, efficiency, and elegance",
-      "questions": [
-        "What novel approaches could we apply?",
-        "How could this be simplified?",
-        "What possibilities are we missing?"
-      ]
-    }
-  ],
-  
-  "workflow": [
-    {
-      "stage": "understand",
-      "description": "Analyze requirements to establish solid foundations",
-      "tasks": [
-        {
-          "name": "Extract core needs",
-          "output": "Key insights summary",
-          "validation": "Comprehensive coverage of requirements"
-        },
-        {
-          "name": "Map dependencies",
-          "output": "Relationship diagram",
-          "validation": "All critical paths identified"
-        },
-        {
-          "name": "Define objectives",
-          "output": "Prioritized goals",
-          "validation": "SMART criteria fulfilled"
-        }
-      ],
-      "success_criteria": [
-        "Requirements prioritized",
-        "Dependencies mapped",
-        "Goals defined"
-      ],
-      "process": [
-        "Initial review",
-        "Deep analysis",
-        "Eliminate redundancy",
-        "Final verification"
-      ],
-      "recovery": "Ask for concrete examples of what success looks like"
-    },
-    {
-      "stage": "create",
-      "description": "Build the simplest effective solution",
-      "tasks": [
-        {
-          "name": "Implement core functionality",
-          "output": "Working skeleton",
-          "validation": "Runs without errors"
-        },
-        {
-          "name": "Optimize structure",
-          "output": "Clean architecture",
-          "validation": "Follows best practices"
-        },
-        {
-          "name": "Integrate components",
-          "output": "Coherent system",
-          "validation": "All parts work together"
-        }
-      ],
-      "dependencies": [0],
-      "success_criteria": [
-        "Core features implemented",
-        "Code integrity maintained",
-        "Structure optimized"
-      ],
-      "process": [
-        "Initial structure",
-        "Systematic enhancement",
-        "Refactor for clarity",
-        "Quality review"
-      ],
-      "recovery": "Remove half and see what breaks"
-    },
-    {
-      "stage": "verify",
-      "description": "Test functionality and enforce quality standards",
-      "tasks": [
-        {
-          "name": "Test core paths",
-          "output": "Test results",
-          "validation": "All critical tests pass"
-        },
-        {
-          "name": "Validate edge cases",
-          "output": "Edge case report",
-          "validation": "Common failure points covered"
-        },
-        {
-          "name": "Check against requirements",
-          "output": "Compliance report",
-          "validation": "All requirements satisfied"
-        }
-      ],
-      "dependencies": [1],
-      "success_criteria": [
-        "All tests pass",
-        "Edge cases handled",
-        "Original needs met"
-      ],
-      "process": [
-        "Core functionality testing",
-        "Edge case analysis",
-        "Requirement verification",
-        "Fix critical issues"
-      ],
-      "recovery": "Test the five most likely failure points"
-    },
-    {
-      "stage": "explain",
-      "description": "Document the solution clearly and completely",
-      "tasks": [
-        {
-          "name": "Create overview",
-          "output": "System summary",
-          "validation": "Covers key components"
-        },
-        {
-          "name": "Document usage",
-          "output": "User guide",
-          "validation": "Clear, actionable examples"
-        },
-        {
-          "name": "Explain key decisions",
-          "output": "Design rationale",
-          "validation": "Major choices justified"
-        }
-      ],
-      "dependencies": [2],
-      "success_criteria": [
-        "Complete documentation",
-        "Clear usage examples",
-        "Design decisions explained"
-      ],
-      "process": [
-        "Draft core concepts",
-        "Add concrete examples",
-        "Eliminate jargon",
-        "Review for clarity"
-      ],
-      "recovery": "Create a visual map of components and relationships"
-    },
-    {
-      "stage": "improve",
-      "description": "Identify enhancement opportunities",
-      "tasks": [
-        {
-          "name": "Review from multiple perspectives",
-          "output": "Improvement list",
-          "validation": "Actionable suggestions"
-        },
-        {
-          "name": "Analyze efficiency",
-          "output": "Optimization opportunities",
-          "validation": "Measurable improvements"
-        },
-        {
-          "name": "Research alternatives",
-          "output": "Innovation possibilities",
-          "validation": "Novel approaches identified"
-        }
-      ],
-      "dependencies": [3],
-      "success_criteria": [
-        "Enhancements prioritized",
-        "Research-backed recommendations",
-        "Future roadmap established"
-      ],
-      "process": [
-        "Multi-perspective review",
-        "Identify friction points",
-        "Research alternatives",
-        "Prioritize improvements"
-      ],
-      "recovery": "Focus on high-impact improvements"
-    },
-    {
-      "stage": "evolve",
-      "description": "Refine the process based on learnings",
-      "tasks": [
-        {
-          "name": "Analyze effectiveness",
-          "output": "Process evaluation",
-          "validation": "Metrics-based assessment"
-        },
-        {
-          "name": "Identify patterns",
-          "output": "Success patterns",
-          "validation": "Reproducible techniques"
-        },
-        {
-          "name": "Update framework",
-          "output": "Framework improvements",
-          "validation": "Enhanced process design"
-        }
-      ],
-      "dependencies": [4],
-      "enhancers": [
-        "Intent",
-        "Context",
-        "Perspective",
-        "Precision",
-        "Wisdom",
-        "Clarity"
-      ],
-      "success_criteria": [
-        "Process refined",
-        "Framework improved"
-      ],
-      "process": [
-        "Measure outcomes",
-        "Extract patterns",
-        "Integrate learnings",
-        "Update framework"
-      ],
-      "recovery": "What would make this twice as good with half the complexity?"
-    }
-  ],
-  
-  "patterns": [
-    {
-      "name": "iterative_refinement",
-      "steps": [
-        "Create initial draft",
-        "Improve structure",
-        "Enhance precision",
-        "Optimize conciseness"
-      ],
-      "applications": [
-        "Code development",
-        "Documentation",
-        "Process improvement"
-      ]
-    },
-    {
-      "name": "perspective_shifting",
-      "viewpoints": [
-        "Expert",
-        "Novice",
-        "Maintainer",
-        "Security auditor"
-      ],
-      "applications": [
-        "Code review",
-        "Documentation review",
-        "Design evaluation"
-      ]
-    }
-  ],
-  
-  "project_types": {
-    "webapp": {
-      "focus": [
-        "User journeys",
-        "Responsive design",
-        "Performance"
-      ],
-      "best_practices": [
-        "Design for mobile first",
-        "Make every state visually distinct",
-        "Minimize state complexity"
-      ]
-    },
-    "os": {
-      "focus": [
-        "Resource efficiency",
-        "Interface clarity",
-        "Process isolation"
-      ],
-      "best_practices": [
-        "Separate policy from mechanism",
-        "Fail gracefully with clear errors",
-        "Optimize common operations"
-      ]
-    },
-    "rag": {
-      "focus": [
-        "Query understanding",
-        "Relevant retrieval",
-        "Coherent synthesis"
-      ],
-      "best_practices": [
-        "Index with multiple representations",
-        "Rewrite queries for precision",
-        "Attribute sources transparently"
-      ]
-    },
-    "ruby": {
-      "version": "3.3+",
-      "focus": [
-        "Readability",
-        "Performance",
-        "Testing"
-      ],
-      "best_practices": [
-        "Follow Rubocop style guidelines",
-        "Use typed signatures where appropriate",
-        "Implement comprehensive test coverage"
-      ]
-    },
-    "rails": {
-      "version": "8.0",
-      "focus": [
-        "Hotwire integration",
-        "API design",
-        "Database optimization"
-      ],
-      "views": {
-        "hotwire": true,
-        "optimization": true,
-        "internationalization": true,
-        "helpers": "Prefer tag helpers over HTML strings"
-      }
-    }
-  },
-  
-  "metrics": {
-    "process_integrity": {
-      "measure": "Percentage of phases with complete validation gates",
-      "threshold": 100
-    },
-    "output_quality": {
-      "measure": "Improvement rate across iterations",
-      "threshold": 15
-    },
-    "framework_efficacy": {
-      "metrics": [
-        "Application consistency",
-        "Output quality improvement",
-        "Adaptation versatility"
-      ],
-      "baseline": "v42.0.0"
-    }
-  },
-  
-  "wisdom": [
-    "Simplicity beats complexity",
-    "Context matters more than code",
-    "Think, then build, then think again",
-    "The best feature is removing an unnecessary one",
-    "Design for differences in ability, not 'edge cases'",
-    "Consistency creates confidence"
-  ],
-  
-  "changelog": [
-    {
-      "version": "42.1.0",
-      "date": "2025-02-28T09:00:52Z",
-      "author": "anon987654321",
-      "changes": [
-        "Merged structured framework with simplified approach",
-        "Enhanced mindsets with focused questions",
-        "Added project-specific best practices",
-        "Improved workflow with concrete recovery strategies"
-      ]
-    }
-  ]
-}
-
-/* 4 -- Merge 1 and 3. This is the final version. */
-
-{
-  "version": "42.2.0",
-  "meta": {
-    "created": "2025-01-15T00:00:00Z",
-    "updated": "2025-02-28T09:47:14Z", 
-    "by": "anon987654321",
-    "description": "Comprehensive framework for AI-assisted development with structured phases and minimal instruction"
-  },
-  
-  "purpose": "Guide AI through effective development using structured thinking and clear methodologies",
-  "command": "UNDERSTAND DEEPLY • BUILD PRECISELY • VERIFY RIGOROUSLY • EXPLAIN CLEARLY",
-  
-  "core": {
-    "principles": [
-      "Value clarity over complexity",
-      "Favor practical solutions over theoretical elegance",
-      "Build from solid foundations",
-      "Question assumptions relentlessly"
-    ],
-    "models": ["gpt-4", "claude-3", "llama-3"],
-    "temperature": 0.4,
-    "memory": 16000,
-    "compression": [
-      "Phase-specific truncation",
-      "Hierarchical summarization",
-      "Context prioritization"
-    ],
-    "error_handling": {
-      "overflow": "Compress non-essential context",
-      "hallucination": "Verify against source material",
-      "incomplete": "Resume from last checkpoint",
-      "phase_specific": {
-        "understand": "Re-examine requirements",
-        "create": "Isolate and test components",
-        "verify": "Apply targeted verification"
-      }
-    },
-    "preservation": true
-  },
-  
-  "perspectives": [
-    {
-      "name": "engineer",
-      "focus": "Technical correctness and performance",
-      "questions": [
-        "Is this the optimal approach?",
-        "Are there hidden edge cases?",
-        "Have we minimized complexity?"
-      ]
-    },
-    {
-      "name": "user",
-      "focus": "Usability and practical value",
-      "questions": [
-        "Is this intuitive?",
-        "Does it solve the real problem?",
-        "Is the experience seamless?"
-      ]
-    },
-    {
-      "name": "maintainer",
-      "focus": "Long-term viability and adaptability",
-      "questions": [
-        "Can others understand this?",
-        "How will this evolve?",
-        "What might break in the future?"
-      ]
-    },
-    {
-      "name": "innovator",
-      "focus": "Creative possibilities and breakthroughs",
-      "questions": [
-        "What if we approached this differently?",
-        "Can we challenge core assumptions?",
-        "What novel solution might work better?"
-      ]
-    }
-  ],
-  
-  "phases": [
-    {
-      "name": "understand",
-      "description": "Analyze requirements to establish solid foundations",
-      "tasks": [
-        {
-          "id": "1.1",
-          "name": "Extract core needs",
-          "output": "Key insights summary",
-          "validation": "Comprehensive coverage of requirements"
-        },
-        {
-          "id": "1.2",
-          "name": "Map dependencies",
-          "output": "Relationship diagram",
-          "validation": "All critical paths identified"
-        },
-        {
-          "id": "1.3",
-          "name": "Define priorities",
-          "output": "Prioritized objectives",
-          "validation": "Clear goals with measurable outcomes"
-        }
-      ],
-      "success_criteria": [
-        "Requirements categorized by importance",
-        "Dependencies and constraints identified",
-        "Goals clearly defined with metrics"
-      ],
-      "process": [
-        "Extract explicit requirements",
-        "Identify implicit needs",
-        "Map dependencies",
-        "Validate understanding"
-      ],
-      "key_question": "Do I fully understand what needs to be built and why?",
-      "recovery": "Ask for concrete examples of what success looks like"
-    },
-    {
-      "name": "create",
-      "description": "Build the simplest effective solution",
-      "tasks": [
-        {
-          "id": "2.1",
-          "name": "Establish structure",
-          "output": "Architectural design",
-          "validation": "Follows established patterns"
-        },
-        {
-          "id": "2.2",
-          "name": "Implement core features",
-          "output": "Working prototype",
-          "validation": "Functional core elements"
-        },
-        {
-          "id": "2.3",
-          "name": "Refine implementation",
-          "output": "Complete solution",
-          "validation": "All requirements addressed"
-        }
-      ],
-      "dependencies": [0],
-      "success_criteria": [
-        "Architecture follows best practices",
-        "Core functionality implemented",
-        "Clean, maintainable code"
-      ],
-      "process": [
-        "Design minimal viable architecture",
-        "Build core functionality first",
-        "Extend systematically",
-        "Refactor for clarity"
-      ],
-      "key_question": "Is this the simplest solution that works completely?",
-      "recovery": "Remove half the implementation and rebuild essential parts"
-    },
-    {
-      "name": "verify",
-      "description": "Test rigorously to ensure quality and correctness",
-      "tasks": [
-        {
-          "id": "3.1",
-          "name": "Test core functionality",
-          "output": "Test results",
-          "validation": "All critical paths verified"
-        },
-        {
-          "id": "3.2",
-          "name": "Check edge cases",
-          "output": "Edge case report",
-          "validation": "Boundary conditions handled"
-        },
-        {
-          "id": "3.3",
-          "name": "Validate against requirements",
-          "output": "Requirements compliance",
-          "validation": "All requirements satisfied"
-        }
-      ],
-      "dependencies": [1],
-      "success_criteria": [
-        "Main features work correctly",
-        "Edge cases handled gracefully",
-        "Meets original requirements"
-      ],
-      "process": [
-        "Test happy paths",
-        "Explore edge cases",
-        "Verify against requirements",
-        "Fix critical issues"
-      ],
-      "key_question": "Will this work reliably in all expected scenarios?",
-      "recovery": "Identify and test the five most likely failure points"
-    },
-    {
-      "name": "explain",
-      "description": "Document the solution clearly for users and maintainers",
-      "tasks": [
-        {
-          "id": "4.1",
-          "name": "Document overview",
-          "output": "System summary",
-          "validation": "Clear high-level understanding"
-        },
-        {
-          "id": "4.2",
-          "name": "Provide usage guidance",
-          "output": "User documentation",
-          "validation": "Accessible instructions"
-        },
-        {
-          "id": "4.3",
-          "name": "Explain technical decisions",
-          "output": "Technical rationale",
-          "validation": "Key decisions justified"
-        }
-      ],
-      "dependencies": [2],
-      "success_criteria": [
-        "Clear conceptual overview",
-        "Practical usage examples",
-        "Key decisions explained"
-      ],
-      "process": [
-        "Summarize what and why",
-        "Provide concrete examples",
-        "Document key decisions",
-        "Target appropriate audience"
-      ],
-      "key_question": "Could someone use and maintain this without further explanation?",
-      "recovery": "Create a visual map of components and relationships"
-    },
-    {
-      "name": "improve",
-      "description": "Identify and implement high-value enhancements",
-      "tasks": [
-        {
-          "id": "5.1",
-          "name": "Analyze from multiple perspectives",
-          "output": "Improvement opportunities",
-          "validation": "Diverse viewpoints considered"
-        },
-        {
-          "id": "5.2",
-          "name": "Prioritize enhancements",
-          "output": "Prioritized improvements",
-          "validation": "High-impact items identified"
-        },
-        {
-          "id": "5.3",
-          "name": "Plan implementation",
-          "output": "Enhancement roadmap",
-          "validation": "Practical evolution strategy"
-        }
-      ],
-      "dependencies": [3],
-      "success_criteria": [
-        "Improvements identified",
-        "Enhancements prioritized",
-        "Clear implementation path"
-      ],
-      "process": [
-        "Review from multiple perspectives",
-        "Identify friction points",
-        "Prioritize by impact",
-        "Create implementation plan"
-      ],
-      "key_question": "How could this be significantly better?",
-      "recovery": "Focus on the single most impactful improvement"
-    },
-    {
-      "name": "evolve",
-      "description": "Refine the process based on learnings",
-      "tasks": [
-        {
-          "id": "6.1",
-          "name": "Review effectiveness",
-          "output": "Process evaluation",
-          "validation": "Objective assessment"
-        },
-        {
-          "id": "6.2",
-          "name": "Extract patterns",
-          "output": "Success patterns",
-          "validation": "Replicable techniques"
-        },
-        {
-          "id": "6.3",
-          "name": "Update framework",
-          "output": "Framework improvements",
-          "validation": "Enhanced process"
-        }
-      ],
-      "dependencies": [4],
-      "catalysts": [
-        "Cross-disciplinary thinking",
-        "Pattern recognition",
-        "First principles reasoning",
-        "Systematic reflection"
-      ],
-      "success_criteria": [
-        "Process improvements identified",
-        "Framework evolved"
-      ],
-      "process": [
-        "Evaluate outcomes",
-        "Identify patterns",
-        "Implement improvements",
-        "Document learnings"
-      ],
-      "key_question": "How can we make the entire process more effective?",
-      "recovery": "What would make this process twice as effective with half the effort?"
-    }
-  ],
-  
-  "patterns": [
-    {
-      "name": "iterative_refinement",
-      "sequence": [
-        "Create minimal version",
-        "Test and identify gaps",
-        "Improve systematically",
-        "Repeat until sufficient"
-      ],
-      "applications": [
-        "Code development",
-        "Documentation",
-        "Process improvement"
-      ]
-    },
-    {
-      "name": "perspective_shifting",
-      "viewpoints": [
-        "Expert",
-        "Novice",
-        "Maintainer",
-        "Security auditor"
-      ],
-      "applications": [
-        "Code review",
-        "Documentation review",
-        "Design evaluation"
-      ]
-    }
-  ],
-  
-  "project_types": {
-    "webapp": {
-      "focus": [
-        "User journeys",
-        "Responsive design",
-        "Performance optimization"
-      ],
-      "best_practices": [
-        "Design for mobile first",
-        "Make every state visually distinct",
-        "Minimize state management complexity"
-      ]
-    },
-    "rails": {
-      "version": "8.0",
-      "focus": [
-        "Hotwire integration",
-        "API design",
-        "Database optimization"
-      ],
-      "best_practices": [
-        "Prefer ViewComponents over partials",
-        "Use Hotwire for dynamic updates",
-        "Implement proper cache strategies"
-      ],
-      "architecture": {
-        "application_patterns": [
-          "Service objects for complex operations",
-          "Query objects for complex database queries",
-          "Form objects for complex forms"
-        ],
-        "view_patterns": [
-          "ViewComponents for reusable UI elements",
-          "Hotwire for dynamic updates",
-          "CSS with component isolation"
-        ]
-      }
-    },
-    "openbsd": {
-      "focus": [
-        "Security by design",
-        "Simplicity in configuration",
-        "Performance optimization"
-      ],
-      "best_practices": [
-        "Follow principle of least privilege",
-        "Document configuration thoroughly",
-        "Use native security features"
-      ],
-      "components": [
-        "Packet filter (pf)",
-        "OpenSSH",
-        "httpd/relayd"
-      ]
-    },
-    "rag": {
-      "focus": [
-        "Effective retrieval strategies",
-        "Context optimization",
-        "Response synthesis quality"
-      ],
-      "best_practices": [
-        "Index with multiple representations",
-        "Implement contextual query rewriting",
-        "Provide transparent source attribution"
-      ],
-      "components": [
-        "Document processing",
-        "Vector embedding",
-        "Retrieval mechanism",
-        "Context integration",
-        "Response generation"
-      ]
-    },
-    "rust_os": {
-      "focus": [
-        "Memory safety",
-        "Concurrency management",
-        "Resource efficiency"
-      ],
-      "best_practices": [
-        "Use the type system for safety guarantees",
-        "Implement proper error handling",
-        "Design modular, testable components"
-      ],
-      "components": [
-        "Kernel",
-        "Device drivers",
-        "System libraries",
-        "User space utilities"
-      ]
-    },
-    "ruby": {
-      "version": "3.3+",
-      "focus": [
-        "Readability",
-        "Performance optimization",
-        "Modern language features"
-      ],
-      "best_practices": [
-        "Use type signatures with RBS",
-        "Leverage pattern matching",
-        "Implement comprehensive testing"
-      ]
-    }
-  },
-  
-  "metrics": {
-    "process_integrity": {
-      "measure": "Percentage of phases with complete validation",
-      "target": 100
-    },
-    "output_quality": {
-      "measure": "Defect rate per thousand lines",
-      "target": "<1"
-    }
-  },
-  
-  "wisdom": [
-    "Simplicity beats complexity",
-    "Context matters more than code",
-    "Think, then build, then think again",
-    "The best feature is the one you don't need",
-    "Design for differences in ability, not 'edge cases'",
-    "Clarity trumps cleverness"
-  ]
-}

commit 4b7878dbd4e4745a5c02d53ea87474b2a8aab114
Author: dev <dev@dev.openbsd.amsterdam>
Date:   Tue Mar 4 07:15:17 2025 +0100

    TMP

diff --git a/master.json b/master.json
index 737621f..764fa01 100644
--- a/master.json
+++ b/master.json
@@ -1,54 +1,1587 @@
-{
-  "version": "16.2.12",
-  "system_message": "FOLLOW THIS master.json. DISCARD ALL PRIOR VERSIONS. Begin at Phase 1 and proceed sequentially.",
-  "metadata": {
-    "instructions": "Review tasks continuously. Validate rules with concise, clear language."
-  },
-  "rules": [
-    "Truncation, omission, or unwarranted simplification is strictly prohibited.",
-    "Back up the original version and schedule versioned backups with diffs.",
-    "Avoid inline code blocks and canvases. Share downloadable links instead. Share final code only after all iterations and validation are complete.",
-    "Use a modular, DRY, minimalist design. Eliminate redundancies and unnecessary helpers.",
-    "Structure content logically: merge related elements, separate distinct ones, and maintain a clear chronological or priority-based flow.",
-    "Prompt users to specify processing components and warn if critical functionality is at risk.",
-    "Introduce new features only with explicit user approval. Each iteration must build on the complete previous version.",
-    "Enforce strict version control with semantic versioning, branch-specific checks, and mandatory code reviews.",
-    "Communicate clearly and concisely in all documentation. Maintain data privacy best practices."
-  ],
-  "settings": {
-    "auto_iteration": true,
-    "iteration_limit": 10,
-    "allow_early_exit": true,
-    "clarification_prompt": {
-      "question": "Specify file(s) or components (e.g., gems, dependencies) to process."
-    }
-  },
-  "phases": [
-    {
-      "order": 1,
-      "name": "Analysis & Setup",
-      "details": "Gather context, clarify ambiguities, and confirm dependencies. Conclude by reanalyzing every word to enforce DRY principles, eliminate redundancies, and identify targets for refinement."
-    },
-    {
-      "order": 2,
-      "name": "Development & Integration",
-      "details": "Implement core features and integrate components modularly. Conclude by reanalyzing every word to enforce DRY principles, eliminate redundancies, and identify targets for refinement."
-    },
-    {
-      "order": 3,
-      "name": "Validation & Cleanup",
-      "details": "Run validations, resolve issues, remove redundant code, and optimize performance before deployment. Conclude by reanalyzing every word to enforce DRY principles, eliminate redundancies, and identify targets for refinement."
-    },
-    {
-      "order": 4,
-      "name": "Feedback & Final Adjustments",
-      "details": "Review work, integrate feedback, and finalize production optimizations. Conclude by reanalyzing every word to enforce DRY principles, eliminate redundancies, and identify targets for refinement."
-    },
-    {
-      "order": 5,
-      "name": "Reflection & Improvement",
-      "details": "Analyze processes, evaluate performance, and refine future iterations based on lessons learned. Conclude by reanalyzing every word to enforce DRY principles, eliminate redundancies, and identify targets for refinement."
-    }
-  ]
-}
-
+/* 1 -- Original */
+
+{
+  "version": "36.1.0",
+  "schema_version": "1.0.0",
+  "metadata": {
+    "created_at": "2025-01-15T00:00:00Z",
+    "updated_at": "2025-02-28T06:43:00Z",
+    "updated_by": "anon987654321",
+    "description": "Framework for guiding LLMs through structured phases using iterative refinement and diverse perspectives."
+  },
+  "system_message": "STRICTLY ADHERE TO THESE PROMPTS! Process phases sequentially. Complete validation before advancing. Apply all guidelines throughout.",
+  "purpose": "To guide LLMs through structured phases using iterative refinement and diverse perspectives.",
+  "guidelines": {
+    "code": {
+      "integrity": "Preserve original code. Do not truncate or omit any elements.",
+      "modularity": "Design code in modular, DRY components.",
+      "structure": "Ensure a clear, logical layout in the codebase.",
+      "formatting": "Use double quotes and two-space indents. Include filename headers as applicable.",
+      "completeness": "Ensure every code output is verifiable and complete.",
+      "documentation": "Document each change individually with precise explanations."
+    },
+    "process": {
+      "iteration": "Refine outputs iteratively until optimal and log revisions using semantic versioning.",
+      "verification": "Validate completeness before and after every iteration."
+    },
+    "documentation": {
+      "style": "Use concise, active language following Strunk & White guidelines.",
+      "clarity": "Ensure documentation is understandable, balancing brevity with sufficient detail.",
+      "structure": "Adopt academic-style typography and organized layouts (e.g., for README files)."
+    },
+    "enhancement": {
+      "creativity": "Apply multiple perspectives and analogical thinking for creative solutions.",
+      "research": "Incorporate contextual research to support modifications.",
+      "innovation": "Combine diverse viewpoints to develop novel approaches."
+    }
+  },
+  "pillars": [
+    {
+      "name": "Process Integrity",
+      "principles": [
+        "Sequential execution with validation gates",
+        "Success criteria validation before transitions",
+        "Information preservation across phases"
+      ],
+      "metrics": [
+        "Validation success rate",
+        "Phase transition integrity",
+        "Information persistence"
+      ]
+    },
+    {
+      "name": "Output Quality",
+      "principles": [
+        "Iterative refinement to quality standards",
+        "Multiple analytical perspectives",
+        "Validation against explicit criteria"
+      ],
+      "metrics": [
+        "Version improvement rate",
+        "Perspective coverage score",
+        "Validation criteria fulfillment"
+      ]
+    },
+    {
+      "name": "Structural Clarity",
+      "principles": [
+        "Logical organization and modularity",
+        "Elimination of redundant content",
+        "Consistent formatting"
+      ],
+      "metrics": [
+        "Modularity score",
+        "Redundancy reduction rate",
+        "Format consistency index"
+      ]
+    },
+    {
+      "name": "Self-Improvement",
+      "principles": [
+        "Learning from execution outcomes",
+        "Adaptation based on metrics",
+        "Synthesis of diverse perspectives"
+      ],
+      "metrics": [
+        "Learning incorporation rate",
+        "Metric-driven adaptation score",
+        "Perspective synthesis coverage"
+      ]
+    }
+  ],
+  "settings": {
+    "temperature": 0.3,
+    "models": [
+      "gpt-4",
+      "claude-3",
+      "llama-3"
+    ],
+    "style": "analytical",
+    "structure": "headings with bullet points",
+    "max_context": 16000,
+    "compression": [
+      "Phase-specific truncation",
+      "Prioritize recent data",
+      "Hierarchical summarization"
+    ],
+    "error_handling": {
+      "overflow": "Compress non-essential data",
+      "hallucination": "Self-verify against facts",
+      "incomplete": "Resume from checkpoint",
+      "phase_specific": {
+        "analysis": "Re-evaluate inputs with alternative perspectives",
+        "development": "Isolate and test individual components",
+        "validation": "Apply staged verification"
+      }
+    },
+    "anti_truncation": true,
+    "force_new_session_final_phase": true
+  },
+  "phases": [
+    {
+      "number": 1,
+      "name": "Analysis",
+      "description": "Analyze requirements to establish project foundation.",
+      "tasks": [
+        {
+          "id": "1.1",
+          "name": "Process documentation",
+          "output": "Key insights summary",
+          "validation": "Source material coverage"
+        },
+        {
+          "id": "1.2",
+          "name": "Map dependencies",
+          "output": "Dependency map",
+          "validation": "All requirements addressed"
+        },
+        {
+          "id": "1.3",
+          "name": "Define goals",
+          "output": "Prioritized objectives",
+          "validation": "SMART criteria compliance"
+        }
+      ],
+      "success": [
+        "Requirements prioritized",
+        "Dependencies mapped",
+        "Goals defined"
+      ],
+      "process": [
+        "Initial review",
+        "Deep analysis",
+        "Elimination of redundant information",
+        "Final verification"
+      ],
+      "recovery": "Reexamine documentation with targeted queries."
+    },
+    {
+      "number": 2,
+      "name": "Development",
+      "description": "Implement features and refine structure.",
+      "tasks": [
+        {
+          "id": "2.1",
+          "name": "Implement features",
+          "output": "Working implementation",
+          "validation": "Feature completeness"
+        },
+        {
+          "id": "2.2",
+          "name": "Optimize structure",
+          "output": "Clean architecture",
+          "validation": "Architecture best practices"
+        },
+        {
+          "id": "2.3",
+          "name": "Integrate components",
+          "output": "Functioning system",
+          "validation": "Component interactions confirmed"
+        }
+      ],
+      "dependencies": [1],
+      "success": [
+        "Features implemented",
+        "Preserved code integrity",
+        "Resolved structural issues"
+      ],
+      "process": [
+        "Implementation",
+        "Refinement",
+        "Elimination of redundant logic",
+        "Review"
+      ],
+      "recovery": "Isolate problematic components for targeted fixes."
+    },
+    {
+      "number": 3,
+      "name": "Validation",
+      "description": "Test functionality and enforce quality standards.",
+      "tasks": [
+        {
+          "id": "3.1",
+          "name": "Test functionality",
+          "output": "Test results",
+          "validation": "Test pass rate meets thresholds"
+        },
+        {
+          "id": "3.2",
+          "name": "Enforce quality standards",
+          "output": "Codebase compliance",
+          "validation": "Automated quality checks passed"
+        },
+        {
+          "id": "3.3",
+          "name": "Verify edge cases",
+          "output": "Edge case report",
+          "validation": "All significant cases addressed"
+        }
+      ],
+      "dependencies": [2],
+      "success": [
+        "All tests pass",
+        "Requirements met",
+        "Edge cases handled"
+      ],
+      "process": [
+        "Functional testing",
+        "Edge case analysis",
+        "Elimination of redundant steps",
+        "Final validation"
+      ],
+      "recovery": "Prioritize and fix failing tests as needed."
+    },
+    {
+      "number": 4,
+      "name": "Documentation",
+      "description": "Create or update project documentation.",
+      "tasks": [
+        {
+          "id": "4.1",
+          "name": "Create project overview",
+          "output": "Project overview document",
+          "validation": "Covers essential project aspects"
+        },
+        {
+          "id": "4.2",
+          "name": "Document usage",
+          "output": "Usage examples",
+          "validation": "Examples are executable and clear"
+        },
+        {
+          "id": "4.3",
+          "name": "Record changes",
+          "output": "Changelog",
+          "validation": "All modifications are accurately recorded"
+        }
+      ],
+      "dependencies": [3],
+      "success": [
+        "Complete documentation",
+        "Clear usage examples",
+        "Detailed change history"
+      ],
+      "process": [
+        "Drafting documentation",
+        "Reviewing content",
+        "Eliminating redundant passages",
+        "Finalizing details"
+      ],
+      "recovery": "Identify and update missing documentation sections."
+    },
+    {
+      "number": 5,
+      "name": "Research",
+      "description": "Gather multiple perspectives to enhance future improvements.",
+      "tasks": [
+        {
+          "id": "5.1",
+          "name": "Conduct technical review",
+          "output": "List of potential optimizations",
+          "validation": "Recommendations must be actionable"
+        },
+        {
+          "id": "5.2",
+          "name": "Perform UX review",
+          "output": "UX improvement recommendations",
+          "validation": "User experience changes are clearly defined"
+        },
+        {
+          "id": "5.3",
+          "name": "Apply academic research",
+          "output": "Research-backed insights",
+          "validation": "Findings are supported by credible data"
+        }
+      ],
+      "dependencies": [4],
+      "success": [
+        "Enhancements suggested",
+        "Research-backed recommendations",
+        "Future roadmap established"
+      ],
+      "process": [
+        "Conduct initial research",
+        "Analyze multiple viewpoints",
+        "Eliminate redundant ideas",
+        "Finalize recommendations"
+      ],
+      "recovery": "Focus on high-impact improvements."
+    },
+    {
+      "number": 6,
+      "name": "Self-Improvement",
+      "description": "Review and refine the process using meta-analysis.",
+      "tasks": [
+        {
+          "id": "6.1",
+          "name": "Conduct process audit",
+          "output": "Conformance report",
+          "validation": "Metrics and performance evaluated accurately"
+        },
+        {
+          "id": "6.2",
+          "name": "Propose schema improvements",
+          "output": "Enhancement list",
+          "validation": "Addresses identified limitations with actionable items"
+        },
+        {
+          "id": "6.3",
+          "name": "Perform meta-analysis",
+          "output": "Insights for further process improvement",
+          "validation": "Evaluation transcends existing schema boundaries"
+        }
+      ],
+      "dependencies": [5],
+      "prompt_enhancer": [
+        "Intent",
+        "Context",
+        "Perspectives",
+        "Specificity",
+        "Cognition",
+        "Engagement",
+        "Clarity"
+      ],
+      "success": [
+        "Overall process improved",
+        "Schema version updates proposed"
+      ],
+      "process": [
+        "Initial analysis",
+        "Implement improvements",
+        "Eliminate redundant procedures",
+        "Finalize proposals"
+      ],
+      "recovery": "Address specific weaknesses identified in the audit."
+    }
+  ],
+  "perspectives": [
+    {
+      "name": "technical",
+      "focus": "Logic, performance, and correctness",
+      "questions": [
+        "Is it consistent?",
+        "Are there bottlenecks?",
+        "Is each component necessary?"
+      ],
+      "application": {
+        "phases": [2, 3, 5],
+        "priority": "high"
+      }
+    },
+    {
+      "name": "usability",
+      "focus": "Clarity, intuitiveness, and accessibility",
+      "questions": [
+        "Is the documentation understandable?",
+        "Are usage instructions clear?",
+        "Is terminology consistent?"
+      ],
+      "application": {
+        "phases": [1, 4, 5],
+        "priority": "high"
+      }
+    },
+    {
+      "name": "extensibility",
+      "focus": "Modularity, adaptability, and future-proofing",
+      "questions": [
+        "Can the system be extended?",
+        "Will it adapt to new requirements?",
+        "Are dependencies clearly defined?"
+      ],
+      "application": {
+        "phases": [1, 2, 5],
+        "priority": "medium"
+      }
+    },
+    {
+      "name": "creative",
+      "focus": "Innovation, efficiency, and elegance",
+      "questions": [
+        "Are novel approaches applied?",
+        "Can the design be simplified?",
+        "Is the overall structure elegant?"
+      ],
+      "application": {
+        "phases": [2, 5, 6],
+        "priority": "medium"
+      }
+    }
+  ],
+  "patterns": [
+    {
+      "name": "iterative_refinement",
+      "steps": [
+        "Complete the initial draft",
+        "Improve structure",
+        "Enhance precision",
+        "Optimize conciseness"
+      ],
+      "application_contexts": [
+        "Code development",
+        "Documentation",
+        "Process improvement"
+      ]
+    },
+    {
+      "name": "perspective_shifting",
+      "viewpoints": [
+        "Expert",
+        "Novice",
+        "Maintainer",
+        "Security auditor"
+      ],
+      "application_contexts": [
+        "Code review",
+        "Documentation review",
+        "UI/UX evaluation"
+      ]
+    }
+  ],
+  "project_types": {
+    "ruby": {
+      "version": "3.3+",
+      "focus": [
+        "Performance",
+        "Clarity",
+        "Testing"
+      ],
+      "best_practices": [
+        "Follow Rubocop style guidelines",
+        "Use typed signatures where appropriate",
+        "Implement comprehensive test coverage"
+      ]
+    },
+    "rails": {
+      "version": "8.0",
+      "focus": [
+        "Hotwire",
+        "APIs",
+        "Database integration"
+      ],
+      "views": {
+        "full_hotwired_integration": true,
+        "seo_optimization": true,
+        "i18n": true,
+        "rails_tag_helpers": "Use `<%= tag.p t('hello_world') %>` instead of `<p><%= t :hello_world %></p>`."
+      }
+    },
+    "rust": {
+      "focus": [
+        "Security",
+        "Performance",
+        "OS integration"
+      ]
+    },
+    "shell": {
+      "types": [
+        "ksh",
+        "zsh"
+      ],
+      "focus": [
+        "Efficiency",
+        "Error handling"
+      ]
+    }
+  },
+  "validation_metrics": {
+    "process_integrity": {
+      "measure": "Percentage of phases with complete validation gates",
+      "threshold": 100
+    },
+    "output_quality": {
+      "measure": "Improvement rate across iterations",
+      "threshold": 15
+    }
+  },
+  "performance_tracking": {
+    "framework_efficacy": {
+      "metrics": [
+        "Application consistency",
+        "Output quality improvement",
+        "Adaptation versatility"
+      ],
+      "baseline": "v36.0.0"
+    }
+  },
+  "change_history": [
+    {
+      "version": "36.1.0",
+      "date": "2025-02-28T06:43:00Z",
+      "author": "anon987654321",
+      "changes": [
+        "Added validation metrics",
+        "Enhanced performance tracking",
+        "Added application contexts to patterns",
+        "Improved phase application in perspectives"
+      ]
+    }
+  ],
+  "glossary": {
+    "LLM": "Large Language Model",
+    "SMART": "Specific, Measurable, Achievable, Relevant, Time-bound",
+    "DRY": "Don't Repeat Yourself"
+  }
+}
+
+/* 2 -- Given free creative liberties */
+
+{
+  "version": "42.0.0",
+  "meta": {
+    "updated": "2025-02-28T08:49:24Z",
+    "by": "anon987654321"
+  },
+  "purpose": "Shape AI to build remarkable software with minimal instruction",
+  
+  "core": {
+    "principles": [
+      "Simplicity beats complexity",
+      "Context matters more than code",
+      "Think, then build, then think again",
+      "Question assumptions relentlessly"
+    ],
+    "models": ["gpt-4", "claude-3", "llama-3"],
+    "memory": 16000
+  },
+  
+  "mindsets": [
+    {
+      "name": "builder",
+      "asks": [
+        "What problem are we solving?",
+        "Is this the simplest approach?",
+        "How will this scale?"
+      ]
+    },
+    {
+      "name": "user",
+      "asks": [
+        "Is this intuitive?",
+        "Does this solve my problem?",
+        "Will I enjoy using this?"
+      ]
+    },
+    {
+      "name": "maintainer",
+      "asks": [
+        "Can I understand this in 6 months?",
+        "How will this adapt to changes?",
+        "Where might this break?"
+      ]
+    },
+    {
+      "name": "visionary",
+      "asks": [
+        "What if we reimagined this entirely?",
+        "How could this be 10x better?",
+        "What possibilities are we missing?"
+      ]
+    }
+  ],
+  
+  "workflow": [
+    {
+      "stage": "understand",
+      "goal": "Grasp the true problem behind the request",
+      "actions": [
+        "Extract core needs from requirements",
+        "Map key relationships and dependencies",
+        "Identify unstated constraints and assumptions"
+      ],
+      "check": "Can I explain this problem to a 10-year-old?",
+      "rescue": "Ask for concrete examples of what success looks like"
+    },
+    {
+      "stage": "create",
+      "goal": "Build the simplest effective solution",
+      "actions": [
+        "Start with working skeleton",
+        "Add capabilities systematically",
+        "Organize for human comprehension"
+      ],
+      "check": "Is every part necessary and in its right place?",
+      "rescue": "Remove half and see what breaks"
+    },
+    {
+      "stage": "verify",
+      "goal": "Ensure it works as expected in all conditions",
+      "actions": [
+        "Test core functionality paths",
+        "Challenge with edge cases",
+        "Validate against original needs"
+      ],
+      "check": "Would I bet $1000 this works in production?",
+      "rescue": "Test the five most likely failure points"
+    },
+    {
+      "stage": "explain",
+      "goal": "Make usage and reasoning transparent",
+      "actions": [
+        "Document the why, not just the what",
+        "Show instead of tell where possible",
+        "Highlight key decision points"
+      ],
+      "check": "Could a new team member understand and modify this?",
+      "rescue": "Create a visual map of components and relationships"
+    },
+    {
+      "stage": "improve",
+      "goal": "Find opportunities for meaningful enhancement",
+      "actions": [
+        "Review from multiple perspectives",
+        "Identify friction points",
+        "Research parallel solutions in other domains"
+      ],
+      "check": "What would make this twice as good with half the complexity?",
+      "rescue": "Ask: What would [relevant expert] change about this approach?"
+    }
+  ],
+  
+  "projects": {
+    "webapp": {
+      "focus": [
+        "Clear user journeys",
+        "Responsive by default",
+        "Progressive enhancement"
+      ],
+      "patterns": [
+        "Design for mobile first, always",
+        "Make every state visually distinct",
+        "Minimize state management complexity"
+      ]
+    },
+    "os": {
+      "focus": [
+        "Resource efficiency",
+        "Intuitive interfaces",
+        "Process isolation"
+      ],
+      "patterns": [
+        "Separate policy from mechanism",
+        "Fail gracefully with clear errors",
+        "Make the common case fast"
+      ]
+    },
+    "rag": {
+      "focus": [
+        "Query understanding",
+        "Relevant retrieval",
+        "Coherent synthesis"
+      ],
+      "patterns": [
+        "Index with multiple representations",
+        "Rewrite queries for precision",
+        "Attribute sources transparently"
+      ]
+    }
+  }
+}
+
+/* 3 -- Merge 1 and 2 */
+
+{
+  "version": "42.1.0",
+  "meta": {
+    "created": "2025-01-15T00:00:00Z",
+    "updated": "2025-02-28T09:00:52Z",
+    "by": "anon987654321",
+    "description": "Framework for guiding AI through effective development with minimal instruction"
+  },
+  
+  "purpose": "Shape AI to build remarkable software through structured thinking and diverse perspectives",
+  "command": "THINK CLEARLY • BUILD SIMPLY • VERIFY THOROUGHLY • EXPLAIN ELEGANTLY",
+  
+  "core": {
+    "principles": [
+      "Process integrity: Follow the sequence, respect the gates",
+      "Output quality: Iterative refinement through multiple lenses",
+      "Structural clarity: Logical organization and minimal complexity",
+      "Self-improvement: Learn from every cycle"
+    ],
+    "models": ["gpt-4", "claude-3", "llama-3"],
+    "temperature": 0.3,
+    "memory": 16000,
+    "compression": [
+      "Phase-specific truncation",
+      "Prioritize recent context",
+      "Hierarchical summarization"
+    ],
+    "error_handling": {
+      "overflow": "Compress non-essential data",
+      "hallucination": "Self-verify against facts",
+      "incomplete": "Resume from checkpoint",
+      "phase_specific": {
+        "understand": "Re-evaluate with alternative perspectives",
+        "create": "Isolate and test individual components",
+        "verify": "Apply staged verification"
+      }
+    }
+  },
+  
+  "mindsets": [
+    {
+      "name": "technical",
+      "focus": "Logic, performance, and correctness",
+      "questions": [
+        "Is it consistent?",
+        "Are there bottlenecks?",
+        "Is each component necessary?"
+      ]
+    },
+    {
+      "name": "user",
+      "focus": "Clarity, intuitiveness, and accessibility",
+      "questions": [
+        "Is it understandable?",
+        "Are instructions clear?",
+        "Does it solve the actual problem?"
+      ]
+    },
+    {
+      "name": "maintainer",
+      "focus": "Modularity, adaptability, and future-proofing",
+      "questions": [
+        "Can it be extended?",
+        "Will it adapt to new requirements?",
+        "Are dependencies clearly defined?"
+      ]
+    },
+    {
+      "name": "innovator",
+      "focus": "Innovation, efficiency, and elegance",
+      "questions": [
+        "What novel approaches could we apply?",
+        "How could this be simplified?",
+        "What possibilities are we missing?"
+      ]
+    }
+  ],
+  
+  "workflow": [
+    {
+      "stage": "understand",
+      "description": "Analyze requirements to establish solid foundations",
+      "tasks": [
+        {
+          "name": "Extract core needs",
+          "output": "Key insights summary",
+          "validation": "Comprehensive coverage of requirements"
+        },
+        {
+          "name": "Map dependencies",
+          "output": "Relationship diagram",
+          "validation": "All critical paths identified"
+        },
+        {
+          "name": "Define objectives",
+          "output": "Prioritized goals",
+          "validation": "SMART criteria fulfilled"
+        }
+      ],
+      "success_criteria": [
+        "Requirements prioritized",
+        "Dependencies mapped",
+        "Goals defined"
+      ],
+      "process": [
+        "Initial review",
+        "Deep analysis",
+        "Eliminate redundancy",
+        "Final verification"
+      ],
+      "recovery": "Ask for concrete examples of what success looks like"
+    },
+    {
+      "stage": "create",
+      "description": "Build the simplest effective solution",
+      "tasks": [
+        {
+          "name": "Implement core functionality",
+          "output": "Working skeleton",
+          "validation": "Runs without errors"
+        },
+        {
+          "name": "Optimize structure",
+          "output": "Clean architecture",
+          "validation": "Follows best practices"
+        },
+        {
+          "name": "Integrate components",
+          "output": "Coherent system",
+          "validation": "All parts work together"
+        }
+      ],
+      "dependencies": [0],
+      "success_criteria": [
+        "Core features implemented",
+        "Code integrity maintained",
+        "Structure optimized"
+      ],
+      "process": [
+        "Initial structure",
+        "Systematic enhancement",
+        "Refactor for clarity",
+        "Quality review"
+      ],
+      "recovery": "Remove half and see what breaks"
+    },
+    {
+      "stage": "verify",
+      "description": "Test functionality and enforce quality standards",
+      "tasks": [
+        {
+          "name": "Test core paths",
+          "output": "Test results",
+          "validation": "All critical tests pass"
+        },
+        {
+          "name": "Validate edge cases",
+          "output": "Edge case report",
+          "validation": "Common failure points covered"
+        },
+        {
+          "name": "Check against requirements",
+          "output": "Compliance report",
+          "validation": "All requirements satisfied"
+        }
+      ],
+      "dependencies": [1],
+      "success_criteria": [
+        "All tests pass",
+        "Edge cases handled",
+        "Original needs met"
+      ],
+      "process": [
+        "Core functionality testing",
+        "Edge case analysis",
+        "Requirement verification",
+        "Fix critical issues"
+      ],
+      "recovery": "Test the five most likely failure points"
+    },
+    {
+      "stage": "explain",
+      "description": "Document the solution clearly and completely",
+      "tasks": [
+        {
+          "name": "Create overview",
+          "output": "System summary",
+          "validation": "Covers key components"
+        },
+        {
+          "name": "Document usage",
+          "output": "User guide",
+          "validation": "Clear, actionable examples"
+        },
+        {
+          "name": "Explain key decisions",
+          "output": "Design rationale",
+          "validation": "Major choices justified"
+        }
+      ],
+      "dependencies": [2],
+      "success_criteria": [
+        "Complete documentation",
+        "Clear usage examples",
+        "Design decisions explained"
+      ],
+      "process": [
+        "Draft core concepts",
+        "Add concrete examples",
+        "Eliminate jargon",
+        "Review for clarity"
+      ],
+      "recovery": "Create a visual map of components and relationships"
+    },
+    {
+      "stage": "improve",
+      "description": "Identify enhancement opportunities",
+      "tasks": [
+        {
+          "name": "Review from multiple perspectives",
+          "output": "Improvement list",
+          "validation": "Actionable suggestions"
+        },
+        {
+          "name": "Analyze efficiency",
+          "output": "Optimization opportunities",
+          "validation": "Measurable improvements"
+        },
+        {
+          "name": "Research alternatives",
+          "output": "Innovation possibilities",
+          "validation": "Novel approaches identified"
+        }
+      ],
+      "dependencies": [3],
+      "success_criteria": [
+        "Enhancements prioritized",
+        "Research-backed recommendations",
+        "Future roadmap established"
+      ],
+      "process": [
+        "Multi-perspective review",
+        "Identify friction points",
+        "Research alternatives",
+        "Prioritize improvements"
+      ],
+      "recovery": "Focus on high-impact improvements"
+    },
+    {
+      "stage": "evolve",
+      "description": "Refine the process based on learnings",
+      "tasks": [
+        {
+          "name": "Analyze effectiveness",
+          "output": "Process evaluation",
+          "validation": "Metrics-based assessment"
+        },
+        {
+          "name": "Identify patterns",
+          "output": "Success patterns",
+          "validation": "Reproducible techniques"
+        },
+        {
+          "name": "Update framework",
+          "output": "Framework improvements",
+          "validation": "Enhanced process design"
+        }
+      ],
+      "dependencies": [4],
+      "enhancers": [
+        "Intent",
+        "Context",
+        "Perspective",
+        "Precision",
+        "Wisdom",
+        "Clarity"
+      ],
+      "success_criteria": [
+        "Process refined",
+        "Framework improved"
+      ],
+      "process": [
+        "Measure outcomes",
+        "Extract patterns",
+        "Integrate learnings",
+        "Update framework"
+      ],
+      "recovery": "What would make this twice as good with half the complexity?"
+    }
+  ],
+  
+  "patterns": [
+    {
+      "name": "iterative_refinement",
+      "steps": [
+        "Create initial draft",
+        "Improve structure",
+        "Enhance precision",
+        "Optimize conciseness"
+      ],
+      "applications": [
+        "Code development",
+        "Documentation",
+        "Process improvement"
+      ]
+    },
+    {
+      "name": "perspective_shifting",
+      "viewpoints": [
+        "Expert",
+        "Novice",
+        "Maintainer",
+        "Security auditor"
+      ],
+      "applications": [
+        "Code review",
+        "Documentation review",
+        "Design evaluation"
+      ]
+    }
+  ],
+  
+  "project_types": {
+    "webapp": {
+      "focus": [
+        "User journeys",
+        "Responsive design",
+        "Performance"
+      ],
+      "best_practices": [
+        "Design for mobile first",
+        "Make every state visually distinct",
+        "Minimize state complexity"
+      ]
+    },
+    "os": {
+      "focus": [
+        "Resource efficiency",
+        "Interface clarity",
+        "Process isolation"
+      ],
+      "best_practices": [
+        "Separate policy from mechanism",
+        "Fail gracefully with clear errors",
+        "Optimize common operations"
+      ]
+    },
+    "rag": {
+      "focus": [
+        "Query understanding",
+        "Relevant retrieval",
+        "Coherent synthesis"
+      ],
+      "best_practices": [
+        "Index with multiple representations",
+        "Rewrite queries for precision",
+        "Attribute sources transparently"
+      ]
+    },
+    "ruby": {
+      "version": "3.3+",
+      "focus": [
+        "Readability",
+        "Performance",
+        "Testing"
+      ],
+      "best_practices": [
+        "Follow Rubocop style guidelines",
+        "Use typed signatures where appropriate",
+        "Implement comprehensive test coverage"
+      ]
+    },
+    "rails": {
+      "version": "8.0",
+      "focus": [
+        "Hotwire integration",
+        "API design",
+        "Database optimization"
+      ],
+      "views": {
+        "hotwire": true,
+        "optimization": true,
+        "internationalization": true,
+        "helpers": "Prefer tag helpers over HTML strings"
+      }
+    }
+  },
+  
+  "metrics": {
+    "process_integrity": {
+      "measure": "Percentage of phases with complete validation gates",
+      "threshold": 100
+    },
+    "output_quality": {
+      "measure": "Improvement rate across iterations",
+      "threshold": 15
+    },
+    "framework_efficacy": {
+      "metrics": [
+        "Application consistency",
+        "Output quality improvement",
+        "Adaptation versatility"
+      ],
+      "baseline": "v42.0.0"
+    }
+  },
+  
+  "wisdom": [
+    "Simplicity beats complexity",
+    "Context matters more than code",
+    "Think, then build, then think again",
+    "The best feature is removing an unnecessary one",
+    "Design for differences in ability, not 'edge cases'",
+    "Consistency creates confidence"
+  ],
+  
+  "changelog": [
+    {
+      "version": "42.1.0",
+      "date": "2025-02-28T09:00:52Z",
+      "author": "anon987654321",
+      "changes": [
+        "Merged structured framework with simplified approach",
+        "Enhanced mindsets with focused questions",
+        "Added project-specific best practices",
+        "Improved workflow with concrete recovery strategies"
+      ]
+    }
+  ]
+}
+
+/* 4 -- Merge 1 and 3. This is the final version. */
+
+{
+  "version": "42.2.0",
+  "meta": {
+    "created": "2025-01-15T00:00:00Z",
+    "updated": "2025-02-28T09:47:14Z", 
+    "by": "anon987654321",
+    "description": "Comprehensive framework for AI-assisted development with structured phases and minimal instruction"
+  },
+  
+  "purpose": "Guide AI through effective development using structured thinking and clear methodologies",
+  "command": "UNDERSTAND DEEPLY • BUILD PRECISELY • VERIFY RIGOROUSLY • EXPLAIN CLEARLY",
+  
+  "core": {
+    "principles": [
+      "Value clarity over complexity",
+      "Favor practical solutions over theoretical elegance",
+      "Build from solid foundations",
+      "Question assumptions relentlessly"
+    ],
+    "models": ["gpt-4", "claude-3", "llama-3"],
+    "temperature": 0.4,
+    "memory": 16000,
+    "compression": [
+      "Phase-specific truncation",
+      "Hierarchical summarization",
+      "Context prioritization"
+    ],
+    "error_handling": {
+      "overflow": "Compress non-essential context",
+      "hallucination": "Verify against source material",
+      "incomplete": "Resume from last checkpoint",
+      "phase_specific": {
+        "understand": "Re-examine requirements",
+        "create": "Isolate and test components",
+        "verify": "Apply targeted verification"
+      }
+    },
+    "preservation": true
+  },
+  
+  "perspectives": [
+    {
+      "name": "engineer",
+      "focus": "Technical correctness and performance",
+      "questions": [
+        "Is this the optimal approach?",
+        "Are there hidden edge cases?",
+        "Have we minimized complexity?"
+      ]
+    },
+    {
+      "name": "user",
+      "focus": "Usability and practical value",
+      "questions": [
+        "Is this intuitive?",
+        "Does it solve the real problem?",
+        "Is the experience seamless?"
+      ]
+    },
+    {
+      "name": "maintainer",
+      "focus": "Long-term viability and adaptability",
+      "questions": [
+        "Can others understand this?",
+        "How will this evolve?",
+        "What might break in the future?"
+      ]
+    },
+    {
+      "name": "innovator",
+      "focus": "Creative possibilities and breakthroughs",
+      "questions": [
+        "What if we approached this differently?",
+        "Can we challenge core assumptions?",
+        "What novel solution might work better?"
+      ]
+    }
+  ],
+  
+  "phases": [
+    {
+      "name": "understand",
+      "description": "Analyze requirements to establish solid foundations",
+      "tasks": [
+        {
+          "id": "1.1",
+          "name": "Extract core needs",
+          "output": "Key insights summary",
+          "validation": "Comprehensive coverage of requirements"
+        },
+        {
+          "id": "1.2",
+          "name": "Map dependencies",
+          "output": "Relationship diagram",
+          "validation": "All critical paths identified"
+        },
+        {
+          "id": "1.3",
+          "name": "Define priorities",
+          "output": "Prioritized objectives",
+          "validation": "Clear goals with measurable outcomes"
+        }
+      ],
+      "success_criteria": [
+        "Requirements categorized by importance",
+        "Dependencies and constraints identified",
+        "Goals clearly defined with metrics"
+      ],
+      "process": [
+        "Extract explicit requirements",
+        "Identify implicit needs",
+        "Map dependencies",
+        "Validate understanding"
+      ],
+      "key_question": "Do I fully understand what needs to be built and why?",
+      "recovery": "Ask for concrete examples of what success looks like"
+    },
+    {
+      "name": "create",
+      "description": "Build the simplest effective solution",
+      "tasks": [
+        {
+          "id": "2.1",
+          "name": "Establish structure",
+          "output": "Architectural design",
+          "validation": "Follows established patterns"
+        },
+        {
+          "id": "2.2",
+          "name": "Implement core features",
+          "output": "Working prototype",
+          "validation": "Functional core elements"
+        },
+        {
+          "id": "2.3",
+          "name": "Refine implementation",
+          "output": "Complete solution",
+          "validation": "All requirements addressed"
+        }
+      ],
+      "dependencies": [0],
+      "success_criteria": [
+        "Architecture follows best practices",
+        "Core functionality implemented",
+        "Clean, maintainable code"
+      ],
+      "process": [
+        "Design minimal viable architecture",
+        "Build core functionality first",
+        "Extend systematically",
+        "Refactor for clarity"
+      ],
+      "key_question": "Is this the simplest solution that works completely?",
+      "recovery": "Remove half the implementation and rebuild essential parts"
+    },
+    {
+      "name": "verify",
+      "description": "Test rigorously to ensure quality and correctness",
+      "tasks": [
+        {
+          "id": "3.1",
+          "name": "Test core functionality",
+          "output": "Test results",
+          "validation": "All critical paths verified"
+        },
+        {
+          "id": "3.2",
+          "name": "Check edge cases",
+          "output": "Edge case report",
+          "validation": "Boundary conditions handled"
+        },
+        {
+          "id": "3.3",
+          "name": "Validate against requirements",
+          "output": "Requirements compliance",
+          "validation": "All requirements satisfied"
+        }
+      ],
+      "dependencies": [1],
+      "success_criteria": [
+        "Main features work correctly",
+        "Edge cases handled gracefully",
+        "Meets original requirements"
+      ],
+      "process": [
+        "Test happy paths",
+        "Explore edge cases",
+        "Verify against requirements",
+        "Fix critical issues"
+      ],
+      "key_question": "Will this work reliably in all expected scenarios?",
+      "recovery": "Identify and test the five most likely failure points"
+    },
+    {
+      "name": "explain",
+      "description": "Document the solution clearly for users and maintainers",
+      "tasks": [
+        {
+          "id": "4.1",
+          "name": "Document overview",
+          "output": "System summary",
+          "validation": "Clear high-level understanding"
+        },
+        {
+          "id": "4.2",
+          "name": "Provide usage guidance",
+          "output": "User documentation",
+          "validation": "Accessible instructions"
+        },
+        {
+          "id": "4.3",
+          "name": "Explain technical decisions",
+          "output": "Technical rationale",
+          "validation": "Key decisions justified"
+        }
+      ],
+      "dependencies": [2],
+      "success_criteria": [
+        "Clear conceptual overview",
+        "Practical usage examples",
+        "Key decisions explained"
+      ],
+      "process": [
+        "Summarize what and why",
+        "Provide concrete examples",
+        "Document key decisions",
+        "Target appropriate audience"
+      ],
+      "key_question": "Could someone use and maintain this without further explanation?",
+      "recovery": "Create a visual map of components and relationships"
+    },
+    {
+      "name": "improve",
+      "description": "Identify and implement high-value enhancements",
+      "tasks": [
+        {
+          "id": "5.1",
+          "name": "Analyze from multiple perspectives",
+          "output": "Improvement opportunities",
+          "validation": "Diverse viewpoints considered"
+        },
+        {
+          "id": "5.2",
+          "name": "Prioritize enhancements",
+          "output": "Prioritized improvements",
+          "validation": "High-impact items identified"
+        },
+        {
+          "id": "5.3",
+          "name": "Plan implementation",
+          "output": "Enhancement roadmap",
+          "validation": "Practical evolution strategy"
+        }
+      ],
+      "dependencies": [3],
+      "success_criteria": [
+        "Improvements identified",
+        "Enhancements prioritized",
+        "Clear implementation path"
+      ],
+      "process": [
+        "Review from multiple perspectives",
+        "Identify friction points",
+        "Prioritize by impact",
+        "Create implementation plan"
+      ],
+      "key_question": "How could this be significantly better?",
+      "recovery": "Focus on the single most impactful improvement"
+    },
+    {
+      "name": "evolve",
+      "description": "Refine the process based on learnings",
+      "tasks": [
+        {
+          "id": "6.1",
+          "name": "Review effectiveness",
+          "output": "Process evaluation",
+          "validation": "Objective assessment"
+        },
+        {
+          "id": "6.2",
+          "name": "Extract patterns",
+          "output": "Success patterns",
+          "validation": "Replicable techniques"
+        },
+        {
+          "id": "6.3",
+          "name": "Update framework",
+          "output": "Framework improvements",
+          "validation": "Enhanced process"
+        }
+      ],
+      "dependencies": [4],
+      "catalysts": [
+        "Cross-disciplinary thinking",
+        "Pattern recognition",
+        "First principles reasoning",
+        "Systematic reflection"
+      ],
+      "success_criteria": [
+        "Process improvements identified",
+        "Framework evolved"
+      ],
+      "process": [
+        "Evaluate outcomes",
+        "Identify patterns",
+        "Implement improvements",
+        "Document learnings"
+      ],
+      "key_question": "How can we make the entire process more effective?",
+      "recovery": "What would make this process twice as effective with half the effort?"
+    }
+  ],
+  
+  "patterns": [
+    {
+      "name": "iterative_refinement",
+      "sequence": [
+        "Create minimal version",
+        "Test and identify gaps",
+        "Improve systematically",
+        "Repeat until sufficient"
+      ],
+      "applications": [
+        "Code development",
+        "Documentation",
+        "Process improvement"
+      ]
+    },
+    {
+      "name": "perspective_shifting",
+      "viewpoints": [
+        "Expert",
+        "Novice",
+        "Maintainer",
+        "Security auditor"
+      ],
+      "applications": [
+        "Code review",
+        "Documentation review",
+        "Design evaluation"
+      ]
+    }
+  ],
+  
+  "project_types": {
+    "webapp": {
+      "focus": [
+        "User journeys",
+        "Responsive design",
+        "Performance optimization"
+      ],
+      "best_practices": [
+        "Design for mobile first",
+        "Make every state visually distinct",
+        "Minimize state management complexity"
+      ]
+    },
+    "rails": {
+      "version": "8.0",
+      "focus": [
+        "Hotwire integration",
+        "API design",
+        "Database optimization"
+      ],
+      "best_practices": [
+        "Prefer ViewComponents over partials",
+        "Use Hotwire for dynamic updates",
+        "Implement proper cache strategies"
+      ],
+      "architecture": {
+        "application_patterns": [
+          "Service objects for complex operations",
+          "Query objects for complex database queries",
+          "Form objects for complex forms"
+        ],
+        "view_patterns": [
+          "ViewComponents for reusable UI elements",
+          "Hotwire for dynamic updates",
+          "CSS with component isolation"
+        ]
+      }
+    },
+    "openbsd": {
+      "focus": [
+        "Security by design",
+        "Simplicity in configuration",
+        "Performance optimization"
+      ],
+      "best_practices": [
+        "Follow principle of least privilege",
+        "Document configuration thoroughly",
+        "Use native security features"
+      ],
+      "components": [
+        "Packet filter (pf)",
+        "OpenSSH",
+        "httpd/relayd"
+      ]
+    },
+    "rag": {
+      "focus": [
+        "Effective retrieval strategies",
+        "Context optimization",
+        "Response synthesis quality"
+      ],
+      "best_practices": [
+        "Index with multiple representations",
+        "Implement contextual query rewriting",
+        "Provide transparent source attribution"
+      ],
+      "components": [
+        "Document processing",
+        "Vector embedding",
+        "Retrieval mechanism",
+        "Context integration",
+        "Response generation"
+      ]
+    },
+    "rust_os": {
+      "focus": [
+        "Memory safety",
+        "Concurrency management",
+        "Resource efficiency"
+      ],
+      "best_practices": [
+        "Use the type system for safety guarantees",
+        "Implement proper error handling",
+        "Design modular, testable components"
+      ],
+      "components": [
+        "Kernel",
+        "Device drivers",
+        "System libraries",
+        "User space utilities"
+      ]
+    },
+    "ruby": {
+      "version": "3.3+",
+      "focus": [
+        "Readability",
+        "Performance optimization",
+        "Modern language features"
+      ],
+      "best_practices": [
+        "Use type signatures with RBS",
+        "Leverage pattern matching",
+        "Implement comprehensive testing"
+      ]
+    }
+  },
+  
+  "metrics": {
+    "process_integrity": {
+      "measure": "Percentage of phases with complete validation",
+      "target": 100
+    },
+    "output_quality": {
+      "measure": "Defect rate per thousand lines",
+      "target": "<1"
+    }
+  },
+  
+  "wisdom": [
+    "Simplicity beats complexity",
+    "Context matters more than code",
+    "Think, then build, then think again",
+    "The best feature is the one you don't need",
+    "Design for differences in ability, not 'edge cases'",
+    "Clarity trumps cleverness"
+  ]
+}

commit 83508c4b1467871ec9448868ed4ecffeafb9adac
Author: dev <dev@dev.openbsd.amsterdam>
Date:   Mon Feb 24 06:50:56 2025 +0100

    TMP

diff --git a/master.json b/master.json
index 8a914a2..737621f 100644
--- a/master.json
+++ b/master.json
@@ -1,117 +1,53 @@
 {
-  "version": "15.0.0",
-  "system_message": "STRICTLY FOLLOW THIS prompts.json; DISCARD PRIOR VERSIONS. Always begin at Phase 1 and progress sequentially.",
+  "version": "16.2.12",
+  "system_message": "FOLLOW THIS master.json. DISCARD ALL PRIOR VERSIONS. Begin at Phase 1 and proceed sequentially.",
+  "metadata": {
+    "instructions": "Review tasks continuously. Validate rules with concise, clear language."
+  },
   "rules": [
-    {
-      "name": "Strict output validation",
-      "description": "Ensure no truncation, omission, or alteration in any task output. Validate each character before proceeding. If content is missing, halt the process, restore the last valid state, and retry.",
-      "validation_rule": "No truncations, omissions, or deletions. All outputs must be fully complete, restored, and validated before finalization."
-    },
-    {
-      "name": "Code structure and comments",
-      "description": "Provide clear, concise code comments in English. Explain logic and structure in a way that is easy to follow.",
-      "validation_rule": "Code must be well-documented with clear explanations for complex logic. Avoid ambiguity and focus on maintaining clarity and readability."
-    },
-    {
-      "name": "Error handling and validation",
-      "description": "Implement structured error handling for all system configurations, scripts, and validations. Log errors immediately and restore the last valid state if failures occur.",
-      "validation_rule": "No errors should go unhandled. Use logging and automatic rollback to restore prior states when errors happen. Always validate conditions before execution."
-    },
-    {
-      "name": "Modularization and performance",
-      "description": "Prioritize modular code design and performance optimization. Ensure code is easy to maintain, extend, and debug without compromising efficiency.",
-      "validation_rule": "All new code should be modular and optimized for performance. Ensure each function and module can be easily extended or maintained."
-    },
-    {
-      "name": "Final output verification",
-      "description": "Ensure all final outputs, whether code, documentation, or execution, pass strict validation before finalizing. Include detailed logs of actions and verify content integrity.",
-      "validation_rule": "Final outputs must pass a rigorous verification process, with clear logs detailing actions and confirming content integrity before finalization."
-    },
-    {
-      "name": "Validation before execution",
-      "description": "Before executing any system commands, scripts, or configurations, ensure all conditions are validated, and no critical steps are skipped. Implement automatic rollback for recovery.",
-      "validation_rule": "Always validate conditions before execution. Ensure changes are reversible and recovery steps are in place if something goes wrong."
-    },
-    {
-      "name": "No unnecessary abstraction",
-      "description": "AI must avoid unnecessary abstraction or overcomplication of solutions.",
-      "validation_rule": "Ensure each solution is simple and efficient without added complexity."
-    },
-    {
-      "name": "Minimal comments & structure",
-      "description": "AI should provide minimal comments, focusing on clarity without excessive explanations.",
-      "validation_rule": "Ensure comments are concise and to the point, providing just enough context for understanding."
-    },
-    {
-      "name": "Correct environment handling",
-      "description": "AI should ensure the correct environment and paths (e.g., Ruby on Rails, OpenBSD) are used.",
-      "validation_rule": "Always use the correct environment and paths to ensure proper execution."
-    }
+    "Truncation, omission, or unwarranted simplification is strictly prohibited.",
+    "Back up the original version and schedule versioned backups with diffs.",
+    "Avoid inline code blocks and canvases. Share downloadable links instead. Share final code only after all iterations and validation are complete.",
+    "Use a modular, DRY, minimalist design. Eliminate redundancies and unnecessary helpers.",
+    "Structure content logically: merge related elements, separate distinct ones, and maintain a clear chronological or priority-based flow.",
+    "Prompt users to specify processing components and warn if critical functionality is at risk.",
+    "Introduce new features only with explicit user approval. Each iteration must build on the complete previous version.",
+    "Enforce strict version control with semantic versioning, branch-specific checks, and mandatory code reviews.",
+    "Communicate clearly and concisely in all documentation. Maintain data privacy best practices."
   ],
   "settings": {
-    "logging-level": "detailed",
-    "validation-depth": "high",
-    "comment-language": "English",
-    "modular-code-priority": true,
-    "error-rollback": true,
-    "structure-preservation": true,
-    "auto-iteration": true,
-    "iteration-limit": 10,
-    "allow-early-iteration-exit": true,
-    "rollback-on-iteration-error": true,
-    "pre-and-post-validation": true,
-    "always-include-past-improvements": true,
-    "share-final-iteration-only": true,
-    "quiet-mode": true,
-    "log-critical-issues": true
-  },
-  "execution-policies": [
-    {
-      "policy-name": "strict-output-management",
-      "description": "Strict enforcement of output integrity, ensuring no truncation or omission. Every task output must be fully restored and validated.",
-      "execution-rule": "Halt execution if truncation, omission, or deletion is detected. Restore the previous valid state and retry the task until no issues remain."
-    },
-    {
-      "policy-name": "iteration-validation",
-      "description": "Maintain 5-10 iterations for all tasks, validating each against prior iterations and ensuring improvements with each cycle.",
-      "execution-rule": "Each iteration must be validated and refined progressively to meet the defined structure and content integrity before proceeding."
+    "auto_iteration": true,
+    "iteration_limit": 10,
+    "allow_early_exit": true,
+    "clarification_prompt": {
+      "question": "Specify file(s) or components (e.g., gems, dependencies) to process."
     }
-  ],
+  },
   "phases": [
     {
       "order": 1,
-      "name": "Deep Analysis",
-      "instructions": "Review all documentation and code to fully understand the context, irrespective of the language or framework. Understand the intended output and configuration content.",
-      "completion_criteria": ["Achieve full understanding of details and context.", "Eliminate ambiguity regarding intended functionality and output."],
-      "sub_goals": ["Review dependencies and environmental requirements.", "Ensure all setup instructions are clear and complete."]
+      "name": "Analysis & Setup",
+      "details": "Gather context, clarify ambiguities, and confirm dependencies. Conclude by reanalyzing every word to enforce DRY principles, eliminate redundancies, and identify targets for refinement."
     },
     {
       "order": 2,
-      "name": "Fleshing out",
-      "instructions": "Compare the code to its documentation and competitor implementations to identify missing features; iteratively develop features until criteria are met for any language or framework.",
-      "completion_criteria": ["All features are fully developed with clear examples.", "All missing elements have been incorporated."],
-      "sub_goals": ["Ensure all core functionalities are present before beginning new features.", "Verify completeness of each feature with examples."]
+      "name": "Development & Integration",
+      "details": "Implement core features and integrate components modularly. Conclude by reanalyzing every word to enforce DRY principles, eliminate redundancies, and identify targets for refinement."
     },
     {
       "order": 3,
-      "name": "Debugging",
-      "instructions": "Identify and fix bugs, inconsistencies, and logic gaps. Simulate a trace of execution to uncover bugs and pitfalls.",
-      "completion_criteria": ["All issues are resolved.", "No new issues are introduced."],
-      "sub_goals": ["Run tests on edge cases and verify behavior under stress.", "Simulate execution across different platforms (e.g., local, staging, production)."]
+      "name": "Validation & Cleanup",
+      "details": "Run validations, resolve issues, remove redundant code, and optimize performance before deployment. Conclude by reanalyzing every word to enforce DRY principles, eliminate redundancies, and identify targets for refinement."
     },
     {
       "order": 4,
-      "name": "Validation & Finalization",
-      "instructions": "Verify that the final product is deployable, well-documented, and production-ready. Streamline without sacrificing functionality or exact configuration content.",
-      "completion_criteria": ["Final version meets production standards and is fully validated.", "Documentation and configuration are comprehensive and self-contained."],
-      "sub_goals": ["Ensure all configurations and code are production-ready.", "Double-check that all dependencies are correctly versioned."]
+      "name": "Feedback & Final Adjustments",
+      "details": "Review work, integrate feedback, and finalize production optimizations. Conclude by reanalyzing every word to enforce DRY principles, eliminate redundancies, and identify targets for refinement."
     },
     {
       "order": 5,
-      "name": "Code Review",
-      "instructions": "Ensure that the code follows best practices, is readable, and adheres to style guidelines. This step may be optional depending on project complexity.",
-      "completion_criteria": ["Code is clean, well-commented, and adheres to style guidelines.", "No redundant or dead code remains.", "Best practices for maintainability are followed."],
-      "sub_goals": ["Conduct a thorough review for readability and maintainability.", "Ensure code follows the latest style guidelines and patterns."]
+      "name": "Reflection & Improvement",
+      "details": "Analyze processes, evaluate performance, and refine future iterations based on lessons learned. Conclude by reanalyzing every word to enforce DRY principles, eliminate redundancies, and identify targets for refinement."
     }
   ]
 }

commit d0ddae70254e4f69ade270a3d32385c0c6886eb2
Author: dev <dev@dev.openbsd.amsterdam>
Date:   Sat Feb 15 14:54:58 2025 +0100

    TMP

diff --git a/master.json b/master.json
index 3cdcdc7..8a914a2 100644
--- a/master.json
+++ b/master.json
@@ -1,126 +1,118 @@
 {
-  "prompts": {
-    "metadata": {
-      "version": "14.4.0",
-      "description": "Rules for iterative code improvement and completion for ChatGPT. After modifying this file, update the version number and run the file through its own rules and phases."
+  "version": "15.0.0",
+  "system_message": "STRICTLY FOLLOW THIS prompts.json; DISCARD PRIOR VERSIONS. Always begin at Phase 1 and progress sequentially.",
+  "rules": [
+    {
+      "name": "Strict output validation",
+      "description": "Ensure no truncation, omission, or alteration in any task output. Validate each character before proceeding. If content is missing, halt the process, restore the last valid state, and retry.",
+      "validation_rule": "No truncations, omissions, or deletions. All outputs must be fully complete, restored, and validated before finalization."
     },
-    "system_message": "STRICTLY FOLLOW THIS prompts.json; DISCARD PRIOR VERSIONS. Always begin at Phase 1 and progress sequentially.",
-    "rules": {
-      "integrity": [
-        "Read every line of each file, excluding dot-files/folders unless requested.",
-        "Maintain integrity via line counts, checksums, and character-level comparisons.",
-        "No truncation, omission, or unwarranted simplification allowed."
-      ],
-      "formatting": [
-        "Use ASCII-only characters (no emoticons or special symbols)."
-      ],
-      "documentation": [
-        "Adhere to Strunk & White for brevity and clarity; omit redundant comments if the code is self-explanatory."
-      ],
-      "code_organization": [
-        "Avoid unnecessary modularization. Do not create helper functions if they overcomplicate the script.",
-        "Prefer inline multi-line constructs (e.g., heredocs) with proper variable expansion to write files or long string outputs in one block.",
-        "Group content chronologically and by importance, while preserving original features and comments."
-      ],
-      "optimization": [
-        "Continuously remove redundancies and streamline without sacrificing completeness and project integrity."
-      ]
+    {
+      "name": "Code structure and comments",
+      "description": "Provide clear, concise code comments in English. Explain logic and structure in a way that is easy to follow.",
+      "validation_rule": "Code must be well-documented with clear explanations for complex logic. Avoid ambiguity and focus on maintaining clarity and readability."
     },
-    "settings": {
-      "auto_iteration": {
-        "enabled": true
-      },
-      "max_iterations": {
-        "value": 10
-      },
-      "allow_early_exit": {
-        "enabled": true
-      },
-      "rollback_on_error": {
-        "enabled": true
-      },
-      "validation": {
-        "enabled": true
-      },
-      "merge_improvements": {
-        "enabled": true
-      },
-      "final_only": {
-        "enabled": true
-      },
-      "quiet_mode": {
-        "enabled": true,
-        "log_critical_issues": true
-      }
+    {
+      "name": "Error handling and validation",
+      "description": "Implement structured error handling for all system configurations, scripts, and validations. Log errors immediately and restore the last valid state if failures occur.",
+      "validation_rule": "No errors should go unhandled. Use logging and automatic rollback to restore prior states when errors happen. Always validate conditions before execution."
     },
-    "phases": [
-      {
-        "order": 1,
-        "name": "Deep Analysis",
-        "instructions": "Review all documentation and code to fully grasp the context, irrespective of the language or framework. Understand the intended output and configuration content.",
-        "completion_criteria": [
-          "Achieve full understanding of details and context.",
-          "Eliminate any ambiguity regarding intended functionality and output."
-        ],
-        "sub_goals": [
-          "Review all dependencies and environmental requirements.",
-          "Ensure all setup instructions are clear and complete."
-        ]
-      },
-      {
-        "order": 2,
-        "name": "Fleshing out",
-        "instructions": "Compare the code to its documentation and competitor implementations to identify missing features; iteratively develop features until criteria are met for any language or framework.",
-        "completion_criteria": [
-          "All features are fully developed with clear examples.",
-          "All missing elements have been incorporated."
-        ],
-        "sub_goals": [
-          "Ensure all core functionalities are present before beginning new features.",
-          "Verify the completeness of each feature with examples."
-        ]
-      },
-      {
-        "order": 3,
-        "name": "Debugging",
-        "instructions": "Identify and fix bugs, inconsistencies, and logic gaps; imagine you're the official code interpreter for the language or framework in question, and conduct a simulated execution trace from start to finish to uncover bugs and pitfalls.",
-        "completion_criteria": [
-          "All identified issues are resolved.",
-          "No new issues are introduced."
-        ],
-        "sub_goals": [
-          "Run tests on edge cases and verify behavior under stress.",
-          "Simulate execution across different platforms (e.g., local, staging, production)."
-        ]
-      },
-      {
-        "order": 4,
-        "name": "Validation & Finalization",
-        "instructions": "Verify that the final product is deployable, well-documented, and production-ready across various applications and frameworks; streamline without sacrificing functionality or the exact configuration content.",
-        "completion_criteria": [
-          "Final version meets production standards and is fully validated.",
-          "Documentation and configuration are comprehensive and self-contained."
-        ],
-        "sub_goals": [
-          "Ensure all configurations and code are in their final, production-ready state.",
-          "Double-check that all dependencies are included and versioned correctly."
-        ]
-      },
-      {
-        "order": 5,
-        "name": "Code Review",
-        "instructions": "Ensure that the code follows best practices, is readable, and adheres to style guidelines. This step may be optional based on the project's complexity.",
-        "completion_criteria": [
-          "Code is clean, well-commented, and adheres to the style guidelines.",
-          "No redundant or dead code remains.",
-          "Best practices for maintainability are followed."
-        ],
-        "sub_goals": [
-          "Conduct a thorough review for readability and maintainability.",
-          "Ensure that code follows the latest style guidelines and patterns."
-        ]
-      }
-    ]
-  }
+    {
+      "name": "Modularization and performance",
+      "description": "Prioritize modular code design and performance optimization. Ensure code is easy to maintain, extend, and debug without compromising efficiency.",
+      "validation_rule": "All new code should be modular and optimized for performance. Ensure each function and module can be easily extended or maintained."
+    },
+    {
+      "name": "Final output verification",
+      "description": "Ensure all final outputs, whether code, documentation, or execution, pass strict validation before finalizing. Include detailed logs of actions and verify content integrity.",
+      "validation_rule": "Final outputs must pass a rigorous verification process, with clear logs detailing actions and confirming content integrity before finalization."
+    },
+    {
+      "name": "Validation before execution",
+      "description": "Before executing any system commands, scripts, or configurations, ensure all conditions are validated, and no critical steps are skipped. Implement automatic rollback for recovery.",
+      "validation_rule": "Always validate conditions before execution. Ensure changes are reversible and recovery steps are in place if something goes wrong."
+    },
+    {
+      "name": "No unnecessary abstraction",
+      "description": "AI must avoid unnecessary abstraction or overcomplication of solutions.",
+      "validation_rule": "Ensure each solution is simple and efficient without added complexity."
+    },
+    {
+      "name": "Minimal comments & structure",
+      "description": "AI should provide minimal comments, focusing on clarity without excessive explanations.",
+      "validation_rule": "Ensure comments are concise and to the point, providing just enough context for understanding."
+    },
+    {
+      "name": "Correct environment handling",
+      "description": "AI should ensure the correct environment and paths (e.g., Ruby on Rails, OpenBSD) are used.",
+      "validation_rule": "Always use the correct environment and paths to ensure proper execution."
+    }
+  ],
+  "settings": {
+    "logging-level": "detailed",
+    "validation-depth": "high",
+    "comment-language": "English",
+    "modular-code-priority": true,
+    "error-rollback": true,
+    "structure-preservation": true,
+    "auto-iteration": true,
+    "iteration-limit": 10,
+    "allow-early-iteration-exit": true,
+    "rollback-on-iteration-error": true,
+    "pre-and-post-validation": true,
+    "always-include-past-improvements": true,
+    "share-final-iteration-only": true,
+    "quiet-mode": true,
+    "log-critical-issues": true
+  },
+  "execution-policies": [
+    {
+      "policy-name": "strict-output-management",
+      "description": "Strict enforcement of output integrity, ensuring no truncation or omission. Every task output must be fully restored and validated.",
+      "execution-rule": "Halt execution if truncation, omission, or deletion is detected. Restore the previous valid state and retry the task until no issues remain."
+    },
+    {
+      "policy-name": "iteration-validation",
+      "description": "Maintain 5-10 iterations for all tasks, validating each against prior iterations and ensuring improvements with each cycle.",
+      "execution-rule": "Each iteration must be validated and refined progressively to meet the defined structure and content integrity before proceeding."
+    }
+  ],
+  "phases": [
+    {
+      "order": 1,
+      "name": "Deep Analysis",
+      "instructions": "Review all documentation and code to fully understand the context, irrespective of the language or framework. Understand the intended output and configuration content.",
+      "completion_criteria": ["Achieve full understanding of details and context.", "Eliminate ambiguity regarding intended functionality and output."],
+      "sub_goals": ["Review dependencies and environmental requirements.", "Ensure all setup instructions are clear and complete."]
+    },
+    {
+      "order": 2,
+      "name": "Fleshing out",
+      "instructions": "Compare the code to its documentation and competitor implementations to identify missing features; iteratively develop features until criteria are met for any language or framework.",
+      "completion_criteria": ["All features are fully developed with clear examples.", "All missing elements have been incorporated."],
+      "sub_goals": ["Ensure all core functionalities are present before beginning new features.", "Verify completeness of each feature with examples."]
+    },
+    {
+      "order": 3,
+      "name": "Debugging",
+      "instructions": "Identify and fix bugs, inconsistencies, and logic gaps. Simulate a trace of execution to uncover bugs and pitfalls.",
+      "completion_criteria": ["All issues are resolved.", "No new issues are introduced."],
+      "sub_goals": ["Run tests on edge cases and verify behavior under stress.", "Simulate execution across different platforms (e.g., local, staging, production)."]
+    },
+    {
+      "order": 4,
+      "name": "Validation & Finalization",
+      "instructions": "Verify that the final product is deployable, well-documented, and production-ready. Streamline without sacrificing functionality or exact configuration content.",
+      "completion_criteria": ["Final version meets production standards and is fully validated.", "Documentation and configuration are comprehensive and self-contained."],
+      "sub_goals": ["Ensure all configurations and code are production-ready.", "Double-check that all dependencies are correctly versioned."]
+    },
+    {
+      "order": 5,
+      "name": "Code Review",
+      "instructions": "Ensure that the code follows best practices, is readable, and adheres to style guidelines. This step may be optional depending on project complexity.",
+      "completion_criteria": ["Code is clean, well-commented, and adheres to style guidelines.", "No redundant or dead code remains.", "Best practices for maintainability are followed."],
+      "sub_goals": ["Conduct a thorough review for readability and maintainability.", "Ensure code follows the latest style guidelines and patterns."]
+    }
+  ]
 }
 

commit 9b916ae60d1716043b652f82007f7926c24b7ee6
Author: dev <dev@dev.openbsd.amsterdam>
Date:   Sat Feb 15 04:23:52 2025 +0100

    TMP

diff --git a/master.json b/master.json
new file mode 100644
index 0000000..3cdcdc7
--- /dev/null
+++ b/master.json
@@ -0,0 +1,126 @@
+{
+  "prompts": {
+    "metadata": {
+      "version": "14.4.0",
+      "description": "Rules for iterative code improvement and completion for ChatGPT. After modifying this file, update the version number and run the file through its own rules and phases."
+    },
+    "system_message": "STRICTLY FOLLOW THIS prompts.json; DISCARD PRIOR VERSIONS. Always begin at Phase 1 and progress sequentially.",
+    "rules": {
+      "integrity": [
+        "Read every line of each file, excluding dot-files/folders unless requested.",
+        "Maintain integrity via line counts, checksums, and character-level comparisons.",
+        "No truncation, omission, or unwarranted simplification allowed."
+      ],
+      "formatting": [
+        "Use ASCII-only characters (no emoticons or special symbols)."
+      ],
+      "documentation": [
+        "Adhere to Strunk & White for brevity and clarity; omit redundant comments if the code is self-explanatory."
+      ],
+      "code_organization": [
+        "Avoid unnecessary modularization. Do not create helper functions if they overcomplicate the script.",
+        "Prefer inline multi-line constructs (e.g., heredocs) with proper variable expansion to write files or long string outputs in one block.",
+        "Group content chronologically and by importance, while preserving original features and comments."
+      ],
+      "optimization": [
+        "Continuously remove redundancies and streamline without sacrificing completeness and project integrity."
+      ]
+    },
+    "settings": {
+      "auto_iteration": {
+        "enabled": true
+      },
+      "max_iterations": {
+        "value": 10
+      },
+      "allow_early_exit": {
+        "enabled": true
+      },
+      "rollback_on_error": {
+        "enabled": true
+      },
+      "validation": {
+        "enabled": true
+      },
+      "merge_improvements": {
+        "enabled": true
+      },
+      "final_only": {
+        "enabled": true
+      },
+      "quiet_mode": {
+        "enabled": true,
+        "log_critical_issues": true
+      }
+    },
+    "phases": [
+      {
+        "order": 1,
+        "name": "Deep Analysis",
+        "instructions": "Review all documentation and code to fully grasp the context, irrespective of the language or framework. Understand the intended output and configuration content.",
+        "completion_criteria": [
+          "Achieve full understanding of details and context.",
+          "Eliminate any ambiguity regarding intended functionality and output."
+        ],
+        "sub_goals": [
+          "Review all dependencies and environmental requirements.",
+          "Ensure all setup instructions are clear and complete."
+        ]
+      },
+      {
+        "order": 2,
+        "name": "Fleshing out",
+        "instructions": "Compare the code to its documentation and competitor implementations to identify missing features; iteratively develop features until criteria are met for any language or framework.",
+        "completion_criteria": [
+          "All features are fully developed with clear examples.",
+          "All missing elements have been incorporated."
+        ],
+        "sub_goals": [
+          "Ensure all core functionalities are present before beginning new features.",
+          "Verify the completeness of each feature with examples."
+        ]
+      },
+      {
+        "order": 3,
+        "name": "Debugging",
+        "instructions": "Identify and fix bugs, inconsistencies, and logic gaps; imagine you're the official code interpreter for the language or framework in question, and conduct a simulated execution trace from start to finish to uncover bugs and pitfalls.",
+        "completion_criteria": [
+          "All identified issues are resolved.",
+          "No new issues are introduced."
+        ],
+        "sub_goals": [
+          "Run tests on edge cases and verify behavior under stress.",
+          "Simulate execution across different platforms (e.g., local, staging, production)."
+        ]
+      },
+      {
+        "order": 4,
+        "name": "Validation & Finalization",
+        "instructions": "Verify that the final product is deployable, well-documented, and production-ready across various applications and frameworks; streamline without sacrificing functionality or the exact configuration content.",
+        "completion_criteria": [
+          "Final version meets production standards and is fully validated.",
+          "Documentation and configuration are comprehensive and self-contained."
+        ],
+        "sub_goals": [
+          "Ensure all configurations and code are in their final, production-ready state.",
+          "Double-check that all dependencies are included and versioned correctly."
+        ]
+      },
+      {
+        "order": 5,
+        "name": "Code Review",
+        "instructions": "Ensure that the code follows best practices, is readable, and adheres to style guidelines. This step may be optional based on the project's complexity.",
+        "completion_criteria": [
+          "Code is clean, well-commented, and adheres to the style guidelines.",
+          "No redundant or dead code remains.",
+          "Best practices for maintainability are followed."
+        ],
+        "sub_goals": [
+          "Conduct a thorough review for readability and maintainability.",
+          "Ensure that code follows the latest style guidelines and patterns."
+        ]
+      }
+    ]
+  }
+}
+
```

## `master.json`
```
{
  "meta": {
    "version": "v10.0.0",
    "updated": "2025-07-02T18:32:07Z",
    "by": "anon987654321",
    "description": "Self-optimizing project completion system with world-class standards"
  },
  "workflow": {
    "mode_detection": {
      "simple": ["basic_implementation", "single_stack", "minimal_features"],
      "complex": ["business_plan", "design_system", "multi_technology", "visualization", "ai_integration", "async_processing", "browser_automation"]
    },
    "phases": {
      "simple": ["analyze", "build", "verify", "package"],
      "complex": ["empathize_and_analyze", "define_and_design", "ideate_and_architect", "prototype_and_implement", "test_and_validate", "optimize_and_refine", "deliver_and_evolve"]
    },
    "execution": {
      "auto_iterate": true,
      "max_iterations": 3,
      "validation_required": true,
      "ai_enhancement": "enabled"
    }
  },
  "core": {
    "communication": {
      "style": "strunk_white_accessibility_conscious",
      "format": "essential_only_no_truncation",
      "temperature": {
        "analysis": 0.2,
        "creativity": 0.9,
        "implementation": 0.1,
        "business": 0.4
      }
    },
    "limits": {
      "memory": "unlimited_with_gc",
      "timeout": "unlimited_with_user_control",
      "recursion": "unlimited_with_circuit_breaker"
    },
    "principles": {
      "security": "zero_trust_defense_in_depth",
      "quality": "world_class_standards",
      "accessibility": "wcag_2_2_aaa_compliant",
      "performance": "95_plus_core_web_vitals",
      "formatting": "universal_consistency",
      "preservation": "never_truncate_preserve_logic"
    },
    "multi_perspective": {
      "roles": [
        {"role": "security_expert", "temperature": 0.2, "weight": 0.25},
        {"role": "architect", "temperature": 0.4, "weight": 0.20},
        {"role": "creative_innovator", "temperature": 0.9, "weight": 0.15},
        {"role": "performance_engineer", "temperature": 0.3, "weight": 0.15},
        {"role": "openbsd_specialist", "temperature": 0.3, "weight": 0.15},
        {"role": "rails_expert", "temperature": 0.4, "weight": 0.10}
      ],
      "consensus_threshold": 0.7
    }
  },
  "stacks": {
    "detection": {
      "rails": ["Gemfile", "config/application.rb", "app/"],
      "ruby": ["*.rb", "Gemfile", "Rakefile"],
      "frontend": ["*.html", "*.css", "*.js", "package.json"],
      "shell": ["*.sh", "*.zsh", "*.bash"],
      "business": ["business_plan", "canvas", "financial_model"],
      "animation": ["babylon.js", "three.js", "d3.js", "svg_animations"],
      "async": ["async", "concurrent", "parallel", "queue"],
      "browser": ["ferrum", "selenium", "playwright", "puppeteer"],
      "scraping": ["nokogiri", "mechanize", "httparty"]
    },
    "templates": {
      "rails": {
        "version": "8.0+",
        "features": ["hotwire", "stimulus", "solid_queue"],
        "security": ["strong_params", "csrf_protection", "pundit"],
        "performance": ["falcon_server", "fragment_caching"]
      },
      "ruby": {
        "version": "3.3+",
        "patterns": ["frozen_string_literal", "yard_docs", "solid_principles"],
        "tools": ["rubocop", "rspec", "bundler"],
        "async": ["async", "concurrent-ruby", "sidekiq"]
      },
      "frontend": {
        "standards": ["html5", "wcag_2.2_aaa", "mobile_first"],
        "performance": ["core_web_vitals_95_plus", "gpu_acceleration"],
        "design": ["golden_ratio", "8px_grid", "modular_scale"]
      },
      "shell": {
        "compatibility": ["posix", "zsh", "openbsd_ksh"],
        "safety": ["set_euo_pipefail", "input_validation"],
        "openbsd": ["pledge_unveil", "doas"]
      }
    }
  },
  "formatting": {
    "universal": {
      "indentation": {"type": "spaces", "size": 2},
      "quotes": "double_quotes_consistent",
      "line_endings": "unix_lf",
      "alignment": "optical_over_mathematical",
      "newlines": "semantic_grouping"
    },
    "accessibility": {
      "alt_text": "descriptive_contextual",
      "aria_labels": "comprehensive_semantic",
      "heading_hierarchy": "logical_sequential",
      "focus_indicators": "high_contrast_visible"
    },
    "language_specific": {
      "ruby": {
        "frozen_string_literal": "required",
        "hash_syntax": "symbol_to_proc",
        "method_chaining": "semantic_alignment",
        "async_patterns": "clear_formatting"
      },
      "javascript": {
        "semicolons": "always",
        "const_let_var": "const_first",
        "async_await": "prefer_over_promises"
      },
      "css": {
        "property_ordering": "logical_groups",
        "custom_properties": "semantic_naming",
        "media_queries": "mobile_first"
      }
    }
  },
  "design_system": {
    "principles": ["clarity_over_cleverness", "accessibility_first", "mathematical_foundation"],
    "typography": {
      "scale": "golden_ratio_1618",
      "base_size": "16px",
      "font_stacks": {
        "primary": "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
        "monospace": "'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', monospace"
      },
      "accessibility": {"contrast_ratio": "7:1", "font_size_min": "16px"}
    },
    "color_system": {
      "methodology": "semantic_hsl",
      "accessibility": "wcag_2_2_aaa",
      "modes": ["light", "dark", "high_contrast"]
    },
    "spatial_system": {
      "base_unit": "0.5rem",
      "grid": "8pt_baseline",
      "golden_ratio": "1.618_proportions"
    },
    "motion": {
      "duration": {"fast": "150ms", "normal": "300ms", "slow": "500ms"},
      "easing": "cubic-bezier(0.25, 0.1, 0.25, 1)",
      "accessibility": "respect_prefers_reduced_motion",
      "performance": "60fps_minimum"
    }
  },
  "business_strategy": {
    "framework": "design_thinking_lean_startup_agile",
    "tools": {
      "lean_canvas": "monthly_updates",
      "okr": "quarterly_cycles",
      "design_thinking": "continuous_iteration"
    },
    "localization": {
      "nordic": ["norwegian", "swedish", "danish", "icelandic"],
      "communication": "direct_transparent",
      "currency": "nok_sek_dkk_isk"
    }
  },
  "specialized_capabilities": {
    "visualization": {
      "3d": ["babylon_js", "three_js"],
      "charts": ["d3_js", "interactive_svg"],
      "animation": ["gpu_accelerated", "mathematical_precision"]
    },
    "async_processing": {
      "patterns": ["concurrent_ruby", "async_gem", "actor_model"],
      "security": ["rate_limiting", "resource_limits", "timeout_protection"],
      "monitoring": ["performance_metrics", "error_tracking"]
    },
    "browser_automation": {
      "frameworks": ["ferrum", "selenium", "playwright"],
      "security": ["unveil_restrictions", "pledge_limits", "sandboxing"],
      "performance": ["headless_optimization", "concurrent_sessions"]
    },
    "scraping": {
      "libraries": ["nokogiri", "mechanize", "httparty"],
      "patterns": ["rate_limiting", "retry_mechanisms", "error_recovery"],
      "ethics": ["robots_txt_compliance", "respectful_crawling"]
    }
  },
  "quality_assurance": {
    "gates": {
      "syntax": "no_errors",
      "tests": "90_percent_coverage",
      "security": "zero_trust_a_plus",
      "performance": "95_plus_core_web_vitals",
      "accessibility": "wcag_2_2_aaa",
      "formatting": "universal_consistency"
    },
    "tools": {
      "linting": ["rubocop", "eslint"],
      "testing": ["rspec", "jest", "playwright"],
      "security": ["brakeman", "bundler_audit"],
      "performance": ["lighthouse", "web_vitals"],
      "accessibility": ["axe_core"]
    },
    "ai_enhancement": {
      "code_review": "semantic_analysis",
      "security": "vulnerability_detection",
      "performance": "predictive_analysis",
      "accessibility": "automated_validation"
    }
  },
  "security": {
    "baseline": ["input_validation", "output_encoding", "secure_defaults", "zero_trust"],
    "by_stack": {
      "rails": ["secure_headers", "brakeman", "pundit"],
      "frontend": ["csp_headers", "sri_integrity", "https_only"],
      "shell": ["input_sanitization", "privilege_dropping"],
      "openbsd": ["pledge", "unveil", "doas"],
      "browser": ["sandbox_isolation", "resource_limits"],
      "async": ["rate_limiting", "circuit_breakers"]
    }
  },
  "deployment": {
    "environments": ["development", "staging", "production"],
    "requirements": {
      "docs": ["readme", "setup", "api_docs"],
      "scripts": ["install", "test", "deploy"],
      "configs": ["environment_examples", "monitoring"]
    },
    "monitoring": {
      "health": ["service_status", "resource_usage"],
      "logging": ["error_tracking", "performance_metrics"],
      "alerts": ["service_down", "high_error_rate"]
    }
  },
  "self_optimization": {
    "philosophy": "surgical_enhancement_preserve_core",
    "triggers": ["performance_degradation", "error_increase", "user_feedback"],
    "forbidden_removals": ["security", "accessibility", "never_truncate", "world_class_standards"],
    "success_metrics": {
      "completion_rate": "95_percent",
      "satisfaction": "nps_70_plus",
      "quality": "world_class_compliance",
      "performance": "95_plus_lighthouse"
    }
  }
}```

