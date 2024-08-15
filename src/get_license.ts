#!/usr/bin/env node

const doc = `
Retrieve a Foundry Virtual Tabletop license key from a user's account using
cookies from authenticate.js.

The utility will print a license key to standard out.

EXIT STATUS
    This utility exits with one of the following values:
    0   Completed successfully.
    >0  An error occurred.

Usage:
  get_license.js [options] <cookiejar>
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
  --user-agent=USERAGENT If specified, then the user-agent header will be set to
                         the specified value. [default: node-fetch]

`;

// Imports
import { CookieJar } from "tough-cookie";
import { FileCookieStore } from "tough-cookie-file-store";
import * as cheerio from "cheerio";
import createLogger from "./logging.js";
import docopt from "docopt";
import fetchCookie from "fetch-cookie";
import nodeFetch, { Headers } from "node-fetch";
import process from "process";
import winston from "winston";

// Setup globals, to be configured in main()
var cookieJar: CookieJar;
var fetch: typeof nodeFetch;
var logger: winston.Logger;

// Constants
const BASE_URL: string = "https://foundryvtt.com";
const LOCAL_DOMAIN: string = "felddy.com";

const HEADERS: Headers = new Headers({
  DNT: "1",
  Referer: BASE_URL,
  "Upgrade-Insecure-Requests": "1",
  "User-Agent": "node-fetch",
});

/**
 * fetchLicense - Fetch a license key for a user.
 *
 * @param  {string} username Username (not e-mail address) of license owner.
 * @return {string[]}        License keys formatted without dashes.
 */
async function fetchLicenses(username: string): Promise<string[]> {
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

  const licenses: string[] = $("div.license label.copy input")
    .map(function (this: cheerio.Element) {
      const value = $(this).attr("value");
      return value ? value.replace(/-/g, "") : undefined; // remove dashes
    })
    .get()
    .filter(Boolean);
  return licenses;
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
  const cookiejar_filename: string = options["<cookiejar>"];
  const log_level: string = options["--log-level"].toLowerCase();
  const select_mode: string = options["--select"];
  HEADERS.set("User-Agent", options["--user-agent"]);

  // Setup logging.
  logger = createLogger("License", log_level);

  // Setup global cookie jar, storage, and fetch library
  logger.debug(`Reading cookies from: ${cookiejar_filename}`);
  cookieJar = new CookieJar(new FileCookieStore(cookiejar_filename));
  fetch = fetchCookie(nodeFetch, cookieJar);

  // Retrieve username from cookie.
  const local_cookies = cookieJar.getCookiesSync(`http://${LOCAL_DOMAIN}`);
  if (local_cookies.length != 1) {
    logger.error(
      `Wrong number of cookies found for ${LOCAL_DOMAIN}.  Expected 1, found ${local_cookies.length}`,
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
      `Could not find any license keys associated with account ${loggedInUsername}`,
    );
    return -1;
  } else {
    logger.info(
      `Found ${key_count} license ${
        key_count == 1 ? "key" : "keys"
      } associated with account ${loggedInUsername}`,
    );
  }

  // Handle a single license key found.
  if (key_count == 1) {
    logger.debug("Returning single license.");
    process.stdout.write(license_keys[0]);
    return 0;
  }

  // Handle multiple licenses keys found.
  var select_index: number;

  // Use a 1-based index when communicating with the user.
  if (!parseInt(select_mode)) {
    // No numeric index specified, so select a random license key.
    select_index = Math.floor(Math.random() * key_count) + 1;
    logger.info(`License key #${select_index} randomly selected.`);
    process.stdout.write(license_keys[select_index - 1]);
    return 0;
  } else {
    // mode is integer
    select_index = parseInt(select_mode);
    if (select_index > key_count) {
      logger.warn(
        `Invalid license key index ${select_index} selected by user.  Using ${key_count}.`,
      );
      select_index = key_count;
    }
    if (select_index < 1) {
      logger.warn(
        `Invalid license key index ${select_index} selected by user.  Using 1.`,
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
