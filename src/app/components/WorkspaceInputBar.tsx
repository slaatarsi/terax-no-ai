import { homeRelativePath } from "@/lib/homeRelativePath";
import { useBlockController } from "@/modules/terminal/lib/blockController";
import { focusLeafInput } from "@/modules/terminal/lib/terminalSessionApi";
import { lazy, Suspense, useEffect, useRef, useState } from "react";
import { useGitBranch } from "./useGitBranch";
import { useSystemInfo } from "./useSystemInfo";

const ShellInput = lazy(() => import("@/modules/terminal/block/ShellInput"));

type Props = {
  isBlockTab: boolean;
  isTerminalTab: boolean;
  activeLeafId: number | null;
  cwd: string | null;
  home: string | null;
};

export function WorkspaceInputBar({
  isBlockTab,
  isTerminalTab,
  activeLeafId,
  cwd,
  home,
}: Props) {
  const { os, shell } = useSystemInfo();
  const controller = useBlockController(isBlockTab ? activeLeafId : null);
  const blockMode = controller?.blockMode ?? "prompt";
  const [promptNonce, setPromptNonce] = useState(0);
  const prevBlockMode = useRef(blockMode);
  useEffect(() => {
    if (prevBlockMode.current !== "prompt" && blockMode === "prompt") {
      setPromptNonce((n) => n + 1);
    }
    prevBlockMode.current = blockMode;
  }, [blockMode]);
  const branch = useGitBranch(
    isTerminalTab && isBlockTab ? cwd : null,
    promptNonce,
  );

  if (!isBlockTab || !controller || activeLeafId === null) return null;

  return (
    <div
      data-shell-input-bar
      className="shrink-0 border-t border-border/60 bg-foreground/[0.02] px-4 py-3"
    >
      <div className="mb-2 flex min-w-0 items-center gap-3 text-[11px] text-muted-foreground">
        {os && <span>{os}</span>}
        {cwd && (
          <span className="truncate" title={cwd}>
            {homeRelativePath(cwd, home)}
          </span>
        )}
        {branch && (
          <span className="truncate" title={`Branch: ${branch}`}>
            {branch}
          </span>
        )}
        {shell && <span>{shell}</span>}
      </div>
      {blockMode === "plain" ? (
        <button
          type="button"
          className="text-sm text-muted-foreground hover:text-foreground"
          onClick={() => focusLeafInput(activeLeafId)}
        >
          Type directly in the terminal
        </button>
      ) : (
        <Suspense fallback={null}>
          <ShellInput
            leafId={activeLeafId}
            mode={blockMode}
            focused
            onSubmit={controller.submitCommand}
            onInterrupt={controller.interrupt}
            getCwd={controller.getCwd}
          />
        </Suspense>
      )}
    </div>
  );
}
