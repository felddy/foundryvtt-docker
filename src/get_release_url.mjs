#!/usr/bin/env node

const doc = `
Generate a Foundry Virtual Tabletop pre-signed release URL using cookies from
authenticate.mjs.

The utility will print the release URL to standard out.

EXIT STATUS
    This utility exits with one of the following values:
    0   Completed successfully.
    >0  An error occurred.

Usage:
  get_release_url.mjs [--log-level=LEVEL] <cookiejar> <version>
  get_release_url.mjs (-h | --help)

Options:
  -h --help              Show this message.
  --log-level=LEVEL      If specified, then the log level will be set to
                         the specified value.  Valid values are "debug", "info",
                         "warn", and "error". [default: info]
`;

// Imports
import { CookieJar } from "tough-cookie";
import { FileCookieStore } from "tough-cookie-file-store";
import createLogger from "./logging.mjs";
import docopt from "docopt";
import fetchCookie from "fetch-cookie/node-fetch.js";
import nodeFetch from "node-fetch";
import process from "process";

// Setup globals, to be configured in main()
var cookieJar;
var fetch;
var logger;

// Constants
const BASE_URL = "https://foundryvtt.com";

const HEADERS = {
  DNT: "1",
  Referer: BASE_URL,
  "Upgrade-Insecure-Requests": "1",
  "User-Agent": "Mozilla/5.0",
};

/**
 * fetchReleaseURL - Fetch the pre-signed S3 URL.
 *
 * @param  {string} build Build to download.
 * @return {string} The URL of the requested build.
 */
async function fetchReleaseURL(build) {
  logger.info(`Fetching S3 pre-signed release URL for build ${build}...`);
  const release_url = `${BASE_URL}/releases/download?build=${build}&platform=linux`;
  logger.debug(`Fetching: ${release_url}`);
  const response = await fetch(release_url, {
    method: "GET",
    headers: HEADERS,
    redirect: "manual",
  });
  // Expect a redirect status
  if (!(response.status >= 300 && response.status < 400)) {
    throw new Error(`Unexpected response ${response.statusText}`);
  }
  const s3_url = response.headers.get("location");
  logger.debug(`S3 presigned URL: ${s3_url}`);

  return s3_url;
}

/**
 * main - Parse command line args, setup logging, do work.
 *
 * @return {number}  exit code
 */
async function main() {
  // Parse command line options.
  const options = docopt.docopt(doc, { version: "2.0.0" });

  // Extract values from CLI options.
  const cookiejar_filename = options["<cookiejar>"];
  const foundry_version = options["<version>"];
  const log_level = options["--log-level"].toLowerCase();

  // Setup logging.
  logger = createLogger("ReleaseURL", log_level);

  // Setup global cookie jar, storage, and fetch library
  logger.debug(`Loading cookies from: ${cookiejar_filename}`);
  cookieJar = new CookieJar(new FileCookieStore(cookiejar_filename));
  fetch = fetchCookie(nodeFetch, cookieJar);

  // Extract build number from FoundryVTT version
  // FoundryVTT versions looks like x.yyy where y is a build
  const foundry_build = foundry_version.split(".").pop();

  // Generate an S3 pre-signed URL and print it to stdout.
  const releaseURL = await fetchReleaseURL(foundry_build);

  if (releaseURL) {
    process.stdout.write(releaseURL);
    return 0;
  } else {
    logger.error("Could not fetch a release URL.");
    return -1;
  }
}

(async () => {
  process.exitCode = await main();
})();
