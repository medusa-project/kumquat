import { CenterPanel } from "../uv-shared-module/CenterPanel";
import { AnnotationBody, IExternalResource, Rendering } from "manifesto.js";
import "mediaelement/build/mediaelement-and-player";
import "mediaelement-plugins/dist/source-chooser/source-chooser";
import "mediaelement-plugins/dist/source-chooser/source-chooser.css";
import { Config } from "../../extensions/uv-mediaelement-extension/config/Config";
export declare class MediaElementCenterPanel extends CenterPanel<Config["modules"]["centerPanel"]> {
    $wrapper: JQuery;
    $container: JQuery;
    $media: JQuery;
    mediaHeight: number;
    mediaWidth: number;
    player: any;
    title: string | null;
    constructor($element: JQuery);
    create(): void;
    openMedia(resources: IExternalResource[]): Promise<void>;
    isTypeMedia(element: Rendering | AnnotationBody): boolean;
    isTypeCaption(element: Rendering | AnnotationBody): boolean;
    isVideo(): boolean;
    resize(): void;
}
