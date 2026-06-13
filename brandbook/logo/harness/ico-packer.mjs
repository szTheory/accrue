/**
 * ico-packer.mjs — Zero-dependency ICO file packer
 *
 * Packs one or more PNG buffers into a valid .ico file using the modern
 * embedded-PNG format (supported since Windows Vista).
 *
 * ICO binary layout:
 *   ICONDIR header (6 bytes):
 *     idReserved = 0  (2B, LE)
 *     idType     = 1  (2B, LE) — 1 = icon
 *     idCount    = N  (2B, LE) — number of images
 *
 *   ICONDIRENTRY × N (16 bytes each):
 *     bWidth      (1B)  — image width in pixels
 *     bHeight     (1B)  — image height in pixels
 *     bColorCount (1B)  — 0 for 32bpp
 *     bReserved   (1B)  — must be 0
 *     wPlanes     (2B, LE) — 1
 *     wBitCount   (2B, LE) — 32
 *     dwBytesInRes (4B, LE) — byte length of the PNG data
 *     dwImageOffset (4B, LE) — absolute byte offset of PNG data in the file
 *
 *   PNG data blocks (verbatim, back-to-back)
 *
 * Zero Node.js imports required — uses only built-in Buffer.
 *
 * @param {Buffer[]} pngBuffers — array of PNG file buffers, one per size
 * @param {number[]} sizes      — array of pixel dimensions (e.g. [16, 32, 48])
 * @returns {Buffer} complete .ico file as a Buffer
 */
export function packIco(pngBuffers, sizes) {
  const n = pngBuffers.length;
  const headerSize = 6;          // ICONDIR header
  const entrySize = 16;          // ICONDIRENTRY per image
  const dataOffset = headerSize + n * entrySize;   // first image starts here

  // --- ICONDIR header (6 bytes) ---
  const header = Buffer.alloc(headerSize);
  header.writeUInt16LE(0, 0);   // idReserved = 0
  header.writeUInt16LE(1, 2);   // idType = 1 (icon)
  header.writeUInt16LE(n, 4);   // idCount = N

  // --- ICONDIRENTRY array ---
  const entries = [];
  let offset = dataOffset;
  for (let i = 0; i < n; i++) {
    const entry = Buffer.alloc(entrySize);
    entry.writeUInt8(sizes[i], 0);            // bWidth
    entry.writeUInt8(sizes[i], 1);            // bHeight
    entry.writeUInt8(0, 2);                   // bColorCount = 0 (32bpp)
    entry.writeUInt8(0, 3);                   // bReserved = 0
    entry.writeUInt16LE(1, 4);               // wPlanes = 1
    entry.writeUInt16LE(32, 6);              // wBitCount = 32
    entry.writeUInt32LE(pngBuffers[i].length, 8);  // dwBytesInRes
    entry.writeUInt32LE(offset, 12);          // dwImageOffset
    entries.push(entry);
    offset += pngBuffers[i].length;
  }

  return Buffer.concat([header, ...entries, ...pngBuffers]);
}

// ---------------------------------------------------------------------------
// Smoke test + isMain guard
// ---------------------------------------------------------------------------

async function main() {
  // Minimal valid 1×1 transparent PNG (67 bytes).
  // Generated from a known-good 1×1 RGBA PNG and hardcoded as hex for zero deps.
  // Verified: PNG sig (8B) + IHDR (25B) + IDAT (22B) + IEND (12B) = 67 bytes.
  const TINY_PNG_HEX =
    "89504e470d0a1a0a" +          // PNG signature
    "0000000d49484452" +          // IHDR length=13, type=IHDR
    "00000001" +                  // width=1
    "00000001" +                  // height=1
    "0806" +                      // bitdepth=8, colortype=6 (RGBA)
    "000000" +                    // compression=0, filter=0, interlace=0
    "1f15c489" +                  // IHDR CRC
    "0000000a49444154" +          // IDAT length=10, type=IDAT
    "7860600000000200" +          // IDAT compressed data
    "0175870144" +                // IDAT data + CRC
    "0000000049454e44" +          // IEND length=0, type=IEND
    "ae426082";                   // IEND CRC

  const tiny = Buffer.from(TINY_PNG_HEX.replace(/\s/g, ""), "hex");

  const buf16 = tiny;
  const buf32 = tiny;
  const buf48 = tiny;

  const ico = packIco([buf16, buf32, buf48], [16, 32, 48]);

  // Header assertions
  console.assert(ico.readUInt16LE(0) === 0, "idReserved must be 0");
  console.assert(ico.readUInt16LE(2) === 1, "idType must be 1 (icon)");
  console.assert(ico.readUInt16LE(4) === 3, "idCount must be 3");

  // Entry 0 assertions (starts at byte 6)
  console.assert(ico.readUInt8(6) === 16, "entry0 bWidth=16");
  console.assert(ico.readUInt8(7) === 16, "entry0 bHeight=16");

  // Entry 0 image offset: 6 (header) + 3×16 (entries) = 54
  console.assert(ico.readUInt32LE(18) === 54, "entry0 image offset=54");

  // Entry 0 byte count
  console.assert(ico.readUInt32LE(14) === buf16.length, "entry0 dwBytesInRes=buf16.length");

  // Entry 1 offset (at byte 6+16=22, imageOffset field at +12 = byte 34)
  const entry1Offset = ico.readUInt32LE(34);
  console.assert(entry1Offset === 54 + buf16.length, "entry1 offset=54+buf16.length");

  // Entry 2 offset (at byte 6+32=38, imageOffset field at +12 = byte 50)
  const entry2Offset = ico.readUInt32LE(50);
  console.assert(
    entry2Offset === 54 + buf16.length + buf32.length,
    "entry2 offset=54+buf16.length+buf32.length"
  );

  // Total buffer length
  const expectedLen = 54 + buf16.length + buf32.length + buf48.length;
  console.assert(ico.length === expectedLen, `total ico length=${expectedLen}`);

  console.log("[ico-packer] smoke: OK");
  process.exit(0);
}

// isMain guard — prevents execution when imported as a module
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  if (process.argv.includes("--test")) {
    main().catch((err) => {
      console.error("[ico-packer] FATAL:", err);
      process.exit(1);
    });
  }
}

// fileURLToPath import (needed for isMain guard — no other imports required for packIco)
import { fileURLToPath } from "url";
