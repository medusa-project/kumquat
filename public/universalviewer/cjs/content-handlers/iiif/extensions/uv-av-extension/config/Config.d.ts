import { BaseConfig, CenterPanelContent, CenterPanelOptions, DownloadDialogueContent, DownloadDialogueOptions, ModuleConfig, SettingsDialogueContent, SettingsDialogueOptions, ShareDialogueContent, ShareDialogueOptions } from "@/content-handlers/iiif/BaseConfig";
declare type AVCenterPanelOptions = CenterPanelOptions & {
    /** Determines if the poster image is expanded */
    posterImageExpanded: boolean;
    /** Determines if media errors are hidden */
    hideMediaError: boolean;
    /** Determines if parent is included in title */
    includeParentInTitleEnabled: boolean;
    /** Field for subtitle metadata */
    subtitleMetadataField: string;
    /** Determines if auto play is enabled */
    autoPlay: boolean;
    /** Determines if fast forward is enabled */
    enableFastForward: boolean;
    /** Determines if fast rewind is enabled */
    enableFastRewind: boolean;
    /** Ratio of the poster image */
    posterImageRatio: number;
    /** Determines if limit is set to range */
    limitToRange: boolean;
    /** Determines if ranges auto advance */
    autoAdvanceRanges: boolean;
};
declare type AVCenterPanelContent = CenterPanelContent & {
    delimiter: string;
};
declare type AVCenterPanel = {
    options: AVCenterPanelOptions;
    content: AVCenterPanelContent;
};
declare type AVDownloadDialogueOptions = DownloadDialogueOptions & {};
declare type AVDownloadDialogueContent = DownloadDialogueContent & {};
declare type AVDownloadDialogue = ModuleConfig & {
    options: AVDownloadDialogueOptions;
    content: AVDownloadDialogueContent;
};
declare type AVShareDialogueOptions = ShareDialogueOptions & {};
declare type AVShareDialogueContent = ShareDialogueContent & {};
declare type AVShareDialogue = ModuleConfig & {
    options: AVShareDialogueOptions;
    content: AVShareDialogueContent;
};
declare type AVSettingsDialogueOptions = SettingsDialogueOptions & {};
declare type AVSettingsDialogueContent = SettingsDialogueContent & {};
declare type AVSettingsDialogue = ModuleConfig & {
    options: AVSettingsDialogueOptions;
    content: AVSettingsDialogueContent;
};
declare type Modules = {
    centerPanel: AVCenterPanel;
    downloadDialogue: AVDownloadDialogue;
    shareDialogue: AVShareDialogue;
    settingsDialogue: AVSettingsDialogue;
};
export declare type Config = BaseConfig & {
    modules: Modules;
};
export {};
