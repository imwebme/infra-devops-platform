import {
  SecretsManagerClient,
  GetSecretValueCommand,
} from "@aws-sdk/client-secrets-manager";
import { fromNodeProviderChain } from  "@aws-sdk/credential-providers";

const REGION = "ap-northeast-2";
const secretsClient = new SecretsManagerClient({
  region: REGION,
  credentials: fromNodeProviderChain(),
});

const secretIds = {
  dev: "arn:aws:secretsmanager:ap-northeast-2:123456789012:secret:demo/dev/common-77jE1C",
  prod: "arn:aws:secretsmanager:ap-northeast-2:123456789012:secret:demo/prod/common-sp19po"
};

const getSecrets = async () => {
  let secrets = {};
  for (const [group, SecretId] of Object.entries(secretIds)) {
    let response = await secretsClient.send(
      new GetSecretValueCommand({ SecretId })
    );
    secrets[group] = JSON.parse(response.SecretString);
  }
  console.log("Finished fetching secrets!!");
  return secrets;
};

export { getSecrets };

// Print secrets when this file is executed directly
if (process.argv[process.argv.length - 1].includes("secret.js")) {
  Promise.resolve(getSecrets().then((secrets) => console.log(secrets)));
}
