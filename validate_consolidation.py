#!/usr/bin/env python3
"""
Validation script for consolidated prompts.json
Verifies that all content is self-contained and no external references remain.
"""

import json
import sys
import os

def validate_consolidation():
    """Validate the consolidated prompts.json file"""
    
    print("🔍 Validating consolidated prompts.json...")
    
    # Check if file exists
    if not os.path.exists('prompts.json'):
        print("❌ prompts.json not found!")
        return False
    
    # Validate JSON structure
    try:
        with open('prompts.json', 'r') as f:
            data = json.load(f)
        print("✅ JSON structure is valid")
    except json.JSONDecodeError as e:
        print(f"❌ JSON validation failed: {e}")
        return False
    
    # Check for @ref: references
    with open('prompts.json', 'r') as f:
        content = f.read()
    
    ref_count = content.count('@ref:')
    if ref_count > 0:
        print(f"❌ Found {ref_count} @ref: references - content not fully consolidated")
        return False
    else:
        print("✅ No @ref: references found - all content is inlined")
    
    # Check for required sections
    required_sections = [
        'file_policy',
        'core_restrictions', 
        'behavioral_rules',
        'universal_standards',
        'design_system',
        'web_development',
        'business_strategy',
        'autonomous_operation',
        'execution',
        'design_intelligence'
    ]
    
    missing_sections = []
    for section in required_sections:
        if section not in data:
            missing_sections.append(section)
    
    if missing_sections:
        print(f"❌ Missing required sections: {missing_sections}")
        return False
    else:
        print("✅ All required sections present")
    
    # Check file policy restrictions
    file_policy = data.get('file_policy', {})
    if file_policy.get('file_creation_restrictions', {}).get('status') != 'FORBIDDEN':
        print("❌ File creation restrictions not properly configured")
        return False
    else:
        print("✅ File creation restrictions properly configured")
    
    # Check core restrictions
    core_restrictions = data.get('core_restrictions', {})
    immutable_rules = core_restrictions.get('immutable_rules', [])
    if 'file_creation_requires_explicit_approval' not in immutable_rules:
        print("❌ Core restrictions not properly configured")
        return False
    else:
        print("✅ Core restrictions properly configured")
    
    # Check behavioral rules
    behavioral_rules = data.get('behavioral_rules', {})
    core_rules = behavioral_rules.get('core_rules', {})
    if 'approval_required' not in core_rules or 'never_truncate_policy' not in core_rules:
        print("❌ Core behavioral rules missing")
        return False
    else:
        print("✅ Core behavioral rules present")
    
    # File size check
    file_size = os.path.getsize('prompts.json')
    print(f"📊 File size: {file_size:,} bytes")
    
    # Line count
    with open('prompts.json', 'r') as f:
        line_count = len(f.readlines())
    print(f"📊 Line count: {line_count:,} lines")
    
    print("\n🎉 Consolidation validation successful!")
    print("📋 Summary:")
    print("   • All external references inlined")
    print("   • File creation explicitly forbidden")
    print("   • All behavioral rules preserved")
    print("   • Single self-contained configuration file")
    
    return True

if __name__ == '__main__':
    success = validate_consolidation()
    sys.exit(0 if success else 1)