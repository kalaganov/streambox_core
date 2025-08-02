#!/bin/bash
set -e

echo "Running tests with coverage..."
dart test --coverage=coverage

echo "Formatting coverage to lcov..."
dart pub global activate coverage --source=hosted > /dev/null

dart pub global run coverage:format_coverage \
  --lcov \
  --in=coverage \
  --out=coverage/lcov.info \
  --report-on=lib/src \
  --packages=.dart_tool/package_config.json

echo "Coverage summary:"
grep "^DA:" coverage/lcov.info | \
awk -F, '{ total++; if ($2 > 0) covered++; } \
END { if (total == 0) print "No data"; else \
printf("  Lines covered: %d/%d (%.2f%%)\n", covered, total, (covered/total)*100) }'

echo "Uncovered lines with code:"
current_file=""
while IFS= read -r line; do
  if [[ $line == SF:* ]]; then
    current_file="${line#SF:}"
  elif [[ $line == DA:* ]]; then
    lineno=$(echo "$line" | cut -d: -f2 | cut -d, -f1)
    hits=$(echo "$line" | cut -d, -f2)
    if [[ "$hits" == "0" ]]; then
      code=$(sed -n "${lineno}p" "$current_file" | sed 's/^[[:space:]]*//')
      echo "$current_file:$lineno: $code"
    fi
  fi
done < coverage/lcov.info