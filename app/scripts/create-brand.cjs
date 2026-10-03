// Rasterize the app's vector wordmark with the bundled display font.
const fs = require("node:fs");
const path = require("node:path");
const { createCanvas, Path2D } = require("@napi-rs/canvas");
const bytes = fs.readFileSync(
  path.resolve(
    "node_modules/@expo-google-fonts/fraunces/600SemiBold/Fraunces_600SemiBold.ttf",
  ),
);
const font = require("opentype.js").parse(
  bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength),
);
function make(file, size, foreground = false, monochrome = false) {
  const canvas = createCanvas(size, size),
    c = canvas.getContext("2d");
  if (!foreground) {
    c.fillStyle = "#8A9C7D";
    c.beginPath();
    c.roundRect(0, 0, size, size, size * 0.25);
    c.fill();
  }
  c.fillStyle = monochrome ? "#000000" : "#FFFEFB";
  const glyphs = font.getPath("p.", 0, 0, size * (foreground ? 0.44 : 0.72));
  const box = glyphs.getBoundingBox();
  c.translate(
    (size - (box.x2 - box.x1)) / 2 - box.x1,
    (size - (box.y2 - box.y1)) / 2 - box.y1,
  );
  c.fill(new Path2D(glyphs.toPathData(3)));
  fs.writeFileSync(path.resolve("assets", file), canvas.toBuffer("image/png"));
}
make("icon.png", 1024);
make("android-icon-foreground.png", 1024, true);
make("android-icon-monochrome.png", 1024, true, true);
make("splash-logo.png", 200);
make("favicon.png", 64);
