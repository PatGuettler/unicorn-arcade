import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Relative base on production build so GitHub Pages works at /repo-name/ without env vars
export default defineConfig(({ command }) => ({
  plugins: [react()],
  base: command === "build" ? "./" : "/",
}));
