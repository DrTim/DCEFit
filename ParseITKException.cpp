
#include "ParseITKException.h"

#include <sstream>

const char* ParseITKException(const itk::ExceptionObject& ex)
{
    std::stringstream desc;

    desc << ex.GetDescription()
        << " File: " << ex.GetFile()
        << "; Line: " << ex.GetLine()
        << std::endl;

    return desc.str().c_str();
}
