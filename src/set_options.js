#!/usr/bin/env node

const DATA_PATH = "/data";
const FOUNDRY_PORT = 30000;
const LANGUAGE = "en.core";
const MAXIMUM_PORT = 65535;
const MINIMUM_PORT = 1;
const MINIMUM_TURN_MAX_PORT = 42153;
const UPDATE_CHANNEL = "release";

let parsedTURNConfigs = undefined;

/**
 * Returns a number from an environment variable whose value is limited to the
 * given range.
 *
 * @param {string} envVar The value of the environment variable
 * @param {number} min The lower boundary of the output range
 * @param {number} max The upper boundary of the output range
 * @return {number} clamped value, or undefined
 */
function clampEnv(envVar, min, max, unset = undefined) {
  if (envVar) {
    i = parseInt(envVar);
    return Math.min(Math.max(i, min), max);
  } else {
    return unset;
  }
}

if (process.env.FOUNDRY_TURN_CONFIGS) {
  parsedTURNConfigs = JSON.parse(process.env.FOUNDRY_TURN_CONFIGS);
}

let options = {
  awsConfig: process.env.FOUNDRY_AWS_CONFIG || null,
  dataPath: DATA_PATH,
  fullscreen: false,
  hostname: process.env.FOUNDRY_HOSTNAME || null,
  language: process.env.FOUNDRY_LANGUAGE || LANGUAGE,
  minifyStaticFiles: process.env.FOUNDRY_MINIFY_STATIC_FILES == "true",
  port: FOUNDRY_PORT,
  proxyPort: clampEnv(
    process.env.FOUNDRY_PROXY_PORT,
    MINIMUM_PORT,
    MAXIMUM_PORT,
    null
  ),
  proxySSL: process.env.FOUNDRY_PROXY_SSL == "true",
  routePrefix: process.env.FOUNDRY_ROUTE_PREFIX || null,
  sslCert: process.env.FOUNDRY_SSL_CERT || null,
  sslKey: process.env.FOUNDRY_SSL_KEY || null,
  turnConfigs: parsedTURNConfigs,
  turnMaxPort: clampEnv(
    process.env.FOUNDRY_TURN_MAX_PORT,
    MINIMUM_TURN_MAX_PORT,
    MAXIMUM_PORT
  ),
  updateChannel: UPDATE_CHANNEL,
  upnp: process.env.FOUNDRY_UPNP == "true",
  world: process.env.FOUNDRY_WORLD || null,
};

process.stdout.write(JSON.stringify(options, null, "  "));
