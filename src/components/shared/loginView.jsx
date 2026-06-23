import loginHero from "../assets/sparkle.png";

const loginIconSrc = `${import.meta.env.BASE_URL}loginIcon.png`;

const LoginView = ({ user, setUser, handleLogin }) => {
  const handleSubmit = (e) => {
    e.preventDefault();
    handleLogin(e);
  };

  return (
    <div className="w-full h-app bg-slate-950 flex items-center justify-center p-4">
      <div className="w-full max-w-md flex flex-col">
        {/* Logo section - above the box */}
        <div className="w-full aspect-[16/9] bg-gradient-to-br from-cyan-500 via-purple-500 to-pink-500 rounded-t-3xl p-1 shadow-2xl shadow-purple-500/20">
          <div className="w-full h-full bg-slate-900 rounded-t-[1.35rem] overflow-hidden">
            <img
              src={loginIconSrc}
              alt="Unicorn Arcade"
              className="w-full h-full object-cover"
              onError={(e) => {
                e.currentTarget.onerror = null;
                e.currentTarget.src = loginHero;
              }}
            />
          </div>
        </div>

        {/* Login box */}
        <div className="w-full bg-slate-900 border border-slate-800 rounded-b-3xl p-8 shadow-2xl relative overflow-hidden border-t-0">
          <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-cyan-500 via-purple-500 to-pink-500" />

          <div className="text-center mb-8">
            <h1 className="text-3xl font-black text-white mb-2">
              UNICORN<span className="text-cyan-400">ARCADE</span>
            </h1>
            <p className="text-slate-400 text-sm">
              Train your brain with code-based games.
            </p>
          </div>

          <div className="space-y-4">
            <div>
              <label className="block text-slate-500 text-xs font-bold uppercase mb-2 ml-1">
                Username
              </label>
              <input
                type="text"
                value={user}
                onChange={(e) => setUser(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleSubmit(e)}
                placeholder="Enter player name..."
                className="w-full bg-slate-950 border border-slate-700 rounded-xl px-4 py-4 text-white placeholder-slate-600 focus:outline-none focus:border-cyan-500 transition-colors"
                autoFocus
              />
            </div>
            <button
              type="button"
              onClick={handleSubmit}
              disabled={!user.trim()}
              data-testid="login-submit"
              className="w-full bg-white text-slate-900 font-bold py-4 rounded-xl hover:bg-cyan-50 disabled:opacity-50 disabled:cursor-not-allowed transition-all active:scale-[0.98] shadow-lg"
            >
              ENTER ARCADE
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LoginView;
