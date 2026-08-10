"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PDFExtensionEvents = void 0;
var PDFExtensionEvents = /** @class */ (function () {
    function PDFExtensionEvents() {
    }
    PDFExtensionEvents.namespace = "pdfExtension.";
    PDFExtensionEvents.PDF_LOADED = PDFExtensionEvents.namespace + "pdfLoaded";
    PDFExtensionEvents.PAGE_INDEX_CHANGE = PDFExtensionEvents.namespace + "pageIndexChange";
    PDFExtensionEvents.SEARCH = PDFExtensionEvents.namespace + "search";
    PDFExtensionEvents.ZOOM_IN = PDFExtensionEvents.namespace + "zoomIn";
    PDFExtensionEvents.ZOOM_OUT = PDFExtensionEvents.namespace + "zoomOut";
    return PDFExtensionEvents;
}());
exports.PDFExtensionEvents = PDFExtensionEvents;
//# sourceMappingURL=Events.js.map