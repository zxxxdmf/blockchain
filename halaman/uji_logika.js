import { readFileSync } from "node:fs";
import * as ethers from "ethers";
import { hashBerkas, hashNomor, idDariTautan, verifikasi } from "./verifikasi.js";

const rpc = process.argv[2];
const dir = new URL("../jalur_qr/dokumen/", import.meta.url);
const m = JSON.parse(readFileSync(new URL("manifest.json", dir)));
let sesuai = 0, total = 0;
for (const k of m.kasus) {
  const d = m.dokumen[k.berkas];
  const idToken = idDariTautan(`?token=${d.id_token}`);
  for (const masukan of k.masukan) {
    const hash = masukan === "nomor" ? hashNomor(ethers, `  ${d.nomor.toLowerCase()} `)
                                     : hashBerkas(ethers, new Uint8Array(readFileSync(new URL(k.berkas, dir))));
    const r = await verifikasi(ethers, { rpc, kontrak: m.kontrak, idToken, hash });
    const ok = r.kategori === k.diharapkan;
    sesuai += ok; total += 1;
    console.log(`  kasus ${k.no} ${masukan.padEnd(5)}: ${r.kategori.padEnd(13)} diharapkan ${k.diharapkan.padEnd(13)} ${ok ? "SESUAI" : "TIDAK SESUAI"}`);
  }
}
console.log(`${sesuai} dari ${total} pemeriksaan logika halaman sesuai`);
process.exit(sesuai === total ? 0 : 1);
