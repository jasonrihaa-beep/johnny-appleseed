#!/usr/bin/env node
'use strict';

// Johnny Appleseed — BUILD_RULES rule 6 (+ rule 7) validator.
// Node stdlib only. Run from repo root: node scripts/validate.js
// Exit 0 = all checks pass, exit 1 = any check failed.

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execFileSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..');
const INDEX_PATH = path.join(ROOT, 'index.html');
const SW_PATH = path.join(ROOT, 'sw.js');

let allPass = true;

function report(name, pass, detail) {
  const status = pass ? 'PASS' : 'FAIL';
  console.log(`[${status}] ${name}${detail ? ' — ' + detail : ''}`);
  if (!pass) allPass = false;
}

// ---- Check 1: CSS brace balance ----
function checkCssBraceBalance(html) {
  const styleRe = /<style\b[^>]*>([\s\S]*?)<\/style>/gi;
  let match;
  let idx = 0;
  let any = false;
  while ((match = styleRe.exec(html)) !== null) {
    any = true;
    idx++;
    const css = match[1];
    const open = (css.match(/\{/g) || []).length;
    const close = (css.match(/\}/g) || []).length;
    report(`CSS brace balance (style block ${idx})`, open === close, `{ = ${open}, } = ${close}`);
  }
  if (!any) {
    report('CSS brace balance', true, 'no <style> blocks found');
  }
}

// ---- Check 2: HTML tag balance ----
const VOID_ELEMENTS = new Set([
  // standard HTML void elements
  'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta',
  'param', 'source', 'track', 'wbr',
  // spec-specified additions / common inline-SVG self-closers
  'use', 'path', 'circle', 'rect', 'line',
]);

function checkHtmlTagBalance(html) {
  const stripped = html
    .replace(/<!--[\s\S]*?-->/g, '')
    .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, '');

  const tagRe = /<(\/?)([a-zA-Z][a-zA-Z0-9:-]*)\b[^>]*?(\/?)>/g;
  let match;
  const stack = [];
  const errors = [];

  while ((match = tagRe.exec(stripped)) !== null) {
    const isClosing = match[1] === '/';
    const name = match[2].toLowerCase();
    const selfClosing = match[3] === '/';

    if (isClosing) {
      if (VOID_ELEMENTS.has(name)) continue;
      const top = stack.pop();
      if (top !== name) {
        errors.push(`mismatched close </${name}> (expected ${top ? '</' + top + '>' : 'nothing on stack'})`);
      }
    } else {
      if (selfClosing || VOID_ELEMENTS.has(name)) continue;
      stack.push(name);
    }
  }

  if (stack.length) {
    errors.push(`unclosed tags remaining on stack: ${stack.join(', ')}`);
  }

  report('HTML tag balance', errors.length === 0, errors.length === 0 ? 'stack empty' : errors.join('; '));
}

// ---- Check 3: inline JS syntax ----
function checkInlineJsSyntax(html) {
  const scriptRe = /<script\b([^>]*)>([\s\S]*?)<\/script>/gi;
  let match;
  let idx = 0;
  let any = false;

  while ((match = scriptRe.exec(html)) !== null) {
    const attrs = match[1];
    if (/\bsrc\s*=/i.test(attrs)) continue; // external script — nothing to check
    const code = match[2];
    if (!code.trim()) continue;

    any = true;
    idx++;
    const tmpFile = path.join(os.tmpdir(), `ja-validate-inline-${process.pid}-${idx}.js`);
    let pass = true;
    let detail = '';
    try {
      fs.writeFileSync(tmpFile, code, 'utf8');
      execFileSync(process.execPath, ['--check', tmpFile], { stdio: 'pipe' });
    } catch (e) {
      pass = false;
      const stderr = (e.stderr ? e.stderr.toString() : e.message) || '';
      detail = stderr.trim().split('\n').slice(0, 3).join(' | ');
    } finally {
      try { fs.unlinkSync(tmpFile); } catch (_) { /* never let cleanup throw */ }
    }
    report(`Inline JS syntax (script block ${idx})`, pass, detail);
  }

  if (!any) {
    report('Inline JS syntax', true, 'no inline (non-src) <script> blocks found');
  }
}

// ---- Check 4: version fan-out consistency (rule 7) ----
function checkVersionFanout(html) {
  const footerMatch = html.match(/Johnny Appleseed v(\d+)\.(\d+)\.(\d+)/);
  if (!footerMatch) {
    report('Version fan-out consistency', false, 'could not find "Johnny Appleseed vX.Y.Z" footer in index.html');
    return;
  }
  const [, maj, min, patch] = footerMatch;
  const footerVersion = `v${maj}.${min}.${patch}`;
  const expectedCache = `appleseed-v${maj}-${min}-${patch}`;

  let swLine1;
  try {
    swLine1 = fs.readFileSync(SW_PATH, 'utf8').split('\n')[0];
  } catch (e) {
    report('Version fan-out consistency', false, `could not read sw.js: ${e.message}`);
    return;
  }

  const cacheMatch = swLine1.match(/appleseed-v\d+-\d+-\d+/);
  if (!cacheMatch) {
    report('Version fan-out consistency', false, `sw.js line 1 has no appleseed-vX-Y-Z CACHE name: ${swLine1.trim()}`);
    return;
  }

  const actualCache = cacheMatch[0];
  report(
    'Version fan-out consistency',
    actualCache === expectedCache,
    `index.html footer ${footerVersion} vs sw.js CACHE ${actualCache}`
  );
}

function main() {
  const html = fs.readFileSync(INDEX_PATH, 'utf8');

  console.log('Johnny Appleseed — validate.js\n');

  checkCssBraceBalance(html);
  checkHtmlTagBalance(html);
  checkInlineJsSyntax(html);
  checkVersionFanout(html);

  console.log('');
  console.log(allPass ? 'RESULT: PASS (all checks passed)' : 'RESULT: FAIL (see failing checks above)');
  process.exit(allPass ? 0 : 1);
}

main();
