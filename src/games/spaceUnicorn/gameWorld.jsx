import { useEffect, useRef } from "react";

const STAR_COUNT = 48;

function drawStarfield(ctx, w, h, scroll) {
  for (let i = 0; i < STAR_COUNT; i++) {
    const sx = ((i * 97) % 1000) / 1000;
    const sy = (((i * 53 + scroll * (0.3 + (i % 5) * 0.1)) % 1000) + 1000) % 1000) / 1000;
    const size = 1 + (i % 3);
    const alpha = 0.3 + (i % 4) * 0.15;
    ctx.fillStyle = `rgba(255,255,255,${alpha})`;
    ctx.beginPath();
    ctx.arc(sx * w, sy * h, size, 0, Math.PI * 2);
    ctx.fill();
  }
}

function drawRainbowTrail(ctx, x, y, w) {
  const g = ctx.createLinearGradient(x - w * 0.04, y, x + w * 0.04, y);
  g.addColorStop(0, "rgba(236,72,153,0.5)");
  g.addColorStop(0.5, "rgba(168,85,247,0.6)");
  g.addColorStop(1, "rgba(34,211,238,0.5)");
  ctx.fillStyle = g;
  ctx.fillRect(x - w * 0.04, y, w * 0.08, h * 0.12);
}

/**
 * Canvas renderer — game state lives in parent ref (no per-frame React state).
 */
export default function GameWorld({ gameRef, unicornImage, tick }) {
  const canvasRef = useRef(null);
  const imgRef = useRef(null);

  useEffect(() => {
    if (!unicornImage) return;
    const img = new Image();
    img.src = unicornImage;
    img.onload = () => {
      imgRef.current = img;
    };
    imgRef.current = img;
  }, [unicornImage]);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    const g = gameRef.current;
    if (!g || !ctx) return;

    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    const rect = canvas.getBoundingClientRect();
    const w = rect.width;
    const h = rect.height;
    if (w < 1 || h < 1) return;

    canvas.width = w * dpr;
    canvas.height = h * dpr;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    g.width = w;
    g.height = h;

    // Background
    const bg = ctx.createLinearGradient(0, 0, 0, h);
    bg.addColorStop(0, "#1e1b4b");
    bg.addColorStop(0.45, "#4c1d95");
    bg.addColorStop(1, "#0f172a");
    ctx.fillStyle = bg;
    ctx.fillRect(0, 0, w, h);

    drawStarfield(ctx, w, h, g.starScroll || 0);

    // Nebula glow
    ctx.fillStyle = "rgba(168,85,247,0.08)";
    ctx.beginPath();
    ctx.ellipse(w * 0.3, h * 0.25, w * 0.35, h * 0.2, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "rgba(236,72,153,0.06)";
    ctx.beginPath();
    ctx.ellipse(w * 0.7, h * 0.4, w * 0.3, h * 0.15, 0, 0, Math.PI * 2);
    ctx.fill();

    // Explosions
    (g.explosions || []).forEach((ex) => {
      const t = ex.life / ex.maxLife;
      const r = ex.r * (1 + (1 - t) * 0.8);
      ctx.globalAlpha = 1 - t;
      ctx.font = `${r}px serif`;
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillText(ex.emoji || "💥", ex.x, ex.y);
      ctx.globalAlpha = 1;
    });

    // Pickups
    (g.pickups || []).forEach((p) => {
      ctx.font = `${p.r * 2}px serif`;
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillText(p.emoji, p.x, p.y);
    });

    // Enemies
    (g.enemies || []).forEach((e) => {
      if (e.hp <= 0) return;
      const shake = e.hitFlash > 0 ? (Math.random() - 0.5) * 4 : 0;
      ctx.font = `${e.r * 2}px serif`;
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillText(e.emoji, e.x + shake, e.y);

      if (e.maxHp > 1) {
        const barW = e.r * 1.6;
        ctx.fillStyle = "rgba(0,0,0,0.5)";
        ctx.fillRect(e.x - barW / 2, e.y - e.r - 8, barW, 4);
        ctx.fillStyle = "#f472b6";
        ctx.fillRect(
          e.x - barW / 2,
          e.y - e.r - 8,
          barW * (e.hp / e.maxHp),
          4
        );
      }
    });

    // Bullets (rainbow bolts)
    (g.bullets || []).forEach((b) => {
      const grad = ctx.createLinearGradient(b.x, b.y + 12, b.x, b.y - 12);
      grad.addColorStop(0, "#22d3ee");
      grad.addColorStop(0.5, "#e879f9");
      grad.addColorStop(1, "#fde047");
      ctx.strokeStyle = grad;
      ctx.lineWidth = 3;
      ctx.lineCap = "round";
      ctx.beginPath();
      ctx.moveTo(b.x, b.y + 10);
      ctx.lineTo(b.x, b.y - 10);
      ctx.stroke();
      ctx.fillStyle = "#fff";
      ctx.beginPath();
      ctx.arc(b.x, b.y - 10, 3, 0, Math.PI * 2);
      ctx.fill();
    });

    // Player unicorn ship
    const px = g.playerX * w;
    const py = g.playerY * h;
    const shipW = Math.min(w * 0.14, 72);

    drawRainbowTrail(ctx, px, py + shipW * 0.35, w);

    if (imgRef.current?.complete) {
      ctx.save();
      ctx.shadowColor = "rgba(236,72,153,0.8)";
      ctx.shadowBlur = 16;
      ctx.drawImage(
        imgRef.current,
        px - shipW / 2,
        py - shipW / 2,
        shipW,
        shipW
      );
      ctx.restore();
    } else {
      ctx.font = `${shipW}px serif`;
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillText("🦄", px, py);
    }

    // Shield flash
    if (g.shieldFlash > 0) {
      ctx.strokeStyle = `rgba(34,211,238,${g.shieldFlash})`;
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.arc(px, py, shipW * 0.65, 0, Math.PI * 2);
      ctx.stroke();
    }
  }, [tick, gameRef, unicornImage]);

  return (
    <canvas
      ref={canvasRef}
      className="absolute inset-0 w-full h-full touch-none"
      style={{ touchAction: "none" }}
    />
  );
}
