#!/bin/bash

# Script to sync fork with upstream and rebase fixes
# Usage: ./upstream_update.sh

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 Syncing fork with upstream sidekick.nvim"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo "❌ Error: Not a git repository"
    exit 1
fi

# Check if upstream remote exists
if ! git remote | grep -q "^upstream$"; then
    echo "⚠️  upstream remote not found. Adding it now..."
    git remote add upstream https://github.com/folke/sidekick.nvim.git
    echo "✅ Added upstream remote"
fi

# Save current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "📍 Current branch: $CURRENT_BRANCH"

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  You have uncommitted changes. Please commit or stash them first."
    git status --short
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📥 Step 1: Fetching upstream changes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
git fetch upstream

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔀 Step 2: Updating main branch"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
git checkout main
git merge upstream/main

if [ $? -eq 0 ]; then
    echo "✅ Main branch updated successfully"
else
    echo "❌ Failed to merge upstream/main"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⬆️  Step 3: Pushing main to your fork"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
git push origin main

if [ $? -eq 0 ]; then
    echo "✅ Pushed main to origin"
else
    echo "⚠️  Failed to push main (this is OK if you don't have push access)"
fi

# Only rebase submit-fix if it exists
if git show-ref --verify --quiet refs/heads/submit-fix; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔧 Step 4: Rebasing submit-fix branch"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    git checkout submit-fix
    
    if git rebase main; then
        echo "✅ Rebased submit-fix successfully"
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "⬆️  Step 5: Pushing submit-fix (force with lease)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # Check if remote branch exists
        if git ls-remote --heads origin submit-fix | grep -q submit-fix; then
            git push origin submit-fix --force-with-lease
            if [ $? -eq 0 ]; then
                echo "✅ Pushed submit-fix to origin"
            else
                echo "⚠️  Failed to push submit-fix"
            fi
        else
            echo "ℹ️  Remote branch doesn't exist yet. Use: git push origin submit-fix"
        fi
    else
        echo "❌ Rebase failed! You may need to resolve conflicts manually."
        echo "   After resolving conflicts, run:"
        echo "   git rebase --continue"
        echo "   git push origin submit-fix --force-with-lease"
        exit 1
    fi
else
    echo ""
    echo "ℹ️  submit-fix branch not found, skipping rebase"
fi

# Return to original branch
if [ "$CURRENT_BRANCH" != "$(git branch --show-current)" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔙 Returning to branch: $CURRENT_BRANCH"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    git checkout "$CURRENT_BRANCH"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Update complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Commit comparison:"
git log --oneline main..submit-fix 2>/dev/null || echo "No custom commits"
echo ""
