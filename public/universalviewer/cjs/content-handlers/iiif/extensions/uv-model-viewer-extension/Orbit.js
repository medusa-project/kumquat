"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Orbit = void 0;
// theta, phi, radius
var Orbit = /** @class */ (function () {
    function Orbit(t, p, r) {
        this.t = t;
        this.p = p;
        this.r = r;
    }
    Orbit.prototype.toString = function () {
        return "".concat(this.t, ",").concat(this.p, ",").concat(this.r);
    };
    Orbit.prototype.toAttributeString = function () {
        return "".concat(this.t, "rad ").concat(this.p, "rad ").concat(this.r, "m");
    };
    Orbit.fromString = function (orbit) {
        orbit = orbit.replace("orbit=", "");
        var orbitArr = orbit.split(",");
        return new Orbit(orbitArr[0], orbitArr[1], orbitArr[2]);
    };
    return Orbit;
}());
exports.Orbit = Orbit;
//# sourceMappingURL=Orbit.js.map