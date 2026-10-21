import { readFileSync } from "node:fs";
import { keccak256, toUtf8Bytes } from "ethers";
const [jenis, nilai] = process.argv.slice(2);
const bytes = jenis === "berkas" ? new Uint8Array(readFileSync(nilai)) : toUtf8Bytes(nilai);
console.log(keccak256(bytes));
