import { useState, useRef, useEffect } from "react";

export const useGameViewport = (initialZoom = 1) => {
  const [zoom, setZoom] = useState(initialZoom);
  const [pan, setPan] = useState({ x: 0, y: 0 });
  const [isDragging, setIsDragging] = useState(false);

  const stateRef = useRef({
    zoom: initialZoom,
    pan: { x: 0, y: 0 },
    isDragging: false,
    dragStart: { x: 0, y: 0, panX: 0, panY: 0 },
    pinchStartDist: 0,
    pinchStartZoom: 1,
    pinchStartPan: { x: 0, y: 0 },
    pinchScreenCenter: { x: 0, y: 0 },
    pinchWorldCenter: { x: 0, y: 0 },
    isPinching: false,
  });

  // Keep stateRef synced
  useEffect(() => {
    stateRef.current.zoom = zoom;
    stateRef.current.pan = pan;
    stateRef.current.isDragging = isDragging;
  }, [zoom, pan, isDragging]);

  const startDrag = (e) => {
    if (e.touches && e.touches.length === 2) return; // pinch mode takes over

    const x = e.touches ? e.touches[0].clientX : e.clientX;
    const y = e.touches ? e.touches[0].clientY : e.clientY;

    stateRef.current.dragStart = {
      x,
      y,
      panX: stateRef.current.pan.x,
      panY: stateRef.current.pan.y,
    };

    setIsDragging(true);
  };

  const doDrag = (e) => {
    // Pinch zooming takes over
    if (stateRef.current.isPinching) return;

    if (!stateRef.current.isDragging) return;

    const x = e.touches ? e.touches[0].clientX : e.clientX;
    const y = e.touches ? e.touches[0].clientY : e.clientY;

    const dx = x - stateRef.current.dragStart.x;
    const dy = y - stateRef.current.dragStart.y;

    setPan({
      x: stateRef.current.dragStart.panX + dx,
      y: stateRef.current.dragStart.panY + dy,
    });
  };

  const endDrag = () => {
    setIsDragging(false);
  };

  // ------------------------------
  //      PINCH-TO-ZOOM SUPPORT
  // ------------------------------
  const touchStart = (e) => {
    if (e.touches.length === 2) {
      e.preventDefault();

      const [a, b] = e.touches;
      const dist = Math.hypot(b.clientX - a.clientX, b.clientY - a.clientY);

      // Store current screen center between fingers
      const screenCenterX = (a.clientX + b.clientX) / 2;
      const screenCenterY = (a.clientY + b.clientY) / 2;

      // Store current state
      const currentZoom = stateRef.current.zoom;
      const currentPanX = stateRef.current.pan.x;
      const currentPanY = stateRef.current.pan.y;

      // Convert to world coordinates
      const worldX = (screenCenterX - currentPanX) / currentZoom;
      const worldY = (screenCenterY - currentPanY) / currentZoom;

      stateRef.current.isPinching = true;
      stateRef.current.pinchStartDist = dist;
      stateRef.current.pinchStartZoom = currentZoom;
      stateRef.current.pinchStartPan = { x: currentPanX, y: currentPanY };
      stateRef.current.pinchScreenCenter = {
        x: screenCenterX,
        y: screenCenterY,
      };
      stateRef.current.pinchWorldCenter = { x: worldX, y: worldY };
    }
  };

  const touchMove = (e) => {
    if (e.touches.length === 2 && stateRef.current.isPinching) {
      e.preventDefault();

      const [a, b] = e.touches;
      const currentDist = Math.hypot(
        b.clientX - a.clientX,
        b.clientY - a.clientY
      );

      // Current screen center between fingers
      const currentScreenCenterX = (a.clientX + b.clientX) / 2;
      const currentScreenCenterY = (a.clientY + b.clientY) / 2;

      // Calculate zoom scale
      const scale = currentDist / stateRef.current.pinchStartDist;
      const newZoom = Math.max(
        0.2,
        Math.min(3.0, stateRef.current.pinchStartZoom * scale)
      );

      // The world point we want to keep under our fingers
      const targetWorldX = stateRef.current.pinchWorldCenter.x;
      const targetWorldY = stateRef.current.pinchWorldCenter.y;

      // Calculate where that world point should be on screen now
      // We want: currentScreenCenter = pan + (worldCenter * zoom)
      // So: pan = currentScreenCenter - (worldCenter * zoom)
      const newPanX = currentScreenCenterX - targetWorldX * newZoom;
      const newPanY = currentScreenCenterY - targetWorldY * newZoom;

      setZoom(newZoom);
      setPan({ x: newPanX, y: newPanY });
    }
  };

  const touchEnd = () => {
    stateRef.current.isPinching = false;
    setIsDragging(false);
  };

  // ----------------------------------
  // Mouse + wheel zoom (desktop)
  // ----------------------------------
  const applyZoom = (delta, center = null) => {
    const focus = center || {
      x: window.innerWidth / 2,
      y: window.innerHeight / 2,
    };

    const current = stateRef.current.zoom;
    const newZoom = Math.max(0.2, Math.min(3.0, current + delta));
    if (newZoom === current) return;

    // Calculate world coordinates at the focus point
    const worldX = (focus.x - stateRef.current.pan.x) / current;
    const worldY = (focus.y - stateRef.current.pan.y) / current;

    // Keep that world point at the same screen position
    const newPanX = focus.x - worldX * newZoom;
    const newPanY = focus.y - worldY * newZoom;

    setZoom(newZoom);
    setPan({ x: newPanX, y: newPanY });
  };

  return {
    zoom,
    pan,
    isDragging,
    startDrag,
    doDrag,
    endDrag,
    applyZoom,
    touchStart,
    touchMove,
    touchEnd,
    setZoom,
    setPan,
  };
};
