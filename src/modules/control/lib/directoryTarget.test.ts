import { describe, expect, it } from "vitest";
import { findDirectoryTarget } from "./directoryTarget";
import type { TerminalTab } from "@/modules/tabs/lib/useTabs";

const spaces = [
  { id: "local", root: "C:/مشروع & spaces", env: { kind: "local" as const } },
  {
    id: "wsl",
    root: "C:/مشروع & spaces",
    env: { kind: "wsl" as const, distro: "Ubuntu" },
  },
];
const terminal: TerminalTab = {
  id: 1,
  kind: "terminal",
  title: "shell",
  spaceId: "local",
  cwd: "C:/مشروع & spaces",
  paneTree: { kind: "leaf", id: 2, cwd: "C:/مشروع & spaces" },
  activeLeafId: 2,
};

describe("directory open target", () => {
  it("reuses a matching local terminal without creating a tab", () => {
    expect(
      findDirectoryTarget(spaces, [terminal], "C:\\مشروع & spaces\\"),
    ).toEqual({ spaceId: "local", tabId: 1 });
  });
  it("never sends Windows paths to a WSL or private terminal", () => {
    expect(
      findDirectoryTarget(
        spaces,
        [
          { ...terminal, spaceId: "wsl" },
          { ...terminal, private: true },
        ],
        spaces[0].root,
      ),
    ).toEqual({ spaceId: "local", tabId: null });
    expect(findDirectoryTarget(spaces.slice(1), [], spaces[0].root)).toBeNull();
  });
  it("uses the active pane's current directory rather than a stale tab cwd", () => {
    const changed = {
      ...terminal,
      paneTree: { kind: "leaf" as const, id: 2, cwd: "D:/elsewhere" },
    };
    expect(findDirectoryTarget(spaces, [changed], spaces[0].root)).toEqual({
      spaceId: "local",
      tabId: null,
    });
    expect(findDirectoryTarget(spaces, [changed], "D:/elsewhere")).toEqual({
      spaceId: "local",
      tabId: 1,
    });
  });
  it("preserves distinct case-sensitive paths and UNC shares", () => {
    expect(
      findDirectoryTarget(spaces, [terminal], "C:/مشروع & SPACES"),
    ).toBeNull();
    expect(
      findDirectoryTarget(
        [{ ...spaces[0], root: "//server/share" }],
        [],
        "\\\\server\\share\\",
      ),
    ).toEqual({ spaceId: "local", tabId: null });
  });
});
