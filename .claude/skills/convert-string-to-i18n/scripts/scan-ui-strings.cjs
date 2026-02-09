#!/usr/bin/env node

/**
 * Heuristic scanner for hardcoded user-facing text in client-side files.
 * This is an estimate, not a strict parser.
 */

const fs = require("fs");
const path = require("path");

const ROOT_DIR = process.argv[2] ? path.resolve(process.argv[2]) : process.cwd();

const TARGET_EXTENSIONS = new Set([
  ".js",
  ".jsx",
  ".ts",
  ".tsx",
  ".html",
  ".vue",
  ".svelte",
]);

const IGNORE_DIRS = new Set([
  ".git",
  "node_modules",
  "dist",
  "build",
  ".next",
  ".nuxt",
  "coverage",
  "out",
  ".cache",
]);

const ATTRS = ["title", "alt", "placeholder", "aria-label", "aria-placeholder", "label"];
const ATTRIBUTE_PATTERN = new RegExp(
  `\\b(?:${ATTRS.join("|")})\\s*=\\s*["']([^"'\\n]+)["']`,
  "g"
);

const LITERAL_PATTERN = /(?<![\w$.])(["'`])((?:\\.|(?!\1)[^\\\n]){2,})\1/g;
const JSX_TEXT_PATTERN = />\s*([^<>{}\n][^<>{}]*)\s*</g;
const COMMENT_PATTERN = /\/\*[\s\S]*?\*\/|\/\/.*$/gm;

function walk(dir, out) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (!IGNORE_DIRS.has(entry.name)) {
        walk(full, out);
      }
      continue;
    }
    if (
      TARGET_EXTENSIONS.has(path.extname(entry.name)) &&
      !/\.(spec|test)\./i.test(entry.name)
    ) {
      out.push(full);
    }
  }
}

function isProbablyCodeLikeString(value) {
  const s = value.trim();
  if (!s) return true;
  if (/^(https?:\/\/|\/|#|\.)/.test(s)) return true;
  if (/^[\w-]+(\.[\w-]+)+$/.test(s)) return true;
  if (/^[A-Z0-9_]+$/.test(s)) return true;
  if (/^[\d\s.,:%+-]+$/.test(s)) return true;
  if (/[{}()[\]=]/.test(s)) return true;
  return false;
}

function collectMatches(pattern, text, groupIndex = 1) {
  const values = [];
  pattern.lastIndex = 0;
  let match;
  while ((match = pattern.exec(text)) !== null) {
    values.push(match[groupIndex] || "");
  }
  return values;
}

function estimateForFile(filePath) {
  const raw = fs.readFileSync(filePath, "utf8");
  const text = raw.replace(COMMENT_PATTERN, "");

  const attrStrings = collectMatches(ATTRIBUTE_PATTERN, text, 1);
  const literalStrings = collectMatches(LITERAL_PATTERN, text, 2);
  const jsxText = collectMatches(JSX_TEXT_PATTERN, text, 1);

  const normalizedCandidates = [...attrStrings, ...literalStrings, ...jsxText]
    .map((s) => s.replace(/\s+/g, " ").trim())
    .filter((s) => s.length >= 2);

  const estimatedUnique = [...new Set(normalizedCandidates)];
  const userFacingUnique = estimatedUnique.filter((s) => !isProbablyCodeLikeString(s));
  const words = userFacingUnique.reduce((acc, s) => acc + s.split(/\s+/).length, 0);
  const chars = userFacingUnique.reduce((acc, s) => acc + s.length, 0);

  return {
    estimatedCount: estimatedUnique.length,
    userFacingCount: userFacingUnique.length,
    words,
    chars,
  };
}

function main() {
  const files = [];
  walk(ROOT_DIR, files);

  if (files.length === 0) {
    console.log("No client-side files found.");
    process.exit(0);
  }

  const rows = [];
  let totalEstimatedCount = 0;
  let totalUserFacingCount = 0;
  let totalWords = 0;
  let totalChars = 0;

  for (const file of files) {
    try {
      const result = estimateForFile(file);
      if (result.estimatedCount > 0) {
        const status =
          result.userFacingCount > 0
            ? "completed"
            : "skipped (technical/code-like only)";

        rows.push({
          file: path.relative(ROOT_DIR, file),
          estimatedCount: result.estimatedCount,
          status,
        });

        totalEstimatedCount += result.estimatedCount;
        totalUserFacingCount += result.userFacingCount;
        totalWords += result.words;
        totalChars += result.chars;
      }
    } catch (err) {
      // Skip unreadable files, keep scanner resilient.
    }
  }

  rows.sort((a, b) => {
    if (b.estimatedCount !== a.estimatedCount) {
      return b.estimatedCount - a.estimatedCount;
    }
    return a.file.localeCompare(b.file);
  });

  if (rows.length === 0) {
    console.log("No likely hardcoded user-facing text found.");
    process.exit(0);
  }

  console.log("| # | File | Est. Strings | Status |");
  console.log("|---|------|--------------|--------|");
  rows.forEach((row, idx) => {
    console.log(
      `| ${idx + 1} | ${row.file} | ~${row.estimatedCount} | ${row.status} |`
    );
  });
  console.log("");
  console.log(
    `Totals: estimated strings=${totalEstimatedCount}, likely user-facing strings=${totalUserFacingCount}, words=${totalWords}, chars=${totalChars}`
  );
}

main();
