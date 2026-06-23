import React, { useState, useEffect } from "react";

const AdBar = () => {
  const [currentAdIndex, setCurrentAdIndex] = useState(0);

  useEffect(() => {
    document.body.classList.add("has-ad-bar");
    return () => document.body.classList.remove("has-ad-bar");
  }, []);

  // Child-safe, educational ads - these would typically come from a COPPA-compliant ad network
  // For now, showing placeholder content that follows children's advertising guidelines
  const childSafeAds = [
    {
      id: 1,
      text: "🎨 Learn to Draw! Fun art lessons for kids",
      bgColor: "bg-gradient-to-r from-pink-400 to-purple-400",
    },
    {
      id: 2,
      text: "📚 Reading Adventures - Explore new stories!",
      bgColor: "bg-gradient-to-r from-blue-400 to-cyan-400",
    },
    {
      id: 3,
      text: "🧩 Puzzle Time! Challenge your brain",
      bgColor: "bg-gradient-to-r from-green-400 to-emerald-400",
    },
    {
      id: 4,
      text: "🎵 Music & Songs - Sing along and learn!",
      bgColor: "bg-gradient-to-r from-yellow-400 to-orange-400",
    },
  ];

  // Rotate ads every 8 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentAdIndex((prev) => (prev + 1) % childSafeAds.length);
    }, 8000);

    return () => clearInterval(interval);
  }, []);

  const currentAd = childSafeAds[currentAdIndex];

  return (
    <div className="fixed bottom-0 left-0 right-0 z-50 pointer-events-auto">
      {/* Ad Container - Following standard ad bar height (50-60px) */}
      <div
        className={`h-14 ${currentAd.bgColor} flex items-center justify-center transition-all duration-500 shadow-lg`}
      >
        <div className="flex items-center gap-2 px-4">
          {/* Ad Label - Required by most ad networks and regulations */}
          <div className="text-[10px] font-bold text-white/70 uppercase tracking-wider bg-white/20 px-2 py-1 rounded">
            Ad
          </div>

          {/* Ad Content */}
          <div className="text-white font-bold text-sm animate-fade-in">
            {currentAd.text}
          </div>

          {/* Indicator Dots */}
          <div className="flex gap-1 ml-auto">
            {childSafeAds.map((_, index) => (
              <div
                key={index}
                className={`w-1.5 h-1.5 rounded-full transition-all ${
                  index === currentAdIndex
                    ? "bg-white scale-110"
                    : "bg-white/40"
                }`}
              />
            ))}
          </div>
        </div>
      </div>

      {/* Safe Area Buffer for devices with bottom notches */}
      <div className="bg-slate-950 h-[env(safe-area-inset-bottom)]" />
    </div>
  );
};

export default AdBar;
