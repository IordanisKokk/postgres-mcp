import { env } from "../config/env.js";
import { AppError } from "../utils/errors.js";

const SYSTEM_SCHEMAS = new Set(["pg_catalog", "information_schema"]);
const IDENTIFIER_PATTERN = /^[A-Za-z_][A-Za-z0-9_$]*$/;

export const validateIdentifier = (name: string, field: string): void => {
  if (!IDENTIFIER_PATTERN.test(name)) {
    throw new AppError("VALIDATION_ERROR", `Invalid ${field}: ${name}`);
  }
}

export const ensureSchemaAllowed = (schema: string): void => {
  if (env.ALLOWED_SCHEMAS.length === 0) {
    return;
  }

  if (!env.ALLOWED_SCHEMAS.includes(schema)) {
    throw new AppError(
      "SCHEMA_NOT_ALLOWED",
      `Schema '${schema}' is not in ALLOWED_SCHEMAS.`
    );
  }
}

export const ensureNotSystemSchema = (schema: string): void => {
  if (SYSTEM_SCHEMAS.has(schema)) {
    throw new AppError("SCHEMA_NOT_ALLOWED", `Schema '${schema}' is not allowed.`);
  }
}