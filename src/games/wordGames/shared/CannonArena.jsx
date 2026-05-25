import { UnicornAvatar } from "../../../components/assets/gameAssets";

/** Falling words + bottom cannon that fires the player's unicorn */
export default function CannonArena({
  words,
  projectiles,
  explosions,
  unicornImage,
}) {
  return (
    <div className="absolute inset-0 overflow-hidden bg-gradient-to-b from-indigo-950 via-purple-900 to-slate-950">
      <div className="absolute inset-0 opacity-30 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-pink-500/20 via-transparent to-transparent" />

      {words.map((w) => (
        <div
          key={w.id}
          className={`absolute px-3 py-1.5 rounded-xl font-black text-lg border-2 transition-all duration-300 ${
            w.destroyed
              ? "opacity-0 scale-150 border-transparent"
              : "opacity-100 border-white/30 bg-slate-900/70 text-white shadow-lg"
          }`}
          style={{
            left: `${w.x}%`,
            top: `${w.y}%`,
            transform: "translate(-50%, -50%)",
            zIndex: 10,
          }}
        >
          {w.text}
        </div>
      ))}

      {explosions.map((ex) => (
        <div
          key={ex.id}
          className="absolute pointer-events-none"
          style={{
            left: `${ex.x}%`,
            top: `${ex.y}%`,
            transform: "translate(-50%, -50%)",
            zIndex: 25,
          }}
        >
          <div className="text-4xl animate-ping">💥</div>
          <div className="absolute inset-0 flex gap-1 justify-center">
            {["✨", "⭐", "🌟"].map((s, i) => (
              <span
                key={i}
                className="text-xl animate-bounce"
                style={{ animationDelay: `${i * 0.1}s` }}
              >
                {s}
              </span>
            ))}
          </div>
        </div>
      ))}

      {projectiles.map((p) => {
        const startX = p.fromX ?? 50;
        const startY = p.fromY ?? 88;
        const endX = p.target.x;
        const endY = p.target.y;
        const t = p.progress ?? (p.status === "hit" ? 1 : 0.5);
        const x = startX + (endX - startX) * t;
        const y = startY + (endY - startY) * t;

        return (
          <div
            key={p.id}
            className="absolute w-14 h-14 transition-none"
            style={{
              left: `${x}%`,
              top: `${y}%`,
              transform: "translate(-50%, -50%)",
              zIndex: 20,
            }}
          >
            {unicornImage ? (
              <UnicornAvatar
                image={unicornImage}
                className={`w-full h-full ${p.status === "flying" ? "rotate-12" : ""}`}
              />
            ) : (
              <span className="text-3xl">🦄</span>
            )}
          </div>
        );
      })}

      {/* Cannon base */}
      <div
        className="absolute left-1/2 -translate-x-1/2 z-15 flex flex-col items-center"
        style={{ bottom: "4.5rem" }}
      >
        <div className="w-20 h-10 bg-gradient-to-t from-slate-800 to-slate-600 rounded-t-2xl border-2 border-slate-500 shadow-xl relative">
          <div className="absolute -top-6 left-1/2 -translate-x-1/2 w-8 h-8 bg-slate-700 rounded-full border-2 border-amber-500/60" />
          <div className="absolute -top-10 left-1/2 -translate-x-1/2 w-3 h-8 bg-slate-600 rounded-full" />
        </div>
        {unicornImage && (
          <div className="absolute -top-16 w-12 h-12">
            <UnicornAvatar image={unicornImage} className="w-full h-full" />
          </div>
        )}
      </div>
    </div>
  );
}
