import { BaseExtension } from "../../modules/uv-shared-module/BaseExtension";
import { DownloadDialogue } from "./DownloadDialogue";
import { FooterPanel } from "../../modules/uv-shared-module/FooterPanel";
import { IPDFExtension } from "./IPDFExtension";
import { MoreInfoRightPanel } from "../../modules/uv-moreinforightpanel-module/MoreInfoRightPanel";
import { PDFCenterPanel } from "../../modules/uv-pdfcenterpanel-module/PDFCenterPanel";
import { PDFHeaderPanel } from "../../modules/uv-pdfheaderpanel-module/PDFHeaderPanel";
import { ResourcesLeftPanel } from "../../modules/uv-resourcesleftpanel-module/ResourcesLeftPanel";
import { SettingsDialogue } from "./SettingsDialogue";
import { ShareDialogue } from "./ShareDialogue";
import "./theme/theme.less";
import { Config } from "./config/Config";
export default class Extension extends BaseExtension<Config> implements IPDFExtension {
    $downloadDialogue: JQuery;
    $shareDialogue: JQuery;
    $helpDialogue: JQuery;
    $settingsDialogue: JQuery;
    centerPanel: PDFCenterPanel;
    downloadDialogue: DownloadDialogue;
    shareDialogue: ShareDialogue;
    footerPanel: FooterPanel<Config["modules"]["footerPanel"]>;
    headerPanel: PDFHeaderPanel;
    leftPanel: ResourcesLeftPanel;
    rightPanel: MoreInfoRightPanel;
    settingsDialogue: SettingsDialogue;
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
                        usePdfJs: boolean;
                    };
                    content: {
                        attribution: string;
                    };
                };
                leftPanel: {
                    options: {
                        elideCount: number;
                        galleryThumbHeight: number;
                        galleryThumbWidth: number;
                        oneColThumbHeight: number;
                        oneColThumbWidth: number;
                        pageModeEnabled: boolean;
                        panelAnimationDuration: number;
                        panelCollapsedWidth: number;
                        panelExpandedWidth: number;
                        panelOpen: boolean;
                        thumbsEnabled: boolean;
                        thumbsExtraHeight: number;
                        thumbsImageFadeInDuration: number;
                        thumbsLoadRange: number;
                        treeEnabled: boolean;
                        twoColThumbHeight: number;
                        twoColThumbWidth: number;
                        expandFullEnabled: boolean;
                    };
                    content: {
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
                headerPanel: {
                    options: {
                        centerOptionsEnabled: boolean;
                        localeToggleEnabled: boolean;
                        settingsButtonEnabled: boolean;
                    };
                    content: {
                        emptyValue: string;
                        first: string;
                        go: string;
                        last: string;
                        next: string;
                        of: string;
                        previous: string;
                        pageSearchLabel: string;
                        close: string;
                        settings: string;
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
                        size: string;
                        width: string;
                        shareUrl: string;
                    };
                };
                authDialogue: {
                    options: {
                        topCloseButtonEnabled: boolean;
                    };
                    content: {
                        cancel: string;
                        confirm: string;
                        close: string;
                    };
                };
                clickThroughDialogue: {
                    options: {
                        topCloseButtonEnabled: boolean;
                    };
                    content: {
                        viewTerms: string;
                        close: string;
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
    render(): void;
    isHeaderPanelEnabled(): boolean;
    createModules(): void;
    bookmark(): void;
    dependencyLoaded(index: number, dep: any): void;
    getEmbedScript(template: string, width: number, height: number): string;
}
