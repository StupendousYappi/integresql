#!/bin/bash
set -e

echo "=== Branch Reorganization Script ==="
echo ""
echo "This script will:"
echo "1. Push the new db-creation-strategy branch"
echo "2. Force-update the agent-setup branch"
echo "3. Optionally create pull requests"
echo ""

# Verify we're in the right directory
if [ ! -d ".git" ]; then
    echo "Error: Must be run from the repository root"
    exit 1
fi

# Verify branches exist locally
if ! git show-ref --verify --quiet refs/heads/agent-setup; then
    echo "Error: agent-setup branch not found"
    exit 1
fi

if ! git show-ref --verify --quiet refs/heads/db-creation-strategy; then
    echo "Error: db-creation-strategy branch not found"
    exit 1
fi

# Show current state
echo "Current branch state:"
echo ""
echo "agent-setup:"
git log --oneline agent-setup -3
echo ""
echo "db-creation-strategy:"
git log --oneline db-creation-strategy -3
echo ""

read -p "Do you want to proceed with pushing these branches? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

# Push db-creation-strategy (new branch)
echo ""
echo "Pushing db-creation-strategy branch..."
git push -u origin db-creation-strategy

# Force push agent-setup (rewritten history)
echo ""
echo "Force-pushing agent-setup branch..."
git push --force-with-lease origin agent-setup

echo ""
echo "✅ Branches pushed successfully!"
echo ""

# Ask about creating PRs
read -p "Do you want to create a PR for agent-setup → main? (yes/no): " create_pr
if [ "$create_pr" = "yes" ]; then
    if command -v gh &> /dev/null; then
        echo "Creating PR for agent-setup..."
        gh pr create --base main --head agent-setup \
            --title "Add AGENTS.md documentation" \
            --body "Adding AGENTS.md file with coding guidance for AI agents."
        echo "✅ PR created for agent-setup"
    else
        echo "⚠️  gh CLI not found. Please create the PR manually via GitHub web interface."
    fi
fi

read -p "Do you want to create a PR for db-creation-strategy → main? (yes/no): " create_feature_pr
if [ "$create_feature_pr" = "yes" ]; then
    if command -v gh &> /dev/null; then
        echo "Creating PR for db-creation-strategy..."
        gh pr create --base main --head db-creation-strategy \
            --title "Database creation strategy improvements" \
            --body "Implements database creation strategy with justfile and related improvements."
        echo "✅ PR created for db-creation-strategy"
    else
        echo "⚠️  gh CLI not found. Please create the PR manually via GitHub web interface."
    fi
fi

echo ""
echo "=== Branch reorganization complete! ==="
