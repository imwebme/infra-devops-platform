#!/usr/bin/env node

const inquirer = require('inquirer');
const fs = require('fs');
const path = require('path');

// Levit 배너
const banner = `
  _               _ _
 | |    _____   _(_) |_
 | |   / _ \ \ / / | __|
 | |__|  __/\ V /| | |_
 |_____\___| \_/ |_|\__|
         Welcome to Levit App Generator!
`;

console.log(banner);

const templates = {
  Go: {
    files: {
      'main.go': `package main

import "fmt"

func main() {
    fmt.Println("Hello from Go!")
}
`,
      'go.mod': `module example.com/your-module

go 1.21
`
    }
  },
  TypeScript: {
    files: {
      'src/index.ts': `console.log("Hello from TypeScript!");\n`,
      'package.json': `{
  "name": "my-ts-app",
  "version": "1.0.0",
  "main": "src/index.ts",
  "scripts": {
    "start": "ts-node src/index.ts"
  },
  "devDependencies": {
    "ts-node": "^10.0.0",
    "typescript": "^5.0.0"
  }
}
`,
      'tsconfig.json': `{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "outDir": "dist",
    "rootDir": "src",
    "strict": true
  }
}
`
    }
  },
  Python: {
    files: {
      'main.py': `print("Hello from Python!")\n`,
      'requirements.txt': `# Add your python dependencies here\n`
    }
  }
};

async function main() {
  const { language } = await inquirer.prompt([
    {
      type: 'list',
      name: 'language',
      message: '어떤 언어로 앱을 생성할까요?',
      choices: ['Go', 'TypeScript', 'Python']
    }
  ]);

  const { appName } = await inquirer.prompt([
    {
      type: 'input',
      name: 'appName',
      message: '앱 이름을 입력하세요:',
      validate: (input) => !!input || '앱 이름을 입력해야 합니다.'
    }
  ]);

  const appDir = path.join('apps', appName);
  if (fs.existsSync(appDir)) {
    console.error(`❌ ${appDir} 이미 존재합니다.`);
    process.exit(1);
  }

  fs.mkdirSync(appDir, { recursive: true });

  const files = templates[language].files;
  for (const [file, content] of Object.entries(files)) {
    const filePath = path.join(appDir, file);
    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    fs.writeFileSync(filePath, content);
  }

  console.log(`\n✅ ${appDir} 생성 완료!`);
}

main();
