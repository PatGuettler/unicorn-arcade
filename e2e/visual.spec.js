import { test } from "@playwright/test";
import { seedTestUser, loginAndReachHome } from "./helpers/seed.js";
import {
  openCategory,
  openDashboard,
} from "./helpers/navigation.js";
import { expectAppScreenshot, prepareVisualTest } from "./helpers/visual.js";

test.beforeEach(async ({ page }) => {
  await prepareVisualTest(page);
  await seedTestUser(page);
  await loginAndReachHome(page);
});

test.describe("visual regression snapshots", () => {
  test("home screen", async ({ page }) => {
    await expectAppScreenshot(page, "home.png");
  });

  test("dashboard screen", async ({ page }) => {
    await openDashboard(page);
    await expectAppScreenshot(page, "dashboard.png");
  });

  test("number category screen", async ({ page }) => {
    await openDashboard(page);
    await openCategory(page, "number");
    await expectAppScreenshot(page, "category-number.png");
  });

  test("word category screen", async ({ page }) => {
    await openDashboard(page);
    await openCategory(page, "word");
    await expectAppScreenshot(page, "category-word.png");
  });
});
