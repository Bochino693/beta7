// SVG do desenho -> PNG e PDF (Chromium do Playwright):
//   node tools/desenho_para_png_pdf.js arduino/ligacao_gol_flash_arena.svg
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
(async () => {
  const svg = path.resolve(process.argv[2]);
  const txt = fs.readFileSync(svg, 'utf8');
  const m = txt.match(/viewBox="0 0 (\d+) (\d+)"/);
  const W = +m[1], H = +m[2];
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
  await p.setContent('<html><body style="margin:0;background:white">' + txt + '</body></html>');
  await p.screenshot({ path: svg.replace(/\.svg$/, '.png'), clip: { x: 0, y: 0, width: W, height: H } });
  await p.pdf({ path: svg.replace(/\.svg$/, '.pdf'), width: W + 'px', height: H + 'px', printBackground: true, pageRanges: '1' });
  await b.close();
  console.log('ok: png e pdf');
})();
