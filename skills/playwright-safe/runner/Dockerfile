FROM mcr.microsoft.com/playwright:v1.51.0-jammy

WORKDIR /app

COPY package.json ./
RUN PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm install --production --quiet

COPY playwright-runner.js ./
