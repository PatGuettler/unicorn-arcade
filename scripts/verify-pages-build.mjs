import { readFileSync, existsSync } from "fs";

const indexPath = "dist/index.html";

if (!existsSync(indexPath)) {
  console.error("dist/index.html missing — run npm run build first");
  process.exit(1);
}

const html = readFileSync(indexPath, "utf8");

if (html.includes("/src/main.jsx") || html.includes('src="/src/')) {
  console.error(
    "dist/index.html still points at dev sources. Pages must deploy dist/, not main branch source."
  );
  process.exit(1);
}

if (!html.includes("./assets/") && !html.includes('assets/')) {
  console.error("dist/index.html has no bundled assets path.");
  process.exit(1);
}

console.log("Pages build OK:", indexPath);
