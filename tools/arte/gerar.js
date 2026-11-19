// A ARTE DO OLHO NO LANCE (capa, abertura, icone, banner da TV e os quadros
// do video), desenhada por tools/arte/arte.html no Chromium:
//   node tools/arte/gerar.js <pasta de saida>
// Depois: python3 -I tools/arte/montar.py <pasta de saida>   (poe no projeto)
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
(async () => {
  const saida = path.resolve(process.argv[2]);
  fs.mkdirSync(path.join(saida, 'quadros'), { recursive: true });
  const url = 'file://' + path.resolve(__dirname, 'arte.html');
  const b = await chromium.launch();
  async function pagina(modo, w, h) {
    const p = await b.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 1 });
    await p.goto(url + '?modo=' + modo);
    await p.waitForFunction('window.pronto === true');
    await p.waitForTimeout(300);
    return p;
  }
  let p = await pagina('capa', 1920, 1080);
  await p.evaluate('quadro(100)');
  await p.screenshot({ path: path.join(saida, 'capa.png') });
  await p.close();
  p = await pagina('icone', 1024, 1024);
  await p.evaluate('quadro(100)');
  await p.screenshot({ path: path.join(saida, 'icone.png') });
  await p.close();
  p = await pagina('banner', 1280, 720);
  await p.evaluate('quadro(100)');
  await p.screenshot({ path: path.join(saida, 'banner.png') });
  await p.close();
  // video: 10 s a 24 quadros por segundo, 1280 x 720 (16:9, como a TV)
  p = await pagina('video', 1280, 720);
  for (let i = 0; i < 240; i++) {
    await p.evaluate('quadro(' + (i / 24) + ')');
    await p.screenshot({ path: path.join(saida, 'quadros', String(i).padStart(4, '0') + '.png') });
  }
  await p.close();
  await b.close();
  console.log('ok: capa, icone, banner e 240 quadros em ' + saida);
})();
