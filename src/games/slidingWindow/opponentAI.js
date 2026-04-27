export class OpponentAI {
  constructor(level, windowSize, levelData) {
    this.level = level;
    this.windowSize = windowSize;
    this.levelData = levelData;
    this.position = 0;
    this.intervalId = null;
    this.isRunning = false;
  }

  // Calculate move speed based on level (milliseconds per move)
  getMoveSpeed() {
    const baseSpeed = 2500; // Start at 2.5 seconds per move
    const speedReduction = (this.level - 1) * 150; // Get 150ms faster each level
    return Math.max(1000, baseSpeed - speedReduction); // Never faster than 1 second
  }

  // Start the opponent's automatic movement
  start(onMove, onWin) {
    if (this.isRunning) {
      return; // Already running
    }

    this.isRunning = true;
    const speed = this.getMoveSpeed();

    this.intervalId = setInterval(() => {
      // Check if we can still move
      if (this.position + this.windowSize >= this.levelData.length) {
        this.stop();
        onWin();
        return;
      }

      // Move forward
      this.position += 1;
      onMove(this.position);

      // Check if opponent reached the end AFTER moving
      if (this.position + this.windowSize >= this.levelData.length) {
        this.stop();
        onWin();
        return;
      }
    }, speed);
  }

  // Stop the opponent's movement
  stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
    this.isRunning = false;
  }

  // Reset opponent position
  reset() {
    this.stop();
    this.position = 0;
    this.isRunning = false;
  }
}
