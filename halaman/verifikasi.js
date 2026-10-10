// Logika halaman verifikasi (subbab 2.1). Dipakai bersama oleh index.html (peramban) dan uji_logika.js (Node),
// sehingga yang diuji otomatis sama dengan yang dijalankan di ponsel. Halaman tidak memuat aturan verifikasi:
// hasil ditentukan fungsi verifikasi kontrak acuan; halaman hanya menghitung hash dan menerjemahkan hasilnya.

export const ABI = ["function verifikasi(uint256 id, bytes32 hashDiperiksa) view returns (uint8)"];

// Urutan enum Hasil di kontrak: TidakTerdaftar, TidakCocok, Dicabut, Aktif
export const KATEGORI = ["palsu", "palsu", "tidak berlaku", "asli"];

/** Penyeragaman nomor ijazah, sama dengan skrip penerbitan: hapus spasi tepi, huruf kapital. */
export function seragamkanNomor(nomor) {
  return nomor.trim().toUpperCase();
}

export function hashNomor(ethers, nomor) {
  return ethers.keccak256(ethers.toUtf8Bytes(seragamkanNomor(nomor)));
}

/** @param {Uint8Array} isi seluruh isi berkas PDF apa adanya */
export function hashBerkas(ethers, isi) {
  return ethers.keccak256(isi);
}

export function idDariTautan(search) {
  const id = new URLSearchParams(search).get("token");
  return id !== null && /^\d+$/.test(id) ? id : null;
}

export async function verifikasi(ethers, { rpc, kontrak, idToken, hash }) {
  const penyedia = new ethers.JsonRpcProvider(rpc);
  const k = new ethers.Contract(kontrak, ABI, penyedia);
  const kode = Number(await k.verifikasi(BigInt(idToken), hash));
  return { kode, kategori: KATEGORI[kode] };
}
