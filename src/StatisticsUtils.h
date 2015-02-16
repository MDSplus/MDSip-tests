#ifndef STATISTICSUTILS_H
#define STATISTICSUTILS_H

#include <stdlib.h>
#include <vector>
#include <stdexcept>

#include "Threads.h"




////////////////////////////////////////////////////////////////////////////////
//  Generator Functions  ///////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


double box_muller();

double noise_white();



////////////////////////////////////////////////////////////////////////////////
//  INCREMENTAL STATISTICS  ////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

namespace detail {

template < typename T >
class mp_mean : Lockable {

public:
    mp_mean(size_t size) : m_size(size), m_current_size(0) {
        if(size <= 0)
            throw std::invalid_argument("mean window size must be greater than 0");
    }

    void add(const T &data) {
        MDS_LOCK_SCOPE(*this);
        if(m_current_size == 0) {
            m_current_size = m_size;
            m_values.push_back(0);
        }
        m_values.back() += data - mean();
        ++m_current_size;
    }

    T mean() const {
        T value = 0;
        for(unsigned int i=0; i< m_values.size()-1; ++i)
            value += m_values[i] / m_size;
        if(m_current_size)
            value += m_values.back() / m_current_size;
        return value;
    }


    inline T operator()() const { return mean(); }

    inline T operator << (const T &data) { this->add(data); }



private:    
    const size_t m_size;
    size_t m_current_size;
    std::vector< T > m_values;
};




class incremental_statistic {
public:

    incremental_statistic() :
        m_count(0),
        m_mean(0),
        m_M2(0) {}

    void add(const double data) {
        ++m_count;
        double delta = data - m_mean;
        m_mean += delta/m_count;
        m_M2 += delta*(data - m_mean);
    }

    size_t size() const { return m_count; }

    double mean() const { return m_mean; }

    double variance() const {
        if(m_count < 2)
            return 0;
        else
            return m_M2/(m_count -1);
    }

    double rms() const { return sqrt(variance()); }

    template < typename T >
    friend incremental_statistic &
    operator << (incremental_statistic &st, const T &data) {
        st.add(data);
        return st;
    }

private:
    size_t m_count;
    double m_mean;
    double m_M2;
};



} // detail



class StatUtils {

public:

    typedef detail::incremental_statistic IncrementalOrder2;

};






#endif // STATISTICSUTILS_H

