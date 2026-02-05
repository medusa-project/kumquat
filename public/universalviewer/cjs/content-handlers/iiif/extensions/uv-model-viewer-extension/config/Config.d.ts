import { BaseConfig, CenterPanelContent, CenterPanelOptions, DownloadDialogueContent, DownloadDialogueOptions, ModuleConfig, SettingsDialogueContent, SettingsDialogueOptions, ShareDialogueContent, ShareDialogueOptions } from "@/content-handlers/iiif/BaseConfig";
declare type ModelViewerCenterPanelOptions = CenterPanelOptions & {
    /** Determines if auto rotation is enabled */
    autoRotateEnabled: boolean;
    /** Delay in camera change */
    cameraChangeDelay: number;
    /** Determines if double click annotation is enabled */
    doubleClickAnnotationEnabled: boolean;
    /** Determines if interaction prompt is enabled */
    interactionPromptEnabled: boolean;
};
declare type ModelViewerCenterPanelContent = CenterPanelContent & {};
declare type ModelViewerCenterPanel = {
    options: ModelViewerCenterPanelOptions;
    content: ModelViewerCenterPanelContent;
};
declare type ModelViewerDownloadDialogueOptions = DownloadDialogueOptions & {};
declare type ModelViewerDownloadDialogueContent = DownloadDialogueContent & {};
declare type ModelViewerDownloadDialogue = ModuleConfig & {
    options: ModelViewerDownloadDialogueOptions;
    content: ModelViewerDownloadDialogueContent;
};
declare type ModelViewerShareDialogueOptions = ShareDialogueOptions & {};
declare type ModelViewerShareDialogueContent = ShareDialogueContent & {};
declare type ModelViewerShareDialogue = ModuleConfig & {
    options: ModelViewerShareDialogueOptions;
    content: ModelViewerShareDialogueContent;
};
declare type ModelViewerSettingsDialogueOptions = SettingsDialogueOptions & {};
declare type ModelViewerSettingsDialogueContent = SettingsDialogueContent & {};
declare type ModelViewerSettingsDialogue = ModuleConfig & {
    options: ModelViewerSettingsDialogueOptions;
    content: ModelViewerSettingsDialogueContent;
};
declare type Modules = {
    centerPanel: ModelViewerCenterPanel;
    downloadDialogue: ModelViewerDownloadDialogue;
    shareDialogue: ModelViewerShareDialogue;
    settingsDialogue: ModelViewerSettingsDialogue;
};
export declare type Config = BaseConfig & {
    modules: Modules;
};
export {};
