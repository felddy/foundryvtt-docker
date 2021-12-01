#!/usr/bin/env node

import crypto from "crypto";
import fs from "fs";

const digest = "sha512";
const iterations = 1000;
const keylen = 64;
const low_sodium = "17c4f39053ac5a50d5797c665ad1f4e6";
const custom_salt = process.env.FOUNDRY_PASSWORD_SALT || null;

var plaintext = fs.readFileSync(process.stdin.fd, "utf-8");
var cyphertext = crypto.pbkdf2Sync(
  plaintext.trim(),
  custom_salt || low_sodium,
  iterations,
  keylen,
  digest
);
process.stdout.write(cyphertext.toString("hex"));
