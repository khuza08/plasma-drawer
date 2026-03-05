/***************************************************************************
 *   Kicker API Compatibility Layer                                        *
 *                                                                         *
 *   Provides runtime detection and fallbacks for private Kicker APIs      *
 *   to improve resilience against Plasma version changes.                 *
 ***************************************************************************/

.pragma library

// Plasma version compatibility matrix
const COMPAT_VERSIONS = {
    "6.0": { supported: true, notes: "Initial Plasma 6 support" },
    "6.1": { supported: true, notes: "RunnerModel API changes" },
    "6.2": { supported: true, notes: "Current tested version" }
};

/**
 * Check if the current Plasma version is supported
 * @returns {boolean} true if supported
 */
function isPlasmaVersionSupported() {
    // This would ideally query the Plasma version at runtime
    // For now, we assume 6.x is supported
    return true;
}

/**
 * Get the minimum required Plasma version
 * @returns {string} Version string (e.g., "6.0")
 */
function getMinimumPlasmaVersion() {
    return "6.0";
}

/**
 * Validate that required Kicker components are available
 * @param {object} kicker - Kicker namespace object
 * @returns {object} Validation result with success and missing components
 */
function validateKickerAPI(kicker) {
    const required = [
        "AppsModel",
        "SystemModel",
        "RunnerModel",
        "DragHelper",
        "ProcessRunner",
        "DashboardWindow"
    ];

    const missing = [];
    const available = [];

    required.forEach(component => {
        if (kicker && component in kicker) {
            available.push(component);
        } else {
            missing.push(component);
        }
    });

    return {
        success: missing.length === 0,
        available: available,
        missing: missing,
        message: missing.length === 0
            ? "All Kicker APIs available"
            : `Missing Kicker components: ${missing.join(", ")}`
    };
}

/**
 * Log compatibility information for debugging
 */
function logCompatibilityInfo() {
    console.log("[Plasma Drawer] Kicker API Compatibility Check");
    console.log("[Plasma Drawer] Minimum Plasma version:", getMinimumPlasmaVersion());
    console.log("[Plasma Drawer] Supported versions:", Object.keys(COMPAT_VERSIONS).join(", "));
}

/**
 * Handle API degradation gracefully
 * @param {string} componentName - Name of the missing component
 * @param {function} fallback - Fallback function to execute
 * @returns {*} Result of fallback or null
 */
function handleMissingAPI(componentName, fallback) {
    console.warn("[Plasma Drawer] Kicker." + componentName + " not available, using fallback");
    try {
        return fallback();
    } catch (e) {
        console.error("[Plasma Drawer] Fallback for " + componentName + " failed:", e);
        return null;
    }
}
