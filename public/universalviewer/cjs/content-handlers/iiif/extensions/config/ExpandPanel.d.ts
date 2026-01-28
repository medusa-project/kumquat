import { ModuleConfig } from "../../BaseConfig";
export declare type ExpandPanelOptions = {
    /** Determines if expand full is enabled */
    expandFullEnabled: boolean;
    /** Determines the duration of the panel expand/collapse animation */
    panelAnimationDuration: number;
    /** Width of the collapsed panel */
    panelCollapsedWidth: number;
    /** Width of the expanded panel */
    panelExpandedWidth: number;
    /** Determines if the panel is open */
    panelOpen: boolean;
};
export declare type ExpandPanelContent = {
    collapse: string;
    collapseFull: string;
    expand: string;
    expandFull: string;
};
export declare type ExpandPanel = ModuleConfig & {
    options: ExpandPanelOptions;
    content: ExpandPanelContent;
};
