import { defineConfig } from "@playwright/test";

const baseURL = process.env.PLAYWRIGHT_BASE_URL || "http://127.0.0.1:4173";

const chromiumMobile = {
  browserName: "chromium",
  isMobile: true,
  hasTouch: true,
};

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: process.env.CI ? 2 : undefined,
  timeout: 60_000,
  reporter: [["list"], ["html", { open: "never" }]],
  snapshotPathTemplate:
    "{testDir}/snapshots/{projectName}/{testFilePath}/{arg}{ext}",
  use: {
    baseURL,
    trace: "on-first-retry",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },
  webServer: {
    command: "npm run build && npm run preview -- --host 127.0.0.1 --port 4173",
    url: baseURL,
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
  projects: [
    {
      name: "phone-small",
      use: {
        ...chromiumMobile,
        viewport: { width: 360, height: 640 },
      },
    },
    {
      name: "phone-samsung",
      use: {
        ...chromiumMobile,
        viewport: { width: 384, height: 854 },
      },
    },
    {
      name: "phone-samsung-compact",
      use: {
        ...chromiumMobile,
        viewport: { width: 360, height: 780 },
      },
    },
    {
      name: "phone-pixel9",
      use: {
        ...chromiumMobile,
        viewport: { width: 412, height: 915 },
      },
    },
    {
      name: "phone-large",
      use: {
        ...chromiumMobile,
        viewport: { width: 430, height: 932 },
      },
    },
    {
      name: "tablet-portrait",
      use: {
        ...chromiumMobile,
        viewport: { width: 768, height: 1024 },
      },
    },
    {
      name: "tablet-large",
      use: {
        ...chromiumMobile,
        viewport: { width: 800, height: 1280 },
      },
    },
    {
      name: "phone-landscape",
      use: {
        browserName: "chromium",
        viewport: { width: 915, height: 412 },
      },
    },
    {
      name: "tablet-landscape",
      use: {
        browserName: "chromium",
        viewport: { width: 1024, height: 768 },
      },
    },
  ],
});
