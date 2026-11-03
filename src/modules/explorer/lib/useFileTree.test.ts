import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  states: [] as unknown[],
  cursor: 0,
  remove: vi.fn(),
  invoke: vi.fn(),
}));

vi.mock("react", () => ({
  useCallback: (callback: unknown) => callback,
  useEffect: () => {},
  useLayoutEffect: () => {},
  useRef: (current: unknown) => ({ current }),
  useState: (initial: unknown) => {
    const index = mocks.cursor++;
    if (!(index in mocks.states)) {
      mocks.states[index] = typeof initial === "function" ? initial() : initial;
    }
    return [mocks.states[index], (value: unknown) => {
      mocks.states[index] = typeof value === "function"
        ? value(mocks.states[index])
        : value;
    }];
  },
}));
vi.mock("@tauri-apps/api/core", () => ({ invoke: mocks.invoke }));
vi.mock("@/modules/workspace", () => ({
  useWorkspaceEnvStore: (select: (state: unknown) => unknown) =>
    select({ env: { kind: "local" } }),
  workspaceScopeKey: () => "local",
  currentWorkspaceEnv: () => ({ kind: "local" }),
}));
vi.mock("@/modules/settings/preferences", () => ({
  usePreferencesStore: (select: (state: unknown) => unknown) => select({}),
}));
vi.mock("./watch", () => ({
  listenFsChanged: vi.fn(),
  watchAdd: vi.fn(),
  watchRemove: vi.fn(),
}));
vi.mock("./watchRegistry", () => ({
  createWatchRegistry: () => ({ remove: mocks.remove }),
}));

import { useFileTree } from "./useFileTree";

function renderTree() {
  mocks.cursor = 0;
  return useFileTree("/repo");
}

describe("collapse all folders", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.states = [];
  });

  it("closes nested folders and releases their watches without reloading files", () => {
    renderTree();
    mocks.states[1] = new Set(["/repo/src", "/repo/src/nested", "/repo/docs"]);
    const tree = renderTree();
    const nodes = tree.nodes;

    tree.collapseAll();

    expect(renderTree().expanded.size).toBe(0);
    expect(renderTree().nodes).toBe(nodes);
    expect(mocks.remove.mock.calls).toEqual([
      ["/repo/src"], ["/repo/src/nested"], ["/repo/docs"],
    ]);
    expect(mocks.remove).not.toHaveBeenCalledWith("/repo");
    expect(mocks.invoke).not.toHaveBeenCalled();
  });

  it("does nothing to watches when all folders are already closed", () => {
    renderTree().collapseAll();
    expect(renderTree().expanded.size).toBe(0);
    expect(mocks.remove).not.toHaveBeenCalled();
  });
});
