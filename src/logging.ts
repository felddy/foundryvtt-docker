import winston from "winston";

/**
 * createLogger - Create a named logger with a level filter.
 *
 * @param  {string} name      Name of the logger shown in log.
 * @param  {string} log_level Filter level to apply to logging.  Valid levels
 *                            are: error, warn, info, debug
 * @return {string}           The logger.
 */
export default function createLogger(
  name: string,
  log_level: string,
): winston.Logger {
  const logger = winston.createLogger({
    level: log_level,
    format: winston.format.combine(
      winston.format.timestamp({ format: "YYYY-MM-DD HH:mm:ss" }),
      winston.format.errors({ stack: true }),
      winston.format.colorize(),
      winston.format.printf(({ level, message, label, timestamp, stack }) => {
        let line = name + " | " + timestamp + " | [" + level + "] " + message;
        if (stack) line += "\n" + stack;
        return line;
      }),
    ),
    transports: [
      new winston.transports.Console({
        stderrLevels: ["error", "warn", "info", "debug"],
      }),
    ],
  });
  return logger;
}
