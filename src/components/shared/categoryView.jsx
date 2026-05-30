import { CATEGORIES, GAMES, WORD_GAME_SECTIONS } from "../../games/gameConfig";
import GlobalHeader from "./globalHeader";

function GameCard({ game, userData, selectGame }) {
  return (
    <div
      onClick={() => selectGame(game.id)}
      className="bg-slate-900 border border-slate-800 p-4 rounded-2xl cursor-pointer hover:border-cyan-500/50 hover:shadow-[0_0_20px_rgba(6,182,212,0.1)] transition-all active:scale-[0.98] flex flex-col items-center text-center aspect-square justify-center"
    >
      <div className="text-4xl mb-3">{game.icon}</div>
      <h3 className="font-bold text-white text-sm mb-1">{game.title}</h3>
      <div className="mt-2 px-2 py-1 bg-slate-800 rounded text-[10px] text-emerald-400 font-mono border border-slate-700">
        {userData[game.id]?.maxLevel > 0
          ? `Last: ${userData[game.id].maxLevel}`
          : "Start"}
      </div>
      <p className="text-xs text-slate-500 mt-2 leading-snug">{game.desc}</p>
    </div>
  );
}

const CategoryView = ({
  activeCategory,
  goBack,
  userData,
  selectGame,
  onHome,
}) => {
  const category = CATEGORIES.find((c) => c.id === activeCategory);
  const isWordCategory = activeCategory === "word";
  const gameList = GAMES[activeCategory] || [];

  return (
    <div className="w-full h-app bg-slate-950 flex flex-col">
      <GlobalHeader
        coins={userData?.coins || 0}
        onBack={goBack}
        isSubScreen={true}
        title={category.title}
        onHome={onHome}
      />

      <div className="flex-1 overflow-y-auto p-6 pb-safe">
        <div className="max-w-md mx-auto">
          <div className="flex items-center gap-4 mb-8">
            <div
              className={`w-12 h-12 ${category.color} rounded-xl flex items-center justify-center text-slate-900`}
            >
              <category.icon size={24} />
            </div>
            <h2 className="text-3xl font-black text-white">{category.title}</h2>
          </div>

          {isWordCategory ? (
            <div className="space-y-8">
              {WORD_GAME_SECTIONS.map((section) => (
                <div key={section.id}>
                  {section.classicLayout ? (
                    <div className="grid grid-cols-2 gap-4">
                      {section.games.map((game) => (
                        <GameCard
                          key={game.id}
                          game={game}
                          userData={userData}
                          selectGame={selectGame}
                        />
                      ))}
                    </div>
                  ) : (
                    <>
                      <div
                        className={`rounded-2xl border bg-gradient-to-r p-4 mb-4 ${section.accent}`}
                      >
                        <div className="flex items-center gap-3">
                          <span className="text-3xl">{section.icon}</span>
                          <div>
                            <h3 className="text-lg font-black text-white">
                              {section.title}
                            </h3>
                            <p className="text-xs text-slate-400">{section.desc}</p>
                          </div>
                        </div>
                      </div>
                      <div className="grid grid-cols-2 gap-4">
                        {section.games.map((game) => (
                          <GameCard
                            key={game.id}
                            game={game}
                            userData={userData}
                            selectGame={selectGame}
                          />
                        ))}
                      </div>
                    </>
                  )}
                </div>
              ))}
            </div>
          ) : gameList.length > 0 ? (
            <div className="grid grid-cols-2 gap-4">
              {gameList.map((game) => (
                <GameCard
                  key={game.id}
                  game={game}
                  userData={userData}
                  selectGame={selectGame}
                />
              ))}
            </div>
          ) : (
            <div className="py-10 text-center text-slate-600 border border-dashed border-slate-800 rounded-2xl">
              No games available in this category yet.
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default CategoryView;
