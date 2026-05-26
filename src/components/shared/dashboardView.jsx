import GlobalHeader from "./globalHeader";

const DashBoardView = ({
  selectCategory,
  user,
  userData,
  setCurrentView,
  handleLogout,
  categories,
  onHome,
}) => {
  return (
    <div className="w-full h-app bg-slate-950 flex flex-col">
      <GlobalHeader
        user={user}
        coins={userData?.coins || 0}
        onBack={() => setCurrentView("home")}
        isSubScreen={true}
        title="Game Categories"
        onHome={onHome}
      />

      <div className="flex-1 overflow-y-auto p-6 pb-safe">
        <div className="max-w-md mx-auto">
          <div className="grid gap-4">
            {categories.map((cat) => (
              <div
                key={cat.id}
                onClick={() => selectCategory(cat.id)}
                className="group bg-slate-900 border border-slate-800 p-6 rounded-3xl cursor-pointer hover:border-slate-600 hover:bg-slate-800 transition-all active:scale-[0.98] relative overflow-hidden"
              >
                <div
                  className={`absolute top-0 right-0 w-24 h-24 ${cat.color} opacity-10 rounded-full blur-2xl -mr-10 -mt-10 transition-opacity group-hover:opacity-20`}
                />
                <div className="flex items-center gap-4 relative z-10">
                  <div
                    className={`w-14 h-14 ${cat.color} rounded-2xl flex items-center justify-center text-slate-900 shadow-lg`}
                  >
                    <cat.icon size={28} />
                  </div>
                  <div>
                    <h3 className="text-xl font-bold text-white group-hover:text-cyan-400 transition-colors">
                      {cat.title}
                    </h3>
                    <p className="text-slate-500 text-sm">{cat.desc}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default DashBoardView;
