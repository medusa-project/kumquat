import { BaseConfig, CenterPanelContent, CenterPanelOptions, DownloadDialogueContent, DownloadDialogueOptions, ModuleConfig, SettingsDialogueContent, SettingsDialogueOptions, ShareDialogueContent, ShareDialogueOptions } from "@/content-handlers/iiif/BaseConfig";
declare type MediaElementCenterPanelOptions = CenterPanelOptions & {
    defaultHeight: number;
    defaultWidth: number;
};
declare type MediaElementCenterPanelContent = CenterPanelContent & {};
declare type MediaElementCenterPanel = {
    options: MediaElementCenterPanelOptions;
    content: MediaElementCenterPanelContent;
};
declare type MediaElementDownloadDialogueOptions = DownloadDialogueOptions & {};
declare type MediaElementDownloadDialogueContent = DownloadDialogueContent & {};
declare type MediaElementDownloadDialogue = ModuleConfig & {
    options: MediaElementDownloadDialogueOptions;
    content: MediaElementDownloadDialogueContent;
};
declare type MediaElementShareDialogueOptions = ShareDialogueOptions & {};
declare type MediaElementShareDialogueContent = ShareDialogueContent & {};
declare type MediaElementShareDialogue = ModuleConfig & {
    options: MediaElementShareDialogueOptions;
    content: MediaElementShareDialogueContent;
};
declare type MediaElementSettingsDialogueOptions = SettingsDialogueOptions & {};
declare type MediaElementSettingsDialogueContent = SettingsDialogueContent & {};
declare type MediaElementSettingsDialogue = ModuleConfig & {
    options: MediaElementSettingsDialogueOptions;
    content: MediaElementSettingsDialogueContent;
};
declare type Modules = {
    centerPanel: MediaElementCenterPanel;
    downloadDialogue: MediaElementDownloadDialogue;
    shareDialogue: MediaElementShareDialogue;
    settingsDialogue: MediaElementSettingsDialogue;
};
export declare type Config = BaseConfig & {
    modules: Modules;
};
export {};
