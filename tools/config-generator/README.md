# demo-config

`demo-config` manages configurations for other projects, including `.env` files.

When new release is created, example-org-host will be updated to have new configs. You can also run the Action manually to update example-org-host.

## How to use

If you're not familar with AWS, start from [this notion page](https://www.notion.so/example-orginc/demo-config-env-7eb54f567c374ac9959d33bfe4b0daf7?pvs=4)

1. Clone this repository.
2. In project root, run `npm i` or `yarn` to install npm dependencies.
3. Make `~/.aws/credentials`, and save your credential. [AWS docs](https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/loading-node-credentials-shared.html)  
   We're using `codedeploy` and `deploy-api` account to read secrets from AWS Secrets manager. If you want to use your account, we should update its permission in IAM console. Talk with @lhj2012 or @yhunroh-example-org.
4. Run `yarn build` to create config files to `output/`.
5. Copy files from `output/flat_/` or `output/<project_name>/` to your project directories.  
   Note that filename may be different. e.g., File `dev.env` should be named `.env` in your project directory.
