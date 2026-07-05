const DIMENSIONS = [
  { id: 1, name: "token-compliance" },
  { id: 2, name: "visual-hierarchy" },
  { id: 3, name: "spacing-rhythm" },
  { id: 4, name: "state-coverage" },
  { id: 5, name: "responsive-mobile-first" },
  { id: 6, name: "contrast" },
  { id: 7, name: "focus-semantics" },
  { id: 8, name: "brand-expression" },
  { id: 9, name: "motion" },
  { id: 10, name: "reuse-dry" },
  { id: 11, name: "interaction-integrity" },
  { id: 12, name: "microcopy" },
];

const STATE_TAXONOMY = [
  "default-populated",
  "empty",
  "loading",
  "error",
  "permission-denied",
  "disconnected-reconnecting",
  "overflow",
  "long-content",
  "disabled-readonly",
  "interactive-open",
];

const OVERLAY_TAGS = [
  "layer-z-index",
  "live-focus",
  "focus-restore",
  "focus-trap",
  "scroll-reachability",
  "overlay-position",
  "actionability",
  "disabled-affordance",
  "hover-affordance",
  "copy-recovery",
  "copy-vocabulary",
  "copy-specificity",
  "dark-mode-role",
  "reduced-motion",
];

const PROJECTS = [
  { name: "chromium-desktop", mode: "chromium-desktop", viewport_width: 1440 },
  { name: "chromium-mobile", mode: "chromium-mobile", viewport_width: 390 },
];

const THEMES = ["light", "dark"];

const OWNER_PHASES = {
  foundation: "188",
  primitive: "189",
  group: "190",
  page: "191",
};

const ALL_STATES = STATE_TAXONOMY;
const FLOW_STATES = [
  "default-populated",
  "empty",
  "loading",
  "error",
  "permission-denied",
  "disconnected-reconnecting",
  "overflow",
  "long-content",
  "interactive-open",
];
const COMPONENT_STATES = [
  "default-populated",
  "empty",
  "loading",
  "error",
  "overflow",
  "long-content",
  "disabled-readonly",
  "interactive-open",
];

const PAGE_FLOWS = [
  ["dashboard", "/billing", "Monitor billing health and recent operational changes."],
  ["customers", "/billing/customers", "Find and inspect billable customers."],
  [
    "customer-detail",
    "/billing/customers/:customer_id",
    "Review customer billing identity, subscriptions, and related records.",
    { fixture: "dashboard", params: ["customer_id"] },
  ],
  ["subscriptions", "/billing/subscriptions", "Triage active, trialing, past-due, and canceled subscriptions."],
  [
    "subscription-detail",
    "/billing/subscriptions/:subscription_id",
    "Inspect subscription state, customer relationship, invoices, and actions.",
    { fixture: "dashboard", params: ["subscription_id"] },
  ],
  ["invoices", "/billing/invoices", "Review invoices across payment and collection states."],
  [
    "invoice-detail",
    "/billing/invoices/:jpy_invoice_id",
    "Inspect invoice totals, line items, customer, and payment state.",
    { fixture: "edge-states", params: ["jpy_invoice_id"] },
  ],
  ["payments", "/billing/payments", "Review charges and payment attempts."],
  [
    "charge-detail",
    "/billing/payments/:charge_id",
    "Inspect a charge, outcome, metadata, and linked customer evidence.",
    { fixture: "operator-flows", params: ["charge_id"] },
  ],
  ["coupons", "/billing/coupons", "Review coupon inventory and redemption constraints."],
  [
    "coupon-detail",
    "/billing/coupons/:coupon_id",
    "Inspect coupon terms, redemption state, and related promotion codes.",
    { fixture: "edge-states", params: ["coupon_id"] },
  ],
  ["promotion-codes", "/billing/promotion-codes", "Review customer-facing promotion codes."],
  [
    "promo-code-detail",
    "/billing/promotion-codes/:promo_code_id",
    "Inspect promotion-code usage, coupon relationship, and constraints.",
    { fixture: "edge-states", params: ["promo_code_id"] },
  ],
  ["connect", "/billing/connect", "Monitor connected accounts and onboarding health."],
  [
    "connect-detail",
    "/billing/connect/:connect_account_id",
    "Inspect connected account requirements and payout readiness.",
    { fixture: "edge-states", params: ["connect_account_id"] },
  ],
  ["events", "/billing/events", "Review processor and internal event history."],
  [
    "event-detail",
    "/billing/events/:source_event_id",
    "Inspect event payload, delivery state, and linked resource context.",
    { fixture: "operator-flows", params: ["source_event_id"] },
  ],
  ["webhooks", "/billing/webhooks", "Review webhook endpoint health and delivery status."],
  [
    "webhook-detail",
    "/billing/webhooks/:single_webhook_id",
    "Inspect webhook delivery attempts, response status, and retry context.",
    { fixture: "operator-flows", params: ["single_webhook_id"] },
  ],
  ["recovery", "/billing/analytics/recovery", "Review recovered revenue and at-risk subscriptions."],
  [
    "campaign-detail",
    "/billing/analytics/recovery/subscriptions/:at_risk_sub_id",
    "Inspect an at-risk subscription recovery path and action history.",
    { fixture: "edge-states", params: ["at_risk_sub_id"] },
  ],
];

const COMPONENT_FAMILIES = [
  ["button", "Activate primary, secondary, ghost, and danger actions with clear affordance."],
  ["status", "Communicate status, severity, and tone across light and dark themes."],
  ["card", "Summarize KPI and delta information with tokenized hierarchy."],
  ["app-shell", "Frame navigation, topbar, content, and theme controls."],
  ["breadcrumbs", "Orient operators inside nested billing resources."],
  ["dropdown-menu", "Expose secondary actions through a keyboard-reachable menu."],
  ["flash-group", "Announce transient feedback without obscuring the next action."],
  ["icon", "Render the shared glyph set with accessible context."],
  ["detail", "Present summary cards, sections, facts, fields, and actions."],
  ["related-resources", "Link related billing resources from detail surfaces."],
  ["tabs", "Switch between related subviews while preserving location and counts."],
  ["data-table", "Scan dense billing records with stable headers and row actions."],
  ["filter-chip-bar", "Show applied filters and clear actions."],
  ["global-search", "Find billing resources quickly from the admin shell."],
  ["input", "Collect text and numeric values with clear labels and errors."],
  ["select", "Choose constrained values without losing form context."],
  ["detail-drawer", "Open contextual detail without stranding focus or scroll."],
  ["dunning-banner", "Surface recovery action requirements with precise copy."],
  ["timeline", "Show chronological event or campaign history."],
  ["json-viewer", "Inspect raw payloads without horizontal overflow traps."],
  ["window-selector", "Change reporting windows without ambiguous state."],
];

const COMPONENT_GROUPS = [
  ["page-header/actions/breadcrumbs", "Orient the operator, name the task, and expose primary actions."],
  ["toolbar/search/filter/sort", "Refine dense lists without hiding current constraints."],
  ["table/empty/loading/error/pagination", "Move from no data through large data sets without losing actionability."],
  ["KPI/chart/table", "Connect summary metrics to trend and row-level evidence."],
  ["detail-header/metadata/actions", "Anchor identity, facts, status, and detail-level operations."],
  ["modal-confirm", "Confirm destructive or consequential actions with focus containment."],
  ["drawer/form", "Edit or inspect details in a layered panel while preserving page context."],
  ["tabs/subviews", "Move between related resource subviews with stable focus and labels."],
];

function slug(value) {
  return String(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

function pageSurface([surface, route, persona_job, routeBuilder]) {
  return {
    surface,
    surface_type: "page-flow",
    persona_job,
    owner_phase: OWNER_PHASES.page,
    seed: "operator-flows+dashboard+edge-states",
    states: FLOW_STATES,
    projects: PROJECTS.map((project) => project.name),
    themes: THEMES,
    route,
    ...(routeBuilder ? { routeBuilder } : {}),
  };
}

function componentSurface([family, persona_job]) {
  return {
    surface: family,
    surface_type: "component",
    persona_job,
    owner_phase: OWNER_PHASES.primitive,
    seed: "component-kitchen",
    states: COMPONENT_STATES,
    projects: PROJECTS.map((project) => project.name),
    themes: THEMES,
    route: "/dev/components",
    routeBuilder: { anchor: `component-${slug(family)}` },
  };
}

function componentGroupSurface([group, persona_job]) {
  return {
    surface: group,
    surface_type: "component-group",
    persona_job,
    owner_phase: OWNER_PHASES.group,
    seed: "component-kitchen+operator-flows+edge-states",
    states: ALL_STATES,
    projects: PROJECTS.map((project) => project.name),
    themes: THEMES,
    route: "/dev/components",
    routeBuilder: { group: slug(group) },
  };
}

const SURFACES = [
  ...PAGE_FLOWS.map(pageSurface),
  ...COMPONENT_FAMILIES.map(componentSurface),
  ...COMPONENT_GROUPS.map(componentGroupSurface),
];

// SLICES (ORCH-08, D-52) — named capture/proposal subsets, keyed by slice name, valued by an
// array of capture-name surface slugs (the EXACT `name` slugs used in admin-visuals.spec.js's
// `shots` array). SLICES is the single source of truth that 207-05's `ui.round` mix task mirrors
// for `--slice` name resolution, and it resolves to the SAME `RATCHET_SURFACES` CSV vocabulary
// that admin-visuals.spec.js AND ratchet-propose.mjs both filter on. The `foundation` slice is
// Phase 208's representative convergence slice: the design-system component gallery (component
// families ride inside the single `component-kitchen` capture per D-52) plus the three exemplar
// page-flows. An unrecognized surface name in a slice/CSV simply matches nothing (silent no-op),
// never expands scope (T-207-05).
const SLICES = {
  foundation: ["component-kitchen", "dashboard", "subscription-detail", "subscriptions"],
};

function lookupProject(project) {
  const found = PROJECTS.find((item) => item.name === project || item.mode === project);
  if (!found) throw new Error(`Unknown baseline project: ${project}`);
  return found;
}

function lookupDimension(dimension) {
  const id = typeof dimension === "number" ? dimension : Number(dimension);
  const found = DIMENSIONS.find((item) => item.id === id || item.name === dimension);
  if (!found) throw new Error(`Unknown baseline dimension: ${dimension}`);
  return found;
}

function cellId(surface, project, theme, state, dimension) {
  const projectInfo = lookupProject(project);
  const dimensionInfo = lookupDimension(dimension);
  if (!THEMES.includes(theme)) throw new Error(`Unknown baseline theme: ${theme}`);
  if (!STATE_TAXONOMY.includes(state)) throw new Error(`Unknown baseline state: ${state}`);
  return [
    "p187",
    slug(surface),
    slug(projectInfo.mode),
    slug(theme),
    slug(state),
    `d${String(dimensionInfo.id).padStart(2, "0")}`,
  ].join("__");
}

function cellsForSurface(surface) {
  const surfaceInfo =
    typeof surface === "string" ? SURFACES.find((item) => item.surface === surface) : surface;
  if (!surfaceInfo) throw new Error(`Unknown baseline surface: ${surface}`);

  const cells = [];
  for (const projectName of surfaceInfo.projects) {
    const project = lookupProject(projectName);
    for (const theme of surfaceInfo.themes) {
      for (const state of surfaceInfo.states) {
        for (const dimension of DIMENSIONS) {
          cells.push({
            cell_id: cellId(surfaceInfo.surface, project.name, theme, state, dimension.id),
            surface: surfaceInfo.surface,
            surface_type: surfaceInfo.surface_type,
            mode: project.mode,
            viewport_width: project.viewport_width,
            theme,
            state,
            dimension: dimension.id,
            dimension_name: dimension.name,
            persona_job: surfaceInfo.persona_job,
            owner_phase: surfaceInfo.owner_phase,
            coverage_status: "gap",
            evidence_refs: [],
            notes: "Awaiting Phase 187 evidence capture.",
          });
        }
      }
    }
  }
  return cells;
}

module.exports = {
  DIMENSIONS,
  STATE_TAXONOMY,
  OVERLAY_TAGS,
  PROJECTS,
  THEMES,
  OWNER_PHASES,
  SURFACES,
  SLICES,
  cellId,
  cellsForSurface,
};
