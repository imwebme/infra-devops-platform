import tracer from "dd-trace";
tracer.init();

import express from "express";
import { buildEnv, envTargets } from "./build.js";
import "dotenv/config";
import CryptoJS from "crypto-js";
import { gitManager } from "./gitManager.js";
import winstonLogger from "./utils/logger/index.js";

const app = express();
const port = 3000;

app.get("/health-check", (req, res) => {
  return res.status(204).send();
});

app.get("/env/:project/:envName", async (req, res) => {
  const { project, envName } = req.params;

  if (!envName.includes(process.env.NODE_ENV)) {
    return res.status(400).send("Can't access other environments");
  }

  await gitManager.stash();
  await gitManager.pull();

  if (!envTargets[project]?.[envName]) {
    return res.status(400).send("Invalid project or envName");
  }

  const envContent = await buildEnv({ project, envName });

  if (!envContent) {
    return res.status(400).send("Invalid project or envName");
  }

  const encryptedEnv = CryptoJS.AES.encrypt(
    envContent,
    process.env.ENCRYPT_KEY
  ).toString();

  res.send({ data: encryptedEnv });
});

const server = app.listen(port, () => {
  winstonLogger.debug(`App listening at ${port}`);
});

server.keepAliveTimeout = 61 * 1000;
server.headersTimeout = 65 * 1000;

app.use(function onError(err, req, res, next) {
  if (err.name === "BadRequestError") {
    return res.status(204).send();
  }

  winstonLogger.error(err);
  res.status(500).send("Something wrong!");
});
