/*
 * File:   DumpMetaDataDictionary.h
 * Author: tim
 *
 * Created on December 21, 2012, 9:45 AM
 */

#ifndef DUMPDICOMMETADATADICTIONARY_H
#define	DUMPDICOMMETADATADICTIONARY_H

#include "ItkTypedefs.h"

std::string DumpDicomMetaDataDictionary(const MetaDataDictionaryType* dict);

std::string DumpDicomMetaDataDictionaryArray(const MetaDataDictionaryArrayType* dict);

#endif	/* DUMPMETADATADICTIONARY_H */

