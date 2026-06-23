import { WORD_GAME_IDS } from "../fixtures/gameCatalog.js";

export const TEST_USER = "e2e-player";
export const DB_KEY = "unicorn_arcade_v1";

function emptyGameStats() {
  return { maxLevel: 0, times: [] };
}

export function buildTestDatabase() {
  const user = {
    coins: 50000,
    ownedUnicorns: ["sparkle", "rainbow", "star", "cloud", "dream", "mystic"],
    equippedUnicorn: "sparkle",
    furniture: { inventory: {}, placements: {} },
    unicorn: emptyGameStats(),
    sliding: emptyGameStats(),
    coin: emptyGameStats(),
    cash: emptyGameStats(),
    spaceUnicorn: emptyGameStats(),
    mathSwipe: emptyGameStats(),
    mathtris: emptyGameStats(),
  };

  WORD_GAME_IDS.forEach((id) => {
    user[id] = emptyGameStats();
  });

  return {
    users: { [TEST_USER]: user },
    lastUser: TEST_USER,
  };
}

export async function seedTestUser(page) {
  const db = buildTestDatabase();
  await page.addInitScript(
    ({ key, value }) => {
      window.localStorage.setItem(key, value);
    },
    { key: DB_KEY, value: JSON.stringify(db) }
  );
}

export async function loginAndReachHome(page) {
  await page.goto("/");
  await page.getByTestId("login-submit").click();
  await page.getByTestId("home-play-button").waitFor({ state: "visible" });
}
