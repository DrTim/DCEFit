/*
 * File:   DumpMetaDataDictionary.h
 * Author: tim
 *
 * Created on December 21, 2012, 9:45 AM
 */

#include <sstream>

#include "DumpDicomMetaDataDictionary.h"

#include <log4cplus/loggingmacros.h>

#include <itkGDCMImageIO.h>

std::string DumpDicomMetaDataDictionary(const itk::MetaDataDictionary* dict)
{
    std::string loggerName = std::string(LOGGER_NAME) + ".CopyMetaDataDictionary";
    LOG4CPLUS_TRACE(log4cplus::Logger::getInstance(loggerName), "Function entry.");

    typedef itk::MetaDataObject<std::string> MetaDataStringType;

    std::ostringstream stream;

    stream << "DumpDicomMetaDataDictionary" << std::endl
            <<"***************************" << std::endl;

    for (itk::MetaDataDictionary::ConstIterator iter = dict->Begin(); iter != dict->End(); ++iter)
    {
        itk::MetaDataObjectBase::Pointer entry = iter->second;
        MetaDataStringType::Pointer entryValue = dynamic_cast<MetaDataStringType*>(entry.GetPointer());
        if (entryValue)
        {
            std::string key = iter->first;
            std::string label;
            bool found = itk::GDCMImageIO::GetLabelFromTag(key, label);
            if (found)
            {
                std::string tagValue = entryValue->GetMetaDataObjectValue();
                stream << "(" << key << ")" << label << " = " << tagValue << std::endl;
            }
            else
            {
                stream << "label (" << label << ") for key " << key << " not found." << std::endl;
            }
        }
        else
        {
            stream << "Non string entry: " << std::endl;
            entry->Print(stream);
        }
    }

    return stream.str();
}

std::string DumpDicomMetaDataDictionaryArray(const MetaDataDictionaryArray* dict)
{
    std::string loggerName = std::string(LOGGER_NAME) + ".CopyMetaDataDictionaryArray";
    LOG4CPLUS_TRACE(log4cplus::Logger::getInstance(loggerName), "Function entry.");

    std::string retVal;

    for (unsigned idx = 0; idx < dict->size(); idx++)
    {
        std::ostringstream stream;

        stream << std::endl << "****** MetaDataDictionary " << idx << " *******" << std::endl;
        retVal += stream.str();

        const SeriesReader::DictionaryRawPointer pDict = (*dict)[idx];
        retVal += DumpDicomMetaDataDictionary(pDict);
        std::cout << retVal;
    }

    return retVal;
}

