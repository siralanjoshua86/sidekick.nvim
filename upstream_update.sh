# Upstream Update Commands

## Manual steps to sync fork with upstream

```bash
# Step 1: Fetch upstream changes
git fetch upstream

# Step 2: Update main branch
git checkout main
git merge upstream/main
git push origin main

# Step 3: Rebase submit-fix branch
git checkout submit-fix
git rebase main
git push origin submit-fix --force-with-lease

# Step 4: View your custom commits
git log --oneline main..submit-fix
```

## One-time setup (if upstream remote doesn't exist)

```bash
git remote add upstream https://github.com/folke/sidekick.nvim.git
```

## Check current status

```bash
# View all remotes
git remote -v

# Check which branch you're on
git branch

# Check for uncommitted changes
git status
```

## If rebase has conflicts

```bash
# After resolving conflicts in your editor:
git add <conflicted-files>
git rebase --continue
git push origin submit-fix --force-with-lease
```

## To abort a rebase

```bash
git rebase --abort
```
