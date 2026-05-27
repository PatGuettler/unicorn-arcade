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

- Node.js (v16 or higher)
- npm or yarn
- For mobile builds: Android Studio (Android) or Xcode (iOS)

### Installation

```bash
# Clone the repository
git clone <your-repo-url>
cd wl-arcade

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

## 📱 Mobile Deployment

### Sync Native Projects

After building, sync the web assets to native projects:

```bash
npx cap sync
```

### Android Build

1. Open Android Studio:

   ```bash
   npx cap open android
   ```

2. In Android Studio:
   - File → Sync Project with Gradle Files
   - Build → Generate Signed Bundle/APK
   - Follow the signing wizard to create your release APK/AAB

### iOS Build

1. Open Xcode:

   ```bash
   npx cap open ios
   ```

2. In Xcode:
   - Select your development team
   - Configure signing & capabilities
   - Product → Archive
   - Follow the distribution wizard

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

Visit your unicorns' homes and decorate them with:

- Furniture (beds, tables, chairs)
- Lighting (lamps, chandeliers, candles)
- Decorations (rugs, plants, toys)
- Seasonal items (Christmas, Halloween)
- Pets and companions

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
├── android/                 # Android native project
├── ios/                     # iOS native project
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

Edit `src/utils/storage.js`:

- Add items to `FURNITURE` array
- Set prices and emoji icons
- Items automatically appear in the shop

## Configuration Files

- `capacitor.config.json` - Capacitor configuration
- `vite.config.js` - Vite build configuration
- `tailwind.config.js` - Tailwind CSS configuration
- `postcss.config.js` - PostCSS plugins

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Create production build
- `npm run preview` - Preview production build
- `npx cap sync` - Sync web assets to native projects
- `npx cap open android` - Open Android Studio
- `npx cap open ios` - Open Xcode

## Troubleshooting

### Build Issues

- Clear node_modules and reinstall: `rm -rf node_modules && npm install`
- Clear build cache: `rm -rf dist`

### Mobile Issues

- Resync Capacitor: `npx cap sync`
- Rebuild native project in Android Studio/Xcode

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
