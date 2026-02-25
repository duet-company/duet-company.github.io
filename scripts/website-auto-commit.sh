#!/bin/bash
# Smart auto-commit for website project
# Analyzes changes and chooses appropriate commit message type

set -e

cd ~/projects/website

# Check if there are changes
if git diff --quiet && git diff --cached --quiet; then
    echo "✓ No changes to commit"
    exit 0
fi

echo "📊 Analyzing changes..."

# Analyze changes to determine commit type
FILES_CHANGED=$(git diff --name-only)
TYPE="chore"
SCOPE=""

# Check for specific patterns
if echo "$FILES_CHANGED" | grep -q "\.css$"; then
    TYPE="style"
    SCOPE="css"
elif echo "$FILES_CHANGED" | grep -q "\.html$\|\.tsx$\|\.jsx$\|\.ts$\|\.js$"; then
    TYPE="feat"
    SCOPE="ui"
elif echo "$FILES_CHANGED" | grep -q "test"; then
    TYPE="test"
    SCOPE="tests"
elif echo "$FILES_CHANGED" | grep -q "\.md$"; then
    TYPE="docs"
    SCOPE="content"
elif echo "$FILES_CHANGED" | grep -q "package\.json\|yarn\.lock\|package-lock\.json"; then
    TYPE="chore"
    SCOPE="deps"
elif echo "$FILES_CHANGED" | grep -q "next\.config\|tailwind\.config\|tsconfig"; then
    TYPE="refactor"
    SCOPE="config"
else
    TYPE="chore"
fi

# Count files
FILE_COUNT=$(echo "$FILES_CHANGED" | wc -l)

# Generate commit message
TIMESTAMP=$(date +'%Y-%m-%d %H:%M')
if [ -n "$SCOPE" ]; then
    COMMIT_MSG="$TYPE($SCOPE): update $FILE_COUNT files"
else
    COMMIT_MSG="$TYPE: $FILE_COUNT files"
fi

# Show status
echo ""
echo "📊 Changes detected:"
git status --short
echo ""
echo "🔍 Analysis:"
echo "  Type: $TYPE"
echo "  Scope: ${SCOPE:-none}"
echo "  Files: $FILE_COUNT"
echo ""
echo "📝 Commit message: $COMMIT_MSG"
echo "  Timestamp: $TIMESTAMP"

# Add all changes
echo ""
echo "📝 Staging changes..."
git add -A

# Commit
echo "💾 Committing..."
git commit -m "$COMMIT_MSG"

# Push
echo ""
echo "🚀 Pushing..."
git push

echo ""
echo "✅ Done! Committed: $COMMIT_MSG"
