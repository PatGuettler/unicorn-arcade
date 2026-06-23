/**
 * Syncs --sai-* CSS vars from env(safe-area-inset-*) and visualViewport offsets.
 * Works on Capacitor 5 without a native safe-area plugin.
 */
function readCssEnvInsets() {
  if (typeof document === "undefined") {
    return { top: 0, right: 0, bottom: 0, left: 0 };
  }

  const probe = document.createElement("div");
  probe.style.cssText =
    "position:fixed;visibility:hidden;pointer-events:none;padding:env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left)";
  document.body.appendChild(probe);
  const styles = getComputedStyle(probe);
  const px = (value) => parseFloat(value) || 0;
  const insets = {
    top: px(styles.paddingTop),
    right: px(styles.paddingRight),
    bottom: px(styles.paddingBottom),
    left: px(styles.paddingLeft),
  };
  document.body.removeChild(probe);
  return insets;
}

function readVisualViewportInsets() {
  if (typeof window === "undefined") {
    return { top: 0, right: 0, bottom: 0, left: 0 };
  }

  const vv = window.visualViewport;
  if (!vv) return { top: 0, right: 0, bottom: 0, left: 0 };

  const top = Math.max(0, Math.round(vv.offsetTop));
  const left = Math.max(0, Math.round(vv.offsetLeft));
  const bottom = Math.max(
    0,
    Math.round(window.innerHeight - vv.height - vv.offsetTop)
  );
  const right = Math.max(
    0,
    Math.round(window.innerWidth - vv.width - vv.offsetLeft)
  );

  return { top, right, bottom, left };
}

function mergeInsets(a, b) {
  return {
    top: Math.max(a.top, b.top),
    right: Math.max(a.right, b.right),
    bottom: Math.max(a.bottom, b.bottom),
    left: Math.max(a.left, b.left),
  };
}

function applySafeAreaInsets(insets) {
  if (typeof document === "undefined") return;
  const root = document.documentElement;
  root.style.setProperty("--sai-top", `${insets.top}px`);
  root.style.setProperty("--sai-right", `${insets.right}px`);
  root.style.setProperty("--sai-bottom", `${insets.bottom}px`);
  root.style.setProperty("--sai-left", `${insets.left}px`);
}

export function syncSafeAreaInsets() {
  const envInsets = readCssEnvInsets();
  const vvInsets = readVisualViewportInsets();
  applySafeAreaInsets(mergeInsets(envInsets, vvInsets));
}

export function installSafeAreaSync() {
  if (typeof window === "undefined") return () => {};

  const update = () => syncSafeAreaInsets();
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
}
