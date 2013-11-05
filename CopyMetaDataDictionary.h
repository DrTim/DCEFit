//
//  CopyMetaDataDictionary.h
//  DCEFit
//
//  Created by Tim Allman on 2013-04-25.
//
//

#ifndef __DCEFit__CopyMetaDataDictionary__
#define __DCEFit__CopyMetaDataDictionary__

#include "ItkTypedefs.h"

/**
 * Copies the data from one dictionary into another. Only string data are copied.
 *
 * @param sourceDict The existing dictionary that we copy from
 * @param toDict The dictionary that we copy to. It need not be empty to start.
 */
void CopyMetaDataDictionary(const MetaDataDictionaryType& sourceDict, MetaDataDictionaryType& destDict);

/**
 * Copies the data from one dictionary array into another. Only string data are copied.
 * The destination array is created using new(). If it points to data on entry
 * they will be lost and the memory leaked.
 *
 * @param sourceArray The existing dictionary array that we copy from
 * @param destArray The dictionary array that we copy to.
 */
void CopyMetaDataDictionaryArray(const MetaDataDictionaryArrayType* sourceArray, MetaDataDictionaryArrayType*& destArray);

#endif /* defined(__DCEFit__CopyMetaDataDictionary__) */
