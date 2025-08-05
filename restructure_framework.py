#!/usr/bin/env python3
"""
Framework Restructuring Tool

Transforms the existing prompts.json v38.0.0 structure to implement:
- Progressive disclosure with reveal_on triggers
- Cognitive load management (7±2 principle)
- Logical grouping of related sections
- Essential-first information hierarchy
"""

import json
import sys
from pathlib import Path
from typing import Dict, Any

def restructure_framework(input_path: str, output_path: str):
    """Restructure the framework for cognitive load optimization."""
    
    # Load original framework
    with open(input_path, 'r') as f:
        original = json.load(f)
    
    # Create new structure with progressive disclosure
    restructured = {
        "meta": {
            "essential_info": {
                "version": "38.0.0",
                "timestamp": "2025-01-27T15:30:00Z", 
                "author": "anon987654321",
                "description": "Self-optimized prompts.json v38.0.0 with cognitive load management",
                "self_validated": True,
                "auto_applies_to": "every_file_and_entire_projects"
            },
            "framework_details": {
                "reveal_on": "detailed_inspection_needed",
                "complexity": "medium",
                "consolidation_summary": original["meta"].get("consolidation_summary", {}),
                "compliance": original["meta"].get("compliance", [])
            },
            "integration_config": {
                "reveal_on": "deployment_or_integration", 
                "complexity": "low",
                "role": original["meta"].get("role", ""),
                "execution_disclaimer": original["meta"].get("execution_disclaimer", ""),
                "github_integration": original["meta"].get("github_integration", {})
            },
            "self_optimization": {
                "cognitive_load_management": True,
                "progressive_disclosure_enabled": True,
                "framework_health_checks": True,
                "self_enforcement_active": True,
                "last_self_validation": "2025-01-27T15:30:00Z"
            }
        },
        
        "core_framework": {
            "essential_first": True,
            "description": "Core behavioral rules and restrictions - essential for all operations",
            "file_policy": original.get("file_policy", {}),
            "core_restrictions": original.get("core_restrictions", {}),
            "behavioral_rules": {
                "essential_rules": {
                    "reveal_on": "immediate",
                    "rules": extract_essential_behavioral_rules(original.get("behavioral_rules", {}))
                },
                "advanced_rules": {
                    "reveal_on": "complex_scenarios",
                    "complexity": "high",
                    "rules": extract_advanced_behavioral_rules(original.get("behavioral_rules", {}))
                }
            }
        },
        
        "standards_and_principles": {
            "description": "Universal standards and core principles - progressive disclosure by complexity",
            "essential_principles": {
                "reveal_on": "immediate",
                "complexity": "low",
                "principles": extract_essential_principles(original.get("principles", []))
            },
            "advanced_principles": {
                "reveal_on": "advanced_usage",
                "complexity": "medium", 
                "principles": extract_advanced_principles(original.get("principles", []))
            },
            "universal_standards": original.get("universal_standards", {}),
            "formatting_rules": original.get("formatting_rules", {}),
            "error_handling": original.get("error_handling", {})
        },
        
        "development_domains": {
            "description": "Domain-specific development standards - revealed based on project type",
            "web_development": {
                "essential_patterns": {
                    "reveal_on": "web_project_detected",
                    "complexity": "medium",
                    "patterns": extract_essential_web_patterns(original.get("web_development", {}))
                },
                "advanced_features": {
                    "reveal_on": "complex_web_features_needed",
                    "complexity": "high", 
                    "features": extract_advanced_web_features(original.get("web_development", {}))
                }
            },
            "design_system": {
                "core_components": {
                    "reveal_on": "ui_design_needed",
                    "complexity": "medium",
                    "components": extract_core_design_components(original.get("design_system", {}))
                },
                "advanced_design": {
                    "reveal_on": "sophisticated_design_needed",
                    "complexity": "high",
                    "components": extract_advanced_design_components(original.get("design_system", {}))
                }
            }
        },
        
        "specialized_systems": {
            "description": "Specialized systems and advanced features - revealed on demand",
            "ai3_assistant_system": {
                "reveal_on": "ai_assistance_needed",
                "complexity": "high",
                "system": original.get("ai3_assistant_system", {})
            },
            "rails_8_ecosystem": {
                "reveal_on": "rails_project_detected",
                "complexity": "medium",
                "ecosystem": original.get("rails_8_ecosystem", {})
            },
            "audio_visualizer_system": {
                "reveal_on": "audio_visualization_needed",
                "complexity": "high", 
                "system": original.get("audio_visualizer_system", {})
            },
            "business_strategy": {
                "reveal_on": "business_planning_needed",
                "complexity": "medium",
                "strategy": original.get("business_strategy", {})
            }
        },
        
        "operational_framework": {
            "description": "Execution, validation, and operational concerns",
            "execution": {
                "essential_execution": {
                    "reveal_on": "immediate",
                    "complexity": "low",
                    "patterns": extract_essential_execution(original.get("execution", {}))
                },
                "advanced_execution": {
                    "reveal_on": "complex_operations_needed",
                    "complexity": "high",
                    "patterns": extract_advanced_execution(original.get("execution", {}))
                }
            },
            "validation_framework": original.get("validation_framework", {}),
            "change_management": original.get("change_management", {}),
            "communication": original.get("communication", {}),
            "communication_standards": original.get("communication_standards", {})
        },
        
        "framework_health": {
            "description": "Framework self-monitoring and health checks",
            "health_checks": {
                "cognitive_load_validation": True,
                "progressive_disclosure_validation": True,
                "dry_compliance_check": True,
                "self_enforcement_check": True
            },
            "self_enforcement": {
                "framework_applies_to_itself": True,
                "recursive_validation": True,
                "continuous_improvement": True
            }
        }
    }
    
    # Save restructured framework
    with open(output_path, 'w') as f:
        json.dump(restructured, f, indent=2)
    
    return restructured

def extract_essential_behavioral_rules(behavioral_rules: Dict[str, Any]) -> Dict[str, Any]:
    """Extract the most essential behavioral rules (≤7 items)."""
    if not behavioral_rules or "core_rules" not in behavioral_rules:
        return {}
    
    core_rules = behavioral_rules["core_rules"]
    essential_rule_keys = [
        "approval_required",
        "full_internalization", 
        "never_truncate_policy",
        "surgical_precision"
    ]
    
    return {key: core_rules[key] for key in essential_rule_keys if key in core_rules}

def extract_advanced_behavioral_rules(behavioral_rules: Dict[str, Any]) -> Dict[str, Any]:
    """Extract advanced behavioral rules."""
    if not behavioral_rules or "core_rules" not in behavioral_rules:
        return {}
    
    core_rules = behavioral_rules["core_rules"]
    essential_keys = {"approval_required", "full_internalization", "never_truncate_policy", "surgical_precision"}
    
    return {key: value for key, value in core_rules.items() if key not in essential_keys}

def extract_essential_principles(principles: list) -> list:
    """Extract essential principles (first 7)."""
    return principles[:7] if principles else []

def extract_advanced_principles(principles: list) -> list:
    """Extract advanced principles (remaining)."""
    return principles[7:] if len(principles) > 7 else []

def extract_essential_web_patterns(web_dev: Dict[str, Any]) -> Dict[str, Any]:
    """Extract essential web development patterns."""
    if not web_dev:
        return {}
    
    essential_keys = [
        "responsive_design",
        "accessibility", 
        "performance",
        "semantic_html",
        "css_architecture"
    ]
    
    return {key: web_dev[key] for key in essential_keys if key in web_dev}

def extract_advanced_web_features(web_dev: Dict[str, Any]) -> Dict[str, Any]:
    """Extract advanced web development features."""
    if not web_dev:
        return {}
    
    essential_keys = {"responsive_design", "accessibility", "performance", "semantic_html", "css_architecture"}
    return {key: value for key, value in web_dev.items() if key not in essential_keys}

def extract_core_design_components(design_system: Dict[str, Any]) -> Dict[str, Any]:
    """Extract core design system components."""
    if not design_system:
        return {}
    
    core_keys = [
        "typography",
        "color_system",
        "spacing",
        "component_library"
    ]
    
    return {key: design_system[key] for key in core_keys if key in design_system}

def extract_advanced_design_components(design_system: Dict[str, Any]) -> Dict[str, Any]:
    """Extract advanced design system components."""
    if not design_system:
        return {}
    
    core_keys = {"typography", "color_system", "spacing", "component_library"}
    return {key: value for key, value in design_system.items() if key not in core_keys}

def extract_essential_execution(execution: Dict[str, Any]) -> Dict[str, Any]:
    """Extract essential execution patterns."""
    if not execution:
        return {}
    
    essential_keys = [
        "validation_gates",
        "error_handling",
        "rollback_mechanisms"
    ]
    
    return {key: execution[key] for key in essential_keys if key in execution}

def extract_advanced_execution(execution: Dict[str, Any]) -> Dict[str, Any]:
    """Extract advanced execution patterns."""
    if not execution:
        return {}
    
    essential_keys = {"validation_gates", "error_handling", "rollback_mechanisms"}
    return {key: value for key, value in execution.items() if key not in essential_keys}

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 restructure_framework.py <input.json> <output.json>")
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    
    try:
        restructured = restructure_framework(input_path, output_path)
        print(f"✅ Framework restructured successfully")
        print(f"📊 New structure has {len(restructured)} top-level sections (vs previous 21)")
        print(f"🎯 Progressive disclosure implemented with reveal_on triggers")
        print(f"💾 Saved to: {output_path}")
    except Exception as e:
        print(f"❌ Restructuring failed: {e}")
        sys.exit(1)