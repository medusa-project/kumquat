"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createStore = void 0;
var vanilla_1 = require("zustand/vanilla");
var createStore = function () {
    return (0, vanilla_1.createStore)(function (set) { return ({
        downloadDialogueOpen: false,
        dialogueTriggerButton: null,
        openDownloadDialogue: function (triggerButton) {
            return set({ downloadDialogueOpen: true, dialogueTriggerButton: triggerButton });
        },
        closeDialogue: function () {
            return set({
                downloadDialogueOpen: false,
                dialogueTriggerButton: null,
            });
        },
    }); });
};
exports.createStore = createStore;
//# sourceMappingURL=Store.js.map