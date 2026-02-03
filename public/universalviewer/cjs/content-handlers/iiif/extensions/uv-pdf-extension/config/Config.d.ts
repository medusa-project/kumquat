import { BaseConfig, CenterPanelContent, CenterPanelOptions, DownloadDialogueContent, DownloadDialogueOptions, HeaderPanelContent, HeaderPanelOptions, ModuleConfig, SettingsDialogueContent, SettingsDialogueOptions, ShareDialogueContent, ShareDialogueOptions } from "@/content-handlers/iiif/BaseConfig";
declare type PDFCenterPanelOptions = CenterPanelOptions & {
    /** Determines if PDF.js should be used for PDF rendering */
    usePdfJs: boolean;
};
declare type PDFCenterPanelContent = CenterPanelContent & {};
declare type PDFCenterPanel = {
    options: PDFCenterPanelOptions;
    content: PDFCenterPanelContent;
};
declare type PDFHeaderPanelOptions = HeaderPanelOptions & {};
declare type PDFHeaderPanelContent = HeaderPanelContent & {
    emptyValue: string;
    first: string;
    go: string;
    last: string;
    next: string;
    of: string;
    pageSearchLabel: string;
    previous: string;
};
declare type PDFHeaderPanel = {
    options: PDFHeaderPanelOptions;
    content: PDFHeaderPanelContent;
};
declare type PDFDownloadDialogueOptions = DownloadDialogueOptions & {};
declare type PDFDownloadDialogueContent = DownloadDialogueContent & {};
declare type PDFDownloadDialogue = ModuleConfig & {
    options: PDFDownloadDialogueOptions;
    content: PDFDownloadDialogueContent;
};
declare type PDFShareDialogueOptions = ShareDialogueOptions & {};
declare type PDFShareDialogueContent = ShareDialogueContent & {};
declare type PDFShareDialogue = ModuleConfig & {
    options: PDFShareDialogueOptions;
    content: PDFShareDialogueContent;
};
declare type PDFSettingsDialogueOptions = SettingsDialogueOptions & {};
declare type PDFSettingsDialogueContent = SettingsDialogueContent & {};
declare type PDFSettingsDialogue = {
    options: PDFSettingsDialogueOptions;
    content: PDFSettingsDialogueContent;
};
declare type Modules = {
    centerPanel: PDFCenterPanel;
    headerPanel: PDFHeaderPanel;
    settingsDialogue: PDFSettingsDialogue;
    downloadDialogue: PDFDownloadDialogue;
    shareDialogue: PDFShareDialogue;
};
export declare type Config = BaseConfig & {
    modules: Modules;
};
export {};
