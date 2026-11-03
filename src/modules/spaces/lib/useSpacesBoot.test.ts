import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  launch: vi.fn(),
  hydrate: vi.fn(),
  save: vi.fn(),
  replace: vi.fn(),
  adopt: vi.fn(),
}));
vi.mock("react", async (original) => ({
  ...(await original<typeof import("react")>()),
  useRef: (current: unknown) => ({ current }),
  useEffect: (effect: () => void) => effect(),
}));
vi.mock("@/modules/tabs/lib/useTabs", () => ({ DEFAULT_SPACE_ID: "default" }));
vi.mock("@/lib/native", () => ({
  native: { launchDirectoryRequest: mocks.launch },
}));
vi.mock("@/modules/settings/preferences", () => ({
  usePreferencesStore: {
    getState: () => ({
      init: async () => {},
      defaultWorkspaceEnv: "wsl:Ubuntu",
    }),
  },
}));
vi.mock("@/modules/workspace", () => ({
  LOCAL_WORKSPACE: { kind: "local" },
  parseWorkspaceScopeKey: () => ({ kind: "wsl", distro: "Ubuntu" }),
}));
vi.mock("./useSpaces", () => ({
  useSpaces: { getState: () => ({ hydrate: mocks.hydrate }) },
}));
vi.mock("./store", () => ({
  loadAll: async () => ({ spaces: [], activeId: null, states: new Map() }),
  saveSpacesList: mocks.save,
  saveActiveId: async () => {},
}));
import { useSpacesBoot } from "./useSpacesBoot";

async function boot() {
  let id = 0;
  await new Promise<void>((resolve) =>
    useSpacesBoot({
      ready: true,
      launchCwd: "C:/home",
      home: "C:/home",
      allocId: () => ++id,
      replaceTabs: mocks.replace,
      markBooted: resolve,
      setActiveSpaceForNewTabs: () => {},
      adoptWorkspaceEnv: mocks.adopt,
    }),
  );
}

describe("directory-request cold startup", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mocks.adopt.mockResolvedValue("C:/home");
  });
  it("starts one strict local terminal, even with WSL as the saved default", async () => {
    mocks.launch.mockResolvedValue("D:/مشروع & spaces");
    await boot();
    expect(mocks.save).toHaveBeenCalledWith([
      expect.objectContaining({
        root: "D:/مشروع & spaces",
        env: { kind: "local" },
      }),
    ]);
    expect(mocks.adopt).toHaveBeenCalledWith({ kind: "local" });
    expect(mocks.replace).toHaveBeenCalledTimes(1);
    const tabs = mocks.replace.mock.calls[0][0];
    expect(tabs).toHaveLength(1);
    expect(tabs[0].paneTree).toMatchObject({
      cwd: "D:/مشروع & spaces",
      requireCwd: true,
    });
  });
  it("leaves an ordinary launch's saved environment and initial tab alone", async () => {
    mocks.launch.mockResolvedValue(null);
    await boot();
    expect(mocks.save).toHaveBeenCalledWith([
      expect.objectContaining({ env: { kind: "wsl", distro: "Ubuntu" } }),
    ]);
    expect(mocks.replace).not.toHaveBeenCalled();
    expect(mocks.adopt).not.toHaveBeenCalled();
  });
});
