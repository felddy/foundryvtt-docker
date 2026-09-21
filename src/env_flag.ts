/**
 * Boolean environment variable parsing shared by the container's Node
 * utilities.  Mirrors src/env_flag.sh: truthy = 1/true/yes/on, falsy =
 * 0/false/no/off (case-insensitive); empty and unset fall back to the
 * caller's default, and any other value warns on stderr and does the same,
 * so a typo never silently flips behavior.
 */

const TRUTHY = new Set(["1", "true", "yes", "on"]);
const FALSY = new Set(["0", "false", "no", "off"]);

/**
 * Interpret a raw string as a boolean flag word, or undefined when it is not
 * one — for options that accept a flag *or* another kind of value (such as a
 * file path) and must not warn on the latter.
 */
export function flagValue(raw: string): boolean | undefined {
    const value = raw.toLowerCase();
    if (TRUTHY.has(value)) {
        return true;
    }
    if (FALSY.has(value)) {
        return false;
    }
    return undefined;
}

export default function envFlag(
    name: string,
    unset: boolean | null = false,
): boolean | null {
    const raw = process.env[name];
    if (raw === undefined || raw === "") {
        return unset;
    }
    const flag = flagValue(raw);
    if (flag !== undefined) {
        return flag;
    }
    console.error(
        `WARN: ${name} has unrecognized value '${raw}'.  Expected true/false ` +
            `(also accepted: 1/0, yes/no, on/off).  Treating it as unset.`,
    );
    return unset;
}
