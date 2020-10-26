#!/usr/bin/env node

let parsedTURNConfigs = undefined;

if (process.env.FOUNDRY_TURN_CONFIGS) {
  parsedTURNConfigs = JSON.parse(process.env.FOUNDRY_TURN_CONFIGS);
}

let options = {
  awsConfig: process.env.FOUNDRY_AWS_CONFIG || null,
  dataPath: "/data",
  fullscreen: false,
  hostname: process.env.FOUNDRY_HOSTNAME || null,
  language: process.env.FOUNDRY_LANGUAGE || "en.core",
  minifyStaticFiles: process.env.FOUNDRY_MINIFY_STATIC_FILES == "true",
  port: 30000,
  proxyPort: parseInt(process.env.FOUNDRY_PROXY_PORT) || null,
  proxySSL: process.env.FOUNDRY_PROXY_SSL == "true",
  routePrefix: process.env.FOUNDRY_ROUTE_PREFIX || null,
  sslCert: process.env.FOUNDRY_SSL_CERT || null,
  sslKey: process.env.FOUNDRY_SSL_KEY || null,
  turnConfigs: parsedTURNConfigs,
  updateChannel: "release",
  upnp: process.env.FOUNDRY_UPNP == "true",
  world: process.env.FOUNDRY_WORLD || null,
};

process.stdout.write(JSON.stringify(options, null, "  "));
