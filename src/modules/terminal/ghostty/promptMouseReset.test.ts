import { readFile } from "node:fs/promises";
import { TeraxGhostty } from "@terax/ghostty-core/adapted";
import { beforeAll, describe, expect, it } from "vitest";
import { AdaptedGhosttyTerminalModel } from "./AdaptedGhosttyTerminalModel";

const encoder = new TextEncoder();
let core: TeraxGhostty;

beforeAll(async () => {
  const file = await readFile(
    new URL(
      "../../../../packages/ghostty-core/adapted/ghostty-vt.wasm",
      import.meta.url,
    ),
  );
  core = await TeraxGhostty.loadBytes(Uint8Array.from(file).buffer);
});

function model() {
  const m = new AdaptedGhosttyTerminalModel(core, {
    backend: "ghostty-webgpu",
    cols: 40,
    rows: 10,
  });
  return { m, write: (text: string) => m.write(encoder.encode(text)) };
}

describe("mouse tracking left behind by a killed program", () => {
  it("is cleared when the shell shows a new prompt", () => {
    const { m, write } = model();
    try {
      write("\x1b]133;C\x07\x1b[?1000h\x1b[?1006h");
      expect(m.modes().mouseTracking).toBe(true);
      write("\x1b]133;D;130\x07\x1b]133;A\x07$ \x1b]133;B\x07");
      expect(m.modes().mouseTracking).toBe(false);
      expect(m.mode(1006)).toBe(false);
    } finally {
      m.dispose();
    }
  });

  it("is kept for a program started in the same chunk as the prompt", () => {
    const { m, write } = model();
    try {
      write("\x1b]133;A\x07$ \x1b]133;B\x07\x1b]133;C\x07\x1b[?1000h");
      expect(m.modes().mouseTracking).toBe(true);
    } finally {
      m.dispose();
    }
  });
});
