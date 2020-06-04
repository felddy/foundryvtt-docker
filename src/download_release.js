#!/usr/bin/env node

const doc = `
Download a Foundry Virtual Tabletop release and license key using valid credentials.
This utility will attempt to create two files:

    foundryvtt-x.y.z.zip - An archive containing the release.
    license.json - A json file containing the license key.

EXIT STATUS
    This utility exits with one of the following values:
    0   Download completed successfully.
    >0  An error occurred.

Usage:
  download_release.js [--log-level=LEVEL] <username> <password> <version>
  download_release.js (-h | --help)

Options:
  -h --help              Show this message.
  --log-level=LEVEL      If specified, then the log level will be set to
                         the specified value.  Valid values are "trace", "debug", "info",
                         "warn", "error", and "fatal". [default: info]
`;

// Argument parsing
const { docopt } = require("docopt");
const options = docopt(doc, { version: "0.0.1" });

// Imports
const _nodeFetch = require("node-fetch");
const _tough = require("tough-cookie");
const _util = require("util");
const cheerio = require("cheerio");
const cookieJar = new _tough.CookieJar();
const fetch = require("fetch-cookie/node-fetch")(_nodeFetch, cookieJar);
const fs = require("fs");
const pino = require("pino");
const streamPipeline = _util.promisify(require("stream").pipeline);

// Setup logger global, configure in main()
let logger = null;

// Constants
const BASE_URL = "https://foundryvtt.com";
const LOGIN_URL = BASE_URL + "/auth/login/";

const HEADERS = {
  DNT: "1",
  Referer: BASE_URL,
  "Upgrade-Insecure-Requests": "1",
  "User-Agent": "Mozilla/5.0",
};

/**
 * fetchTokens - Fetch the CSRF form and cookie tokens.
 *
 * @return {type}  CSRF middleware token extracted from the login form.
 */
async function fetchTokens() {
  // Make a request to the main site to get our two CSRF tokens
  logger.info(`Requesting CSRF tokens from ${BASE_URL}`);
  const response = await fetch(BASE_URL, {
    method: "GET",
    headers: HEADERS,
  });
  if (!response.ok) {
    throw new Error(`Unexpected response ${response.statusText}`);
  }
  const body = await response.text();
  const $ = await cheerio.load(body);

  const csrfmiddlewaretoken = $('input[name ="csrfmiddlewaretoken"]').val();
  if (typeof csrfmiddlewaretoken == "undefined") {
    logger.fatal("Could not find the CSRF middleware token.");
    throw new Error("Could not find the CSRF middleware token.");
  }
  return csrfmiddlewaretoken;
}

/**
 * login - description
 *
 * @param  {string} csrfmiddlewaretoken CSRF middleware token extracted from form.
 * @param  {string} username            Username or e-mail address of user.
 * @param  {string} password            Password associated with the username.
 * @return {string}                     The actual username of the account.
 */
async function login(csrfmiddlewaretoken, username, password) {
  const form_params = new URLSearchParams({
    csrfmiddlewaretoken: csrfmiddlewaretoken,
    login_password: password,
    login_redirect: "/",
    login_username: username,
    login: "",
  });

  logger.info(`Logging in as: ${username}`);
  response = await fetch(LOGIN_URL, {
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
  if (typeof session_cookie == "undefined") {
    logger.fatal(`Unable to log in as ${username}, verify your credentials...`);
    throw new Error(
      `Unable to log in as ${username}, verify your credentials...`
    );
  }

  // A user may login with an e-mail address.  Resolve it to a username now.
  const loggedInUsername = $("#login-welcome a").attr("title");
  logger.info(`Successfully logged in as: ${loggedInUsername}`);
  return loggedInUsername;
}

/**
 * fetchLicense - Fetch a license key for a user.
 *
 * @param  {string} username Username (not e-mail address) of license owner.
 * @return {string}          License key formatted with dashes.
 */
async function fetchLicense(username) {
  logger.info("Fetching license.");
  const LICENSE_URL = `${BASE_URL}/community/${username}/licenses`;
  response = await fetch(LICENSE_URL, {
    method: "GET",
    headers: HEADERS,
  });
  if (!response.ok) {
    throw new Error(`Unexpected response ${response.statusText}`);
  }
  body = await response.text();
  $ = await cheerio.load(body);

  const license_with_dashes = $("pre.license-key code").text();
  return license_with_dashes;
}

/**
 * saveLicense - Write a license to a json file.
 *
 * @param  {string} license  License key.
 * @param  {string} filename Filesystem path to write.
 * @return {undefined}
 */
async function saveLicense(license, filename) {
  // remove dashes from license
  const license_no_dashes = license.replace(/-/g, "");
  logger.info(`Writing license to: ${filename}`);
  await fs.writeFile(
    filename,
    JSON.stringify({ license: license_no_dashes }, null, 2),
    function (err) {
      if (err) {
        logger.warn(`License could not be saved: ${err}`);
      } else {
        logger.info("License successfully saved.");
      }
    }
  );
}

/**
 * downloadRelease - Download a FoundryVTT release and save it to a file.
 *
 * @param  {string} version Semantic version to download.
 * @param  {string} path    Filesystem path to write.
 * @return {undefined}
 */
async function downloadRelease(version, path) {
  logger.info(`Downloading release ${version} to ${path}...`);
  const release_url = `${BASE_URL}/releases/download?version=${version}&platform=linux`;
  response = await fetch(release_url, {
    method: "GET",
    headers: HEADERS,
  });
  if (!response.ok) {
    throw new Error(`Unexpected response ${response.statusText}`);
  }
  await streamPipeline(response.body, fs.createWriteStream(path));
  logger.info(`Release download complete.`);
}

/**
 * main - Parse command line args, setup logging, do work.
 *
 * @return {number}  exit code
 */
async function main() {
  // Extract values from CLI options.
  const username = options["<username>"].toLowerCase();
  const password = options["<password>"];
  const foundry_version = options["<version>"];
  const log_level = options["--log-level"].toLowerCase();

  // Setup logging.
  logger = pino({
    level: log_level,
    prettyPrint: {
      translateTime: true,
      ignore: "pid,hostname",
    },
  });

  // Get the tokens and cookies we'll need to login.
  const csrfmiddlewaretoken = await fetchTokens();

  // Login using the credentials, tokens, and cookies.
  const loggedInUsername = await login(csrfmiddlewaretoken, username, password);

  // Attempt to fetch a license key.
  const license = await fetchLicense(loggedInUsername);
  if (license) {
    await saveLicense(license, "license.json");
  } else {
    logger.warn("Could not find license.");
  }

  // Download the FoundryVTT release.
  await downloadRelease(foundry_version, `foundryvtt-${foundry_version}.zip`);

  return 0;
}

return main();
