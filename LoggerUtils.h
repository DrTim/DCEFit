/*
 * File:   Logger.h
 * Author: tim
 *
 * Created on February 27, 2013, 9:32 AM
 */

#ifndef SETUP_LOGGER_H
#define	SETUP_LOGGER_H

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

#endif	/* LOGGER_H */

