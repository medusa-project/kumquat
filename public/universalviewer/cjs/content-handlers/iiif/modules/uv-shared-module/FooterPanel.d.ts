import { BaseView } from "./BaseView";
import { BaseConfig } from "../../BaseConfig";
export declare class FooterPanel<T extends BaseConfig["modules"]["footerPanel"]> extends BaseView<T> {
    $feedbackButton: JQuery;
    $bookmarkButton: JQuery;
    $downloadButton: JQuery;
    $moreInfoButton: JQuery;
    $shareButton: JQuery;
    $embedButton: JQuery;
    $openButton: JQuery;
    $fullScreenBtn: JQuery;
    $options: JQuery;
    $toggleLeftPanelButton: JQuery;
    $mainOptions: JQuery;
    $leftOptions: JQuery;
    $rightOptions: JQuery;
    constructor($element: JQuery);
    create(): void;
    updateMinimisedButtons(): void;
    updateMoreInfoButton(): void;
    updateOpenButton(): void;
    updateFullScreenButton(): void;
    updateEmbedButton(): void;
    updateShareButton(): void;
    updateDownloadButton(): void;
    updateFeedbackButton(): void;
    updateBookmarkButton(): void;
    resize(): void;
}
