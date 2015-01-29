#ifndef DATAUTILS_H
#define DATAUTILS_H


#include <sys/time.h>
#include <utility>
#include <vector>

#include "ClassUtils.h"
#include "Threads.h"

#include "StatisticsUtils.h"

////////////////////////////////////////////////////////////////////////////////
//  Named  /////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class Named
{
public:
    Named() : m_name("") {}

    Named(const std::string name) :
    m_name(name) {}

    std::string & operator()() { return m_name; }
    const std::string & operator()() const { return m_name; }

    std::string GetName() const { return m_name; }

private:
    std::string m_name;
};




////////////////////////////////////////////////////////////////////////////////
//  Timer  /////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class Timer
{
public:
    void Start() { gettimeofday(&m_start, NULL); }

    double StopWatch() {
        gettimeofday(&m_end, NULL);
        double timeSec = m_end.tv_sec - m_start.tv_sec +
                (m_end.tv_usec - m_start.tv_usec)*1E-6;
        return timeSec;
    }

private:
    struct timeval m_start, m_end;
};





////////////////////////////////////////////////////////////////////////////////
//  Point2D  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


template <typename _Scalar>
struct Point2D {

    Point2D() {
        m_data[0] = 0;
        m_data[1] = 0;
    }

    Point2D(_Scalar x, _Scalar y) {
        m_data[0] = x;
        m_data[1] = y;
    }

    typedef CommaInitializer< Point2D<_Scalar> , _Scalar >  CommaInit;

    inline CommaInit operator <<(_Scalar scalar) {
        return CommaInit(this, scalar);
    }

    _Scalar & operator[] (const unsigned int i) { return m_data[i]; }

    _Scalar & operator() (const unsigned int i) { return m_data[i]; }

    template < typename _Other >
    operator Point2D<_Other> () {
        return Point2D<_Other> (static_cast<_Other>(m_data[0]), static_cast<_Other>(m_data[1]) );
    }

    friend std::ostream &
    operator << (std::ostream &o, Point2D<_Scalar> &pt) {
        return o << pt[0] << "," << pt[1];
    }

private:
    friend class CommaInitializer< Point2D<_Scalar> , _Scalar >;
    void resize(int i) {}

    _Scalar m_data[2];
};











////////////////////////////////////////////////////////////////////////////////
//  Histogram  /////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


template < typename T >
class Histogram : public Named
{
public:

    Histogram() {} // required by map container //

    Histogram(const char *name, size_t nbin, const T min, const T max) :
        Named(name),
        m_bins(nbin),
        m_limits(min,max)
    {}

    void Push(const T data) {        
        int bin = this->get_bin(data);
        if(bin >= 0 && bin < (int)Size())
            ++m_bins.at( bin );
    }

    inline size_t Size() const { return m_bins.size(); }

    inline void operator<<(const T data) { Push(data); }

    inline std::pair<T,size_t> operator[](unsigned int bin) const { return std::make_pair(get_pos(bin),m_bins.at(bin)); }

    inline size_t operator()(const T pos) const { return m_bins.at(get_bin(pos)); }

    friend std::ostream &
    operator << (std::ostream &o, const Histogram<T> &_this) {
        static const char _c = ';';
        o << _this.GetName() << _c << "value" << "\n";
        for(size_t i=0; i<_this.Size(); ++i)
            o << _this.get_pos(i) << _c << _this.m_bins[i] << "\n";
        return o;
    }

private:

    int get_bin(const T data) const {
        T bin_size = (m_limits.second - m_limits.first) / this->Size();
        return floor( (data-m_limits.first) /bin_size);
    }

    T get_pos(const int bin) const {
        T bin_size = (m_limits.second - m_limits.first) / this->Size();
        return m_limits.first + bin_size * bin;
    }

    std::vector<size_t> m_bins;
    std::pair<T,T> m_limits;
};





////////////////////////////////////////////////////////////////////////////////
//  Curve2D  ////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// FINIRE //

class Curve2D : Lockable, Named
{
public:

    Curve2D(const char *name) :
        Named(name)
    {}

    template < typename _T >
    void AddPoint( const Point2D<_T> &pt ) {
        MDS_LOCK_SCOPE(*this);
        m_data.push_back ( (Point2D<double>)pt );
    }


private:
    std::vector< Point2D<double> > m_data;
};





////////////////////////////////////////////////////////////////////////////////
//  Plot  //////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class Plot2D : Named
{
public:
    struct Axis {
        std::string name;
        std::pair<double,double> limits;
        double ticks;
    };


    Plot2D(const char *name) :
        Named(name),
        m_axis(2)
    {}


    Axis & GetAxis(unsigned int i) { return m_axis[i]; }
    inline Axis & XAxis() { return GetAxis(0); }
    inline Axis & YAxis() { return GetAxis(1); }

private:
    std::vector<Axis> m_axis;
};













#endif // DATAUTILS_H

