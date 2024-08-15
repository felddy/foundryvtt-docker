#!/usr/bin/env node

const doc = `
Log into Foundry Virtual Tabletop website, and save cookies to file.

EXIT STATUS
    This utility exits with one of the following values:
    0   Login completed successfully.
    >0  An error occurred.

Usage:
  authenticate.js [options] <username> <password> <cookiejar>
  authenticate.js (-h | --help)

Options:
  -h --help              Show this message.
  --log-level=LEVEL      If specified, then the log level will be set to
                         the specified value.  Valid values are "debug", "info",
                         "warn", and "error". [default: info]
  --user-agent=USERAGENT If specified, then the user-agent header will be set to
                         the specified value. [default: node-fetch]
`;

// Imports
import { CookieJar, Cookie } from "tough-cookie";
import { FileCookieStore } from "tough-cookie-file-store";
import * as cheerio from "cheerio";
import createLogger from "./logging.js";
import winston from "winston";
import docopt from "docopt";
import fetchCookie from "fetch-cookie";
import nodeFetch, { Headers } from "node-fetch";
import process from "process";

// Setup globals, to be configured in main()
var cookieJar: CookieJar;
var fetch: typeof nodeFetch;
var logger: winston.Logger;

// Constants
const BASE_URL = "https://foundryvtt.com";
const LOCAL_DOMAIN = "felddy.com";
const LOGIN_URL = BASE_URL + "/auth/login/";
const USERNAME_RE = /\/community\/(?<username>.+)/;

const HEADERS: Headers = new Headers({
  DNT: "1",
  Referer: BASE_URL,
  "Upgrade-Insecure-Requests": "1",
  "User-Agent": "node-fetch",
});

/**
 * fetchTokens - Fetch the CSRF form and cookie tokens.
 *
 * @return {string}  CSRF middleware token extracted from the login form.
 */
async function fetchTokens() {
  // Make a request to the main site to get our two CSRF tokens
  logger.info(`Requesting CSRF tokens from ${BASE_URL}`);
  logger.debug(`Fetching: ${BASE_URL}`);
  const response = await fetch(BASE_URL, {
    method: "GET",
    headers: HEADERS,
  });
  if (!response.ok) {
    throw new Error(`Unexpected response ${response.statusText}`);
  }
  const body = await response.text();
  const $ = await cheerio.load(body);

  const csrfmiddlewaretoken: string | string[] | undefined = $(
    'input[name ="csrfmiddlewaretoken"]',
  ).val();
  if (typeof csrfmiddlewaretoken == "undefined") {
    logger.error("Could not find the CSRF middleware token.");
    throw new Error("Could not find the CSRF middleware token.");
  }
  return csrfmiddlewaretoken;
}

/**
 * login - Login to site, and get a session cookie, and actual username.
 *
 * @param  {string} csrfmiddlewaretoken CSRF middleware token extracted from form.
 * @param  {string} username            Username or e-mail address of user.
 * @param  {string} password            Password associated with the username.
 * @return {string}                     The actual username of the account.
 */
async function login(
  csrfmiddlewaretoken: string,
  username: string,
  password: string,
) {
  const form_params = new URLSearchParams({
    csrfmiddlewaretoken: csrfmiddlewaretoken,
    next: "/",
    password: password,
    username: username,
  });

  logger.info(`Logging in as: ${username}`);
  logger.debug(`Fetching: ${LOGIN_URL}`);
  const response = await fetch(LOGIN_URL, {
    body: form_params,
    method: "POST",
    headers: HEADERS,
  });
  if (!response.ok) {
    throw new Error(`Unexpected response ${response.statusText}`);
  }
  const body = await response.text();
  const $ = await cheerio.load(body);

  // Check to see if we have a sessionid (logged in)
  const cookies = cookieJar.getCookiesSync(BASE_URL);
  const session_cookie = cookies.find((cookie) => {
    return cookie.key == "sessionid";
  });
  if (!session_cookie) {
    logger.error(`Unable to log in as ${username}, verify your credentials...`);
    throw new Error(
      `Unable to log in as ${username}, verify your credentials...`,
    );
  }

  // A user may login with an e-mail address.  Resolve it to a username now.
  const communityURL: string | undefined = $("#login-welcome a").attr("href");
  logger.debug(`Community URL: ${communityURL}`);
  if (!communityURL) {
    logger.error("Could not find the community URL.");
    throw new Error("Could not find the community URL.");
  }
  const match = communityURL.match(USERNAME_RE);
  if (!match?.groups?.username) {
    logger.error(`Unable to resolve username from ${communityURL}`);
    throw new Error(`Unable to resolve username from ${communityURL}`);
  }
  const loggedInUsername = match.groups.username;
  logger.info(`Successfully logged in as: ${loggedInUsername}`);

  // The site preserves case, but this will break our use in the LICENSE_URL
  return loggedInUsername.toLowerCase();
}

/**
 * main - Parse command line args, setup logging, do work.
 *
 * @return {number}  exit code
 */
async function main(): Promise<number> {
  // Parse command line options.
  const options = docopt.docopt(doc, { version: "1.0.0" });

  // Extract values from CLI options.
  const cookiejar_filename = options["<cookiejar>"];
  const log_level = options["--log-level"].toLowerCase();
  HEADERS.set("User-Agent", options["--user-agent"]);
  const password = options["<password>"];
  const username = options["<username>"].toLowerCase();

  // Setup logging.
  logger = createLogger("Authenticate", log_level);

  // Setup global cookie jar, storage, and fetch library
  logger.debug(`Saving cookies to: ${cookiejar_filename}`);
  cookieJar = new CookieJar(new FileCookieStore(cookiejar_filename));
  fetch = fetchCookie(nodeFetch, cookieJar);

  try {
    // Get the tokens and cookies we'll need to login.
    const csrfmiddlewaretoken = await fetchTokens();

    // Login using the credentials, tokens, and cookies.
    const loggedInUsername = await login(
      csrfmiddlewaretoken,
      username,
      password,
    );

    // Store the username in a cookie for use by other utilities
    const username_cookie = Cookie.parse(
      `username=${loggedInUsername}; Domain=${LOCAL_DOMAIN}; Path=/`,
    );
    cookieJar.setCookieSync(
      username_cookie!.toString(),
      `http://${LOCAL_DOMAIN}`,
    );
  } catch (err: any) {
    logger.error(`Unable to authenticate: ${err.message}`);
    return -1;
  }
  return 0;
}

(async () => {
  process.exitCode = await main();
})();
