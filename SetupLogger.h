/*
 * File:   Logger.h
 * Author: tim
 *
 * Created on February 27, 2013, 9:32 AM
 */

#ifndef LOGGER_H
#define	LOGGER_H

#import <Log4m/Log4m.h>

/**
 * Set up the logger. Return 0 if all was well, !0 otherwise.
 */
int SetupLogger(const char* name, int level);

#endif	/* LOGGER_H */

