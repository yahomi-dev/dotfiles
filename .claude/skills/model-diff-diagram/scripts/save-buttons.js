(() => {
  const status = document.getElementById("status");
  const scaleOf = () => Number(document.getElementById("scale").value);
  const sizeOf = (svg) => {
    const vb = svg.viewBox.baseVal;
    const w = Number(svg.getAttribute("width")) || vb.width;
    const h = Number(svg.getAttribute("height")) || vb.height;
    return { w, h };
  };
  const serialize = (svg) => {
    const clone = svg.cloneNode(true);
    clone.setAttribute("xmlns", "http://www.w3.org/2000/svg");
    const { w, h } = sizeOf(svg);
    clone.setAttribute("width", String(w));
    clone.setAttribute("height", String(h));
    // 外のフォント (@import) は画像として描くときに読めないので外す。文字はこの PC のフォントで描かれる
    for (const style of clone.querySelectorAll("style")) {
      style.textContent = style.textContent.replace(/@import[^;]+;/g, "");
    }
    return new XMLSerializer().serializeToString(clone);
  };
  const download = (blob, name) => {
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = name;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(a.href), 2000);
  };
  const toPng = async (svg, scale) => {
    const { w, h } = sizeOf(svg);
    const url = URL.createObjectURL(new Blob([serialize(svg)], { type: "image/svg+xml;charset=utf-8" }));
    const img = new Image();
    await new Promise((resolve, reject) => { img.onload = resolve; img.onerror = reject; img.src = url; });
    const canvas = document.createElement("canvas");
    canvas.width = Math.round(w * scale);
    canvas.height = Math.round(h * scale);
    const ctx = canvas.getContext("2d");
    ctx.fillStyle = "#ffffff";
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
    URL.revokeObjectURL(url);
    return new Promise((resolve) => canvas.toBlob(resolve, "image/png"));
  };
  const savePng = async (section) => {
    const svg = section.querySelector("svg");
    const name = section.dataset.file;
    status.textContent = `${name}.png を作っています`;
    const blob = await toPng(svg, scaleOf());
    download(blob, `${name}.png`);
    status.textContent = `${name}.png を保存しました`;
  };
  const saveSvg = (section) => {
    const svg = section.querySelector("svg");
    const name = section.dataset.file;
    download(new Blob([serialize(svg)], { type: "image/svg+xml;charset=utf-8" }), `${name}.svg`);
    status.textContent = `${name}.svg を保存しました`;
  };
  for (const button of document.querySelectorAll(".save-png")) {
    button.addEventListener("click", () => { savePng(button.closest("section")).catch((e) => { status.textContent = `保存に失敗: ${e}`; }); });
  }
  for (const button of document.querySelectorAll(".save-svg")) {
    button.addEventListener("click", () => saveSvg(button.closest("section")));
  }
  document.getElementById("save-all").addEventListener("click", async () => {
    // ブラウザが「複数のファイルのダウンロード」を聞いてくるので、許可する
    const sections = document.querySelectorAll("section[data-file]");
    for (const section of sections) {
      await savePng(section);
      await new Promise((resolve) => setTimeout(resolve, 400));
    }
    status.textContent = `${sections.length} 枚を保存しました`;
  });
})();
