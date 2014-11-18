/*
 * File:   LoggerUtils.h
 * Author: tim
 *
 * Created on February 27, 2013, 9:32 AM
 */

#ifndef LOGGER_UTILS_H
#define	LOGGER_UTILS_H

#include <string>

/**
 * Set up the logger. Return 0 if all was well, !0 otherwise.
 */
void SetupLogger(const char* name, int level);

/**
 * Reset the logger level
 * @param name The name of the logger
 * @param level The new level. See log4cplus for valid  levels.
 */
void ResetLoggerLevel(const char* name, int level);

/**
 * Converts the int logging level to a std::string.
 * @param level The level. It must be a valid log4cplus level.
 * @ @return A string describibing the level, "Unknown" if level is invalid.
 */
std::string LogLevelToString(int level);

#endif	/* LOGGER_UTILS_H */

