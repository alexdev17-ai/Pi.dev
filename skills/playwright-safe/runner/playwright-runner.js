'use strict';

const { chromium } = require('playwright');
const { URL: URLParser } = require('url');
const args = require('minimist')(process.argv.slice(2));

const OPERATION = args.operation;
const URL = args.url;
const SELECTORS = args.selectors ? JSON.parse(args.selectors) : [];
const ACTION_DATA = args['action-data'] ? JSON.parse(args['action-data']) : {};

function respond(status, messages, data) {
  process.stdout.write(JSON.stringify({ status, messages, data }) + '\n');
}

async function main() {
  if (!OPERATION || !URL) {
    respond('error', ['--operation and --url are required'], {});
    process.exit(1);
  }

  // Whitelist: only http and https schemes allowed
  try {
    const parsed = new URLParser(URL);
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
      respond('error', [`URL scheme '${parsed.protocol}' is not allowed. Only http: and https: are permitted.`], {});
      process.exit(1);
    }
  } catch (e) {
    respond('error', [`Invalid URL: ${e.message}`], {});
    process.exit(1);
  }

  const browser = await chromium.launch({ args: ['--no-sandbox', '--disable-setuid-sandbox'] });
  const context = await browser.newContext();
  const page = await context.newPage();

  const data = {
    url: '',
    title: '',
    text: '',
    links: [],
    screenshot_path: null
  };

  try {
    await page.goto(URL, { waitUntil: 'domcontentloaded', timeout: 30000 });
    data.url = page.url();
    data.title = await page.title();

    switch (OPERATION) {
      case 'goto':
        data.text = (await page.textContent('body') || '').trim().slice(0, 50000);
        data.links = await page.$$eval('a[href]', els =>
          els.map(el => el.href).filter(h => h.startsWith('http')).slice(0, 200)
        );
        break;

      case 'click':
        if (!SELECTORS[0]) throw new Error('click requires selectors[0]');
        await page.click(SELECTORS[0]);
        await page.waitForLoadState('domcontentloaded');
        data.url = page.url();
        data.title = await page.title();
        data.text = (await page.textContent('body') || '').trim().slice(0, 50000);
        break;

      case 'extract_text':
        for (const sel of SELECTORS) {
          const el = await page.$(sel);
          if (el) {
            const t = await el.textContent();
            data.text += (t || '').trim() + '\n';
          }
        }
        data.text = data.text.slice(0, 50000);
        break;

      case 'extract_links':
        data.links = await page.$$eval('a[href]', els =>
          els.map(el => ({ href: el.href, text: el.textContent.trim() }))
            .filter(l => l.href.startsWith('http'))
            .slice(0, 500)
        );
        break;

      case 'screenshot': {
        const screenshotPath = `/work/screenshots/${Date.now()}.png`;
        await page.screenshot({ path: screenshotPath, fullPage: false });
        data.screenshot_path = screenshotPath;
        break;
      }

      case 'form_login': {
        const { usernameSelector, passwordSelector, submitSelector,
                username, password } = ACTION_DATA;
        if (!usernameSelector || !passwordSelector || !username || !password) {
          throw new Error('form_login requires usernameSelector, passwordSelector, username, password in action-data');
        }
        await page.fill(usernameSelector, username);
        await page.fill(passwordSelector, password);
        if (submitSelector) {
          await page.click(submitSelector);
        } else {
          await page.keyboard.press('Enter');
        }
        await page.waitForLoadState('domcontentloaded');
        data.url = page.url();
        data.title = await page.title();
        break;
      }

      default:
        throw new Error(`Unknown operation: ${OPERATION}. Valid: goto, click, extract_text, extract_links, screenshot, form_login`);
    }

    respond('success', [], data);
  } catch (err) {
    respond('error', [err.message], data);
  } finally {
    await browser.close();
  }
}

main().catch(err => {
  respond('error', [err.message], {});
  process.exit(1);
});
