import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { fmtShortcut, MOD_KEY, SHIFT_KEY } from "@/lib/platform";
import {
  ComputerTerminal02Icon,
  GitBranchIcon,
  Globe02Icon,
  IncognitoIcon,
  PencilEdit02Icon,
  PlusSignIcon,
} from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";

type Props = {
  onNew: () => void;
  onNewBlock: () => void;
  onNewPrivate: () => void;
  onNewPreview: () => void;
  onNewEditor: () => void;
  onNewGitGraph: () => void;
};

export function NewTabMenu({
  onNew,
  onNewBlock,
  onNewPrivate,
  onNewPreview,
  onNewEditor,
  onNewGitGraph,
}: Props) {
  const items = [
    {
      label: "Terminal",
      icon: ComputerTerminal02Icon,
      action: onNew,
      shortcut: fmtShortcut(MOD_KEY, "T"),
    },
    {
      label: "Blocks",
      icon: ComputerTerminal02Icon,
      action: onNewBlock,
      shortcut: fmtShortcut(MOD_KEY, SHIFT_KEY, "T"),
    },
    {
      label: "Privacy",
      icon: IncognitoIcon,
      action: onNewPrivate,
      shortcut: fmtShortcut(MOD_KEY, "R"),
    },
    {
      label: "Editor",
      icon: PencilEdit02Icon,
      action: onNewEditor,
      shortcut: fmtShortcut(MOD_KEY, "E"),
    },
    {
      label: "Preview",
      icon: Globe02Icon,
      action: onNewPreview,
      shortcut: fmtShortcut(MOD_KEY, "P"),
    },
    {
      label: "Git Graph",
      icon: GitBranchIcon,
      action: onNewGitGraph,
      shortcut: "",
    },
  ];
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          size="icon"
          className="ml-1 size-6 shrink-0 rounded-full"
          title="New tab"
        >
          <HugeiconsIcon icon={PlusSignIcon} data-icon="inline-start" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent
        align="start"
        className="min-w-44"
        onCloseAutoFocus={(event) => event.preventDefault()}
      >
        <DropdownMenuGroup>
          {items.map((item) => (
            <DropdownMenuItem key={item.label} onSelect={item.action}>
              <HugeiconsIcon icon={item.icon} size={14} strokeWidth={1.75} />
              <span className="flex-1">{item.label}</span>
              <span className="text-xs text-muted-foreground">
                {item.shortcut}
              </span>
            </DropdownMenuItem>
          ))}
        </DropdownMenuGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
