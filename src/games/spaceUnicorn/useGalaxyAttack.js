import { useRef, useCallback } from "react";

const ENEMY_TYPES = [
  { id: "gloom", emoji: "☁️", hp: 1, speed: 0.00035, score: 10, r: 18 },
  { id: "bat", emoji: "🦇", hp: 1, speed: 0.0005, score: 15, r: 16, zigzag: true },
  { id: "rock", emoji: "🪨", hp: 2, speed: 0.00028, score: 25, r: 20 },
  { id: "skull", emoji: "👾", hp: 2, speed: 0.0004, score: 30, r: 18 },
  { id: "boss", emoji: "🌑", hp: 8, speed: 0.00015, score: 100, r: 32, boss: true },
];

let nextId = 0;
const uid = () => nextId++;

export function createGameState() {
  return {
    width: 0,
    height: 0,
    playerX: 0.5,
    playerY: 0.88,
    bullets: [],
    enemies: [],
    explosions: [],
    pickups: [],
    kills: 0,
    targetKills: 12,
    score: 0,
    lives: 3,
    level: 1,
    starScroll: 0,
    shieldFlash: 0,
    fireCooldown: 0,
    spawnTimer: 0,
    bossSpawned: false,
    playing: false,
    invuln: 0,
  };
}

function pickEnemy(level, waveBoss) {
  if (waveBoss) return { ...ENEMY_TYPES[4], id: uid() };
  const pool = ENEMY_TYPES.filter((e) => !e.boss);
  const weights =
    level <= 2
      ? [0.7, 0.2, 0.1, 0]
      : level <= 5
        ? [0.4, 0.25, 0.2, 0.15]
        : [0.25, 0.25, 0.25, 0.25];
  const r = Math.random();
  let acc = 0;
  for (let i = 0; i < pool.length; i++) {
    acc += weights[i] || 0;
    if (r <= acc) return { ...pool[i], id: uid() };
  }
  return { ...pool[0], id: uid() };
}

function spawnEnemy(g, level, forceBoss = false) {
  const isBossWave = forceBoss || (level % 5 === 0 && !g.bossSpawned && g.kills >= g.targetKills * 0.6);
  const type = pickEnemy(level, isBossWave);
  const x = 0.1 + Math.random() * 0.8;
  g.enemies.push({
    ...type,
    x: x * g.width,
    y: -30,
    hp: type.hp + Math.floor(level / 6),
    maxHp: type.hp + Math.floor(level / 6),
    hitFlash: 0,
    phase: Math.random() * Math.PI * 2,
  });
  if (type.boss) g.bossSpawned = true;
}

function dist(ax, ay, bx, by) {
  const dx = ax - bx;
  const dy = ay - by;
  return Math.sqrt(dx * dx + dy * dy);
}

export function useGalaxyAttack() {
  const gameRef = useRef(createGameState());
  const pointerRef = useRef({ active: false, x: 0.5 });

  const launchLevel = useCallback((level) => {
    const g = createGameState();
    g.level = level;
    g.targetKills = 8 + Math.floor(level * 2.5);
    g.playing = true;
    g.spawnTimer = 0;
    gameRef.current = g;
    pointerRef.current = { active: false, x: 0.5 };
    // Opening wave
    for (let i = 0; i < 3 + level; i++) {
      setTimeout(() => {
        if (gameRef.current.playing) spawnEnemy(gameRef.current, level);
      }, i * 400);
    }
  }, []);

  const setPointer = useCallback((clientX, canvasRect) => {
    if (!canvasRect.width) return;
    const x = (clientX - canvasRect.left) / canvasRect.width;
    pointerRef.current.x = Math.max(0.08, Math.min(0.92, x));
    gameRef.current.playerX = pointerRef.current.x;
  }, []);

  const tick = useCallback((dt, onKillsReached, onGameOver) => {
    const g = gameRef.current;
    if (!g.playing || !g.width || !g.height) return;

    const lvl = g.level;
    g.starScroll = (g.starScroll || 0) + dt * 0.04;
    g.fireCooldown = Math.max(0, g.fireCooldown - dt);
    g.spawnTimer += dt;
    g.invuln = Math.max(0, g.invuln - dt);
    if (g.shieldFlash > 0) g.shieldFlash -= dt * 2;

    // Auto-fire rainbow bolts
    const fireRate = Math.max(120, 280 - lvl * 15);
    if (g.fireCooldown <= 0) {
      g.fireCooldown = fireRate;
      g.bullets.push({
        id: uid(),
        x: g.playerX * g.width,
        y: g.playerY * g.height - 28,
        vy: -0.55 - lvl * 0.02,
      });
    }

    // Spawn enemies
    const spawnEvery = Math.max(600, 2200 - lvl * 150);
    if (g.spawnTimer >= spawnEvery && g.enemies.length < 8 + lvl) {
      g.spawnTimer = 0;
      spawnEnemy(g, lvl);
      if (Math.random() < 0.25 + lvl * 0.03) spawnEnemy(g, lvl);
    }

    // Move player toward pointer
    const targetX = pointerRef.current.x;
    g.playerX += (targetX - g.playerX) * Math.min(1, dt * 0.012);

    // Bullets
    g.bullets = g.bullets.filter((b) => {
      b.y += b.vy * g.height * (dt / 16);
      return b.y > -20;
    });

    // Enemies
    g.enemies.forEach((e) => {
      e.y += e.speed * g.height * (dt / 16) * 60;
      if (e.zigzag) {
        e.x += Math.sin(e.phase + Date.now() * 0.003) * 0.8;
      }
      if (e.hitFlash > 0) e.hitFlash -= dt;
    });

    // Bullet-enemy collisions
    g.bullets = g.bullets.filter((b) => {
      let hit = false;
      for (const e of g.enemies) {
        if (e.hp <= 0) continue;
        if (dist(b.x, b.y, e.x, e.y) < e.r + 8) {
          e.hp -= 1;
          e.hitFlash = 120;
          hit = true;
          if (e.hp <= 0) {
            g.kills += 1;
            g.score += e.score;
            g.explosions.push({
              id: uid(),
              x: e.x,
              y: e.y,
              r: e.r,
              emoji: e.boss ? "🌟" : "💥",
              life: 0,
              maxLife: 400,
            });
            if (Math.random() < 0.12) {
              g.pickups.push({
                id: uid(),
                emoji: Math.random() < 0.5 ? "💖" : "⚡",
                x: e.x,
                y: e.y,
                vy: 0.0002,
                r: 14,
                kind: Math.random() < 0.5 ? "heal" : "rapid",
              });
            }
          }
          break;
        }
      }
      return !hit;
    });

    g.enemies = g.enemies.filter((e) => e.hp > 0 && e.y < g.height + 50);

    // Pickups fall
    g.pickups.forEach((p) => {
      p.y += p.vy * g.height * (dt / 16) * 60;
    });
    g.pickups = g.pickups.filter((p) => {
      const px = g.playerX * g.width;
      const py = g.playerY * g.height;
      if (dist(p.x, p.y, px, py) < 36) {
        if (p.kind === "heal") g.lives = Math.min(5, g.lives + 1);
        else g.fireCooldown = -200;
        g.explosions.push({
          id: uid(),
          x: p.x,
          y: p.y,
          r: 12,
          emoji: "✨",
          life: 0,
          maxLife: 300,
        });
        return false;
      }
      return p.y < g.height + 20;
    });

    // Player collision
    if (g.invuln <= 0) {
      const px = g.playerX * g.width;
      const py = g.playerY * g.height;
      for (const e of g.enemies) {
        if (dist(px, py, e.x, e.y) < e.r + 24) {
          g.lives -= 1;
          g.invuln = 1500;
          g.shieldFlash = 1;
          g.explosions.push({
            id: uid(),
            x: px,
            y: py,
            r: 20,
            emoji: "💫",
            life: 0,
            maxLife: 350,
          });
          if (g.lives <= 0) {
            g.playing = false;
            onGameOver?.();
            return;
          }
          break;
        }
      }
    }

    // Enemies past player
    g.enemies.forEach((e) => {
      if (e.y > g.height * 0.92 && g.invuln <= 0) {
        e.hp = 0;
        g.lives -= 1;
        g.invuln = 1200;
        if (g.lives <= 0) {
          g.playing = false;
          onGameOver?.();
        }
      }
    });
    g.enemies = g.enemies.filter((e) => e.hp > 0);

    // Explosion animation
    g.explosions.forEach((ex) => {
      ex.life += dt;
    });
    g.explosions = g.explosions.filter((ex) => ex.life < ex.maxLife);

    if (g.kills >= g.targetKills) {
      g.playing = false;
      onKillsReached?.();
    }
  }, []);

  const stop = useCallback(() => {
    gameRef.current.playing = false;
  }, []);

  return {
    gameRef,
    launchLevel,
    setPointer,
    tick,
    stop,
    getHud: () => {
      const g = gameRef.current;
      return {
        kills: g.kills,
        target: g.targetKills,
        score: g.score,
        lives: g.lives,
      };
    },
  };
}
