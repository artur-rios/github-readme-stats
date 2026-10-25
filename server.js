// The server of the Forgejo + Jenkins deployment (yggdrasil). Vercel served each file of api/ as a serverless
// function under /api/*; this mounts the same handlers on the same paths in one plain Node server, and adds
// GET /healthz for the container health check. express.js (upstream's local-development server) is left as is.
// api/status/* is not mounted: without Vercel's edge cache every public request would reach GitHub, and pat-info
// describes the tokens.
import express from "express";
import statsCard from "./api/index.js";
import repoCard from "./api/pin.js";
import langCard from "./api/top-langs.js";
import wakatimeCard from "./api/wakatime.js";
import gistCard from "./api/gist.js";

const app = express();
const router = express.Router();

router.get("/", statsCard);
router.get("/pin", repoCard);
router.get("/top-langs", langCard);
router.get("/wakatime", wakatimeCard);
router.get("/gist", gistCard);

app.disable("x-powered-by");
app.get("/healthz", (_req, res) => {
  res.type("text/plain").send("ok");
});
// vercel.json redirected the root to the project's page.
app.get("/", (_req, res) => {
  res.redirect(308, "https://github.com/anuraghazra/github-readme-stats");
});
app.use("/api", router);

const port = process.env.PORT || 8080;
const server = app.listen(port, "0.0.0.0", () => {
  console.log(`Server running on port ${port}`);
});

// A request that has not finished in 15 s is dropped (the cards finish in a few seconds at most).
server.requestTimeout = 15000;

// node is PID 1 in the container, where SIGTERM is ignored unless handled. Connections that stay open are cut off
// after 8 s, before the container runtime kills the process.
for (const signal of ["SIGTERM", "SIGINT"]) {
  process.on(signal, () => {
    setTimeout(() => process.exit(1), 8000).unref();
    server.close(() => process.exit(0));
  });
}
