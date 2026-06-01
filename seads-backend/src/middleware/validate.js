'use strict';

/**
 * Returns an Express middleware that validates req.body against a Zod schema.
 * On failure: responds 422 with the first validation error.
 *
 * @param {import('zod').ZodSchema} schema
 */
function validate(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      const first = result.error.errors[0];
      return res.status(422).json({
        error: `${first.path.join('.') || 'body'}: ${first.message}`,
      });
    }
    req.body = result.data;   // replace body with parsed + coerced value
    next();
  };
}

module.exports = validate;
