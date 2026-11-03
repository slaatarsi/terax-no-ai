import { renderToStaticMarkup } from "react-dom/server";
import { beforeEach, expect, it, vi } from "vitest";
import { WorkspaceInputBar } from "./WorkspaceInputBar";

const mocks = vi.hoisted(() => ({
  blockMode: "plain" as "plain" | "prompt",
  controller: vi.fn(),
}));
vi.mock("@/modules/terminal/lib/blockController", () => ({
  useBlockController: (leafId: number | null) => {
    mocks.controller(leafId);
    return leafId === null
      ? null
      : {
          blockMode: mocks.blockMode,
          submitCommand: vi.fn(),
          interrupt: vi.fn(),
          getCwd: () => "/home/me/project",
        };
  },
}));
vi.mock("@/modules/terminal/lib/terminalSessionApi", () => ({
  focusLeafInput: vi.fn(),
}));
vi.mock("./useSystemInfo", () => ({
  useSystemInfo: () => ({ os: "Linux", shell: "bash" }),
}));
vi.mock("./useGitBranch", () => ({ useGitBranch: () => "main" }));

const props = {
  isBlockTab: true,
  isTerminalTab: true,
  activeLeafId: 1,
  cwd: "/home/me/project",
  home: "/home/me",
};

beforeEach(() => {
  mocks.blockMode = "plain";
  mocks.controller.mockClear();
});

it("leaves normal terminals and non-terminal tabs without a command bar", () => {
  expect(
    renderToStaticMarkup(<WorkspaceInputBar {...props} isBlockTab={false} />),
  ).toBe("");
  expect(mocks.controller).toHaveBeenCalledWith(null);
});

it("keeps shell context and direct terminal input for unsupported block shells", () => {
  const html = renderToStaticMarkup(<WorkspaceInputBar {...props} />);
  for (const text of [
    "Linux",
    "bash",
    "~/project",
    "main",
    "Type directly in the terminal",
  ])
    expect(html).toContain(text);
  expect(html).not.toMatch(/\b(?:AI|agent|model|chat)\b/i);
});

it("does not attach a controller when there is no active terminal leaf", () => {
  expect(
    renderToStaticMarkup(<WorkspaceInputBar {...props} activeLeafId={null} />),
  ).toBe("");
});
