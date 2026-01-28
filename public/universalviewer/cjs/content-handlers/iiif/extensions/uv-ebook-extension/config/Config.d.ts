import { BaseConfig, CenterPanelContent, CenterPanelOptions, DownloadDialogueContent, DownloadDialogueOptions, ModuleConfig, SettingsDialogueContent, SettingsDialogueOptions, ShareDialogueContent, ShareDialogueOptions } from "@/content-handlers/iiif/BaseConfig";
import { ExpandPanelContent, ExpandPanelOptions } from "../../config/ExpandPanel";
declare type EbookLeftPanelOptions = ExpandPanelOptions & {};
declare type EbookLeftPanelContent = ExpandPanelContent & {
    title: string;
};
declare type EbookLeftPanel = {
    options: EbookLeftPanelOptions;
    content: EbookLeftPanelContent;
};
declare type EbookCenterPanelOptions = CenterPanelOptions & {};
declare type EbookCenterPanelContent = CenterPanelContent & {};
declare type EbookCenterPanel = {
    options: EbookCenterPanelOptions;
    content: EbookCenterPanelContent;
};
declare type EbookDownloadDialogueOptions = DownloadDialogueOptions & {};
declare type EbookDownloadDialogueContent = DownloadDialogueContent & {};
declare type EbookDownloadDialogue = ModuleConfig & {
    options: EbookDownloadDialogueOptions;
    content: EbookDownloadDialogueContent;
};
declare type EbookShareDialogueOptions = ShareDialogueOptions & {};
declare type EbookShareDialogueContent = ShareDialogueContent & {};
declare type EbookShareDialogue = ModuleConfig & {
    options: EbookShareDialogueOptions;
    content: EbookShareDialogueContent;
};
declare type EbookSettingsDialogueOptions = SettingsDialogueOptions & {};
declare type EbookSettingsDialogueContent = SettingsDialogueContent & {};
declare type EbookSettingsDialogue = ModuleConfig & {
    options: EbookSettingsDialogueOptions;
    content: EbookSettingsDialogueContent;
};
declare type Modules = {
    leftPanel: EbookLeftPanel;
    centerPanel: EbookCenterPanel;
    downloadDialogue: EbookDownloadDialogue;
    shareDialogue: EbookShareDialogue;
    settingsDialogue: EbookSettingsDialogue;
};
export declare type Config = BaseConfig & {
    modules: Modules;
};
export {};
