import { useState, useEffect, useRef, useCallback } from "react";
import { snapToGrid } from "../utils/furnitureUtils";

const clamp = (v, min, max) => Math.max(min, Math.min(max, v));

/**
 * Smooth room placement: local state while dragging, persist once on pointer up.
 * Single window-level pointer listener (no per-item mousemove handlers).
 */
export function useRoomDrag({ placements, gridSnap, onCommit }) {
  const [items, setItems] = useState(placements);
  const canvasRectRef = useRef(null);
  const dragRef = useRef(null);
  const rafRef = useRef(null);
  const pendingRef = useRef(null);

  useEffect(() => {
    if (!dragRef.current) {
      setItems(placements);
    }
  }, [placements]);

  const setCanvasRect = useCallback((rect) => {
    if (rect?.width > 0 && rect?.height > 0) {
      canvasRectRef.current = rect;
    }
  }, []);

  const flushPending = useCallback(() => {
    const p = pendingRef.current;
    if (!p) return;
    pendingRef.current = null;
    setItems((prev) =>
      prev.map((it) =>
        it.instanceId === p.instanceId ? { ...it, x: p.x, y: p.y } : it
      )
    );
  }, []);

  const schedulePositionUpdate = useCallback(
    (instanceId, x, y) => {
      pendingRef.current = { instanceId, x, y };
      if (rafRef.current == null) {
        rafRef.current = requestAnimationFrame(() => {
          rafRef.current = null;
          flushPending();
        });
      }
    },
    [flushPending]
  );

  const updateItemLocal = useCallback((instanceId, patch) => {
    setItems((prev) => {
      const next = prev.map((it) =>
        it.instanceId === instanceId ? { ...it, ...patch } : it
      );
      const updated = next.find((it) => it.instanceId === instanceId);
      if (updated) onCommit(updated);
      return next;
    });
  }, [onCommit]);

  const endDrag = useCallback(
    (e) => {
      const d = dragRef.current;
      if (!d || e.pointerId !== d.pointerId) return;

      try {
        e.target?.releasePointerCapture?.(e.pointerId);
      } catch {
        /* already released */
      }

      if (d.mode === "move") {
        flushPending();
        setItems((prev) => {
          const item = prev.find((it) => it.instanceId === d.instanceId);
          if (item) onCommit(item);
          return prev;
        });
      } else if (d.mode === "resize") {
        setItems((prev) => {
          const item = prev.find((it) => it.instanceId === d.instanceId);
          if (item) onCommit(item);
          return prev;
        });
      }

      dragRef.current = null;
    },
    [flushPending, onCommit]
  );

  useEffect(() => {
    const onMove = (e) => {
      const d = dragRef.current;
      if (!d || e.pointerId !== d.pointerId) return;

      const rect = canvasRectRef.current;
      if (!rect) return;

      if (d.mode === "move") {
        const dx = ((e.clientX - d.startX) / rect.width) * 100;
        const dy = ((e.clientY - d.startY) / rect.height) * 100;
        let x = clamp(d.originX + dx, 4, 96);
        let y = clamp(d.originY + dy, 4, 96);
        x = snapToGrid(x, gridSnap);
        y = snapToGrid(y, gridSnap);
        schedulePositionUpdate(d.instanceId, x, y);
      } else if (d.mode === "resize") {
        const dx = e.clientX - d.startX;
        const scale = clamp(d.originScale + dx * 0.004, 0.5, 3);
        setItems((prev) =>
          prev.map((it) =>
            it.instanceId === d.instanceId ? { ...it, scale } : it
          )
        );
      }
    };

    const onUp = (e) => endDrag(e);
    const onCancel = (e) => endDrag(e);

    window.addEventListener("pointermove", onMove, { passive: true });
    window.addEventListener("pointerup", onUp);
    window.addEventListener("pointercancel", onCancel);

    return () => {
      window.removeEventListener("pointermove", onMove);
      window.removeEventListener("pointerup", onUp);
      window.removeEventListener("pointercancel", onCancel);
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
    };
  }, [gridSnap, schedulePositionUpdate, endDrag]);

  const startDrag = useCallback((e, instanceId, mode = "move") => {
    e.preventDefault();
    e.stopPropagation();

    const item = items.find((it) => it.instanceId === instanceId);
    if (!item) return;

    const el = e.currentTarget;
    if (el.setPointerCapture) {
      try {
        el.setPointerCapture(e.pointerId);
      } catch {
        /* ignore */
      }
    }

    dragRef.current = {
      instanceId,
      mode,
      pointerId: e.pointerId,
      startX: e.clientX,
      startY: e.clientY,
      originX: item.x,
      originY: item.y,
      originScale: item.scale ?? 1,
    };
  }, [items]);

  const addItem = useCallback((item) => {
    setItems((prev) => [...prev, item]);
  }, []);

  const removeItem = useCallback((instanceId) => {
    setItems((prev) => prev.filter((it) => it.instanceId !== instanceId));
  }, []);

  const replaceItems = useCallback((next) => {
    setItems(next);
  }, []);

  const isDragging = (instanceId) =>
    dragRef.current?.instanceId === instanceId;

  return {
    items,
    setCanvasRect,
    startDrag,
    updateItemLocal,
    addItem,
    removeItem,
    replaceItems,
    isDragging,
  };
}
