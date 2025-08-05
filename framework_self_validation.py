#!/usr/bin/env python3
"""
Framework Self-Validation System for prompts.json v38.0.0

Applies the framework's own standards to itself to ensure complete self-enforcement
and demonstrate framework consistency through meta-validation.
"""

import json
import sys
from pathlib import Path
from typing import Dict, List, Any, Tuple

class FrameworkSelfValidator:
    """Validates that the framework follows its own principles."""
    
    def __init__(self, framework_path: str):
        self.framework_path = Path(framework_path)
        self.framework_data = self._load_framework()
        self.violations = []
        self.suggestions = []
    
    def _load_framework(self) -> Dict[str, Any]:
        """Load and parse the framework JSON."""
        try:
            with open(self.framework_path, 'r') as f:
                return json.load(f)
        except Exception as e:
            raise ValueError(f"Failed to load framework: {e}")
    
    def validate_cognitive_load(self) -> Dict[str, Any]:
        """Validate 7±2 cognitive load principle compliance."""
        violations = []
        
        # Check top-level sections (should be 5-9)
        top_level_count = len(self.framework_data.keys())
        if top_level_count > 9:
            violations.append({
                "type": "cognitive_overload",
                "location": "root",
                "count": top_level_count,
                "limit": 9,
                "severity": "high"
            })
        
        # Check subsections
        for key, value in self.framework_data.items():
            if isinstance(value, dict):
                sub_count = len(value.keys())
                if sub_count > 9:
                    violations.append({
                        "type": "cognitive_overload",
                        "location": key,
                        "count": sub_count,
                        "limit": 9,
                        "severity": "medium"
                    })
            elif isinstance(value, list) and len(value) > 9:
                violations.append({
                    "type": "cognitive_overload",
                    "location": key,
                    "count": len(value),
                    "limit": 9,
                    "severity": "medium"
                })
        
        return {
            "compliant": len(violations) == 0,
            "violations": violations,
            "suggestions": self._generate_cognitive_load_suggestions(violations)
        }
    
    def validate_progressive_disclosure(self) -> Dict[str, Any]:
        """Check for progressive disclosure implementation."""
        framework_str = json.dumps(self.framework_data)
        
        # Look for progressive disclosure patterns
        reveal_on_count = framework_str.count('"reveal_on"')
        essential_first_count = framework_str.count('"essential_first"')
        complexity_indicators = framework_str.count('"complexity"')
        
        compliant = reveal_on_count > 0 or essential_first_count > 0
        
        return {
            "compliant": compliant,
            "patterns_found": {
                "reveal_on": reveal_on_count,
                "essential_first": essential_first_count,
                "complexity_indicators": complexity_indicators
            },
            "suggestions": [
                "Add 'reveal_on' triggers for complex sections",
                "Implement 'essential_first' information hierarchy",
                "Add complexity indicators for cognitive load management"
            ] if not compliant else []
        }
    
    def validate_dry_compliance(self) -> Dict[str, Any]:
        """Check for DRY (Don't Repeat Yourself) violations."""
        framework_str = json.dumps(self.framework_data)
        
        # Common patterns that might indicate repetition
        patterns = {
            "required": framework_str.count('"required"'),
            "mandatory": framework_str.count('"mandatory"'),
            "validation_required": framework_str.count('validation_required'),
            "error_handling": framework_str.count('error_handling'),
            "essential": framework_str.count('"essential"')
        }
        
        violations = []
        for pattern, count in patterns.items():
            if count > 10:  # Threshold for potential DRY violation
                violations.append({
                    "pattern": pattern,
                    "occurrences": count,
                    "threshold": 10,
                    "severity": "medium" if count < 20 else "high"
                })
        
        return {
            "compliant": len(violations) == 0,
            "patterns": patterns,
            "violations": violations,
            "suggestions": [
                "Create reusable pattern libraries for common validations",
                "Abstract repeated validation logic into shared functions",
                "Consolidate similar error handling approaches"
            ] if violations else []
        }
    
    def validate_self_enforcement(self) -> Dict[str, Any]:
        """Check if framework has self-enforcement mechanisms."""
        framework_str = json.dumps(self.framework_data)
        
        indicators = {
            "self_validated": '"self_validated"' in framework_str,
            "health_checks": 'health_check' in framework_str,
            "validation_framework": '"validation_framework"' in framework_str,
            "auto_applies": '"auto_applies"' in framework_str
        }
        
        compliant = sum(indicators.values()) >= 2
        
        return {
            "compliant": compliant,
            "indicators": indicators,
            "suggestions": [
                "Add framework health check mechanisms",
                "Implement self-validation routines",
                "Create automated enforcement rules"
            ] if not compliant else []
        }
    
    def _generate_cognitive_load_suggestions(self, violations: List[Dict]) -> List[str]:
        """Generate suggestions for fixing cognitive load violations."""
        suggestions = []
        
        for violation in violations:
            if violation["location"] == "root":
                suggestions.append(
                    "Consider grouping related top-level sections under categorical containers"
                )
            else:
                suggestions.append(
                    f"Implement progressive disclosure for '{violation['location']}' "
                    f"({violation['count']} items)"
                )
        
        return suggestions
    
    def run_comprehensive_validation(self) -> Dict[str, Any]:
        """Run all validation checks and return comprehensive results."""
        results = {
            "framework_version": self.framework_data.get("meta", {}).get("version", "unknown"),
            "validation_timestamp": self.framework_data.get("meta", {}).get("timestamp", "unknown"),
            "cognitive_load": self.validate_cognitive_load(),
            "progressive_disclosure": self.validate_progressive_disclosure(),
            "dry_compliance": self.validate_dry_compliance(),
            "self_enforcement": self.validate_self_enforcement()
        }
        
        # Calculate overall compliance
        compliance_scores = [
            results["cognitive_load"]["compliant"],
            results["progressive_disclosure"]["compliant"],
            results["dry_compliance"]["compliant"],
            results["self_enforcement"]["compliant"]
        ]
        
        results["overall_compliance"] = {
            "score": sum(compliance_scores) / len(compliance_scores),
            "passing": all(compliance_scores),
            "areas_needing_improvement": sum(1 for score in compliance_scores if not score)
        }
        
        return results

def main():
    """Run framework self-validation."""
    if len(sys.argv) != 2:
        print("Usage: python3 framework_self_validation.py <prompts.json>")
        sys.exit(1)
    
    framework_path = sys.argv[1]
    
    try:
        validator = FrameworkSelfValidator(framework_path)
        results = validator.run_comprehensive_validation()
        
        print("🔍 Framework Self-Validation Report")
        print("=" * 50)
        print(f"Framework Version: {results['framework_version']}")
        print(f"Validation Time: {results['validation_timestamp']}")
        print()
        
        # Cognitive Load Analysis
        cognitive = results["cognitive_load"]
        status = "✅" if cognitive["compliant"] else "❌"
        print(f"{status} Cognitive Load (7±2 Principle): {'COMPLIANT' if cognitive['compliant'] else 'VIOLATIONS FOUND'}")
        if cognitive["violations"]:
            for violation in cognitive["violations"]:
                print(f"  ⚠️  {violation['location']}: {violation['count']} items (limit: {violation['limit']})")
        
        # Progressive Disclosure
        disclosure = results["progressive_disclosure"]
        status = "✅" if disclosure["compliant"] else "❌"
        print(f"{status} Progressive Disclosure: {'IMPLEMENTED' if disclosure['compliant'] else 'MISSING'}")
        
        # DRY Compliance
        dry = results["dry_compliance"]
        status = "✅" if dry["compliant"] else "❌"
        print(f"{status} DRY Principle: {'COMPLIANT' if dry['compliant'] else 'VIOLATIONS FOUND'}")
        if dry["violations"]:
            for violation in dry["violations"]:
                print(f"  ⚠️  Pattern '{violation['pattern']}': {violation['occurrences']} occurrences")
        
        # Self-Enforcement
        enforcement = results["self_enforcement"]
        status = "✅" if enforcement["compliant"] else "❌"
        print(f"{status} Self-Enforcement: {'IMPLEMENTED' if enforcement['compliant'] else 'MISSING'}")
        
        # Overall Assessment
        overall = results["overall_compliance"]
        print()
        print(f"📊 Overall Compliance Score: {overall['score']:.1%}")
        print(f"🎯 Framework Self-Validation: {'PASSING' if overall['passing'] else 'NEEDS IMPROVEMENT'}")
        
        if not overall["passing"]:
            print()
            print("🔧 Recommended Actions:")
            for section, data in results.items():
                if isinstance(data, dict) and "suggestions" in data and data["suggestions"]:
                    print(f"  {section.replace('_', ' ').title()}:")
                    for suggestion in data["suggestions"]:
                        print(f"    • {suggestion}")
        
        return 0 if overall["passing"] else 1
        
    except Exception as e:
        print(f"❌ Validation failed: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())