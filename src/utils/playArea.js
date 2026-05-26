import { useState, useEffect, useMemo } from "react";
import { Capacitor } from "@capacitor/core";

/** Visible viewport (accounts for mobile browser chrome when visualViewport exists) */
export function getPlayAreaSize() {
  const vv = window.visualViewport;
  return {
    width: vv?.width ?? window.innerWidth,
    height: vv?.height ?? window.innerHeight,
    offsetTop: vv?.offsetTop ?? 0,
  };
}

/**
 * Device + browser context for sizing games.
 * Safe for Capacitor native (ios/android) and mobile/desktop web.
 */
export function getPlayAreaProfile() {
  const { width, height } = getPlayAreaSize();
  const platform = Capacitor.getPlatform();
  const isNative = Capacitor.isNativePlatform();
  const isPortrait = height >= width;

  const isPhone = width < 640 || (isPortrait && width < 820);
  const isTablet = !isPhone && width < 1100;
  const isTouch =
    typeof window !== "undefined" &&
    ("ontouchstart" in window ||
      window.matchMedia?.("(pointer: coarse)")?.matches);

  const isStandalone =
    window.matchMedia?.("(display-mode: standalone)")?.matches ||
    window.navigator.standalone === true;

  /** Mobile Safari / Chrome with URL bar (not installed PWA, not native shell) */
  const mobileBrowser =
    !isNative && isPhone && platform === "web" && !isStandalone;

  /** Phone layout: board on top, controls/how-to below (Mathtris, etc.) */
  const stackedControls = isPhone;

  return {
    width,
    height,
    platform,
    isNative,
    isPortrait,
    isPhone,
    isTablet,
    isTouch,
    isStandalone,
    mobileBrowser,
    stackedControls,
  };
}

let cachedSafeInsets = null;

function readSafeAreaInsets() {
  if (typeof document === "undefined") {
    return { top: 0, bottom: 0, left: 0, right: 0 };
  }
  if (cachedSafeInsets) return cachedSafeInsets;
  const probe = document.createElement("div");
  probe.style.cssText =
    "position:fixed;visibility:hidden;pointer-events:none;padding:env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left)";
  document.body.appendChild(probe);
  const s = getComputedStyle(probe);
  const px = (v) => parseFloat(v) || 0;
  cachedSafeInsets = {
    top: px(s.paddingTop),
    bottom: px(s.paddingBottom),
    left: px(s.paddingLeft),
    right: px(s.paddingRight),
  };
  document.body.removeChild(probe);
  return cachedSafeInsets;
}

export function invalidateSafeAreaCache() {
  cachedSafeInsets = null;
}

/**
 * Mathtris cell size from play area.
 * On phones: fill available width (sidebar scrolls below). On desktop: fit height too.
 */
export function computeMathtrisCellSize(
  profile,
  { cols = 8, rows = 14, gap = 2, gridPadding = 8 } = {}
) {
  const { width, height, isPhone, isNative, mobileBrowser, stackedControls } =
    profile;

  const insets = readSafeAreaInsets();
  const cellMin = 26;

  let cellMax = 48;
  if (isPhone) {
    cellMax = isNative ? 52 : mobileBrowser ? 48 : 50;
  } else if (profile.isTablet) {
    cellMax = 46;
  }

  const sidePad = isPhone ? 10 + insets.left + insets.right : 28;
  const maxBoardWidth = width - sidePad;
  const fromWidth = Math.floor(
    (maxBoardWidth - gridPadding - (cols - 1) * gap) / cols
  );

  if (stackedControls) {
    return Math.max(cellMin, Math.min(cellMax, fromWidth));
  }

  const headerReserve =
    (isNative ? 148 : mobileBrowser ? 172 : 160) + insets.top;
  const footerReserve = 28 + insets.bottom;
  const fromHeight = Math.floor(
    (height - headerReserve - footerReserve - (rows - 1) * gap) / rows
  );

  return Math.max(cellMin, Math.min(cellMax, Math.min(fromWidth, fromHeight)));
}

export function computeMathtrisLayout(profile, gridOpts) {
  const cell = computeMathtrisCellSize(profile, gridOpts);
  const cols = gridOpts?.cols ?? 8;
  const gap = gridOpts?.gap ?? 2;
  const gridPadding = gridOpts?.gridPadding ?? 8;
  const boardWidth = cols * cell + (cols - 1) * gap + gridPadding;

  return {
    cell,
    cellFont: `${Math.max(1, cell * 0.042)}rem`,
    boardWidth,
    boardMaxWidth: profile.isPhone
      ? Math.min(profile.width - 12, boardWidth)
      : Math.min(480, boardWidth),
    stackedControls: profile.stackedControls,
    profile,
  };
}

export function usePlayAreaProfile() {
  const [profile, setProfile] = useState(() => getPlayAreaProfile());

  useEffect(() => {
    const update = () => {
      invalidateSafeAreaCache();
      setProfile(getPlayAreaProfile());
    };
    update();
    window.addEventListener("resize", update);
    window.addEventListener("orientationchange", update);
    window.visualViewport?.addEventListener("resize", update);
    window.visualViewport?.addEventListener("scroll", update);
    return () => {
      window.removeEventListener("resize", update);
      window.removeEventListener("orientationchange", update);
      window.visualViewport?.removeEventListener("resize", update);
      window.visualViewport?.removeEventListener("scroll", update);
    };
  }, []);

  return profile;
}

export function useMathtrisLayout(gridOpts) {
  const profile = usePlayAreaProfile();
  return useMemo(
    () => computeMathtrisLayout(profile, gridOpts),
    [
      profile,
      profile.width,
      profile.height,
      profile.isNative,
      profile.mobileBrowser,
      profile.stackedControls,
      gridOpts?.cols,
      gridOpts?.rows,
      gridOpts?.gap,
      gridOpts?.gridPadding,
    ]
  );
}
