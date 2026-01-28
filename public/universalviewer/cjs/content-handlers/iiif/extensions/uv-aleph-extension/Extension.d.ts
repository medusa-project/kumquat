import { AlephCenterPanel } from "../../modules/uv-alephcenterpanel-module/AlephCenterPanel";
import { BaseExtension } from "../../modules/uv-shared-module/BaseExtension";
import { DownloadDialogue } from "./DownloadDialogue";
import { FooterPanel } from "../../modules/uv-shared-module/FooterPanel";
import { FooterPanel as MobileFooterPanel } from "../../modules/uv-avmobilefooterpanel-module/MobileFooter";
import { HeaderPanel } from "../../modules/uv-shared-module/HeaderPanel";
import { IAlephExtension } from "./IAlephExtension";
import { MoreInfoRightPanel } from "../../modules/uv-moreinforightpanel-module/MoreInfoRightPanel";
import { SettingsDialogue } from "./SettingsDialogue";
import { ShareDialogue } from "./ShareDialogue";
import { AlephLeftPanel } from "../../modules/uv-alephleftpanel-module/AlephLeftPanel";
import "./theme/theme.less";
import { Config } from "./config/Config";
export default class Extension extends BaseExtension<Config> implements IAlephExtension {
    $downloadDialogue: JQuery;
    $multiSelectDialogue: JQuery;
    $settingsDialogue: JQuery;
    $shareDialogue: JQuery;
    centerPanel: AlephCenterPanel;
    downloadDialogue: DownloadDialogue;
    footerPanel: FooterPanel<Config["modules"]["footerPanel"]>;
    headerPanel: HeaderPanel<Config["modules"]["headerPanel"]>;
    leftPanel: AlephLeftPanel;
    mobileFooterPanel: MobileFooterPanel;
    rightPanel: MoreInfoRightPanel;
    settingsDialogue: SettingsDialogue;
    shareDialogue: ShareDialogue;
    defaultConfig: Config;
    locales: {
        "en-GB": {
            options: {
                allowStealFocus: boolean;
                authAPIVersion: number;
                bookmarkThumbHeight: number;
                bookmarkThumbWidth: number;
                dropEnabled: boolean;
                footerPanelEnabled: boolean;
                headerPanelEnabled: boolean;
                leftPanelEnabled: boolean;
                limitLocales: boolean;
                metrics: {
                    type: string;
                    minWidth: number;
                }[];
                multiSelectionMimeType: string;
                navigatorEnabled: boolean;
                openTemplate: string;
                overrideFullScreen: boolean;
                pagingEnabled: boolean;
                pagingOptionEnabled: boolean;
                pessimisticAccessControl: boolean;
                preserveViewport: boolean;
                rightPanelEnabled: boolean;
                saveUserSettings: boolean;
                clickToZoomEnabled: boolean;
                searchWithinEnabled: boolean;
                termsOfUseEnabled: boolean;
                theme: string;
                tokenStorage: string;
                useArrowKeysToNavigate: boolean;
                zoomToSearchResultEnabled: boolean;
            };
            modules: {
                leftPanel: {
                    options: {
                        consoleTabEnabled: boolean;
                        graphTabEnabled: boolean;
                        settingsTabEnabled: boolean;
                        srcTabEnabled: boolean;
                        expandFullEnabled: boolean;
                        panelAnimationDuration: number;
                        panelCollapsedWidth: number;
                        panelExpandedWidth: number;
                        panelOpen: boolean;
                    };
                    content: {
                        title: string;
                        collapse: string;
                        collapseFull: string;
                        expand: string;
                        expandFull: string;
                    };
                };
                dialogue: {
                    options: {
                        topCloseButtonEnabled: boolean;
                    };
                    content: {
                        close: string;
                    };
                };
                footerPanel: {
                    options: {
                        bookmarkEnabled: boolean;
                        downloadEnabled: boolean;
                        embedEnabled: boolean;
                        feedbackEnabled: boolean;
                        fullscreenEnabled: boolean;
                        minimiseButtons: boolean;
                        moreInfoEnabled: boolean;
                        openEnabled: boolean;
                        printEnabled: boolean;
                        shareEnabled: boolean;
                    };
                    content: {
                        bookmark: string;
                        download: string;
                        embed: string;
                        exitFullScreen: string;
                        feedback: string;
                        fullScreen: string;
                        moreInfo: string;
                        open: string;
                        share: string;
                    };
                };
                genericDialogue: {
                    options: {
                        topCloseButtonEnabled: boolean;
                    };
                    content: {
                        close: string;
                        emptyValue: string;
                        invalidNumber: string;
                        noMatches: string;
                        ok: string;
                        pageNotFound: string;
                        refresh: string;
                    };
                };
                headerPanel: {
                    options: {
                        centerOptionsEnabled: boolean;
                        localeToggleEnabled: boolean;
                        settingsButtonEnabled: boolean;
                    };
                    content: {
                        close: string;
                        settings: string;
                    };
                };
                helpDialogue: {
                    options: {
                        topCloseButtonEnabled: boolean;
                    };
                    content: {
                        close: string;
                        text: string;
                        title: string;
                    };
                };
                moreInfoRightPanel: {
                    options: {
                        canvasDisplayOrder: string;
                        canvasExclude: string;
                        copyToClipboardEnabled: boolean;
                        expandFullEnabled: boolean;
                        limitToRange: boolean;
                        manifestDisplayOrder: string;
                        manifestExclude: string;
                        panelAnimationDuration: number;
                        panelCollapsedWidth: number;
                        panelExpandedWidth: number;
                        panelOpen: boolean;
                        rtlLanguageCodes: string;
                        showAllLanguages: boolean;
                        textLimit: number;
                        textLimitType: string;
                        topCloseButtonEnabled: boolean;
                    };
                    content: {
                        attribution: string;
                        canvasHeader: string;
                        close: string;
                        collapse: string;
                        collapseFull: string;
                        copiedToClipboard: string;
                        copyToClipboard: string;
                        description: string;
                        expand: string;
                        expandFull: string;
                        holdingText: string;
                        less: string;
                        license: string;
                        logo: string;
                        manifestHeader: string;
                        more: string;
                        noData: string;
                        page: string;
                        rangeHeader: string;
                        title: string;
                    };
                };
                centerPanel: {
                    options: {
                        titleEnabled: boolean;
                        subtitleEnabled: boolean;
                        mostSpecificRequiredStatement: boolean;
                        requiredStatementEnabled: boolean;
                        dracoDecoderPath: string;
                    };
                    content: {
                        attribution: string;
                    };
                };
                settingsDialogue: {
                    options: {
                        topCloseButtonEnabled: boolean;
                    };
                    content: {
                        close: string;
                        locale: string;
                        navigatorEnabled: string;
                        clickToZoomEnabled: string;
                        pagingEnabled: string;
                        reducedMotion: string;
                        preserveViewport: string;
                        title: string;
                        website: string;
                    };
                };
                shareDialogue: {
                    options: {
                        embedEnabled: boolean;
                        shareEnabled: boolean;
                        embedTemplate: string;
                        instructionsEnabled: boolean;
                        shareFrameEnabled: boolean;
                        shareManifestsEnabled: boolean;
                        topCloseButtonEnabled: boolean;
                    };
                    content: {
                        close: string;
                        customSize: string;
                        embed: string;
                        embedInstructions: string;
                        height: string;
                        iiif: string;
                        share: string;
                        shareInstructions: string;
                        shareUrl: string;
                        size: string;
                        width: string;
                    };
                };
                authDialogue: {
                    options: {
                        topCloseButtonEnabled: boolean;
                    };
                    content: {
                        cancel: string;
                        close: string;
                        confirm: string;
                    };
                };
                clickThroughDialogue: {
                    options: {
                        topCloseButtonEnabled: boolean;
                    };
                    content: {
                        close: string;
                        viewTerms: string;
                    };
                };
                downloadDialogue: {
                    options: {
                        topCloseButtonEnabled: boolean;
                    };
                    content: {
                        allPages: string;
                        close: string;
                        currentViewAsJpg: string;
                        currentViewAsJpgExplanation: string;
                        download: string;
                        downloadSelection: string;
                        downloadSelectionExplanation: string;
                        editSettings: string;
                        entireDocument: string;
                        entireFileAsOriginal: string;
                        entireFileAsOriginalWithFormat: string;
                        individualPages: string;
                        noneAvailable: string;
                        pagingNote: string;
                        preview: string;
                        selection: string;
                        termsOfUse: string;
                        title: string;
                        wholeImageHighRes: string;
                        wholeImageHighResExplanation: string;
                        wholeImageLowResAsJpg: string;
                        wholeImageLowResAsJpgExplanation: string;
                        wholeImagesHighRes: string;
                        wholeImagesHighResExplanation: string;
                    };
                };
                loginDialogue: {
                    options: {
                        topCloseButtonEnabled: boolean;
                    };
                    content: {
                        login: string;
                        logout: string;
                        cancel: string;
                        close: string;
                    };
                };
                restrictedDialogue: {
                    options: {
                        topCloseButtonEnabled: boolean;
                    };
                    content: {
                        cancel: string;
                        close: string;
                    };
                };
                mobileFooterPanel: {
                    options: {
                        bookmarkEnabled: boolean;
                        downloadEnabled: boolean;
                        embedEnabled: boolean;
                        feedbackEnabled: boolean;
                        fullscreenEnabled: boolean;
                        minimiseButtons: boolean;
                        moreInfoEnabled: boolean;
                        openEnabled: boolean;
                        printEnabled: boolean;
                        shareEnabled: boolean;
                    };
                    content: {
                        rotateRight: string;
                        moreInfo: string;
                        zoomIn: string;
                        zoomOut: string;
                        bookmark: string;
                        download: string;
                        embed: string;
                        exitFullScreen: string;
                        feedback: string;
                        fullScreen: string;
                        open: string;
                        share: string;
                    };
                };
            };
            localisation: {
                label: string;
                locales: {
                    name: string;
                    label: string;
                }[];
            };
            content: {
                authCORSError: string;
                authorisationFailedMessage: string;
                canvasIndexOutOfRange: string;
                fallbackDegradedLabel: string;
                fallbackDegradedMessage: string;
                forbiddenResourceMessage: string;
                termsOfUse: string;
                mediaViewer: string;
                skipToDownload: string;
            };
        };
    };
    create(): void;
    createModules(): Promise<void>;
    render(): void;
    isLeftPanelEnabled(): boolean;
    getEmbedScript(template: string, width: number, height: number): string;
}
