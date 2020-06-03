#!/usr/bin/env node
/* eslint-disable no-console */

const doc = `
Download the foundry release using valid credentials.

EXIT STATUS
    This utility exits with one of the following values:
    0   Download completed successfully.
    >0  An error occurred.

Usage:
  download_release.js <username> <password> <version>
  download_release.js (-h | --help)

Options:
  -h --help              Show this message.
`;

// Argument parsing
const { docopt } = require("docopt");
const options = docopt(doc, { version: "0.0.1" });
const username = options["<username>"];
const password = options["<password>"];
const foundry_version = options["<version>"];

// Imports
const _nodeFetch = require("node-fetch");
const _tough = require("tough-cookie");
const _util = require("util");
const cheerio = require("cheerio");
const cookieJar = new _tough.CookieJar();
const fetch = require("fetch-cookie/node-fetch")(_nodeFetch, cookieJar);
const fs = require("fs");
const streamPipeline = _util.promisify(require("stream").pipeline);

// Constants
const BASE_URL = "https://foundryvtt.com";
const LICENSE_PATH = "license.json";
const LICENSE_URL = `${BASE_URL}/community/${username}/licenses`;
const LOGIN_URL = BASE_URL + "/auth/login/";
const PRIVACY_POLICY_COOKIE =
  "privacy-policy-accepted=accepted; path=/; domain=foundryvtt.com";
const RELEASE_PATH = `foundryvtt-${foundry_version}.zip`;
const RELEASE_URL = `${BASE_URL}/releases/download?version=${foundry_version}&platform=linux`;

const HEADERS = {
  DNT: "1",
  Referer: BASE_URL,
  "Upgrade-Insecure-Requests": "1",
  "User-Agent": "Mozilla/5.0",
};

(async () => {
  // Setup cookieJar
  await cookieJar.setCookie(PRIVACY_POLICY_COOKIE, BASE_URL);

  // Make a request to the main site to get our two CSRF tokens
  console.log("Requesting FoundryVTT homepage.");
  var response = await fetch(BASE_URL, {
    method: "GET",
    headers: HEADERS,
  });
  if (!response.ok) {
    throw new Error(`Unexpected response ${response.statusText}`);
  }
  var body = await response.text();
  var $ = await cheerio.load(body);

  console.log("Extracting input token.");
  const csrfmiddlewaretoken = $('input[name ="csrfmiddlewaretoken"]').val();
  if (typeof csrfmiddlewaretoken == "undefined") {
    console.error("Could not find the CSRF middleware token.");
    return -1;
  }

  var form_params = new URLSearchParams({
    csrfmiddlewaretoken: csrfmiddlewaretoken,
    login_password: options["<password>"],
    login_redirect: "/",
    login_username: options["<username>"],
    login: "",
  });

  console.log(`Logging in to Foundry website as ${options["<username>"]}.`);
  response = await fetch(LOGIN_URL, {
    body: form_params,
    method: "POST",
    headers: HEADERS,
  });
  if (!response.ok) {
    throw new Error(`Unexpected response ${response.statusText}`);
  }

  // Check to see if we have a sessionid (logged in)
  cookies = cookieJar.getCookiesSync(BASE_URL);
  session_cookie = cookies.find((cookie) => {
    return cookie.key == "sessionid";
  });
  if (typeof session_cookie == "undefined") {
    console.error(
      `Unable to log in as ${options["<username>"]}, verify your credentials..`
    );
    return -1;
  }
  console.log(`Successfully logged in as ${options["<username>"]}.`);

  console.log("Fetching license.");
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
  if (license_with_dashes) {
    // remove the dashes
    const license_no_dashes = license_with_dashes.replace(/-/g, "");
    console.log(`Writing license to ${LICENSE_PATH}`);
    fs.writeFile(
      LICENSE_PATH,
      JSON.stringify({ license: license_no_dashes }, null, 2),
      function (err) {
        if (err) {
          console.warn(`License could not be saved: ${err}`);
        }
        console.log("License successfully saved.");
      }
    );
  } else {
    console.warn("Could not find license.");
  }

  console.log(`Downloading release ${foundry_version} to ${RELEASE_PATH}`);
  response = await fetch(RELEASE_URL, {
    method: "GET",
    headers: HEADERS,
  });

  if (!response.ok) {
    throw new Error(`Unexpected response ${response.statusText}`);
  }
  streamPipeline(response.body, fs.createWriteStream(RELEASE_PATH));
})();
