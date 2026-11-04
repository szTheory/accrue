// This committed hook bundle is part of the direct-render Storybook asset. The
// iframe loads it before its own
// LiveSocket bundle. Keep the same hooks available to stories that the admin
// application uses, without starting a second application LiveSocket here.
import { CommandPalette } from "./hooks/command_palette";
import { ConnectionState } from "./hooks/connection_state";
import { FocusTrap } from "./hooks/focus_trap";
import { Overlay } from "./hooks/overlay";
import { Clipboard } from "./hooks/clipboard";
import { PreserveDisclosure } from "./hooks/preserve_disclosure";
import { TimeDisplay } from "./hooks/time_display";
import { JsonViewerTabs } from "./hooks/json_viewer_tabs";
import { Pagination } from "./hooks/pagination";

window.storybook = window.storybook || {};
window.storybook.Hooks = {
  ...window.storybook.Hooks,
  CommandPalette,
  ConnectionState,
  FocusTrap,
  Overlay,
  Clipboard,
  PreserveDisclosure,
  TimeDisplay,
  JsonViewerTabs,
  Pagination
};
