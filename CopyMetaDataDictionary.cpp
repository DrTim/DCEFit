//
//  CopyMetaDataDictionary.cpp
//  DCEFit
//
//  Created by Tim Allman on 2013-04-25.
//
//

#include "CopyMetaDataDictionary.h"

#include <log4cplus/loggingmacros.h>

#include <itkGDCMImageIO.h>

void CopyMetaDataDictionary(const MetaDataDictionary &sourceDict,
                            MetaDataDictionary &destDict)
{
    std::string loggerName = std::string(LOGGER_NAME) + ".CopyMetaDataDictionary";
    LOG4CPLUS_TRACE(log4cplus::Logger::getInstance(loggerName), "Function entry.");

    typedef itk::MetaDataObject<std::string> MetaDataStringType;
    
    for (MetaDataDictionary::ConstIterator iter = sourceDict.Begin();
         iter != sourceDict.End(); ++iter)
    {
        itk::MetaDataObjectBase::Pointer entry = iter->second;
        
        MetaDataStringType::Pointer entryvalue = dynamic_cast<MetaDataStringType*>(entry.GetPointer());
        if (entryvalue)
        {
            std::string tagkey = iter->first;
            std::string tagvalue = entryvalue->GetMetaDataObjectValue();
            itk::EncapsulateMetaData<std::string> (destDict, tagkey, tagvalue);
        }
        else
        {
            LOG4CPLUS_INFO(log4cplus::Logger::getInstance(loggerName),
                           "Non-string entry: " << entry->GetNameOfClass());
        }
    }
}

void CopyMetaDataDictionaryArray(const MetaDataDictionaryArray* sourceArray,
                                 MetaDataDictionaryArray*& destArray)
{
    std::string loggerName = std::string(LOGGER_NAME) + ".CopyMetaDataDictionaryArray";
    LOG4CPLUS_TRACE(log4cplus::Logger::getInstance(loggerName), "Function entry.");
    
    // Create the new dictionary
    destArray = new MetaDataDictionaryArray;
    
    // Iterate through the source array and add new copies of the dictionaries
    // to the destination array.
    for (MetaDataDictionaryArray::const_iterator iter = sourceArray->begin();
         iter != sourceArray->end(); ++iter)
    {
        MetaDataDictionary* dict = new MetaDataDictionary;
        CopyMetaDataDictionary(**iter, *dict);
        destArray->push_back(dict);
    }
}
