import { exec } from "child_process";

class GitManager {
  isPulling = false;

  async pull() {
    await this.ensureSinglePull();
    this.isPulling = true;
    await this.command("pull");
    this.isPulling = false;
  }

  async stash() {
    await this.command("stash");
  }

  async command(command) {
    return new Promise((resolve, reject) => {
      exec(`git ${command}`, (error, stdout, stderr) => {
        if (error) {
          console.error(`Error during git ${command}: ${error.message}`);
          return reject(error);
        }

        if (stderr) {
          console.error(`Git ${command} stderr: ${stderr}`);
        }

        console.log(`Git ${command} stdout: ${stdout}`);
        resolve(stdout);
      });
    });
  }

  async ensureSinglePull() {
    return new Promise((resolve, reject) => {
      const interval = setInterval(() => {
        if (this.isPulling === false) {
          clearInterval(interval);
          resolve(true);
        }
      }, 100);
    });
  }
}

export const gitManager = new GitManager();
