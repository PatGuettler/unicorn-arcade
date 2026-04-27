import React, { useState, useEffect } from "react";
import { App as CapacitorApp } from "@capacitor/app";

import { getDB, saveDB, UNICORNS } from "./utils/storage";
import UnicornJumpGame from "./games/unicornJump";
import SlidingWindowGame from "./games/slidingWindow";
import CoinCountGame from "./games/coinCount";
import CashCounterGame from "./games/cashCounter";
import MathSwipeGame from "./games/mathSwipe";
import ProfileView from "./components/shared/profileView";
import HomeView from "./components/shared/homeView";
import ShopView from "./components/shared/shopView";
import UnicornAlleyView from "./components/unicornAlley/unicornAlleyView";
import RoomView from "./components/unicornAlley/roomView";
import { CATEGORIES } from "./games/gameConfig";
import LoginView from "./components/shared/loginView";
import CategoryView from "./components/shared/categoryView";
import DashBoardView from "./components/shared/dashboardView";
import AdBar from "./components/shared/adBar";
import { calculateCoins } from "./utils/useGameManager";

export default function App() {
  const [currentView, setCurrentView] = useState("login");
  const [user, setUser] = useState("");
  const [activeCategory, setActiveCategory] = useState(null);
  const [activeGame, setActiveGame] = useState(null);
  const [activeRoomUnicorn, setActiveRoomUnicorn] = useState(null);
  const [userData, setUserData] = useState(null);

  const goHome = () => setCurrentView("home");

  useEffect(() => {
    const db = getDB();
    if (db.lastUser && db.users[db.lastUser]) {
      setUser(db.lastUser);
      setUserData(db.users[db.lastUser]);
    }
  }, []);

  const ensureDataStructure = (data) => {
    if (!data) return null;
    if (!data.coins) data.coins = 0;
    if (!data.ownedUnicorns) data.ownedUnicorns = ["sparkle"];
    if (!data.equippedUnicorn) data.equippedUnicorn = "sparkle";
    if (!data.furniture) data.furniture = { inventory: {}, placements: {} };
    return data;
  };

  useEffect(() => {
    let backButtonListener;
    const setupListener = async () => {
      backButtonListener = await CapacitorApp.addListener(
        "backButton",
        ({ canGoBack }) => {
          if (
            [
              "game",
              "category",
              "dashboard",
              "profile",
              "shop",
              "alley",
              "room",
            ].includes(currentView)
          ) {
            goBack();
          } else if (currentView === "home" || currentView === "login") {
            CapacitorApp.exitApp();
          }
        }
      );
    };
    setupListener();
    return () => {
      if (backButtonListener) backButtonListener.remove();
    };
  }, [currentView]);

  const handleLogin = (e) => {
    e.preventDefault();
    if (!user.trim()) return;
    const db = getDB();
    db.lastUser = user;
    if (!db.users[user]) {
      db.users[user] = {
        coins: 1000,
        ownedUnicorns: ["sparkle"],
        equippedUnicorn: "sparkle",
        furniture: { inventory: {}, placements: {} },
        unicorn: { maxLevel: 0, times: [] },
        sliding: { maxLevel: 0, times: [] },
        coin: { maxLevel: 0, times: [] },
        cash: { maxLevel: 0, times: [] },
        spaceUnicorn: { maxLevel: 0, times: [] },
        mathSwipe: { maxLevel: 0, times: [] },
      };
    }

    saveDB(db);
    setUserData(db.users[user]);
    setCurrentView("home");
  };

  const handlePlay = () => setCurrentView("dashboard");

  const handleSaveProgress = (gameKey, nextLvl, time) => {
    const db = getDB();
    const currentUserData = ensureDataStructure(db.users[user]);
    const coinsEarned = 10 + nextLvl * 5;
    currentUserData.coins += coinsEarned;
    if (nextLvl > currentUserData[gameKey].maxLevel)
      currentUserData[gameKey].maxLevel = nextLvl;
    currentUserData[gameKey].times.push({
      level: nextLvl,
      time,
      date: Date.now(),
    });
    db.users[user] = currentUserData;
    saveDB(db);
    setUserData({ ...currentUserData });
  };

  const handleSpendCoins = (amount) => {
    const db = getDB();
    const currentUserData = ensureDataStructure(db.users[user]);
    if (currentUserData.coins >= amount) {
      currentUserData.coins -= amount;
      db.users[user] = currentUserData;
      saveDB(db);
      setUserData({ ...currentUserData });
      return true;
    }
    return false;
  };

  const handleBuyUnicorn = (id, cost) => {
    const db = getDB();
    const currentUserData = ensureDataStructure(db.users[user]);
    if (currentUserData.coins >= cost) {
      currentUserData.coins -= cost;
      currentUserData.ownedUnicorns.push(id);
      db.users[user] = currentUserData;
      saveDB(db);
      setUserData({ ...currentUserData });
    }
  };

  const handleBuyFurniture = (itemId, cost) => {
    const db = getDB();
    const currentUserData = ensureDataStructure(db.users[user]);
    if (currentUserData.coins >= cost) {
      currentUserData.coins -= cost;
      const currentQty = currentUserData.furniture.inventory[itemId] || 0;
      currentUserData.furniture.inventory[itemId] = currentQty + 1;

      db.users[user] = currentUserData;
      saveDB(db);
      setUserData({ ...currentUserData });
    }
  };

  const handlePlaceItem = (unicornId, itemInstance) => {
    const db = getDB();
    const currentUserData = ensureDataStructure(db.users[user]);

    if (!currentUserData.furniture.placements[unicornId]) {
      currentUserData.furniture.placements[unicornId] = [];
    }

    const list = currentUserData.furniture.placements[unicornId].filter(
      (i) => i.instanceId !== itemInstance.instanceId
    );
    list.push(itemInstance);
    currentUserData.furniture.placements[unicornId] = list;

    db.users[user] = currentUserData;
    saveDB(db);
    setUserData({ ...currentUserData });
  };

  const handleRemoveItem = (unicornId, instanceId) => {
    const db = getDB();
    const currentUserData = ensureDataStructure(db.users[user]);
    if (currentUserData.furniture.placements[unicornId]) {
      currentUserData.furniture.placements[unicornId] =
        currentUserData.furniture.placements[unicornId].filter(
          (i) => i.instanceId !== instanceId
        );
      db.users[user] = currentUserData;
      saveDB(db);
      setUserData({ ...currentUserData });
    }
  };

  const handleEquipUnicorn = (id) => {
    const db = getDB();
    const currentUserData = ensureDataStructure(db.users[user]);
    currentUserData.equippedUnicorn = id;
    db.users[user] = currentUserData;
    saveDB(db);
    setUserData({ ...currentUserData });
  };

  const handleLogout = () => {
    setUser("");
    setUserData(null);
    setCurrentView("login");
  };

  const selectCategory = (catId) => {
    setActiveCategory(catId);
    setCurrentView("category");
  };

  const selectGame = (gameId) => {
    setActiveGame(gameId);
    setCurrentView("game");
  };

  const enterRoom = (unicornId) => {
    setActiveRoomUnicorn(unicornId);
    setCurrentView("room");
  };

  const goBack = () => {
    if (currentView === "game") setCurrentView("category");
    else if (currentView === "category") setCurrentView("dashboard");
    else if (currentView === "dashboard") setCurrentView("home");
    else if (
      currentView === "profile" ||
      currentView === "shop" ||
      currentView === "alley"
    )
      setCurrentView("home");
    else if (currentView === "room") setCurrentView("alley");
  };

  // Determine if we should show the ad bar
  // Show ads everywhere except login screen
  const shouldShowAdBar = currentView !== "login";

  // View Routing
  if (currentView === "login")
    return (
      <LoginView user={user} setUser={setUser} handleLogin={handleLogin} />
    );

  if (currentView === "home")
    return (
      <>
        <HomeView
          user={user}
          userData={userData || { coins: 0, equippedUnicorn: "sparkle" }}
          onPlay={handlePlay}
          onShop={() => setCurrentView("shop")}
          onProfile={() => setCurrentView("profile")}
          onAlley={() => setCurrentView("alley")}
          onHome={goHome}
        />
        {/* {shouldShowAdBar && <AdBar />} */}
      </>
    );

  if (currentView === "shop")
    return (
      <>
        <ShopView
          userData={userData}
          onBuy={handleBuyUnicorn}
          onBuyFurniture={handleBuyFurniture}
          onEquip={handleEquipUnicorn}
          onBack={() => setCurrentView("home")}
          onHome={goHome}
        />
        {/* {shouldShowAdBar && <AdBar />} */}
      </>
    );

  if (currentView === "alley")
    return (
      <>
        <UnicornAlleyView
          userData={userData}
          onEnterRoom={enterRoom}
          onBack={() => setCurrentView("home")}
          onHome={goHome}
        />
        {/* {shouldShowAdBar && <AdBar />} */}
      </>
    );

  if (currentView === "room")
    return (
      <>
        <RoomView
          unicornId={activeRoomUnicorn}
          userData={userData}
          onPlaceItem={handlePlaceItem}
          onRemoveItem={handleRemoveItem}
          onBack={() => setCurrentView("alley")}
          onHome={goHome}
        />
        {/* {shouldShowAdBar && <AdBar />} */}
      </>
    );

  if (currentView === "profile")
    return (
      <>
        <ProfileView
          user={user}
          data={userData}
          onBack={() => setCurrentView("home")}
          onHome={goHome}
          handleLogout={handleLogout}
        />
        {/* {shouldShowAdBar && <AdBar />} */}
      </>
    );

  if (currentView === "dashboard")
    return (
      <>
        <DashBoardView
          user={user}
          userData={userData}
          selectCategory={selectCategory}
          setCurrentView={setCurrentView}
          handleLogout={handleLogout}
          categories={CATEGORIES}
          onHome={goHome}
        />
        {/* {shouldShowAdBar && <AdBar />} */}
      </>
    );

  if (currentView === "game") {
    // Get current unicorn image to pass to game
    const equippedId = userData.equippedUnicorn || "sparkle";
    const currentUnicorn =
      UNICORNS.find((u) => u.id === equippedId) || UNICORNS[0];
    const unicornImage = currentUnicorn.image;

    if (activeGame === "unicorn")
      return (
        <>
          <UnicornJumpGame
            onExit={goBack}
            lastCompletedLevel={userData.unicorn.maxLevel + 1}
            onSaveProgress={(lvl, time) =>
              handleSaveProgress("unicorn", lvl, time)
            }
            calcCoins={calculateCoins}
            coins={userData.coins}
            onSpendCoins={handleSpendCoins}
            onHome={goHome}
            unicornImage={unicornImage}
          />
          {/* {shouldShowAdBar && <AdBar />} */}
        </>
      );
    if (activeGame === "sliding")
      return (
        <>
          <SlidingWindowGame
            onExit={goBack}
            lastCompletedLevel={userData.sliding.maxLevel + 1}
            onSaveProgress={(lvl, time) =>
              handleSaveProgress("sliding", lvl, time)
            }
            calcCoins={calculateCoins}
            onHome={goHome}
            coins={userData.coins}
            onSpendCoins={handleSpendCoins}
            unicornImage={unicornImage}
          />
          {/* {shouldShowAdBar && <AdBar />} */}
        </>
      );
    if (activeGame === "coin")
      return (
        <>
          <CoinCountGame
            onExit={goBack}
            lastCompletedLevel={userData.coin.maxLevel + 1}
            onSaveProgress={(lvl, time) =>
              handleSaveProgress("coin", lvl, time)
            }
            calcCoins={calculateCoins}
            onHome={goHome}
            coins={userData.coins}
            onSpendCoins={handleSpendCoins}
          />
          {/* {shouldShowAdBar && <AdBar />} */}
        </>
      );
    if (activeGame === "cash")
      return (
        <>
          <CashCounterGame
            onExit={goBack}
            lastCompletedLevel={userData.cash.maxLevel + 1}
            onSaveProgress={(lvl, time) =>
              handleSaveProgress("cash", lvl, time)
            }
            calcCoins={calculateCoins}
            onHome={goHome}
            coins={userData.coins}
            onSpendCoins={handleSpendCoins}
          />
          {/* {shouldShowAdBar && <AdBar />} */}
        </>
      );
    if (activeGame === "mathSwipe")
      return (
        <>
          <MathSwipeGame
            onExit={goBack}
            lastCompletedLevel={userData.mathSwipe?.maxLevel + 1 || 1}
            onSaveProgress={(lvl, time) =>
              handleSaveProgress("mathSwipe", lvl, time)
            }
            calcCoins={calculateCoins}
            onHome={goHome}
            coins={userData.coins}
            onSpendCoins={handleSpendCoins}
          />
          {/* {shouldShowAdBar && <AdBar />} */}
        </>
      );

    return <div className="text-white">Game Not Found</div>;
  }

  if (currentView === "category")
    return (
      <>
        <CategoryView
          selectCategory={selectCategory}
          user={user}
          setCurrentView={setCurrentView}
          handleLogout={handleLogout}
          activeCategory={activeCategory}
          goBack={goBack}
          userData={userData}
          selectGame={selectGame}
          onHome={goHome}
        />
        {/* {shouldShowAdBar && <AdBar />} */}
      </>
    );

  return null;
}
