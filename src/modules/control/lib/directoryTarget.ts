import type { SpaceMeta } from "@/modules/spaces/lib/store";
import type { Tab } from "@/modules/tabs/lib/useTabs";
import { findLeafCwd } from "@/modules/terminal/lib/panes";

export function findDirectoryTarget(
  spaces: Pick<SpaceMeta, "id" | "root" | "env">[],
  tabs: Tab[],
  path: string,
): { spaceId: string; tabId: number | null } | null {
  const local = spaces.filter((space) => space.env.kind === "local");
  const normalize = (value: string) =>
    value.replace(/\\/g, "/").replace(/\/+$/, "");
  const target = normalize(path);
  for (const tab of tabs) {
    if (
      tab.kind !== "terminal" ||
      tab.private ||
      !local.some((space) => space.id === tab.spaceId)
    )
      continue;
    const cwd = findLeafCwd(tab.paneTree, tab.activeLeafId) ?? tab.cwd;
    if (cwd && normalize(cwd) === target)
      return { spaceId: tab.spaceId, tabId: tab.id };
  }
  const space = local.find(
    (space) => space.root && normalize(space.root) === target,
  );
  return space ? { spaceId: space.id, tabId: null } : null;
}
