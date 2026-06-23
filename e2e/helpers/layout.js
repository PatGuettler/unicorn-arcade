import { expect } from "@playwright/test";

export async function expectNoOverflow(page) {
  const result = await page.evaluate(() => {
    const doc = document.documentElement;
    return {
      bodyOverflowX: doc.scrollWidth - doc.clientWidth,
      viewportWidth: window.innerWidth,
      viewportHeight: window.innerHeight,
    };
  });

  expect(
    result.bodyOverflowX,
    `Unexpected horizontal page overflow (${result.bodyOverflowX}px at width ${result.viewportWidth})`
  ).toBeLessThanOrEqual(1);
}

export async function expectAllReachable(page, itemSelector, options = {}) {
  const {
    scrollSelector = null,
    tolerance = 2,
  } = options;

  const items = page.locator(itemSelector);
  const count = await items.count();
  expect(count, `Expected items for ${itemSelector}`).toBeGreaterThan(0);

  for (let i = 0; i < count; i += 1) {
    const reachable = await page.evaluate(
      ({ index, selector, scrollSel, tol }) => {
        const nodes = [...document.querySelectorAll(selector)];
        const el = nodes[index];
        if (!el) return { ok: false, reason: "missing element" };

        const scrollEl = scrollSel
          ? document.querySelector(scrollSel)
          : el.closest(".app-scroll, [data-scroll-root='true']");

        const isFullyVisible = () => {
          const rect = el.getBoundingClientRect();
          return (
            rect.top >= tol &&
            rect.left >= tol &&
            rect.bottom <= window.innerHeight - tol &&
            rect.right <= window.innerWidth - tol
          );
        };

        if (scrollEl) {
          const maxScroll = scrollEl.scrollHeight - scrollEl.clientHeight;
          for (
            let step = 0;
            step <= maxScroll;
            step += Math.max(24, Math.floor(maxScroll / 10) || 24)
          ) {
            scrollEl.scrollTop = step;
            if (isFullyVisible()) return { ok: true };
          }
          scrollEl.scrollTop = maxScroll;
        }

        el.scrollIntoView({ block: "center", inline: "nearest" });
        const rect = el.getBoundingClientRect();
        return {
          ok: isFullyVisible(),
          rect: {
            top: rect.top,
            left: rect.left,
            bottom: rect.bottom,
            right: rect.right,
          },
          viewport: { width: window.innerWidth, height: window.innerHeight },
        };
      },
      {
        index: i,
        selector: itemSelector,
        scrollSel: scrollSelector,
        tol: tolerance,
      }
    );

    expect(
      reachable.ok,
      `Item ${i} not reachable: ${JSON.stringify(reachable)}`
    ).toBe(true);
  }
}

export async function expectPrimaryControlsVisible(page) {
  const back = page.getByTestId("header-back");
  const shell = page.getByTestId("word-game-shell");
  const gameShell = page.getByTestId("game-shell");

  if (await shell.count()) {
    await expect(shell).toBeVisible();
  } else if (await gameShell.count()) {
    await expect(gameShell).toBeVisible();
  }
  await expect(back).toBeVisible();
}

export async function waitForGameShell(page) {
  await page
    .locator(
      "[data-testid='header-back'], [data-testid='word-game-shell'], [data-testid='game-shell']"
    )
    .first()
    .waitFor({ state: "visible", timeout: 15_000 });
}
