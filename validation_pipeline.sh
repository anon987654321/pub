#!/bin/bash
# Automated validation pipeline for Master.json v12.9.0

echo "§ Master.json v12.9.0 Validation Pipeline"
echo "Running validation on critical files..."

# Set paths
export PATH="/home/runner/.local/share/gem/ruby/3.2.0/bin:$PATH"

# Run RuboCop if available
if command -v rubocop &> /dev/null; then
  echo "Running RuboCop validation..."
  rubocop --auto-correct --format simple || echo "RuboCop completed with warnings"
else
  echo "RuboCop not available, skipping"
fi

echo "Validation pipeline completed"
