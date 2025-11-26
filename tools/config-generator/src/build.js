import fs from "fs";
import nunjucks from "nunjucks";

import { getSecrets } from "./secret.js";

const TEMPLATE_PATH = "./templates";
const OUTPUT_PATH = "./output";
const FLAT_OUTPUT_PATH = "./output/_flat";
nunjucks.configure(TEMPLATE_PATH, {
  noCache: true,
});
if (!fs.existsSync(FLAT_OUTPUT_PATH))
  fs.mkdirSync(FLAT_OUTPUT_PATH, { recursive: true });

const envTargets = {
  // cron
  "demo-cron": {
    prod: {
      template: "demo-cron.env.prod.njk",
      output: ".env.prod",
    },
    dev: {
      template: "demo-cron.env.dev.njk",
      output: ".env.dev",
    },
    local: {
      template: "demo-cron.env.local.njk",
      output: ".env.local",
    },
  },
  "demo-cron-pay": {
    prod: {
      template: "demo-cron-pay.env.prod.njk",
      output: ".env.prod",
    },
    dev: {
      template: "demo-cron-pay.env.dev.njk",
      output: ".env.dev",
    },
    local: {
      template: "demo-cron-pay.env.local.njk",
      output: ".env.local",
    },
  },
  "demo-python-cron": {
    prod: {
      template: "demo-python-cron.env.njk",
      output: ".env",
    },
    "prod-eks": {
      template: "demo-cron-python.env.prod.njk",
      output: ".env.prod",
    },
    dev: {
      template: "demo-cron-python.env.dev.njk",
      output: ".env.dev",
    },
    local: {
      template: "demo-cron-python.env.local.njk",
      output: ".env.local",
    },
  },
  // front
  "demo-front": {
    dev: {
      template: "demo-front-dev.env.njk",
      output: "dev.env",
    },
    staging: {
      template: "demo-front-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-front-production.env.njk",
      output: "prod.env",
    },
  },
  "demo-farm": {
    dev: {
      template: "demo-farm-dev.env.njk",
      output: "dev.env",
    },
    staging: {
      template: "demo-farm-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-farm-production.env.njk",
      output: "prod.env",
    },
  },
  "demo-webscreen": {
    staging: {
      template: "demo-webscreen-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-webscreen.env.njk",
      output: "prod.env",
    },
  },
  "demo-shorts-front": {
    staging: {
      template: "demo-shorts-front-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-shorts-front-prod.env.njk",
      output: "prod.env",
    },
  },
  "alwalk-front": {
    staging: {
      template: "alwalk-front-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "alwalk-front.env.njk",
      output: "prod.env",
    },
  },
  "demo-seller": {
    dev: {
      template: "demo-seller-dev.env.njk",
      output: "dev.env",
    },
    staging: {
      template: "demo-seller-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-seller.env.njk",
      output: "prod.env",
    },
  },
  "demo-seller-back": {
    dev: {
      template: "demo-seller-back-dev.env.njk",
      output: "dev.env",
    },
    prod: {
      template: "demo-seller-back-production.env.njk",
      output: "prod.env",
    },
    staging: {
      template: "demo-seller-back-staging.env.njk",
      output: "staging.env",
    },
  },
  "demo-admin": {
    prod: {
      template: "demo-admin.env.njk",
      output: ".env",
    },
    staging: {
      template: "demo-admin-front-staging.env.njk",
      output: "staging.env",
    },
  },
  // back
  "demo-back": {
    dev: {
      template: "demo-back-dev.env.njk",
      output: "dev.env",
    },
    staging: {
      template: "demo-back-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-back-production.env.njk",
      output: "prod.env",
    },
  },
  "alfarm-back": {
    dev: {
      template: "alfarm-back-dev.env.njk",
      output: "dev.env",
    },
    staging: {
      template: "alfarm-back-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "alfarm-back-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-shorts-back": {
    staging: {
      template: "demo-shorts-back-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-shorts-back-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-admin-back": {
    dev: {
      template: "demo-admin-back-dev.env.njk",
      output: "dev.env",
    },
    staging: {
      template: "demo-admin-back-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-admin-back-production.env.njk",
      output: "prod.env",
    },
  },
  "allulu-back": {
    staging: {
      template: "allulu-back-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "allulu-back-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-square-back": {
    dev: {
      template: "demo-square-back-dev.env.njk",
      output: "dev.env",
    },
    prod: {
      template: "demo-square-back-production.env.njk",
      output: "prod.env",
    },
  },
  "demo-square-front": {
    prod: {
      template: "demo-square-front-production.env.njk",
      output: "prod.env",
    },
  },
  "demo-drama-back": {
    dev: {
      template: "demo-drama-back-dev.env.njk",
      output: "dev.env",
    },
    staging: {
      template: "demo-drama-back-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-drama-back-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-drama-front": {
    staging: {
      template: "demo-drama-front-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-drama-front-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-crawlsearch-front": {
    prod: {
      template: "demo-crawlsearch-prod.env.njk",
      output: "prod.env",
    },
  },
  // etc
  "demo-web": {
    prod: {
      template: "demo-web.env.njk",
      output: ".env",
    },
  },
  "demo-airflow": {
    prod: {
      template: "demo-airflow-prod.env.njk",
      output: ".env",
    },
  },
  "demo-recommendation": {
    dev: {
      template: "demo-reco.env.development.njk",
      output: ".env.dev",
    },
    staging: {
      template: "demo-reco.env.staging.njk",
      output: ".env.staging",
    },
    prod: {
      template: "demo-reco.env.production.njk",
      output: ".env.prod",
    },
    local: {
      template: "demo-reco.env.local.njk",
      output: ".env.local",
    },
  },
  "demo-games-back": {
    dev: {
      template: "demo-games-back-dev.env.njk",
      output: "dev.env",
    },
    staging: {
      template: "demo-games-back-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-games-back-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-games-front": {
    dev: {
      template: "demo-games-front-dev.env.njk",
      output: "dev.env",
    },
    staging: {
      template: "demo-games-front-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-games-front-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-shop-front": {
    dev: {
      template: "demo-shop-front-dev.env.njk",
      output: "dev.env",
    },
    staging: {
      template: "demo-shop-front-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-shop-front-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-events-front": {
    dev: {
      template: "demo-events-front-dev.env.njk",
      output: "dev.env",
    },
    staging: {
      template: "demo-events-front-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-events-front-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-ads-front": {
    dev: {
      template: "demo-ads-front-dev.env.njk",
      output: "dev.env",
    },
    staging: {
      template: "demo-ads-front-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-ads-front-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-short-form-shop-front": {
    prod: {
      template: "demo-short-form-shop-front-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-altto-front": {
    staging: {
      template: "demo-altto-front-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-altto-front-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-alranch-front": {
    prod: {
      template: "demo-alranch-front-prod.env.njk",
      output: "prod.env",
    },
  },
  "almart-front": {
    dev: {
      template: "almart-front-dev.env.njk",
      output: "dev.env",
    },
    staging: {
      template: "almart-front-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "almart-front-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-price-front": {
    dev: {
      template: "demo-price-dev.env.njk",
      output: "dev.env",
    },
    prod: {
      template: "demo-price-prod.env.njk",
      output: "prod.env",
    },
  },
  "almart-back": {
    dev: {
      template: "almart-back-dev.env.njk",
      output: "dev.env",
    },
    staging: {
      template: "almart-back-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "almart-back-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-brainteaser-front": {
    prod: {
      template: "demo-brainteaser-front-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-torimah-front": {
    staging: {
      template: "demo-torimah-front-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-torimah-front-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-altoon-web-front": {
    prod: {
      template: "demo-altoon-web-front-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-node-scraper": {
    prod: {
      template: "demo-node-scraper.env.prod.njk",
      output: "prod.env",
    },
    dev: {
      template: "demo-node-scraper.env.dev.njk",
      output: "dev.env",
    },
  },
  "demo-alfarm-v2-front": {
    dev: {
      template: "demo-alfarm-v2-front-dev.env.njk",
      output: "dev.env",
    },
    staging: {
      template: "demo-alfarm-v2-front-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-alfarm-v2-front-production.env.njk",
      output: "prod.env",
    },
  },
  "shopin-front": {
    staging: {
      template: "shopin-front-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "shopin-front-prod.env.njk",
      output: "prod.env",
    },
  },
  "shopin-partners-front": {
    staging: {
      template: "shopin-partners-front-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "shopin-partners-front-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-pay": {
    dev: {
      template: "demo-pay-dev.env.njk",
      output: "dev.env",
    },
    prod: {
      template: "demo-pay-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-altoon-back": {
    dev: {
      template: "demo-altoon-back-dev.env.njk",
      output: "dev.env",
    },
    staging: {
      template: "demo-altoon-back-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-altoon-back-production.env.njk",
      output: "prod.env",
    },
  },
  "shopin-back": {
    staging: {
      template: "shopin-back-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "shopin-back-prod.env.njk",
      output: "prod.env",
    },
  },
  "shopin-partners-back": {
    staging: {
      template: "shopin-partners-back-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "shopin-partners-back-prod.env.njk",
      output: "prod.env",
    },
  },
  "price-csx-front": {
    prod: {
      template: "price-csx-front-prod.env.njk",
      output: "prod.env",
    },
  },
  "demo-strategy-back": {
    dev: {
      template: "demo-strategy-back-dev.env.njk",
      output: "dev.env",
    },
    staging: {
      template: "demo-strategy-back-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-strategy-back-production.env.njk",
      output: "prod.env",
    },
  },
  "demo-grocery-assitant-front": {
    dev: {
      template: "demo-grocery-assitant-dev.env.njk",
      output: "dev.env",
    },
    staging: {
      template: "demo-grocery-assitant-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-grocery-assitant-production.env.njk",
      output: "prod.env",
    },
  },
  "demo-agent-back": {
    staging: {
      template: "demo-agent-back-staging.env.njk",
      output: "staging.env",
    },
    prod: {
      template: "demo-agent-back-production.env.njk",
      output: "prod.env",
    },
  },
  abwayz: {
    dev: {
      template: "abwayz-dev.env.njk",
      output: "dev.env",
    },
    prod: {
      template: "abwayz-prod.env.njk",
      output: "prod.env",
    },
  },
};

function writeEnvFiles(secrets) {
  console.log("\nBuilding configs...");
  const envContents = {};

  for (const [project, infoObj] of Object.entries(envTargets)) {
    const projectPath = `${OUTPUT_PATH}/${project}`;
    if (!fs.existsSync(projectPath)) fs.mkdirSync(projectPath);
    envContents[project] = {};

    for (const [envName, { template, output }] of Object.entries(infoObj)) {
      console.log(`Rendering ${project}/${output} (${envName})`);
      const flatOutput = template.replace(".njk", "");
      const res = nunjucks.render(template, secrets);

      fs.writeFileSync(`${projectPath}/${output}`, res);
      fs.writeFileSync(`${FLAT_OUTPUT_PATH}/${flatOutput}`, res);
      envContents[project][envName] = res;
    }
  }
  console.log("Finished rendering!");
  return envContents;
}

function writeEnvFile({ secrets, project, envName }) {
  console.log(`\nBuilding config... ${project} ${envName}`);

  const projectPath = `${OUTPUT_PATH}/${project}`;
  if (!fs.existsSync(projectPath)) fs.mkdirSync(projectPath);

  const { template, output } = envTargets[project][envName];
  console.log(`Rendering ${project}/${output} (${envName})`);

  const flatOutput = template.replace(".njk", "");
  const res = nunjucks.render(template, secrets);

  fs.writeFileSync(`${projectPath}/${output}`, res);
  fs.writeFileSync(`${FLAT_OUTPUT_PATH}/${flatOutput}`, res);

  return res;
}

async function buildEnvs() {
  const envContents = await getSecrets().then(writeEnvFiles);
  return envContents;
}

async function buildEnv({ project, envName }) {
  const secrets = await getSecrets();
  return writeEnvFile({ secrets, project, envName });
}

await buildEnvs();

export { envTargets, writeEnvFiles, buildEnvs, buildEnv };
