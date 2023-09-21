#!/usr/bin/env node

const DATA_PATH: string = "/data";
const FOUNDRY_PORT: number = 30000;
const LANGUAGE: string = "en.core";
const MAXIMUM_PORT: number = 65535;
const MINIMUM_PORT: number = 1;
const UPDATE_CHANNEL: string = "release";

let parsedDemoConfig: any = undefined;

/**
 * Returns a number from an environment variable whose value is limited to the
 * given range.
 *
 * @param {string | undefined} envVarValue The value of the environment variable
 * @param {number} min The lower boundary of the output range
 * @param {number} max The upper boundary of the output range
 * @param {number | null} unset The default value to return if the environment variable is not set
 * @return {number | null} clamped value, or undefined
 */
function clampEnv(
  envVarValue: string | undefined,
  min: number,
  max: number,
  unset: number | null = null,
): number | null {
  if (envVarValue) {
    var i = parseInt(envVarValue);
    return Math.min(Math.max(i, min), max);
  } else {
    return unset;
  }
}

if (process.env.FOUNDRY_DEMO_CONFIG) {
  parsedDemoConfig = JSON.parse(process.env.FOUNDRY_DEMO_CONFIG);
}

let options: object = {
  awsConfig: process.env.FOUNDRY_AWS_CONFIG || null,
  compressSocket: process.env.FOUNDRY_COMPRESS_WEBSOCKET == "true",
  compressStatic: process.env.FOUNDRY_MINIFY_STATIC_FILES == "true",
  cssTheme: process.env.FOUNDRY_CSS_THEME || "foundry",
  dataPath: DATA_PATH,
  demo: parsedDemoConfig,
  fullscreen: false,
  hostname: process.env.FOUNDRY_HOSTNAME || null,
  hotReload: process.env.FOUNDRY_HOT_RELOAD == "true",
  language: process.env.FOUNDRY_LANGUAGE || LANGUAGE,
  localHostname: process.env.FOUNDRY_LOCAL_HOSTNAME || null,
  passwordSalt: process.env.FOUNDRY_PASSWORD_SALT || null,
  port: FOUNDRY_PORT,
  protocol: process.env.FOUNDRY_PROTOCOL || null,
  proxyPort: clampEnv(
    process.env.FOUNDRY_PROXY_PORT,
    MINIMUM_PORT,
    MAXIMUM_PORT,
    null,
  ),
  proxySSL: process.env.FOUNDRY_PROXY_SSL == "true",
  routePrefix: process.env.FOUNDRY_ROUTE_PREFIX || null,
  sslCert: process.env.FOUNDRY_SSL_CERT || null,
  sslKey: process.env.FOUNDRY_SSL_KEY || null,
  telemetry: process.env.FOUNDRY_TELEMETRY || null,
  updateChannel: UPDATE_CHANNEL,
  upnp: process.env.FOUNDRY_UPNP == "true",
  upnpLeaseDuration: process.env.FOUNDRY_UPNP_LEASE_DURATION || null,
  world: process.env.FOUNDRY_WORLD || null,
};

process.stdout.write(JSON.stringify(options, null, "  "));
