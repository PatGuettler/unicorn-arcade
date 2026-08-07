import { expect } from "@playwright/test";

/** Shared Playwright screenshot options for cross-platform CI stability */
export const screenShotOptions = {
  animations: "disabled",
  caret: "hide",
  scale: "css",
  maxDiffPixelRatio: 0.05,
  threshold: 0.25,
};

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
  // Prefer CSS stabilization (data-visual-test) over Playwright masks. Masks bake
  // magenta into baselines and amplify tiny layout shifts between local and CI.
  const masks = (options.maskSelectors ?? []).map((sel) => page.locator(sel));
  await expect(target).toHaveScreenshot(name, {
    ...screenShotOptions,
    ...(options.maxDiffPixelRatio != null
      ? { maxDiffPixelRatio: options.maxDiffPixelRatio }
      : {}),
    mask: masks.length ? masks : undefined,
  });
}
