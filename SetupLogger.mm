//
//  SetupLogger.mm
//  TestLib
//
//  Created by Tim Allman on 2013-11-04.
//  Copyright (c) 2013 Tim Allman. All rights reserved.
//

#include "SetupLogger.h"

#include <log4cplus/loglevel.h>
#include <log4cplus/logger.h>
#include <log4cplus/consoleappender.h>
#include <log4cplus/fileappender.h>
#include <log4cplus/loggingmacros.h>

int SetupLogger(const char* name, int level)
{
    std::string loggerName(name);

    // The logger is set to log all messages. We use the appenders to restrict the output(s).
    log4cplus::Logger logger = log4cplus::Logger::getInstance(loggerName);
    logger.setLogLevel(level);

    // The console appender
    log4cplus::SharedAppenderPtr consoleAppender(new log4cplus::ConsoleAppender);
    std::string consoleAppName = loggerName + ".console";
    consoleAppender->setName(consoleAppName);
    consoleAppender->setThreshold(log4cplus::INFO_LOG_LEVEL);
    std::string consolePattern = "%-5p (%d{%q}) [%b:%L] %m%n";
    std::auto_ptr<log4cplus::Layout> layout(new log4cplus::PatternLayout(consolePattern));
    consoleAppender->setLayout(layout);

    logger.addAppender(consoleAppender);

    // Generate the name of the rolling file in $HOME/Library/Logs
    std::string homeDir = getenv("HOME");
    std::string logFileName = loggerName + ".log";
    std::string logFilePath = homeDir + "/Library/Logs/" + logFileName;

    std::string logFileAppName = loggerName + ".file";
    log4cplus::SharedAppenderPtr
    logFileApp(new log4cplus::RollingFileAppender(logFilePath, 1000000, 5, false));
    logFileApp->setName(logFileAppName);
    std::string filePattern = "%-5p [%d{%y-%m-%d %H:%M:%S:%q}][%b:%L] %m%n";
    std::auto_ptr<log4cplus::Layout> fileLayout(new log4cplus::PatternLayout(filePattern));
    logFileApp->setLayout(fileLayout);
    logFileApp->setThreshold(log4cplus::TRACE_LOG_LEVEL);
    logger.addAppender(logFileApp);

    LOG4CPLUS_INFO(logger, "Logging to file: " << logFilePath);

    return 0;
}
