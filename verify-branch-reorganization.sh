#!/bin/bash

echo "=== Branch Reorganization Verification ==="
echo ""

# Check if we're in a git repo
if [ ! -d ".git" ]; then
    echo "❌ Not in a git repository"
    exit 1
fi

echo "📋 Local Branch Status:"
echo ""

# Check agent-setup
echo "1. agent-setup branch:"
if git show-ref --verify --quiet refs/heads/agent-setup; then
    echo "   ✅ Exists locally"
    echo "   Commits since base (9e395cd):"
    git log --oneline 9e395cd..agent-setup | sed 's/^/      /'
    
    # Check for AGENTS.md
    if git ls-tree agent-setup --name-only | grep -q "^AGENTS.md$"; then
        echo "   ✅ Contains AGENTS.md"
    else
        echo "   ❌ Missing AGENTS.md"
    fi
    
    # Check for justfile (should NOT be present)
    if git ls-tree agent-setup --name-only | grep -q "^justfile$"; then
        echo "   ❌ Contains justfile (should not be present)"
    else
        echo "   ✅ Does not contain justfile"
    fi
else
    echo "   ❌ Does not exist locally"
fi

echo ""

# Check db-creation-strategy
echo "2. db-creation-strategy branch:"
if git show-ref --verify --quiet refs/heads/db-creation-strategy; then
    echo "   ✅ Exists locally"
    echo "   Commits since base (9e395cd):"
    git log --oneline 9e395cd..db-creation-strategy | sed 's/^/      /'
    
    # Check for justfile
    if git ls-tree db-creation-strategy --name-only | grep -q "^justfile$"; then
        echo "   ✅ Contains justfile"
    else
        echo "   ❌ Missing justfile"
    fi
    
    # Check for AGENTS.md (should NOT be present)
    if git ls-tree db-creation-strategy --name-only | grep -q "^AGENTS.md$"; then
        echo "   ❌ Contains AGENTS.md (should not be present)"
    else
        echo "   ✅ Does not contain AGENTS.md"
    fi
else
    echo "   ❌ Does not exist locally"
fi

echo ""
echo "📡 Remote Branch Status:"
echo ""

# Check remote agent-setup
if git ls-remote --heads origin agent-setup | grep -q agent-setup; then
    echo "1. origin/agent-setup:"
    echo "   ✅ Exists on remote"
    remote_sha=$(git ls-remote --heads origin agent-setup | awk '{print $1}')
    local_sha=$(git rev-parse agent-setup 2>/dev/null || echo "")
    
    if [ "$remote_sha" = "$local_sha" ]; then
        echo "   ✅ In sync with local"
    else
        echo "   ⚠️  Out of sync with local (force push needed)"
        echo "      Remote: $remote_sha"
        echo "      Local:  $local_sha"
    fi
else
    echo "1. origin/agent-setup:"
    echo "   ❌ Does not exist on remote"
fi

echo ""

# Check remote db-creation-strategy
if git ls-remote --heads origin db-creation-strategy | grep -q db-creation-strategy; then
    echo "2. origin/db-creation-strategy:"
    echo "   ✅ Exists on remote"
else
    echo "2. origin/db-creation-strategy:"
    echo "   ⚠️  Does not exist on remote (push needed)"
fi

echo ""
echo "📊 Summary:"
echo ""

# Summary checks
local_ok=true
remote_ok=true

if ! git show-ref --verify --quiet refs/heads/agent-setup; then
    local_ok=false
fi

if ! git show-ref --verify --quiet refs/heads/db-creation-strategy; then
    local_ok=false
fi

if [ "$local_ok" = true ]; then
    echo "✅ Local branches are correctly organized"
else
    echo "❌ Local branches need attention"
fi

if git ls-remote --heads origin db-creation-strategy | grep -q db-creation-strategy; then
    remote_sha=$(git ls-remote --heads origin agent-setup | awk '{print $1}')
    local_sha=$(git rev-parse agent-setup 2>/dev/null || echo "")
    
    if [ "$remote_sha" = "$local_sha" ]; then
        echo "✅ Remote branches are in sync"
        remote_ok=true
    else
        echo "⚠️  Remote branches need to be updated (run complete-branch-reorganization.sh)"
        remote_ok=false
    fi
else
    echo "⚠️  Remote branches need to be pushed (run complete-branch-reorganization.sh)"
    remote_ok=false
fi

echo ""
if [ "$local_ok" = true ] && [ "$remote_ok" = true ]; then
    echo "🎉 Branch reorganization is complete!"
elif [ "$local_ok" = true ]; then
    echo "📝 Next step: Run ./complete-branch-reorganization.sh to push changes"
else
    echo "⚠️  Branch reorganization needs to be redone"
fi
