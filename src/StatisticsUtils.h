#ifndef STATISTICSUTILS_H
#define STATISTICSUTILS_H

#include <stdlib.h>
#include <vector>
#include <stdexcept>

#include "Threads.h"




////////////////////////////////////////////////////////////////////////////////
//  Generator Functions  ///////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


class StatisticGen {
public:

    static double boxMuller(const double mean = 0, const double sigma = 1);

    static double noiseWhite();

};


////////////////////////////////////////////////////////////////////////////////
//  INCREMENTAL STATISTICS  ////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

namespace detail {


template<typename T>
struct sum_kahan
{
    sum_kahan() : m_sum(0), m_cps(0) {}

    void add(const T &val) {
        const T y = val - m_cps;
        const T t = m_sum + y;
        m_cps = (t - m_sum) - y;
        m_sum = t;
    }

    T operator ()() const {
        return this->m_sum;
    }

    inline friend sum_kahan & operator << (sum_kahan &sum, const T &val) {
        sum.add(val);
        return sum;
    }

private:
    T m_sum;
    T m_cps;
};


template < typename T >
class mean_kahan  {

public:
    mean_kahan() : m_size(0) {}

    void add(const T &data) {
        m_sum.add(data); ++m_size;
    }

    T mean() const { return m_sum() / m_size; }

    inline T operator ()() const { return mean(); }

    inline friend mean_kahan & operator << (mean_kahan &mean, const T &data) {
        mean.add(data);
        return mean;
    }

private:    
    sum_kahan<T> m_sum;
    size_t m_size;
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

    void clear() { *this = incremental_statistic(); }

    size_t size() const { return m_count; }

    double mean() const { return m_mean; }

    double variance() const {
        if(m_count < 2)
            return 0;
        else
            return m_M2/(m_count -1);
    }

    double rms() const { return sqrt(variance()); }

    void operator += (const incremental_statistic & other) {
        size_t nx = other.m_count + m_count;
        double d = other.m_mean - m_mean;
        double mx;
        if(m_count > 50 && other.m_count > 50)
            mx = (m_mean*m_count + other.m_mean*other.m_count) /
                    m_count + other.m_count;
        else {
            mx = m_mean + d * other.m_count / nx;
        }
        m_M2 = other.m_M2 + m_M2 + d*d*m_count*other.m_count/nx;
        m_mean = mx;
        m_count = nx;
    }


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

