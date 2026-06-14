// Source: W3C WCAG 2.0 Techniques G17 + WCAG 2.1 Understanding SC 1.4.3
// artifacts/contrast.js — zero external dependencies
// Run: node artifacts/contrast.js > artifacts/contrast-table.txt

function linearize(v) {
  const s = v / 255;
  return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
}
function luminance(r, g, b) {
  return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b);
}
function contrastRatio(l1, l2) {
  const [hi, lo] = l1 > l2 ? [l1, l2] : [l2, l1];
  return (hi + 0.05) / (lo + 0.05);
}
function parseHex(h) {
  const c = h.replace('#', '');
  return [parseInt(c.slice(0,2),16), parseInt(c.slice(2,4),16), parseInt(c.slice(4,6),16)];
}

const PALETTE = {
  Ink:    '#111418',
  Slate:  '#24303B',
  Fog:    '#E9EEF2',
  Paper:  '#FAFBFC',
  Moss:   '#5E9E84',
  Cobalt: '#5D79F6',
  Amber:  '#C8923B',
};

const lums = Object.fromEntries(
  Object.entries(PALETTE).map(([name, hex]) => [name, luminance(...parseHex(hex))])
);

const names = Object.keys(PALETTE);
const header = 'Accrue palette WCAG 2.x contrast ratios (threshold: 0.03928)';
const divider = '='.repeat(60);
console.log(header);
console.log(divider);
for (let i = 0; i < names.length; i++) {
  for (let j = i + 1; j < names.length; j++) {
    const [a, b] = [names[i], names[j]];
    const r = contrastRatio(lums[a], lums[b]);
    const level = r >= 7.0 ? 'AAA' : r >= 4.5 ? 'AA-body' : r >= 3.0 ? 'AA-large' : 'FAIL';
    console.log(`${a} vs ${b}: ${r.toFixed(2)}:1  [${level}]`);
  }
}
