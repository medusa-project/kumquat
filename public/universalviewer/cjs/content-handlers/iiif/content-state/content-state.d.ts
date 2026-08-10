import { Annotation } from "@iiif/presentation-3";
import { SupportedTarget } from "./expand-target";
export type ContentState = string | (Annotation & {
    "@context"?: string;
}) | (StateSource & {
    "@context"?: string;
}) | Array<string | (Annotation & {
    "@context"?: string;
}) | (StateSource & {
    "@context"?: string;
})>;
export type StateSource = {
    id: string;
    type: "Manifest" | "Canvas" | "Range";
    partOf?: string | {
        id: string;
        type: string;
    } | Array<{
        id: string;
        type: string;
    }>;
};
export type NormalisedContentState = {
    id: string;
    type: "Annotation";
    motivation: ["contentState", ...string[]];
    target: Array<SupportedTarget>;
    extensions: Record<string, any>;
};
type ValidationResponse = readonly [false, {
    reason?: string;
}] | readonly [true];
export declare function validateContentState(annotation: ContentState, strict?: boolean): ValidationResponse;
export declare function serialiseContentState(annotation: ContentState): string;
export declare function parseContentState(state: string): ContentState;
export declare function parseContentState(state: string, async: false): ContentState;
export declare function parseContentState(state: string, async: true): Promise<ContentState>;
export declare function encodeContentState(state: string): string;
export declare function decodeContentState(encodedContentState: string): string;
export declare function normaliseContentState(state: ContentState): NormalisedContentState;
export {};
