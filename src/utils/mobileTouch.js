/** Elements that should receive taps instead of parent pan/zoom handlers */
const INTERACTIVE_SELECTOR =
  'button, a, input, textarea, select, label, [data-tap], [data-game-node], [data-falling], [data-mcell][data-falling], [role="button"]';

export function isInteractiveTouch(e) {
  const target = e.target;
  if (!(target instanceof Element)) return false;
  return !!target.closest(INTERACTIVE_SELECTOR);
}

/** Wrap a handler so it skips buttons/inputs (fixes iOS Safari ghost taps) */
export function ignoreIfInteractive(handler) {
  return (e) => {
    if (isInteractiveTouch(e)) return;
    handler?.(e);
  };
}

/** Call on buttons/links so parent game drag handlers do not steal the tap */
export function guardTap(e) {
  e.stopPropagation();
}
