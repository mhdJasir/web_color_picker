# 🖌️ Web Color Picker

A customizable color picker widget for Flutter, supporting:

- HSV color sliders
- RGBA and HEX input fields
- Predefined swatches
- 🎯 Eyedropper tool to pick colors directly from the screen (Web only)

---

## ✨ Features

- Modern, responsive UI
- Full control via `Color` and `ValueChanged<Color>`
- Web-specific eyedropper support using `html2canvas` and JavaScript interop

---

## 🚀 Getting Started

### 1. Install

Add to your `pubspec.yaml`:

```yaml
dependencies:
  web_color_pick: ^1.0.0


## 🛠 Setup

Add the following to your app’s `web/index.html` before `</body>`:

```html
<script src="https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.min.js"></script>
<script>
  window.captureFlutterApp = async function () {
    const canvas = await html2canvas(document.body);
    return canvas.toDataURL("image/png");
  };
</script>

