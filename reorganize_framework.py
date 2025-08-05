#!/usr/bin/env python3
"""
Framework Reorganization Tool for Cognitive Load Optimization

Reorganizes prompts.json v35.2.0+ to implement the 7±2 cognitive load principle
by creating logical groupings of related sections while preserving all functionality.
"""

import json
import sys
from pathlib import Path

def reorganize_framework(input_path: str, output_path: str):
    """Reorganize framework sections into logical cognitive load groups."""
    
    # Load original framework
    with open(input_path, 'r') as f:
        original = json.load(f)
    
    # Create the new structure with 7 main categories
    reorganized = {
        "meta": original.get("meta", {}),
        
        "core_framework": {
            "description": "Essential framework components - always visible",
            "reveal_on": "immediate",
            "complexity": "medium",
            "core": original.get("core", {}),
            "universal_standards": original.get("universal_standards", {}),
            "behavioral_rules": original.get("behavioral_rules", {}),
            "principles": original.get("principles", [])
        },
        
        "development_domains": {
            "description": "Domain-specific development standards and tools",
            "reveal_on": "domain_specific_project_detected",
            "complexity": "high",
            "web_development": original.get("web_development", {}),
            "design_system": original.get("design_system", {}),
            "music_audio_processing": original.get("music_audio_processing", {}),
            "file_processing": original.get("file_processing", {})
        },
        
        "ai_and_automation": {
            "description": "AI enhancement, automation, and intelligent capabilities",
            "reveal_on": "ai_features_needed",
            "complexity": "high",
            "ai_enhancement": original.get("ai_enhancement", {}),
            "specialized_capabilities": original.get("specialized_capabilities", {}),
            "autonomous_completion": original.get("autonomous_completion", {})
        },
        
        "business_and_communication": {
            "description": "Business strategy and communication standards",
            "reveal_on": "business_context_needed",
            "complexity": "medium",
            "business_strategy": original.get("business_strategy", {}),
            "communication": original.get("communication", {})
        },
        
        "quality_and_standards": {
            "description": "Quality assurance, formatting, and validation standards",
            "reveal_on": "quality_validation_needed", 
            "complexity": "medium",
            "quality": original.get("quality", {}),
            "formatting": original.get("formatting", {}),
            "documentation": original.get("documentation", {}),
            "validation_enhancement": original.get("validation_enhancement", {}),
            "_validation": original.get("_validation", {})
        },
        
        "operations_and_workflow": {
            "description": "Workflow management, monitoring, and operational concerns",
            "reveal_on": "operational_management_needed",
            "complexity": "medium",
            "workflow": original.get("workflow", {}),
            "monitoring": original.get("monitoring", {}),
            "execution": original.get("execution", {}),
            "system_configurations": original.get("system_configurations", {}),
            "infrastructure_preservation": original.get("infrastructure_preservation", {})
        },
        
        "framework_management": {
            "description": "Framework self-management, optimization, and maintenance",
            "reveal_on": "framework_maintenance_needed",
            "complexity": "high",
            "self_optimization": original.get("self_optimization", {}),
            "cross_reference_integrity_system": original.get("cross_reference_integrity_system", {}),
            "change_management": original.get("change_management", {}),
            "framework_self_optimization": original.get("framework_self_optimization", {}),
            "eof_metadata": original.get("eof_metadata", {})
        }
    }
    
    # Save reorganized framework
    with open(output_path, 'w') as f:
        json.dump(reorganized, f, indent=2)
    
    return reorganized

def validate_reorganization(original_path: str, reorganized_path: str):
    """Validate that no content was lost during reorganization."""
    
    with open(original_path, 'r') as f:
        original = json.load(f)
    
    with open(reorganized_path, 'r') as f:
        reorganized = json.load(f)
    
    # Extract all content from original (excluding meta)
    original_sections = set(original.keys()) - {"meta"}
    
    # Extract all content from reorganized groups
    reorganized_sections = set()
    for group_name, group_data in reorganized.items():
        if group_name == "meta":
            continue
        if isinstance(group_data, dict):
            for section_name in group_data.keys():
                if section_name not in ["description", "reveal_on", "complexity"]:
                    reorganized_sections.add(section_name)
    
    missing_sections = original_sections - reorganized_sections
    extra_sections = reorganized_sections - original_sections
    
    print(f"📊 Reorganization Validation:")
    print(f"   Original sections: {len(original_sections)}")
    print(f"   Reorganized sections: {len(reorganized_sections)}")
    print(f"   Top-level groups: {len([k for k in reorganized.keys() if k != 'meta'])}")
    
    if missing_sections:
        print(f"   ❌ Missing sections: {missing_sections}")
        return False
    elif extra_sections:
        print(f"   ❌ Extra sections: {extra_sections}")
        return False
    else:
        print(f"   ✅ All content preserved")
        return True

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 reorganize_framework.py <input.json> <output.json>")
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    
    try:
        reorganized = reorganize_framework(input_path, output_path)
        valid = validate_reorganization(input_path, output_path)
        
        if valid:
            print(f"✅ Framework reorganized successfully")
            print(f"🎯 Cognitive load optimized: 29 → 7 top-level sections")
            print(f"💾 Saved to: {output_path}")
        else:
            print(f"❌ Validation failed - content may be missing")
            sys.exit(1)
            
    except Exception as e:
        print(f"❌ Reorganization failed: {e}")
        sys.exit(1)