import { test, expect } from "@playwright/test";
import { seedTestUser, loginAndReachHome } from "./helpers/seed.js";
import {
  expectAllReachable,
  expectNoOverflow,
  expectPrimaryControlsVisible,
  waitForGameShell,
} from "./helpers/layout.js";
import {
  backFromGame,
  backToDashboard,
  backToHome,
  getAllCategories,
  getAllGameEntries,
  getGamesForCategory,
  openCategory,
  openDashboard,
  openGame,
} from "./helpers/navigation.js";

test.beforeEach(async ({ page }) => {
  await seedTestUser(page);
  await loginAndReachHome(page);
});

test.describe("shared screens", () => {
  test("home screen is fully visible", async ({ page }) => {
    await expectNoOverflow(page);
    await expect(page.getByTestId("home-play-button")).toBeVisible();
    await expect(page.getByTestId("home-shop-button")).toBeVisible();
    await expect(page.getByTestId("home-profile-button")).toBeVisible();
    await expect(page.getByTestId("home-alley-button")).toBeVisible();
  });

  test("dashboard categories are reachable", async ({ page }) => {
    await openDashboard(page);
    await expectNoOverflow(page);
    await expectAllReachable(page, "[data-testid^='category-card-']", {
      scrollSelector: "[data-testid='dashboard-scroll']",
    });
  });

  test("shop, profile, and alley screens are reachable from home", async ({
    page,
  }) => {
    await page.getByTestId("home-shop-button").click();
    await page.getByTestId("shop-scroll").waitFor({ state: "visible" });
    await expectNoOverflow(page);
    await page.getByTestId("header-back").click();

    await page.getByTestId("home-profile-button").click();
    await page.getByTestId("profile-scroll").waitFor({ state: "visible" });
    await expectNoOverflow(page);
    await page.getByTestId("header-back").click();

    await page.getByTestId("home-alley-button").click();
    await expect(page.getByText("Unicorn Alley")).toBeVisible();
    await expectNoOverflow(page);
    await page.getByTestId("header-back").click();
    await expect(page.getByTestId("home-play-button")).toBeVisible();
  });
});

test.describe("category lists", () => {
  for (const categoryId of getAllCategories()) {
    test(`${categoryId} category shows all games`, async ({ page }) => {
      await openDashboard(page);
      await openCategory(page, categoryId);

      const games = getGamesForCategory(categoryId);
      test.skip(games.length === 0, "No games in category");

      await expectNoOverflow(page);
      await expectAllReachable(page, `[data-testid^='game-card-']`, {
        scrollSelector: "[data-testid='category-scroll']",
      });

      for (const gameId of games) {
        await expect(page.getByTestId(`game-card-${gameId}`)).toBeVisible();
      }
    });
  }
});

test.describe("games smoke layout", () => {
  for (const { categoryId, gameId, title } of getAllGameEntries()) {
    test(`${title} (${gameId}) loads with visible controls`, async ({
      page,
    }) => {
      await openDashboard(page);
      await openCategory(page, categoryId);
      await openGame(page, gameId);

      await expectNoOverflow(page);
      await expectPrimaryControlsVisible(page);

      await backFromGame(page);
      await backToDashboard(page);
      await backToHome(page);
    });
  }
});

test.describe("number games regression", () => {
  test("all number games are reachable on compact screens", async ({ page }) => {
    await openDashboard(page);
    await openCategory(page, "number");

    const numberGames = getGamesForCategory("number");
    expect(numberGames.length).toBeGreaterThan(0);

    await expectAllReachable(page, "[data-testid^='game-card-']", {
      scrollSelector: "[data-testid='category-scroll']",
    });

    for (const gameId of numberGames.slice(-2)) {
      await expect(page.getByTestId(`game-card-${gameId}`)).toBeVisible();
    }
  });
});
