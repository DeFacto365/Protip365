#!/bin/bash

# Add AutoMirrored icon imports to all affected files

echo "📦 Adding AutoMirrored imports..."

for file in $(grep -r "Icons.AutoMirrored.Filled" app/src/main/java --include="*.kt" -l); do
  # Check if file already has automirrored import
  if ! grep -q "import androidx.compose.material.icons.automirrored" "$file"; then
    # Find the last icons import line
    if grep -q "^import androidx.compose.material.icons" "$file"; then
      # Add import after the last icons import
      sed -i '' '/^import androidx.compose.material.icons/a\
import androidx.compose.material.icons.automirrored.filled.*
' "$file"
      echo "✅ Added import to: $file"
    fi
  fi
done

echo "✅ All imports added!"

