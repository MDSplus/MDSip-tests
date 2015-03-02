/*//////////////////////////////////////////////////////////////////////////////
// CMT Cosmic Muon Tomography project //////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

  Copyright (c) 2014, Universita' degli Studi di Padova, INFN sez. di Padova
  All rights reserved

  Authors: Andrea Rigoni Garola < andrea.rigoni@pd.infn.it >

  ------------------------------------------------------------------
  This library is free software;  you  can  redistribute  it  and/or
  modify it  under the  terms  of  the  GNU  Lesser  General  Public
  License as published  by  the  Free  Software  Foundation;  either
  version 3.0 of the License, or (at your option) any later version.

  This library is  distributed in  the hope that it will  be useful,
  but  WITHOUT ANY WARRANTY;  without  even  the implied warranty of
  MERCHANTABILITY  or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of  the GNU Lesser General  Public
  License along with this library.

//////////////////////////////////////////////////////////////////////////////*/



#include <cmath>
#include <limits>
#include <stdio.h>
//#include <iostream>

//#include "boost/preprocessor/stringize.hpp"

#define PP_STRINGIZE_I(text) #text


#define BEGIN_TESTING(name)                \
static int _fail = 0;                      \
printf("..:: Testing " #name " ::..\n");

#define END_TESTING return _fail;

#define TEST1(val) _fail += (val)==0
#define TEST0(val) _fail += (val)!=0

#define PRINT_TEST(val) printf("testing: (" #val ") = %i\n",(val))
#define TEST1_P(val) PRINT_TEST(val); _fail += (val)==0
#define TEST0_P(val) PRINT_TEST(val); _fail += (val)!=0


namespace testing {

template < typename T >
bool AreSame(T a, T b) {
    return std::fabs(a - b) < std::numeric_limits<T>::epsilon();
}

} // testing


using namespace testing;
