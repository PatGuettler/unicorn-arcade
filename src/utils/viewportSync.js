/**
 * Keeps --app-height aligned with the visible viewport (WebView-safe).
 * Prefer visualViewport when available; fall back to innerHeight.
 */
export function getVisibleAppHeight() {
  if (typeof window === "undefined") return 0;
  const vv = window.visualViewport;
  return Math.round(vv?.height ?? window.innerHeight);
}

export function syncAppHeight() {
  if (typeof document === "undefined") return;
  const height = getVisibleAppHeight();
  document.documentElement.style.setProperty("--app-height", `${height}px`);
}

export function installViewportSync() {
  if (typeof window === "undefined") return () => {};

  syncAppHeight();

  const update = () => syncAppHeight();
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
