import type { EffectCallback } from "react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { useControlBridge } from "./useControlBridge";

const mocks = vi.hoisted(() => ({
  effects: [] as EffectCallback[],
  listener: null as ((event: { payload: unknown }) => void) | null,
  invoke: vi.fn(),
  stop: vi.fn(),
  window: { show: vi.fn(), unminimize: vi.fn(), setFocus: vi.fn() },
}));
vi.mock("react", async (importOriginal) => ({
  ...(await importOriginal<typeof import("react")>()),
  useEffect: (effect: EffectCallback) => mocks.effects.push(effect),
}));
vi.mock("@tauri-apps/api/core", () => ({ invoke: mocks.invoke }));
vi.mock("@tauri-apps/api/window", () => ({
  getCurrentWindow: () => mocks.window,
}));
vi.mock("@tauri-apps/api/event", () => ({
  listen: (_name: string, callback: typeof mocks.listener) => {
    mocks.listener = callback;
    return Promise.resolve(mocks.stop);
  },
}));

beforeEach(() => {
  vi.clearAllMocks();
  mocks.effects.length = 0;
  mocks.listener = null;
  mocks.invoke.mockResolvedValue(true);
  mocks.window.setFocus.mockReset().mockResolvedValue(undefined);
  vi.spyOn(console, "warn").mockImplementation(() => {});
  vi.stubGlobal("requestAnimationFrame", (callback: FrameRequestCallback) => {
    callback(0);
    return 1;
  });
});
afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("directory control delivery", () => {
  it.each([true, false])(
    "opens the requested local target and acknowledges it even when focused=%s",
    async (focused) => {
      if (!focused)
        mocks.window.setFocus.mockRejectedValueOnce(new Error("focus denied"));
      const path = "C:\\مشروع & spaces";
      const onOpen = vi.fn();
      const onOpenDirectory = vi
        .fn()
        .mockResolvedValue({ spaceId: "requested", tabId: 99 });
      useControlBridge({
        ready: true,
        tabsRef: { current: [] },
        activeTabIdRef: { current: 0 },
        activeSpaceIdRef: { current: "local" },
        onOpen,
        onOpenDirectory,
      });
      const cleanup = mocks.effects[0]?.();
      try {
        mocks.listener?.({
          payload: {
            id: "directory",
            method: "open_directory",
            params: { path },
            caller: {},
          },
        });
        await vi.waitFor(() =>
          expect(mocks.invoke).toHaveBeenCalledWith("control_respond", {
            requestId: "directory",
            response: {
              ok: true,
              result: { path, space_id: "requested", tab_id: 99, focused },
            },
          }),
        );
        expect(onOpenDirectory).toHaveBeenCalledExactlyOnceWith(path);
        expect(onOpen).not.toHaveBeenCalled();
        expect(mocks.window.show).toHaveBeenCalledOnce();
        expect(mocks.window.unminimize).toHaveBeenCalledOnce();
      } finally {
        if (typeof cleanup === "function") cleanup();
      }
    },
  );
});
