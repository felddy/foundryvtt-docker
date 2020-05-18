#!/usr/bin/env node
/* eslint-disable no-console */

const crypto = require("crypto");
const fs = require("fs");

const digest = "sha512";
const iterations = 1000;
const keylen = 64;
const salt = "17c4f39053ac5a50d5797c665ad1f4e6";

var plaintext = fs.readFileSync(process.stdin.fd, "utf-8");
var cyphertext = crypto.pbkdf2Sync(
  plaintext.trim(),
  salt,
  iterations,
  keylen,
  digest
);
process.stdout.write(cyphertext.toString("hex"));
