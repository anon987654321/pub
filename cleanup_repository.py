#!/usr/bin/env python3
"""
Repository Cleanup Script
Removes unused copilot branches and closes redundant PRs
"""

import subprocess
import sys
import json
import re
from typing import List, Dict, Set

def run_command(cmd: List[str], capture_output=True) -> subprocess.CompletedProcess:
    """Run a command and return the result"""
    try:
        result = subprocess.run(cmd, capture_output=capture_output, text=True, check=True)
        return result
    except subprocess.CalledProcessError as e:
        print(f"Command failed: {' '.join(cmd)}")
        print(f"Error: {e.stderr}")
        return e

def get_copilot_branches() -> List[str]:
    """Get all copilot/fix-* branches from remote"""
    try:
        result = run_command(['git', 'ls-remote', '--heads', 'origin'])
        branches = []
        for line in result.stdout.splitlines():
            if 'copilot/fix-' in line:
                branch_name = line.split('refs/heads/')[-1]
                branches.append(branch_name)
        return branches
    except Exception as e:
        print(f"Error getting branches: {e}")
        return []

def switch_to_main_branch():
    """Switch to main branch if it exists, otherwise master"""
    try:
        # Try main first
        result = run_command(['git', 'checkout', 'main'])
        if result.returncode == 0:
            return 'main'
    except:
        pass
    
    try:
        # Try master
        result = run_command(['git', 'checkout', 'master'])
        if result.returncode == 0:
            return 'master'
    except:
        pass
    
    # Try to create main from origin/main
    try:
        run_command(['git', 'checkout', '-b', 'main', 'origin/main'])
        return 'main'
    except:
        pass
    
    # Try to create main from origin/master
    try:
        run_command(['git', 'checkout', '-b', 'main', 'origin/master'])
        return 'main'
    except:
        pass
    
    print("Could not switch to main or master branch")
    return None

def delete_remote_branches(branches: List[str]) -> Dict[str, bool]:
    """Delete remote branches"""
    results = {}
    
    for branch in branches:
        try:
            print(f"Deleting remote branch: {branch}")
            result = run_command(['git', 'push', 'origin', '--delete', branch])
            results[branch] = result.returncode == 0
            if result.returncode == 0:
                print(f"✓ Deleted: {branch}")
            else:
                print(f"✗ Failed to delete: {branch}")
        except Exception as e:
            print(f"✗ Error deleting {branch}: {e}")
            results[branch] = False
    
    return results

def cleanup_local_branches():
    """Clean up local tracking branches"""
    try:
        print("Cleaning up local tracking branches...")
        run_command(['git', 'remote', 'prune', 'origin'])
        print("✓ Pruned remote tracking branches")
    except Exception as e:
        print(f"Error pruning branches: {e}")

def main():
    """Main cleanup function"""
    print("Starting repository cleanup...")
    
    # Switch to main branch first
    main_branch = switch_to_main_branch()
    if not main_branch:
        print("Error: Could not switch to main branch")
        return False
    
    print(f"Switched to {main_branch} branch")
    
    # Get all copilot branches
    print("Getting list of copilot/fix-* branches...")
    copilot_branches = get_copilot_branches()
    
    if not copilot_branches:
        print("No copilot/fix-* branches found")
        return True
    
    print(f"Found {len(copilot_branches)} copilot/fix-* branches")
    
    # Delete remote branches
    print("Deleting remote copilot/fix-* branches...")
    deletion_results = delete_remote_branches(copilot_branches)
    
    # Clean up local tracking branches
    cleanup_local_branches()
    
    # Print summary
    successful_deletions = [b for b, success in deletion_results.items() if success]
    failed_deletions = [b for b, success in deletion_results.items() if not success]
    
    print("\n" + "="*50)
    print("CLEANUP SUMMARY")
    print("="*50)
    print(f"Total copilot/fix-* branches found: {len(copilot_branches)}")
    print(f"Successfully deleted: {len(successful_deletions)}")
    print(f"Failed to delete: {len(failed_deletions)}")
    
    if successful_deletions:
        print(f"\nSuccessfully deleted branches:")
        for branch in successful_deletions[:10]:  # Show first 10
            print(f"  ✓ {branch}")
        if len(successful_deletions) > 10:
            print(f"  ... and {len(successful_deletions) - 10} more")
    
    if failed_deletions:
        print(f"\nFailed to delete branches:")
        for branch in failed_deletions:
            print(f"  ✗ {branch}")
    
    print(f"\nRepository cleanup completed!")
    return len(failed_deletions) == 0

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)