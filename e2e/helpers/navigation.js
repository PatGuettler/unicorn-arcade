import { CATEGORIES, GAMES } from "../fixtures/gameCatalog.js";
import { waitForGameShell } from "./layout.js";

export async function openDashboard(page) {
  await page.getByTestId("home-play-button").click();
  await page.getByTestId("dashboard-scroll").waitFor({ state: "visible" });
}

export async function openCategory(page, categoryId) {
  await page.getByTestId(`category-card-${categoryId}`).click();
  await page.getByTestId("category-scroll").waitFor({ state: "visible" });
}

export async function openGame(page, gameId) {
  await page.getByTestId(`game-card-${gameId}`).click();
  await waitForGameShell(page);
}

export async function backFromGame(page) {
  await page.getByTestId("header-back").click();
  await page.getByTestId("category-scroll").waitFor({ state: "visible" });
}

export async function backToDashboard(page) {
  await page.getByTestId("header-back").click();
  await page.getByTestId("dashboard-scroll").waitFor({ state: "visible" });
}

export async function backToHome(page) {
  await page.getByTestId("header-home").click();
  await page.getByTestId("home-play-button").waitFor({ state: "visible" });
}

export function getAllCategories() {
  return CATEGORIES.map((c) => c.id);
}

export function getGamesForCategory(categoryId) {
  return (GAMES[categoryId] || []).map((g) => g.id);
}

export function getAllGameEntries() {
  return CATEGORIES.flatMap((category) =>
    (GAMES[category.id] || []).map((game) => ({
      categoryId: category.id,
      gameId: game.id,
      title: game.title,
    }))
  );
}
