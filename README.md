# Unicorn Arcade

A collection of educational mini-games designed for children to learn math, logic, and word skills while having fun with magical unicorn companions!

## Features

- **Number Games**: Math challenges, coin counting, cash handling, and logic puzzles
- **Word Games**: Typing and vocabulary building activities
- **Unicorn Collection**: Unlock and customize magical unicorn companions
- **Room Decoration**: Personalize your unicorn's living space with furniture
- **Progress Tracking**: Track your best scores and completed levels
- **Offline Support**: Play anytime, anywhere - no internet required

## Quick Start

### Prerequisites

- Node.js 20 LTS (CI uses 20)
- npm
- **Play Store builds:** JDK 17 + Android SDK 36 (CI installs these; Android Studio is optional)

### Installation

```bash
# Clone the repository
git clone <your-repo-url>
cd unicorn-arcade

# Install dependencies
npm install
```

### Development

```bash
# Run development server with hot reload
npm run dev

# The app will be available at http://localhost:5173
```

### Build for Production

```bash
# Build optimized production bundle
npm run build

# Preview production build locally
npm run preview
```

### GitHub Pages (live site)

The site must deploy the **built** `dist/` folder, not the raw `src/` sources.

1. **Settings → Pages → Source:** choose **GitHub Actions** (not Jekyll, not `main` branch).
2. Pushes to `main` run `.github/workflows/deploy-github-pages.yml` (Vite build + deploy).
3. Do **not** use the auto-generated Jekyll workflow — it serves `index.html` with `/src/main.jsx` and causes 404 errors.

```bash
npm run build:verify   # local check before push
```

## Mobile Deployment (Android / Play Store)

**App name:** Unicorn Arcade · **Package:** `com.grapegames.wlarcade` · **Target SDK:** 36 (see [docs/android-play-compliance.md](docs/android-play-compliance.md)).

Production builds are usually done via GitHub Actions (`.github/workflows/deploy-android.yml`), not Android Studio.

```bash
npm ci
npm run build:android
```

Set `VERSION_NAME` in `android/version.properties`. For release signing locally, set `SIGNING_*` env vars (same names as CI). CI sets `versionCode` from the workflow run number (must always increase on Play).

**Godot (in progress):** Native remake lives in [`godot/`](godot/). See [docs/godot-setup.md](docs/godot-setup.md) and [docs/godot-execution.md](docs/godot-execution.md). Capacitor `android/` remains the Play Store build until cutover.

Optional native debugging: `npx cap open android` (Android Studio).

## Game Categories

### Number Games

- **Unicorn Jump**: Navigate paths by jumping exact distances
- **Sliding Window**: Find maximum values in moving windows
- **Coin Count**: Learn to count coins and make change
- **Cash Counter**: Practice with bills and larger amounts
- **Math Swipe**: Solve equations by swiping the correct answer
- **Mathtris**: Drop blocks and clear equations like Tetris

### Word Games

- More games coming soon!

## Unicorn System

Unlock adorable unicorn companions by earning coins through gameplay:

- **Sparkle** (Free) - Your starter companion
- **Rainbow** (500 coins) - Leaves colorful trails
- **Star** (1,200 coins) - Shines bright
- **Cloud** (2,500 coins) - Float above the rest
- **Dreamer** (5,000 coins) - From fantasy worlds
- **Mystic** (10,000 coins) - Pure magical energy

## Unicorn Alley

Visit your unicorns' homes on the alley map and decorate each room (Animal Crossing–style):

- **Marketplace Decor tab** — Browse by category, search items, read flavor descriptions, buy or sell back (50% refund) unused stock
- **Furniture Bag** — Place owned items per room; filter by category; shared inventory across all houses
- **Room editor** — Tap items to select; drag, rotate, resize; grid snap toggle; layer forward/back; reset room
- **Catalog** — 100+ items including cozy, kitchen, nature, wall, luxury, unicorn-themed, and seasonal decor (see `src/data/furnitureCatalog.js`)

## Tech Stack

- **Frontend**: React 18
- **Styling**: Tailwind CSS
- **Build Tool**: Vite
- **Mobile**: Capacitor 5
- **Icons**: Lucide React
- **Storage**: LocalStorage (browser-based persistence)

## Project Structure

```
unicorn-arcade/
├── src/
│   ├── components/
│   │   ├── assets/          # Images and game assets
│   │   ├── shared/          # Reusable UI components
│   │   └── unicornAlley/    # Room decoration system
│   ├── games/               # Individual game implementations
│   ├── hooks/               # Custom React hooks
│   ├── utils/               # Helper functions and storage
│   ├── App.jsx              # Main application component
│   └── main.jsx             # Application entry point
├── android/                 # Capacitor Android shell (Play Store AAB)
├── docs/                    # Play compliance, migration notes
├── dist/                    # Production build output
└── public/                  # Static assets
```

## Customization

### Adding a New Game

1. Create game component in `src/games/yourGame/`
2. Register in `src/games/gameConfig.js`
3. Add game logic and UI
4. Integrate with `useGameSystem` hook for progress tracking

### Modifying Unicorns

Edit `src/utils/storage.js`:

- Add new unicorns to `UNICORNS` array
- Set pricing and descriptions
- Import corresponding image assets

### Adding Furniture

Edit `src/data/furnitureCatalog.js`:

- Add items to the `FURNITURE` array with `id`, `name`, `price`, `icon`, `category`, `rarity`, and `desc`
- Categories are defined in `FURNITURE_CATEGORIES`
- Items automatically appear in the Marketplace Decor tab and Furniture Bag

## Configuration Files

- `capacitor.config.json` - Capacitor configuration
- `vite.config.js` - Vite build configuration
- `tailwind.config.js` - Tailwind CSS configuration
- `postcss.config.js` - PostCSS plugins

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Create production build
- `npm run preview` - Preview production build
- `npm run build:android` - Web build, Capacitor sync, release AAB (requires SDK + signing for release)
- `npx cap sync android` - Sync web assets into `android/` only

## Troubleshooting

### Build Issues

- Clear node_modules and reinstall: `rm -rf node_modules && npm install`
- Clear build cache: `rm -rf dist`

### Mobile Issues

- Resync Capacitor: `npx cap sync android`
- Rebuild AAB: `npm run build:android` (or push to `main` for CI)

### Storage Issues

- Clear browser localStorage to reset progress
- Check browser console for errors

## License

This project is private and proprietary.

## Development Notes

- Game state is managed through `useGameSystem` hook
- Progress is auto-saved to localStorage
- All games support hints (free on level 1, purchasable after)
- Responsive design supports mobile and desktop
- Status bar is hidden on mobile for full-screen experience

## Future Enhancements

- More word games
- Multiplayer features
- Cloud save sync
- Achievement system
- Daily challenges
