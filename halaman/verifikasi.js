export const ABI = ["function verifikasi(uint256 id, bytes32 hashDiperiksa) view returns (uint8)"];

export const KATEGORI = ["palsu", "palsu", "tidak berlaku", "asli"];

export function seragamkanNomor(nomor) {
  return nomor.trim().toUpperCase();
}

export function hashNomor(ethers, nomor) {
  return ethers.keccak256(ethers.toUtf8Bytes(seragamkanNomor(nomor)));
}

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
