window.captureFlutterApp = async function () {
  const app = document.body;
  const canvas = await html2canvas(app, {
    useCORS: false,
    backgroundColor: null,
    logging: true,
  });
  const dataUrl = canvas.toDataURL("image/png");
  return dataUrl;
};
