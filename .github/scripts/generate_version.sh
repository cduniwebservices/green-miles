#!/bin/bash
# Generate version number based on year progress
# Formula: (YY - 25) . (seconds_elapsed / 31536000 as 6-digit)

# Get current UTC time components
YEAR=$(date -u +%Y)
YY=$(date -u +%y)
DAY_OF_YEAR=$(date -u +%j)
HOUR=$(date -u +%H)
MIN=$(date -u +%M)
SEC=$(date -u +%S)

# Calculate major version (YY - 25)
MAJOR=$((10#$YY - 25))

# Calculate seconds elapsed since start of year
# Using 10# prefix to prevent octal interpretation of leading zeros
DAY_ZERO_INDEXED=$((10#$DAY_OF_YEAR - 1))
SECONDS_ELAPSED=$((DAY_ZERO_INDEXED * 86400 + 10#$HOUR * 3600 + 10#$MIN * 60 + 10#$SEC))

# Seconds in a standard year (365 days)
SECONDS_IN_YEAR=31536000

# Calculate minor version as 6-digit integer
# Python is available on all GitHub Actions runners
MINOR=$(python3 -c "
seconds_elapsed = ${SECONDS_ELAPSED}
seconds_in_year = ${SECONDS_IN_YEAR}
pct = seconds_elapsed / seconds_in_year
minor = int(pct * 1000000)
print(f'{minor:06d}')
")

# Full version
VERSION="${MAJOR}.${MINOR}"

echo "Generated version: ${VERSION}"
if [ -n "$GITHUB_ENV" ]; then
  echo "VERSION=${VERSION}" >> "${GITHUB_ENV}"
fi
if [ -n "$GITHUB_OUTPUT" ]; then
  echo "version=${VERSION}" >> "${GITHUB_OUTPUT}"
fi
