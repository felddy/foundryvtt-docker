#!/usr/bin/env node

"use strict";

const doc = `
Retrieve a Foundrty Virtual Tabletop license key from a user's account using
cookies from authenticate.js.

The utility will print a license key to standard out.

EXIT STATUS
    This utility exits with one of the following values:
    0   Completed successfully.
    >0  An error occurred.

Usage:
  get_license.js [--log-level=LEVEL] [--select=MODE] <cookiejar>
  get_license.js (-h | --help)

Options:
  -h --help              Show this message.
  --log-level=LEVEL      If specified, then the log level will be set to
                         the specified value.  Valid values are "debug", "info",
                         "warn", and "error". [default: info]
  --select=INDEX         If more than one license key is associated with an
                         account return the one specified by index.  In
                         unspecified, a random license will be returned.  Index
                         starts at 1.
`;

// Argument parsing
const { docopt } = require("docopt");
const options = docopt(doc, { version: "1.0.0" });

// Imports
const _nodeFetch = require("node-fetch");
const { CookieJar } = require("tough-cookie");
const cheerio = require("cheerio");
const CookieFileStore = require("tough-cookie-file-store").FileCookieStore;
const createLogger = require("./logging").createLogger;
const process = require("process");

// Setup globals, to be configured in main()
var cookieJar;
var fetch;
var logger;

// Constants
const BASE_URL = "https://foundryvtt.com";
const LOCAL_DOMAIN = "felddy.com";

const HEADERS = {
  DNT: "1",
  Referer: BASE_URL,
  "Upgrade-Insecure-Requests": "1",
  "User-Agent": "Mozilla/5.0",
};

/**
 * fetchLicense - Fetch a license key for a user.
 *
 * @param  {string} username Username (not e-mail address) of license owner.
 * @return {string}          License key formatted with dashes.
 */
async function fetchLicenses(username) {
  logger.info("Fetching licenses.");
  const LICENSE_URL = `${BASE_URL}/community/${username}/licenses`;
  logger.debug(`Fetching: ${LICENSE_URL}`);
  const response = await fetch(LICENSE_URL, {
    method: "GET",
    headers: HEADERS,
  });
  if (!response.ok) {
    throw new Error(`Unexpected response ${response.statusText}`);
  }
  const body = await response.text();
  const $ = await cheerio.load(body);

  const licenses = $("pre.license-key code")
    .map(function () {
      return $(this).text().replace(/-/g, ""); // remove dashes
    })
    .toArray();
  return licenses;
}

/**
 * main - Parse command line args, setup logging, do work.
 *
 * @return {number}  exit code
 */
async function main() {
  // Extract values from CLI options.
  const cookiejar_filename = options["<cookiejar>"];
  const log_level = options["--log-level"].toLowerCase();
  const select_mode = options["--select"];

  // Setup logging.
  logger = createLogger("License", log_level);

  // Setup global cookie jar, storage, and fetch library
  logger.debug(`Reading cookies from: ${cookiejar_filename}`);
  cookieJar = new CookieJar(new CookieFileStore(cookiejar_filename));
  fetch = require("fetch-cookie/node-fetch")(_nodeFetch, cookieJar);

  // Retrieve username from cookie.
  const local_cookies = cookieJar.getCookiesSync(`http://${LOCAL_DOMAIN}`);
  if (local_cookies.length != 1) {
    logger.fatal(
      `Wrong number of cookies found for ${LOCAL_DOMAIN}.  Expected 1, found ${local_cookies.length}`
    );
    return -1;
  }
  const loggedInUsername = local_cookies[0].value;

  // Attempt to fetch a license key.
  const license_keys = await fetchLicenses(loggedInUsername);
  const key_count = license_keys.length;

  // Handle no license keys found.
  if (key_count == 0) {
    logger.error(
      `Could not find any license keys associated with account ${loggedInUsername}`
    );
    return -1;
  } else {
    logger.info(
      `Found ${key_count} license ${
        key_count == 1 ? "key" : "keys"
      } associated with account ${loggedInUsername}`
    );
  }

  // Handle a single license key found.
  if (key_count == 1) {
    logger.debug("Returning single license.");
    process.stdout.write(license_keys[0]);
    return 0;
  }

  // Handle multiple licenses keys found.
  var select_index;

  // Use a 1-based index when communicating with the user.
  if (!select_mode) {
    select_index = Math.floor(Math.random() * key_count) + 1;
    logger.info(`License key #${select_index} randomly selected.`);
    process.stdout.write(license_keys[select_index - 1]);
    return 0;
  } else if (select_mode == parseInt(select_mode)) {
    // mode is integer
    select_index = parseInt(select_mode);
    if (select_index > key_count) {
      logger.warn(
        `Invalid license key index ${select_index} selected by user.  Using ${key_count}.`
      );
      select_index = key_count;
    }
    if (select_index < 1) {
      logger.warn(
        `Invalid license key index ${select_index} selected by user.  Using 1.`
      );
      select_index = 1;
    }
    logger.info(`License key #${select_index} selected by user.`);
    process.stdout.write(license_keys[select_index - 1]);
    return 0;
  }
}

(async () => {
  process.exitCode = await main();
})();
