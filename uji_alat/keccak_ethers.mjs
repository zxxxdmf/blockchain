// UJI ALAT: keccak256 berkas atau teks dengan ethers.js 6.17.0 (sama dengan yang dipakai halaman verifikasi).
// Pemakaian: node keccak_ethers.mjs berkas <path> | node keccak_ethers.mjs teks <string>
import { readFileSync } from "node:fs";
import { keccak256, toUtf8Bytes } from "ethers";
const [jenis, nilai] = process.argv.slice(2);
const bytes = jenis === "berkas" ? new Uint8Array(readFileSync(nilai)) : toUtf8Bytes(nilai);
console.log(keccak256(bytes));
