import { BaseConfig, CenterPanelContent, CenterPanelOptions, DownloadDialogueContent, DownloadDialogueOptions, ModuleConfig, SettingsDialogueContent, SettingsDialogueOptions, ShareDialogueContent, ShareDialogueOptions } from "@/content-handlers/iiif/BaseConfig";
declare type DefaultCenterPanelOptions = CenterPanelOptions & {};
declare type DefaultCenterPanelContent = CenterPanelContent & {};
declare type DefaultCenterPanel = {
    options: DefaultCenterPanelOptions;
    content: DefaultCenterPanelContent;
};
declare type DefaultDownloadDialogueOptions = DownloadDialogueOptions & {};
declare type DefaultDownloadDialogueContent = DownloadDialogueContent & {};
declare type DefaultDownloadDialogue = ModuleConfig & {
    options: DefaultDownloadDialogueOptions;
    content: DefaultDownloadDialogueContent;
};
declare type DefaultShareDialogueOptions = ShareDialogueOptions & {};
declare type DefaultShareDialogueContent = ShareDialogueContent & {};
declare type DefaultShareDialogue = ModuleConfig & {
    options: DefaultShareDialogueOptions;
    content: DefaultShareDialogueContent;
};
declare type DefaultSettingsDialogueOptions = SettingsDialogueOptions & {};
declare type DefaultSettingsDialogueContent = SettingsDialogueContent & {};
declare type DefaultSettingsDialogue = ModuleConfig & {
    options: DefaultSettingsDialogueOptions;
    content: DefaultSettingsDialogueContent;
};
declare type Modules = {
    centerPanel: DefaultCenterPanel;
    downloadDialogue: DefaultDownloadDialogue;
    shareDialogue: DefaultShareDialogue;
    settingsDialogue: DefaultSettingsDialogue;
};
export declare type Config = BaseConfig & {
    modules: Modules;
};
export {};
