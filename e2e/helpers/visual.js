import { expect } from "@playwright/test";

/** Shared Playwright screenshot options for cross-platform CI stability */
export const screenShotOptions = {
  animations: "disabled",
  caret: "hide",
  scale: "css",
  // Slightly looser than 0.05: emoji + pixel-art header icons still differ a few
  // percent between local Linux and ubuntu-latest Chromium font stacks.
  maxDiffPixelRatio: 0.1,
  threshold: 0.25,
};

/** Regions that vary by OS font/emoji/pixel scaling and should not fail CI. */
export const defaultMaskSelectors = [
  '[data-testid="header-home"]',
  '[data-testid^="game-card-"] [data-testid="game-card-icon"]',
  '[data-testid^="game-card-"] .text-4xl',
];

/**
 * Call before navigation (e.g. alongside seedTestUser).
 * Disables motion via a document attribute read by index.css.
 */
export async function prepareVisualTest(page) {
  await page.addInitScript(() => {
    document.documentElement.setAttribute("data-visual-test", "true");
  });
}

/** Settle layout/fonts/scroll before capturing a screenshot. */
export async function stabilizeForScreenshot(page) {
  await page.evaluate(() => {
    document.documentElement.setAttribute("data-visual-test", "true");
    document.querySelectorAll(".app-scroll, [data-scroll-root='true']").forEach(
      (el) => {
        el.scrollTop = 0;
      }
    );
    document.getAnimations?.().forEach((animation) => {
      try {
        animation.finish();
      } catch {
        animation.cancel();
      }
    });
  });

  await page.waitForLoadState("networkidle");
  await page.evaluate(() => document.fonts.ready);
}

export async function expectAppScreenshot(page, name, options = {}) {
  await stabilizeForScreenshot(page);
  const target = page.locator(".h-app").first();
  const maskSelectors = [
    ...defaultMaskSelectors,
    ...(options.maskSelectors ?? []),
  ];
  const masks = maskSelectors
    .map((sel) => page.locator(sel))
    .filter((locator) => locator);
  await expect(target).toHaveScreenshot(name, {
    ...screenShotOptions,
    ...(options.maxDiffPixelRatio != null
      ? { maxDiffPixelRatio: options.maxDiffPixelRatio }
      : {}),
    mask: masks.length ? masks : undefined,
  });
}
