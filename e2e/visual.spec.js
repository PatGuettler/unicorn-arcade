import { test, expect } from "@playwright/test";
import { seedTestUser, loginAndReachHome } from "./helpers/seed.js";
import {
  openCategory,
  openDashboard,
} from "./helpers/navigation.js";

test.beforeEach(async ({ page }) => {
  await seedTestUser(page);
  await loginAndReachHome(page);
});

test.describe("visual regression snapshots", () => {
  test("home screen", async ({ page }) => {
    await expect(page.locator(".h-app").first()).toHaveScreenshot("home.png", {
      animations: "disabled",
    });
  });

  test("dashboard screen", async ({ page }) => {
    await openDashboard(page);
    await expect(page.locator(".h-app").first()).toHaveScreenshot(
      "dashboard.png",
      { animations: "disabled" }
    );
  });

  test("number category screen", async ({ page }) => {
    await openDashboard(page);
    await openCategory(page, "number");
    await expect(page.locator(".h-app").first()).toHaveScreenshot(
      "category-number.png",
      { animations: "disabled" }
    );
  });

  test("word category screen", async ({ page }) => {
    await openDashboard(page);
    await openCategory(page, "word");
    await expect(page.locator(".h-app").first()).toHaveScreenshot(
      "category-word.png",
      { animations: "disabled" }
    );
  });
});
