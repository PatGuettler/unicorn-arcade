import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

/** Project Pages URL: https://<user>.github.io/<repo>/ */
const repoName = process.env.GITHUB_REPOSITORY?.split("/")?.[1];
const base =
  process.env.GITHUB_ACTIONS === "true" && repoName ? `/${repoName}/` : "/";

export default defineConfig({
  plugins: [react()],
  base,
});
