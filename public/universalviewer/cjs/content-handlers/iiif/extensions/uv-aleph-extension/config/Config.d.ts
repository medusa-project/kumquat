import { BaseConfig, CenterPanelContent, CenterPanelOptions, DownloadDialogueContent, DownloadDialogueOptions, ModuleConfig, SettingsDialogueContent, SettingsDialogueOptions, ShareDialogueContent, ShareDialogueOptions } from "@/content-handlers/iiif/BaseConfig";
import { ExpandPanelContent, ExpandPanelOptions } from "../../config/ExpandPanel";
declare type AlephLeftPanelOptions = ExpandPanelOptions & {
    /** Determines if the console tab is enabled */
    consoleTabEnabled: boolean;
    /** Determines if the graph tab is enabled */
    graphTabEnabled: boolean;
    /** Determines if the settings tab is enabled */
    settingsTabEnabled: boolean;
    /** Determines if the source tab is enabled */
    srcTabEnabled: boolean;
};
declare type AlephLeftPanelContent = ExpandPanelContent & {
    title: string;
};
declare type AlephLeftPanel = {
    options: AlephLeftPanelOptions;
    content: AlephLeftPanelContent;
};
declare type AlephCenterPanelOptions = CenterPanelOptions & {};
declare type AlephCenterPanelContent = CenterPanelContent & {};
declare type AlephCenterPanel = {
    options: AlephCenterPanelOptions;
    content: AlephCenterPanelContent;
};
declare type AlephDownloadDialogueOptions = DownloadDialogueOptions & {};
declare type AlephDownloadDialogueContent = DownloadDialogueContent & {};
declare type AlephDownloadDialogue = ModuleConfig & {
    options: AlephDownloadDialogueOptions;
    content: AlephDownloadDialogueContent;
};
declare type AlephShareDialogueOptions = ShareDialogueOptions & {};
declare type AlephShareDialogueContent = ShareDialogueContent & {};
declare type AlephShareDialogue = ModuleConfig & {
    options: AlephShareDialogueOptions;
    content: AlephShareDialogueContent;
};
declare type AlephSettingsDialogueOptions = SettingsDialogueOptions & {};
declare type AlephSettingsDialogueContent = SettingsDialogueContent & {};
declare type AlephSettingsDialogue = ModuleConfig & {
    options: AlephSettingsDialogueOptions;
    content: AlephSettingsDialogueContent;
};
declare type Modules = {
    leftPanel: AlephLeftPanel;
    centerPanel: AlephCenterPanel;
    downloadDialogue: AlephDownloadDialogue;
    shareDialogue: AlephShareDialogue;
    settingsDialogue: AlephSettingsDialogue;
};
export declare type Config = BaseConfig & {
    modules: Modules;
};
export {};
